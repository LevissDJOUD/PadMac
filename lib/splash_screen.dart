import 'dart:async';

import 'package:material_ui/material_ui.dart';

class PadMacSplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const PadMacSplashScreen({super.key, required this.nextScreen});

  @override
  State<PadMacSplashScreen> createState() => _PadMacSplashScreenState();
}

class _PadMacSplashScreenState extends State<PadMacSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.84,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _navigationTimer = Timer(
      const Duration(milliseconds: 2200),
      _openNextScreen,
    );
  }

  void _openNextScreen() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.nextScreen,
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final double artworkSize = (size.width * 0.66)
        .clamp(210.0, 310.0)
        .toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF07110C),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.18),
                radius: 1.1,
                colors: <Color>[
                  Color(0xFF173D27),
                  Color(0xFF0D1D13),
                  Color(0xFF07110C),
                ],
                stops: <double>[0, 0.48, 1],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _opacity,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: artworkSize,
                        height: artworkSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: const Color(0xFF36E978)
                                  .withValues(alpha: 0.16),
                              blurRadius: 48,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/padmac_brand.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: const Color(0xFF12251A),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.sports_esports_rounded,
                                  color: Color(0xFF55D889),
                                  size: 112,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.2,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'PAD',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: 'MAC',
                              style: TextStyle(color: Color(0xFF55D889)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'TA MANETTE ANDROID POUR MAC',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFB5C7BA),
                          fontSize: 10,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 34),
                      SizedBox(
                        width: 112,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: const LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: Color(0xFF293D30),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF55D889),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 22,
            child: Text(
              'BLUETOOTH  •  GAMEPAD',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.34),
                fontSize: 9,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
