# Historique des versions

Ce fichier répertorie les changements notables apportés à PadMac.

Le format suit l'esprit de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/). Les versions publiées seront identifiées par un tag Git et une GitHub Release correspondante.

## [Unreleased] — Première version en préparation

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

> **Publication :** aucune version stable `v1.0.0` n'est déclarée ici. Le tag et la GitHub Release `v1.0.0` seront créés lorsque les tests de bout en bout sur Android, Bluetooth, macOS et OJD auront été jugés suffisamment concluants.
