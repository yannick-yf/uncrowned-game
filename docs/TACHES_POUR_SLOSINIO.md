# Pour slosinio — ta liste de tâches pour la démo

Écrit le 2026-09-29, pour toi. Une page, dans l'ordre de priorité.

La longue lettre (`docs/POUR_SLOSINIO.md`) explique le pourquoi de chaque point. Ici, il
n'y a que le quoi. Rien de cette liste n'est une commande : tu dis oui, non ou plus
tard, point par point.

**La démo, c'est ce trajet** : on se réveille dans le cimetière au sud de Brindle, Bram
nous appelle, trois entraînements au combat, la route vers le nord, deux loups avant le
pont, puis l'usine et sa quête. Tout ce qui est hors de ce trajet passe après.

---

## 1. Urgent : tes maillages compressés

**Le problème.** Tes maillages fusionnés (le verger du village fermier, sa verdure, la
côte) sont enregistrés en binaire compressé (en-tête `RSCC`). À l'intérieur, chaque
dépendance est écrite avec le chemin de **ton** projet, par exemple
`res://assets/farming/meshes/pommier_etale_Merged_bark.res`. Notre copie de ton projet
change ces chemins dans les fichiers texte, mais elle ne peut pas le faire dans un
binaire compressé.

**Ce que ça fait aujourd'hui.** On a retiré trois secteurs de notre copie :
`VillageFermier`, `FarmingAtmosphere` et `CoastlineDecor`. Sans ça, le jeu affichait
412 erreurs au lancement. Mais depuis que le jeu commence au cimetière, la côte est sur
le premier écran : **tes falaises apparaissent nues**, et il y a des trous pâles dans le
sol, là où devraient être la mer ou la côte.

**Ce qu'on te demande.** Dans ton outil de fusion, au choix :
- intégrer les maillages dans le multimesh au lieu de les référencer ;
- ou les enregistrer non compressés, avec des chemins relatifs.

**Et pour tes pièces de côte** (par exemple `amas_galets_granit`) : assigner la matière
dans la scène plutôt que dans le maillage. Aujourd'hui son maillage garde le chemin
`res://assets/coastline/materials/coastal_granite.tres`, et on ne peut pas le réécrire.

On saura que c'est réglé quand ces trois secteurs se chargent chez nous sans erreur.

---

## 2. Ce que tu n'as pas dessiné, et qu'on a remplacé en attendant

Pour chacun, on a fait une version à nous. Elle utilise seulement tes couleurs et tes
matières. Le jour où tu dessines le tien, un test le voit et on retire le nôtre.

| Quoi | Ce qu'on a fait en attendant | Ce qu'il faudrait |
|---|---|---|
| **Le combat du voyageur** | 12 images tirées de tes images : bras armé, coup, recul, dans les quatre directions | La préparation du coup, le coup et le recul, dans les quatre directions |
| **L'arc** (bientôt) | Rien encore. Le joueur va tirer à l'arc dans le tutoriel | Une pose « arc bandé » dans les quatre directions, et une flèche |
| **Un animal** | Le loup : onze blocs, peints avec ta roche et ton sombre | Un loup, qui marche et qui mord |
| **Une tombe** | Des stèles en pierre et des planches en bois, faites avec tes matières | Un petit kit de cimetière : deux ou trois pierres tombales, une croix de bois, un tertre de terre, un tertre herbeux, un muret bas |
| **Un feu de camp** | Composé de tes pièces (pierres, bûches, braises, fumée) ; seules les flammes sont à nous | Un feu de camp à toi, si tu veux |
| **Le « ! » au-dessus de Bram** | Une barre et un point couleur braise, dessinés en code | Facultatif : un « ! » peint à ta main |

---

## 3. L'usine : quatre questions ouvertes

1. **La clôture et la porte de la cour.** On a monté la cour des fourneaux avec tes
   modules (`soubassement_2m`, `portail_cour`). Si tu préfères la poser toi-même dans
   ton atelier, le jeu lira la tienne à la place de la nôtre.
2. **La pollution visible** : elle pèse sur l'usine qui tourne, et elle se lève quand
   l'usine s'arrête. C'est à toi de dire comment elle se dessine.
3. **Des pièces d'usine détruite** : le signal le plus fort pour la victoire des
   ouvriers, mais le plus cher. Est-ce que ça vaut le travail ?
4. **Moins de bâtiments** : l'usine en a 27. Est-ce que tu veux en retirer ?

---

## 4. La carte : trois écarts à régler avec Yannick

Ce ne sont pas des erreurs de ta part. La spec a été écrite pour l'ancienne carte 2D.

1. **Les fourneaux sont loin de Brindle** : environ 160 m au nord. La spec voulait les
   voir depuis les ruines. Soit tu les rapproches, soit on adapte l'histoire.
2. **La route** : il faut 147 s pour la parcourir à ta vitesse de marche, et elle est
   presque droite (rapport 1,24 ; la spec visait 1,30 à 1,50). À décider avec Yannick.
3. **Le nord est coupé** : tes deux affluents au nord du château isolent 15 % de la
   carte, sans pont. Soit un pont, soit une zone sauvage que personne ne visite.

---

## 5. À regarder avec Yannick

**La teinte de lumière selon l'allégeance** : plus chaude dans un lieu loyal au roi,
plus froide dans un lieu hostile. Yannick n'est pas convaincu. Trois choix : la
garder, l'adoucir, ou montrer l'allégeance autrement (une bannière du roi, sa garde),
ce que toi tu peux dessiner.

---

## 6. Plus tard, hors du trajet de la démo

- **Les visages**, dans ton style. Aujourd'hui, tout le monde a le même. Pour la démo
  d'abord : Bram, Wren, Tom, Sena et Harry.
- **Tes pièces à la place de nos blocs gris** : les tentes, les bateaux, les étals,
  le donjon et ses tours, les corps de garde, un panneau à l'entrée de chaque ville.
- **Le remplissage de la carte** : Harrowgate, le Rassemblement, Saltmarch, les
  champs, les rues de Cairnwell et le château sont encore notre kit posé sur ton
  terrain.

---

## Pour information, rien à faire

- **La clairière des fées est supprimée.** Le joueur ne s'y réveille plus. Il n'y a
  plus d'anneau de bois à planter autour.
- **Le village de la scierie et la cité royale** : on les voit à l'écran, mais le jeu
  ne les lit pas encore. Yannick a décidé de les laisser tels quels pour le moment.
