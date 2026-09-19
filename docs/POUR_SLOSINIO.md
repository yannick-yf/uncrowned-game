# Pour slosinio — ce qu'on apprend en branchant la simulation sur ta carte

Écrit en français, pour toi. Mis à jour au fur et à mesure du travail.
Dernière mise à jour : 2026-09-18 (les gens qui marchent).

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
UNCROWNED_FIGHT=bram tools/shot.sh /tmp/combat.png play 280,315
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
