# Demo — shared walkthrough and next sessions

Date: 2026-09-15. Prepared for Yannick and slosinio.

**Status: prepared, not yet walked or agreed with slosinio.** This is the shared
output for Y00/B01 in [the work-item inventory](DEMO_WORK_ITEMS.md), not an extra
set of hours added to those cards. All measurements and review results below are
pending. Existing-map references were checked in data; their proposed story uses
have not been validated by playing.

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

## Use the same game for the review

Proposed review budget: use Y00's two hours for preparation, walking and notes,
and B01's two hours for the brother's review. A joint portion counts against both
budgets. If the timing does not fit, split the review; these are unconfirmed estimates.

Record the revision before comparing views. The integrated game is the proof of
what the player can experience; the workshop is the reference for the brother's
intended layout. Differences between them become integration findings.

| Review record | Value |
|---|---|
| Date and participants | Pending |
| Game Git revision and any local changes | Pending — obtain with `git rev-parse HEAD` and `git status --short` |
| Workshop delivery used by the generated copy/bake | Pending — confirm it matches the reviewed delivery |
| World/view | Baked world, 3D; confirm no procedural/2D override |
| Platform, window size and input device | Pending |
| Active testing switches | Record QUICK_START, terrain slowdown and music settings |
| Evidence location | Pending — use screenshot/video filenames in the rows below |

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
| R01 — Create the player | Existing creation screen | Record which choices are available and whether a fresh run preserves them. Note separately what those choices mean to the player | Not checked |
| R02 — Talk to the fairy | `fairy` anchor at `clearing`; clearing still scaffold | Find and approach the fairy; read the conversation; identify the direction to the ruins. Agree any missing presentation on existing terrain | Not checked |
| R03 — See the destroyed village | Delivered `brindle` site | Walk from the clearing, see the destruction from the normal camera and record what currently explains the player's grievance | Not checked; clearing → ruins: pending seconds |
| R04 — Walk to the steelworks town | Delivered `village_acierie`, gameplay name `cinderworks` | Reach the town without teleporting; note wrong turns, invisible obstacles and unreadable approaches | Not checked; ruins → town: pending seconds |
| R05 — Hear management | Candidate exterior near `MaisonContremaitre` or `BureauPesee` | Choose a visible, reachable speaking spot; check the camera and nearby movement. Do not assume the building has a playable interior | Not checked; location choice pending |
| R06 — Hear workers | Candidate shared space near `CuisineCommune`, `DortoirPlace` or `DortoirNord` | Choose a reachable spot distinguishable from management's; assess existing cast placement and space to converse | Not checked; location choice pending |
| R07 — Investigate, act and enter combat | Candidate production area near `HalleMartelage`, `ForgeFinition` or `FourneauUn` | Identify space for evidence, the resolving action and encounter entry. Record what exists; the bell, accident and guard intervention remain story proposals | Not checked; action/opponent pending design review |
| R08 — See production stop or continue | Existing active/cold forge and furnace effects | Choose a repeatable viewing position. Inspect available states and note what a player could actually perceive. A debug preview does not prove the quest causes the change | Not checked; viewing spot pending |
| R09 — Understand the cost | Existing quest speakers and journal | List the missing explanation of safety, wages and crown steel. Eventually compare both outcomes and check the words against actual simulation effects | Not checked; exact feedback pending |

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
| Opening route and fairy presentation | Clearing → Brindle → existing steelworks town | Pending | Pending | Pending |
| Management and worker meeting spots | Existing buildings/shared spaces in R05/R06 | Pending | Pending | Pending |
| Evidence, action and encounter entry | Existing production area; exact actions undecided | Pending | Pending | Pending |
| Visible shutdown | Reuse cold furnace/forge effects; identify any missing cue | Pending | Pending | Pending |
| Combat prototype assets | Reuse the brother's available assets or agreed plain blocks | Pending | Pending | Pending |
| Next sessions and art effort | Refine the inventory using this walkthrough | Pending | Pending | Pending |

For each observed gap, add one row here before creating a task. There are no
verified walkthrough findings yet; a blank register does not mean the route works.

| Gap ID | Route row / evidence | Player problem | Smallest proposed change | Responsible owner and dependency | Blocks the demo? |
|---|---|---|---|---|---|
| To fill after observation | — | — | — | — | — |

The walkthrough is complete when every route row has an honest result, affected
locations/visual uses have both brothers' recorded review, and each blocking gap
has an assigned next step. This closes a planning review, not the gameplay fixes.
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

Fill the review record and R01–R09, then complete the decision and gap tables with
slosinio. Select the first few cards from those findings. Keep later cards as
proposals until their dependencies and estimates are known. No new broad scope
interview is needed; no walkthrough result or brother's approval has been recorded yet.
