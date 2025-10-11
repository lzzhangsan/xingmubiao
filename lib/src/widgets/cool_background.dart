import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:xingmubiao/src/providers/app_provider.dart';
import 'package:xingmubiao/src/navigation/route_observer.dart';

// A reusable Gradient AppBar for the cool theme
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;

  const GradientAppBar({required this.title, this.actions, super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).appBarTheme.titleTextStyle ??
        const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white);

    return PreferredSize(
      preferredSize: preferredSize,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFFFF4081), Color(0xFF40C4FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(child: DefaultTextStyle(style: titleStyle, child: title)),
              if (actions != null) ...actions!,
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// A more flashy animated background intended for the "炫酷" theme.
// It's reasonably optimized but creates multiple layers of subtle animation:
// - moving multi-stop gradient
// - floating orbs with soft radial gradients
// - tiny sparkle particles with shimmer
// - occasional radial pulses
class AnimatedCoolBackground extends StatefulWidget {
  final Widget child;
  final bool dimContent; // if true, make content slightly dimmer so effects pop
  const AnimatedCoolBackground({required this.child, this.dimContent = false, super.key});

  @override
  State<AnimatedCoolBackground> createState() => _AnimatedCoolBackgroundState();
}

class _AnimatedCoolBackgroundState extends State<AnimatedCoolBackground> with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final AnimationController _controller;
  late final Ticker _pulseTicker;
  double _pulse = 0.0;
  final math.Random _rnd = math.Random();
  Offset? _tapPos;

  AnimationIntensity _intensity = AnimationIntensity.high;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    // a lightweight ticker to drive occasional pulses at random intervals
    _pulseTicker = createTicker((elapsed) {
      // slowly decay pulse
      if (_pulse > 0) {
        setState(() {
          _pulse = math.max(0, _pulse - 0.009);
        });
      } else if (_rnd.nextDouble() < 0.003) {
        // small chance to trigger a new pulse
        setState(() {
          _pulse = 0.5 + _rnd.nextDouble() * 0.9;
        });
      }
    });
  // Don't start the pulse ticker here: we call _applyIntensity() in
  // didChangeDependencies which will start it if appropriate. Starting
  // it here causes a double-start when didChangeDependencies runs.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<AppProvider>(context);
    _intensity = provider.animationIntensity;
    _applyIntensity();
    // subscribe to route changes
    try {
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _controller.stop();
      if (_pulseTicker.isActive) _pulseTicker.stop();
    } else if (state == AppLifecycleState.resumed) {
      _applyIntensity();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      routeObserver.unsubscribe(this);
    } catch (_) {}
    _controller.dispose();
    _pulseTicker.dispose();
    super.dispose();
  }

  void _applyIntensity() {
    // intensity controls whether animations run and how heavy they are
    if (!mounted) return;
    if (_intensity == AnimationIntensity.off) {
      _controller.stop();
      if (_pulseTicker.isActive) _pulseTicker.stop();
    } else {
      if (!_controller.isAnimating) _controller.repeat();
      if (!_pulseTicker.isActive) _pulseTicker.start();
    }
    // If low intensity, slow down controller a bit
    if (_intensity == AnimationIntensity.low) {
      _controller.duration = const Duration(seconds: 18);
    } else if (_intensity == AnimationIntensity.medium) {
      _controller.duration = const Duration(seconds: 12);
    } else {
      _controller.duration = const Duration(seconds: 10);
    }
  }

  // RouteAware callbacks
  @override
  void didPush() {}

  @override
  void didPop() {}

  @override
  void didPushNext() {
    // another route covered this one -> pause
    _controller.stop();
    if (_pulseTicker.isActive) _pulseTicker.stop();
  }

  @override
  void didPopNext() {
    // returned to this route -> resume based on intensity
    _applyIntensity();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) {
        // localized pulse and small ripple
        _tapPos = details.localPosition;
        setState(() {
          _pulse = math.min(1.2, _pulse + 0.6);
        });
        Future.delayed(const Duration(milliseconds: 420), () {
          if (mounted) setState(() => _tapPos = null);
        });
      },
      child: Stack(
        children: [
        // animated gradient wash layer
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + t * 2, -1),
                    end: Alignment(1 - t * 2, 1),
                    colors: const [Color(0xFF7C4DFF), Color(0xFFFF4081), Color(0xFF40C4FF)],
                    stops: const [0.0, 0.56, 1.0],
                  ),
                ),
              );
            },
          ),
        ),

        // large soft orbs
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => CustomPaint(
              painter: _SuperOrbsPainter(progress: _controller.value, pulse: _pulse, intensity: _intensity),
            ),
          ),
        ),

        // sparkle particles
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SparkleFieldPainter(progress: _controller.value, intensity: _intensity),
            ),
          ),
        ),

        // subtle glass blur + optional dim
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: Container(
              color: Colors.black.withOpacity(widget.dimContent ? 0.12 : 0.06),
              child: widget.child,
            ),
          ),
        ),

        // pulse overlay (very subtle)
        if (_pulse > 0.01)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Colors.white.withOpacity(0.06 * _pulse), Colors.transparent],
                    stops: const [0.0, 1.0],
                    radius: 0.8,
                    center: Alignment(0.0, -0.6 + 0.8 * math.sin(_controller.value * math.pi * 2)),
                  ),
                ),
              ),
            ),
          ),
        // localized tap ripple
        if (_tapPos != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TapRipplePainter(center: _tapPos!, progress: _pulse),
              ),
            ),
          ),
      ],
      ),
    );
  }
}

class _SuperOrbsPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final AnimationIntensity intensity;
  final math.Random _rnd = math.Random(42);
  _SuperOrbsPainter({required this.progress, required this.pulse, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // orb configs (number/opacity depends on intensity)
    final baseConfigs = [
      _OrbConfig(phase: 0.0, speed: 0.12, baseRadius: size.width * 0.18, color: const Color(0xFF7C4DFF)),
      _OrbConfig(phase: 0.25, speed: 0.2, baseRadius: size.width * 0.12, color: const Color(0xFFFF4081)),
      _OrbConfig(phase: 0.5, speed: 0.16, baseRadius: size.width * 0.1, color: const Color(0xFF40C4FF)),
      _OrbConfig(phase: 0.7, speed: 0.08, baseRadius: size.width * 0.14, color: const Color(0xFF9C27B0)),
      _OrbConfig(phase: 0.9, speed: 0.09, baseRadius: size.width * 0.08, color: const Color(0xFFFFC107)),
    ];

    final configs = intensity == AnimationIntensity.off
        ? []
        : intensity == AnimationIntensity.low
            ? baseConfigs.take(2).toList()
            : intensity == AnimationIntensity.medium
                ? baseConfigs.take(4).toList()
                : baseConfigs;

    for (final cfg in configs) {
      final o = _computeOrb(size, progress, cfg);
      final radius = o.radius * (1.0 + 0.08 * pulse);
      final opacityBase = intensity == AnimationIntensity.low ? 0.14 : (intensity == AnimationIntensity.medium ? 0.20 : 0.26);
      paint.shader = RadialGradient(
        colors: [o.color.withOpacity(opacityBase + 0.08 * pulse), o.color.withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: o.offset, radius: radius));
      canvas.drawCircle(o.offset, radius, paint);
    }

    // small soft blobs for depth
  final smallCount = intensity == AnimationIntensity.low ? 4 : 8;
  for (int i = 0; i < smallCount; i++) {
      final p = progress + i * 0.07;
      final dx = size.width * ((i + 3) / 11 + 0.06 * math.sin(p * 2 * math.pi * (i + 1)));
      final dy = size.height * (0.2 + 0.6 * math.cos(p * 2 * math.pi * (i + 1)) * 0.5);
      final radius = size.width * (0.03 + 0.02 * math.sin(p * 4 * math.pi));
      final color = Colors.white.withOpacity((intensity == AnimationIntensity.low ? 0.01 : 0.02) + 0.02 * math.sin(p * 6 * math.pi));
      paint.color = color;
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  _Orb _computeOrb(Size size, double p, _OrbConfig cfg) {
    final t = (p * cfg.speed + cfg.phase) % 1.0;
    final dx = size.width * (0.15 + 0.7 * t);
    final dy = size.height * (0.25 + 0.5 * (0.5 + 0.5 * math.sin((p + cfg.phase) * 2 * math.pi)));
    final radius = cfg.baseRadius * (0.8 + 0.3 * math.sin((p + cfg.phase) * 2 * math.pi));
    return _Orb(offset: Offset(dx, dy), radius: radius.abs(), color: cfg.color);
  }

  @override
  bool shouldRepaint(covariant _SuperOrbsPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.pulse != pulse;
}

class _OrbConfig {
  final double phase;
  final double speed;
  final double baseRadius;
  final Color color;
  _OrbConfig({required this.phase, required this.speed, required this.baseRadius, required this.color});
}

class _Orb {
  final Offset offset;
  final double radius;
  final Color color;
  _Orb({required this.offset, required this.radius, required this.color});
}

class _SparkleFieldPainter extends CustomPainter {
  final double progress;
  final AnimationIntensity intensity;
  final math.Random _rnd = math.Random(123);
  _SparkleFieldPainter({required this.progress, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
  final count = intensity == AnimationIntensity.low ? 8 : (intensity == AnimationIntensity.medium ? 14 : 18);
  if (intensity == AnimationIntensity.off) return;
  for (int i = 0; i < count; i++) {
      final p = (progress + i * 0.07) % 1.0;
      final x = size.width * ((i + 0.5) / count) + 12 * math.sin(p * 2 * math.pi * (i + 2));
      final y = size.height * (0.12 + 0.7 * math.cos(p * 2 * math.pi * (i + 1)) * 0.5);
      final s = 1.0 + 2.5 * (0.5 + 0.5 * math.sin((p + i * 0.1) * 2 * math.pi));
      final baseOp = intensity == AnimationIntensity.low ? 0.06 : (intensity == AnimationIntensity.medium ? 0.10 : 0.12);
      paint.color = Colors.white.withOpacity(baseOp * (0.6 + 0.4 * math.sin(p * 2 * math.pi)));
      canvas.drawCircle(Offset(x, y), s, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleFieldPainter oldDelegate) => oldDelegate.progress != progress;
}

class _TapRipplePainter extends CustomPainter {
  final Offset center;
  final double progress;
  _TapRipplePainter({required this.center, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final maxR = math.max(size.width, size.height) * 0.6;
    final r = maxR * progress;
    paint.color = Colors.white.withOpacity(0.06 * (1.2 - progress).clamp(0.0, 1.0));
    canvas.drawCircle(center, r, paint);
  }

  @override
  bool shouldRepaint(covariant _TapRipplePainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.center != center;
}
