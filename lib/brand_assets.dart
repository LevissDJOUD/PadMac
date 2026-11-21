import 'controller_profile.dart';

/// Retourne le logo PadMac correspondant au profil sélectionné.
String brandAssetForProfile(ControllerProfileId profileId) {
  return switch (profileId) {
    ControllerProfileId.xbox => 'assets/images/padmac_brand_xbox.png',

    ControllerProfileId.dualShock4 =>
      'assets/images/padmac_brand_playstation.png',

    ControllerProfileId.switchPro => 'assets/images/padmac_brand_switch.png',
  };
}
