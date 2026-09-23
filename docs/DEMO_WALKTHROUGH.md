# Demo — shared walkthrough and next sessions

> **Measurements out of date, 2026-09-18.** Every tile and distance below was measured
> against his ironworks **version 3**; his v4 landed on 2026-09-17 and moved sixteen of
> twenty-seven buildings. The route legs and the gap register still read true; the
> building tiles do not. The demo's own locations are now settled in
> [QUEST_CINDERWORKS.md](QUEST_CINDERWORKS.md).

Date: 2026-09-15. Prepared for Yannick and slosinio.

**Status: measured 2026-09-16; not walked by a person, not reviewed by slosinio.**
This is the shared output for Y00/B01 in [the work-item
inventory](DEMO_WORK_ITEMS.md), not an extra set of hours added to those cards.
The route legs, the candidate spots and the two production states below were
measured headless against the checked-in bake and photographed with
`tools/shot.sh` on the revision named in the review record.

**A measured path and a rendered frame are not a played walk.** No row below
records a person finishing the journey with the controls, and no row records
slosinio's review. The proposed story uses of his buildings remain proposals.

## What this review must produce

One agreed route through the existing map, locations for the demo's interactions,
a short list of actual missing pieces, and the next few session-sized tasks.
Yannick owns story and systems; slosinio owns map and graphics. Both review any
choice that couples them, including whether a scene needs a new asset at all.
Agents prepare and implement assigned work; they cannot record agreement on either
brother's behalf. This sheet does not amend the specs or authorize implementation.

The Windows demo journey is settled: creation → fairy → destroyed village → walk
to the steelworks town → support workers or management → combat → consequences.
Workers' victory stops production, removes the immediate work danger and wages,
and costs the crown steel. The shutdown must be visible; basic NPC/journal feedback
can explain the kingdom effect. The final combat approach remains an experiment.
See [the decision handoff](V2_VISION_AUDIT.md) for the accepted scope and audit.

Yannick has now confirmed the map sequence: **Brindle → the inhabited quarter
where the player meets residents → the production installations where the player
acts and sees consequences**. The inhabited quarter and installations form the
existing steelworks settlement. Castle construction and castle outcome visuals
are outside the demo requirements. Exact meeting spots and the brother's review
remain pending; agreement on this sequence does not certify route playability.

## Use the same game for the review

Proposed review budget: use Y00's two hours for preparation, walking and notes,
and B01's two hours for the brother's review. A joint portion counts against both
budgets. If the timing does not fit, split the review; these are unconfirmed estimates.

Record the revision before comparing views. The integrated game is the proof of
what the player can experience; the workshop is the reference for the brother's
intended layout. Differences between them become integration findings.

| Review record | Value |
|---|---|
| Date and participants | Measurement pass 2026-09-16, Yannick + Claude. **Joint walk with slosinio: pending** |
| Game Git revision and any local changes | `6b71e3e`, branch `chore/ingest-recent-map-changes`; one unrelated local change, `prototypes/brindle_3d/assets/landscape/ironworks_ground_mask.png.import` |
| Workshop delivery used by the generated copy/bake | `content/region.json` of 2026-09-15 over the PR #6 ironworks delivery; `view3d/workshop/` present. Neither was regenerated for this pass, so a re-bake before the joint walk is the honest starting point |
| World/view | Baked world, 3D (`Places.world_id()` reported `baked`, pace 2.50 tiles/s) |
| Platform, window size and input device | macOS, `tools/shot.sh` frames at 1280 × 720. **Windows and a real input device: pending** |
| Active testing switches | `Screens.QUICK_START = true`, `Region.TERRAIN_SLOWS_YOU = false`, `Sound.MUSIC = false` |
| Evidence location | Frames are reproducible rather than stored: the exact `tools/shot.sh` command is in each row below |
| Suite at the time of measurement | Fast suite green: 34 suites, 345 tests, 10,380 assertions, 0 failed, 3 map debts, 2 switched off — 9,147.9 ms |

Open the repository's main `project.godot` to walk the integrated game. The
brother's `prototypes/brindle_3d/project.godot` is a separate project. If the
generated copy or bake is stale, assign the refresh to the ingestion owner before
claiming a visual mismatch. Do not edit the workshop to compensate for ingestion.

Creation is currently bypassed by QUICK_START. Record that as a release-path gap;
the existing `tools/shot.sh /tmp/uncrowned-demo-creation.png creation` can show the
screen separately, but a screenshot does not prove creation flows into gameplay.
Use normal walking for route checks. Debug jumps may inspect a spot, but cannot
establish that the journey reaches it. Record blockers rather than fixing them
during this inspection.

## Walkthrough sheet

Each result must be `works`, `needs a named fix`, or `not checked`, with evidence.
Data references alone leave a result `not checked`. Measure travel in seconds,
separating movement from time spent reading or discussing.

| ID / player moment | Existing location or candidate | Check in the integrated game | Result / evidence / actual time |
|---|---|---|---|
| R01 — Create the player | Existing creation screen | Record which choices are available and whether a fresh run preserves them. Note separately what those choices mean to the player | **Not walked.** Read in source: `Screens.QUICK_START = true` ([screens.gd:27](../view/screens.gd#L27)) opens straight into play, so a fresh run does not pass through creation today. What the six traits are worth in play is reviewed in [the existing-behaviour review](DEMO_EXISTING_BEHAVIOUR.md) |
| R02 — Talk to the fairy | `fairy` anchor at `clearing`; clearing still scaffold | Find and approach the fairy; read the conversation; identify the direction to the ruins. Agree any missing presentation on existing terrain | **Frame taken, conversation not played.** `clearing+(0,-1)` resolves; the prompt *« E, parler à la fée, ce qui vit dans le bois »* is offered at (292,286). **There is no fairy to see** — she is a light on the player, and the ground is wooded where the player wakes, so the clearing does not read as a clearing (GAP-01, GAP-02). `tools/shot.sh out.png play 292,286` |
| R03 — See the destroyed village | Delivered `brindle` site | Walk from the clearing, see the destruction from the normal camera and record what currently explains the player's grievance | **Frame taken, not walked.** His six burnt ruins read clearly from the normal camera at (279,319); Wren stands at `brindle+(-4,-3)`. One of our plain placeholder blocks sits in frame (GAP-06). Measured headless, clearing → Brindle centre: **33 tiles, 13.2 s** at 2.5 tiles/s (direct 35). `tools/shot.sh out.png play 279,319` |
| R04 — Walk to the steelworks town | Delivered `village_acierie`, gameplay name `cinderworks` | Reach the town without teleporting; note wrong turns, invisible obstacles and unreadable approaches | **Path exists, measured headless, not walked.** Brindle centre → works centre: **107 tiles, 42.8 s** (direct 110, ratio 0.97 — the way is near-straight). For comparison, clearing → works direct is **75 tiles, 30.0 s**: the ruins are a **southward detour**, and the player passes the clearing again on the way north (GAP-07). The southern approach is the storage yard; frame at `tools/shot.sh out.png play 305,232` |
| R05 — Hear management | Candidate exterior near `MaisonContremaitre` or `BureauPesee` | Choose a visible, reachable speaking spot; check the camera and nearby movement. Do not assume the building has a playable interior | **Both exist in the bake, both reachable; spot not chosen.** `MaisonContremaitre` (310,205), stand (310,204), 118 tiles from Brindle; `BureauPesee` (311,219), stand (310,218), **102 tiles — the nearest candidate to the approach**. Both in zone `cinderworks` with an open tile against the wall. Halgrave does not stand at either today (GAP-03) |
| R06 — Hear workers | Candidate shared space near `CuisineCommune`, `DortoirPlace` or `DortoirNord` | Choose a reachable spot distinguishable from management's; assess existing cast placement and space to converse | **All three exist and are reachable; spot not chosen.** `CuisineCommune` (300,217) stand (299,216), 104 tiles; `DortoirPlace` (308,204) 119; `DortoirNord` (293,200) 121. The workers' campfire already sits at `cinderworks+(-9,9)` → (300,222), just south of the kitchen. **The quarter is empty of people in the frame** — Sena, Ivo and Halgrave all resolve into the production/weigh-office band (GAP-03). `tools/shot.sh out.png play 299,206` |
| R07 — Investigate, act and enter combat | Candidate production area near `HalleMartelage`, `ForgeFinition` or `FourneauUn` | Identify space for evidence, the resolving action and encounter entry. Record what exists; the bell, accident and guard intervention remain story proposals | **Space exists; no quest action and no combat exist.** `HalleMartelage` (312,210) 111 tiles, `ForgeFinition` (313,216) 105, the six furnaces `FourneauUn`–`Six` 110–119, all reachable. The yard is open enough to fight in. **One act is already offered there and is not the quest's:** *« E, éteindre le four »* (`i_wrecked_a_furnace`) stands at the furnaces with no gate (GAP-05). `tools/shot.sh out.png play 320,207` |
| R08 — See production stop or continue | Existing active/cold forge and furnace effects | Choose one inhabited-quarter and one production-area viewpoint. Check the shared visual checklist before the choice and after each outcome. A debug preview does not prove the quest causes the change | **The stopped state is already visible and legible — through the debug switch, not through the quest.** Same viewpoint (320,207), held vs freed: embers and every smoke plume **gone**, furnaces cold, and the entrance line changes from *« Les Forges. 3e aciérie du royaume. Le feu ne s'éteint jamais. »* to *« Les Forges sont aux hommes qui y travaillent. Le compte des morts s'arrête ici. »* Proposed production viewpoint: **(320,207)**; proposed quarter viewpoint: **(299,206)**. `tools/shot.sh out.png play 320,207` then `UNCROWNED_FREE=cinderworks tools/shot.sh out.png play 320,207`. **Y20 is still open**: nothing in the quest causes this |
| R09 — Understand the cost | Existing quest speakers and journal | List the missing explanation of safety, wages and crown steel. Eventually compare both outcomes and check the words against actual simulation effects | **Not played. The effects exist and do not yet say what Yannick confirmed.** `i_turned_the_workers` moves `steel_output −15`, `worker_morale −30`, `town_sentiment −10`, hardship `cinderworks +12`; `i_settled_the_wage` moves `worker_morale +22`, `steel_output +8`, `crown_treasury −8`, hardship `brindle +10`, `cinderworks −12`. **Nothing stops production and nothing names the lost wages.** Detail and verdicts in [the existing-behaviour review](DEMO_EXISTING_BEHAVIOUR.md) |

Location references: [bake brief](../content/bake_brief.json),
[generated region](../content/region.json), [anchors](../content/places.json),
and the brother's [town data](../prototypes/brindle_3d/planning/ironworks-town.json).
`places.json` also contains procedural fallback positions; do not treat those as
the delivered 3D layout. Preserve stable IDs and use anchors for later placement.

## Decisions and gaps to fill together

The brother's existing map is a design input. Prefer a suitable existing space
before requesting a building, interior, new character asset or effect. A map
change is one possible answer to a mismatch; a different interaction location or
scene design may also satisfy the experience.

| Decision | Proposal from data inspection | Yannick's review | slosinio's review | Agreed result / date |
|---|---|---|---|---|
| Map sequence | Brindle → inhabited quarter → production installations; no castle art required for demo | Confirmed 2026-09-15 | Pending | Measured 2026-09-16: the quarter and the works are **side by side, not one behind the other** — coming from the south the player meets the weigh office and the common kitchen first (102 and 104 tiles), the houses lie north-west and the furnaces north-east. Still to walk together |
| Opening route and fairy presentation | Clearing → Brindle → existing steelworks town | Pending | Pending | Pending |
| Management and worker meeting spots | Existing buildings/shared spaces in R05/R06 | Pending | Pending | Pending |
| Evidence, action and encounter entry | Existing production area; exact actions undecided | Pending | Pending | Pending |
| Visual states for the two outcomes | Use the work-item checklist: operating under management, visibly stopped under workers; select exact elements together | Outcome visibility required, 2026-09-15; recipe pending | Pending | Pending |
| Combat prototype assets | Reuse the brother's available assets or agreed plain blocks | Pending | Pending | Pending |
| Next sessions and art effort | Refine the inventory using this walkthrough | Pending | Pending | Pending |

For each observed gap, add one row here before creating a task. The rows below
came from the 2026-09-16 measurement pass — headless paths and rendered frames.
**None came from a played walk**, so a route problem only a player would meet is
still not excluded, and slosinio has reviewed none of them.

| Gap ID | Route row / evidence | Player problem | Smallest proposed change | Responsible owner and dependency | Blocks the demo? |
|---|---|---|---|---|---|
| GAP-01 | R02, frame at (292,286) | The game says *« parler à la fée »* and there is no fairy in the picture — she is a light on the player. The demo's first character is invisible | Agree whether the light *is* her presentation for the demo, or she needs a figure | slosinio (M3b), with Yannick. Decision before any art | Yes — it is the demo's opening beat |
| GAP-02 | R02, same frame | The clearing does not read as a clearing: his trees and the brief's stand where the player wakes, and the HUD calls it *les terres sauvages* | Either plant the ring and open the glade, or accept the wood and drop the word *clearing* from the writing | slosinio (the ring is the standing DEBT), with Yannick | No, but it costs the opening its legibility |
| GAP-03 | R06, frame at (299,206) | Nobody stands in the inhabited quarter. All three Cinderworks speakers resolve into the production band: Halgrave (323,210), Sena (313,214), Ivo (309,218) | Move the anchors the demo needs into the agreed meeting spots, after B01 fixes them | Yannick (`content/places.json`), depends on R05/R06 being chosen | Yes — R06 has no one to hear |
| GAP-04 | R05/R06 candidate spots | Content cannot name his stable building ids. `Region.resolve` matches a `feature` by **kind** and takes the first prop in bake order, so Halgrave stands at `FourneauUn` only because it is first in the list. A re-bake that reorders props moves him | Let an anchor name a `source_id`, and fail by name in `test_anchors` when it is gone. The bake already carries `source_id` on all 74 delivered props | Map-ingestion lane (Claude): `core/region.gd`, `core/places.gd`, `test/test_anchors.gd` | Yes, for placing the quest at named buildings |
| GAP-05 | R07, frame at (320,207) | *« E, éteindre le four »* (`i_wrecked_a_furnace`) is offered at every furnace with no gate, and it is the act that stops the clearing. The demo's workers' outcome is meant to be the quest's, not a free sabotage next to it | Design decision: gate it, remove it from the demo, or make the quest own it | Yannick (design, then `core/rules/`) | Yes — it undercuts the quest's own resolution |
| GAP-06 | R03, frame at (279,319); R02 | Our plain grey placeholder blocks stand in the demo's two opening frames | Name which props his library still owes for Brindle and the clearing, or accept the blocks for the demo | slosinio (M3b), with Yannick | No, but it is the first thing a stranger sees |
| GAP-07 | R04, measured legs | Brindle is a **13 s detour south** of the clearing while the works is 30 s **north** of it: the player walks back past where they woke | Confirm the sequence is wanted as a there-and-back, or move the demo's opening | Both brothers — a map and story decision, not a defect | No — but it is the shape of the opening |

Use the [shared visual checklist in the brother's work items](DEMO_WORK_ITEMS.md#shared-visual-checklist--before-the-choice-and-after-each-outcome)
to fill the following delivery list together. Include each affected production
effect or activity and the agreed status presentation; reuse existing assets.

Filled from the bake and the two rendered states on 2026-09-16. **Everything in
the "workers' outcome" column below already renders** — through
`UNCROWNED_FREE=cinderworks`, not through any quest. slosinio has agreed none of it.

| Existing element / stable ID | Location and comparison viewpoint | Before choice | Management outcome | Workers' outcome | Missing asset or staging work | Brother's delivery / integration owner |
|---|---|---|---|---|---|---|
| `FourneauUn`–`FourneauSix` (his `bas_fourneau_actif`/`_pierre`/`_argile`) | (321,208) (323,203) (321,202) (325,201) (319,211) (324,208); production viewpoint **(320,207)** | Lit: embers and smoke plumes | Unchanged — the initial appearance already says "working" | **Cold: embers and every plume gone.** Renders today | None for the furnaces themselves | Delivered (PR #6). Integration: bind to quest state — Y20 |
| `HalleMartelage` (`forge_affinage`), `ForgeFinition` | (312,210), (313,216); same viewpoint | Working forge effects | Unchanged | Cooled with the works | None known; confirm at the viewpoint | Delivered. Integration: Y20 |
| The works' entrance line | HUD, on entering `cinderworks` | *« Les Forges. 3e aciérie du royaume. Le feu ne s'éteint jamais. »* | Needs its own *restored* words (`sign.cinderworks.restored` exists as a key) | *« Les Forges sont aux hommes qui y travaillent. Le compte des morts s'arrête ici. »* | **It is a HUD line, not an object in the world** — B18's sign/speaker staging is the open piece | Words: Yannick (content, FR+EN). Object: slosinio |
| The four figures standing in the yard | around (320,207) | Traveller sprites, static | Same | Same — they do not stop, because they never worked | Decide whether depicted presence must change; otherwise nothing implies work | slosinio, with Yannick — optional per the checklist |
| Inhabited quarter | `CuisineCommune` (300,217), `DortoirNord` (293,200), `DortoirPlace` (308,204), `MaisonContremaitre` (310,205), `BureauPesee` (311,219); quarter viewpoint **(299,206)** | His houses, the well and trough; **no people** | Response explains continued wages and the danger | Response explains safety and lost wages | The speakers themselves (GAP-03) and their faces (M3b) | Placement: Yannick. Appearance: slosinio (B12–B14) |
| Brindle and the route in | `brindle` (279,319) → works; 107 tiles, 42.8 s | Six burnt ruins, readable | Unchanged | Unchanged | One placeholder block in frame (GAP-06) | slosinio, if the block is to go |
| Crown steel | No object in the world | `steel_output` at its ceiling | `i_settled_the_wage`: +8 | `i_turned_the_workers`: −15, and **production does not stop** | The confirmed outcome — production stops, wages lost — is not what the rules do. See [the behaviour review](DEMO_EXISTING_BEHAVIOUR.md) | Yannick (`core/rules/`), Y18/Y19 |

Production must visibly operate under management and stop after a workers'
victory. If work activity is depicted, it must match that state. Extra idle-worker
poses or scenery changes are proposals to agree with the brother, not assumed
requirements. Brindle and the town's buildings need no new transformation for this
quest; kingdom feedback can remain simple.

Plan six comparison captures for B21: the inhabited quarter and production area
in each of the three states, using the same two viewpoints. Record image paths and
the game revision when they exist. Y20 checks that the actual quest causes these
states and Y21 that the saved state restores them. These captures and checks are
pending; the current sheet is a delivery agreement to complete, not visual proof.

The walkthrough is complete when every route row has an honest result, affected
locations/visual uses have both brothers' recorded review, and each blocking gap
has an assigned next step, including the agreed list of visual state changes.
This closes a planning review, not the gameplay fixes.
Unresolved location choices remain open; preparation by an agent is not approval.

## Turn the findings into small, playable work

The existing 52 cards are an inventory. Their hours are provisional; the brother
has not committed to them. Refine the next few sessions, then revise later work
using actual durations and discoveries. In particular, Y02 combines too much
character authoring, and Y08 combines several combat behaviours. Split those before
execution. Y04 restores creation access; it does not review the creation design.

Review each system through the demo behaviour it must support. Reuse what exists,
record missing behaviour, and implement only the next bounded increment. Technical
foundation tasks may use automated checks, but must name the playable increment
they enable. Preserve the deterministic simulation and existing test discipline.

| Area | First bounded review or increment | Evidence that closes it |
|---|---|---|
| Player creation | Review the existing choices and select the first missing or confusing behaviour | A recorded demo requirement, evidence of the current behaviour, and one follow-up card; no assumed redesign of the whole engine |
| Cast | Agree one participant's role, motive, relationship to the dispute and short French voice sample, then English | Yannick reviews the writing; the brother reviews appearance implications before dependent art |
| Dialogue | After that approval, make one conversation communicate one actionable fact at an agreed location | Walk to that speaker and obtain the fact; verify a repeat conversation and the relevant alternate source |
| Combat | First compare the smallest playable exchange using agreed prototype assets | The player can approach, land an attack or miss, and see the result; technical sub-tasks feed that trial |
| Quest and consequences | After its action is agreed, connect one resolution to the existing production state and its explanation | Perform the action, see the furnace state and read the response; replay/save checks verify persistence |

These rows describe refinement targets, not five newly estimated implementation
cards. If a row requires several sessions, split it into its observable behaviours.
Full-v1 scope still needs its own milestone outline; finishing this demo inventory
does not establish feasibility of the whole three-month game.

Use this short card for the next assigned work:

```text
ID / existing inventory parent:
Player-visible result (one sentence):
Existing behaviour and evidence:
Small change in this session:
Owner / assigned agent / files in scope:
Dependency or decision needed:
Map/graphics input and brother's agreement, if affected:
Estimate (at most four hours, including review and checks):
Exact in-game check, or automated/document check and the playable result it enables:
Completion evidence / actual time / remaining issue:
```

Deliver and integrate each usable map/art increment promptly through its assigned
owner; do not accumulate all integration until week three. Compare the same game
revision together at each affected handoff. An asset can be delivered while its
playable behaviour is still unfinished. Record both states clearly.

Before a shared delivery, record the stable site/asset IDs, intended interaction
and visible states, the recipient responsible for integration, and the exact
in-game check. This keeps Yannick, slosinio and the assigned agent working toward
the same result. It does not authorize either agent to edit the brother's project.

## Next session

The review record and R01–R09 now carry measured observations (2026-09-16) and
seven gap rows. **What is still missing is the part only people can do:** a played
walk from the clearing to the works with the controls, and slosinio's review of the
spots, the two viewpoints and the gap rows. Nothing below has his agreement.

The first session-sized cards these findings produce are sequenced in
[the demo plan](DEMO_PLAN.md), which is now the order of work; the cards themselves
and their verdicts on existing behaviour are in
[the existing-behaviour review](DEMO_EXISTING_BEHAVIOUR.md) §3.

**One measurement here is already out of date on purpose.** The spots and tiles
above are his town **version 3**; his version 4 (`4f4d13e`, 2026-09-15) is not yet
in the game and moves 16 of 27 buildings. Re-measure this sheet after W0. Keep the remaining
cards of the inventory as proposals until their dependencies are known. No new
broad scope interview is needed.
