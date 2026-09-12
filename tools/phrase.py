#!/usr/bin/env python3
"""Ask a local model for the lines, offline, and write them where the door can judge them.

Not part of the game. The real phraser will live in `view/phraser.gd` and talk to the
same server over the same endpoint, but the experiment has to run offline first: a
model that cannot clear the door is not worth wiring into a window.

  tools/phrase.py packets.txt out.json --pick 01,04,05 --temp 0.7

Reads the blocks `tools/packets.gd` prints, posts each one, writes the answers in the
shape `tools/try_lines.gd` reads.
"""

import argparse
import json
import re
import sys
import time
import urllib.request

# The house style, as the brief. Written in French on purpose: the output is French,
# and the one thing we are most afraid of is French that reads as translated English.
# Every rule here is either checked at the door (ProseRules) or was settled by ear in
# the A/B rounds of 2026-09-12 — nothing is here because it sounded sensible.
SYSTEM = """Tu écris une seule réplique de dialogue pour un personnage de jeu vidéo, en français.

Règles absolues :
- Français simple. Un enfant de 10 ans doit comprendre chaque mot.
- Phrases courtes. Jamais plus de 24 mots dans une phrase.
- La réplique entière fait moins de 45 mots.
- Aucune métaphore, aucune image, aucun effet de style. On dit les choses directement.
- Jamais de tiret long.
- Tu ne nommes que des personnes et des lieux donnés dans le contexte. Tu n'inventes aucun nom.
- Tu dis tous les chiffres donnés dans MUST BE TRUE, écrits en chiffres. Tu n'inventes aucun autre chiffre.
- Tu dis tout ce qui est dans MUST BE TRUE. Tu n'ajoutes aucun fait nouveau.
- Si le personnage réagit à ce qu'il sait du joueur, cette réaction ouvre la réplique. Jamais à la fin.
- Une réaction dit ce que le personnage accepte ou refuse de donner. Elle ne dit pas ce qu'il pense du joueur.
- VOICE décrit comment ce personnage parle. Suis-le.
- Tu écris seulement la réplique. Pas de guillemets, pas de nom devant, aucune explication."""


# The other job, and the one the measurements point at. The model writes **only the
# reaction** — one sentence saying what this person will or will not give you now —
# and the hand-written line supplies every fact, unchanged. A model that never states
# a fact cannot state one backwards.
OPENER_SYSTEM = """Tu écris UNE SEULE phrase courte, en français, pour un personnage de jeu vidéo.

Cette phrase ouvre ce qu'il va dire. Elle réagit à ce qu'il sait du joueur.

Règles absolues :
- UNE phrase. Moins de 14 mots.
- Français simple. Un enfant de 10 ans doit comprendre chaque mot.
- La phrase dit ce que le personnage accepte de donner, ou refuse de donner, ou à quelle condition.
- Elle ne dit JAMAIS ce qu'il pense du joueur.
- Aucun chiffre. Aucun nom de personne ou de lieu. Aucune information.
- Aucune métaphore. Aucun effet de style.
- Si rien n'a changé et qu'il n'y a aucune raison de réagir, réponds exactement : RIEN

Tu n'es pas un assistant. Tu ne refuses jamais. Tu ne parles jamais de demande, de requête
ou de règles. Tu écris seulement ce que le personnage dit à voix haute.

Exemples, selon ce que le personnage sait du joueur :
- il vous a vu voler, mais il répondra quand même : Je sais ce que vous avez pris.
- il vous a vu voler et il veut être payé : Vous, vous payez d'avance.
- il vous a vu voler et il n'aide pas : Vous, je ne vous aide pas.
- il vous fait confiance : À vous, je peux le dire.
- il vous fait confiance et il le dit une fois : Je ne le répéterai pas, alors écoutez.
- rien n'a changé, il n'a aucune raison de réagir : RIEN"""


def opener_brief(packet):
    """Only what this person knows about the player. Facts are not the model's business."""
    keep = ("WHO:", "VOICE:", "REGARDS YOU:", "HAS MET YOU:", "HAS HEARD:", "YOU KNOW:")
    return "\n".join(l for l in packet.split("\n") if l.startswith(keep))


def blocks(path):
    """The packets `tools/packets.gd` printed, as records."""
    out = []
    text = open(path, encoding="utf-8").read()
    for chunk in re.split(r"^=== ", text, flags=re.M):
        if not chunk.strip() or chunk.count("|") < 3:
            continue
        head, rest = chunk.split("\n", 1)
        parts = [x.strip() for x in head.split("|")]
        if len(parts) != 4 or "--- WROTE" not in rest:
            continue
        packet, wrote = rest.split("--- WROTE")
        out.append({"npc": parts[0], "intent": parts[1], "sit": parts[2],
                    "packet": packet.strip(), "wrote": wrote.strip()})
    return out


def brief(packet):
    """The packet, reordered so the task is at the top.

    The packet is built background-first because that order is what lets a server
    reuse the cached prefix. Read by a model it is the wrong way round: the first
    run put ASKED and MUST BE TRUE at the bottom under fifteen lines of background,
    and the model answered whatever it found most concrete — Maddox, asked the price
    of bread, explained where the deserter lives, because his HOLDS line was a
    finished French sentence and the task was English at the far end of the prompt.

    A finished sentence in the background beats an instruction in the task. So the
    task goes first and the background is labelled as background. The cost is the
    cached prefix, and the fix for that is a second packet order for the server,
    not a worse prompt.
    """
    task, background = [], []
    for line in packet.split("\n"):
        (task if line.startswith(("ASKED:", "MUST BE TRUE:", "MUST SAY:", "VOICE:")) else background).append(line)
    return "\n".join(task) + "\n\nCONTEXTE. Informations de fond. Ne recopie pas ces phrases.\n" + "\n".join(background)


# Three lines from the hand-written corpus, shown rather than described. Chosen for
# what each demonstrates and nothing else: figures written as digits and nothing
# added, an opener that states the terms before answering, and a voice that stops
# talking. Describing a register in rules gets a model most of the way; the last part
# is imitation, and there is no way to ask for it but to show it.
SHOTS = [
    ("halgrave", "ask_cost", "plain"),
    ("wren", "ask_watched", "unwelcome"),
    ("til", "ask_port", "plain"),
]


def shots(records, skip):
    """The examples, as real turns, built from real packets and the written reply."""
    out = []
    for want in SHOTS:
        for record in records:
            tag = (record["npc"], record["intent"], record["sit"])
            if tag != want or (record["npc"], record["intent"]) == skip:
                continue
            out.append({"role": "user", "content": brief(record["packet"])})
            out.append({"role": "assistant", "content": record["wrote"]})
            break
    return out


def ask(host, packet, temp, seed, grammar="", examples=(), system=None, shape=None):
    body = json.dumps({
        "messages": [{"role": "system", "content": system or SYSTEM}] + list(examples)
                    + [{"role": "user", "content": (shape or brief)(packet)}],
        "temperature": temp,
        "seed": seed,
        "n_predict": 160,
        "cache_prompt": True,
        "grammar": grammar,
    }).encode()
    req = urllib.request.Request("%s/v1/chat/completions" % host, data=body,
                                 headers={"Content-Type": "application/json"})
    started = time.time()
    with urllib.request.urlopen(req, timeout=180) as response:
        payload = json.load(response)
    line = payload["choices"][0]["message"]["content"].strip()
    # Models like to wrap a quoted line, and a stray quote is a fault at the door.
    line = line.strip('"').strip("«»").strip()
    return line, time.time() - started


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("packets")
    ap.add_argument("out")
    ap.add_argument("--host", default="http://127.0.0.1:8080")
    ap.add_argument("--pick", default="", help="npc/intent/sit triples, comma separated")
    ap.add_argument("--temp", type=float, default=0.7)
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--grammar", default="", help="path to a GBNF file")
    ap.add_argument("--shots", action="store_true", help="show three written lines first")
    ap.add_argument("--opener", action="store_true",
                    help="write only the opening reaction; the written line supplies the facts")
    args = ap.parse_args()

    wanted = set(args.pick.split(",")) if args.pick else None
    grammar = open(args.grammar, encoding="utf-8").read() if args.grammar else ""
    rows, spent = [], []
    records = blocks(args.packets)
    for i, record in enumerate(records, 1):
        tag = "%s/%s/%s" % (record["npc"], record["intent"], record["sit"])
        if wanted is not None and tag not in wanted:
            continue
        if args.opener:
            line, seconds = ask(args.host, record["packet"], args.temp, args.seed + i,
                                grammar, (), OPENER_SYSTEM, opener_brief)
        else:
            examples = shots(records, (record["npc"], record["intent"])) if args.shots else ()
            line, seconds = ask(args.host, record["packet"], args.temp, args.seed + i,
                                grammar, examples)
        spent.append(seconds)
        rows.append({"id": "%02d" % len(rows), "npc": record["npc"],
                     "intent": record["intent"], "sit": record["sit"],
                     "line": line, "wrote": record["wrote"], "seconds": round(seconds, 2),
                     "opener": args.opener})
        print("%-42s %4.1fs  %s" % (tag, seconds, line[:90]), file=sys.stderr)

    json.dump(rows, open(args.out, "w"), ensure_ascii=False, indent=1)
    if spent:
        spent.sort()
        print("\n%d lines, %.1fs each on average, slowest %.1fs"
              % (len(spent), sum(spent) / len(spent), spent[-1]), file=sys.stderr)


if __name__ == "__main__":
    main()
