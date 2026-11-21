import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controller_profile.dart';

/// Palette visuelle complète d'un profil de manette PadMac.
/// Toutes les couleurs de l'interface sont centralisées ici afin que les
/// widgets et l'écran de démarrage utilisent la même identité visuelle.
class AppPalette {
  final Color background;
  final Color backgroundGradientStart;
  final Color backgroundGradientEnd;
  final Color surface;
  final Color surfaceRaised;
  final Color muted;
  final Color accent;
  final Color controlPressed;
  final Color facePressed;
  final Color dpadPressed;
  final Color centerPressed;
  final Color controlSurface;
  final Color controlBorder;
  final Color dpadBase;
  final Color faceSurface;
  final Color triggerTrack;
  final Color triggerStart;
  final Color triggerMid;
  final Color triggerEnd;
  final Color stickWellStart;
  final Color stickWellEnd;
  final Color stickWellBorder;
  final Color stickKnobStart;
  final Color stickKnobEnd;
  final Color stickKnobBorder;
  final Color stickKnobCenter;

  const AppPalette({
    required this.background,
    required this.backgroundGradientStart,
    required this.backgroundGradientEnd,
    required this.surface,
    required this.surfaceRaised,
    required this.muted,
    required this.accent,
    required this.controlPressed,
    required this.facePressed,
    required this.dpadPressed,
    required this.centerPressed,
    required this.controlSurface,
    required this.controlBorder,
    required this.dpadBase,
    required this.faceSurface,
    required this.triggerTrack,
    required this.triggerStart,
    required this.triggerMid,
    required this.triggerEnd,
    required this.stickWellStart,
    required this.stickWellEnd,
    required this.stickWellBorder,
    required this.stickKnobStart,
    required this.stickKnobEnd,
    required this.stickKnobBorder,
    required this.stickKnobCenter,
  });

  static const AppPalette xbox = AppPalette(
    background: Color(0xFF101513),
    backgroundGradientStart: Color(0xFF1A241E),
    backgroundGradientEnd: Color(0xFF0B100D),
    surface: Color(0xFF1A211D),
    surfaceRaised: Color(0xFF252E28),
    muted: Color(0xFF94A39A),
    accent: Color(0xFF55D889),
    controlPressed: Color(0xFF3A7954),
    facePressed: Color(0xFF496653),
    dpadPressed: Color(0xFF4B795D),
    centerPressed: Color(0xFF405C49),
    controlSurface: Color(0xFF29332D),
    controlBorder: Color(0xFF65736A),
    dpadBase: Color(0xFF252D29),
    faceSurface: Color(0xFF303A34),
    triggerTrack: Color(0xFF27332C),
    triggerStart: Color(0xFF347C50),
    triggerMid: Color(0xFF67E69A),
    triggerEnd: Color(0xFF347C50),
    stickWellStart: Color(0xFF303B34),
    stickWellEnd: Color(0xFF1A211D),
    stickWellBorder: Color(0xFF607368),
    stickKnobStart: Color(0xFF53675A),
    stickKnobEnd: Color(0xFF202923),
    stickKnobBorder: Color(0xFF9AC5A7),
    stickKnobCenter: Color(0xFF789783),
  );

  static const AppPalette playStation = AppPalette(
    background: Color(0xFF101720),
    backgroundGradientStart: Color(0xFF19283A),
    backgroundGradientEnd: Color(0xFF0A111A),
    surface: Color(0xFF192432),
    surfaceRaised: Color(0xFF253448),
    muted: Color(0xFF9AAEC0),
    accent: Color(0xFF55A9F5),
    controlPressed: Color(0xFF315F89),
    facePressed: Color(0xFF365F87),
    dpadPressed: Color(0xFF376B9A),
    centerPressed: Color(0xFF315B80),
    controlSurface: Color(0xFF263646),
    controlBorder: Color(0xFF607D98),
    dpadBase: Color(0xFF202F3E),
    faceSurface: Color(0xFF293B4D),
    triggerTrack: Color(0xFF1B2B3A),
    triggerStart: Color(0xFF27689E),
    triggerMid: Color(0xFF69B7F5),
    triggerEnd: Color(0xFF27689E),
    stickWellStart: Color(0xFF34495D),
    stickWellEnd: Color(0xFF172431),
    stickWellBorder: Color(0xFF58758F),
    stickKnobStart: Color(0xFF526F89),
    stickKnobEnd: Color(0xFF1D2D3D),
    stickKnobBorder: Color(0xFF91BCE0),
    stickKnobCenter: Color(0xFF78A9D1),
  );

  static const AppPalette nintendo = AppPalette(
    background: Color(0xFF171212),
    backgroundGradientStart: Color(0xFF2A1A1B),
    backgroundGradientEnd: Color(0xFF100B0C),
    surface: Color(0xFF241B1B),
    surfaceRaised: Color(0xFF332525),
    muted: Color(0xFFB9A4A4),
    accent: Color(0xFFF06464),
    controlPressed: Color(0xFF783A3F),
    facePressed: Color(0xFF754044),
    dpadPressed: Color(0xFF8A444A),
    centerPressed: Color(0xFF753B40),
    controlSurface: Color(0xFF342729),
    controlBorder: Color(0xFF80595C),
    dpadBase: Color(0xFF2B2021),
    faceSurface: Color(0xFF38292B),
    triggerTrack: Color(0xFF2B1D1F),
    triggerStart: Color(0xFF8D343B),
    triggerMid: Color(0xFFF07878),
    triggerEnd: Color(0xFF8D343B),
    stickWellStart: Color(0xFF493234),
    stickWellEnd: Color(0xFF24191A),
    stickWellBorder: Color(0xFF80585A),
    stickKnobStart: Color(0xFF765052),
    stickKnobEnd: Color(0xFF2A1D1F),
    stickKnobBorder: Color(0xFFCB9294),
    stickKnobCenter: Color(0xFFB8797C),
  );
}

/// Gestionnaire central du thème et du profil sélectionné.
///
/// Le profil est chargé avant runApp() pour que l'écran de démarrage affiche
/// immédiatement la bonne palette. Les changements sont ensuite sauvegardés
/// dans les préférences locales de l'application.
class AppTheme {
  AppTheme._();

  static const String _profilePreferenceKey =
      'padmac.selected_controller_profile';
  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static final ValueNotifier<ControllerProfileId> profile =
      ValueNotifier<ControllerProfileId>(ControllerProfileId.xbox);

  // Sérialise les écritures en cas de changements rapides de profil.
  static Future<void> _pendingWrites = Future<void>.value();

  static AppPalette get current => paletteFor(profile.value);

  /// À appeler avant runApp(). Une valeur absente ou inconnue revient à Xbox.
  static Future<void> initialize() async {
    try {
      final String? storedProfile = await _preferences.getString(
        _profilePreferenceKey,
      );
      profile.value = _profileFromStorage(storedProfile);
    } catch (error, stackTrace) {
      debugPrint('PadMac: impossible de charger le profil sauvegardé: $error');
      debugPrintStack(stackTrace: stackTrace);
      profile.value = ControllerProfileId.xbox;
    }
  }

  static ControllerProfileId _profileFromStorage(String? storedValue) {
    for (final ControllerProfileId id in ControllerProfileId.values) {
      if (id.name == storedValue) return id;
    }
    return ControllerProfileId.xbox;
  }

  static AppPalette paletteFor(ControllerProfileId profileId) {
    return switch (profileId) {
      ControllerProfileId.xbox => AppPalette.xbox,
      ControllerProfileId.dualShock4 => AppPalette.playStation,
      ControllerProfileId.switchPro => AppPalette.nintendo,
    };
  }

  /// Met à jour immédiatement l'interface et sauvegarde le choix localement.
  static Future<void> selectProfile(ControllerProfileId profileId) {
    if (profile.value == profileId) return _pendingWrites;

    profile.value = profileId;
    final String valueToStore = profileId.name;

    _pendingWrites = _pendingWrites.then((_) async {
      try {
        await _preferences.setString(_profilePreferenceKey, valueToStore);
      } catch (error, stackTrace) {
        debugPrint('PadMac: impossible de sauvegarder le profil: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });

    return _pendingWrites;
  }

  static ThemeData themeFor(ControllerProfileId profileId) {
    final AppPalette palette = paletteFor(profileId);
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: palette.accent,
          brightness: Brightness.dark,
          surface: palette.surface,
        ).copyWith(
          primary: palette.accent,
          secondary: palette.accent,
          surface: palette.surface,
        );

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: palette.background,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      cardColor: palette.surface,
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.accent,
        thumbColor: palette.accent,
        overlayColor: palette.accent.withValues(alpha: 0.14),
      ),
    );
  }
}
