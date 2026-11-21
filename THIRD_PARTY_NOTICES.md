# Notices relatives aux logiciels tiers

PadMac s'appuie sur Flutter, des packages Dart/Flutter et des composants fournis par des tiers. Ce document rassemble les principales attributions identifiées pour le projet au moment de la préparation de la version **1.1.0**.

Chaque composant reste soumis à sa propre licence. La licence de PadMac ne remplace ni ne modifie les conditions applicables aux composants tiers.

> **Portée de cet inventaire :** les packages listés ci-dessous sont les dépendances directes identifiées à partir du code et des informations de configuration communiqués pour PadMac. Les versions réellement résolues doivent être confirmées dans `pubspec.lock`. Cet inventaire n'est pas une liste exhaustive des dépendances transitives, des composants natifs Android ou des éléments éventuellement fournis par le SDK Flutter.

## Dépendances directes Flutter et Dart

| Composant | Utilisation dans PadMac | Type | Version utilisée | Licence | Source |
|---|---|---|---|---|---|
| [`material_ui`](https://pub.dev/packages/material_ui) | Widgets Material, thèmes, composants et éléments d'interface | Exécution | Voir `pubspec.lock` | BSD-3-Clause | [Dépôt Flutter Packages](https://github.com/flutter/packages/tree/main/packages/material_ui) |
| [`cupertino_icons`](https://pub.dev/packages/cupertino_icons) | Ressources d'icônes Cupertino | Exécution / ressources | Voir `pubspec.lock` | MIT | [Page du package](https://pub.dev/packages/cupertino_icons) |
| [`permission_handler`](https://pub.dev/packages/permission_handler) | Demande et vérification des autorisations Android, notamment Bluetooth et notifications | Exécution | Voir `pubspec.lock` | MIT | [Dépôt Baseflow](https://github.com/Baseflow/flutter-permission-handler) |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Sauvegarde et restauration du profil de manette sélectionné | Exécution | Voir `pubspec.lock` | BSD-3-Clause | [Dépôt Flutter Packages](https://github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences) |
| [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) | Génération des icônes de l'application à partir des ressources du projet | Développement uniquement | Voir `pubspec.lock` | MIT | [Dépôt Flutter Community](https://github.com/fluttercommunity/flutter_launcher_icons) |

Les licences indiquées correspondent aux métadonnées de licence publiées pour ces packages au moment de la vérification. Pour toute distribution, conserve les versions exactes résolues dans `pubspec.lock` et vérifie le fichier de licence fourni avec chaque version effectivement utilisée.

`flutter_launcher_icons` est un outil de génération utilisé pendant le développement. Il n'est normalement pas embarqué comme dépendance d'exécution dans l'APK final. Il est néanmoins recensé ici pour documenter les outils du projet.

## Dépendances transitives

Les packages directs peuvent dépendre d'autres packages qui sont eux-mêmes intégrés à l'application ou utilisés pendant sa compilation. Leurs licences et avis de copyright doivent être examinés et conservés conformément à leurs conditions respectives.

Pour afficher l'arbre des dépendances depuis la racine du projet :

```bash
flutter pub deps --style=compact
```

Avant une publication, examine les dépendances résolues dans `pubspec.lock`, identifie celles qui sont distribuées avec l'application et complète les attributions lorsque leurs licences l'exigent. Ne déduis pas les versions utilisées de la dernière version affichée sur pub.dev : seule la résolution du projet fait foi.

## Logiciel externe requis

### OpenJoystickDriver (OJD)

[OpenJoystickDriver](https://github.com/xsyetopz/OpenJoystickDriver) est un logiciel macOS externe avec lequel PadMac est conçu pour fonctionner. OJD reçoit les commandes du contrôleur Bluetooth et expose un périphérique virtuel à macOS. Il est développé et distribué indépendamment de PadMac.

PadMac ne contient pas et ne redistribue pas l'application OpenJoystickDriver. L'utilisateur doit l'obtenir séparément depuis le [dépôt officiel](https://github.com/xsyetopz/OpenJoystickDriver) et respecter les conditions applicables à la version qu'il installe.

Au moment de la préparation de PadMac 1.1.0, le fichier [`LICENSE` de la branche principale d'OJD](https://github.com/xsyetopz/OpenJoystickDriver/blob/main/LICENSE) présente la **Mozilla Public License 2.0 (MPL-2.0)**. La licence d'une version publiée peut différer de celle de la branche principale ou avoir évolué dans le temps : consulte toujours le fichier `LICENSE` associé à la version exacte utilisée.

La licence d'OJD s'applique à OJD et à ses propres composants couverts. Elle ne remplace pas la licence de PadMac et ne signifie pas que le code d'OJD est intégré au dépôt PadMac.

## SDK et outils de plateforme

PadMac est développé avec Flutter et Dart et compile une application Android qui comprend du code natif Kotlin/Android pour la communication Bluetooth HID et les échanges avec Flutter.

Le SDK Flutter, le SDK Android, Gradle, Kotlin, le plugin Android Gradle et les composants natifs utilisés par les plugins peuvent apporter leurs propres licences ou notices. Ils doivent être identifiés à partir des versions et fichiers réellement utilisés par le projet. Les notices produites ou fournies par les outils de compilation doivent être conservées lorsqu'elles sont requises.

## Ressources graphiques et marques

Les fichiers graphiques de PadMac identifiés dans le projet comprennent notamment :

- `assets/images/padmac_brand_xbox.png`
- `assets/images/padmac_brand_playstation.png`
- `assets/images/padmac_brand_switch.png`
- `assets/images/padmac_app_icon_512.png`

Le présent inventaire ne leur attribue pas de licence tierce faute d'information sur leur création ou leur provenance. Si un fichier contient une illustration, une police, un pictogramme ou un élément visuel provenant d'un tiers, ajoute ici son auteur ou titulaire, sa source et sa licence, et conserve l'avis de copyright ou le fichier de licence requis.

Les noms et marques **Xbox**, **PlayStation**, **Nintendo Switch**, **Android**, **macOS** et les autres marques de tiers appartiennent à leurs titulaires respectifs. Ils sont utilisés uniquement pour identifier les plateformes et dispositions concernées. PadMac n'est ni affilié à ces sociétés ni présenté comme un produit officiel de celles-ci.

## Composants natifs et autres ressources à auditer

Les dépendances déclarées dans les fichiers Gradle, les composants Android embarqués, ainsi que les polices, images, sons, icônes ou autres ressources provenant de tiers doivent être vérifiés avant de considérer cet inventaire comme exhaustif.

| Composant ou ressource | Emplacement / méthode de vérification | Auteur / titulaire | Licence | État |
|---|---|---|---|---|
| Dépendances Gradle et AndroidX | `android/settings.gradle(.kts)`, `android/build.gradle(.kts)`, `android/app/build.gradle(.kts)` et éventuels fichiers de verrouillage | À identifier | À vérifier | Audit nécessaire |
| Composants natifs apportés par les plugins Flutter | Plugins résolus dans `.flutter-plugins-dependencies` et `pubspec.lock` | À identifier | À vérifier | Audit nécessaire |
| Ressources graphiques, polices et autres médias tiers | `assets/`, `android/app/src/main/res/` et autres répertoires de ressources | À identifier si applicable | À vérifier si applicable | À confirmer |

## Vérification avant publication

- [ ] Comparer les dépendances déclarées dans `pubspec.yaml` avec celles résolues dans `pubspec.lock`.
- [ ] Vérifier les licences des dépendances directes et transitives effectivement utilisées et distribuées.
- [ ] Distinguer les dépendances d'exécution des outils de développement.
- [ ] Examiner les dépendances natives déclarées dans les fichiers Gradle et les composants Android apportés par les plugins.
- [ ] Vérifier la provenance et les licences des logos, icônes, polices, images, sons et autres ressources.
- [ ] Vérifier la licence de la version exacte d'OpenJoystickDriver installée séparément par l'utilisateur.
- [ ] Conserver les textes de licence et avis de copyright exigés par les auteurs des composants concernés.
- [ ] Mettre à jour ce fichier à chaque ajout, suppression ou remplacement de dépendance ou de ressource tierce.

---

Cet inventaire est fourni à titre d'information et de traçabilité. Il ne constitue pas un audit juridique exhaustif. En cas de redistribution d'un composant tiers, les obligations de sa licence doivent être examinées à partir de la version réellement distribuée.
