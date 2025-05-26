# 🚀 2022-USMB-CMI_OPTIMISATION_BARRAGE – Optimisation de la Production d’un Barrage Hydraulique
Optimisation mathématique de la production d’un barrage hydraulique à l’aide de la programmation dynamique et de l’équation de Bellman.

🎓 Projet universitaire réalisé dans le cadre de la Licence Mathématiques - CMI Mathématiques Appliquées à l'Université Savoie Mont Blanc (USMB)

---

## 🎯 Objectifs du Projet
Concevoir et implémenter un algorithme d’**optimisation de la production électrique** d’un barrage hydraulique selon différents **scénarios de débits entrants**, en maximisant le rendement économique via la **programmation dynamique**.

### Cas étudiés :

1. 🔁 Débit entrant constant
2. 📈 Débit entrant variant de manière sinusoïdale
3. 🌊 Débit entrant contenant un épisode de crue

### Extensions :

- 💸 **Tarification horaire** : prise en compte de l’évolution du prix de l’électricité en fonction de l’heure de la journée, afin de maximiser le gain financier
- 🎲 **Stochasticité** : modélisation d’un débit entrant aléatoire, via une chaîne de Markov et implémentation de l’équation de programmation dynamique stochastique associée
- 🏞️ **Multi-barrages** : extension du modèle à un barrage à deux puis trois retenues, avec une adaptation de l’équation de programmation dynamique et de l'algorithme associé
- 🧠 **Modèle en graphe** : modélisation du réseau de retenues sous forme de graphe, avec matrice d'adjacence

---

## 🛠️ Méthodologie & Stack

- **Langage** : MATLAB
- **Méthodes** : Programmation Dynamique Déterministe & Stochastique
- **Modélisation** : Chaînes de Markov, Optimisation multi-étapes, Graphes

---

## 📊 Résultats et Analyses

- Visualisation des politiques optimales et de la production selon les configurations
- Interprétation des stratégies de maximisation des gains économiques, déterminées par les différentes versions de l'algorithme, selons les configurations des retenues et des entrées d'eaux
- Résultats illustrés et analysés dans le [rapport final](./Projet601.pdf)

---

## 📂 Structure du dépôt

- 📁 src/ # Scripts MATLAB du projet
- 📄 Projet601.pdf # Rapport final avec résultats et analyses
- 📊 Projet 601 présentation.pptx
- 📄 README.md # Présentation du projet

---

## 🧑‍💻 Auteur

Julien Ducrey
💬 Pour toute remarque, question ou suggestion : n’hésitez pas à ouvrir une issue ou me contacter directement.

---

## 📌 Note

Ce projet académique a été mené dans un **cadre pédagogique**, mais les méthodes sont réutilisables dans des cas industriels de gestion énergétique et de smart grid. 
