import 'controller_layout_spec.dart';

/// Disposition Xbox historique de PadMac.
///
/// Les facteurs reprennent les positions de la manette qui étaient déjà
/// utilisées avant l'ajout des profils : cette disposition reste la référence.
class XboxLayout {
  static const ControllerLayoutSpec spec = ControllerLayoutSpec(
    leftStickLeftFactor: 0.065,
    leftStickTopFactor: 0.025,
    rightStickRightFactor: 0.22,
    rightStickTopFactor: 0.53,
    dpadLeftFactor: 0.22,
    dpadTopFactor: 0.51,
    faceRightFactor: 0.045,
    faceTopFactor: 0.015,
    centerControlsTopFactor: 0.36,
    stickSizeFactor: 1.0,
    dpadSizeFactor: 1.0,
    faceSizeFactor: 1.0,
    separatedDpad: false,
  );
}
