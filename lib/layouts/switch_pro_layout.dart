import 'controller_layout_spec.dart';

/// Disposition inspirée de la Nintendo Switch Pro Controller :
/// stick gauche en haut, touches directionnelles en bas à gauche,
/// boutons ABXY en haut à droite et stick droit en bas à droite.
class SwitchProLayout {
  static const ControllerLayoutSpec spec = ControllerLayoutSpec(
    leftStickLeftFactor: 0.095,
    leftStickTopFactor: 0.045,
    rightStickRightFactor: 0.095,
    rightStickTopFactor: 0.535,
    dpadLeftFactor: 0.095,
    dpadTopFactor: 0.535,
    faceRightFactor: 0.095,
    faceTopFactor: 0.045,
    centerControlsTopFactor: 0.34,
    stickSizeFactor: 0.96,
    dpadSizeFactor: 0.90,
    faceSizeFactor: 0.96,
    separatedDpad: true,
  );
}
