# Historique des versions

Ce fichier répertorie les changements notables apportés à PadMac.

Le format suit l'esprit de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/). Les versions publiées sont identifiées par un tag Git et une GitHub Release correspondante.

## [Unreleased]

Aucun changement enregistré pour le moment.

## [1.2.0] - 2026-11-21

Évolution fonctionnelle du profil PlayStation DualShock 4 avec l'activation du pavé tactile et une amélioration de son ergonomie.

### Ajouté

- Activation des gestes à un doigt sur le pavé tactile DualShock 4.
- Conversion des déplacements tactiles en commandes analogiques X/Y du stick sélectionné.
- Possibilité de choisir le stick piloté par le pavé tactile (gauche ou droit).
- Réglage de la sensibilité du pavé tactile.
- Gestion de priorité : le pavé tactile prend temporairement la main sur le stick ciblé pendant le contact, puis la commande physique reprend au relâchement.

### Modifié

- Agrandissement de la surface du pavé tactile DualShock 4 : largeur relative portée à 35 %, largeur maximale à 270 px et hauteur à 58 px.
- Repositionnement vertical du pavé tactile légèrement vers le haut.
- Mise à jour de la documentation des fonctionnalités et des limites du profil DualShock 4.

### Technique

- Conservation du rapport HID existant de 16 octets et de la transmission Bluetooth HID actuelle.
- Aucun changement requis dans les services Kotlin, le manifeste Android ou les dépendances Flutter pour cette fonctionnalité.

### Limites connues

- Les gestes sont convertis en axes analogiques génériques ; les coordonnées multitouch natives du DualShock 4 ne sont pas transmises.
- Le clic physique du pavé tactile n'est pas exposé comme bouton distinct.
- La compatibilité effective reste dépendante de la détection du contrôleur et du profil virtuel configuré dans OpenJoystickDriver, ainsi que du jeu ou de l'application utilisé.

## [1.1.2] - 2026-11-21

Mise à jour corrective qui étend le retour haptique aux commandes tactiles de la manette.

### Ajouté

- Retour haptique léger sur les boutons virtuels : boutons de façade, croix directionnelle, commandes centrales, boutons d’épaule et clics L3/R3.
- Retour haptique au début de l’appui sur les gâchettes LT/RT, sans vibration répétée pendant le maintien ou les changements de pression.

### Modifié

- Harmonisation du retour haptique entre les commandes tactiles des trois profils de manette.

## [1.1.1] - 2026-11-21

Mise à jour corrective et visuelle de l'interface, sans changement annoncé du protocole HID ni des profils de manette.

### Modifié

- Affichage des variantes PNG du logo dans leurs couleurs d'origine, sans filtre monochrome, sur le splash screen.
- Allègement du splash screen avec suppression de la mention « ANDROID • MAC ».
- Raccourcissement du libellé « Balayage automatique de test » en « Balayage automatique » sur l'écran de connexion, sans modifier le fonctionnement du balayage.

## [1.1.0] - 2026-11-21

Évolution majeure de l'interface et de la prise en charge des profils de manettes. PadMac ne se limite plus à une disposition inspirée de Xbox et propose désormais trois expériences adaptées aux profils Xbox, PlayStation DualShock 4 et Nintendo Switch Pro.

### Ajouté

- Prise en charge de trois profils de manettes : Xbox, PlayStation DualShock 4 et Nintendo Switch Pro.
- Dispositions tactiles spécifiques à chaque profil, avec adaptation de l'organisation et du positionnement des commandes.
- Symboles et libellés des boutons de façade adaptés aux conventions de chaque profil.
- Palettes graphiques dédiées : vert pour Xbox, bleu pour PlayStation et rouge pour Nintendo Switch Pro.
- Sauvegarde du profil sélectionné et restauration automatique au prochain lancement de l'application.
- Variantes du logo PadMac propres à chaque profil.
- Aperçu visuel du pavé tactile DualShock 4.
- Retour haptique lors de l'activation des clics de sticks L3 et R3.

### Modifié

- Adaptation du comportement des gâchettes au profil sélectionné : fonctionnement analogique pour Xbox et DualShock 4, numérique pour Nintendo Switch Pro.
- Application automatique de la palette du profil actif à l'interface.
- Affichage du logo correspondant au profil sélectionné sur l'écran de démarrage et la page de connexion.
- Refonte du splash screen : présentation plus minimaliste, animation progressive et meilleure répartition de l'espace disponible.
- Amélioration de l'organisation visuelle des dispositions de manettes.

### Documentation

- Mise à jour du README.md pour présenter les trois profils, leurs particularités et les limites connues.
- Actualisation de la structure du projet et des ressources graphiques documentées.
- Mise à jour de `THIRD_PARTY_NOTICES.md` avec les dépendances directes identifiées, leurs licences et les vérifications restant à effectuer.

### Limites connues

- Le pavé tactile DualShock 4 est uniquement présenté à titre d'aperçu visuel ; il n'est pas encore interactif et ses coordonnées ne sont pas transmises par le rapport HID.
- La variation analogique des gâchettes dépend des informations de pression réellement fournies par l'écran tactile. Sur un appareil ne signalant pas de pression variable, l'appui peut se comporter comme une commande numérique.
- La compatibilité finale dépend également de la détection du contrôleur et du profil virtuel configuré dans OpenJoystickDriver, ainsi que du jeu ou de l'application utilisé.

## [1.0.0] - 2026-11-20

Première version de PadMac préparée pour une publication stable.

### Ajouté

- Application Android développée avec Flutter pour utiliser le téléphone comme manette Bluetooth avec un Mac.
- Interface tactile inspirée des manettes Xbox avec boutons ABXY, croix directionnelle, sticks, gâchettes LT/RT et boutons centraux.
- Communication HID Bluetooth avec OpenJoystickDriver sur macOS.
- Écrans de connexion, de manette et de paramètres.
- Réglages de taille, de sensibilité et de zone morte des sticks, ainsi que de sensibilité des gâchettes.
- Écran de démarrage et identité visuelle PadMac.
- Journal d'événements pour faciliter le diagnostic de la connexion.
- Mode de balayage automatique pour tester les entrées de la manette dans OJD.

### Documentation

- Documentation de l'installation et de la configuration d'OpenJoystickDriver.
- Instructions de développement, de génération d'APK et de diagnostic.
- Ajout des notices relatives aux dépendances tierces.
