import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 排名奖牌（金/银/铜）。
///
/// 全部用 CustomPainter 矢量绘制，不依赖图片资源：
/// 明亮的金属锥形渐变外圈 + 立体斜面 + 连枝麦穗环 + 浮雕数字 + 缎面丝带 + 光晕 + 扫光 + 星芒闪烁。
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
    required this.wheat,
  });

  final List<Color> rim; // 外圈锥形渐变（首尾同色）
  final List<Color> face; // 内盘径向渐变：亮 / 中 / 暗
  final Color deep; // 最深的描边色
  final Color light; // 最亮的高光色
  final Color glow; // 外发光
  final List<Color> ribbon; // 丝带三条纹
  final List<Color> numberGrad; // 数字上下渐变
  final Color numberShadow;
  final List<Color> wheat; // 麦穗叶片渐变：亮 -> 暗
}

const _gold = _Palette(
  rim: [
    Color(0xFFFFFCD6),
    Color(0xFFFFE65C),
    Color(0xFFE6AC00),
    Color(0xFFFFF4A8),
    Color(0xFFFFD42A),
    Color(0xFFC98A00),
    Color(0xFFFFFCD6),
  ],
  face: [Color(0xFFFFF9C2), Color(0xFFFFDC3D), Color(0xFFF2B000)],
  deep: Color(0xFF9A6A00),
  light: Color(0xFFFFFFF0),
  glow: Color(0xFFFFD21F),
  ribbon: [Color(0xFFE02B2B), Color(0xFFFFFFFF), Color(0xFF2358E6)],
  numberGrad: [Color(0xFFFFFFF0), Color(0xFFFFE770), Color(0xFFF0A800)],
  numberShadow: Color(0xFF9A6200),
  wheat: [Color(0xFFFFF3A0), Color(0xFFE0A000)],
);

const _silver = _Palette(
  rim: [
    Color(0xFFFFFFFF),
    Color(0xFFE6EAF0),
    Color(0xFF98A2AE),
    Color(0xFFF7F9FC),
    Color(0xFFC9D0D8),
    Color(0xFF7E8894),
    Color(0xFFFFFFFF),
  ],
  face: [Color(0xFFFFFFFF), Color(0xFFDDE3EA), Color(0xFFAEB8C3)],
  deep: Color(0xFF69737E),
  light: Color(0xFFFFFFFF),
  glow: Color(0xFFC4D6F0),
  ribbon: [Color(0xFF3B74F2), Color(0xFFFFFFFF), Color(0xFF1F45B5)],
  numberGrad: [Color(0xFFFFFFFF), Color(0xFFEBEFF4), Color(0xFFA9B3BE)],
  numberShadow: Color(0xFF58626D),
  wheat: [Color(0xFFFFFFFF), Color(0xFFA9B3BE)],
);

const _bronze = _Palette(
  rim: [
    Color(0xFFFFE3BD),
    Color(0xFFF2AB66),
    Color(0xFFB86A2A),
    Color(0xFFFFC890),
    Color(0xFFDA8340),
    Color(0xFF8E4A18),
    Color(0xFFFFE3BD),
  ],
  face: [Color(0xFFFFD9AE), Color(0xFFF2A55A), Color(0xFFD27A34)],
  deep: Color(0xFF7A3E12),
  light: Color(0xFFFFF0DC),
  glow: Color(0xFFFFAA55),
  ribbon: [Color(0xFF2DBE5E), Color(0xFFFFFFFF), Color(0xFF17803E)],
  numberGrad: [Color(0xFFFFF2DE), Color(0xFFFFC488), Color(0xFFD9803A)],
  numberShadow: Color(0xFF6E360C),
  wheat: [Color(0xFFFFE2BC), Color(0xFFC9772F)],
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

    // 1. 外发光（更大更亮，随呼吸起伏）
    canvas.drawCircle(
      c,
      _r + 3,
      Paint()
        ..color = pal.glow.withOpacity(0.50 + 0.25 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    // 2. 丝带（左压右）
    const botY = _cy - _r * 0.9;
    _band(canvas, pal, topX: _cx - 18, botX: _cx - 5, botY: botY, hw: 7);
    _band(canvas, pal, topX: _cx + 18, botX: _cx + 5, botY: botY, hw: 7);
    
    // 3. 挂环
    // 4. 奖牌投影
    canvas.drawCircle(
      c.translate(0, 2.5),
      _r,
      Paint()
        ..color = Colors.black.withOpacity(0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );

    // 5. 外圈：明亮的金属锥形渐变
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
        ..color = pal.deep.withOpacity(0.7),
    );
    // 斜面：暗线 + 亮线
    final bevelR = _r * 0.88;
    canvas.drawCircle(
      c,
      bevelR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = pal.deep.withOpacity(0.45),
    );
    canvas.drawCircle(
      c,
      bevelR - 1.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = Colors.white.withOpacity(0.7),
    );

    // 6. 内盘
    final fr = _r * 0.80;
    final faceRect = Rect.fromCircle(center: c, radius: fr);
    canvas.drawCircle(
      c,
      fr,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 1.15,
          colors: pal.face,
          stops: const [0.0, 0.5, 1.0],
        ).createShader(faceRect),
    );
    canvas.drawCircle(
      c,
      fr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = pal.deep.withOpacity(0.4),
    );
    // 内盘上方柔和提亮，让整体更“亮闪闪”
    canvas.save();
    canvas.clipPath(Path()..addOval(faceRect));
    final bloom = Rect.fromCircle(
        center: Offset(_cx - fr * 0.35, _cy - fr * 0.45), radius: fr * 0.95);
    canvas.drawCircle(
      bloom.center,
      bloom.width / 2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(0.55),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(bloom),
    );
    canvas.restore();

    // 7. 连枝麦穗环（左右对称）
    _wheat(canvas, pal, c, fr * 0.76, mirror: false);
    _wheat(canvas, pal, c, fr * 0.76, mirror: true);

    // 8. 浮雕数字
    _number(canvas, pal, c);

    // 9. 高光：内盘上半部弧形光 + 整枚奖牌的扫光
    canvas.save();
    canvas.clipPath(Path()..addOval(faceRect));
    final gloss =
        Rect.fromLTWH(_cx - fr * 0.9, _cy - fr * 1.05, fr * 1.8, fr * 1.1);
    canvas.drawOval(
      gloss,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.62),
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
      final band = Rect.fromLTWH(-4.5, -_r * 1.6, 9, _r * 3.2);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withOpacity(0.0),
              Colors.white.withOpacity(0.75),
              Colors.white.withOpacity(0.0),
            ],
          ).createShader(band),
      );
    }
    canvas.restore();

    // 10. 星芒闪烁（三处，错开节奏）
    final s1 = math.max(0.0, math.sin(2 * math.pi * t));
    final s2 = math.max(0.0, math.sin(2 * math.pi * (t + 0.33)));
    final s3 = math.max(0.0, math.sin(2 * math.pi * (t + 0.66)));
    if (s1 > 0.02) {
      _sparkle(
          canvas, Offset(_cx + _r * 0.78, _cy - _r * 0.62), 2.5 + 5 * s1, s1);
    }
    if (s2 > 0.02) {
      _sparkle(
          canvas, Offset(_cx - _r * 0.72, _cy + _r * 0.5), 2 + 4 * s2, s2);
    }
    if (s3 > 0.02) {
      _sparkle(
          canvas, Offset(_cx - _r * 0.55, _cy - _r * 0.8), 1.8 + 3.5 * s3, s3);
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
            Colors.black.withOpacity(0.14),
            Colors.transparent,
            Colors.white.withOpacity(0.26),
            Colors.transparent,
            Colors.black.withOpacity(0.18),
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
          colors: [Colors.transparent, Colors.black.withOpacity(0.24)],
          stops: const [0.5, 1.0],
        ).createShader(rect),
    );
    canvas.drawPath(
      quad,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = Colors.black.withOpacity(0.22),
    );
  }

  /// 绶带穿过挂环的可见部分。挂环随后绘制在带子上方，形成真实的前后遮挡。
  void _threadedRibbon(Canvas canvas, _Palette pal) {
    const width = 6.2;
    const top = 27.0;
    const bottom = 47.0;
    final rect = Rect.fromLTRB(_cx - width / 2, top, _cx + width / 2, bottom);
    final colors = pal.ribbon;
    const stops = [0.0, 0.3, 0.7, 1.0];
    for (var i = 0; i < 3; i++) {
      final left = rect.left + rect.width * stops[i];
      final right = rect.left + rect.width * stops[i + 1];
      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), Paint()..color = colors[i]);
    }
    canvas.drawRect(
      rect,
      Paint()..shader = const LinearGradient(colors: [Color(0x24000000), Color(0x00FFFFFF), Color(0x44FFFFFF), Color(0x00000000), Color(0x26000000)]).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()..style = PaintingStyle.stroke..strokeWidth = 0.45..color = Colors.black.withOpacity(0.2),
    );
  }

  /// 单侧麦穗：一根弧形主茎，叶片成对长在茎上、斜向穗尖，首尾相连像一串麦穗。
  /// mirror 为 true 时水平镜像到右侧。
  void _wheat(Canvas canvas, _Palette pal, Offset center, double rad,
      {required bool mirror}) {
    canvas.save();
    if (mirror) {
      canvas.translate(center.dx, 0);
      canvas.scale(-1, 1);
      canvas.translate(-center.dx, 0);
    }

    const a0 = 0.62 * math.pi; // 茎起点：左下
    const a1 = 1.16 * math.pi; // 茎终点：左上；左右顶部各自收尖，中央留出约 1/3 开口
    Offset at(double a) => center + Offset(math.cos(a), math.sin(a)) * rad;

    // 主茎
    final stem = Path()..moveTo(at(a0).dx, at(a0).dy);
    for (int i = 1; i <= 24; i++) {
      final a = a0 + (a1 - a0) * i / 24;
      stem.lineTo(at(a).dx, at(a).dy);
    }
    canvas.drawPath(
      stem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..strokeCap = StrokeCap.round
        ..color = pal.deep.withOpacity(0.85),
    );

    // 叶片：每个节点内外各一片，向穗尖方向倾斜；末端一片顶叶
    const n = 8;
    for (int i = 0; i < n; i++) {
      final f = i / (n - 1);
      final a = a0 + (a1 - a0) * f;
      final p = at(a);
      final tangent = a + math.pi / 2; // 指向穗尖
      final len = 4.1 - 1.2 * f;
      final wid = 1.65 - 0.35 * f;
      _leaf(canvas, pal, p, tangent - 0.62, len, wid); // 外侧
      _leaf(canvas, pal, p, tangent + 0.62, len * 0.82, wid * 0.9); // 内侧
    }
    _leaf(canvas, pal, at(a1), a1 + math.pi / 2, 3.25, 1.4); // 顶叶

    canvas.restore();
  }

  void _leaf(Canvas canvas, _Palette pal, Offset p, double angle, double len,
      double wid) {
    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(len * 0.45, -wid, len, 0)
      ..quadraticBezierTo(len * 0.45, wid, 0, 0)
      ..close();
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(angle);
    canvas.drawPath(
      leaf,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: pal.wheat,
        ).createShader(Rect.fromLTWH(0, -wid, len, wid * 2)),
    );
    canvas.drawPath(
      leaf,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = pal.deep.withOpacity(0.6),
    );
    // 叶脉
    canvas.drawLine(
      Offset.zero,
      Offset(len * 0.85, 0),
      Paint()
        ..strokeWidth = 0.4
        ..color = pal.deep.withOpacity(0.35),
    );
    canvas.restore();
  }

  /// 立体浮雕数字：投影 + 深色描边 + 上缘亮边 + 渐变主体
  void _number(Canvas canvas, _Palette pal, Offset center) {
    final text = '$rank';
    const fontSize = 34.0;
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

    mk(Paint()..color = pal.numberShadow.withOpacity(0.8))
        .paint(canvas, off.translate(0, 1.8));
    mk(Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7
          ..strokeJoin = StrokeJoin.round
          ..color = pal.deep)
        .paint(canvas, off);
    mk(Paint()..color = Colors.white.withOpacity(0.85))
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
