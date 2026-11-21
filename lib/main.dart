import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:padmac/brand_assets.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_theme.dart';
import 'controller_profile.dart';
import 'playstation_glyph.dart';
import 'layouts/controller_layout_spec.dart';
import 'layouts/dualshock4_layout.dart';
import 'layouts/switch_pro_layout.dart';
import 'layouts/xbox_layout.dart';
import 'hid_gamepad.dart';
import 'splash_screen.dart';
import 'touchpad_controller.dart';

AppPalette get _palette => AppTheme.current;
Color get _background => _palette.background;
Color get _surfaceRaised => _palette.surfaceRaised;
Color get _accent => _palette.accent;
Color get _muted => _palette.muted;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // L'accueil s'ouvre toujours en portrait avec les barres système visibles.
  await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Charge le dernier profil avant d'afficher le splash screen : sa palette
  // correspond ainsi immédiatement à la préférence sauvegardée.
  await AppTheme.initialize();

  runApp(const PadMacApp());
}

class PadMacApp extends StatelessWidget {
  const PadMacApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ControllerProfileId>(
      valueListenable: AppTheme.profile,
      builder:
          (BuildContext context, ControllerProfileId profileId, Widget? child) {
            return MaterialApp(
              title: 'PadMac',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.themeFor(profileId),
              home: const PadMacSplashScreen(nextScreen: HomePage()),
            );
          },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final GamepadState _state = GamepadState();
  final List<String> _logs = <String>[];
  final List<bool> _directions = List<bool>.filled(4, false);

  List<BondedDevice> _bonded = <BondedDevice>[];
  StreamSubscription<Map<String, String>>? _eventSubscription;
  Timer? _sweepTimer;

  bool _connected = false;
  bool _initializing = false;
  bool _sweepOn = false;
  bool _sending = false;
  bool _reportPending = false;
  bool _sendFailureLogged = false;
  int _page = 0;
  double _stickSizeFactor = 1.0;
  double _stickSensitivity = 1.0;
  double _stickDeadZone = 0.10;
  double _triggerSensitivity = 1.0;

  // Valeurs physiques conservées séparément des commandes du pavé tactile.
  // Le pavé peut ainsi prendre temporairement la priorité sur un stick sans
  // écraser la position réellement saisie sur ce stick.
  double _physicalLeftStickX = 0.0;
  double _physicalLeftStickY = 0.0;
  double _physicalRightStickX = 0.0;
  double _physicalRightStickY = 0.0;
  double _touchpadStickX = 0.0;
  double _touchpadStickY = 0.0;
  bool _touchpadEngaged = false;
  int _touchpadResetToken = 0;
  TouchpadStickTarget _touchpadTarget = TouchpadStickTarget.right;
  double _touchpadSensitivity = 1.0;

  ControllerProfileId _controllerProfileId = AppTheme.profile.value;

  ControllerProfile get _controllerProfile =>
      ControllerProfile.fromId(_controllerProfileId);

  String get _brandAsset => brandAssetForProfile(_controllerProfileId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _eventSubscription = HidGamepad.events.listen(
      _handleHidEvent,
      onError: (Object error) {
        _addLog('Erreur du flux HID : $error');
      },
    );
  }

  void _handleHidEvent(Map<String, String> event) {
    if (!mounted) return;

    final String type = event['event'] ?? '';
    final String value = event['value'] ?? '';

    if (type == 'conn') {
      final bool nowConnected = value.endsWith(': connecté');
      setState(() => _connected = nowConnected);

      if (nowConnected) {
        _sendFailureLogged = false;
        _pushReport();
      } else {
        _reportPending = false;
        _resetLocalState(send: false);
      }
    }

    _addLog('$type : $value');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Libère toutes les commandes si Android masque ou suspend l'application.
      _resetLocalState(send: true);
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_applyDisplayMode(_page));
    }
  }

  Future<void> _applyDisplayMode(int page) async {
    if (page == 1) {
      await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      // Android 16+ ignore le SystemUiMode.immersiveSticky historique.
      // On utilise directement WindowInsetsController côté natif.
      await HidGamepad.setImmersiveMode(true);
    } else {
      await HidGamepad.setImmersiveMode(false);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  Future<void> _openControllerPage() async {
    if (_page == 1) return;
    _resetLocalState(send: true);
    try {
      await _applyDisplayMode(1);
      if (!mounted) return;
      setState(() => _page = 1);
    } on PlatformException catch (error) {
      _addLog(
        'Impossible de passer en mode manette : ${error.message ?? error.code}',
      );
    }
  }

  Future<void> _returnToConnectionPage() async {
    _resetLocalState(send: true);
    if (mounted) setState(() => _page = 0);
    try {
      await _applyDisplayMode(0);
    } on PlatformException catch (error) {
      _addLog(
        'Impossible de restaurer le mode portrait : ${error.message ?? error.code}',
      );
    }
  }

  Future<void> _openSettingsPage() async {
    if (_page == 1) _resetLocalState(send: true);
    if (mounted) setState(() => _page = 2);
    try {
      await _applyDisplayMode(2);
    } on PlatformException catch (error) {
      _addLog(
        'Impossible d’ouvrir les paramètres : ${error.message ?? error.code}',
      );
    }
  }

  void _selectControllerProfile(ControllerProfileId? profileId) {
    if (profileId == null || profileId == _controllerProfileId) return;

    // Neutralise les commandes avant de changer leur signification visuelle.
    _resetLocalState(send: true);
    // Le changement visuel est immédiat ; le profil est aussi sauvegardé
    // pour être restauré au prochain lancement de l'application.
    unawaited(AppTheme.selectProfile(profileId));
    setState(() => _controllerProfileId = profileId);
    _addLog('Disposition sélectionnée : ${_controllerProfile.name}.');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sweepTimer?.cancel();
    _eventSubscription?.cancel();
    unawaited(HidGamepad.dispose());
    super.dispose();
  }

  void _addLog(String line) {
    if (!mounted) return;
    setState(() {
      _logs.insert(0, '${TimeOfDay.now().format(context)}  $line');
      if (_logs.length > 40) _logs.removeLast();
    });
  }

  Future<void> _initializeHid() async {
    if (_initializing) return;
    setState(() => _initializing = true);

    try {
      final Map<Permission, PermissionStatus> statuses = await <Permission>[
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ].request();

      final bool bluetoothGranted = statuses.values.every(
        (PermissionStatus status) => status.isGranted,
      );

      if (!bluetoothGranted) {
        _addLog(
          'Autorisations Bluetooth refusées. Vérifie les permissions Android.',
        );
        return;
      }

      // La notification du service est utile, mais son refus ne doit pas
      // bloquer l'initialisation HID elle-même.
      final PermissionStatus notification = await Permission.notification
          .request();
      if (!notification.isGranted) {
        _addLog(
          'Notification refusée : la connexion HID sera tout de même tentée.',
        );
      }

      final bool ok = await HidGamepad.init();
      _addLog(
        ok
            ? 'Initialisation HID demandée.'
            : 'Le service HID n’a pas pu démarrer.',
      );
    } on PlatformException catch (error) {
      _addLog('Erreur Android (${error.code}) : ${error.message ?? ''}');
    } catch (error) {
      _addLog('Erreur d’initialisation : $error');
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _requestDiscoverable() async {
    try {
      await HidGamepad.requestDiscoverable();
      _addLog('Demande de visibilité Bluetooth envoyée à Android.');
    } on PlatformException catch (error) {
      _addLog(
        'Visibilité Bluetooth impossible : ${error.message ?? error.code}',
      );
    } catch (error) {
      _addLog('Erreur Bluetooth : $error');
    }
  }

  Future<void> _loadBondedDevices() async {
    try {
      final List<BondedDevice> devices = await HidGamepad.bondedDevices();
      if (!mounted) return;
      setState(() => _bonded = devices);
      _addLog('${devices.length} appareil(s) déjà appairé(s).');
    } on PlatformException catch (error) {
      _addLog(
        'Lecture des appareils impossible : ${error.message ?? error.code}',
      );
    } catch (error) {
      _addLog('Erreur pendant la lecture Bluetooth : $error');
    }
  }

  Future<void> _connect(BondedDevice device) async {
    try {
      final bool ok = await HidGamepad.connect(device.address);
      _addLog(
        'Connexion à ${device.name.isEmpty ? device.address : device.name} : $ok',
      );
    } on PlatformException catch (error) {
      _addLog('Connexion impossible : ${error.message ?? error.code}');
    } catch (error) {
      _addLog('Erreur de connexion : $error');
    }
  }

  Future<void> _disconnect() async {
    try {
      final bool ok = await HidGamepad.disconnect();
      _addLog('Déconnexion demandée : $ok');
    } catch (error) {
      _addLog('Erreur de déconnexion : $error');
    }
  }

  /// Sérialise les rapports : les événements tactiles rapides ne peuvent pas
  /// faire partir plusieurs écritures Bluetooth dans le désordre.
  void _pushReport() {
    if (!_connected) return;
    _reportPending = true;
    if (!_sending) unawaited(_drainReports());
  }

  Future<void> _drainReports() async {
    if (_sending || !mounted) return;
    _sending = true;

    try {
      while (_reportPending && mounted && _connected) {
        _reportPending = false;
        final Uint8List report = _state.toReport();
        final bool sent = await HidGamepad.sendReport(report);
        if (!sent && !_sendFailureLogged && mounted) {
          _sendFailureLogged = true;
          _addLog('Rapport non transmis. Vérifie la connexion HID au Mac.');
        } else if (sent) {
          _sendFailureLogged = false;
        }
      }
    } on PlatformException catch (error) {
      if (mounted) {
        _addLog('Erreur d’envoi HID : ${error.message ?? error.code}');
      }
    } catch (error) {
      if (mounted) _addLog('Erreur de rapport : $error');
    } finally {
      _sending = false;
      if (_reportPending && mounted && _connected) {
        unawaited(_drainReports());
      }
    }
  }

  void _setButton(int index, bool pressed) {
    if (!mounted) return;
    setState(() => _state.setButton(index, pressed));
    _pushReport();
  }

  void _setDirection(int index, bool pressed) {
    if (index < 0 || index >= _directions.length) return;
    setState(() {
      _directions[index] = pressed;
      _state.hat = GamepadState.hatFrom(
        _directions[0], // haut
        _directions[1], // droite
        _directions[2], // bas
        _directions[3], // gauche
      );
    });
    _pushReport();
  }

  /// Applique la source prioritaire à chaque stick.
  ///
  /// Tant que le doigt est posé sur le pavé tactile, celui-ci remplace les
  /// valeurs du stick sélectionné. Les valeurs physiques restent mémorisées
  /// et redeviennent actives dès que le doigt est relâché.
  void _applyEffectiveStickValues() {
    final bool touchpadOnLeft =
        _touchpadEngaged && _touchpadTarget == TouchpadStickTarget.left;
    final bool touchpadOnRight =
        _touchpadEngaged && _touchpadTarget == TouchpadStickTarget.right;

    _state.lx = GamepadState.axis16(
      touchpadOnLeft ? _touchpadStickX : _physicalLeftStickX,
    );
    _state.ly = GamepadState.axis16(
      touchpadOnLeft ? _touchpadStickY : _physicalLeftStickY,
    );
    _state.rx = GamepadState.axis16(
      touchpadOnRight ? _touchpadStickX : _physicalRightStickX,
    );
    _state.ry = GamepadState.axis16(
      touchpadOnRight ? _touchpadStickY : _physicalRightStickY,
    );
  }

  void _setLeftStick(double x, double y) {
    setState(() {
      _physicalLeftStickX = x;
      _physicalLeftStickY = y;
      _applyEffectiveStickValues();
    });
    _pushReport();
  }

  void _setRightStick(double x, double y) {
    setState(() {
      _physicalRightStickX = x;
      _physicalRightStickY = y;
      _applyEffectiveStickValues();
    });
    _pushReport();
  }

  void _setTouchpadGestureActive(bool active) {
    if (!mounted) return;
    setState(() {
      _touchpadEngaged = active;
      if (!active) {
        _touchpadStickX = 0.0;
        _touchpadStickY = 0.0;
      }
      _applyEffectiveStickValues();
    });
    _pushReport();
  }

  void _setTouchpadVector(Offset value) {
    if (!mounted) return;
    setState(() {
      _touchpadStickX = value.dx;
      _touchpadStickY = value.dy;
      _applyEffectiveStickValues();
    });
    _pushReport();
  }

  void _setTrigger(bool left, int value) {
    final int normalizedValue = _controllerProfile.digitalTriggers
        ? (value > 0 ? 255 : 0)
        : value.clamp(0, 255).toInt();

    setState(() {
      if (left) {
        _state.lt = normalizedValue;
      } else {
        _state.rt = normalizedValue;
      }
    });
    _pushReport();
  }

  void _resetLocalState({required bool send}) {
    _sweepTimer?.cancel();
    _sweepOn = false;
    _touchpadResetToken++;
    _touchpadEngaged = false;
    _touchpadStickX = 0.0;
    _touchpadStickY = 0.0;
    _physicalLeftStickX = 0.0;
    _physicalLeftStickY = 0.0;
    _physicalRightStickX = 0.0;
    _physicalRightStickY = 0.0;
    _directions.fillRange(0, _directions.length, false);
    _state.reset();
    if (mounted) setState(() {});
    if (send) _pushReport();
  }

  void _toggleSweep(bool enabled) {
    _sweepTimer?.cancel();

    if (!enabled) {
      setState(() => _sweepOn = false);
      _resetLocalState(send: true);
      _addLog('Balayage de test arrêté.');
      return;
    }

    if (!_connected) {
      _addLog('Connecte d’abord le Mac pour lancer le balayage.');
      return;
    }

    // Le balayage doit être la seule source de commandes pendant le test.
    _resetLocalState(send: true);

    // Use elapsed time instead of adding a fixed phase per Timer tick.
    // 120 Hz sampling produces a denser, smoother full orbit on the Pixel 7.
    final Stopwatch sweepClock = Stopwatch()..start();
    const double revolutionSeconds = 3.6;
    setState(() => _sweepOn = true);
    _addLog('Balayage de test démarré (jusqu’à 120 Hz).');

    _sweepTimer = Timer.periodic(const Duration(milliseconds: 8), (_) {
      if (!mounted || !_sweepOn) return;
      final double elapsedSeconds = sweepClock.elapsedMicroseconds / 1000000.0;
      final double phase = (elapsedSeconds / revolutionSeconds) * 2.0 * math.pi;
      setState(() {
        _state.lx = GamepadState.axis16(math.cos(phase));
        _state.ly = GamepadState.axis16(math.sin(phase));
        _state.rx = GamepadState.axis16(math.cos(-phase));
        _state.ry = GamepadState.axis16(math.sin(-phase));

        final int leftSweep = GamepadState.trigger8(
          (math.sin(phase) + 1.0) / 2.0,
        );
        final int rightSweep = GamepadState.trigger8(
          (math.cos(phase) + 1.0) / 2.0,
        );
        _state.lt = _controllerProfile.digitalTriggers
            ? (leftSweep >= 128 ? 255 : 0)
            : leftSweep;
        _state.rt = _controllerProfile.digitalTriggers
            ? (rightSweep >= 128 ? 255 : 0)
            : rightSweep;

        _state.buttons = 1 << ((phase / 1.5).floor() % kButtonNames.length);
        _state.hat = 8;
        _directions.fillRange(0, _directions.length, false);
      });
      _pushReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget page = switch (_page) {
      1 => _padPage(),
      2 => _settingsPage(),
      _ => _connectionPage(),
    };

    return Scaffold(
      body: page,
      bottomNavigationBar: _page == 1
          ? null
          : NavigationBar(
              selectedIndex: _page == 2 ? 2 : 0,
              onDestinationSelected: (int index) {
                switch (index) {
                  case 0:
                    unawaited(_returnToConnectionPage());
                    break;
                  case 1:
                    unawaited(_openControllerPage());
                    break;
                  case 2:
                    unawaited(_openSettingsPage());
                    break;
                }
              },
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.bluetooth_rounded),
                  label: 'Connexion',
                ),
                NavigationDestination(
                  icon: Icon(Icons.sports_esports_rounded),
                  label: 'Manette',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_rounded),
                  label: 'Paramètres',
                ),
              ],
            ),
    );
  }

  Widget _connectionPage() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        children: <Widget>[
          Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  _brandAsset,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.gamepad_rounded, color: _accent),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'PADMAC',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Manette virtuelle Bluetooth',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _ConnectionBadge(connected: _connected),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Connexion au Mac',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _connected ? 'Le Mac est connecté à PadMac.' : 'Initialise le périphérique HID, rends le Pixel visible puis connecte-le depuis le Mac.',
                    style: TextStyle(color: _muted, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _initializing
                                    ? null
                                    : _initializeHid,
                                icon: _initializing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.power_settings_new_rounded,
                                        size: 18,
                                      ),
                                label: const Text(
                                  'Initialiser',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _requestDiscoverable,
                                icon: const Icon(
                                  Icons.visibility_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Rendre visible',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _loadBondedDevices,
                                icon: const Icon(
                                  Icons.devices_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Appareils appairés',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _connected ? _disconnect : null,
                                icon: const Icon(
                                  Icons.link_off_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Déconnecter',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.bluetooth_connected_rounded, color: _accent),
                      const SizedBox(width: 8),
                      Text(
                        'Appareils déjà appairés',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${_bonded.length}',
                        style: TextStyle(color: _muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_bonded.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Aucun appareil chargé. Utilise « Appareils appairés » pour actualiser la liste.',
                        style: TextStyle(color: _muted),
                      ),
                    )
                  else
                    ..._bonded.map((BondedDevice device) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: _surfaceRaised,
                          child: Icon(Icons.laptop_mac_rounded, color: _accent),
                        ),
                        title: Text(
                          device.name.isEmpty ? device.address : device.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(device.address),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _connect(device),
                      );
                    }),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.terminal_rounded, color: _accent),
                      const SizedBox(width: 8),
                      Text(
                        'Journal système',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(_logs.clear),
                        child: const Text('Effacer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 150,
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: _logs.isEmpty
                        ? Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'En attente des événements Bluetooth…',
                              style: TextStyle(color: _muted, fontSize: 12),
                            ),
                          )
                        : ListView.builder(
                            reverse: false,
                            itemCount: _logs.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  _logs[index],
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    color: _accent,
                                    fontSize: 10.5,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: SwitchListTile.adaptive(
              value: _sweepOn,
              onChanged: _toggleSweep,
              activeThumbColor: _accent,
              title: const Text('Balayage automatique'),
              subtitle: Text(
                'Fait varier les sticks, les gâchettes et les boutons pour vérifier la réception dans OJD.',
                style: TextStyle(color: _muted),
              ),
              secondary: Icon(Icons.radar_rounded, color: _accent),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => unawaited(_openControllerPage()),
            icon: const Icon(Icons.sports_esports_rounded),
            label: const Text('Ouvrir la manette'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: _accent,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsPage() {
    final ControllerProfile profile = _controllerProfile;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.tune_rounded, color: _accent, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Paramètres',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Personnalise les sensations de ta manette.',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.gamepad_rounded, color: _accent),
                      SizedBox(width: 9),
                      Text(
                        'Disposition de la manette',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ControllerProfileId>(
                    initialValue: _controllerProfileId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Profil',
                      border: OutlineInputBorder(),
                    ),
                    items: ControllerProfile.all
                        .map(
                          (ControllerProfile item) =>
                              DropdownMenuItem<ControllerProfileId>(
                                value: item.id,
                                child: Text(item.name),
                              ),
                        )
                        .toList(growable: false),
                    onChanged: _selectControllerProfile,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    profile.description,
                    style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.gamepad_rounded, color: _accent),
                      SizedBox(width: 9),
                      Text(
                        'Joysticks',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SettingsSlider(
                    title: 'Taille des sticks',
                    subtitle: 'Ajuste la surface tactile des deux joysticks.',
                    value: _stickSizeFactor,
                    min: 0.82,
                    max: 1.18,
                    divisions: 18,
                    valueLabel: '${(_stickSizeFactor * 100).round()} %',
                    onChanged: (double value) =>
                        setState(() => _stickSizeFactor = value),
                  ),
                  _SettingsSlider(
                    title: 'Sensibilité des sticks',
                    subtitle: 'Augmente ou réduit l’amplitude du mouvement.',
                    value: _stickSensitivity,
                    min: 0.60,
                    max: 1.50,
                    divisions: 18,
                    valueLabel: '${(_stickSensitivity * 100).round()} %',
                    onChanged: (double value) =>
                        setState(() => _stickSensitivity = value),
                  ),
                  _SettingsSlider(
                    title: 'Zone morte',
                    subtitle: 'Évite les petites déviations autour du centre des sticks et du pavé tactile DS4.',
                    value: _stickDeadZone,
                    min: 0.02,
                    max: 0.22,
                    divisions: 20,
                    valueLabel: '${(_stickDeadZone * 100).round()} %',
                    onChanged: (double value) =>
                        setState(() => _stickDeadZone = value),
                  ),
                ],
              ),
            ),
          ),
          if (profile.id == ControllerProfileId.dualShock4)
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.touch_app_rounded, color: _accent),
                        const SizedBox(width: 9),
                        const Text(
                          'Pavé tactile DualShock 4',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Un glissement transforme le déplacement du doigt en axes analogiques. Le stick choisi est piloté tant que le doigt reste posé ; au relâchement, sa commande physique reprend.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TouchpadStickTarget>(
                      initialValue: _touchpadTarget,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Stick commandé par le pavé tactile',
                        border: OutlineInputBorder(),
                      ),
                      items: const <DropdownMenuItem<TouchpadStickTarget>>[
                        DropdownMenuItem<TouchpadStickTarget>(
                          value: TouchpadStickTarget.left,
                          child: Text('Stick gauche (L3)'),
                        ),
                        DropdownMenuItem<TouchpadStickTarget>(
                          value: TouchpadStickTarget.right,
                          child: Text('Stick droit (R3)'),
                        ),
                      ],
                      onChanged: (TouchpadStickTarget? value) {
                        if (value == null || value == _touchpadTarget) return;
                        setState(() {
                          _touchpadTarget = value;
                          _applyEffectiveStickValues();
                        });
                        _pushReport();
                      },
                    ),
                    const SizedBox(height: 12),
                    _SettingsSlider(
                      title: 'Sensibilité du pavé tactile',
                      subtitle: 'Détermine la distance de glissement nécessaire pour atteindre l’amplitude maximale.',
                      value: _touchpadSensitivity,
                      min: 0.60,
                      max: 1.80,
                      divisions: 24,
                      valueLabel: '${(_touchpadSensitivity * 100).round()} %',
                      onChanged: (double value) =>
                          setState(() => _touchpadSensitivity = value),
                    ),
                    Text(
                      'Cette prise en charge convertit les gestes en axes HID génériques. Les coordonnées multitouch natives et le clic du pavé DS4 ne sont pas transmis.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.sports_esports_rounded, color: _accent),
                      SizedBox(width: 9),
                      Text(
                        'Gâchettes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SettingsSlider(
                    title: 'Sensibilité LT / RT',
                    subtitle: profile.digitalTriggers
                        ? 'ZL et ZR fonctionnent en tout-ou-rien dans cette disposition.'
                        : 'Permet d’atteindre la pression maximale plus tôt ou plus progressivement.',
                    value: _triggerSensitivity,
                    min: 0.60,
                    max: 1.50,
                    divisions: 18,
                    valueLabel: profile.digitalTriggers
                        ? 'Numérique'
                        : '${(_triggerSensitivity * 100).round()} %',
                    enabled: !profile.digitalTriggers,
                    onChanged: (double value) =>
                        setState(() => _triggerSensitivity = value),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Réglages personnalisés',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Les valeurs sont appliquées immédiatement. Elles reviennent aux valeurs initiales au redémarrage de l’application.',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Réinitialiser les réglages',
                    onPressed: () => setState(() {
                      _stickSizeFactor = 1.0;
                      _stickSensitivity = 1.0;
                      _stickDeadZone = 0.10;
                      _triggerSensitivity = 1.0;
                      _touchpadTarget = TouchpadStickTarget.right;
                      _touchpadSensitivity = 1.0;
                    }),
                    icon: const Icon(Icons.restart_alt_rounded),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'PADMAC  •  ${_connected ? 'CONNECTÉ' : 'EN ATTENTE DU MAC'}',
              style: TextStyle(
                color: _muted,
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _padPage() {
    final ControllerProfile profile = _controllerProfile;
    final ControllerLayoutSpec layout = switch (profile.id) {
      ControllerProfileId.xbox => XboxLayout.spec,
      ControllerProfileId.dualShock4 => DualShock4Layout.spec,
      ControllerProfileId.switchPro => SwitchProLayout.spec,
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            _palette.backgroundGradientStart,
            _background,
            _palette.backgroundGradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            final double height = constraints.maxHeight;
            final double scale = math
                .min(width / 900.0, height / 380.0)
                .clamp(0.72, 1.12)
                .toDouble();
            final double stickSize =
                116.0 * scale * _stickSizeFactor * layout.stickSizeFactor;
            final double dpadSize = 124.0 * scale * layout.dpadSizeFactor;
            final double abxySize = 138.0 * scale * layout.faceSizeFactor;
            final double bodyTop = 104.0 * scale;
            final double bodyHeight = (height - bodyTop - 5.0)
                .clamp(120.0, height)
                .toDouble();

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: <Widget>[
                Positioned.fill(
                  left: 8,
                  right: 8,
                  top: 36 * scale,
                  bottom: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.018),
                      borderRadius: BorderRadius.circular(54 * scale),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.045),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.gamepad_rounded, color: _accent, size: 19),
                      const SizedBox(width: 7),
                      Text(
                        'PADMAC',
                        style: TextStyle(
                          fontSize: 12 * scale,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _ConnectionBadge(
                      connected: _connected,
                      compact: true,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (_sweepOn)
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Icon(
                            Icons.radar_rounded,
                            color: _accent,
                            size: 17 * scale,
                          ),
                        ),
                      IconButton(
                        tooltip: 'Retour à la connexion',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 30,
                        ),
                        onPressed: () => unawaited(_returnToConnectionPage()),
                        icon: Icon(Icons.tune_rounded, size: 20 * scale),
                      ),
                    ],
                  ),
                ),

                // Gâchettes et boutons d'épaule selon le profil sélectionné.
                Positioned(
                  left: 18 * scale,
                  top: 35 * scale,
                  child: _ShoulderCluster(
                    triggerLabel: profile.leftTrigger,
                    bumperLabel: profile.leftBumper,
                    triggerValue: _state.lt,
                    bumperPressed: (_state.buttons & (1 << 4)) != 0,
                    width: 138 * scale,
                    sensitivity: _triggerSensitivity,
                    digitalTrigger: profile.digitalTriggers,
                    onTriggerChanged: (int value) => _setTrigger(true, value),
                    onBumperChanged: (bool pressed) => _setButton(4, pressed),
                  ),
                ),
                Positioned(
                  right: 18 * scale,
                  top: 35 * scale,
                  child: _ShoulderCluster(
                    triggerLabel: profile.rightTrigger,
                    bumperLabel: profile.rightBumper,
                    triggerValue: _state.rt,
                    bumperPressed: (_state.buttons & (1 << 5)) != 0,
                    width: 138 * scale,
                    sensitivity: _triggerSensitivity,
                    digitalTrigger: profile.digitalTriggers,
                    onTriggerChanged: (int value) => _setTrigger(false, value),
                    onBumperChanged: (bool pressed) => _setButton(5, pressed),
                  ),
                ),

                if (layout.showTouchpadPreview)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: bodyTop + bodyHeight * layout.touchpadTopFactor,
                    child: Center(
                      child: InteractiveTouchpad(
                        key: ValueKey<int>(_touchpadResetToken),
                        width: math.min(
                          width * layout.touchpadWidthFactor,
                          layout.touchpadMaxWidth * scale,
                        ),
                        height: layout.touchpadHeight * scale,
                        sensitivity: _touchpadSensitivity,
                        deadZone: _stickDeadZone,
                        target: _touchpadTarget,
                        enabled: !_sweepOn,
                        onGestureStart: () => _setTouchpadGestureActive(true),
                        onChanged: _setTouchpadVector,
                        onGestureEnd: () => _setTouchpadGestureActive(false),
                      ),
                    ),
                  ),

                // Stick gauche : position haute et extérieure.
                Positioned(
                  left: width * layout.leftStickLeftFactor,
                  top: bodyTop + bodyHeight * layout.leftStickTopFactor,
                  child: _Stick(
                    label: 'L STICK',
                    x: _state.lx,
                    y: _state.ly,
                    size: stickSize,
                    sensitivity: _stickSensitivity,
                    deadZone: _stickDeadZone,
                    onChanged: _setLeftStick,
                    clickLabel: 'L3',
                    clickPressed: (_state.buttons & (1 << 8)) != 0,
                    onClickChanged: (bool pressed) => _setButton(8, pressed),
                  ),
                ),

                // D-pad : plus bas et légèrement vers l'intérieur.
                Positioned(
                  left: width * layout.dpadLeftFactor,
                  top: bodyTop + bodyHeight * layout.dpadTopFactor,
                  child: _DPad(
                    size: dpadSize,
                    directions: _directions,
                    onChanged: _setDirection,
                    separated: layout.separatedDpad,
                  ),
                ),

                // Boutons centraux : les fonctions changent selon le profil.
                Positioned(
                  left: (width - 166 * scale) / 2,
                  top: bodyTop + bodyHeight * layout.centerControlsTopFactor,
                  child: _CenterControls(
                    scale: scale,
                    profile: profile,
                    leftPressed: (_state.buttons & (1 << 6)) != 0,
                    middlePressed: (_state.buttons & (1 << 11)) != 0,
                    rightPressed: (_state.buttons & (1 << 7)) != 0,
                    systemPressed: (_state.buttons & (1 << 10)) != 0,
                    onLeft: (bool pressed) => _setButton(6, pressed),
                    onMiddle: (bool pressed) => _setButton(11, pressed),
                    onRight: (bool pressed) => _setButton(7, pressed),
                    onSystem: (bool pressed) => _setButton(10, pressed),
                  ),
                ),

                // Boutons de façade : symboles propres au profil, finition commune.
                Positioned(
                  right: width * layout.faceRightFactor,
                  top: bodyTop + bodyHeight * layout.faceTopFactor,
                  child: _AbxyPad(
                    size: abxySize,
                    pressed: <int, bool>{
                      0: (_state.buttons & (1 << 0)) != 0,
                      1: (_state.buttons & (1 << 1)) != 0,
                      2: (_state.buttons & (1 << 2)) != 0,
                      3: (_state.buttons & (1 << 3)) != 0,
                    },
                    topLabel: profile.faceTop,
                    rightLabel: profile.faceRight,
                    bottomLabel: profile.faceBottom,
                    leftLabel: profile.faceLeft,
                    onChanged: _setButton,
                  ),
                ),

                // Stick droit : position basse et plus proche du centre.
                Positioned(
                  right: width * layout.rightStickRightFactor,
                  top: bodyTop + bodyHeight * layout.rightStickTopFactor,
                  child: _Stick(
                    label: 'R STICK',
                    x: _state.rx,
                    y: _state.ry,
                    size: stickSize,
                    sensitivity: _stickSensitivity,
                    deadZone: _stickDeadZone,
                    onChanged: _setRightStick,
                    clickLabel: 'R3',
                    clickPressed: (_state.buttons & (1 << 9)) != 0,
                    onClickChanged: (bool pressed) => _setButton(9, pressed),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SettingsSlider extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;
  final bool enabled;

  const _SettingsSlider({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                valueLabel,
                style: TextStyle(
                  color: enabled ? _accent : _muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: _muted, fontSize: 11)),
          Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            divisions: divisions,
            activeColor: _accent,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  final bool connected;
  final bool compact;

  const _ConnectionBadge({required this.connected, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final Color color = connected ? _accent : const Color(0xFFFF7A72);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: compact ? 6 : 8,
            height: compact ? 6 : 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(
            connected ? 'CONNECTÉ' : 'NON CONNECTÉ',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 9 : 11,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShoulderCluster extends StatelessWidget {
  final String triggerLabel;
  final String bumperLabel;
  final int triggerValue;
  final bool bumperPressed;
  final double width;
  final double sensitivity;
  final bool digitalTrigger;
  final ValueChanged<int> onTriggerChanged;
  final ValueChanged<bool> onBumperChanged;

  const _ShoulderCluster({
    required this.triggerLabel,
    required this.bumperLabel,
    required this.triggerValue,
    required this.bumperPressed,
    required this.width,
    required this.sensitivity,
    required this.digitalTrigger,
    required this.onTriggerChanged,
    required this.onBumperChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _AnalogTrigger(
            label: triggerLabel,
            value: triggerValue,
            width: width,
            sensitivity: sensitivity,
            digital: digitalTrigger,
            onChanged: onTriggerChanged,
          ),
          const SizedBox(height: 5),
          _TouchButton(
            width: width,
            height: 30 * (width / 138),
            radius: BorderRadius.circular(9),
            color: _surfaceRaised,
            pressedColor: AppTheme.current.controlPressed,
            borderColor: Colors.white24,
            pressedBorderColor: _accent,
            pressed: bumperPressed,
            onChanged: onBumperChanged,
            child: Text(
              bumperLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalogTrigger extends StatefulWidget {
  final String label;
  final int value;
  final double width;
  final double sensitivity;
  final bool digital;
  final ValueChanged<int> onChanged;

  const _AnalogTrigger({
    required this.label,
    required this.value,
    required this.width,
    required this.sensitivity,
    required this.digital,
    required this.onChanged,
  });

  @override
  State<_AnalogTrigger> createState() => _AnalogTriggerState();
}

class _AnalogTriggerState extends State<_AnalogTrigger> {
  int? _activePointer;

  void _update(PointerEvent event) {
    // Utilise la pression réelle rapportée par l'écran tactile,
    // et non la position horizontale du doigt.
    final double pressureRange = event.pressureMax - event.pressureMin;

    // Si l'appareil ne fournit pas de mesure de pression variable,
    // un appui est considéré comme une pression complète.
    final double normalized = pressureRange > 0.0
        ? ((event.pressure - event.pressureMin) / pressureRange)
              .clamp(0.0, 1.0)
              .toDouble()
        : 1.0;

    // Conserve le réglage de sensibilité existant.
    final double exponent = 1.0 / widget.sensitivity.clamp(0.4, 2.0).toDouble();

    final double scaled = math
        .pow(normalized, exponent)
        .toDouble()
        .clamp(0.0, 1.0)
        .toDouble();

    widget.onChanged(GamepadState.trigger8(scaled));
  }

  @override
  Widget build(BuildContext context) {
    final double progress = widget.value / 255.0;

    return SizedBox(
      width: widget.width,
      height: 29 * (widget.width / 138),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (PointerDownEvent event) {
          if (_activePointer != null) return;
          _activePointer = event.pointer;
          unawaited(HapticFeedback.selectionClick().catchError((Object _) {}));
          if (widget.digital) {
            widget.onChanged(255);
          } else {
            _update(event);
          }
        },
        onPointerMove: (PointerMoveEvent event) {
          if (event.pointer != _activePointer || widget.digital) return;
          _update(event);
        },
        onPointerUp: (PointerEvent event) {
          if (event.pointer != _activePointer) return;
          _activePointer = null;
          widget.onChanged(0);
        },
        onPointerCancel: (PointerEvent event) {
          if (event.pointer != _activePointer) return;
          _activePointer = null;
          widget.onChanged(0);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.current.triggerTrack,
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 85),
                    curve: Curves.easeOutCubic,
                    width: widget.width * progress,
                    height: 29 * (widget.width / 138),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      gradient: LinearGradient(
                        colors: <Color>[
                          AppTheme.current.triggerStart,
                          AppTheme.current.triggerMid,
                          AppTheme.current.triggerEnd,
                        ],
                      ),
                      boxShadow: progress > 0.02
                          ? <BoxShadow>[
                              BoxShadow(
                                color: _accent.withValues(alpha: 0.28),
                                blurRadius: 9,
                                spreadRadius: 0.5,
                              ),
                            ]
                          : const <BoxShadow>[],
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '${widget.label}  ${(progress * 100).round()} %',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TouchButton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry radius;
  final Color color;
  final Color pressedColor;
  final Color borderColor;
  final Color pressedBorderColor;
  final bool pressed;
  final ValueChanged<bool> onChanged;
  final Widget child;
  final List<BoxShadow>? boxShadow;
  final bool hapticOnPress;

  const _TouchButton({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
    required this.pressedColor,
    required this.borderColor,
    required this.pressedBorderColor,
    required this.pressed,
    required this.onChanged,
    required this.child,
    this.boxShadow,
    this.hapticOnPress = true,
  });

  @override
  State<_TouchButton> createState() => _TouchButtonState();
}

class _TouchButtonState extends State<_TouchButton> {
  final Set<int> _pointers = <int>{};

  void _down(PointerDownEvent event) {
    final bool wasEmpty = _pointers.isEmpty;
    _pointers.add(event.pointer);
    if (wasEmpty) {
      if (widget.hapticOnPress) {
        // Retour haptique léger pour les clics de stick L3/R3.
        unawaited(HapticFeedback.selectionClick().catchError((Object _) {}));
      }
      widget.onChanged(true);
    }
  }

  void _up(PointerEvent event) {
    final bool removed = _pointers.remove(event.pointer);
    if (removed && _pointers.isEmpty) widget.onChanged(false);
  }

  @override
  void dispose() {
    _pointers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool active = widget.pressed;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: AnimatedScale(
          scale: active ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 75),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 75),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? widget.pressedColor : widget.color,
              borderRadius: widget.radius,
              border: Border.all(
                color: active ? widget.pressedBorderColor : widget.borderColor,
                width: active ? 1.8 : 1.1,
              ),
              boxShadow: active
                  ? <BoxShadow>[
                      BoxShadow(
                        color: widget.pressedColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : (widget.boxShadow ?? const <BoxShadow>[]),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _DPad extends StatelessWidget {
  final double size;
  final List<bool> directions;
  final void Function(int index, bool pressed) onChanged;
  final bool separated;

  const _DPad({
    required this.size,
    required this.directions,
    required this.onChanged,
    this.separated = false,
  });

  @override
  Widget build(BuildContext context) {
    final double cell = size / 3;
    final double inner = cell * 0.94;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: <Widget>[
          // La disposition Xbox conserve sa base directionnelle en croix.
          // Sony et Nintendo affichent quatre touches distinctes.
          if (!separated)
            Positioned(
              left: cell,
              top: 1,
              width: cell,
              height: size - 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.current.dpadBase,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white10),
                ),
              ),
            ),
          if (!separated)
            Positioned(
              left: 1,
              top: cell,
              width: size - 2,
              height: cell,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.current.dpadBase,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white10),
                ),
              ),
            ),
          Positioned(
            left: cell + (cell - inner) / 2,
            top: (cell - inner) / 2,
            child: _TouchButton(
              width: inner,
              height: inner,
              radius: BorderRadius.circular(10),
              color: AppTheme.current.controlSurface,
              pressedColor: AppTheme.current.dpadPressed,
              borderColor: Colors.white12,
              pressedBorderColor: _accent,
              pressed: directions[0],
              onChanged: (bool value) => onChanged(0, value),
              child: const Icon(Icons.keyboard_arrow_up_rounded, size: 23),
            ),
          ),
          Positioned(
            left: cell * 2 + (cell - inner) / 2,
            top: cell + (cell - inner) / 2,
            child: _TouchButton(
              width: inner,
              height: inner,
              radius: BorderRadius.circular(10),
              color: AppTheme.current.controlSurface,
              pressedColor: AppTheme.current.dpadPressed,
              borderColor: Colors.white12,
              pressedBorderColor: _accent,
              pressed: directions[1],
              onChanged: (bool value) => onChanged(1, value),
              child: const Icon(Icons.keyboard_arrow_right_rounded, size: 23),
            ),
          ),
          Positioned(
            left: cell + (cell - inner) / 2,
            top: cell * 2 + (cell - inner) / 2,
            child: _TouchButton(
              width: inner,
              height: inner,
              radius: BorderRadius.circular(10),
              color: AppTheme.current.controlSurface,
              pressedColor: AppTheme.current.dpadPressed,
              borderColor: Colors.white12,
              pressedBorderColor: _accent,
              pressed: directions[2],
              onChanged: (bool value) => onChanged(2, value),
              child: const Icon(Icons.keyboard_arrow_down_rounded, size: 23),
            ),
          ),
          Positioned(
            left: (cell - inner) / 2,
            top: cell + (cell - inner) / 2,
            child: _TouchButton(
              width: inner,
              height: inner,
              radius: BorderRadius.circular(10),
              color: AppTheme.current.controlSurface,
              pressedColor: AppTheme.current.dpadPressed,
              borderColor: Colors.white12,
              pressedBorderColor: _accent,
              pressed: directions[3],
              onChanged: (bool value) => onChanged(3, value),
              child: const Icon(Icons.keyboard_arrow_left_rounded, size: 23),
            ),
          ),
          if (!separated)
            Positioned(
              left: cell + (cell - 20 * (size / 124)) / 2,
              top: cell + (cell - 20 * (size / 124)) / 2,
              child: IgnorePointer(
                child: Container(
                  width: 20 * (size / 124),
                  height: 20 * (size / 124),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171D19),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AbxyPad extends StatelessWidget {
  final double size;
  final Map<int, bool> pressed;
  final String topLabel;
  final String rightLabel;
  final String bottomLabel;
  final String leftLabel;
  final void Function(int index, bool value) onChanged;

  const _AbxyPad({
    required this.size,
    required this.pressed,
    required this.topLabel,
    required this.rightLabel,
    required this.bottomLabel,
    required this.leftLabel,
    required this.onChanged,
  });

  Widget _faceGlyph(String label, double buttonSize) {
    final PlayStationButtonSymbol? symbol = switch (label) {
      '△' => PlayStationButtonSymbol.triangle,
      '○' => PlayStationButtonSymbol.circle,
      '×' => PlayStationButtonSymbol.cross,
      '□' => PlayStationButtonSymbol.square,
      _ => null,
    };

    if (symbol != null) {
      return PlayStationButtonGlyph(
        symbol: symbol,
        size: buttonSize * 0.72,
        color: const Color(0xFFE8EEE9),
      );
    }

    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        height: 1.0,
        shadows: <Shadow>[
          Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
    );
  }

  Widget _button({
    required int index,
    required String label,
    required double buttonSize,
  }) {
    return _TouchButton(
      width: buttonSize,
      height: buttonSize,
      radius: BorderRadius.circular(buttonSize),
      color: AppTheme.current.faceSurface,
      pressedColor: AppTheme.current.facePressed,
      borderColor: AppTheme.current.controlBorder,
      pressedBorderColor: _accent,
      pressed: pressed[index] ?? false,
      onChanged: (bool value) => onChanged(index, value),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.34),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.045),
          blurRadius: 1,
          offset: const Offset(0, -1),
        ),
      ],
      child: _faceGlyph(label, buttonSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double buttonSize = size * 0.36;
    final double inset = size * 0.32;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: <Widget>[
          // Bouton du haut.
          Positioned(
            left: (size - buttonSize) / 2,
            top: 0,
            child: _button(index: 3, label: topLabel, buttonSize: buttonSize),
          ),
          // Bouton de gauche.
          Positioned(
            left: 0,
            top: (size - buttonSize) / 2,
            child: _button(index: 2, label: leftLabel, buttonSize: buttonSize),
          ),
          // Bouton de droite.
          Positioned(
            right: 0,
            top: (size - buttonSize) / 2,
            child: _button(index: 1, label: rightLabel, buttonSize: buttonSize),
          ),
          // Bouton du bas.
          Positioned(
            left: (size - buttonSize) / 2,
            bottom: 0,
            child: _button(
              index: 0,
              label: bottomLabel,
              buttonSize: buttonSize,
            ),
          ),
          Positioned(
            left: inset,
            top: inset,
            child: IgnorePointer(
              child: Container(
                width: size - 2 * inset,
                height: size - 2 * inset,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterControls extends StatelessWidget {
  final double scale;
  final ControllerProfile profile;
  final bool leftPressed;
  final bool middlePressed;
  final bool rightPressed;
  final bool systemPressed;
  final ValueChanged<bool> onLeft;
  final ValueChanged<bool> onMiddle;
  final ValueChanged<bool> onRight;
  final ValueChanged<bool> onSystem;

  const _CenterControls({
    required this.scale,
    required this.profile,
    required this.leftPressed,
    required this.middlePressed,
    required this.rightPressed,
    required this.systemPressed,
    required this.onLeft,
    required this.onMiddle,
    required this.onRight,
    required this.onSystem,
  });

  Widget _content(CenterControlKind kind, double size) {
    final double iconSize = size * 0.56;
    switch (kind) {
      case CenterControlKind.view:
        return CustomPaint(
          size: Size(iconSize, iconSize),
          painter: _ViewGlyphPainter(),
        );
      case CenterControlKind.share:
        return Icon(Icons.ios_share_rounded, size: iconSize * 0.88);
      case CenterControlKind.menu:
        return Icon(Icons.menu_rounded, size: iconSize * 0.92);
      case CenterControlKind.options:
        return Icon(Icons.more_horiz_rounded, size: iconSize * 1.12);
      case CenterControlKind.xboxGuide:
        return CustomPaint(
          size: Size(size * 0.62, size * 0.62),
          painter: _XboxGuidePainter(),
        );
      case CenterControlKind.playStation:
        return Text(
          'PS',
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            shadows: const <Shadow>[
              Shadow(
                color: Colors.black54,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        );
      case CenterControlKind.home:
        return Icon(Icons.home_rounded, size: iconSize);
      case CenterControlKind.minus:
        return Text(
          '−',
          style: TextStyle(fontSize: size * 0.62, fontWeight: FontWeight.w800),
        );
      case CenterControlKind.plus:
        return Text(
          '+',
          style: TextStyle(fontSize: size * 0.62, fontWeight: FontWeight.w800),
        );
      case CenterControlKind.consumerRecord:
        return Icon(
          Icons.fiber_manual_record_rounded,
          color: const Color(0xFFFF7770),
          size: iconSize * 0.78,
        );
    }
  }

  Widget _button({
    required double size,
    required String tooltip,
    required bool pressed,
    required ValueChanged<bool> onChanged,
    required Widget child,
    bool system = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: _TouchButton(
        width: size,
        height: size,
        radius: BorderRadius.circular(size * (system ? 0.38 : 0.34)),
        color: AppTheme.current.controlSurface,
        pressedColor: AppTheme.current.centerPressed,
        borderColor: AppTheme.current.controlBorder,
        pressedBorderColor: _accent,
        pressed: pressed,
        onChanged: onChanged,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.045),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double small = 35 * scale;
    final double system = 41 * scale;
    final CenterControlKind? middleKind = profile.middleKind;
    const double clusterWidth = 166;

    return SizedBox(
      width: clusterWidth * scale,
      height: 82 * scale,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: (clusterWidth * scale - system) / 2,
            top: 0,
            child: _button(
              size: system,
              tooltip: profile.systemTooltip,
              pressed: systemPressed,
              onChanged: onSystem,
              system: true,
              child: _content(profile.systemKind, system),
            ),
          ),
          Positioned(
            left: 7 * scale,
            bottom: 2 * scale,
            child: _button(
              size: small,
              tooltip: profile.centerLeftTooltip,
              pressed: leftPressed,
              onChanged: onLeft,
              child: _content(profile.centerLeftKind, small),
            ),
          ),
          if (middleKind != null)
            Positioned(
              left: (clusterWidth * scale - small) / 2,
              bottom: 2 * scale,
              child: _button(
                size: small,
                tooltip: profile.middleTooltip ?? '',
                pressed: middlePressed,
                onChanged: onMiddle,
                child: _content(middleKind, small),
              ),
            ),
          Positioned(
            right: 7 * scale,
            bottom: 2 * scale,
            child: _button(
              size: small,
              tooltip: profile.centerRightTooltip,
              pressed: rightPressed,
              onChanged: onRight,
              child: _content(profile.centerRightKind, small),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewGlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, size.width * 0.10).toDouble()
      ..strokeJoin = StrokeJoin.round;

    final RRect back = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.34,
        size.height * 0.12,
        size.width * 0.56,
        size.height * 0.62,
      ),
      Radius.circular(size.width * 0.08),
    );
    final RRect front = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.10,
        size.height * 0.29,
        size.width * 0.56,
        size.height * 0.62,
      ),
      Radius.circular(size.width * 0.08),
    );
    canvas.drawRRect(back, paint);
    canvas.drawRRect(front, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _XboxGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.6, size.width * 0.10).toDouble()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Rect oval = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.08,
      size.width * 0.84,
      size.height * 0.84,
    );
    canvas.drawOval(oval, paint);

    final Path x = Path()
      ..moveTo(size.width * 0.27, size.height * 0.29)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.42,
        size.width * 0.73,
        size.height * 0.71,
      )
      ..moveTo(size.width * 0.73, size.height * 0.29)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.42,
        size.width * 0.27,
        size.height * 0.71,
      );
    canvas.drawPath(x, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Stick extends StatefulWidget {
  final String label;
  final int x;
  final int y;
  final double size;
  final double sensitivity;
  final double deadZone;
  final void Function(double x, double y) onChanged;
  final String clickLabel;
  final bool clickPressed;
  final ValueChanged<bool> onClickChanged;

  const _Stick({
    required this.label,
    required this.x,
    required this.y,
    required this.size,
    required this.sensitivity,
    required this.deadZone,
    required this.onChanged,
    required this.clickLabel,
    required this.clickPressed,
    required this.onClickChanged,
  });

  @override
  State<_Stick> createState() => _StickState();
}

class _StickState extends State<_Stick> {
  int? _activePointer;

  double get _travelRadius => widget.size / 2 - widget.size * 0.22;

  Offset _knobOffset() {
    final double nx = widget.x < 0 ? widget.x / 32768.0 : widget.x / 32767.0;
    final double ny = widget.y < 0 ? widget.y / 32768.0 : widget.y / 32767.0;
    Offset offset = Offset(nx, ny) * _travelRadius;
    final double distance = offset.distance;
    if (distance > _travelRadius && distance > 0) {
      offset = offset / distance * _travelRadius;
    }
    return offset;
  }

  void _move(PointerEvent event) {
    final double radius = _travelRadius;
    if (radius <= 0) return;

    final Offset center = Offset(widget.size / 2, widget.size / 2);
    final Offset raw = (event.localPosition - center) / radius;
    final double magnitude = raw.distance;

    final double deadZone = widget.deadZone.clamp(0.0, 0.35).toDouble();
    if (magnitude <= deadZone) {
      widget.onChanged(0, 0);
      return;
    }

    final double limitedMagnitude = magnitude.clamp(0.0, 1.0).toDouble();
    final double remapped = ((limitedMagnitude - deadZone) / (1.0 - deadZone))
        .clamp(0.0, 1.0)
        .toDouble();
    final double exponent = 1.0 / widget.sensitivity.clamp(0.4, 2.0).toDouble();
    final double sensitiveMagnitude = math
        .pow(remapped, exponent)
        .toDouble()
        .clamp(0.0, 1.0)
        .toDouble();
    final Offset normalized = raw / magnitude * sensitiveMagnitude;
    widget.onChanged(normalized.dx, normalized.dy);
  }

  void _release(PointerEvent event) {
    if (event.pointer != _activePointer) return;
    _activePointer = null;
    widget.onChanged(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppTheme.current;
    final Offset knob = _knobOffset();
    final double knobSize = widget.size * 0.40;
    final double center = widget.size / 2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (PointerDownEvent event) {
              if (_activePointer != null) return;
              _activePointer = event.pointer;
              _move(event);
            },
            onPointerMove: (PointerMoveEvent event) {
              if (event.pointer == _activePointer) _move(event);
            },
            onPointerUp: _release,
            onPointerCancel: _release,
            child: Stack(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        palette.stickWellStart,
                        palette.stickWellEnd,
                      ],
                    ),
                    border: Border.all(
                      color: palette.stickWellBorder,
                      width: 1.5,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.36),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.all(widget.size * 0.12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: center + knob.dx - knobSize / 2,
                  top: center + knob.dy - knobSize / 2,
                  width: knobSize,
                  height: knobSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: <Color>[
                          palette.stickKnobStart,
                          palette.stickKnobEnd,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: palette.stickKnobBorder,
                        width: 1.4,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.48),
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: knobSize * 0.16,
                        height: knobSize * 0.16,
                        decoration: BoxDecoration(
                          color: palette.stickKnobCenter,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: widget.size * 0.075,
                  child: IgnorePointer(
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontSize: widget.size * 0.075,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        _TouchButton(
          width: widget.size * 0.38,
          height: widget.size * 0.16,
          radius: BorderRadius.circular(7),
          color: _surfaceRaised,
          pressedColor: AppTheme.current.controlPressed,
          borderColor: Colors.white24,
          pressedBorderColor: _accent,
          pressed: widget.clickPressed,
          onChanged: widget.onClickChanged,
          hapticOnPress: true,
          child: Text(
            widget.clickLabel,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}
