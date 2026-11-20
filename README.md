# PadMac

**PadMac transforme un téléphone Android en manette Bluetooth utilisable avec un Mac.** L'application propose une interface tactile inspirée des manettes Xbox et transmet les commandes au Mac, où [OpenJoystickDriver (OJD)](https://github.com/GuardianOfDreams/OpenJoystickDriver) prend en charge la manette et expose un contrôleur virtuel à macOS.

> **État du projet** — La version actuelle cible principalement le scénario **Android → Bluetooth → macOS avec OpenJoystickDriver**. La compatibilité avec Windows n'est pas garantie et Windows n'est pas une plateforme officiellement prise en charge par ce projet.

## Fonctionnalités

- Connexion Bluetooth entre un téléphone Android et un Mac.
- Transmission des commandes à OpenJoystickDriver sur macOS.
- Interface tactile inspirée d'une manette Xbox : boutons ABXY, croix directionnelle, sticks, gâchettes et boutons centraux.
- Sticks analogiques et gâchettes LT/RT analogiques.
- Retour visuel lors des pressions, avec jauge LT/RT animée depuis le centre.
- Écrans de connexion, de manette et de paramètres.
- Personnalisation de la taille et de la sensibilité des sticks, de leur zone morte et de la sensibilité des gâchettes.
- Écran d'accueil en portrait et interface de manette en paysage immersif.
- Écran de démarrage et identité visuelle PadMac.
- Journal d'événements pour faciliter le diagnostic de la connexion.

**Persistance des paramètres :** dans la version actuelle, les réglages personnalisés sont conservés pendant l'exécution de l'application. Ils sont réinitialisés à leurs valeurs par défaut après la fermeture complète de l'application.

## Fonctionnement général

```text
Téléphone Android
      │
      │ Bluetooth
      ▼
OpenJoystickDriver (macOS)
      │
      ▼
Manette virtuelle reconnue par macOS
      │
      ▼
Jeux et applications compatibles
```

PadMac ne remplace pas OpenJoystickDriver sur le Mac. OJD reçoit les commandes de la manette Bluetooth et publie le périphérique virtuel utilisé par macOS et les applications compatibles. PadMac est développé avec Flutter.

## Architecture du projet

```text
lib/
├── main.dart             # Interface, navigation et gestion des commandes
├── splash_screen.dart    # Écran de démarrage PadMac
└── hid_gamepad.dart      # État de la manette et pont Flutter / Android natif

assets/
└── images/
    ├── padmac_brand.png
    └── padmac_app_icon_512.png

android/
└── app/src/main/
    ├── kotlin/           # Communication Bluetooth HID et service Android
    └── res/              # Icônes et ressources Android
```

## Prérequis

### Environnement de développement

- Flutter installé et configuré.
- Une version du SDK Dart compatible avec la contrainte du projet (`^3.14.0`).
- Android SDK et outils de compilation Android configurés.
- Un téléphone Android équipé du Bluetooth.
- Un câble USB ou un autre moyen de déployer l'application sur le téléphone.

### Mac cible

- Un Mac compatible avec la version d'OpenJoystickDriver installée.
- [OpenJoystickDriver](https://github.com/GuardianOfDreams/OpenJoystickDriver) installé et son service démarré.
- Les autorisations macOS demandées par OJD accordées, notamment Surveillance de l'entrée et Accessibilité lorsque cela est requis par la version de macOS utilisée.
- Le téléphone et le Mac à portée Bluetooth.

Consulte la documentation d'OpenJoystickDriver pour les instructions d'installation, les autorisations et les éventuelles limites de compatibilité.

## Installation et lancement en développement

Depuis la racine du projet :

```bash
flutter doctor -v
flutter pub get
flutter analyze
flutter run
```

Un appareil Android doit être connecté et détecté par Flutter. Pour vérifier les appareils disponibles :

```bash
flutter devices
```

### Régénérer l'icône Android

L'image source de l'icône est `assets/images/padmac_app_icon_512.png`. Après installation des dépendances, régénère les icônes avec :

```bash
dart run flutter_launcher_icons
```

La configuration du générateur se trouve dans `pubspec.yaml`, sous `flutter_launcher_icons:`.

## Préparer le Mac avec OpenJoystickDriver

Sur le Mac, vérifie d'abord l'état du service et les manettes détectées :

```bash
ojd status
ojd controller list
```

Après avoir connecté le téléphone depuis PadMac, récupère l'identifiant de la manette affiché par OJD, puis inspecte ses entrées :

```bash
ojd controller show IDENTIFIANT_DE_LA_MANETTE
ojd controller watch IDENTIFIANT_DE_LA_MANETTE --duration 20 --output
```

Remplace `IDENTIFIANT_DE_LA_MANETTE` par l'identifiant réellement retourné par OJD.

Pendant le test, les axes et les gâchettes doivent revenir à zéro au repos. Lorsqu'une commande est manipulée, seules les valeurs correspondantes doivent évoluer.

Le profil virtuel validé pendant les essais de PadMac est `game-controller-compatible`. Le nom du profil et les options disponibles peuvent varier selon la version d'OJD installée.

## Générer un APK

Pour générer un APK de test en mode release :

```bash
flutter build apk --release
```

Le fichier est normalement créé à l'emplacement suivant :

```text
build/app/outputs/flutter-apk/app-release.apk
```

Pour installer l'application sur un appareil Android connecté :

```bash
flutter install
```

## Vérifications avant publication

Avant de publier une modification, exécute les contrôles suivants depuis la racine du projet :

```bash
flutter pub get
flutter analyze
flutter test
```

Si aucun test automatisé n'a encore été ajouté, `flutter test` peut ne pas avoir de tests utiles à exécuter. Il est recommandé d'en créer progressivement.

Avant chaque commit, vérifie avec `git status` que le dépôt ne contient pas de clés, certificats privés, fichiers locaux, caches ou sorties de compilation qui ne doivent pas être publiés. Le fichier `.gitignore` doit être présent et adapté au projet.

Conserve `pubspec.lock` dans le dépôt : pour une application Flutter, il permet de retrouver les versions exactes des dépendances résolues.

## Dépannage

- **Le Mac ne détecte pas le téléphone :** vérifie le Bluetooth, les autorisations Android et l'état du service OJD avec `ojd status`.
- **OJD détecte le téléphone, mais aucune manette virtuelle n'apparaît :** vérifie la publication du périphérique dans OJD et le profil virtuel sélectionné.
- **Une commande reste active après relâchement :** exécute `ojd controller watch ... --output` et vérifie que l'axe ou la gâchette revient à zéro. Consulte également le journal d'événements de PadMac.
- **L'icône de l'application ne change pas :** relance `dart run flutter_launcher_icons`, puis reconstruis l'application. Android peut conserver temporairement l'ancienne icône en cache.
- **Une dépendance pose problème :** vérifie les versions avec `flutter --version`, puis relance `flutter pub get`.

## Compatibilité et limites connues

- Le scénario principalement visé et testé est **Android → Bluetooth → OpenJoystickDriver sur macOS**.
- La compatibilité avec Windows, d'autres pilotes de manette virtuelle ou d'autres profils OJD n'est pas garantie.
- Les autorisations Bluetooth et les restrictions liées aux services en arrière-plan varient selon les versions d'Android et les fabricants.
- Une compilation réussie ne remplace pas un test réel avec le téléphone, le Mac, OJD et un jeu ou un outil de test de manette.

## Licence

PadMac est distribué sous les termes de la **[PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0)**.

Cette licence autorise l'utilisation, la modification et la redistribution du projet pour des usages non commerciaux, sous réserve du respect de ses conditions. Elle n'accorde pas de permission générale pour une exploitation commerciale. Toute utilisation commerciale nécessite une autorisation distincte du titulaire des droits.

Le texte intégral de la licence est disponible dans le fichier [`LICENSE`](LICENSE). Cette licence est une licence à restriction non commerciale : le projet est publiquement consultable et son code est disponible, mais il ne s'agit pas d'un logiciel open source au sens habituel des licences qui autorisent aussi les usages commerciaux.

Les dépendances, outils, ressources et composants tiers éventuellement inclus dans le dépôt restent soumis à leurs propres licences. La licence de PadMac ne remplace pas ces licences tierces.

## Contact

Pour toute question, remarque ou proposition de collaboration :

- **X :** [@OGDJOUD](https://x.com/OGDJOUD)
- **LinkedIn :** [OG DJOUD](https://www.linkedin.com/in/djoud-og/)
