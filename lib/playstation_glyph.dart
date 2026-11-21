import 'package:material_ui/material_ui.dart';

enum PlayStationButtonSymbol { triangle, circle, cross, square }

/// Symbole PlayStation dessiné en vectoriel natif Flutter.
/// Il conserve un même cadre, un centrage optique et une épaisseur cohérente
/// sans dépendance SVG ni image raster.
class PlayStationButtonGlyph extends StatelessWidget {
  final PlayStationButtonSymbol symbol;
  final double size;
  final Color color;

  const PlayStationButtonGlyph({
    super.key,
    required this.symbol,
    required this.size,
    this.color = const Color(0xFFE8EEE9),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _PlayStationButtonPainter(symbol: symbol, color: color),
      ),
    );
  }
}

class _PlayStationButtonPainter extends CustomPainter {
  final PlayStationButtonSymbol symbol;
  final Color color;

  const _PlayStationButtonPainter({required this.symbol, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = switch (symbol) {
        PlayStationButtonSymbol.cross => 7.2,
        _ => 6.4,
      }
      ..isAntiAlias = true;

    switch (symbol) {
      case PlayStationButtonSymbol.triangle:
        final Path triangle = Path()
          ..moveTo(50, 15)
          ..lineTo(82, 77)
          ..lineTo(18, 77)
          ..close();
        canvas.drawPath(triangle, paint);
        break;
      case PlayStationButtonSymbol.circle:
        canvas.drawCircle(const Offset(50, 50), 27.5, paint);
        break;
      case PlayStationButtonSymbol.cross:
        final Path cross = Path()
          ..moveTo(23, 23)
          ..lineTo(77, 77)
          ..moveTo(77, 23)
          ..lineTo(23, 77);
        canvas.drawPath(cross, paint);
        break;
      case PlayStationButtonSymbol.square:
        final RRect square = RRect.fromRectAndRadius(
          const Rect.fromLTWH(21, 21, 58, 58),
          const Radius.circular(2),
        );
        canvas.drawRRect(square, paint);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlayStationButtonPainter oldDelegate) {
    return oldDelegate.symbol != symbol || oldDelegate.color != color;
  }
}
