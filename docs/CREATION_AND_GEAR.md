# Who you are, and what you wear — design

Asked by Yannick on 2026-10-01, before P2, as part of the demo and its tutorial: **block 1**,
the player's appearance chosen at creation; **block 2**, an inventory with equipment slots.
He asked to be advised on the game design as well as for a plan. This is the advice and
the architecture; the tasks are groups **A** and **E** of `docs/DEMO_TASKS.md`.

**Status: approved 2026-10-01.** Yannick answered every question by number: the options
and their counts as proposed, the backpack stays the player's mark, two weapon slots and
no gloves (*« plus tard on ajoutera plein d'armes »*), protection and weight as proposed,
loot as proposed, the hair board before going further, Tab for the inventory. On where the
first weapon comes from he offered two answers — Bram hands it over at the lesson, *or* a
weapon lies to be picked up just past the fairy — and the second is taken, §4: a lesson can
be refused, and a player who refuses it must not walk to the wolves with nothing.

---

## 1. What the screen can show

The player is about **70 pixels tall** on a 1080p screen (his brother's 197-pixel frame at
the game's lens), seen from about 48° above, and **the head is more than half of him**.
`docs/frames/creation/what_shows.png` is each candidate, close up and at that size:

| Candidate | At the game's size | Verdict |
|---|---|---|
| Hair colour | The largest area of the figure | **Worth it** |
| Hair style | Changes the head's outline, which is most of the silhouette | **Worth it** — and the most work |
| Skin tone | Face and hands, clearly | **Worth it** |
| Beard | Reads from the front and the side, not from behind | **Worth it**, a few variants |
| Colour of the starting clothes | The whole body | **Worth it**, and nearly free |
| Build (slimmer, stouter) | A body ±10 % wide under a head that size barely moves | **Not now**: it would also stretch his brushwork in all 64 frames |
| Eye colour, eye shape | His eyes are two dark bars, **two pixels** on screen | **Not worth it** — invisible |
| Height, nose, mouth, scars | Not drawn at this size | No |

**How far we can go, and how far we should.** We *can* go a long way, because every option
is a layer drawn from his traveller (§3). We *should* stop at what reads at 70 pixels: five
choices, about 5,700 combinations, all visible. A choice the player cannot see in the game
is a choice that makes the screen feel padded.

## 2. Block 1 — the options

| Option | Variants | Notes |
|---|---|---|
| **Hair style** | **6** | His spiky hair (the default), short, long to the shoulders, tied back, braided, shaved. Each drawn from his own hair's texture, so it reads as his |
| **Hair colour** | **8** | Red (his), black, dark brown, chestnut, blond, ash blond, grey, auburn. Pure white is impossible: his shader throws away light greys |
| **Skin tone** | **5** | From his pale to dark. His face's reddish outline is recoloured with the skin, or dark skins wear a halo |
| **Beard** | **4** | None, stubble, short, full — in the hair's colour |
| **Clothes' colour** | **6** | The starting tunic and trousers (block 2's first items), dyed |

**The default is his traveller exactly** — red spiky hair, pale skin, no beard, blue tunic —
so a player who changes nothing is the character the brother drew.

**The backpack stays on the player, and only on him.** Group L took it off everybody
else; it has become the player's mark in a crowd, at no cost.

**No name, no gender.** A name is typed text, and the game has none. The figure is
unmarked; long hair and a beard cover what a gender choice would, without labelling them.

**Not now, and why:** eyes (invisible), build (barely visible, distorts his drawing), and
anything else his frames do not draw. If his brother draws bodies one day, build comes
back for free.

## 3. Architecture — layers

Yannick's point: block 1 and block 2 draw together, so they share one system from the start.

**The order, bottom to top:**

```
body (skin, outline, eyes) → trousers → feet → tunic → backpack → beard → hair
→ head gear (may hide the hair) → weapon in the hand → weapon on the back
```

- **A layer is a sheet in the layout every look already uses** — his walk frames with our
  fight cells below them. So every layer has the same frame at the same place, and
  `CastLooks.frames_for` (group L) reads all of them unchanged.
- **The layers are baked by the tool that made the cast's looks** (`tools/draw_cast_looks.gd`,
  a new `--layers` mode): his figure split into its parts, the parts he never drew (a
  shaved head, the other hair styles, the beards, every item) painted by the same pieces
  in his manner. **The test that makes it trustworthy:** the default layers stacked back
  together give his traveller, pixel for pixel.
- **Colour is applied live, by a shader**, the same recolouring the recipes do (hue,
  saturation scale and floor, value scale — his values kept). So eight hair colours are one
  sheet per style, not eight; a choice on the creation screen changes a number, not an
  image; and putting on a helmet changes nothing but which sheet is on the head.
- **Head gear hides hair with a mask.** A helmet's sheet carries, in its own channel, where
  hair may not show: the shader drops the hair's pixels there. A close cap hides only the
  crown, so long hair falls below it; a closed helm hides all of it. Group L's helm, cap
  and hood rules already say exactly this; they move from "erase" to "mask".
- **One compositing function, two shaders**: a spatial one for the world (with the fight's
  flash and the player's ghost, which exist today) and a canvas one for the creation and
  inventory screens. **The preview is the game's own drawing**, not an imitation of it.
- **Only the player is layered.** The cast keeps group L's baked sheets: a crowd of thirty
  does not need thirty live composites. Because the same pieces make both, the leather cap
  a player loots is the cap the works' guard wore.
- **Memory**: a tintable layer is grey and alpha (6 MB, not 12); only the player's current
  layers are loaded — about a hundred megabytes at worst, beside group L's sheets.

**In the simulation**, appearance is data and nothing reads it: the `create_character`
event carries the five choices beside the traits, a new `Appearance` store holds them,
and `AppearanceRules` refuses an option that does not exist. A save from before this has
no such fields and loads as his traveller. No save version bump for block 1.

## 4. Block 2 — inventory and equipment

### The slots, and the hands

| Slot | What goes there |
|---|---|
| Head | Cap, hood, helmet |
| Torso | Tunic, gambeson, breastplate |
| Legs | Trousers, leggings |
| Feet | Boots |
| **Weapon** | Sword, and later dagger or axe |
| **Bow** | A bow, carried on the back |

**The recommendation for the hands: two weapon slots and no gloves.** The fight already has
two ways to strike and a key, **U**, that switches between them; the tutorial teaches it.
Two slots — one for the hand, one on the back — keep that exactly, and make the bow
something you carry rather than a fact you were given. **Gloves are left out**: hands are
three pixels on screen, so a glove is a stat nobody can see. Plate gauntlets come with the
breastplate, as the king's guards wear them.

### What equipment does — simple, and readable

Two numbers on every piece of armour, and the fight reads nothing else:

- **Protection** (0 to 3): taken off **every blow you receive**, never below 1. A cloth
  tunic gives 0, leather 1, plate 2. Full royal plate takes a king's guard's blow of 10 to 5.
- **Weight** (light or heavy): **two heavy pieces or more cost one tile of movement a turn**
  (4 becomes 3). Protection against mobility — and the quest's archers are built to make
  you move, so the choice is real.

**Weapons keep the numbers they have** (`content/duel.json`): the sword strikes for 5 at
one tile, the bow for 3 from two to six. New weapons later are new rows, not new rules.
**The traits do not change** for the demo: they open lines of dialogue, and making them
combat numbers is a design of its own.

### Where things come from, in the demo

- **At the start**: a cloth tunic and cloth trousers in the colour chosen at creation,
  and walking boots. **No weapon.**
- **The first sword lies by the graves, just past the fairy** (Yannick, 2026-10-01): a
  short sword on a fallen villager's grave, picked up with the key that picks anything up.
  Bram's line points at it if you come to him without it. **Bare hands** strike for less
  than a sword, so a player who walks past it is weaker, not stuck.
- **Wren's bow**: given at the bow lesson as today, now an item in the bow slot.
- **Loot — recommended**: a beaten fighter leaves **what you saw on him**. The works'
  guards: a leather cap, an ochre gambeson. Each king's guard, by a miracle: a helmet, a
  breastplate or leggings. It makes the looks of group L worth looking at, and it is
  deterministic — a fixed table per kind, through derived events like the purse.

### The screen

**Tab** opens it (I is the gift's key). The player in the middle, drawn by the game's own
layers, turning; the six slots around him; on the right, what you carry, with protection,
weight, damage and reach, and what changes against what you wear. Equip and unequip are
events in the log, like every other act. **Not during a fight.** A save version bump (5),
because the fight reads armour.

---

## 5. What is ours, and the art rule

Everything here is drawn by us from his traveller, in his manner, and nothing is
downloaded (`CLAUDE.md`, *Art rule*, 2026-09-30). An asset-research sub-agent is not
needed for the drawing; one review sub-agent walks the whole of it at the end (the path
from the creation screen to equipment in play).
