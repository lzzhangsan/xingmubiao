import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 排名奖牌（金/银/铜）。
///
/// 全部用 CustomPainter 矢量绘制，不依赖图片资源：
/// 金属锥形渐变外圈 + 立体斜面 + 月桂叶环 + 浮雕数字 + 缎面丝带 + 高光扫光 + 星芒闪烁。
/// rank 只支持 1~3，其它名次返回空组件。
class RankMedal extends StatefulWidget {
  const RankMedal({super.key, required this.rank, this.width = 72});

  final int rank;

  /// 组件宽度，高度按 72:104 等比。
  final double width;

  @override
  State<RankMedal> createState() => _RankMedalState();
}

class _RankMedalState extends State<RankMedal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rank < 1 || widget.rank > 3) return const SizedBox.shrink();
    return RepaintBoundary(
      child: SizedBox(
        width: widget.width,
        height: widget.width * 104 / 72,
        child: CustomPaint(
          painter: _MedalPainter(rank: widget.rank, anim: _ctrl),
        ),
      ),
    );
  }
}

class _Palette {
  const _Palette({
    required this.rim,
    required this.face,
    required this.deep,
    required this.light,
    required this.glow,
    required this.ribbon,
    required this.numberGrad,
    required this.numberShadow,
  });

  final List<Color> rim; // 外圈锥形渐变（首尾同色）
  final List<Color> face; // 内盘径向渐变：亮 / 中 / 暗
  final Color deep; // 最深的描边色
  final Color light; // 最亮的高光色
  final Color glow; // 外发光
  final List<Color> ribbon; // 丝带三条纹
  final List<Color> numberGrad; // 数字上下渐变
  final Color numberShadow;
}

const _gold = _Palette(
  rim: [
    Color(0xFFFFF6B0),
    Color(0xFFFFD23F),
    Color(0xFF9A6B00),
    Color(0xFFFFE57A),
    Color(0xFFD69E00),
    Color(0xFF7A5200),
    Color(0xFFFFF6B0),
  ],
  face: [Color(0xFFFFF1A8), Color(0xFFFFC928), Color(0xFFC98A00)],
  deep: Color(0xFF7A5200),
  light: Color(0xFFFFFBE0),
  glow: Color(0xFFFFC107),
  ribbon: [Color(0xFFD62828), Color(0xFFFFFFFF), Color(0xFF1D4ED8)],
  numberGrad: [Color(0xFFFFFBE6), Color(0xFFFFD34D), Color(0xFFE09A00)],
  numberShadow: Color(0xFF8A5A00),
);

const _silver = _Palette(
  rim: [
    Color(0xFFFFFFFF),
    Color(0xFFD5DAE0),
    Color(0xFF7B848E),
    Color(0xFFF2F5F8),
    Color(0xFFB5BCC4),
    Color(0xFF5F6770),
    Color(0xFFFFFFFF),
  ],
  face: [Color(0xFFF7F9FB), Color(0xFFC3CAD2), Color(0xFF8D96A0)],
  deep: Color(0xFF5A626B),
  light: Color(0xFFFFFFFF),
  glow: Color(0xFFB0C4DE),
  ribbon: [Color(0xFF2563EB), Color(0xFFFFFFFF), Color(0xFF1E3A8A)],
  numberGrad: [Color(0xFFFFFFFF), Color(0xFFDDE2E8), Color(0xFF9AA3AD)],
  numberShadow: Color(0xFF4B535C),
);

const _bronze = _Palette(
  rim: [
    Color(0xFFFFD9A8),
    Color(0xFFE39A55),
    Color(0xFF8A4B1A),
    Color(0xFFF2B27A),
    Color(0xFFB8692E),
    Color(0xFF6B3510),
    Color(0xFFFFD9A8),
  ],
  face: [Color(0xFFFFC890), Color(0xFFD9873F), Color(0xFF9A5320)],
  deep: Color(0xFF5E300F),
  light: Color(0xFFFFE9CF),
  glow: Color(0xFFFF9A3C),
  ribbon: [Color(0xFF22A04D), Color(0xFFFFFFFF), Color(0xFF14632F)],
  numberGrad: [Color(0xFFFFEBD2), Color(0xFFF0A868), Color(0xFFC06E2E)],
  numberShadow: Color(0xFF5E300F),
);

class _MedalPainter extends CustomPainter {
  _MedalPainter({required this.rank, required this.anim})
      : super(repaint: anim);

  final int rank;
  final Animation<double> anim;

  // 设计坐标系 72 x 104
  static const double _cx = 36;
  static const double _cy = 70;
  static const double _r = 28;

  _Palette get _pal => rank == 1 ? _gold : (rank == 2 ? _silver : _bronze);

  @override
  void paint(Canvas canvas, Size size) {
    final pal = _pal;
    final t = anim.value;
    final pulse = 0.5 + 0.5 * math.sin(2 * math.pi * t);
    const c = Offset(_cx, _cy);

    canvas.save();
    canvas.scale(size.width / 72);
    // 轻微上下浮动
    canvas.translate(0, 1.2 * math.sin(2 * math.pi * t));

    // 1. 外发光
    canvas.drawCircle(
      c,
      _r + 2,
      Paint()
        ..color = pal.glow.withOpacity(0.30 + 0.18 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    // 2. 丝带（左压右）
    const botY = _cy - _r * 0.9;
    _band(canvas, pal, topX: _cx - 18, botX: _cx - 2, botY: botY, hw: 7);
    _band(canvas, pal, topX: _cx + 18, botX: _cx + 2, botY: botY, hw: 7);

    // 3. 挂环
    final hook = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: const Offset(_cx, _cy - _r - 1.5), width: 11, height: 10),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      hook,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [pal.light, pal.rim[1], pal.deep],
        ).createShader(hook.outerRect),
    );

    // 4. 奖牌投影
    canvas.drawCircle(
      c.translate(0, 2.5),
      _r,
      Paint()
        ..color = Colors.black.withOpacity(0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );

    // 5. 外圈：金属锥形渐变
    final medalRect = Rect.fromCircle(center: c, radius: _r);
    canvas.drawCircle(
      c,
      _r,
      Paint()
        ..shader = SweepGradient(
          colors: pal.rim,
          transform: const GradientRotation(-math.pi / 4),
        ).createShader(medalRect),
    );
    // 外沿细描边
    canvas.drawCircle(
      c,
      _r - 0.4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = pal.deep.withOpacity(0.85),
    );
    // 斜面：暗线 + 亮线
    final bevelR = _r * 0.88;
    canvas.drawCircle(
      c,
      bevelR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = pal.deep.withOpacity(0.55),
    );
    canvas.drawCircle(
      c,
      bevelR - 1.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withOpacity(0.55),
    );

    // 6. 内盘
    final fr = _r * 0.80;
    final faceRect = Rect.fromCircle(center: c, radius: fr);
    canvas.drawCircle(
      c,
      fr,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.1,
          colors: pal.face,
          stops: const [0.0, 0.55, 1.0],
        ).createShader(faceRect),
    );
    canvas.drawCircle(
      c,
      fr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = pal.deep.withOpacity(0.5),
    );

    // 7. 月桂叶环（左右对称）
    _laurel(canvas, pal, c, fr * 0.74, mirror: false);
    _laurel(canvas, pal, c, fr * 0.74, mirror: true);

    // 8. 浮雕数字
    _number(canvas, pal, c);

    // 9. 高光：内盘上半部弧形光 + 整枚奖牌的扫光
    canvas.save();
    canvas.clipPath(Path()..addOval(faceRect));
    final gloss =
        Rect.fromLTWH(_cx - fr * 0.9, _cy - fr * 1.05, fr * 1.8, fr * 1.15);
    canvas.drawOval(
      gloss,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.55),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(gloss),
    );
    canvas.restore();

    canvas.save();
    canvas.clipPath(Path()..addOval(medalRect.deflate(0.5)));
    final sweep = (t / 0.55).clamp(0.0, 1.0);
    if (sweep < 1.0) {
      final bandX = _cx - _r * 1.6 + sweep * _r * 3.6;
      canvas.translate(bandX, _cy);
      canvas.rotate(math.pi / 6);
      final band = Rect.fromLTWH(-4, -_r * 1.6, 8, _r * 3.2);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withOpacity(0.0),
              Colors.white.withOpacity(0.6),
              Colors.white.withOpacity(0.0),
            ],
          ).createShader(band),
      );
    }
    canvas.restore();

    // 10. 星芒闪烁
    final s1 = math.max(0.0, math.sin(2 * math.pi * t));
    final s2 = math.max(0.0, math.sin(2 * math.pi * (t + 0.5)));
    if (s1 > 0.02) {
      _sparkle(
          canvas, Offset(_cx + _r * 0.78, _cy - _r * 0.62), 2.5 + 5 * s1, s1);
    }
    if (s2 > 0.02) {
      _sparkle(
          canvas, Offset(_cx - _r * 0.72, _cy + _r * 0.5), 2 + 4 * s2, s2);
    }

    canvas.restore();
  }

  /// 缎面丝带：三条纹 + 光泽 + 靠近奖牌处变暗
  void _band(Canvas canvas, _Palette pal,
      {required double topX,
      required double botX,
      required double botY,
      required double hw}) {
    final tl = Offset(topX - hw, 0);
    final tr = Offset(topX + hw, 0);
    final br = Offset(botX + hw, botY);
    final bl = Offset(botX - hw, botY);

    const fr = [0.0, 0.3, 0.7, 1.0];
    for (int i = 0; i < 3; i++) {
      final a = Offset.lerp(tl, tr, fr[i])!;
      final b = Offset.lerp(tl, tr, fr[i + 1])!;
      final c2 = Offset.lerp(bl, br, fr[i + 1])!;
      final d = Offset.lerp(bl, br, fr[i])!;
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c2.dx, c2.dy)
        ..lineTo(d.dx, d.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = pal.ribbon[i]);
    }

    final quad = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();
    final rect = Rect.fromLTRB(
        math.min(tl.dx, bl.dx), 0, math.max(tr.dx, br.dx), botY);

    // 横向缎面光泽
    canvas.drawPath(
      quad,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.black.withOpacity(0.16),
            Colors.transparent,
            Colors.white.withOpacity(0.22),
            Colors.transparent,
            Colors.black.withOpacity(0.20),
          ],
        ).createShader(rect),
    );
    // 纵向：下端被奖牌遮住的阴影
    canvas.drawPath(
      quad,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.28)],
          stops: const [0.5, 1.0],
        ).createShader(rect),
    );
    canvas.drawPath(
      quad,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = Colors.black.withOpacity(0.25),
    );
  }

  /// 单侧月桂叶；mirror 为 true 时水平镜像到右侧
  void _laurel(Canvas canvas, _Palette pal, Offset center, double rad,
      {required bool mirror}) {
    canvas.save();
    if (mirror) {
      canvas.translate(center.dx, 0);
      canvas.scale(-1, 1);
      canvas.translate(-center.dx, 0);
    }
    const n = 7;
    for (int i = 0; i < n; i++) {
      final f = i / (n - 1);
      final ang = math.pi * (0.62 + 0.80 * f);
      final p = center + Offset(math.cos(ang), math.sin(ang)) * rad;
      final len = 7.0 - 1.6 * f;
      final wid = 3.2 - 0.6 * f;
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(len * 0.5, -wid, len, 0)
        ..quadraticBezierTo(len * 0.5, wid, 0, 0);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(ang + math.pi / 2 - 0.5);
      canvas.drawPath(
        leaf,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [pal.light, pal.face[2]],
          ).createShader(Rect.fromLTWH(0, -wid, len, wid * 2)),
      );
      canvas.drawPath(
        leaf,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = pal.deep.withOpacity(0.55),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  /// 立体浮雕数字：投影 + 深色描边 + 上缘亮边 + 渐变主体
  void _number(Canvas canvas, _Palette pal, Offset center) {
    final text = '$rank';
    const fontSize = 30.0;
    TextPainter mk(Paint fg) => TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1.0,
              foreground: fg,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

    final measure = mk(Paint()..color = Colors.black);
    final off = Offset(center.dx - measure.width / 2,
        center.dy - measure.height / 2 + 0.5);

    mk(Paint()..color = pal.numberShadow.withOpacity(0.85))
        .paint(canvas, off.translate(0, 1.8));
    mk(Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeJoin = StrokeJoin.round
          ..color = pal.deep)
        .paint(canvas, off);
    mk(Paint()..color = Colors.white.withOpacity(0.75))
        .paint(canvas, off.translate(0, -0.9));
    mk(Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: pal.numberGrad,
          ).createShader(
              Rect.fromLTWH(off.dx, off.dy, measure.width, measure.height)))
        .paint(canvas, off);
  }

  void _sparkle(Canvas canvas, Offset o, double size, double opacity) {
    final p = Path()
      ..moveTo(o.dx, o.dy - size)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + size, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + size)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - size, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - size)
      ..close();
    canvas.drawPath(
      p,
      Paint()
        ..color = Colors.white.withOpacity(opacity.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _MedalPainter old) => old.rank != rank;
}
