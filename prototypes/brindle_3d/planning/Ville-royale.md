# Cité royale et château de montagne

Composition 3D de l'atelier graphique, inspirée de la référence fournie : pierre
claire, donjon dominant, tours à toits coniques, toitures d'ardoise et de tuile,
maisons à colombages au pied du rocher. Le château est implanté sur le flanc
montagneux nord-ouest montré dans la capture de la carte.

## Implantation et quartiers

- **Château** : terrasse à 94 m, palais, aile latérale, donjon de plus de 60 m
  au-dessus de sa cour, enceinte haute, tours et porte ouverte. Une petite maison
  de service occupe le côté nord-ouest de la cour.
- **Ville basse** : sol autour de 64–66 m, 33 bâtiments distincts, enceinte et
  onze tours de courtine, plus les tours des deux portes. Avenue centrale depuis
  le pont, place avec fontaine et quatre étals, halle, quartier des artisans,
  logements marchands, chapelle, hôtel de ville, grenier, écuries et corps de garde.
- **Montée** : chemin en lacets de 5 m, soutènements et parapets, de la porte haute
  à la cour du château. Le profil gagne environ 28,5 m et reste franchissable par
  le personnage de test. Le tracé et sa pente partagent une même courbe.
- **Accès régional** : pont de pierre de 18 m, largeur utile 5,8 m, porte de 7 m,
  raccord progressif aux chemins de la carte. Les rues principales font 3 à 5,8 m.

Les 34 bâtiments de ville et de service ont chacun leur propre scène, avec
dimensions, façade et silhouette différentes. Les tours et courtines utilisent
des modules répétés pour une enceinte cohérente. Aucun PNJ, dialogue ou scénario
n'est ajouté. Les façades sont des décors extérieurs ; les intérieurs et la
navigation de la simulation restent un travail distinct.

## Douves et eau

L'affluent existant est conservé à l'est du château. Une dérivation part de son
niveau de 63 m, descend vers des douves à **60 m**, puis un exutoire redescend
vers l'affluent à **47 m**. Le terrain comporte des berges surélevées autour du
bassin. Le relief protège le côté montagne ; les douves entourent les fronts
ouest, sud et est de la ville. Il ne s'agit pas d'un anneau d'eau suspendu autour
du château situé à 94 m.

Le tablier du pont est à **64,2 m**, ses appuis rejoignent le fond. Les deux arches
laissent passer l'eau. Les nouveaux canaux sont nommés `royal_alimentation`,
`royal_douves` et `royal_exutoire` dans `planning/river-layout-v2.json`.
Les modifications du relief source se limitent au secteur nord-ouest.

## Ouvrir et modifier

Lancer **Ouvrir-ville-chateau.cmd** pour ouvrir une vue jouable de la cité.
**C** cadre la ville et le château dans la caméra libre ; **Tab** passe au
personnage, placé sur l'avenue. La molette zoome et le bouton du milieu permet
de tourner. Le lancement habituel du projet reste à Brindle.

- `scenes/sectors/ville_royale.tscn` : groupes de quartiers, bâtiments et chemins.
- `scenes/sectors/ville_royale_enceinte.tscn` : fortifications et soutènements.
- `assets/royal_city/` : **44 assets natifs originaux**, catalogue, meshes compressés
  et matériaux partagés, environ **7,3 Mio** hors cache Godot. Aucun pack téléchargé.
- `planning/royal-city.json` : recette éditable des architectures, positions,
  assises, rues, enceinte et profil de montée. `ramp_xyz` contient des points
  **[X, Z, altitude]**, comme les profils de rivière.
- `scenes/relief_godot.tscn` : assises `Royal_*`. Déplacer ensemble un bâtiment
  et son assise pour une retouche manuelle. La montée applique ensuite son profil
  continu via `scripts/royal_ascent.gd` afin d'éviter des marches entre assises.
- `assets/landscape/royal_ground_mask.png` : rues en terre claire et cour du
  château peintes sur le terrain. Les rubans `Chemins` sont masqués pour éviter
  des surfaces superposées. Les seuils suivent les portes réelles des modèles.

Les scènes livrées s'ouvrent sans Python. Pour régénérer, reporter les retouches
manuelles dans la recette avant ces commandes, qui remplacent les scènes générées :

```sh
godot --headless --path . --script res://tools/build_royal_assets.gd
godot --headless --path . --script res://tools/build_royal_fortifications.gd
python tools/build_royal_city.py
godot --headless --editor --path . --import --quit
```

Si les profils hydrauliques sont modifiés, exécuter aussi `build_landscape.py`,
puis `build_river_crossings.gd` **avec le moteur graphique** pour préserver les
MultiMeshes de végétation. Les outils Python nécessitent NumPy et Pillow.
Les captures de revue sont conservées hors du dépôt.

## Vérifications

- `verify_royal_city.gd` : **167 contrôles**, chargement des 44 assets, architectures
  distinctes, assises sèches et stables, appuis du château, rues libres sur trois
  lignes, pentes et traversée du vrai personnage depuis le pont jusqu'à la cour.
- `verify_river_data.py` : continuité de **831 points de profils**, aucune rupture
  humide, sept franchissements.
- `verify_river_crossings.gd` : **102 contrôles** de ponts, eau sous les tabliers,
  accès et liaisons régionales.
- Régressions de la scierie, de l'aciérie et de Brindle ; vues de la ville, du
  château et des douves inspectées avec Godot 4.7.2, Forward+ / D3D12.

Le contrôle de la cité est inclus dans `tools/check_workshop.sh`. Pour capturer
les vues réelles du moteur :

```sh
godot --path . --script res://tools/review_royal_city.gd -- --capture --out=/chemin/absolu/apercus
```
