import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Ordre des contrôles selon la table HID standard utilisée par OJD :
/// Button 1..11 = A, B, X, Y, LB, RB, View, Menu, L3, R3, Guide.
/// Share est émis séparément comme Consumer Control / Record (0x0C:B2).
const List<String> kButtonNames = <String>[
  'A',
  'B',
  'X',
  'Y',
  'LB',
  'RB',
  'View',
  'Menu',
  'L3',
  'R3',
  'Guide',
  'Share',
];

class GamepadState {
  /// Axes HID signés : -32767 = minimum, 0 = centre, 32767 = maximum.
  /// OJD interprétait 0x8000 (ancien centre non signé) comme -32768.
  static const int axisCenter = 0;

  /// Bits 0..10 = usages HID Button 1..11. Le bit 11 est réservé à Share.
  int buttons = 0;

  int lx = axisCenter;
  int ly = axisCenter;
  int rx = axisCenter;
  int ry = axisCenter;

  /// Gâchettes exposées à l'interface en 0..255, converties en 16 bits
  /// dans le rapport HID pour correspondre aux usages Desktop Z et Rz d'OJD.
  int lt = 0;
  int rt = 0;

  /// Hat Switch : 0 = haut, puis sens horaire, 8 = neutre.
  int hat = 8;

  void setButton(int index, bool pressed) {
    if (index < 0 || index > 11) return;

    if (pressed) {
      buttons |= (1 << index);
    } else {
      buttons &= ~(1 << index);
    }
    buttons &= 0x0FFF;
  }

  /// Convertit [-1, 1] vers un axe HID signé [-32767, 32767].
  /// Le zéro signé est le centre physique attendu par OJD.
  /// La deadzone radiale est appliquée dans le widget tactile du stick.
  static int axis16(double value) {
    final double normalized = value.clamp(-1.0, 1.0).toDouble();
    final double scaled = normalized < 0.0
        ? normalized * 32768.0
        : normalized * 32767.0;
    return scaled.round().clamp(-32768, 32767).toInt();
  }

  /// Gâchette tactile [0, 1] -> [0, 255].
  static int trigger8(double value) {
    final double normalized = value.clamp(0.0, 1.0).toDouble();
    return (normalized * 255.0).round().clamp(0, 255).toInt();
  }

  /// Dans la carte HID standard d'OJD, Brake/Accelerator sont inversés :
  /// l'entrée brute 0 est rapportée comme gâchette complètement tirée.
  /// On inverse donc le rapport sur le fil : 65535 = relâchée, 0 = tirée.
  static int _trigger16(int value) {
    final int level = value.clamp(0, 255).toInt();
    return 65535 - (level * 257);
  }

  /// Rapport HID de 16 octets, sans Report ID.
  ///
  /// Alignement des usages HID lus par la carte standard OJD :
  ///   0..1   : boutons + remplissage
  ///   2..3   : Generic Desktop X   -> LeftStickX (Int16 signé)
  ///   4..5   : Generic Desktop Y   -> LeftStickY (Int16 signé)
  ///   6..7   : Generic Desktop Z   -> RightStickX (Int16 signé)
  ///   8..9   : Generic Desktop Rz  -> RightStickY (Int16 signé)
  ///  10..11 : Simulation Brake    -> LeftTrigger (polarité inversée)
  ///  12..13 : Simulation Accelerator -> RightTrigger (polarité inversée)
  ///     14   : Hat Switch + 4 bits de remplissage
  ///     15   : Consumer Record (0x0C:B2) -> Share/Capture
  ///
  /// BluetoothHidDevice.sendReport() reçoit le Report ID séparément.
  Uint8List toReport() {
    final ByteData data = ByteData(16);

    data.setUint16(0, buttons & 0x07FF, Endian.little);
    data.setInt16(2, lx.clamp(-32768, 32767).toInt(), Endian.little);
    data.setInt16(4, ly.clamp(-32768, 32767).toInt(), Endian.little);
    // OJD's Z/Rz descriptor shape is selected when Rx/Ry are absent.
    data.setInt16(6, rx.clamp(-32768, 32767).toInt(), Endian.little);
    data.setInt16(8, ry.clamp(-32768, 32767).toInt(), Endian.little);
    data.setUint16(10, _trigger16(lt), Endian.little);
    data.setUint16(12, _trigger16(rt), Endian.little);
    data.setUint8(14, hat & 0x0F);
    data.setUint8(15, (buttons >> 11) & 0x01);

    return data.buffer.asUint8List();
  }

  void reset() {
    buttons = 0;
    lx = axisCenter;
    ly = axisCenter;
    rx = axisCenter;
    ry = axisCenter;
    lt = 0;
    rt = 0;
    hat = 8;
  }

  static int hatFrom(bool up, bool right, bool down, bool left) {
    // Les diagonales opposées s'annulent : haut+bas ou gauche+droite.
    final bool verticalUp = up && !down;
    final bool verticalDown = down && !up;
    final bool horizontalRight = right && !left;
    final bool horizontalLeft = left && !right;

    if (verticalUp && horizontalRight) return 1;
    if (verticalDown && horizontalRight) return 3;
    if (verticalDown && horizontalLeft) return 5;
    if (verticalUp && horizontalLeft) return 7;
    if (verticalUp) return 0;
    if (horizontalRight) return 2;
    if (verticalDown) return 4;
    if (horizontalLeft) return 6;
    return 8;
  }
}

class BondedDevice {
  final String name;
  final String address;

  const BondedDevice(this.name, this.address);
}

class HidGamepad {
  HidGamepad._();

  static const MethodChannel _method = MethodChannel('padmac/hid');
  static const EventChannel _events = EventChannel('padmac/hid_events');
  static const int reportLength = 16;

  static Stream<Map<String, String>> get events => _events
      .receiveBroadcastStream()
      .map((dynamic event) {
        final Map<Object?, Object?> raw = Map<Object?, Object?>.from(event as Map);
        return <String, String>{
          'event': raw['event']?.toString() ?? '',
          'value': raw['value']?.toString() ?? '',
        };
      });

  static Future<bool> init() async {
    return (await _method.invokeMethod<bool>('init')) ?? false;
  }

  static Future<void> requestDiscoverable() async {
    await _method.invokeMethod<void>('discoverable');
  }

  static Future<List<BondedDevice>> bondedDevices() async {
    final List<dynamic> raw =
        await _method.invokeMethod<List<dynamic>>('bonded') ?? <dynamic>[];

    return raw.map((dynamic item) {
      final Map<Object?, Object?> map = Map<Object?, Object?>.from(item as Map);
      return BondedDevice(
        map['name']?.toString() ?? '',
        map['address']?.toString() ?? '',
      );
    }).toList(growable: false);
  }

  static Future<bool> connect(String address) async {
    return (await _method.invokeMethod<bool>(
          'connect',
          <String, String>{'address': address},
        )) ??
        false;
  }

  static Future<bool> disconnect() async {
    return (await _method.invokeMethod<bool>('disconnect')) ?? false;
  }

  /// Masque ou restaure les barres système via WindowInsetsController Android.
  /// Nécessaire sur Android 16+ lorsque SystemUiMode.immersiveSticky est ignoré.
  static Future<void> setImmersiveMode(bool enabled) async {
    await _method.invokeMethod<bool>(
      'systemUi',
      <String, bool>{'immersive': enabled},
    );
  }

  static Future<bool> sendReport(Uint8List report) async {
    if (report.length != reportLength) return false;
    return (await _method.invokeMethod<bool>('send', report)) ?? false;
  }

  static Future<bool> send(GamepadState state) => sendReport(state.toReport());

  static Future<void> dispose() async {
    await _method.invokeMethod<void>('dispose');
  }
}
