# Public demo — Cinderworks work items

> **Superseded, 2026-09-18.** Its 52 cards were written for the old simulation and are
> replaced by [DEMO_TASKS.md](DEMO_TASKS.md). What is still live here: the capacity
> table, the brother's B-items, and the shared visual checklist. Read
> [SIMULATION_MODEL.md](SIMULATION_MODEL.md) before acting on anything below.

Date: 2026-09-15. Planning draft by Codex for Yannick and his brother.

## What is agreed

- Public demo in a few weeks, targeting one month (working date around 2026-10-15).
- Full playable v1 in three months (working date around 2026-12-15). The demo is an
  early part of that game, not the whole three-month deliverable.
- Demo journey: create the player → speak with the fairy → see the destroyed
  village → walk to the steelworks town → support workers or management → combat
  within the quest → understand the kingdom impact and see the local consequence.
  Fit this journey to the map and town the brother has already built.
- Confirmed map sequence: **Brindle → the inhabited steelworks quarter → the
  production installations**. The quarter and works form the same delivered
  settlement. Castle construction or castle consequence art is not a demo dependency.
- Quest: a workers' dispute inside the works, with the player supporting workers or
  management. No forest-camp quest is planned for the demo.
- Workers' victory: production stops. Workers escape the danger but lose their
  wages, and the crown loses steel. Worker-run continued production is not this outcome.
- Kingdom feedback may be very basic for the demo. The factory shutdown must have
  visible consequences; a second transformed location is not required.
- The brother's work explicitly includes the map/asset presentation for the two
  quest outcomes, verified in the integrated game. The shared visual checklist
  below is part of demo acceptance, not optional final polish.
- Public demo platform: **Windows only**. Development may continue on macOS.
- Combat is required. The real-time fighting screen inspired by Street Fighter and
  Budokai is the initial candidate; try another approach and select by playing.
  The final style, move set and art requirements are not approved yet.
- Each person has four hours a day, six days a week. Agents help with drafting,
  implementation and tests; their presence does not create extra human review/art hours.

See [the audit and decision handoff](V2_VISION_AUDIT.md). This document adds a
proposed backlog, **not implementation, approved dialogue/lore, a spec amendment,
or a promise that all estimates have been proven**. Every work item is currently
unstarted. The location lookup below is prepared; the in-game walkthrough is still
open. No source, spec or workshop file was changed to create this plan.

**Start with [the shared walkthrough sheet](DEMO_WALKTHROUGH.md).** It is the
concrete Y00/B01 deliverable and records the route checks, both brothers' decisions,
gaps and next-session cards. Its route rows and gap register were filled with
measured observations on 2026-09-16 — headless paths and rendered frames, not a
played walk, and with no review by slosinio. **Y00 is part done and B01 is
untouched.** [The existing-behaviour review](DEMO_EXISTING_BEHAVIOUR.md) narrows
Y01 to four open questions and holds the first five refined cards; read it before
treating Y01, Y04, Y15–Y18 as ready to code. The brother has not agreed this inventory or its art
estimates. The 52 cards below are a draft inventory, not a validated session plan;
refine oversized items before execution and integrate usable deliveries throughout
development, rather than waiting for week three. The walkthrough sheet records the
execution corrections agreed after this first planning draft.

## Map the journey onto the delivered world

The current [bake brief](../content/bake_brief.json) and generated
[region data](../content/region.json) bind `cinderworks` to the brother's
`village_acierie`, and `brindle` to his `brindle`. Both settlements are marked as
delivered, not scaffold settlements. The steelworks bake includes 27 buildings
and 47 props from his town. This is a data inspection, not a new playability check.

| Journey beat | Existing location or asset | What must be checked before authoring |
|---|---|---|
| Player creation | Existing title/creation screens | Selected traits survive entry to the opening; the public build does not bypass creation |
| Fairy conversation | Existing `fairy` anchor at point `clearing` | The clearing is still marked scaffold in the bake: agree its presentation on the existing terrain and its walk to the ruins |
| Destroyed village | Delivered `brindle` site and Brindle scene | The player can see the destruction and understand the grievance from the normal game camera |
| Walk to the steelworks town | Delivered `village_acierie` site, exposed to gameplay as `cinderworks` | Walk clearing → Brindle → town without debug movement; record actual duration and any blocked or confusing approach |
| Management's account | Existing `MaisonContremaitre` / `BureauPesee` buildings | Candidate exterior meeting spots; choose a reachable approach, not an assumed playable interior |
| Workers' account | Existing `CuisineCommune` / `DortoirPlace` / `DortoirNord` | Candidate shared-space meeting spots; confirm actor and interaction visibility |
| Evidence, action and combat entry | Existing production area, including `HalleMartelage`, `ForgeFinition` and `FourneauUn` | Pick reachable evidence/action anchors and the encounter entry; this does not determine the combat screen's shape |
| Visible shutdown | Delivered furnaces/forges and their existing active/cold effects | Verify the approved quest outcome drives those effects, with workers' responses explaining lost wages |
| Basic kingdom impact | Existing steel quantity, journal and relevant NPC dialogue | Show the actual loss of crown steel through a short explanation; no new receiving yard or capital scene is required |

Building IDs above come from the brother's
[ironworks town data](../prototypes/brindle_3d/planning/ironworks-town.json);
their story uses are proposals. Existing Harry/Sena/Ivo and ledger anchors in
[places.json](../content/places.json) are not yet proof that those people or
interactions stand at these particular buildings. The procedural fallback positions
in that file are not the delivered 3D layout. Any later placement uses anchors.

Y00/B01 turn this lookup into a walked route and agreed location sheet before Y01
fixes the quest actions. Some opening road extensions remain scaffold proposals;
JSON references alone do not prove the whole walk is ready. Reuse existing town
spaces first and give the brother only the specific missing presentation or route
fixes found in the walkthrough. The two sides are workers and management, not two
new physical camps or a new town.

## Confirmed outcome and proposed quest scene

The scope interview has answered the questions needed to draft the demo work:
location, conflict, workers' winning outcome, combat inclusion/candidate and platform.
Do not repeat those questions. Y01 is now a concrete design review, not another
choice between an internal workers' dispute and a forest camp.

**Confirmed by Yannick:** a workers' victory stops production. Workers no longer
risk their lives at the furnaces but lose their wages; the crown loses steel.
Supporting management is the other side of the dispute. The particular concession
and actions below are proposals for review, not new canon.

Proposed scene to review in Y01:

1. After another accident, the workers want the dangerous shift stopped. The
   foreman argues that keeping the works open keeps wages and royal orders coming.
   The accident, exact demands and names still need authorial approval in Y01/Y02.
2. The player inspects the furnace/ledger and hears the worker representative and
   foreman. The physician provides an independent account; evidence remains available
   if one person cannot provide it. Use the existing three roles before inventing cast.
3. **Management path:** obtain a concrete wage commitment from the foreman, take
   its terms to the workers, then call the shift back using the agreed physical
   interaction. A shift bell is a candidate prop: the player must go and act, rather
   than ownership changing as soon as a document is read. Wages and production
   continue; the dangerous work and its cost remain.
4. **Workers' path:** corroborate the safety case, back the walkout during a guard
   intervention, then stop the shift through the agreed interaction. The guard
   encounter offers combat and a peaceful resolution supported by evidence; it is
   not an extra camp or a second quest. Exact defeat/death handling is part of Y01.
5. At the works, compare the lit furnaces with the stopped works. Workers away
   from their posts are an optional staging detail. Hear the foreman and workers
   respond. Show the loss of wages as a real cost in the agreed scene/dialogue.
6. **Basic kingdom proof:** the crown actually loses steel under the workers'
   outcome. A short journal entry and/or existing speaker explains the connection
   to the stopped works. This is the proposed minimum for Yannick's acceptance of
   basic kingdom feedback; the local shutdown remains visibly demonstrated.

The exact amounts, physical action and encounter script become ready-to-code
definitions in Y01, after mapping them to the delivered town. Y16–Y20 and B15–B16 are bounded implementation
slots until that review, with concrete candidate actions above. Re-estimate them
if the reviewed design grows. A peaceful route and quest survival when an NPC is
unavailable remain subject to existing invariants. Combat availability does not
mean every playthrough must kill someone. The demo contains one quest with two
outcomes, not two separate questlines.

## Existing work to reuse

Targeted source inspection for this plan, separate from the earlier document-only
audit, found:

- [QuestRules](../core/rules/quest_rules.gd) has eight fact-pattern quests,
  including learning the works' true toll and stopping the clearing.
- [PlaceRules](../core/rules/place_rules.gd) recognizes Cinderworks ownership,
  the ledger's freeing act and the wage-settlement holding act.
- [The French cast](../content/cast.fr.json) already contains Harry, Sena and
  Ivo, their positions in the dispute and several spoken deeds. Their current
  writing/names are inputs to review, not automatically approved demo content.
- [Screens](../view/screens.gd) already routes title/creation/play; QUICK_START
  bypasses creation during development.
- [The play window](../view/main.gd) has screenshot-position/state pokes, not a
  safe interactive scenario editor. Do not extend the direct state writes into
  the new testing mode.
- [ContactSystem](../core/systems/contact_system.gd) still handles contact damage
  from the king. It is not a playable combat system. [Sim](../core/sim.gd) defines
  the step, tick, event and replay contract combat must respect.
- [SaveFile](../core/save_file.gd) already writes/reloads the run. Extend and test
  it for new state rather than invent a parallel gameplay save.
- [V3](V3.md) records delivered 3D ironworks and working/cold furnace effects.
  This is a starting point, not proof of the demo's final quest or all visuals.
- No export configuration was found in the targeted file search. A
  Windows export and actual Windows play check are scheduled early/explicitly.

## How to use the tickets

Estimates are first-pass **owner time**, including normal review, applicable tests,
documentation and handoff. They are not measured implementation durations.
Every item is at most four hours; if its agreed acceptance condition cannot fit,
split/re-estimate it before coding. Do not call an incomplete item done to preserve
the calendar. Art estimates especially need the brother's calibration after B04.

Yannick owns Y items, assisted by Codex or Claude. Core/content can stay in Codex's
lane. Window, combat presentation and ingestion work must be assigned explicitly:
Claude can own the relevant current window/ingestion files, or a future task can
explicitly extend Codex's scope. This planning document does not change ownership.
The brother alone owns B items and edits under prototypes/. Joint review is counted
once on each person's budget (Y12 and B06). Do not let both agents edit the same files
at the same time. No agents are spawned by this plan.

For code changes: test first through tools/run_tests.sh; run the fast suite after
meaningful steps and both full suites before commits, following the shared working
agreement. Content is French first and English in the same change. Visual acceptance
requires a rendered game or screenshot, not just headless tests. Test helpers name
places/anchors, not literal coordinates. Production state mutations go through Sim.
Explicitly named document/art reviews below are alternatives to in-game checks until
those outputs have been integrated.

Development scenarios use separate saves and are absent from the public export.
Windows release checks must run on Windows; identify the test host in Y24. Preparing
an export is authorized by its future implementation task; publishing remains
Yannick's action.

## Four-week capacity and ordering

| Owner | Week 1 | Week 2 | Week 3 | Week 4 | Scheduled | Reserve within 96 h |
|---|---:|---:|---:|---:|---:|---:|
| Yannick + agents | 23 h | 18 h | 22 h | 11 h | 74 h | 22 h |
| Brother | 20 h | 18 h | 13 h | 4 h | 55 h | 41 h |
| Combined | 43 h | 36 h | 35 h | 15 h | 129 h | 63 h |

The table is a first-pass capacity calculation, not a validated schedule. The 52
tickets below still need refinement, particularly Y02's bundled cast work and
Y08's combat foundation. Y04 also needs a focused review of existing creation
behaviour before assuming that restoring the screen covers the demo requirement.
A week means six four-hour working sessions. Reserve covers integration
surprises, animation overruns and fixes from playtests, not extra promised features.
The remaining days around the one-month date are not counted as free capacity.

- **Week 1:** map the journey onto the existing world, settle the dispute/cast,
  launch isolated test runs, play the first
  combat candidate, prepare route/character assets and produce an initial Windows
  package. Confirm the real Windows test machine now.
- **Week 2:** compare/select combat, enter/leave encounters, teach controls, discover
  the dispute and perform both resolution actions. Combat production poses follow
  the comparison, not the other way round.
- **Week 3:** integrate both local outcomes and basic kingdom feedback, test persistence,
  complete combat visuals and play from the opening through a resolution.
- **Week 4:** Windows playtesting, readability, credits, blocking fixes and the
  candidate package. The public demo is not released solely because its tests pass.

Dependency order matters within a week. No listed dependency sits in a later week.
Y01 can change the detailed outcome work; Y12 can change combat/animation work. Recalculate
this table at those two points. If a two-outcome quest or useful combat requires
more than the reserve, present the measured trade-off early; do not quietly move
the demo to month three or remove combat/world change.

## Yannick's work items

### Y00 — Walk and map the demo journey on the delivered map

Owner: Yannick + agent. Estimate: 2 h. Week: 1. Depends on: —.

**Done:** Use the location lookup above to trace fairy clearing → Brindle ruins → steelworks town in the integrated game. Record candidate worker/management, evidence, action and encounter-entry spots by stable IDs; measure walking time and list only the route/presentation gaps that affect the demo. Hand the sheet to the brother for B01 before writing the exact scene.

Use [DEMO_WALKTHROUGH.md](DEMO_WALKTHROUGH.md) for the evidence and result; no route check is complete yet.

**Check:** Capture the opening, ruins, town approach and proposed interaction spots during a normal walk. Distinguish reachable places from blockers and scaffold presentation; no teleport or new geometry is used to claim the route works. This task is inspection and planning, not a map edit.

### Y01 — Write the workers' dispute as two playable outcome paths

Owner: Yannick + agent. Estimate: 2 h. Week: 1. Depends on: Y00, B01.

**Done:** Review the proposed scene above against the agreed existing-town locations: workers seek a stoppage after an accident; management offers wages to keep production going. Agree the demands, each side's resolving action, guard encounter/peaceful alternative, defeat semantics, visible local outcome and basic steel-loss feedback. Workers' victory stopping production is already confirmed; the accident and guard script remain proposals.

**Check:** Walk both paths on paper with Yannick. Each has an action beyond reading, a cost, and a visible result. This is a design review, not an in-game test.

### Y02 — Approve the opening and quest cast's identities and voices

Owner: Yannick + agent. Estimate: 2 h. Week: 1. Depends on: Y01.

**Done:** For the fairy and each named quest participant, agree motive, relationship, naming direction and three sample lines in French first, then English. Reuse existing characters where they fit; the prototype budget assumes three named quest participants.

**Check:** Read the lines aloud without role labels: the speakers' interests must differ and both sides must have a comprehensible case. Other characters' full dossiers are not a prerequisite.

### Y03 — Record only the demo decisions and the combat simulation contract

Owner: Yannick + agent. Estimate: 1 h. Week: 1. Depends on: Y01.

**Done:** Prepare the accepted changes for the relevant SPECS sections and §20: opening journey, quest outcomes, combat result semantics and advancing fights while world time pauses. Reconcile the audited opening/king-information conflict before Y22's dialogue, rather than silently choosing between old wording and the vision. Preserve determinism and the fact-based quest model; identify any changed invariant explicitly.

**Check:** Review the small spec diff before implementation. No conflicting rule remains for the two chosen quest outcomes or combat clock. This future task needs authorization to amend SPECS; this planning session does not do so.

### Y04 — Make a normal fresh run reach the opening through creation

Owner: Yannick + agent. Estimate: 2 h. Week: 1. Depends on: Y03.

**Done:** Reuse the title and creation screens. Ensure the public demo starts there rather than through QUICK_START, with selected traits passed into the opening and normal Continue behavior preserved.

**Check:** Start fresh, allocate traits, meet the fairy, then quit and Continue after resting. Check both French and English; debug quick launch remains a separate development path.

### Y05 — Add a development launcher for a fresh Cinderworks test run

Owner: Yannick + agent. Estimate: 3 h. Week: 1. Depends on: —.

**Done:** One named scenario opens a playable run beside the works using anchors, with a separate test-save location. A normal run and its save are untouched; the launcher is absent from a release export.

**Check:** Launch the scenario twice and get the same initial state. Rest in it, return to the normal run and verify the original save is unchanged.

### Y06 — Jump between named test locations

Owner: Yannick + agent. Estimate: 2 h. Week: 1. Depends on: Y05, Y00.

**Done:** In development, select an existing place/anchor to move the player there through the simulation's event path. Cover the fairy clearing, Brindle ruins and works interaction/viewing spots without typing coordinates.

**Check:** Jump to each location, walk and interact there, then replay the test log and verify the same final position. Invalid anchors produce a useful error.

### Y07 — Add before-choice and both after-choice scenarios

Owner: Yannick + agent. Estimate: 2 h. Week: 3. Depends on: Y05, Y18.

**Done:** Three named, playable quest scenarios: before resolution, workers' outcome, management's outcome. Produce their state through the accepted event/setup path, not direct writes from the view.

**Check:** Load each twice, compare the visible state and journal, then continue playing. Replays agree; loading an outcome does not accidentally apply its effects twice.

### Y08 — Resolve one deterministic fight independently of the screen

Owner: Yannick + agent. Estimate: 4 h. Week: 1. Depends on: Y03.

**Done:** Introduce only the fight state/events needed for two combatants, an attack, damage, defense and a result. Advance through the simulation; world time pauses during the fight and resumes afterwards.

**Check:** Headless alternative check: replay identical inputs and compare health, result and world tick; different advance chunk sizes must agree. This foundation is not yet a playable fight.

### Y09 — Play the first fighting-screen candidate

Owner: Yannick + agent. Estimate: 3 h. Week: 1. Depends on: Y08, B04, Y05.

**Done:** Using the brother's prototype assets, move and strike a stationary opponent in the real-time fighting screen. One attack has a readable reach and recovery; health changes are visible.

**Check:** From the test launcher, approach, attack in range, miss out of range and try holding the button. Damage follows the defined cadence rather than render rate.

### Y10 — Give the opponent one readable attack and let the player defend

Owner: Yannick + agent. Estimate: 3 h. Week: 2. Depends on: Y09, B05.

**Done:** One opponent approach/attack behavior and one defensive action. Its anticipation, hit and recovery are driven by the fight state, not scene timers deciding outcomes.

**Check:** Avoid or defend against the signalled attack, then punish its recovery. Repeat with slower rendering and verify the action timing and results remain consistent.

### Y11 — Try one alternative combat approach with the same encounter

Owner: Yannick + agent. Estimate: 3 h. Week: 2. Depends on: Y10.

**Done:** At this session, choose the contrasting approach with Yannick, as he requested. Reuse the same combatants, stakes and available assets; constrain this to an experiment, not a second production combat system.

**Check:** Play the same encounter in both candidates. Note control mistakes, whether attacks/defense are understood, and which version the two brothers prefer. If a useful comparison cannot fit, re-scope the experiment before building.

### Y12 — Choose the demo combat approach by playing it

Owner: Yannick + agent. Estimate: 1 h. Week: 2. Depends on: Y11.

**Done:** Joint review with the brother, whose hour is also budgeted as B06. Record the chosen candidate and the small demo move set; the working budget assumes repositioning, an attack, defense and one additional attack.

**Check:** Both brothers play the same trials and give reasons for the choice. Retain findings from the rejected candidate; no final combat-art commission precedes this decision.

### Y13 — Enter a fight from the world and return its result

Owner: Yannick + agent. Estimate: 3 h. Week: 2. Depends on: Y12.

**Done:** A world interaction enters the selected fight and submits one outcome on return. Connect victory and defeat to the semantics agreed in Y01, including the existing rest/checkpoint policy.

**Check:** Win once and lose once from the same starting scenario. Return to the correct place/checkpoint, with correct health and facts; world time resumes and no outcome is duplicated.

### Y14 — Teach the chosen controls through one practice encounter

Owner: Yannick + agent. Estimate: 2 h. Week: 2. Depends on: Y13.

**Done:** Short French-first prompts cover movement, attacking and defense as the player tries them. The practice encounter can be restarted or left; completing it is not an arbitrary quest-unlock flag.

**Check:** A player unfamiliar with the controls performs the three actions without oral coaching. Leave and return, and check that the quest remains reachable.

### Y15 — Let the player discover the dispute through two sources

Owner: Yannick + agent. Estimate: 2 h. Week: 2. Depends on: Y02, Y03.

**Done:** Implement the agreed opposing accounts and one inspectable piece of evidence at an anchor. The fact needed to act has at least two sources, and every line stands on its own.

**Check:** Approach management first in one run and workers first in another; obtain the actionable fact in both orders. Remove one source in a test and verify the surviving route.

### Y16 — Secure management's wage agreement and call the shift back

Owner: Yannick + agent. Estimate: 2 h. Week: 2. Depends on: Y15, Y13.

**Done:** Implement the reviewed Y01 path: get the foreman's wage commitment, take the terms to the workers and perform the agreed return-to-work action. The bell in the scene proposal is one candidate for that physical action. Record the management resolution through deeds/facts; no new quest store.

**Check:** Start before the choice, perform the action and observe the resolution fact/journal entry. Dialogue alone must not silently auto-select this side; re-entering cannot farm the act.

### Y17 — Back the walkout and stop the works

Owner: Yannick + agent. Estimate: 2 h. Week: 2. Depends on: Y15, Y13.

**Done:** Implement the reviewed Y01 path: corroborate the workers' safety case, deal with the guard intervention by fighting or the agreed peaceful route, then perform the shutdown action. Workers' victory stops production; it does not introduce worker-run production. Preserve an alternate path if an involved NPC is unavailable.

**Check:** Resolve for the workers in a fresh run and confirm the result. Test the surviving path if an involved person is unavailable; repeating the action does not duplicate credit.

### Y18 — Make each resolution change the works and the kingdom once

Owner: Yannick + agent. Estimate: 2 h. Week: 3. Depends on: Y16, Y17.

**Done:** Apply the agreed ownership, steel-supply and human-cost effects once as facts and derived events. Workers' victory stops this works' production and wages; management's resolution keeps production and wages while its human cost remains. Use the agreed operation/steel mapping and existing quantities; no third production outcome is included.

**Check:** Compare both resolutions to the initial state and replay each log. Verify the effects at a full starting quantity too: no claimed increase beyond the ceiling and no invented cause in the journal.

### Y19 — Make workers and management acknowledge the result

Owner: Yannick + agent. Estimate: 2 h. Week: 3. Depends on: Y18, Y02.

**Done:** Add the outcome-specific greeting/reply for one worker and one management voice, in French and English, plus the brief journal explanation agreed in Y01. Explain safety, wages and the crown's steel using the actual outcome; the cost must be intelligible without consulting a debug number.

**Check:** Talk to both people before and after each outcome. Their lines fit what happened, reveal the trade-off and do not require reading earlier dialogue in a particular order.

### Y20 — Show the factory working or stopped in 3D

Owner: Yannick + agent. Estimate: 3 h. Week: 3. Depends on: Y18, Y23.

**Done:** Connect the accepted quest state to the visual checklist agreed with the brother in B01/Y01 and delivered through B15/B16/B18. Reuse the existing active/cold furnace effects and bind each agreed element to the simulation's production/outcome state. The view reads simulation state; the graphics are the brother's. This task belongs with the owner of the relevant window/ingestion files. Basic kingdom feedback is covered by Y18/Y19, with no second consequence scene.

**Check:** Perform each resolution from the pre-choice scenario, then walk from the inhabited quarter to the production area. Compare the agreed elements against all three columns of the visual checklist. Management keeps production active; workers' victory stops it visibly. Collision and visible objects agree. A debug preview or journal entry alone cannot prove the quest causes the shutdown; Y21 checks the same visual state after save/load.

### Y21 — Keep quest consequences across save/load and combat defeat

Owner: Yannick + agent. Estimate: 2 h. Week: 3. Depends on: Y18, Y13.

**Done:** Exercise the existing rest/save/replay path after each resolution and the checkpoint policy on defeat. Fix only failures this new quest/fight integration exposes.

**Check:** Resolve, rest, quit and reload both outcomes; compare ownership, supplies, NPC responses and visuals. Lose from a saved pre-fight state and verify the specified rollback with no duplicate effects.

### Y22 — Make the opening lead intelligibly to the dispute

Owner: Yannick + agent. Estimate: 2 h. Week: 3. Depends on: Y04, Y15, Y02, Y23.

**Done:** Write and connect the short opening-to-works clue using the opening agreement from Y03 and voices from Y02. Let the player talk to the fairy, view the destroyed Brindle village and understand why to walk to the existing steelworks town. Use the locations checked in Y00/B01 without requiring a new town or a quest-marker trail.

**Check:** Start as a new player, listen/read, and explain who harmed the village and why visiting the works is useful. Walk the actual delivered route; no debug teleport is needed.

### Y23 — Ingest the demo map and consequence-scene delivery

Owner: Yannick + agent. Estimate: 3 h. Week: 3. Depends on: B02, B03, B12, B13, B14, B15, B16, B18.

**Done:** Refresh the generated workshop copy and bake for the agreed delivery, then resolve anchors, quest-participant appearances and visual states through the ingestion contract. Do not edit the brother's project; prototype asset refreshes belong in their individual combat tasks.

**Check:** Run the required suites on both worlds and walk the demo route and both outcome arrangements. Existing unrelated map debt is reported; no new debt conceals a demo-path failure.

### Y24 — Produce an initial Windows build and identify its test machine

Owner: Yannick + agent. Estimate: 2 h. Week: 1. Depends on: —.

**Done:** Set up a repeatable Windows export of the current game using the required Godot templates; keep workshop source/editor tooling out of the public package. Identify who can test on an actual Windows machine before relying on release week.

**Check:** Build the archive and inspect its contents. It must not depend on the repository checkout. Record the Windows test host; a macOS run or headless CI is not Windows gameplay verification.

### Y25 — Play the integrated Windows build on Windows

Owner: Yannick + agent. Estimate: 2 h. Week: 4. Depends on: Y24, Y21, Y31, Y22, Y20, Y19.

**Done:** Use a freshly extracted archive on the identified Windows machine. Verify start, input, combat, both quest outcomes, save/Continue, audio and French/English text.

**Check:** Record the tested Windows version, build identifier, failures and screenshots. A missing Windows test host leaves this task open; do not replace it with an editor launch.

### Y26 — Make the demo's controls and text readable at the shipped window size

Owner: Yannick + agent. Estimate: 2 h. Week: 4. Depends on: Y14, Y19, Y31.

**Done:** Check prompts, keyboard labels, text boxes, combat health, pause and existing sound controls in French and English. Fix clipping/illegibility in the actual export; do not claim a full accessibility pass.

**Check:** Read the longest quest replies and combat prompts at the target window size, pause/resume mid-encounter, and verify visible control labels match the chosen inputs.

### Y27 — Observe a fresh-player run and turn failures into fix tickets

Owner: Yannick + agent. Estimate: 2 h. Week: 4. Depends on: Y25, Y26.

**Done:** Yannick arranges one tester unfamiliar with the quest. Watch without coaching; measure time, requests for help, combat retries, and whether they notice a world consequence.

**Check:** The tester can describe both sides, their choice and what changed. Every blocker becomes a small reproduction/fix item paid from the reserve; observing a failed run is not release approval.

### Y28 — Prepare credits and check the exported asset inventory

Owner: Yannick + agent. Estimate: 2 h. Week: 4. Depends on: B20.

**Done:** Verify the demo's shipped assets have the repository-required provenance/licence records and credited sources. Include required notices in the Windows package.

**Check:** Compare the actual package inventory to the records and open its credits. Missing provenance is unresolved work, not a statement that all 3D assets are already cleared.

### Y29 — Produce the demo release candidate for Yannick to review

Owner: Yannick + agent. Estimate: 3 h. Week: 4. Depends on: Y25, Y26, Y27, Y28, B21.

**Done:** After blocking fixes, run --all and --procedural --all, export Windows and write exact install/play/check instructions. Confirm development scenarios are absent while normal creation and Continue work.

**Check:** From the candidate archive, complete the opening, combat and each quest outcome and reload a save. Report test counts, demo-path defects and remaining debt. Deliver the artifact locally; Yannick publishes.

### Y30 — Add the additional attack agreed for the demo

Owner: Yannick + agent. Estimate: 3 h. Week: 3. Depends on: Y12, Y13.

**Done:** Implement one second attack with a meaningful difference in reach, commitment or recovery; reuse the same outcome and input pipeline. If Y12 selects a different move set, replace/re-estimate this ticket before coding.

**Check:** Against the same opponent, demonstrate when each attack succeeds and when its recovery exposes the player. Holding either input cannot bypass recovery or duplicate hits.

### Y31 — Use the brother's final demo combat poses and tune readability

Owner: Yannick + agent. Estimate: 3 h. Week: 3. Depends on: Y10, Y30, B07, B08, B09, B10, B11.

**Done:** Map combat states to the delivered movement, attack, defense, hurt and defeat visuals for player and one opponent. Adjust timings only against repeated playable trials.

**Check:** Play attack, defense, interruption, victory and defeat trials. What the player sees matches when damage/defense is active, and the selected combat remains playable at the tested export performance.

## The brother's work items

### Shared visual checklist — before the choice and after each outcome

**Confirmed by Yannick on 2026-09-15:** the existing Brindle → inhabited quarter →
production-area route is sufficient for the demo, and the map/assets must show
the consequences of the player's choice. The castle is outside the demo's art
requirements. This checklist makes that work explicit for the brother; his exact
visual recipe, asset effort and location choices remain to be agreed.

| Place / visible element | Before the choice | Management outcome | Workers' outcome | Work and acceptance |
|---|---|---|---|---|
| Brindle and the route into the inhabited quarter | Existing ruined village and walk to the settlement | Same route remains available | Same route remains available | B01/B02: confirm the path and camera; no new Brindle transformation is required for this dispute |
| Inhabited quarter and meeting spots | Existing homes, shared spaces and recognizable participants | Outcome response explains continued wages and dangerous work | Outcome response explains safety and lost wages | B12–B14/B18 with Y19: stage readable speakers/status; buildings can remain as delivered |
| Production fire, furnace glow and smoke | Works visibly operating | Works visibly operating or resuming | Production fire/glow/smoke visibly cease | B15/B16 with Y20: reuse active/cold effects; identify the exact production emitters affected, preserving unrelated domestic fires |
| Other production activity, if shown | Working poses/moving equipment agree with active production | Activity agrees with continued production | Any depicted activity that implies continued production must stop | B01 lists what actually exists; B15/B16 specify only needed variants. New machinery or worker animations are not automatically commissioned |
| Entrance/status presentation | Unresolved dispute | Status agrees with management's outcome | Status agrees with the stoppage | B18 with Y19/Y20: agree sign or speaker staging and keep words in localized content |
| Crown steel | Existing supply | Supply continues under the agreed rules | Actual loss of crown steel | Y18/Y19: simple explanation is sufficient; no castle, convoy or second kingdom scene is required |

For each affected element, B01/Y01 must record **existing asset/site ID, what stays,
what changes, whether an asset is missing, who delivers it, and the viewing spot**
in [the walkthrough sheet](DEMO_WALKTHROUGH.md). The mandatory result is visibly
operating versus stopped production. The brother chooses the concrete visual
solution with Yannick; the table does not require a second complete town or a
demolished factory. Management may preserve the initial working appearance.

The brother owns asset creation and staging. Yannick and the assigned integration
agent connect these to the actual quest state through Y18/Y20/Y23. An exported
asset or workshop preview alone does not close the playable result. Deliver each
usable change for integration as it becomes available.

B21's shared review uses **six matched views**: one inhabited-quarter view and one
production-area view in each of the three states. The ordinary game camera must
make operating versus stopped production recognizable. Y20 proves the quest causes
the change; Y21 checks persistence; the Windows play check confirms it in the demo
build. List any missing cue as a task, rather than accepting text-only local impact.

This checklist refines existing B01/B15/B16/B18/B19/B21 and Y20/Y21 work. It adds no
assumed art hours to the provisional budget. If the agreed missing pieces exceed a
session, split and re-estimate them with the brother before implementation.

### B01 — Confirm the journey's use of the existing map and town

Owner: Brother. Estimate: 2 h. Week: 1. Depends on: Y00.

**Done:** Review Y00's walked route and candidate locations against the delivered Brindle and village_acierie scenes. Confirm the ruined-village → inhabited-quarter → production-area sequence and existing spaces suitable for each beat. Review the shared visual checklist, identifying existing affected elements and only missing route/presentation pieces. Preserve stable IDs and choose the two comparison viewpoints; exact quest actions follow in Y01.

Record the brother's actual review in [DEMO_WALKTHROUGH.md](DEMO_WALKTHROUGH.md), including changes to the proposed art effort. An agent's prepared sheet does not close B01.

**Check:** Match the location sheet to the workshop scenes and captured game views. Mark each proposed spot usable or needing a named fix; no new town, camp or royal receiving yard is required. This author/map review is the alternative check for the sheet, with fixes verified in game later.

### B02 — Make the opening-to-works route legible

Owner: Brother. Estimate: 3 h. Week: 1. Depends on: B01.

**Done:** Inspect and reuse the fairy/ruins/steelworks approach. Fix only B01's confirmed presentation or route gaps with the brother's terrain, paths and landmarks; if the existing stretch already works, record the check and return unused time to reserve.

**Check:** From the opening, walk to the works without developer directions and see every obstacle that stops the player. Provide the delivery for ingestion.

### B03 — Deliver the quest's one evidence/action prop

Owner: Brother. Estimate: 3 h. Week: 1. Depends on: B01, Y01.

**Done:** Reuse an existing piece for the evidence/action agreed in Y01 where possible; create a prop only if the mapped scene needs one. Give it a stable ID and an approach the player can stand at. The proposed bell is not a required new asset.

**Check:** In the workshop, approach and see the prop at the game's camera scale; its collision does not cover the interaction approach.

### B04 — Provide reusable combat prototype assets

Owner: Brother. Estimate: 3 h. Week: 1. Depends on: —.

**Done:** Provide minimal player/opponent representations and a floor/background from the brother's style or plain blocks, usable before the final combat presentation is chosen.

**Check:** Open the prototype assets in Godot and distinguish the two combatants at the intended scale. These are experiment assets, not a commitment to final animation requirements.

### B05 — Give the prototype attack a visible anticipation pose

Owner: Brother. Estimate: 2 h. Week: 2. Depends on: B04, Y08.

**Done:** Supply one obvious anticipation/attack distinction for the simple opponent, compatible with Y10's state timings.

**Check:** Watch the same attack start repeatedly and identify its warning before the hit. Reuse this visual in the comparison wherever possible.

### B06 — Compare the combat candidates with Yannick

Owner: Brother. Estimate: 1 h. Week: 2. Depends on: Y11.

**Done:** Joint session also budgeted in Y12. Record preferred feel, animation needs and scope of the demo's final move set.

**Check:** Play both candidates, then agree the work needed for the chosen one before beginning B07–B11.

### B07 — Deliver the player's demo combat movement/facing

Owner: Brother. Estimate: 4 h. Week: 2. Depends on: Y12, B06.

**Done:** Using the selected format, produce the bounded movement/facing set the prototype needs, reusing the existing traveller where suitable.

**Check:** Move and turn through Y13's fight. The player remains recognizable and correctly grounded; the approved pose/frame list fits this session or is split before work starts.

### B08 — Deliver the player's attack and defense poses

Owner: Brother. Estimate: 4 h. Week: 2. Depends on: B07.

**Done:** Produce the attack/defense assets from the move set chosen in Y12; agree the exact frame list first.

**Check:** Play each action and identify anticipation, active action and recovery. If the required animation set exceeds four hours, split it and re-budget rather than call a partial set finished.

### B09 — Deliver the player's hurt and defeat poses

Owner: Brother. Estimate: 3 h. Week: 2. Depends on: B07.

**Done:** Finish the selected presentation's hurt/defeat states without adding new combat mechanics.

**Check:** Take a hit and lose in the playable encounter. The player can recognize both states and the checkpoint transition is visually understandable.

### B10 — Deliver one opponent's movement and attack

Owner: Brother. Estimate: 4 h. Week: 2. Depends on: Y12, B06.

**Done:** Complete one reusable opponent presentation suited to the workers' dispute, using the agreed role and selected format.

**Check:** Approach and fight it repeatedly; facing, reach and warning poses are readable from both relative positions.

### B11 — Deliver the opponent's defense, hurt and defeat poses

Owner: Brother. Estimate: 3 h. Week: 3. Depends on: B10.

**Done:** Complete the remaining states needed by the chosen one-opponent encounter.

**Check:** Defend, hit and defeat it in the selected combat window; each state is distinguishable without debug overlays.

### B12 — Make the management speaker recognizable

Owner: Brother. Estimate: 3 h. Week: 1. Depends on: Y02.

**Done:** Deliver the approved management character's world appearance using the brother's character family and stable actor ID.

**Check:** Find the management speaker at the works without checking the debug NPC list; compare with the other quest participants at the normal camera scale.

### B13 — Make the workers' speaker recognizable

Owner: Brother. Estimate: 3 h. Week: 1. Depends on: Y02.

**Done:** Deliver the approved worker representative's world appearance, reflecting the agreed character rather than an invented biography.

**Check:** Find the workers' speaker beside the same works and distinguish them from management and generic workers.

### B14 — Make the third quest participant recognizable

Owner: Brother. Estimate: 3 h. Week: 1. Depends on: Y02.

**Done:** Deliver the third named participant selected in Y02. If the agreed quest only needs two, remove this task and keep the time as reserve; do not invent a person to fill a budget row.

**Check:** Identify that person in the actual dialogue scene and check their silhouette/appearance against the approved role. Names remain content, not text baked into an asset.

### B15 — Verify the working-factory presentation for management's outcome

Owner: Brother. Estimate: 3 h. Week: 3. Depends on: Y01, B01.

**Done:** Complete the management column of the shared visual checklist using the delivered working forges and agreed staging. Provide the stable IDs and intended active states to the integration owner. Check continued production is legible at the selected viewing spot; Y19 explains wages and the remaining danger. Reuse the initial working appearance where it already communicates the result.

**Check:** From the normal camera identify the operating factory, then compare it with the workers' stopped outcome. Management may preserve the initial appearance; the player must still understand the resolution from their action and the response.

### B16 — Verify and finish the visible factory shutdown

Owner: Brother. Estimate: 3 h. Week: 3. Depends on: Y01, B01.

**Done:** Complete the workers column of the shared visual checklist. Inspect the existing cold-forge/furnace effects first and finish only the missing shutdown cues agreed in Y01. Supply the affected asset IDs and their stopped states to the integration owner. Production fire/glow/smoke must visibly cease, and any depicted work must agree with the stoppage. Additional idle-worker staging is optional; Y19 explains lost wages. Reuse delivered pieces.

**Check:** Compare the initial, management and workers views side by side. Point to the cessation of production in the scene; Y19 explains the lost wages.

### B18 — Deliver the works' entrance status prop

Owner: Brother. Estimate: 2 h. Week: 3. Depends on: B01.

**Done:** Provide the sign/speaker staging agreed for the demo entrance and its checklist states before resolution, after management's outcome and after the stoppage. A single existing object/person can serve all states through localized text; no new graphic variant is required unless agreed with Yannick. Keep localized words in content rather than baked into a French-only graphic.

**Check:** Approach the entrance at normal camera distance. The status can be read through the agreed interaction/HUD, with a visible object/person anchoring it.

### B19 — Remove occlusion/readability problems from the demo views

Owner: Brother. Estimate: 2 h. Week: 3. Depends on: B15, B16.

**Done:** Adjust the agreed demo scenes so the player, interaction spots and consequence elements remain visible from the game camera in all three checklist states. Check the inhabited-quarter → production-area approach and the two agreed comparison viewpoints.

**Check:** Repeat the opening, interaction and both outcome camera checks in the integrated game; record any remaining obstruction for a fix ticket.

### B20 — Deliver provenance records for the demo art

Owner: Brother. Estimate: 2 h. Week: 4. Depends on: B07, B08, B09, B10, B11, B15, B16.

**Done:** Supply the existing required origin/licence information and credit names for every new demo asset delivered by the brother.

**Check:** Yannick can match each delivered asset group to its record for Y28. Missing information remains an open item.

### B21 — Review the final integrated demo visuals

Owner: Brother. Estimate: 2 h. Week: 4. Depends on: Y20, Y31, B19.

**Done:** Review the actual candidate game with Yannick, including creation, fairy, ruins, inhabited quarter, both factory outcomes, combat and French/English status presentation. Compare every agreed visual element with the shared checklist; a town that looks identical while production continues after a workers' victory is unfinished demo work.

**Check:** Capture the six matched views: inhabited quarter and production area, each before resolution and after both outcomes. Both brothers can identify working versus stopped production without debug overlays. Record the tested game revision and remaining blockers by location/state. Fix work comes from the reserve; workshop-only screenshots do not close this item.

## Release proof and what follows

The demo candidate must let a fresh player create a character, talk to the fairy,
see the destroyed village, walk to the existing steelworks town, engage with both
sides of the dispute, use combat and finish the quest. They must understand the
basic kingdom impact and see the stopped factory after a workers' victory. A
development run must reproduce the other outcome. Both must survive the agreed
rest/save/reload policy. Crown steel loss must be real, with simple NPC/journal
feedback sufficient for this demo; local shutdown must be visible in the world.

The earlier proposed B17 receiving/loading scene is deferred from this demo. Its
four-hour estimate returns to the brother's reserve. IDs after B17 are retained
so handoffs remain stable; the 52 active cards comprise 32 Y items and 20 B items.
Richer downstream kingdom visuals belong in the full-v1 planning pass.

Review footage/screenshots and the Windows test record alongside automated results.
Record remaining unrelated map debt honestly. Any missing art or disconnected path
needed by this demo is unfinished demo work, even if a historical test labels a
broader-map claim as debt. Debug tools, unreviewed placeholders in required demo
scenes, or contact damage posing as combat do not satisfy the candidate check.

After the demo, keep its quest, combat and consequence systems in full v1. The next
planning pass must produce equally small tickets for the other selected locations,
their authored cast/quests, broader combat/equipment, king confrontation, endings
and full-game integration. The remaining audit decisions must be reconciled rather
than assumed solved by the demo. This is a detailed demo backlog, not yet a detailed
or feasibility-validated backlog for the entire three-month game.
