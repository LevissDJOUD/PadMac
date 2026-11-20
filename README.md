# PadMac

**PadMac transforme un téléphone Android en manette Bluetooth utilisable avec un Mac.** L'application propose une interface tactile inspirée des manettes Xbox et transmet les commandes au Mac, où [OpenJoystickDriver (OJD)](https://github.com/xsyetopz/OpenJoystickDriver) prend en charge la manette et expose un contrôleur virtuel à macOS.

> **État du projet** — PadMac cible principalement le scénario **Android → Bluetooth → macOS avec OpenJoystickDriver**. La compatibilité avec Windows n'est pas garantie et Windows n'est pas une plateforme officiellement prise en charge.

## Fonctionnalités

- Connexion Bluetooth entre un téléphone Android et un Mac.
- Transmission des commandes à OpenJoystickDriver sur macOS.
- Interface tactile inspirée d'une manette Xbox : boutons ABXY, croix directionnelle, sticks, gâchettes et boutons centraux.
- Sticks analogiques et gâchettes LT/RT.
- Retour visuel lors des pressions, avec jauge LT/RT animée.
- Écrans de connexion, de manette et de paramètres.
- Personnalisation de la taille et de la sensibilité des sticks, de leur zone morte et de la sensibilité des gâchettes.
- Écran d'accueil en portrait et interface de manette en paysage immersif.
- Écran de démarrage et identité visuelle PadMac.
- Journal d'événements pour faciliter le diagnostic de la connexion.

**Persistance des paramètres :** dans la version actuelle, les réglages personnalisés sont conservés pendant l'exécution de l'application. Ils reviennent à leurs valeurs par défaut après la fermeture complète de l'application.

## Fonctionnement général

```text
Téléphone Android
       │
       │ Bluetooth HID
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

## Prérequis

### Téléphone Android et développement

- Un téléphone Android équipé du Bluetooth.
- Flutter installé et configuré.
- Un SDK Dart compatible avec la contrainte du projet (`^3.14.0`).
- Android SDK et outils de compilation Android configurés.
- Un câble USB ou un autre moyen de déployer l'application sur le téléphone.

### Mac cible

- Un Mac sous macOS 12 (Monterey) ou une version ultérieure, compatible avec la version d'OJD utilisée.
- [OpenJoystickDriver](https://github.com/GuardianOfDreams/OpenJoystickDriver) installé et lancé.
- Les autorisations macOS demandées par OJD accordées, notamment **Surveillance de l'entrée** et **Accessibilité** (les intitulés peuvent varier selon la version de macOS).
- Le téléphone et le Mac à portée Bluetooth.

## Préparer le Mac avec OpenJoystickDriver

> **À effectuer avant les commandes `ojd` ci-dessous.** La commande `ojd` est fournie avec l'application OpenJoystickDriver : elle doit être installée depuis les réglages d'OJD avant de pouvoir être utilisée dans le Terminal.

### 1. Installer OpenJoystickDriver

1. Ouvre le [dépôt officiel d'OpenJoystickDriver](https://github.com/GuardianOfDreams/OpenJoystickDriver) et accède à ses versions publiées.
2. Télécharge le fichier `.dmg` correspondant à la version souhaitée.
3. Ouvre l'image disque et fais glisser `OpenJoystickDriver.app` dans le dossier **Applications**.
4. Éjecte l'image disque, puis lance OpenJoystickDriver depuis **Applications**.

Conserve l'application dans `/Applications` : certaines opérations d'OJD s'attendent à ce qu'elle se trouve à cet emplacement.

### 2. Accorder les autorisations macOS

1. Clique sur l'icône du contrôleur OpenJoystickDriver dans la barre des menus.
2. Ouvre la fenêtre principale d'OJD.
3. Si OJD indique qu'un accès est nécessaire, utilise l'action **Grant Access** ou les boutons de demande d'autorisation proposés.
4. Dans les réglages **Confidentialité et sécurité** de macOS, autorise OpenJoystickDriver pour **Surveillance de l'entrée** et **Accessibilité**, lorsque ces autorisations sont demandées.
5. Si OJD propose de redémarrer l'application après l'octroi des autorisations, effectue cette action.

### 3. Installer la commande `ojd` depuis les réglages d'OJD

Cette étape est indispensable pour utiliser les commandes du Terminal présentées dans la suite du README.

1. Ouvre les **Settings** d'OpenJoystickDriver.
2. Sélectionne **Install Command-Line Tool**.
3. Autorise macOS à effectuer l'opération et saisis ton mot de passe administrateur si macOS le demande.

OJD crée alors le lien de commande `/usr/local/bin/ojd` vers l'exécutable de l'application. Il n'est normalement pas nécessaire d'installer séparément un autre package CLI.

Vérifie ensuite dans le Terminal :

```bash
which ojd
ojd status
```

La première commande doit localiser `ojd`. La seconde affiche l'état du service OJD, de ses autorisations et des périphériques disponibles. Si le Terminal répond `command not found`, retourne dans les réglages d'OJD et vérifie que **Install Command-Line Tool** a bien été exécuté.

### 4. Connecter PadMac et vérifier la manette

1. Lance PadMac sur le téléphone Android et initialise le périphérique HID.
2. Rends le téléphone visible et effectue l'appairage Bluetooth avec le Mac si nécessaire.
3. Depuis PadMac, connecte le Mac dans la liste des appareils appairés.
4. Dans le menu d'OJD, vérifie que le téléphone apparaît dans la section des contrôleurs.
5. Dans OJD, sélectionne le contrôleur et utilise **Open Input Test** pour vérifier les boutons, les sticks et les gâchettes.

Tu peux également effectuer les vérifications depuis le Terminal :

```bash
ojd status
ojd controller list
```

Récupère l'identifiant réellement affiché par `ojd controller list`, puis remplace `IDENTIFIANT_DE_LA_MANETTE` dans les commandes suivantes :

```bash
ojd controller show IDENTIFIANT_DE_LA_MANETTE
ojd controller watch IDENTIFIANT_DE_LA_MANETTE --duration 20 --output
```

Pendant le test, les axes et les gâchettes doivent revenir à leur valeur de repos après relâchement. Lorsqu'une commande est manipulée, les valeurs correspondantes doivent évoluer. L'option `--output` permet également d'observer les valeurs envoyées au périphérique virtuel après le mappage OJD.

Le profil virtuel utilisé pendant les essais de PadMac a été noté `game-controller-compatible`. Le nom et les profils disponibles peuvent varier selon la version d'OJD ; vérifie le profil effectivement proposé et sélectionné dans l'application OJD.

Pour les détails et les commandes disponibles, consulte la [documentation officielle d'OpenJoystickDriver](https://github.com/GuardianOfDreams/OpenJoystickDriver).

## Installation et lancement en développement

Depuis la racine du projet :

```bash
flutter doctor -v
flutter pub get
flutter analyze
flutter run
```

Vérifie que Flutter détecte bien le téléphone :

```bash
flutter devices
```

### Régénérer l'icône Android

L'image source de l'icône est `assets/images/padmac_app_icon_512.png`. Après installation des dépendances, régénère les icônes avec :

```bash
dart run flutter_launcher_icons
```

La configuration du générateur se trouve dans `pubspec.yaml`, sous `flutter_launcher_icons:`.

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
- **La commande `ojd` est introuvable :** retourne dans les réglages d'OJD et utilise **Install Command-Line Tool**. Vérifie également que `/usr/local/bin` est accessible depuis le `PATH` du Terminal.
- **OJD détecte le téléphone, mais aucune manette virtuelle n'apparaît :** vérifie la connexion HID, le contrôleur sélectionné et le profil virtuel configuré dans OJD.
- **Une commande reste active après relâchement :** exécute `ojd controller watch IDENTIFIANT_DE_LA_MANETTE --output` et vérifie que l'axe ou la gâchette revient à sa valeur de repos. Consulte également le journal d'événements de PadMac.
- **L'icône de l'application ne change pas :** relance `dart run flutter_launcher_icons`, puis reconstruis l'application. Android peut conserver temporairement l'ancienne icône en cache.
- **Une dépendance pose problème :** vérifie les versions avec `flutter --version`, puis relance `flutter pub get`.

## Compatibilité et limites connues

- Le scénario principalement visé et testé est **Android → Bluetooth → OpenJoystickDriver sur macOS**.
- La compatibilité avec Windows, d'autres pilotes de manette virtuelle ou d'autres profils OJD n'est pas garantie.
- Les autorisations Bluetooth et les restrictions liées aux services en arrière-plan varient selon les versions d'Android et les fabricants.
- Une compilation réussie ne remplace pas un test réel avec le téléphone, le Mac, OJD et un jeu ou un outil de test de manette.

## Signaler un problème

Les rapports de bugs et les propositions d'amélioration peuvent être déposés dans l'onglet **Issues** du dépôt GitHub. Avant de créer un ticket, indique si possible le modèle du téléphone, la version d'Android, la version de macOS, la version d'OJD et les étapes permettant de reproduire le problème. Ne joins pas de données personnelles ni d'informations sensibles provenant des journaux.

## Licence

PadMac est distribué sous les termes de la **[PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0)**.

Cette licence autorise l'utilisation, la modification et la redistribution du projet pour des usages non commerciaux, sous réserve du respect de ses conditions. Elle n'accorde pas de permission générale pour une exploitation commerciale. Toute utilisation commerciale nécessite une autorisation distincte du titulaire des droits.

Le texte intégral est disponible dans le fichier [`LICENSE`](LICENSE). PadMac est un projet à code source disponible soumis à une restriction non commerciale ; il ne s'agit pas d'un logiciel open source au sens des licences qui autorisent également les usages commerciaux.

Les packages, outils, ressources et composants tiers restent soumis à leurs propres licences. Consulte [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) pour les attributions et références correspondantes.

## Historique des versions

Les modifications du projet sont consignées dans [`CHANGELOG.md`](CHANGELOG.md). Les versions officielles seront publiées dans l'onglet **Releases** du dépôt.

## Contact

Pour toute question, remarque ou proposition de collaboration :

<p>
  <a href="https://x.com/OGDJOUD">
    <img src="https://img.shields.io/badge/X-000000?style=for-the-badge&logo=x&logoColor=white" alt="X — @OGDJOUD" />
  </a>
  <a href="https://www.linkedin.com/in/djoud-og/">
    <img src="https://img.shields.io/badge/LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn — OG DJOUD" />
  </a>
</p>
