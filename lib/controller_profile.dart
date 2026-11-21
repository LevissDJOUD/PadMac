enum ControllerProfileId {
  xbox,
  dualShock4,
  switchPro,
}

enum CenterControlKind {
  view,
  share,
  menu,
  options,
  xboxGuide,
  playStation,
  home,
  minus,
  plus,
  consumerRecord,
}

/// Présentation et correspondance tactile des dispositions PadMac.
///
/// Ces profils changent les libellés et l'affichage dans PadMac. Ils ne
/// changent pas l'identité HID annoncée par Android ni le profil virtuel choisi
/// par OpenJoystickDriver sur macOS.
class ControllerProfile {
  final ControllerProfileId id;
  final String name;
  final String description;

  /// Libellés des boutons placés en losange.
  /// Leur finition visuelle est commune aux trois profils.
  final String faceTop;
  final String faceRight;
  final String faceBottom;
  final String faceLeft;

  final String leftBumper;
  final String rightBumper;
  final String leftTrigger;
  final String rightTrigger;
  final bool digitalTriggers;

  /// Contrôles centraux reliés aux usages déjà présents dans le rapport HID.
  final CenterControlKind centerLeftKind;
  final CenterControlKind centerRightKind;
  final CenterControlKind systemKind;
  final CenterControlKind? middleKind;
  final String centerLeftTooltip;
  final String centerRightTooltip;
  final String systemTooltip;
  final String? middleTooltip;

  const ControllerProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.faceTop,
    required this.faceRight,
    required this.faceBottom,
    required this.faceLeft,
    required this.leftBumper,
    required this.rightBumper,
    required this.leftTrigger,
    required this.rightTrigger,
    required this.digitalTriggers,
    required this.centerLeftKind,
    required this.centerRightKind,
    required this.systemKind,
    required this.middleKind,
    required this.centerLeftTooltip,
    required this.centerRightTooltip,
    required this.systemTooltip,
    required this.middleTooltip,
  });

  static const ControllerProfile xbox = ControllerProfile(
    id: ControllerProfileId.xbox,
    name: 'Xbox',
    description:
        'Disposition Xbox classique. LT et RT conservent leur commande analogique.',
    faceTop: 'Y',
    faceRight: 'B',
    faceBottom: 'A',
    faceLeft: 'X',
    leftBumper: 'LB',
    rightBumper: 'RB',
    leftTrigger: 'LT',
    rightTrigger: 'RT',
    digitalTriggers: false,
    centerLeftKind: CenterControlKind.view,
    centerRightKind: CenterControlKind.menu,
    systemKind: CenterControlKind.xboxGuide,
    middleKind: CenterControlKind.share,
    centerLeftTooltip: 'View',
    centerRightTooltip: 'Menu',
    systemTooltip: 'Guide',
    middleTooltip: 'Share — Consumer Control Record',
  );

  static const ControllerProfile dualShock4 = ControllerProfile(
    id: ControllerProfileId.dualShock4,
    name: 'PlayStation (DualShock 4)',
    description:
        'Disposition DualShock 4. L2 et R2 restent analogiques. Share, Options et PS sont affichés. Le pavé convertit les glissements en axes du stick sélectionné ; les coordonnées multitouch natives et le clic DS4 ne sont pas transmis.',
    faceTop: '△',
    faceRight: '○',
    faceBottom: '×',
    faceLeft: '□',
    leftBumper: 'L1',
    rightBumper: 'R1',
    leftTrigger: 'L2',
    rightTrigger: 'R2',
    digitalTriggers: false,
    centerLeftKind: CenterControlKind.share,
    centerRightKind: CenterControlKind.options,
    systemKind: CenterControlKind.playStation,
    // Le bit 11 du rapport actuel est Consumer Record, pas un bouton DS4.
    middleKind: null,
    centerLeftTooltip: 'Share (commande HID générique)',
    centerRightTooltip: 'Options (commande HID générique)',
    systemTooltip: 'PS (commande HID générique)',
    middleTooltip: null,
  );

  static const ControllerProfile switchPro = ControllerProfile(
    id: ControllerProfileId.switchPro,
    name: 'Nintendo Switch Pro',
    description:
        'Disposition Switch Pro. ZL et ZR sont simulées en boutons numériques. Le contrôle REC utilise Consumer Control Record : ce n’est pas le bouton Capture natif de la Switch Pro.',
    faceTop: 'X',
    faceRight: 'A',
    faceBottom: 'B',
    faceLeft: 'Y',
    leftBumper: 'L',
    rightBumper: 'R',
    leftTrigger: 'ZL',
    rightTrigger: 'ZR',
    digitalTriggers: true,
    centerLeftKind: CenterControlKind.minus,
    centerRightKind: CenterControlKind.plus,
    systemKind: CenterControlKind.home,
    middleKind: CenterControlKind.consumerRecord,
    centerLeftTooltip: 'Minus (−)',
    centerRightTooltip: 'Plus (+)',
    systemTooltip: 'Home',
    middleTooltip: 'Record — Consumer Control (pas Capture natif)',
  );

  static const List<ControllerProfile> all = <ControllerProfile>[
    xbox,
    dualShock4,
    switchPro,
  ];

  static ControllerProfile fromId(ControllerProfileId id) {
    return switch (id) {
      ControllerProfileId.xbox => xbox,
      ControllerProfileId.dualShock4 => dualShock4,
      ControllerProfileId.switchPro => switchPro,
    };
  }
}
