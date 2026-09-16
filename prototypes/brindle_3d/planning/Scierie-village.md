# Village de la scierie

Composition 3D du village du bois, dans l'atelier graphique Uncrowned. La référence
fournie inspire les colombages, les toitures pentues, les ateliers ouverts et le
moulin sur la rivière. Le village occupe environ 70 × 95 m, avec ses accès extérieurs.

## Organisation

- **Cour des grumes, au nord** : arrivée forestière, dépôt couvert, portique,
  remise des charrettes et atelier du charron. Les stocks restent hors des voies.
- **Séchage** : halle ventilée, piles de planches et poutres sur supports.
- **Logements, à l'ouest** : huit maisons et baraquements différents, chemins
  secondaires, jardins clos, bancs et quelques bouleaux.
- **Place du village** : comptoir des livraisons, puits, jonction des rues et
  accès au pont. L'espace central reste libre pour la circulation.
- **Ateliers** : charpentier, banc de sciage de long, établi, chevalets et chutes.
- **Rive du moulin** : grande scierie, rampe de chargement, roue animée,
  alimentation surélevée et canal de fuite.

Les 15 bâtiments utilisent chacun une scène différente. Quinze accessoires de
travail complètent les cours. Les 20 chemins relient les bâtiments à la place,
aux dépôts, à la forêt et au pont. L'aciérie conserve son organisation existante.
Deux raccords de relief adoucissent les routes de liaison, dont une ancienne
rupture de pente à l'entrée ouest de l'aciérie.

## Eau

Un bras dérivé de la source nord-est contourne le village et rejoint le lac.
La rivière principale conserve son trajet. Une petite retenue à **48,88 m**
alimente une vanne puis un canal de bois à environ **48,77 m**. L'eau arrive
au-dessus de la roue, dont l'axe est à environ **46,43 m**. Le canal de fuite
part à **44,22 m**, descend vers la rivière puis le lac à **40 m**.

Le moulin est sur la rive basse, avec des appuis de pierre prolongés jusqu'au
terrain. Le pont des charrettes en aval possède une largeur utile de 3,4 m et
une longueur de 12 m. Les arbres qui empiétaient sur l'eau, les constructions
ou les voies ont été retirés de la forêt nord-est.

Il s'agit d'une composition graphique : l'eau et les mécanismes sont animés,
mais aucun calcul de débit, de rendement ou de production économique n'est ajouté.
Pas de PNJ, de dialogue ou de contenu d'histoire.

## Ouvrir et modifier

Lancer **Ouvrir-village-scierie.cmd**. **Tab** permet de jouer avec le personnage
depuis la place. Dans la caméra libre de la carte, **T** cadre la scierie.
Le lancement habituel du projet conserve son point de départ à Brindle.

La scène `scenes/sectors/scierie.tscn` est instanciée sous `Decor/Scierie` dans
`scenes/map_plate.tscn`. Les groupes de quartiers contiennent les bâtiments
déplaçables. Les cours et l'eau sont dans `scierie_cours.tscn` et `scierie_eau.tscn`.
Les bâtiments partagent les ressources de `assets/sawmill` : le kit complet et
les aménagements occupent environ **2,8 Mio** de fichiers sources, hors cache Godot.
Les captures de revue restent hors du dépôt.

Chaque bâtiment possède une assise `Scierie_Sol_*` sous `ReliefGodot` : déplacer
l'assise avec le bâtiment. La grande scierie, sa vanne et son canal constituent
un ensemble hydraulique ; modifier leurs hauteurs ensemble et vérifier le canal
de fuite après toute modification.

Les chemins sont peints sur le terrain pour éviter la superposition de surfaces.
Leurs nœuds `Chemins` conservent les points éditables, mais leurs rubans sont
masqués. Pour une modification durable de leur tracé, modifier la recette
`tools/build_sawmill_town.py` puis régénérer le masque et la scène. Les données
livrées sont consignées dans `planning/sawmill-town.json`.

## Régénération facultative

Les scènes sauvegardées sont directement utilisables. Ces commandes remplacent
les éléments générés : reporter auparavant toute retouche manuelle dans la recette.
Depuis le dossier de l'atelier, avec Godot, Python, NumPy et Pillow disponibles :

```sh
python tools/build_landscape.py
python tools/build_sawmill_town.py
godot --headless --editor --path . --import
godot --headless --path . --script res://tools/build_sawmill_waterworks.gd
godot --headless --path . --script res://tools/build_sawmill_courtyards.gd
godot --path . --script res://tools/build_river_crossings.gd
```

Le dernier outil nécessite le moteur graphique pour conserver les MultiMeshes
de végétation. Le catalogue indépendant des 34 éléments s'ouvre avec
`Ouvrir-catalogue-scierie.cmd`. `build_sawmill_assets.gd` reconstruit ce kit si
les modèles doivent être modifiés ; son exécution n'est pas nécessaire pour jouer.

## Vérification

- `verify_sawmill.gd` : 146 contrôles des 34 assets, collisions et passages.
- `verify_sawmill_town.gd` : 82 contrôles du village, bâtiments uniques, assises
  sèches, rues libres, accès du vrai personnage et rampe de la scierie.
- `verify_river_data.py` : continuité des 662 points de profils jusqu'au lac
  et à la mer, validité des données et berges.
- `verify_river_crossings.gd` : traversée des six ponts dans les deux sens et
  sur trois lignes, eau sous les ponts et routes régionales.
- Contrôles de régression de Brindle et de l'aciérie, plus vues réelles Godot
  du village, des logements, des dépôts et des ouvrages d'eau.

`tools/check_workshop.sh` inclut désormais les vérifications du kit et du village.
Pour générer des captures avec le moteur :

```sh
godot --path . --script res://tools/review_sawmill_town.gd -- --capture --out=/chemin/absolu/apercus
```
