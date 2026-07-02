import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class NeuralBackground extends StatefulWidget {
  final Widget? child;
  final int nodeCount;
  final bool animate;
  const NeuralBackground({super.key, this.child, this.nodeCount = 30, this.animate = true});

  @override
  State<NeuralBackground> createState() => _NeuralBackgroundState();
}

class _NeuralBackgroundState extends State<NeuralBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Node> _nodes;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _nodes = List.generate(widget.nodeCount, (_) => _Node(
      x: _rng.nextDouble(), y: _rng.nextDouble(),
      vx: (_rng.nextDouble() - 0.5) * 0.0004,
      vy: (_rng.nextDouble() - 0.5) * 0.0004,
      radius: _rng.nextDouble() * 2.5 + 1.5,
      opacity: _rng.nextDouble() * 0.5 + 0.2,
      pulseOffset: _rng.nextDouble() * math.pi * 2,
    ));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(decoration: const BoxDecoration(gradient: AppColors.darkBackground)),
      if (widget.animate)
        AnimatedBuilder(animation: _ctrl, builder: (_, __) {
          for (final n in _nodes) n.update();
          return CustomPaint(
            painter: _NeuralPainter(nodes: _nodes, time: _ctrl.value),
            child: const SizedBox.expand(),
          );
        }),
      if (widget.child != null) widget.child!,
    ]);
  }
}

class _Node {
  double x, y, vx, vy;
  final double radius, opacity, pulseOffset;
  _Node({required this.x, required this.y, required this.vx, required this.vy,
    required this.radius, required this.opacity, required this.pulseOffset});
  void update() {
    x += vx; y += vy;
    if (x < 0 || x > 1) vx = -vx;
    if (y < 0 || y > 1) vy = -vy;
    x = x.clamp(0.0, 1.0); y = y.clamp(0.0, 1.0);
  }
}

class _NeuralPainter extends CustomPainter {
  final List<_Node> nodes;
  final double time;
  static const double _dist = 0.2;
  _NeuralPainter({required this.nodes, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 0.5;
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dx = nodes[i].x - nodes[j].x;
        final dy = nodes[i].y - nodes[j].y;
        final d = math.sqrt(dx * dx + dy * dy);
        if (d >= _dist) continue;
        final alpha = (1 - d / _dist) * 0.25;
        paint.color = AppColors.darkPrimary.withOpacity(alpha);
        canvas.drawLine(
          Offset(nodes[i].x * size.width, nodes[i].y * size.height),
          Offset(nodes[j].x * size.width, nodes[j].y * size.height),
          paint,
        );
      }
    }
    for (final node in nodes) {
      final pulse = math.sin(time * math.pi * 2 + node.pulseOffset) * 0.3 + 0.7;
      final glowPaint = Paint()
        ..color = AppColors.darkPrimary.withOpacity(node.opacity * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(
        Offset(node.x * size.width, node.y * size.height),
        node.radius * pulse, glowPaint,
      );
      canvas.drawCircle(
        Offset(node.x * size.width, node.y * size.height),
        node.radius * 0.4,
        Paint()..color = Colors.white.withOpacity(node.opacity * 0.8 * pulse),
      );
    }
  }

  @override
  bool shouldRepaint(_NeuralPainter old) => true;
}
