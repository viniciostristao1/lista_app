import 'package:flutter/material.dart';

/// Logo do app: dois "V" (duplo-check) em tons de azul, com sombra suave.
/// Desenho vetorial próprio — inspirado na ideia de "confirmado", sem copiar
/// nenhuma marca.
class LogoLista extends StatelessWidget {
  const LogoLista({super.key, this.size = 84});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width;
    final h = size.height;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.28));

    // fundo: gradiente azul claro
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEAF2FF), Color(0xFFCFE0FF)],
      ).createShader(rect);
    canvas.drawRRect(rrect, bg);

    Path check(double dx) => Path()
      ..moveTo(w * (0.20 + dx), h * 0.52)
      ..lineTo(w * (0.34 + dx), h * 0.67)
      ..lineTo(w * (0.60 + dx), h * 0.35);

    final sw = w * 0.10;

    // sombra dos "V"
    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0x33244A8A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.save();
    canvas.translate(0, h * 0.02);
    canvas.drawPath(check(0.0), shadow);
    canvas.drawPath(check(0.17), shadow);
    canvas.restore();

    // os dois "V" em gradiente azul
    final blue = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6FA8FF), Color(0xFF3B6FE0)],
      ).createShader(rect);
    canvas.drawPath(check(0.0), blue);
    canvas.drawPath(check(0.17), blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
