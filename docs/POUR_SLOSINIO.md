# Pour slosinio — ce qu'on apprend en branchant la simulation sur ta carte

Écrit en français, pour toi. Mis à jour au fur et à mesure du travail.
Dernière mise à jour : 2026-09-30 (la nouvelle règle des dessins, et les tenues).

**Ta liste de tâches, en une page, est à côté : `docs/TACHES_POUR_SLOSINIO.md`** (2026-09-29).

Ce document n'est pas une commande. C'est ce qu'on découvre en jouant, mesuré plutôt
que supposé, pour que tu décides de ton côté en sachant ce qui se voit et ce qui ne se
voit pas.

---

## 1. Ce que la simulation sait maintenant d'un lieu

Deux nombres, de 0 à 10, et rien d'autre :

- **l'allégeance** — à quel point le lieu est avec le roi ;
- **la richesse** — à quel point il va bien.

Au-dessus de 5, le lieu se lit « loyal » ou « riche ». En dessous, « hostile » ou
« pauvre ». Ça fait **quatre apparences par lieu**.

**Ces deux nombres n'existent que pour être vus.** Leur seul rôle est de changer ce
que le joueur regarde. C'est donc ton travail qui décide s'ils servent à quelque chose.

---

## 2. La chose la plus importante : des signaux, pas quatre versions de chaque bâtiment

L'idée de départ était « quatre états graphiques pour chaque maison ». L'aciérie a
**27 bâtiments**. Quatre états × 27, c'est **108 variantes de bâtiments pour une seule
ville**, et il y a huit villes.

Ça ne tiendra pas, et ce n'est pas nécessaire.

À la place : **quelques signaux qui s'allument ou s'éteignent et se combinent.**
Quatre ou cinq signaux à deux positions donnent seize apparences lisibles avec une
poignée d'éléments.

| Signal | Piloté par |
|---|---|
| Le feu, la lueur et la fumée des fours | la richesse |
| Les volets, les toits, l'état des maisons | la richesse |
| La bannière du roi, la présence de la garde | l'allégeance |
| Les gens au travail, désœuvrés, ou partis | les deux |

---

## 3. Ce qu'on a mesuré, et ce que ça dit de ce qui vaut le coup

Trois choses construites, trois résultats très différents. Les chiffres sont réels.

### Les fours : **ça marche très bien**

La richesse décide combien de tes six fours brûlent. Sur six : **aucun à 1, deux à 4,
quatre à 7, les six à 10**. À richesse basse, plus une flamme, plus une fumée, plus une
braise — fours **et** forges.

C'est de loin le signal le plus fort qu'on ait. Il vient entièrement de toi : ce sont
tes effets livrés, on ne fait que les allumer et les éteindre.

### Les objets qui disparaissent : **trop faible, mesuré**

Quand un lieu devient pauvre, il cesse de sortir son travail : la charrette de
minerai, les barres liées, la loupe de fer encore chaude, le bois empilé.

On a compté les pixels entre l'image riche et l'image pauvre : **0,35 % de l'image
change**. Autrement dit, invisible. Cinq objets seulement, et ils sont petits.

**Ce n'est pas un reproche à ta livraison.** C'est que les objets mobiles sont peu
nombreux et petits par nature. Ça ne suffira jamais à montrer une ville qui s'arrête.

### La lumière : **à ton avis, et Yannick n'est pas convaincu**

On a essayé de faire pencher la lumière vers le chaud dans un lieu loyal et vers le
froid dans un lieu hostile. C'est **une teinte multipliée par ta lumière**, pas un
remplacement : ton soleil et ton ciel restent les tiens, et le milieu des deux
penchants est exactement ta lumière d'origine.

Yannick n'est pas sûr d'aimer. **C'est ton domaine, et c'est un commit à défaire.**
Trois sorties possibles : la garder, l'adoucir, ou montrer l'allégeance autrement — par
la bannière du roi et la présence de sa garde, ce que toi tu peux dessiner.

---

## 4. Ce qui rendra vraiment une ville arrêtée visible : les gens

C'est la conclusion des trois mesures ci-dessus, et c'est aussi ce que Yannick avait
décrit en premier.

Une ville qui s'arrête, ce n'est pas des objets en moins. **C'est des gens qui ne
partent plus travailler.**

**C'est construit, et mesuré.** Douze personnes sortent de l'usine vers la coupe et
reviennent. La richesse décide combien partent : toutes au plafond, **aucune au
plancher**.

| Ce qu'on a essayé | Part de l'image qui change |
|---|---|
| Les objets qui disparaissent | 0,35 % |
| **Les gens** | **2,33 %** |

Sept fois plus, et les deux images ne se ressemblent pas : une douzaine de silhouettes
sur la route et trois sur ton pont, contre une route vide.

**Ça ne t'a demandé aucune animation nouvelle** — c'est ton voyageur qui marche.

Un détail qui te concerne : ils marchent vers **la coupe** (le `working_face`), pas
vers la mine. La route de la mine est un point de ta carte qui n'existe pas sur
l'ancienne carte 2D, et la coupe existe sur les deux. C'est aussi une meilleure
histoire : les gens qui vont là-bas **sont ceux qui mangent la forêt**, ce qui relie
cette quête à celle de la fée.

---

## 5. Ce dont la démo a besoin de toi

Court, et tout réutilise ce que tu as déjà.

1. **Une clôture et une porte** entre le quartier d'habitation et la zone de
   production. Tu as déjà les `cloture_2m` et tu en poses déjà. C'est ce qui empêche le
   joueur d'aller éteindre un four avant d'avoir rencontré qui que ce soit — la quête
   est la clé qui ouvre cette porte.
2. **La pollution, visible sur la carte.** Elle pèse sur une ville qui tourne et se
   lève quand elle s'arrête. C'est un signal piloté par la production, pas une valeur
   de plus.
3. **Éventuellement : des éléments d'usine détruite.** Yannick l'a proposé. C'est le
   signal le plus fort possible pour la victoire des ouvriers, et c'est aussi le plus
   coûteux — à toi de dire si ça vaut le travail.
4. **Moins de bâtiments**, si tu es d'accord. Yannick en a parlé. 27 bâtiments pour une
   ville rend chaque variante chère.

---

## 6. La liste de ce qui disparaît t'appartient

Elle est dans **`content/towns.json`**, bloc `poverty`. Une ligne à changer, aucun
code à toucher. Si tu ajoutes des objets à l'usine, ajoute leur nom à la liste et ils
seront portés automatiquement.

Deux règles que le jeu applique quoi qu'il y ait dans la liste :

- **on ne cache jamais un objet posé sur du sol infranchissable**, sinon il resterait
  un mur que personne ne voit — c'est la règle « ce qui t'arrête doit se voir » ;
- **jamais un bâtiment** : une usine arrêtée est vide, pas démolie.

---

## 7. Le contrat à ne pas casser

Une seule chose fragile entre ton travail et le nôtre : **les identifiants**. Les noms
de tes sites (`village_acierie`), de tes bâtiments (`MaisonContremaitre`,
`FourneauUn`) et de tes ponts.

Le jeu place les gens et les actions par ces noms-là, jamais par des coordonnées.
C'est pour ça que ta v4 a pu déplacer **seize bâtiments sur vingt-sept** sans qu'on
ait une seule ligne de contenu à changer.

Renomme si tu veux, mais dis-le : un test nous prévient le jour où un nom disparaît,
mais il ne devine pas le nouveau.

---

## 8. Le combat arrive, et il y a une question pour toi

On a commencé le système de combat. Le calcul est fait et testé : deux combattants, des
coups, une garde, un résultat. L'image attend une décision de Yannick, et cette décision
te concerne directement.

**La question.** Le combat se passe où ? Deux réponses possibles. Sur un écran séparé, en
2D vue de côté. Ou sur place, dans le monde 3D, avec la caméra qui descend.

**Ce qu'on a vérifié dans ton fichier `traveler_walk_frames.tres`.** Ton voyageur a huit
animations : `idle` et `walk`, dans quatre directions — `up`, `left`, `right`, `down`. Et
le jeu choisit laquelle afficher d'après la direction **dans le monde**, pas d'après la
caméra.

Conséquence : **la caméra ne peut pas tourner.** Si on la fait pivoter de quatre-vingt-dix
degrés, un personnage qui marche vers l'est reste dessiné de face. Les coups partiraient
dans le vide.

**Ce qu'on recommande, et ça ne te demande aucun dessin.** Garder l'orientation de la
caméra exactement où elle est. Baisser seulement sa hauteur — de 48 degrés à 25 ou 30 —
et resserrer le cadre. Le combat se déroule alors sur l'axe est-ouest. Les deux profils
dont il a besoin sont tes images `left` et `right`, qui existent déjà.

**L'autre solution coûterait cher, à toi.** Faire tourner la caméra voudrait dire
redessiner chaque personnage sous huit angles. C'est la plus grosse demande de dessin du
projet, et on préfère te l'éviter.

**Yannick a tranché le 19 septembre : le combat se passe sur place, sans coupure.** Et
c'est construit — tu peux le voir toi-même :

```bash
UNCROWNED_DUEL=bram tools/shot.sh /tmp/combat.png play 280,315
```

**Son idée, et elle est bonne.** Pendant que la caméra descend, **les bords de l'écran
s'assombrissent**. Ça dessine une arène qui n'existe pas. Aucun décor, aucun dessin, et
surtout : ça marche sur un terrain vide, dans un bois, n'importe où. On avait d'abord
pensé à un cercle de gens qui regardent — mais il faut des gens, et il n'y en a pas
toujours. Les spectateurs restent pour plus tard, en plus, là où il y en a vraiment.

Pendant le combat on ne peut pas sortir de la zone : deux cases de chaque côté. C'est
une règle du jeu, pas un effet d'image.

**Ce sur quoi ton avis compte.** La force du noir, la vitesse à laquelle il arrive, et
l'angle de la caméra (48° en exploration, 27° en combat). Tout ça se change en trois
nombres. Regarde l'image et dis-moi.

### La seule chose qu'on te demande vraiment : trois images

On a vérifié ton fichier `traveler_walk_frames.tres`. Il contient huit animations :
`idle` et `walk`, dans quatre directions. C'est tout.

Donc aujourd'hui, dans un combat, **frapper, garder et reculer se ressemblent tous** :
quelqu'un debout. Et tout le combat est construit pour qu'on *voie venir* un coup — il y
a vingt-huit images de préparation avant qu'il parte. Personne ne les voit.

En attendant, on déplace ton personnage : il se ramasse pendant la préparation, il se
détend d'un coup quand le coup part, il s'écarte derrière une garde. Ça se lit en
mouvement. Ce n'est pas un dessin, c'est un déplacement, et c'est marqué comme provisoire
dans nos tests.

### On a dessiné dessus, et tu dois le savoir

**Yannick a décidé le 19 septembre qu'on les fasse nous-mêmes, en attendant.** Je lui ai
dit qu'une deuxième main sur ton personnage se verrait. Il a dit d'y aller quand même.
Donc c'est écrit ici plutôt que découvert.

Ce qu'on a fait, exactement :

- **Aucune couleur inventée.** Ta main est recopiée ailleurs, ta manche est allongée en
  répétant une de ses propres colonnes, ton contour est prélevé sur ton trait. Ton
  personnage est peint, pas en aplats — rien que les cheveux font des milliers de bruns —
  donc un rectangle de couleur à côté aurait sauté aux yeux.
- **On n'a pas touché à tes fichiers.** `prototypes/` est à toi, l'outil ne fait que le
  lire. La planche combinée et les animations en plus sont chez nous, dans `view3d/`.
- **L'outil est `tools/draw_fight_frames.gd`** et il se relance. Le jour où tu dessines
  les tiennes, on supprime l'outil et le fichier, et un test nous force la main : il
  échoue dès que ta planche gagne une neuvième animation. *(Depuis le 30 septembre, la
  règle a changé : on choisit ensemble entre les tiennes et les nôtres. Voir le §15.)*

C'est grossier, et Yannick l'a dit après avoir joué. On a fait une deuxième passe : il y
a maintenant **quatre** poses, parce que la préparation du coup n'en avait aucune — le
bras se ramène, puis il part. Ça se lit en jeu. Ce n'est pas mieux que ça.

Une chose qu'on a apprise en s'y cassant les dents, et qui te servira : **ta chevelure
prend les trois cinquièmes du haut du sprite.** Tout bras dessiné à hauteur de tête s'y
perd ou barbouille le visage. La seule bande dégagée est la poitrine.

**Ce qui remplacerait ça, c'est trois images :**

| | |
|---|---|
| **Attaque** | le personnage qui frappe |
| **Garde** | le personnage qui se protège |
| **Encaisse** | le personnage touché, une image suffit |

**Et seulement `left` et `right`.** Pas besoin de `up` ni de `down` : la caméra ne tourne
jamais pendant un combat, donc un combat se déroule toujours d'est en ouest. Six images en
tout, donc, si tu comptes les deux sens.

C'est la seule chose qui manque vraiment au combat. Le reste marche.

### Une chose qu'on te demande en plus : un animal

Depuis le 25 septembre il y a des **loups** dans le bois et sur la Route du Roi. Ils se
battent, ils tuent, on peut les tuer — et ils sont dessinés comme **un bloc gris dans ta
peinture de roche**, parce que tu n'as encore dessiné aucun animal.

C'est la règle qu'on s'est donnée : ce que tu n'as pas fait est *visiblement* absent
plutôt qu'emprunté à autre chose. On aurait pu mettre ton voyageur — ça aurait posé un
homme sur la route en l'appelant un loup, et c'est la seule chose que la règle interdit
vraiment.

Donc au début, sur un pont de la Route du Roi, deux cailloux mordaient le joueur.

**Depuis le 26 septembre, c'est un loup de chez nous, dans ta peinture.** Yannick a
trouvé les cailloux trop laids et m'a demandé mieux. Je n'ai pas voulu télécharger un
modèle : ç'aurait été la main d'un troisième artiste. Je l'ai donc **construit** — onze
boîtes, dans le style facetté de tes accessoires — et **coloré uniquement avec deux de
tes matières**, `styled_rock` pour le pelage et `styled_dark` pour le dos, le museau,
les oreilles et la queue. Aucune couleur inventée, comme pour les images de combat.

Ça se voit que c'est nous, et c'est normal. Ton loup le remplacera. *(Depuis le 30
septembre, la règle a changé : on choisit ensemble entre ton loup et le nôtre. Voir le
§15.)*

**Ce qu'il faudrait :** un loup, vu de dessus comme tes autres personnages, dans les
quatre orientations si tu peux, une seule de profil si tu ne peux pas. Une posture
suffit — ils ne marchent pas encore, ils attendent. Le jour où tu le livres, le bloc
disparaît tout seul : un test le surveille.

### Ce qui a changé le 24 septembre, et ça te concerne directement

Deux paragraphes plus haut sont maintenant faux, et plutôt que de les effacer je les
corrige ici — pour que tu voies ce qui a bougé et pourquoi.

**Le combat a changé de forme.** Il n'est plus en temps réel. C'est maintenant du **tour
par tour sur la grille du monde**, à la Baldur's Gate : chacun son tour, on se déplace de
quatre cases et on frappe. Yannick l'a décidé après avoir joué le premier, pour une
raison simple — il veut qu'on puisse **s'en prendre à n'importe qui**, y compris à trois
personnes dans une cour, et un duel en temps réel ne sait pas faire ça.

**Ce que ça défait.** On t'avait écrit : *« seulement `left` et `right`, pas besoin de
`up` ni de `down`, un combat se déroule toujours d'est en ouest »*. **Ce n'est plus
vrai.** Sur une grille, deux combattants se retrouvent constamment l'un au nord de
l'autre.

**Et donc on a dessiné sur ta vue de dos.** Il faut que tu le saches, c'est la raison
d'être de cette section. Il y a maintenant **douze poses** au lieu de quatre : la
préparation, le coup et l'encaissement, dans les quatre directions. Les trois conditions
n'ont pas bougé — aucune couleur inventée, tes fichiers jamais touchés, tout supprimé le
jour où tu dessines les tiennes — et la première est devenue un **test** plutôt qu'une
promesse : il parcourt les seize cases et échoue sur un seul pixel dont la couleur
n'existe pas dans ton image d'origine.

**Ce qu'on te demande a donc changé de taille.** Ce n'étaient pas six images, ce sont
douze :

| | `left` | `right` | `up` | `down` |
|---|---|---|---|---|
| **Préparation** | ✔ | ✔ | ✔ | ✔ |
| **Attaque** | ✔ | ✔ | ✔ | ✔ |
| **Encaisse** | ✔ | ✔ | ✔ | ✔ |

La garde a disparu du jeu — il n'y a pas de bouton de blocage, comme dans Baldur's Gate 3
— donc ne la dessine pas.

**Et une chose franche, parce que tu la verrais de toute façon.** Le coup vers le nord se
lit : le bras monte et le poing passe derrière les cheveux. **Le coup vers le sud, non.**
De profil, la préparation est basse et en arrière et le coup part vers l'avant ; vers le
sud, la préparation est haute et le coup descend le long du corps. Les deux mêmes poses
veulent dire des choses opposées selon l'orientation, et un bras qui pend se lit comme un
bras retombé, pas comme un coup. C'est la pose qu'on referait en premier.

**Deux autres choses ont bougé et ton avis compte sur les deux.**

- **On ne peut plus sortir de la zone, ce n'est plus vrai non plus** : la limite de deux
  cases a disparu. Tu peux quitter un combat en marchant, et l'adversaire te poursuit sur
  huit cases avant d'abandonner.
- **La caméra de combat est passée de 7 m à 15 m**, parce qu'un déplacement de quatre
  cases fait un champ de neuf cases de large et que ça débordait de l'écran. **Tes
  personnages sont donc environ deux fois plus petits pendant un combat.** L'angle et
  l'orientation n'ont pas bougé. Regarde et dis ce que tu en penses :

```bash
UNCROWNED_DUEL=bram tools/shot.sh /tmp/duel.png play 280,315
```

Et un avertissement qu'on te doit : dans un bois dense, un combat est presque illisible.
Tes sapins passent devant les combattants. On sait comment le régler — faire disparaître
en fondu ce qui passe entre la caméra et eux — mais ce n'est pas encore fait.

Donc concrètement, pour toi : **rien à redessiner.** La caméra garde son orientation,
elle descend seulement. Le combat se déroule d'est en ouest, et il utilise tes images
`left` et `right` telles quelles.

Une seule chose pourrait venir vers toi plus tard. On a rendu quatre cadrages pour
vérifier, et deux choses sont ressorties. Dans un quartier bâti, les toits passent devant
les combattants quand la caméra descend. En terrain nu, rien ne cadre le combat. La
réponse aux deux est la même : le combat se passe sur un terrain dégagé, entouré des gens
qui regardent — et un spectateur, c'est le sprite voyageur que tu as déjà.

Donc si tu veux bien, **une cour dégagée près de l'aciérie** serait utile un jour. Pas
urgent, et bien plus petit que les huit orientations qu'on vient d'éviter.

---

## 9. Détail pratique : ouvrir ton projet salit des fichiers

Chaque fois que ton projet Godot est ouvert, Godot réimporte tes textures et modifie
des fichiers `.import` suivis par git. C'est arrivé trois fois cette semaine.

Après avoir regardé ton atelier :

```bash
git checkout -- prototypes/
```

Et pour voir ton travail dans **le jeu** plutôt que dans ton atelier, sans rien salir :

```bash
UNCROWNED_TOWN=cinderworks:6/4 godot --path .   # l'aciérie qui va mal
UNCROWNED_TOWN=cinderworks:3/1 godot --path .   # l'aciérie morte
UNCROWNED_TOWN=cinderworks:9/7 godot --path .   # l'aciérie qui tourne
```

## 10. La cour des fourneaux est faite de tes modules (2026-09-21)

Le bake lit maintenant ton `assets/ironworks/catalog.json` — `size_m`, `front: +Z`,
`ground_pivot`, tes formes de collision, et ta note `placement`. C'est elle qui a
décidé la cour : `soubassement_2m` posé bout à bout à 2 m comme tu l'écris (*extrémités
à X = ±1 m ; dupliquer pour prolonger*), `portail_cour` avec son passage de 2,6 m dans le
mur ouest là où ta traverse des fourneaux quitte la rue, `enseigne_forge` à côté. Le mur
part de la rive, suit ta ruelle du charbon au nord, la verge de ta rue de travail à
l'ouest, passe sous l'avant-toit de ta halle de tri au sud, et revient à la rivière. Rien
n'est bâti le long de l'eau : la rivière est le bord est. Le sol de la cour est ton
matériau de chemin (`ironworks_path.tres`), à 62 % pour que ton bruit le morcelle.

Deux choses pour toi, si tu veux :

- Ton `MuretMinerai_03` (274, 50) est posé exactement sur une limite de case (z = 50 m
  est un multiple de 2) et **n'arrête personne** dans la simulation : le centre d'aucune
  case ne tombe dans ses blocs. Le mur de la cour ne compte donc pas sur lui. Un demi-
  mètre plus au nord ou au sud, il fermerait une case.
- Si un jour tu poses toi-même une cour autour des fourneaux dans ton atelier, le bake
  la lira à ta place : les entrées `yards` de `content/bake_brief.json` sont notre
  proposition et disparaissent le jour où tes données nomment la même chose.


## 11. Le cimetière est fait de tes pièces, et il te manque une tombe (2026-09-29)

Le jeu commence maintenant dans **le cimetière du village brûlé**, sur la prairie au sud
de Brindle, entre ton sentier et ton bois, au-dessus de tes falaises. Yannick l'a voulu :
on se réveille parmi les morts du village, et on sort par les ruines.

Tu n'as dessiné ni tombe, ni stèle, ni croix. Plutôt que d'en inventer, le cimetière est
**entièrement fait de tes pièces**, posées au mètre près par le bake comme la cour des
fourneaux :

- ta **clôture rustique** (`cloture_rustique_2m`) au nord, avec ton **portail fermier
  ouvert** au milieu, qui donne sur ton sentier vers les ruines ;
- pour chaque pierre tombale, ton **bloc arrondi** (`boulder_round`) **réduit et
  aminci** — environ 0,85 m de large, 1,2 m de haut pour les anciennes, un peu moins pour
  les récentes — avec une petite variation d'angle et de taille d'une pierre à l'autre ;
- sur les trois tombes récentes (les morts de l'incendie), ton **raccord de terre**
  (`sol_cultive_raccord`) rétréci à la taille d'une tombe ; sur les trois anciennes, ta
  **jachère** (`jachere_irreguliere`) rétrécie pareil, une tombe retournée à l'herbe sèche.

Tes noisetiers du secteur Brindle sont restés où tu les as mis : le coin ouest, près du
sentier, leur est laissé, et les tombes sont posées autour.

Ça se lit comme un cimetière à la distance du jeu. De près, ça se voit que ce sont des
cailloux et de la terre de champ détournés.

**Ce qu'il faudrait :** un petit kit de cimetière de village — deux ou trois pierres
tombales brutes ou taillées, une croix de bois, un tertre de terre et un tertre herbeux,
peut-être un muret bas. Le jour où l'un d'eux arrive dans ta bibliothèque ou un de tes
catalogues, un test le voit (`test_his_brother_has_drawn_no_grave`) et le cimetière est
refait avec.

**Une chose qu'on a essayée et qui ne marche pas chez nous :** ton amas de galets de la
côte (`amas_galets_granit`). Son maillage garde le chemin de ton propre projet pour sa
matière (`res://assets/coastline/materials/coastal_granite.tres`), et notre copie ne peut
pas réécrire l'intérieur d'un fichier binaire — c'est le même souci que les trois
secteurs de §9b dans `docs/MIGRATION_3D.md`. Si tu ré-exportes tes pièces de côte avec la
matière assignée dans la scène plutôt que dans le maillage, on pourra s'en servir.

## 12. Bram t'interpelle, et le « ! » est à nous (2026-09-29)

En remontant du cimetière vers le village, le joueur entre dans une petite bande de
terrain à la lisière sud de Brindle (deux cercles côte à côte, juste au nord du
cimetière). Bram le voit : un **« ! »** surgit au-dessus de sa tête, le joueur
est tenu immobile, Bram descend vers lui en marchant (ton voyageur, qui marche comme tu
l'as animé), s'arrête à côté de lui sur la même rangée, et la conversation s'ouvre toute
seule. (Il s'arrêtait d'abord juste au nord du joueur — sous ton bouleau, où on ne le
voyait plus.) Une seule fois. C'est le « dresseur
Pokémon » que Yannick a demandé pour lancer le tutoriel.

Le « ! » est **dessiné par nous, en code** : une barre et un point couleur braise (la même
braise que les feux), cerclés d'un trait d'encre, toujours au-dessus du reste de l'image.
C'est un signe d'interface, comme les petites marques au-dessus des témoins d'un vol, pas
un objet de ton monde. Si tu veux en dessiner un à ta main — une bulle, un point
d'exclamation peint —, il remplace le nôtre sans rien changer d'autre.

## 13. Des stèles et des feux de camp, faits avec tes matières (2026-09-29)

Yannick a vu tes rochers réduits en guise de stèles et a validé qu'on fabrique de vraies
stèles, comme pour le loup. Elles sont donc **faites par nous, uniquement avec tes
matières** : une stèle de pierre au sommet arrondi sur un petit socle (`styled_rock`)
pour les anciennes tombes, une planche taillée en pointe (`styled_wood`) pour les
tombes des morts de l'incendie. La terre et la jachère dessous restent les tiennes.

Il a aussi demandé un vrai **feu de camp** à la place du bloc gris. Il est **composé de
tes pièces** : un cercle de ton `boulder_round` en petit, quatre de ton `fallen_log`
coupés en bûches et appuyés en tipi, un lit de braises dans la matière `embers` de tes
fourneaux, ta fumée `fumee_ruine` au-dessus, et une lumière de la couleur de ta forge
qui vacille. Seules les flammes sont à nous (des particules, faites comme ta fumée,
dans les couleurs de tes braises et de ta forge). Tous les feux de camp du jeu sont
maintenant comme ça.

Le jour où tu dessines une tombe ou un feu de camp, on remplace les nôtres par les tiens.

## 14. L'arc du joueur, les gardes de l'usine, et la clairière (2026-09-29)

Yannick a joué le tutoriel. Trois changements te concernent.

**Le joueur tire à l'arc.** Wren lui donne un arc pendant l'entraînement, et la touche U
passe de l'épée à l'arc. Une flèche touche au moment du tir, de deux à six cases. Tu n'as
dessiné ni arc ni tir : on réutilise la pose « bras armé » tirée de tes images, et la flèche
est un trait clair dessiné par nous, en code. Si tu dessines une pose d'arc bandé dans les
quatre directions, et une flèche, on remplace les nôtres.

**Les gardes du roi.** Si le joueur attaque le portier, trois gardes du roi arrivent :
très forts, trop forts pour le joueur au début du jeu. Si par miracle il bat les quatre, la
porte est à lui, et il peut éteindre ou rallumer les fours ; éteindre fait venir les gardes
de l'usine (un à l'épée, deux archers, faciles à battre), rallumer fait venir Tom.
Depuis le 2026-09-30, chacun porte une tenue qui le distingue (voir le §15) : les gardes
du roi en armure noire, ceux de l'usine en ocre.

**La clairière des fées est supprimée.** Le joueur ne s'y réveille plus depuis le
cimetière. Il n'y a plus d'anneau de bois à planter autour.

Ta liste de tâches à jour est dans `docs/TACHES_POUR_SLOSINIO.md`.


## 15. La règle change : on dessine aussi, en restant fidèles à ton style (2026-09-30)

Yannick a changé la règle des dessins. Jusqu'ici, tout ce qu'on voyait dans le jeu venait
de toi. Quand tu n'avais pas dessiné quelque chose, on posait un bloc peint avec ta roche.
Il y avait trois exceptions, décidées une par une : les images de combat, le loup, les
stèles et les feux de camp.

**Maintenant, on peut dessiner nous aussi, en 2D et en 3D, tout ce dont le jeu a besoin.**
Yannick sait que tu utilises aussi Codex pour tes objets 3D. La seule condition est la
**cohérence** : ce qu'on fait doit ressembler à ton travail. Pour nous, ça veut dire :

- nos objets 3D sont en low-poly et portent tes matières (`styled_rock`, `styled_wood`,
  `styled_dark`, tes braises) ;
- nos images de personnages gardent ton contour sombre, ta lumière venue d'en haut à
  gauche et ta texture peinte ;
- on ne télécharge rien : ce serait la main d'un troisième artiste ;
- on ne touche jamais à tes fichiers ;
- tout ce qu'on fait est noté ici.

Les trois « exceptions » ne sont donc plus des exceptions. Un test surveille toujours ta
bibliothèque : le jour où tu livres des images de coup, un animal ou une tombe, il nous
prévient, et on choisit ensemble entre ta version et la nôtre.

**Les tenues des personnages.** Tout le monde était ton voyageur : cheveux roux, chemise
bleue, sac à dos. Dans un combat, on voyait six fois le même homme. Yannick a demandé que
chaque type de personnage se reconnaisse du premier coup d'œil. On a donc **habillé ton
voyageur, sans le redessiner** : la couleur des cheveux et des vêtements change, mais la
forme de tes ombres est gardée. Par-dessus, on dessine ce que tu n'as pas fait : un casque,
une calotte, une capuche, un chapeau de paille, un tablier, une barbe, une épée, un arc.

Il y a quatorze tenues :

- **les gardes du roi** : armure noircie, casque fermé avec un plumet rouge, tunique
  rouge à couronne, bouclier dans le dos, une épée à la main, 20 % plus grands que les
  autres. Ils doivent avoir l'air impossibles à battre ;
- **les soldats du roi** (le garde du pont, les sentinelles) : rouge du roi, mais en
  tissu, avec une calotte de fer et une épée à la ceinture, qu'ils sortent pour se
  battre ;
- **les gardes et les archers de l'usine** : ocre, la couleur de l'usine, une calotte de
  cuir, une épée ou un arc à la main ;
- **trois ouvriers** : vêtements sombres, tablier de cuir, gants, foulard ;
- **Harry, le contremaître** : un manteau de la couleur de l'usine, plus sombre, sans
  tablier, et un chapeau de feutre à bord ;
- **quatre villageois** : des vêtements de tous les jours, sans sac à dos ; l'un porte un
  chapeau de paille, un autre un foulard rouge, les deux autres sont tête nue ;
- **Bram** : cheveux gris, barbe courte, épée à la ceinture, et à la main quand il se
  bat ;
- **Wren** : capuche verte, un arc et un carquois. De face, elle tient l'arc à la main ;
  de profil, il est dans son dos, pour ne pas passer devant son visage.

**Le joueur reste ton voyageur, exactement** (jusqu'au 1er octobre : voir le §16). La
planche est dans `docs/frames/cast/looks.png`, et l'outil qui les fabrique est
`tools/draw_cast_looks.gd`.

**Ce qui est à nous sur ton voyageur**, pour que tu le voies d'un coup d'œil : les
couleurs des tenues, et les pièces dessinées par-dessus. Un casque, une capuche ou un
chapeau changent la forme de la tête, et le sac à dos est enlevé. Tes animations, ton
contour et la forme de tes ombres restent les tiens. Les images dans le jeu sont dans
`docs/frames/cast/in_game.png`.

**Ce que tu pourrais dessiner à la place**, si tu veux : les vrais personnages, au repos
et en marche dans les quatre directions, comme ton voyageur. Ceux qui se battent ont
aussi besoin des images de combat : la préparation du coup, le coup et le recul, dans les
quatre directions. D'abord un garde du roi, un garde de l'usine, un ouvrier, un
villageois, Bram et Wren. Ta liste de tâches
(`docs/TACHES_POUR_SLOSINIO.md`, §2) le reprend. Le jour où tu en livres un, on choisit
ensemble lequel garder.

## 16. Le joueur se choisit, et il s'équipe (2026-10-01)

Avant la relecture des textes, Yannick a demandé deux choses pour la démo : **choisir
l'apparence du joueur** à la création du personnage, et **un inventaire** avec de
l'équipement qu'on voit sur lui.

**Ton voyageur est toujours le joueur par défaut, exactement.** Mais on l'a **découpé en
calques** : le corps, la peau, les cheveux, la tunique, le pantalon, les bottes et le sac
à dos. Un calque est une image à part, posée sur les autres. Un shader les empile et les
colore pendant le jeu. C'est le même dessin sur l'écran de création, dans le monde et
pendant un combat. L'outil est `tools/draw_player_layers.gd`, et les calques sont dans
`view3d/layers/`.

**Ce qu'on a peint nous-mêmes, sur ton voyageur :**

- une tête sous tes cheveux, là où on ne la voyait jamais (pour le crâne rasé) ;
- cinq coiffures (courte, longue, attachée, tressée, rasée) et trois barbes, peintes
  avec la texture de tes propres cheveux ;
- des pièces d'équipement, prises sur les tenues du §15 : une épée à la ceinture et à la
  main, un arc, la calotte de cuir des gardes de l'usine, le heaume et la cuirasse des
  gardes du roi. Un casque cache les cheveux avec un masque : une image qui dit où les
  cheveux ne doivent pas se voir.

Le joueur choisit sa coiffure, la couleur de ses cheveux, sa peau, sa barbe et la couleur
de ses vêtements. Il commence en tunique et pantalon de toile. **La première épée est
posée sur une tombe**, juste après la fée. Un garde battu laisse ce qu'il portait.

**Une épée posée sur une tombe**, en 3D : quatre blocs (lame, garde, poignée, pommeau),
peints seulement avec ta roche, ton bois et ton sombre. Un test le vérifie.

**Ce qui reste à toi :** tes animations, ton contour, la forme de tes ombres, ton visage.
Une seule retouche : sous tes cheveux, ton visage est plus sombre là où tombe la frange.
Avec une autre coiffure, cette ombre faisait un trait orange sur le front. On utilise donc
une deuxième peau, sans cette ombre, pour toutes les coiffures sauf la tienne. Avec tes
cheveux, ta peau reste exactement la tienne.
On n'a rien redessiné de tout ça : on a découpé et recoloré.

**Ce que tu pourrais dessiner à la place**, si tu veux : des coiffures, des barbes et des
pièces d'équipement dans ton style, chacune comme un calque à part, au repos, en marche
et au combat, dans les quatre directions. Les planches sont dans
`docs/frames/creation/` et `docs/frames/gear/`.
