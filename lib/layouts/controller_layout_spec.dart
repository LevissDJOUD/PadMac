/// Paramètres géométriques d'une disposition PadMac.
///
/// Les facteurs horizontaux sont appliqués à la largeur disponible.
/// Les facteurs verticaux sont appliqués à la hauteur utile sous l'en-tête.
/// Cette classe ne modifie jamais le rapport HID ni l'ordre des boutons.
class ControllerLayoutSpec {
  final double leftStickLeftFactor;
  final double leftStickTopFactor;
  final double rightStickRightFactor;
  final double rightStickTopFactor;

  final double dpadLeftFactor;
  final double dpadTopFactor;
  final double faceRightFactor;
  final double faceTopFactor;
  final double centerControlsTopFactor;

  final double stickSizeFactor;
  final double dpadSizeFactor;
  final double faceSizeFactor;

  /// true : quatre directions visuellement séparées.
  /// false : croix directionnelle avec base continue, comme Xbox.
  final bool separatedDpad;

  /// Aperçu non interactif du pavé tactile DualShock 4.
  final bool showTouchpadPreview;
  final double touchpadTopFactor;
  final double touchpadWidthFactor;
  final double touchpadMaxWidth;
  final double touchpadHeight;

  const ControllerLayoutSpec({
    required this.leftStickLeftFactor,
    required this.leftStickTopFactor,
    required this.rightStickRightFactor,
    required this.rightStickTopFactor,
    required this.dpadLeftFactor,
    required this.dpadTopFactor,
    required this.faceRightFactor,
    required this.faceTopFactor,
    required this.centerControlsTopFactor,
    required this.stickSizeFactor,
    required this.dpadSizeFactor,
    required this.faceSizeFactor,
    required this.separatedDpad,
    this.showTouchpadPreview = false,
    this.touchpadTopFactor = 0.0,
    this.touchpadWidthFactor = 0.0,
    this.touchpadMaxWidth = 0.0,
    this.touchpadHeight = 0.0,
  });
}
