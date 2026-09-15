# Ironworking town asset kit

62 reusable Godot scenes for a medieval European-inspired mining settlement.
Its architecture uses dark coursed masonry, dressed stone surrounds, thin slate
roofs, heavy timber supports and black iron fittings. A dedicated local-coordinate
shader and material family are independent of Brindle's domestic architecture. The kit adds mine logistics, direct
reduction ironworking, storage, housing and courtyard props. It does not place the
town in the world map or change the production simulation, cast or dialogue.

## Inspect and place

Open `scenes/catalogue_acierie.tscn` in this workshop and press F6, or run
`Ouvrir-catalogue-acierie.cmd` on Windows. The catalog starts with an illustrative
assembly. Search or select a family to inspect individual scenes. Mouse wheel
zooms, middle-button drag orbits, Left/Right changes asset, R reframes and D opens
the assembly. Dimensions are shown as width × height × depth in meters.

Drag scenes from `assets/ironworks/<family>/` into a map sector. The root origin is
at ground level, the front faces +Z, and one Godot unit is one meter. Some props
extend asymmetrically around the origin; use the displayed dimensions for spacing.
Scene metadata records function and suggested placement. Place on a leveled pad
and rotate around Y rather than tilting whole buildings with the terrain.

## Production logic and layout

The town uses charcoal-fired bloomeries: ore sorting, roasting and crushing;
charcoal charging with manual bellows; extraction and hammering of the solid iron
bloom; finishing and storage of forged bars. Glowing pieces represent hot coals,
not pools of molten iron. This is a stylized, historically informed kit, not an
exact reconstruction of a particular archaeological site or an operating model.

Use a legible route from the mountain mine to the sorting bays, preparation court,
furnaces, hammering shed, toolmaker and finished-bar store. Separate the charcoal
store from open hearths. Place slag in a distinct waste area. Keep the domestic
well, kitchen, granary and housing apart from industrial waste and latrines.
Charcoal production can sit at the forest edge rather than beside bedrooms.

These are composition guidelines, not a fixed city plan. First fit access roads to
the approved terrain; then use irregular courts, offset buildings, subtle slate
variations and twelve individually authored dwelling silhouettes. Leave room for cart movement and later
expansion. Connect the mine entry to the mountain by embedding its rear and sides;
the existing world mine remains untouched by this kit.

Historical references:
- [Wealden Iron Research Group: experimental bloomery smelting](https://www.wealdeniron.org.uk/Expt/smelt.htm)
- [WIRG experiment overview](https://www.wealdeniron.org.uk/Expt/)
- [Historic England: Smithy Beck bloomery and charcoal-burning remains](https://historicengland.org.uk/listing/the-list/list-entry/1007235)

## Editing, performance and limitations

The saved meshes are grouped by structural part and material, with simplified
static collision shapes. The complete kit has 391,940.0 triangles before repeated
placement. There is no asset-generation work at runtime. Materials, transforms,
child visibility and smoke remain editable in Godot; change construction recipes
in `tools/build_ironworks_assets.gd` and `tools/ironworks_building_designs.gd` for structural mesh revisions. Save custom
variants under a new scene name before regenerating generated files.

Buildings with closed doors are exterior scenery; their walls have solid
collisions. Open sheds and the mine approach are accessible. The mine provides a
short entry with a closed back, not a complete underground level. Bellows, wheels,
winch and grinding stone are static models. Smoke and ember variation are visual
effects only. The active furnace and hammering forge have smoke under `FumeeFourneau` (22 CPU particles each), plus a small warm light. The smoke amount,
emitting state and scale can be adjusted. Tiny loose props are decorative and may
have no collision. The catalog floor is only a neutral presentation surface.

No NPC, work schedule, economy, interaction or navigation mesh is attached to the
kit. Main-map terrain, paths and sector optimization remain separate work. Measure
the final placed district before choosing LOD, occlusion or instancing budgets.

## Rebuild and verify

From this workshop root, with Godot 4.7.2 available as `godot`:

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tools/build_ironworks_assets.gd
godot --headless --path . --script res://tools/verify_ironworks.gd
```

Rebuilding overwrites generated ironworks scenes, meshes, materials, manifest and
catalog scene. It does not rewrite the source Brindle assets or world map.
The builder uses a per-asset seed, keeping results reproducible by asset id.
Verification loads all 48 resources and the catalog, checks finite bounds and
sweeps a player-sized capsule through the hangar, gate, winch and mine approach.
It also checks the mine's closed back and active smoke emitter. A successful run
must end with `IRONWORKS_CHECK_RESULT PASS` and contain no `SCRIPT ERROR` or `ERROR`.
Rendering was checked separately in Godot; headless validation cannot verify art.

## Visual direction, geography and provenance

The approved geography places the ironworking village around X=255, Z=65, in a
100 × 100 m planning footprint at the foot of the eastern mining massif. The
ironworks tributary crosses the valley; wood access comes from the northern
sawmill/forest route. Buildings should occupy prepared terraces beside circulation
and the water corridor. This asset kit does not change those approved coordinates.

The stone-and-slate palette is the chosen visual interpretation of that fictional
valley. It does not assert a geological survey or reproduce one historical town.
Buildings use solid masonry rather than exposed decorative timber framing, narrow
stone window surrounds, square chimney stacks, and open work canopies on raised
masonry piers. Slate courses are thin, staggered and matte. Faceted geometry and
small bevels give stone and iron a harder appearance; pale cloth and warm wood
remain readable accents. The charcoal mound retains its earth color.

The forge of Fontenay, dated by the abbey to the late twelfth century, is a
reference for substantial masonry and work buildings near ore sources. Its
hydraulic machinery and monastic plan are not reproduced here. Guédelon's
experimental thirteenth-century construction informs the use of stone, timber,
clay and craft-specific equipment. The bloomery process reference remains WIRG.

- [Fontenay: the forge](https://www.abbayedefontenay.com/decouvrir-fontenay/l-abbaye-et-ses-jardins/la-forge)
- [Guédelon: medieval construction using site materials](https://www.guedelon.fr/?lang=fr)

All kit geometry and material resources are authored in the offline Godot builder.
The well, seat, barrels and crates are generated in the settlement's own material
family. No Brindle building, material or painted texture is required by the kit.
The workshop's generic smoke effect remains a shared technical dependency.
No external asset pack or paid generation service is introduced.

## Scene catalogue

| Scene | Width × height × depth (m) | Purpose |
|---|---|---|
| `production/bas_fourneau_argile.tscn` | 3.56 × 1.81 × 2.37 | Réduction du minerai au charbon ; gorge de chargement et bouche d’extraction. |
| `production/bas_fourneau_actif.tscn` | 3.56 × 1.81 × 2.37 | Même four avec braises et fumée légère ; la loupe reste un métal solide. |
| `production/bas_fourneau_pierre.tscn` | 3.91 × 2.13 × 2.66 | Four trapu à parement de pierre et tuyère, variante d’atelier. |
| `production/grillage_minerai.tscn` | 2.60 × 0.72 × 2.50 | Préparation du minerai sur un lit de bois avant concassage. |
| `production/concassage_minerai.tscn` | 3.14 × 0.84 × 1.49 | Dalle, masses, tamis incliné et paniers pour préparer le minerai. |
| `production/soufflets_jumeles.tscn` | 1.92 × 1.06 × 2.39 | Deux soufflets manuels pour un apport d’air alterné. |
| `production/forge_affinage.tscn` | 6.33 × 5.12 × 4.95 | Halle basse sur piles de pierre avec foyer, enclume, outils et cuve. |
| `production/atelier_outilleur.tscn` | 5.83 × 4.75 × 5.84 | Bâtiment de finition : outils, ferrures et entretien du matériel de la mine. |
| `production/meule_charbonniere.tscn` | 3.55 × 1.32 × 3.59 | Empilement de bois couvert de terre pour produire le charbon de bois. |
| `stockage/halle_tri_minerai.tscn` | 7.72 × 4.72 × 4.15 | Trois casiers couverts pour séparer minerai brut, préparé et gangue. |
| `stockage/depot_charbon.tscn` | 5.93 × 4.69 × 4.45 | Hangar ventilé avec deux casiers de charbon et sacs sous toiture. |
| `stockage/depot_barres.tscn` | 6.22 × 5.11 × 5.15 | Halle avec râteliers et lots de barres prêts à être chargés. |
| `stockage/hangar_charrettes.tscn` | 7.33 × 5.71 × 5.75 | Grand abri traversant pour chargement, entretien et rangement. |
| `stockage/bureau_pesee.tscn` | 4.58 × 4.04 × 4.96 | Comptoir couvert, balance et réserve fermée pour compter les livraisons. |
| `stockage/entree_mine_roche.tscn` | 7.47 × 4.30 × 3.90 | Bouche de galerie boisée avec trois cadres de soutènement et un court tunnel sombre. |
| `stockage/portique_treuil_mine.tscn` | 5.18 × 2.90 × 0.94 | Cadre en bois, tambour manuel, corde et palan pour les charges. |
| `stockage/charrette_ore.tscn` | 2.00 × 1.65 × 4.03 | Transport à roues en bois, sans rail, avec chargement adapté. |
| `stockage/charrette_bars.tscn` | 2.00 × 1.53 × 4.03 | Transport à roues en bois, sans rail, avec chargement adapté. |
| `stockage/tri_minerai_a_pignon.tscn` | 7.03 × 4.15 × 4.33 | Open transverse gable with three low sorting bays. |
| `stockage/charbon_halle_a_croupes.tscn` | 6.33 × 4.01 × 4.63 | Hipped canopy and low ventilated charcoal bays. |
| `production/forge_de_finition_a_pignon.tscn` | 6.48 × 4.89 × 5.30 | Gabled finishing forge with an exposed truss and open work face. |
| `stockage/reserve_barres_longue.tscn` | 5.03 × 4.04 × 6.14 | Narrow deep gabled warehouse with two long storage racks. |
| `village/remise_des_betes_de_trait.tscn` | 6.58 × 4.08 × 4.63 | Hipped stable with two stalls and a closed fodder room. |
| `village/latrines_a_deux_places.tscn` | 3.20 × 2.77 × 2.37 | Two small compartments under a transverse gable. |
| `village/logis_porte_basse.tscn` | 4.94 × 4.49 × 5.81 | Deep stone gable with a recessed side store. |
| `village/maison_aux_deux_volumes.tscn` | 5.71 × 4.29 × 4.18 | Hipped main roof and a stepped entrance wing. |
| `village/baraquement_des_equipes.tscn` | 6.97 × 4.17 × 4.69 | Low timber barrack with two entrances and end chimneys. |
| `village/logis_a_colombages.tscn` | 3.83 × 5.29 × 5.21 | Tall half-timber lodging under a hipped roof. |
| `village/baraque_jumelee_de_la_cour.tscn` | 5.93 × 4.24 × 4.66 | Staggered timber rooms with two different roof heights. |
| `village/maison_du_virage.tscn` | 4.58 × 4.57 × 4.85 | Broad stone house with a projecting timber bay. |
| `village/maison_haute_de_la_venelle.tscn` | 4.40 × 5.44 × 4.46 | Narrow two-storey masonry house with an external chimney. |
| `village/baraquement_de_la_grande_cour.tscn` | 8.48 × 4.69 × 5.93 | Long communal lodging with a continuous covered entrance porch. |
| `village/baraquement_a_galerie.tscn` | 8.27 × 6.07 × 5.54 | Stone lower floor and timber upper floor with a left-hand stair. |
| `village/logis_du_contremaitre_en_l.tscn` | 5.18 × 5.24 × 5.72 | L-shaped masonry residence with a taller front room. |
| `village/maison_des_charretiers.tscn` | 5.13 × 4.29 × 5.28 | Wide low gable with a small rear storage projection. |
| `village/maison_au_toit_decale.tscn` | 4.92 × 4.29 × 4.80 | Asymmetric gable with a short sheltered bench. |
| `village/cuisine_commune.tscn` | 7.83 × 4.71 × 6.09 | Salle commune, auvent de repas, four maçonné et réserve de tonneaux. |
| `village/grenier_vivres.tscn` | 4.40 × 4.47 × 5.17 | Réserve surélevée pour céréales et provisions de la communauté. |
| `village/remise_ecurie.tscn` | 6.72 × 4.87 × 4.75 | Abri ouvert avec mangeoires, séparations de stalles et réserve de foin. |
| `village/latrines_bois.tscn` | 2.10 × 2.99 × 2.42 | Petit édicule ventilé, posé sur une base de pierre. |
| `village/puits_abreuvoir.tscn` | 3.72 × 1.86 × 2.39 | Margelle carrée en pierre sombre, treuil manuel et auge massive. |
| `accessoires/tas_minerai.tscn` | 2.51 × 1.14 × 2.14 | Tas distinct par matière et couleur, modulable par répétition et rotation. |
| `accessoires/tas_charbon.tscn` | 2.63 × 1.12 × 2.14 | Tas distinct par matière et couleur, modulable par répétition et rotation. |
| `accessoires/tas_scories.tscn` | 2.56 × 1.12 × 2.13 | Tas distinct par matière et couleur, modulable par répétition et rotation. |
| `accessoires/loupe_fer_brute.tscn` | 0.85 × 0.38 × 0.75 | Masse spongieuse de fer avant consolidation, différente d’un lingot coulé. |
| `accessoires/barres_fer_liees.tscn` | 1.05 × 0.59 × 2.40 | Barres forgées regroupées sur traverses de bois. |
| `accessoires/bacs_minerai.tscn` | 1.77 × 0.89 × 1.42 | Casier ouvert avec renforts et chargement de minerai. |
| `accessoires/billot_enclume.tscn` | 1.17 × 1.16 × 0.64 | Enclume à corne, talon, trou carré et petit marteau. |
| `accessoires/etabli_outils.tscn` | 1.65 × 1.19 × 0.94 | Table de travail renforcée avec outils et étau. |
| `accessoires/cuve_trempe.tscn` | 1.48 × 0.61 × 0.97 | Auge maçonnée pour refroidissement et travail de forge. |
| `accessoires/outils_mine.tscn` | 1.78 × 1.54 × 0.32 | Pioches, pelles et rangement à la hauteur du personnage. |
| `accessoires/sacs_reserve.tscn` | 1.07 × 0.90 × 0.98 | Trois sacs en toile serrés au col par une corde. |
| `accessoires/buches_rangees.tscn` | 1.93 × 0.72 × 2.02 | Bois coupé avec extrémités claires et écorce sombre. |
| `accessoires/balance_plateaux.tscn` | 1.40 × 0.82 × 0.48 | Balance de comptoir à deux plateaux suspendus. |
| `accessoires/meule_manivelle.tscn` | 1.57 × 1.36 × 0.98 | Roue abrasive montée sur un bâti en bois avec axe et manivelle. |
| `accessoires/tuyeres_argile.tscn` | 1.25 × 0.61 × 0.80 | Tuyères de rechange et argile rangées sur une table basse. |
| `modules/soubassement_2m.tscn` | 1.98 × 0.68 × 0.40 | Module de soubassement et de séparation de cour. |
| `modules/cloture_2m.tscn` | 2.13 × 1.15 × 0.13 | Barrière de bois pour limites de cour et petites enclos. |
| `modules/portail_cour.tscn` | 3.26 × 1.50 × 1.37 | Deux battants ouverts avec ferrures et poteaux. |
| `modules/quai_chargement.tscn` | 3.60 × 0.77 × 4.24 | Plateforme de bois avec rampe praticable et pieds en pierre. |
| `modules/enseigne_forge.tscn` | 1.57 × 2.45 × 0.17 | Potence en bois et emblème d’enclume en fer forgé. |
| `modules/rigole_pierre_2m.tscn` | 0.72 × 0.24 × 2.00 | Petit canal ouvert pour aménager les cours et évacuer l’eau. |
