# Original v2 vision — specification audit and handoff

Date: 2026-09-15. Author: Codex. Requested by Yannick.

## Status and how to resume

This records a read-only comparison requested by Yannick, then persisted at his
request, followed by explicitly attributed planning clarifications. It is an audit
and a set of recommendations, **not an approved redesign, release plan, or amendment
to SPECS**. Only entries under "Confirmed planning clarifications" are confirmed;
saving the findings does not approve the recommendations.
No spec or source file was changed by the audit. No gameplay verification was run
for it; statements about delivered features below are attributed to delivery notes.

For Claude Code or another agent resuming:

1. Follow the repository's working agreement and reading order first.
2. Read this document rather than repeating the audit. Consult only the relevant
   SPECS sections when resolving an individual finding.
3. The current targets are a public demo in a few weeks, targeting one month, and
   the full playable v1 in three months. The demo is the opening, one quest, visible
   world consequences and combat. See "Current milestone brief" and the final
   section; do not budget three months for the one-quest demo. The quest is now
   selected: a workers' dispute at the Cinderworks. The public demo targets Windows
   only. [DEMO_WORK_ITEMS.md](DEMO_WORK_ITEMS.md) holds the draft session backlog.
4. Do not interpret this handoff as permission to implement changes, rewrite the
   specs, or reopen every documented decision. Ask about unresolved choices and
   conflicts; identify later decisions already attributed to Yannick.
5. The brother owns graphics and `prototypes/`. The earlier permission to take over
   ingestion files was for the ingestion task, not blanket permission for future work.

The audit used [SPECS](SPECS.md), [v2 intent](history/V2_INTENT.md),
[V2 delivery](V2.md), [V3 delivery](V3.md), the relevant
[migration agreement](MIGRATION_3D.md) sections, and [CLAUDE.md](../CLAUDE.md).
Section titles below are lookup references; delivery claims are dated context, not
fresh measurements. The current task did not audit source implementation.

## Confirmed planning clarifications

| Date | Question | Yannick's answer | What remains open |
|---|---|---|---|
| 2026-09-15 | What does "first release" mean? | "first game means complet small game that can be deliver as public demo." Initial wording, subsequently clarified into two milestones below | Do not retain the earlier interpretation that the demo and full game are one three-month deliverable |
| 2026-09-15 | Is combat required for this public demo? | "for small game and public demo combat system is expected of course". Combat is required | The assistant's question also bundled in the king fight. Its earlier interpretation must now be read against the narrower demo scope below; do not silently require the full campaign ending in the demo |
| 2026-09-15 | Does the fighting-game description still apply? | "We can keep taht description for now, but at the time of combat style we will try differetn appraoch. For now one we will try is real-time fighting screen inspired by Street Fighter and Budokai." Keep this as an initial prototype candidate and compare approaches when working on combat style | The final style is not chosen. Other approaches, comparison criteria, prototype time budget and graphics requirements remain to be defined |
| 2026-09-15 | What belongs in the demo, and when are the releases? | "demo will be start of the game, one quest, allowing player to see world impact and how the world change + combat." Demo in a few weeks, targeting one month; full playable v1 in three months. "I dont want the demo with one quest in 3 month.I want taht in few weeks." | The two milestones and combat inclusion are settled; quest/location and platform are answered in subsequent rows |
| 2026-09-15 | Which demo location, and should planning become work items? | "Agreed with Cinderworks, but we then need to transalte that as I explain into work item". Cinderworks is selected; prepare tasks and continue the interview for unresolved decisions | Exact quest actions/outcomes and estimates still need review, not permission to start implementation |
| 2026-09-15 | Which Cinderworks conflict? | "A workers' dispute inside the works: support the workers or the management." | No forest-camp quest is planned for the demo; the workers' outcome is answered below |
| 2026-09-15 | Which public demo platforms? | "Windows only" | Actual Windows test host and repeatable export are early backlog tasks; development can continue on macOS |
| 2026-09-15 | What does a workers' victory mean? | "Production stops: the workers stop risking their lives, but lose their wages; the crown loses steel." | The exact dispute demands, player actions and encounter script remain a design-review task. Continued worker-run production is not the chosen outcome |
| 2026-09-15 | How does the demo fit the delivered map, and what is its journey? | "We need to map taht to the map and town already built by my brother". Player creation → fairy conversation → viewing the destroyed village → walking to the steel factory village → helping one side → combat → kingdom impact → visible factory shutdown for workers' victory | The two sides remain workers and management, not two new physical camps. Walk and map existing spaces before fixing quest actions; no new town is requested |
| 2026-09-15 | How much kingdom feedback does the demo need? | "Say impact on the kingdom (for the demo very basic accepted). And steel factory stop to roks with visual consquence." | Basic kingdom feedback is sufficient; visible local shutdown remains required. Proposed minimum: actual crown steel loss explained by a short NPC/journal response. A separate receiving-yard/capital transformation is deferred |

**The latest milestone clarification governs.** The Windows public demo is the
beginning of the game on the brother's existing map: creation, fairy, ruined village,
walk to the steelworks town, the Cinderworks workers' dispute and combat. Kingdom
feedback may be basic, but the local shutdown must be visible. Workers' victory
stops production, removes its danger and its wages,
and costs the crown steel. The full playable v1 is the three-month goal. Do not
ask for a demo playtime target before planning this agreed content, or treat one
quest as the entire three-month scope.

**Combat is required in both milestones. Do not ask whether to include it again.**
Yannick's answer supersedes the earlier combat deferral for release planning; the
historical audit findings and current implementation status below remain accurate
as records of what was specified and delivered before this clarification. It does
not authorize implementation. Combat must not remain a final optional phase in the
new release plan.

**Combat style is provisional, with an initial candidate agreed.** For planning,
retain the real-time fighting-screen description inspired by Street Fighter and
Budokai. When combat-style work begins, try different approaches and choose after
playing them. Do not turn this provisional direction into a final commitment to
side-on 2D, a camera, an input scheme or a particular arena implementation. Do not
ask Yannick to settle the final style now; he has explicitly deferred that choice
to experimentation. Plan the comparison early, alongside the authorial foundation
and testing tool, and agree visual requirements with the brother before committing
to production combat art. This clarification authorizes the planning direction,
not starting code or graphics work in this audit/planning session.

## Current milestone brief

These are the current requirements from Yannick's answers, rather than new design
proposals. Calendar dates are working translations of "one month" and "three months"
from this discussion on 2026-09-15, not separately agreed launch appointments.

| Milestone | Timing | Required experience |
|---|---|---|
| Public demo | A few weeks, targeting one month; working date around 2026-10-15 | Windows only: creation → fairy → destroyed village → walk to the existing steelworks town → workers/management quest with combat → basic kingdom feedback and visible factory shutdown for workers' victory |
| Full playable v1 | Three months; working date around 2026-12-15 | The full intended small game: opening, multiple local adventures and world consequences, combat, confrontation and resolutions. The detailed release inventory still needs reconciliation with the audit |

The demo is an early portion of the full game. Recommended delivery approach:
build its quest, combat foundation and consequence systems so they remain in v1.
The latest demo description does not require the whole campaign or its ending.
Plan the tutorial and a quest fight for the demo; retain the king confrontation
and fight in the full-v1 scope. That is a planning interpretation of the new
boundary, not a decision to remove existing access to the king or to forbid showing
him in the demo.

The repo already uses "v1", "v2" and "v3" for earlier internal development stages.
Here **full playable v1 means Yannick's future three-month release milestone**,
not the historical internal build already labelled delivered in SPECS.

Capacity remains 24 hours per person per week, 48 combined. Four working weeks give
96 hours each, 192 combined, including design, art, implementation, integration,
review and fixes. That four-week calculation is a budgeting baseline, not an exact
calendar-month total. Claude Code and Codex support the work; do not count them as
two extra human art/design schedules or assume review and playtesting disappear.
Do not infer permission to spawn agents from the mention of using both tools.

The one-month target requires the demo route and its art, quest and combat to be
developed together. The whole kingdom's final character dossiers and final art
cannot be prerequisites for showing this opening quest. Establish the shared
setting and relevant cast first, then deepen other places for the full release.

## Vision being compared

This is a summary of Yannick's original message, not a verbatim transcript.

- Finish a first release within three months. Yannick and his brother each have
  four hours per day, six days per week: 24 hours each, 48 combined per week.
- The brother owns the map and graphics; Yannick owns systems, content and design.
- Break work into tasks achievable in one session. Each needs a definition of done
  and an in-game check, or an alternative test if it cannot be checked by playing.
- Define NPCs, roles, relationships and lore early, with an explicit dependency
  order. Address English-sounding placeholder names and AI-like dialogue.
- Make the simulation assessable through play. Provide a testing mode for moving
  around the map and loading situations, including confronting the king with all
  weapons or all NPCs supporting the player. Ask about undecided design choices.
- Phase 1: player creation, fairy, world context, first combat tutorial, and a clear
  goal of killing, deposing or replacing the king for destroying village and forest.
- Phase 2: organic play, potentially five minutes or ten hours. Industry brings
  jobs, wealth, food and defensive weapons, but also dispossession, pollution,
  deaths, war and mercenaries. Choices directly affect the king and kingdom.
- Phase 3: confrontation. Earlier actions affect endings and the visible condition
  of the capital, castle and king's fall.
- The kingdom starts rich and strong. Each meaningful place contributes something,
  tracks status and allegiance, and has a substantial handcrafted quest with
  alternate outcomes. Local state supplies inputs to kingdom prosperity and power.
- The farm example: consolidated estates replaced villages; one employer and
  controlled prices coexist with food security. Returning land to smallholders
  reduces food delivered elsewhere, producing higher bread prices or starvation.
- The factory example: choose between supporting production and siding with its
  opponents, potentially through fighting. Production affects military strength.
- WoodTown illustrates wood supporting houses and population. These English town
  names and particular encounters are rough examples, not mandatory literal content.
- Outcomes visibly change locations: destroyed factories, large estates becoming
  smaller farms with different crops. An entrance sign or person summarizes local
  status. Changes to the capital reflect the kingdom's changing wealth and strength.

## Overall finding

The specs preserve the central idea, but are not a complete, faithful translation
of this vision. They retain morally ambiguous choices and systemic consequences,
while narrowing local adventures and adding strong rules about outcomes, freedom,
fiction and presentation. Some are explicit later decisions, some proposals, and
some incompletely specified requirements.

The strongest alignment is the connection between places and royal power: food,
steel, army and finance; supporting or opposing the crown; costs borne by named
people; changing prices, dialogue, local appearance and castle condition. The three
phases are explicit. See SPECS §2, §3 "The four places", §8's quantities and
"A change the player cannot perceive is identical to no change".

## Gaps and changes

| ID | Original requirement | Specification or delivery finding | Assessment and reference |
|---|---|---|---|
| G01 | First release in three months at 24 hours/week per person | Roadmaps describe completed technical phases and remaining 3D work, without a capacity-based release schedule or agreed first-release boundary | Missing planning requirement. "v2 delivered" does not establish completion of the intended first release. SPECS §17–18 |
| G02 | One-session tasks, each with playable proof and instructions | Phases have proofs and the working agreement requires tests, but there is no corresponding release backlog of session-sized tasks with individual acceptance checks | Verification principle present; requested task-level planning absent. SPECS §18 |
| G03 | Navigate anywhere and play selected situations | Documented tools skip days, locate NPCs, show the map and take screenshots. Freeing places is available for a screenshot frame | No documented playable scenario picker, live teleport workflow, equipment presets or all-support confrontation preset. V3 "The debug tools"; CLAUDE.md development tools |
| G04 | Opening clearly establishes the king as the target | The fairy must not name the king or explain where to go; her request is "save us". The opening deliberately points toward serving either side | Material narrative change. Ambiguity fits the vision, but withholding the initial target changes the stated opening. SPECS §4 "The opening", §5 "The opening points two ways" |
| G05 | First combat tutorial and eventual king fight | Tutorial means creation, fairy and walking out. Combat is explicitly excluded from v2 and current v3 delivery | Deferred requirement, not delivered combat. Later deferral is explicitly attributed to Yannick. SPECS §10; §18 v1 conclusion and v2 roadmap; V3 omissions |
| G06 | Every meaningful location contributes and has a substantial quest | Four places receive the complete state treatment: Wide Acres, Cinderworks, Muster, bank. Harrowgate and Greyhold are deferred. Wood is absorbed into Cinderworks fuel | Scope reduction requiring a clear release boundary. The literal example town names need not survive. Removal of a separate sawmill village is a documented later decision. SPECS §3; MIGRATION_3D §9 |
| G07 | Substantial handcrafted local adventures lead to different outcomes | A decisive outcome is generally reading a document locally or its corresponding spoken crown-supporting act. Other deeds affect quantities without changing ownership | Largest gameplay narrowing. The specs establish an outcome mechanism, not the substantial adventures described. A fact-based quest representation is compatible with rich quests; it does not provide their content. SPECS §3 "The decisive change" and Phase C delivery; §8 place changes |
| G08 | Supporting production makes the kingdom stronger/richer | Steel, treasury, bank confidence and army start at 100, their ceiling. Supporting them restores losses but cannot increase initial values; an act can still impose hardship at the ceiling | Added restriction on what prosperity means. A day-one loyal act can cost people without increasing production. SPECS §8 "A ceiling, found by building it" |
| G09 | Physical transformations: destroyed industry, redistributed land, varied crops | Smaller fields and altered factories are described, but each place is restricted to two variants. Delivery mainly removes fences/tents, extinguishes furnaces and darkens buildings | Partly specified, partly deferred. Varied crops and fuller reconstruction are not established as delivered. Destroyed and independently operated works are compressed into one free state. SPECS §4 ground states; §13 ground variants; V3 omissions |
| G10 | An entrance sign or person summarizes local status | Loyal/free/restored text exists; delivery is a HUD line while standing in the place. Signs are framed as potentially unreliable propaganda | Meaning partly preserved, physical presentation incomplete, reliability changed. SPECS §15 "The entrance sign" |
| G11 | Pollution, arms/defense versus war/mercenaries, wood for housing/population | Food prices, army strength, industry and forest loss have explicit mechanisms. Runoff is an illustrative cost; war/mercenary escalation and housing/population have no comparable specified chains | Original examples only partly translated. They need explicit inclusion or exclusion; generic hardship does not by itself establish these experiences. SPECS §8 quantities and "The cost has a face" |
| G12 | A confrontation produces different endings, including replacement | Endings trigger from world conditions and may make confrontation unnecessary. Taking the throne is a reading of Deposed plus high crown standing, rather than an explicit succession choice | Material change in agency. Equipment and allies are mentioned without complete designs for their part in the confrontation. SPECS §3 endings/throne; §11; §12 |
| G13 | Define authored identities, relationships and credible French before dependent content | Sheets, roles, relationship graph and French-first rules exist. Names remain placeholders; recent shared history is TBD. No explicit editorial approval checkpoint precedes downstream quests/art | Structural coverage, unfinished authorial work. Sentence-length tests cannot establish natural French or character distinction. SPECS §6; §5 recent history; §9 house style; §18 cast delivery |

The brief's potential ten hours of organic content also has no corresponding
content/playtime budget: SPECS §17 leaves playtime TBD. It is a range illustrating
freedom, not necessarily a promise to require ten hours, but the release plan must
say what amount of content it is funding.

## Additions beyond this brief

Absent from this particular brief does **not** mean never approved elsewhere. Some
entries have explicit attribution to Yannick. The audit does not revoke them.

| Addition | Consequence | Reference |
|---|---|---|
| Every NPC is killable; no progression flags gate actions; at least one ending always survives | Stronger design and testing commitments than "open world" alone | SPECS §1 |
| Every kingdom-changing act must cost someone; every reputation loss must have a positive counterpart | Mandatory symmetry is stronger than a request for moral ambiguity | SPECS §8 hard rules |
| Documents/information can be spent once, to one audience | Reading the grants in Harrowgate can permanently prevent using them to free the Acres | SPECS §3 Phase C delivery; §8 giving knowledge |
| Two states per place, no improvement beyond the initial ceiling | Collapses distinctions between independence, destruction and alternative prosperity | SPECS §3, §8; §20 decisions of 2026-09-13 |
| A mandatory two-day / 12-real-minute hold after a decisive allegiance act | Prevents both ambient reversal and the player's opposite act. Explicitly attributed to Yannick | SPECS §8 freeze; §20 |
| Resurrection, memory as its price, legal death, anti-magic church and ending-dependent memory restoration | Substantial added fiction and ending obligations | SPECS §5 |
| Six fixed traits, four faction ranks, occupation-based enemy tiers | Specific progression and balancing commitments | SPECS §10–11 |
| Separate side-on real-time fighting screen and no player spellcasting | A specific combat direction not implied by the brief. The current onboarding brief separately says not to assume the future screen's shape | SPECS §10; AGENTS.md ownership |
| Play continues after the ending, with changed authority and dialogue | Requires post-resolution behavior and writing | SPECS §5 endings |
| Strict writing constraints and no live model in delivered play | A particular response to AI-like writing; neither automatically proves editorial quality | SPECS §9; §18 cast/dialogue delivery |

## Conflicts and unreliable status information

1. **Forest conservation through loyal industry is inconsistent.** SPECS §5
   "The opening points two ways" promises that improving efficiency and settling
   wages can stop expansion while preserving the works. §3's local outcome says
   holding the works makes the wood shrink faster. The promised loyal conservation
   route lacks a clear, consistent mechanical definition. This is a spec finding,
   not a verified code bug.
2. **The proposed cut order deprioritizes the vision's visible consequences.**
   SPECS §17 proposes cutting castle visuals and free-state variants before several
   newly added rules. Signs and quantities alone do not fulfill the original physical
   transformation requirement. This cut order remains marked as a proposal.
3. **Approval, specification and delivery are mixed.** SPECS' introduction says
   AI-proposed sections still await approval despite being built. The historical
   v2 intent calls its interpretation settled. Neither establishes that every
   difference from the original message was individually approved.
4. **Historical assessments remain in the current source of truth.** For example,
   §8 "Can the twelve quantities carry these five?" describes missing relationships
   and couplings that later sections report delivered. The opening metadata also
   points to older delivery notes and an older debt count. Consult V3 for dated
   current-state claims; do not treat every open-question row as a current absence.
5. **Combat presentation needs reconciliation.** §10 still fixes a side-on 2D
   screen while the current working brief prohibits assuming its shape. A 3D world
   does not itself settle whether combat should be 2D, 3D or in a separate screen.

## What 3D changes, and what it does not

The four-place/document model already belongs to v2; it is not merely a consequence
of migrating to 3D. The migration agreement correctly lets content and systems
advance through anchors while the brother supplies map scenes and graphics.

V3's delivery notes on 2026-09-15 report:

- The delivered ironworks and bridges are ingested. Furnace/forge effects cool when
  the works is freed. This is an existing visible consequence.
- Full settlement art, real free-state scenes, entrance props and distinct faces
  remain incomplete. Everyone currently uses the brother's traveller sprite.
- Creation exists but is bypassed by `Screens.QUICK_START` for testing.
- Terrain slowdowns and music are switched off. These layers were not deleted.
- The works' visibility from the opening and travel targets require map/narrative
  reconciliation. Core behavior passing tests does not prove visual parity.

See V3 "What v3 built" and "What is deliberately not there", CLAUDE.md's testing
switches, and MIGRATION_3D §6.2 and §9. Mitigation should be agreed with the brother;
it does not authorize adding graphics or editing his project from this lane.

## Demo quest brief — Cinderworks and workers' dispute selected

**Selected by Yannick: the Cinderworks, with a workers' dispute.** The earlier audit
suggested the Wide Acres because it directly matches CornTown. The clarified
one-month target led to the Cinderworks proposal, which Yannick accepted: its
buildings/props are delivered, the opening already concerns it, and Halgrave/Sena/Ivo
already have roles. This does not approve all current writing or names. The Wide
Acres remains relevant to full v1. Workers' victory is now confirmed to stop
production, so the existing cold-furnace effect is directly useful. The lost wages
and the loss of steel to the crown must also be made perceptible.

Confirmed journey, with proposed implementation checks:

1. Create the player, meet the fairy, view the destroyed village and understand
   the immediate situation.
2. Walk to the steelworks town already built by the brother and learn both what
   it provides and whom it harms through the people involved. Review these
   characters' motives, relationships and French voices before writing the quest's
   final dialogue or commissioning their faces.
3. Investigate the workers' dispute and take a concrete action at the works, with
   a combat tutorial and a quest encounter. The exact demands, action and opponent
   are writing/design work still to do; this brief does not invent them as canon.
4. Resolve the quest in support of workers or management, with evidence informing
   the choice. Workers' victory stops production, removes its danger and its wages,
   and costs the crown steel. The current document-reading mechanism alone does not
   establish that a substantial quest has been delivered.
5. See the factory stop working under the workers' outcome; production continues
   under management. Reuse the existing active/cold furnace effects and finish only
   missing presentation needed to make this clear from the game camera.
6. Understand the basic kingdom consequence: the crown loses steel. Proposed
   minimum feedback is a short response from an affected person and/or the journal,
   tied to the actual simulation effect. A separate transformed receiving yard or
   capital scene is not required for this demo. Lost wages also need clear feedback.

The desktop map lookup in [DEMO_WORK_ITEMS.md](DEMO_WORK_ITEMS.md) identifies
`brindle` as the delivered ruins and `cinderworks` as the delivered `village_acierie`
town, with 27 buildings and 47 props in the current bake. Management/worker meeting
spots can be selected from those existing buildings. These are candidate story
uses, not verified actor placements. The fairy's `clearing` is still scaffold, and
the full clearing → ruins → town walk needs an in-game check. Y00/B01 cover that
check and map-owner review before Y01 fixes the quest scene.

Proposed demo acceptance check: a fresh player can understand the opening, learn
combat, finish the quest and point to a visible change caused by their decision.
Using the testing mode, Yannick can reproduce both quest outcomes, inspect the
local visuals and basic kingdom feedback, and verify that those states survive save/load. Existing
code and art are inputs to this proof; the proof is not yet claimed to pass.

## Next planning deliverables

The draft now exists in [DEMO_WORK_ITEMS.md](DEMO_WORK_ITEMS.md): 52 work items,
each with an owner, estimate no larger than four hours, dependencies, a result and
an in-game check or named alternative. It also records the targeted source reads
used to identify existing work; the original audit above remains a document audit.

**Current next deliverable: [DEMO_WALKTHROUGH.md](DEMO_WALKTHROUGH.md).** Following
Yannick's emphasis on alignment with his brother and small system-development
tasks, the shared sheet records the exact route checks, candidate interaction
locations, decisions for both brothers, gaps and a next-session card template.
It is prepared but has not been walked or approved by slosinio. The existing
52-card list is a provisional inventory: oversized tasks require splitting,
creation needs a behaviour review as well as restoring access, and usable art/map
deliveries should be integrated as they arrive. Owner labels and hour estimates
are not evidence of the brother's agreement or delivery feasibility. Refine the
next sessions around playable behaviours using observed results.

The revised first-pass budget is 74 hours for Yannick with agents and 55 for the
brother, leaving 22 and 41 hours respectively within four 24-hour weeks. These are estimates
to calibrate through the first prototype/art tasks, not measured delivery promises.
The backlog includes a concrete proposed scene (wage agreement or walkout, a guard
intervention and a physical shift action). Local shutdown remains visible; the
previous proposed separate steel-delivery scene is deferred, matching the latest
acceptance of basic kingdom feedback. The 52 active cards now comprise 32 Y items
and 20 B items: Y00 adds map inspection; B17's wider scene leaves the demo budget.
Those scene details are proposals, not approved lore. Related implementation items
are not ready to code until the Y01 review fixes their exact actions/effects. Do not
wait for every later design detail to refine independent testing, export and
combat-foundation tasks.

The milestones, location, conflict, workers' outcome, platform, combat inclusion and
provisional combat candidate are answered. No further broad scope interview is
needed to start reviewing the work items. Next: walk and map the confirmed journey
onto the existing world (Y00), obtain the brother's location review (B01), then
review the concrete two-path quest brief (Y01) and associated work/art estimates.
The testing mode starts with
reproducible quest and combat situations needed for this demo;
broader presets follow as full-v1 systems exist. Develop combat and demo content
together rather than waiting for all kingdom content.

The full-v1 backlog must still cover the remaining quests, cast, world reactions,
combat depth, confrontation and endings from the original vision. Its scope should
be reconciled with the audit; publishing one demo quest is not completion of v1.
The demo deadline is a delivery milestone inside that three-month plan.

Only accepted decisions should subsequently update SPECS §20 and the affected
sections. No spec or source edits are authorized by the audit/handoff alone. Do
not mark the proposed quest, task estimates or art requirements as approved merely
because another agent resumes from this file.
