import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:padmac/brand_assets.dart';

import 'app_theme.dart';

class PadMacSplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const PadMacSplashScreen({super.key, required this.nextScreen});

  @override
  State<PadMacSplashScreen> createState() => _PadMacSplashScreenState();
}

class _PadMacSplashScreenState extends State<PadMacSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _contentOpacity;
  late final Animation<double> _contentOffset;
  late final Animation<double> _loadingOpacity;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.8, curve: Curves.easeOut),
    );

    _contentOffset = Tween<double>(begin: 12, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _loadingOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();

    _navigationTimer = Timer(const Duration(seconds: 5), _openNextScreen);
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

  Widget _buildTopLabel(AppPalette palette) {
    return FadeTransition(
      opacity: _contentOpacity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: palette.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: palette.accent.withValues(alpha: 0.45),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Text(
            'ANDROID  •  MAC',
            style: TextStyle(
              color: palette.muted.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(AppPalette palette) {
    return FadeTransition(
      opacity: _logoOpacity,
      child: ScaleTransition(
        scale: _logoScale,
        child: Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: palette.surfaceRaised,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: palette.accent.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: palette.accent.withValues(alpha: 0.13),
                blurRadius: 38,
                spreadRadius: 2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(palette.accent, BlendMode.srcIn),
              child: Image.asset(
                brandAssetForProfile(AppTheme.profile.value),
                width: 82,
                height: 82,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.sports_esports_rounded,
                    color: palette.accent,
                    size: 52,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrand(AppPalette palette) {
    return FadeTransition(
      opacity: _contentOpacity,
      child: AnimatedBuilder(
        animation: _contentOffset,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _contentOffset.value),
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
                children: [
                  const TextSpan(
                    text: 'PAD',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: 'MAC',
                    style: TextStyle(color: palette.accent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            Text(
              'Votre téléphone devient une manette.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(AppPalette palette) {
    return FadeTransition(
      opacity: _loadingOpacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 112,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: palette.surfaceRaised,
                valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Initialisation de PadMac...',
            style: TextStyle(
              color: palette.muted.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppTheme.current;

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond dégradé subtil.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  palette.backgroundGradientStart,
                  palette.background,
                  palette.backgroundGradientEnd,
                ],
              ),
            ),
          ),

          // Halo diffus derrière le contenu.
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.24,
            left: MediaQuery.sizeOf(context).width * 0.15,
            right: MediaQuery.sizeOf(context).width * 0.15,
            child: IgnorePointer(
              child: Container(
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.accent.withValues(alpha: 0.035),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  // Partie supérieure.
                  _buildTopLabel(palette),

                  const Spacer(flex: 3),

                  // Identité principale.
                  _buildLogo(palette),

                  const SizedBox(height: 36),

                  _buildBrand(palette),

                  const Spacer(flex: 4),

                  // Partie inférieure.
                  _buildLoading(palette),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
