import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';

/// Stick auquel les gestes du pavé tactile sont temporairement affectés.
enum TouchpadStickTarget {
  left,
  right,
}

/// Surface tactile du profil DualShock 4.
///
/// Le widget ne transmet pas les coordonnées tactiles au périphérique HID.
/// Il convertit le déplacement du doigt en une paire d'axes analogiques
/// normalisés [-1, 1], consommée par le stick sélectionné dans `main.dart`.
class InteractiveTouchpad extends StatefulWidget {
  final double width;
  final double height;
  final double sensitivity;
  final double deadZone;
  final TouchpadStickTarget target;
  final bool enabled;
  final VoidCallback onGestureStart;
  final ValueChanged<Offset> onChanged;
  final VoidCallback onGestureEnd;

  const InteractiveTouchpad({
    super.key,
    required this.width,
    required this.height,
    required this.sensitivity,
    required this.deadZone,
    required this.target,
    required this.enabled,
    required this.onGestureStart,
    required this.onChanged,
    required this.onGestureEnd,
  });

  @override
  State<InteractiveTouchpad> createState() => _InteractiveTouchpadState();
}

class _InteractiveTouchpadState extends State<InteractiveTouchpad> {
  int? _activePointer;
  Offset _origin = Offset.zero;
  bool _touching = false;

  void _begin(PointerDownEvent event) {
    if (!widget.enabled || _activePointer != null) return;

    _activePointer = event.pointer;
    _origin = event.localPosition;
    setState(() => _touching = true);

    widget.onGestureStart();
    widget.onChanged(Offset.zero);
    unawaited(HapticFeedback.selectionClick().catchError((Object _) {}));
  }

  void _move(PointerMoveEvent event) {
    if (!widget.enabled || event.pointer != _activePointer) return;

    // Le pavé DS4 est volontairement peu haut à l'écran. L'échelle verticale
    // est donc plus courte que l'échelle horizontale pour garder un mouvement
    // haut/bas exploitable sans exiger un grand déplacement du doigt.
    final double horizontalRange =
        math.max(1.0, widget.width * 0.30).toDouble();
    final double verticalRange =
        math.max(1.0, widget.height * 0.42).toDouble();
    final double sensitivity =
        widget.sensitivity.clamp(0.4, 2.0).toDouble();

    final Offset raw = Offset(
      ((event.localPosition.dx - _origin.dx) / horizontalRange) * sensitivity,
      ((event.localPosition.dy - _origin.dy) / verticalRange) * sensitivity,
    );

    final double magnitude = raw.distance;
    final double deadZone = widget.deadZone.clamp(0.0, 0.35).toDouble();

    if (magnitude <= deadZone || magnitude == 0.0) {
      widget.onChanged(Offset.zero);
      return;
    }

    final double limitedMagnitude = magnitude.clamp(0.0, 1.0).toDouble();
    final double remappedMagnitude = ((limitedMagnitude - deadZone) /
            (1.0 - deadZone))
        .clamp(0.0, 1.0)
        .toDouble();
    final Offset normalized = raw / magnitude * remappedMagnitude;

    widget.onChanged(
      Offset(
        normalized.dx.clamp(-1.0, 1.0).toDouble(),
        normalized.dy.clamp(-1.0, 1.0).toDouble(),
      ),
    );
  }

  void _end(PointerEvent event) {
    if (event.pointer != _activePointer) return;

    _activePointer = null;
    _origin = Offset.zero;
    setState(() => _touching = false);

    // Le stick revient à son état physique précédent au relâchement.
    widget.onChanged(Offset.zero);
    widget.onGestureEnd();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppTheme.current;
    final String targetLabel = widget.target == TouchpadStickTarget.left
        ? 'STICK GAUCHE'
        : 'STICK DROIT';

    return Tooltip(
      message: widget.enabled
          ? 'Glisse ton doigt pour piloter le stick sélectionné. Relâche pour rendre la main au stick physique.'
          : 'Pavé tactile temporairement désactivé pendant le balayage de test.',
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _begin,
          onPointerMove: _move,
          onPointerUp: _end,
          onPointerCancel: _end,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF202824),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _touching ? palette.accent : palette.controlBorder,
                width: _touching ? 1.8 : 1.2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
                if (_touching)
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.20),
                    blurRadius: 10,
                    spreadRadius: 0.5,
                  ),
              ],
            ),
            child: Opacity(
              opacity: widget.enabled ? 1.0 : 0.40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.touch_app_rounded,
                    color: _touching ? palette.accent : Colors.white70,
                    size: math.max(12.0, widget.height * 0.38).toDouble(),
                  ),
                  const SizedBox(width: 7),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'PAVÉ TACTILE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: math.max(7.5, widget.height * 0.18).toDouble(),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _touching
                            ? 'ACTIVE · $targetLabel'
                            : 'GLISSE · $targetLabel',
                        style: TextStyle(
                          color: _touching ? palette.accent : Colors.white54,
                          fontSize: math.max(6.0, widget.height * 0.14).toDouble(),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
