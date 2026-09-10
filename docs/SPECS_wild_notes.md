# Uncrowned — raw notes

> Yannick's original notes, kept verbatim as source material.
> **Superseded by `SPECS.md`, which is the source of truth.**
> Nothing here is authoritative; it is preserved because the phrasing of an
> early idea is sometimes better than its formalisation.

---

## 1. History - Context - Goal - Higlevel

Goal is to kill/face the king in front of what he did and its consequence.
The kind destroyed nature, to create Steel manufacturing, destroy village doing war to accumulate gold and create differnce rule depending where people come from and how rich they are. he doesnt like poor people.  
The Hero came from a town that has been destroyed by king's men to create steel factory. It was a small peacful village where people used to live by farming and enjoying life. 
Hero's family has been killed like all the poeple living threr. The hero survived by miracle but lost a lot of memory. Only remember some part of his past. But he knows and rmemeber kings en destroy his village and kills people he loved.
The goal is to evolve in the open world, to find a way to confront the king. We could kill him or not. The whole game idea is to give a huge freedom to the player. We could finish the game without killing anyone. Or by killing everyone. Every NPC can be killed.
This is an open world fantasy with some magic, but magic is not somehting everyone practice. 

Idea of the game is that the hero will evolve in sa world where depending what he is doing he will be considered as hero or considred as no one.
He will evolve in a simulation kind of. 
So if he enters in a new town, dependng the interaction how he looks what he said/knows the interaction with people will be dramtaically different.

I want the game also to be like Zelda breath of the wild in the particular point: If the player manage to find a way to directly go to the king he can interact and kill him. He might by be desgin almso impossible because at thte start of the game the player will have no stats, also no context on why the king is acting like that and also the king will be strong with a lot of support.

Another things we want to get inspiration is Assassins creed Odyssey. In that game for each region ypu can ether kill the leader either sparte or Athen. But to have an easy fight you can wekness the leader postion by attakin camp or burning some ressurces. 
In our game we will have only one xone but free key quests will invlve to weakness kings assets. That will be also a way to learn more on why and how he is acting like that.

While playing the game , the player should feel each reset of the game unique in the sense the player choices will highly impact how th workd react to his action.

I want to player to evolve in a simulation where everyone lives her own life. If player do nothing the world around him is continue to evlove. But also the choice he is doing has always consequence we can see.

The player creation will follow the Fallout loigc where at the start a certain number of point needs to be allocated to traits such as inteligence, agility etc

---

## 2. The world and the map

My vision: What we should target ultimatly: Zelda Echoes of Wisdom Grphics like
What we can start with: The Legend of Zelda: A Link to the Past GRphics like

The map will be open world where the user can navigate via the grid like in The Legend of Zelda: A Link to the Past.
I will provide a draw of a map. For twon and donjon it will be a grid itelf so when a user see a town it will enter a spefic zone.
King's castle same logic.
Ideally we will have with the capital and the king's Castle. 2,3 towns and 2,3 dunjon/small castle.
When I said we could fight the king directly like in Zelda breathc of the wild I meant that if the user fnd a way to enter the castle (he shouldnt have the right to enter because at the start of the game he is no one. But we want the game open and permissive in certain way so if the plauyer find a way he can confront the king.)


---

## 3. The NPC interecation - Local LLM.

The workflow I imagine. Local LLM with a low level RAG where each document of the local RAG is NPC descritpion, the history the famliy links etc. So it is almsot like a grph rag becasue there is relation via the other NPC and also the player. 

High level description of intercation.
Player go to NPC 1. when player enter to action button/caht button it opens the chat.
Since player initiate the chat, the local llm provide 3/4 options of waht the player can ask. It depends on context the player gather during the past plays.
So as example we are at the start of the game the player wake up losing half memory, walk and enter the first village without doing anything between.
Clicking on chatting to the first NPC will lead to something like:

- Hello I am lost , where am I ? (inteligent traits if user select this traites when creating the player)
- Hello, my town has been destroyed by the king I need to find him (If user selected angry.furious traits when creating the player)
- Option 3
Thos chat option would be generated by the local llm levraging the context getting wrote in the sytsme based on waht the users saw and did. so the llm got a lot of cotnext form user interaction

The NPC will then says somthing according the NPC context and waht the user says. If the NPC never heard of the player it wont have access to his context.
Other scenario, iuf the user provide a quest or needs something, he can have in its own memory acces to past exhcngae etc.

The npoc needs and how a request/quest can be initaite will be based on how NPC context is built. So we can say for eample. Tom lied in Town ABC, and Tom lost his nsister in the forest. Tom is rich and looking for someone to help.
So if player appears , depenidng the user context and how interaction goes , the NPC can open this quest line.

---

## 4. Combat system

Every NPC can be fight and killed. This is up to the player to react correctly. Since we are on simualted workd, like in gta games if you killed poeple in frnt of otehr guard will fight and by deisgn at start of the gaem they might be better equiped and might killed you.
The comabt system will be no part of the open world.
LEts say you walk in the open world and you face a monster. A specifc screen wil appears, like in pokement or in Final fantasy RPG. However the fight will be like in fighting game. 2 d screen, user on the right, opponent or opponents on the left. Taht will be for the first version. Magic can be used if user decide to have those traits etc.


---
