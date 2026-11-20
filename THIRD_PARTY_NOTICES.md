# Notices relatives aux logiciels tiers

PadMac s'appuie sur des outils, packages et composants développés par des tiers. Ce fichier rassemble les principales attributions identifiées pour le projet. Chaque composant reste soumis à sa propre licence ; la licence de PadMac ne remplace pas les conditions des composants tiers.

> **Portée de cet inventaire :** les entrées ci-dessous recensent les dépendances directes identifiées dans le code et la configuration décrits pour PadMac. Les versions exactes doivent être vérifiées dans `pubspec.lock`. Les dépendances transitives et les éventuels composants natifs Android doivent également être contrôlés avant une publication officielle. Cet inventaire ne doit pas être considéré comme exhaustif tant que cet audit n'a pas été effectué.

## Dépendances Flutter et Dart identifiées

| Composant | Utilisation dans PadMac | Version utilisée | Licence | Source |
|---|---|---|---|---|
| [`material_ui`](https://pub.dev/packages/material_ui) | Composants d'interface Material | Voir `pubspec.lock` | BSD 3-Clause | [Dépôt du package](https://github.com/flutter/packages) |
| [`cupertino_icons`](https://pub.dev/packages/cupertino_icons) | Ressources d'icônes Cupertino | Voir `pubspec.lock` | MIT | [Page du package](https://pub.dev/packages/cupertino_icons) |
| [`permission_handler`](https://pub.dev/packages/permission_handler) | Demande et vérification des autorisations Android | Voir `pubspec.lock` | MIT | [Dépôt du package](https://github.com/Baseflow/flutter-permission-handler) |
| [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) | Génération des icônes de l'application (outil de développement) | Voir `pubspec.lock` | MIT | [Dépôt du package](https://github.com/fluttercommunity/flutter_launcher_icons) |

Les licences indiquées correspondent aux métadonnées de licence publiées pour ces packages. Pour la distribution, conserve les versions exactes résolues dans `pubspec.lock` et vérifie les fichiers de licence fournis avec ces versions.

## Dépendances transitives

Les packages listés dans `pubspec.lock` peuvent eux-mêmes dépendre d'autres packages. Leurs licences et avis de copyright doivent être conservés conformément à leurs conditions respectives.

Pour afficher l'arbre des dépendances depuis la racine du projet :

```bash
flutter pub deps --style=compact
```

Avant une release, complète cet inventaire avec les dépendances transitives nécessitant une attribution distincte et vérifie les licences correspondantes dans les sources des packages résolus.

## Logiciels externes requis

### OpenJoystickDriver (OJD)

[OpenJoystickDriver](https://github.com/GuardianOfDreams/OpenJoystickDriver) est une application macOS externe avec laquelle PadMac est conçu pour fonctionner. OJD n'est pas développé par PadMac et n'est pas inclus dans le dépôt PadMac comme composant redistribué par ce projet.

OJD est distribué sous sa propre licence. Consulte le [dépôt officiel](https://github.com/GuardianOfDreams/OpenJoystickDriver) et les conditions de licence correspondant à la version utilisée.

## Composants natifs et ressources

Les dépendances natives éventuellement déclarées dans les fichiers Gradle, ainsi que les polices, images, sons, icônes ou autres ressources provenant de tiers, doivent être ajoutés ici avec leur auteur, leur source et leur licence.

| Composant ou ressource | Emplacement dans le projet | Auteur / titulaire | Licence | Source |
|---|---|---|---|---|
| À compléter après vérification des fichiers Android et des ressources | — | — | — | — |

## Vérification avant publication

- [ ] Comparer les dépendances déclarées dans `pubspec.yaml` avec celles résolues dans `pubspec.lock`.
- [ ] Examiner les licences des dépendances directes et transitives.
- [ ] Examiner les dépendances natives déclarées dans les fichiers Gradle.
- [ ] Ajouter les attributions requises pour les images, polices, sons, icônes et autres ressources tierces.
- [ ] Conserver les textes de licence et avis de copyright exigés par les auteurs des composants concernés.
