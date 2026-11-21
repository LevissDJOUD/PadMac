# PadMac

**PadMac transforme un téléphone Android en manette Bluetooth utilisable avec un Mac.** L'application propose trois dispositions tactiles inspirées des manettes **Xbox**, **PlayStation DualShock 4** et **Nintendo Switch Pro**. Les commandes sont transmises au Mac en Bluetooth HID ; [OpenJoystickDriver (OJD)](https://github.com/xsyetopz/OpenJoystickDriver) prend ensuite en charge le contrôleur et expose un périphérique virtuel à macOS.

> **État du projet — v1.1.1 (build 3)** : PadMac cible principalement le scénario **Android → Bluetooth HID → macOS avec OpenJoystickDriver**. La compatibilité avec Windows et avec d'autres pilotes de manette virtuelle n'est pas garantie. Windows n'est pas une plateforme officiellement prise en charge.

## Fonctionnalités

- Connexion Bluetooth entre un téléphone Android et un Mac.
- Transmission des commandes au Mac via Bluetooth HID et prise en charge côté macOS par OpenJoystickDriver.
- Trois profils de manette sélectionnables : Xbox, PlayStation DualShock 4 et Nintendo Switch Pro.
- Dispositions tactiles adaptées à chaque profil : boutons de façade, croix directionnelle, sticks, gâchettes et commandes centrales.
- Symboles et libellés des boutons adaptés au profil sélectionné, notamment les symboles Triangle, Cercle, Croix et Carré pour PlayStation.
- Sticks analogiques avec réglages de taille, de sensibilité et de zone morte.
- Gâchettes analogiques pour les profils Xbox et DualShock 4 ; gâchettes numériques pour le profil Switch Pro.
- Retour visuel lors des pressions, avec jauges animées pour les gâchettes.
- Retour haptique lors de l'activation des clics de sticks L3 et R3.
- Palette et logo adaptés au profil sélectionné : vert pour Xbox, bleu pour PlayStation et rouge pour Nintendo Switch Pro.
- Sauvegarde du profil choisi et restauration automatique au prochain lancement.
- Écrans de connexion, de manette et de paramètres.
- Écran d'accueil en portrait et interface de manette en paysage immersif.
- Splash screen animé et identité visuelle PadMac adaptés au profil actif.
- Journal d'événements pour faciliter le diagnostic de la connexion.
- Mode de balayage automatique pour tester les entrées de la manette dans OJD.

### Particularités et limites des profils

- **Xbox** : disposition inspirée de la manette Xbox, avec gâchettes analogiques.
- **PlayStation DualShock 4** : disposition et symboles PlayStation, avec gâchettes analogiques. Le pavé tactile est actuellement un aperçu visuel non interactif ; ses coordonnées ne sont pas transmises par le rapport HID.
- **Nintendo Switch Pro** : disposition adaptée aux commandes Switch Pro, avec gâchettes ZL/ZR numériques.

La variation analogique des gâchettes dépend de la mesure de pression fournie par l'écran tactile. Si l'appareil ne signale pas de pression variable, PadMac peut interpréter l'appui comme une pression complète.

### Persistance des paramètres

Le **profil de manette sélectionné** est sauvegardé et restauré au prochain lancement de l'application.

Les réglages personnalisés des sticks et des gâchettes (taille, sensibilité et zone morte) sont actuellement conservés pendant l'exécution de l'application. Ils reviennent à leurs valeurs par défaut après la fermeture complète de l'application.

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

PadMac ne remplace pas OpenJoystickDriver sur le Mac. OJD reçoit les commandes de la manette Bluetooth et publie un périphérique virtuel que macOS et les applications compatibles peuvent utiliser. La détection finale dépend notamment du profil virtuel choisi dans OJD et de l'API de manette utilisée par le jeu. PadMac est développé avec Flutter.

## Prérequis

### Téléphone Android et développement

- Un téléphone Android équipé du Bluetooth.
- Flutter installé et configuré.
- Un SDK Dart compatible avec la contrainte du projet (`^3.14.0`).
- Android SDK et outils de compilation Android configurés.
- Un câble USB ou un autre moyen de déployer l'application sur le téléphone.

### Mac cible

- Un Mac compatible avec la version d'OpenJoystickDriver installée (vérifier les exigences indiquées pour la version téléchargée).
- [OpenJoystickDriver](https://github.com/xsyetopz/OpenJoystickDriver) installé et lancé.
- Les autorisations macOS demandées par OJD accordées, notamment **Surveillance de l'entrée** et **Accessibilité** lorsqu'elles sont requises.
- Le téléphone et le Mac à portée Bluetooth.

> Les exigences macOS peuvent évoluer entre les versions d'OJD. Consulte la page du dépôt et les notes de version de l'édition que tu installes plutôt que de supposer qu'une ancienne version minimale reste valable.

## Préparer le Mac avec OpenJoystickDriver

> **À effectuer avant les commandes `ojd` ci-dessous.** La commande `ojd` est fournie avec OpenJoystickDriver. Elle doit être installée depuis les réglages de l'application avant de pouvoir être utilisée dans le Terminal.

### 1. Installer OpenJoystickDriver

1. Ouvre le [dépôt officiel d'OpenJoystickDriver](https://github.com/xsyetopz/OpenJoystickDriver) et consulte ses [versions publiées](https://github.com/xsyetopz/OpenJoystickDriver/releases).
2. Télécharge le fichier `.dmg` correspondant à la version souhaitée.
3. Ouvre l'image disque et fais glisser `OpenJoystickDriver.app` dans le dossier **Applications**.
4. Éjecte l'image disque, puis lance OpenJoystickDriver depuis **Applications**.

Conserve l'application dans `/Applications` : certaines opérations de gestion d'OJD s'attendent à ce qu'elle se trouve à cet emplacement.

### 2. Accorder les autorisations macOS

1. Clique sur l'icône du contrôleur OpenJoystickDriver dans la barre des menus.
2. Ouvre la fenêtre principale ou les réglages d'OJD.
3. Si OJD affiche l'action **Grant Access**, utilise-la pour ouvrir les réglages macOS nécessaires.
4. Dans **Réglages Système → Confidentialité et sécurité**, autorise OpenJoystickDriver pour **Surveillance de l'entrée** et **Accessibilité**, lorsque ces autorisations sont demandées.
5. Si macOS ou OJD demande de relancer l'application, effectue cette action.

Les intitulés et l'emplacement des réglages peuvent varier selon la version de macOS.

### 3. Installer la commande `ojd`

Cette étape est nécessaire pour utiliser les commandes de diagnostic du Terminal.

1. Ouvre les **Settings** d'OpenJoystickDriver.
2. Sélectionne **Install Command-Line Tool**.
3. Autorise macOS à effectuer l'opération et saisis ton mot de passe administrateur si macOS le demande.

OJD installe alors la commande `ojd` (le lien usuel est `/usr/local/bin/ojd`). Il n'est normalement pas nécessaire d'installer un package CLI séparé.

Vérifie ensuite dans le Terminal :

```bash
which ojd
ojd status
```

Si le Terminal répond `command not found`, retourne dans les réglages d'OJD et vérifie que **Install Command-Line Tool** a bien été exécuté. Vérifie également que le répertoire contenant `ojd` est accessible depuis le `PATH` du Terminal.

### 4. Connecter PadMac et vérifier la manette

1. Lance PadMac sur le téléphone Android et initialise le périphérique HID.
2. Accorde les autorisations Bluetooth demandées par Android.
3. Rends le téléphone visible et effectue l'appairage Bluetooth avec le Mac si nécessaire.
4. Depuis PadMac, actualise la liste des appareils appairés et connecte le Mac.
5. Dans le menu d'OJD, ouvre la section **Controllers** et vérifie que le téléphone apparaît.
6. Sélectionne le contrôleur, puis ouvre **Open Input Test** pour vérifier les boutons, les sticks et les gâchettes.

Tu peux également vérifier l'état du service et les contrôleurs détectés depuis le Terminal :

```bash
ojd status
ojd controller list
```

Consulte la [documentation officielle d'OpenJoystickDriver](https://github.com/xsyetopz/OpenJoystickDriver) pour les commandes et options correspondant à la version installée. Les profils virtuels proposés par OJD peuvent influencer la manière dont les jeux détectent le contrôleur ; vérifie le profil disponible et sélectionné dans l'application OJD.

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

L'image source de l'icône de l'application est `assets/images/padmac_app_icon_512.png`. Après installation des dépendances, régénère les icônes avec :

```bash
dart run flutter_launcher_icons
```

La configuration du générateur se trouve dans `pubspec.yaml`, sous `flutter_launcher_icons:`.

## Architecture du projet

```text
lib/
├── main.dart                         # Interface, navigation et gestion des commandes
├── app_theme.dart                    # Palettes et thème selon le profil
├── brand_assets.dart                 # Sélection du logo selon le profil
├── controller_profile.dart           # Définition des profils de manette
├── playstation_glyph.dart             # Dessin des symboles PlayStation
├── splash_screen.dart                 # Écran de démarrage PadMac
├── hid_gamepad.dart                   # État de la manette et pont Flutter / Android natif
└── layouts/
    ├── controller_layout_spec.dart    # Spécifications communes des dispositions
    ├── xbox_layout.dart               # Disposition Xbox
    ├── dualshock4_layout.dart         # Disposition DualShock 4
    └── switch_pro_layout.dart         # Disposition Switch Pro

assets/
└── images/
    ├── padmac_brand_xbox.png
    ├── padmac_brand_playstation.png
    ├── padmac_brand_switch.png
    └── padmac_app_icon_512.png

android/
└── app/src/main/
    ├── kotlin/                        # Communication Bluetooth HID et service Android
    └── res/                           # Icônes et ressources Android
```

Adapte cette arborescence si des fichiers ont été déplacés ou renommés dans ta copie du projet.

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

- **Le Mac ne détecte pas le téléphone :** vérifie le Bluetooth, les autorisations Android, l'appairage et l'état du service OJD avec `ojd status`.
- **La commande `ojd` est introuvable :** retourne dans les réglages d'OJD et utilise **Install Command-Line Tool**. Vérifie également que le répertoire d'installation est accessible depuis le `PATH` du Terminal.
- **OJD détecte le téléphone, mais aucune manette virtuelle n'apparaît :** vérifie la connexion HID, le contrôleur sélectionné et le profil virtuel configuré dans OJD.
- **Une commande reste active après relâchement :** ouvre **Open Input Test** dans OJD et vérifie que l'axe ou la gâchette revient à sa valeur de repos. Consulte également le journal d'événements de PadMac.
- **La pression des gâchettes varie peu ou pas :** vérifie si l'écran tactile fournit une mesure de pression variable. Certains appareils ne permettent qu'un comportement proche du tout-ou-rien.
- **L'icône de l'application ne change pas :** relance `dart run flutter_launcher_icons`, puis reconstruis l'application. Android peut conserver temporairement l'ancienne icône en cache.
- **Une dépendance pose problème :** vérifie les versions avec `flutter --version`, puis relance `flutter pub get`.

## Compatibilité et limites connues

- Le scénario principalement visé est **Android → Bluetooth HID → OpenJoystickDriver sur macOS**.
- La compatibilité avec Windows, d'autres pilotes de manette virtuelle ou d'autres profils OJD n'est pas garantie.
- Le pavé tactile DualShock 4 est actuellement un aperçu visuel et n'envoie pas de coordonnées.
- La variation analogique des gâchettes dépend des capacités de mesure de pression de l'écran tactile.
- Les autorisations Bluetooth et les restrictions liées aux services en arrière-plan varient selon les versions d'Android et les fabricants.
- Certains jeux ou applications peuvent ne pas reconnaître le contrôleur virtuel, même si OJD le détecte correctement.
- Une compilation réussie ne remplace pas un test réel avec le téléphone, le Mac, OJD et un jeu ou un outil de test de manette.

## Signaler un problème

Les rapports de bugs et les propositions d'amélioration peuvent être déposés dans l'onglet [Issues](https://github.com/LevissDJOUD/PadMac/issues) du dépôt GitHub. Avant de créer un ticket, indique si possible le modèle du téléphone, la version d'Android, la version de macOS, la version d'OJD et les étapes permettant de reproduire le problème. Ne joins pas de données personnelles ni d'informations sensibles provenant des journaux.

## Licence

PadMac est distribué sous les termes de la **[PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/)**.

Cette licence autorise l'utilisation, la modification et la redistribution du projet pour des usages non commerciaux, sous réserve du respect de ses conditions. Elle n'accorde pas de permission générale pour une exploitation commerciale. Toute utilisation commerciale nécessite une autorisation distincte du titulaire des droits.

Le texte intégral est disponible dans le fichier [`LICENSE`](LICENSE). PadMac est un projet à code source disponible soumis à une restriction non commerciale ; il ne s'agit pas d'un logiciel open source au sens des licences qui autorisent également les usages commerciaux.

Les packages, outils, ressources et composants tiers restent soumis à leurs propres licences. Consulte [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) pour les attributions et références correspondantes.

## Historique des versions

Les modifications du projet sont consignées dans [`CHANGELOG.md`](CHANGELOG.md). Les versions officielles sont publiées dans l'onglet [Releases](https://github.com/LevissDJOUD/PadMac/releases) du dépôt.

## Contact

Retrouve-moi également sur :

<h3 align="center">Retrouvez-moi également sur</h3>

<p align="center">
  <a href="https://x.com/OGDJOUD"><img src="https://img.shields.io/badge/%40OGDJOUD-000000?style=flat&logo=x&logoColor=white" alt="X — @OGDJOUD" /></a>
  <br/><br/>
  <a href="https://www.linkedin.com/in/djoud-og/"><img src="https://img.shields.io/badge/LinkedIn-OG%20DJOUD-0A66C2?style=flat&logo=linkedin&logoColor=white" alt="LinkedIn — OG DJOUD" /></a>
</p>