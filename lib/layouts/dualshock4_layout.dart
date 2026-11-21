import 'controller_layout_spec.dart';

/// Disposition inspirée de la DualShock 4 :
/// sticks symétriques en partie basse, pavé directionnel et boutons de façade
/// dans les parties hautes, avec une zone centrale réservée au pavé tactile.
class DualShock4Layout {
  static const ControllerLayoutSpec spec = ControllerLayoutSpec(
    leftStickLeftFactor: 0.285,
    leftStickTopFactor: 0.55,
    rightStickRightFactor: 0.285,
    rightStickTopFactor: 0.55,
    dpadLeftFactor: 0.065,
    dpadTopFactor: 0.22,
    faceRightFactor: 0.065,
    faceTopFactor: 0.22,
    centerControlsTopFactor: 0.30,
    stickSizeFactor: 0.94,
    dpadSizeFactor: 0.94,
    faceSizeFactor: 0.94,
    separatedDpad: true,
    showTouchpadPreview: true,
    touchpadTopFactor: 0.035,
    touchpadWidthFactor: 0.29,
    touchpadMaxWidth: 224.0,
    touchpadHeight: 43.0,
  );
}
