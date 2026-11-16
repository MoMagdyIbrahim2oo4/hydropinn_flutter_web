import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hydropinn_flutter_web/core/constants/app_colors.dart';

class ColorStop {
  final double pos;
  final Color color;
  const ColorStop(this.pos, this.color);
}

class HydroColorRamps {
  static const List<ColorStop> head = [
    ColorStop(0.00, Color(0xFF141433)),
    ColorStop(0.18, Color(0xFF0B3B5C)),
    ColorStop(0.36, Color(0xFF0E7490)),
    ColorStop(0.54, Color(0xFF0D9488)),
    ColorStop(0.70, Color(0xFF65A30D)),
    ColorStop(0.84, Color(0xFFFACC15)),
    ColorStop(1.00, Color(0xFFFEF3C7)),
  ];

  static const List<ColorStop> drawdown = [
    ColorStop(0.00, Color(0xFF0A1626)),
    ColorStop(0.12, Color(0xFF0E7490)),
    ColorStop(0.32, Color(0xFF22D3EE)),
    ColorStop(0.52, Color(0xFFA3E635)),
    ColorStop(0.70, Color(0xFFFACC15)),
    ColorStop(0.86, Color(0xFFFB923C)),
    ColorStop(1.00, Color(0xFFEF4444)),
  ];

  static const List<ColorStop> diverge = [
    ColorStop(0.00, Color(0xFFEF4444)),
    ColorStop(0.22, Color(0xFFFB923C)),
    ColorStop(0.42, Color(0xFFF59E0B)),
    ColorStop(0.50, Color(0xFF232C3D)),
    ColorStop(0.58, Color(0xFF0E7490)),
    ColorStop(0.78, Color(0xFF22D3EE)),
    ColorStop(1.00, Color(0xFFA7F3D0)),
  ];

  static const List<ColorStop> error = [
    ColorStop(0.00, Color(0xFF0B2B3A)),
    ColorStop(0.25, Color(0xFF0E7490)),
    ColorStop(0.50, Color(0xFF0D9488)),
    ColorStop(0.70, Color(0xFFA3E635)),
    ColorStop(0.86, Color(0xFFFACC15)),
    ColorStop(1.00, Color(0xFFFB7185)),
  ];

  static List<ColorStop> byName(String name) {
    switch (name) {
      case 'drawdown':
        return drawdown;
      case 'diverge':
        return diverge;
      case 'error':
        return error;
      case 'head':
      default:
        return head;
    }
  }

  static Color sample(List<ColorStop> ramp, double t) {
    final clamped = t.clamp(0.0, 1.0);
    for (int i = 0; i < ramp.length - 1; i++) {
      final a = ramp[i];
      final b = ramp[i + 1];
      if (clamped >= a.pos && clamped <= b.pos) {
        final k = (clamped - a.pos) / (b.pos - a.pos + 1e-9);
        return Color.lerp(a.color, b.color, k) ?? a.color;
      }
    }
    return ramp.last.color;
  }
}

class HydroHeatmapPainter extends CustomPainter {
  final List<double> grid; // 50x50 = 2500
  final int nx;
  final int ny;
  final double minVal;
  final double maxVal;
  final String rampName;
  final bool showContours;
  final int wellRow;
  final int wellCol;
  final int? selectedRow;
  final int? selectedCol;
  final bool showCrosshair;

  HydroHeatmapPainter({
    required this.grid,
    this.nx = 50,
    this.ny = 50,
    required this.minVal,
    required this.maxVal,
    this.rampName = 'head',
    this.showContours = true,
    this.wellRow = 20,
    this.wellCol = 34,
    this.selectedRow,
    this.selectedCol,
    this.showCrosshair = true,
  });

  double _valAt(int r, int c) {
    final rr = r.clamp(0, ny - 1);
    final cc = c.clamp(0, nx - 1);
    return grid[rr * nx + cc];
  }

  double _bilinear(double gx, double gy) {
    final x0 = gx.floor().clamp(0, nx - 1);
    final y0 = gy.floor().clamp(0, ny - 1);
    final x1 = (x0 + 1).clamp(0, nx - 1);
    final y1 = (y0 + 1).clamp(0, ny - 1);
    final fx = gx - x0;
    final fy = gy - y0;
    final v00 = _valAt(y0, x0);
    final v10 = _valAt(y0, x1);
    final v01 = _valAt(y1, x0);
    final v11 = _valAt(y1, x1);
    final top = v00 + (v10 - v00) * fx;
    final bot = v01 + (v11 - v01) * fx;
    return top + (bot - top) * fy;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (grid.isEmpty) return;
    final ramp = HydroColorRamps.byName(rampName);
    final span = (maxVal - minVal).abs() < 1e-9 ? 1.0 : (maxVal - minVal);

    // Upsample to 100x100 sub-cells for smooth bilinear rendering
    const int res = 100;
    final double cellW = size.width / res;
    final double cellH = size.height / res;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int py = 0; py < res; py++) {
      final gy = (py / (res - 1)) * (ny - 1);
      for (int px = 0; px < res; px++) {
        final gx = (px / (res - 1)) * (nx - 1);
        final v = _bilinear(gx, gy);
        final norm = (v - minVal) / span;
        paint.color = HydroColorRamps.sample(ramp, norm);
        canvas.drawRect(
          Rect.fromLTWH(px * cellW, py * cellH, cellW + 0.6, cellH + 0.6),
          paint,
        );
      }
    }

    // Subtle coordinate grid lines (every 10 cells)
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.0;
    for (int i = 1; i < 5; i++) {
      final x = size.width * (i / 5.0);
      final y = size.height * (i / 5.0);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Iso-contours using marching segments
    if (showContours) {
      const int levels = 7;
      final contourPaint = Paint()
        ..color = Colors.white.withOpacity(0.26)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      for (int l = 1; l < levels; l++) {
        final iso = minVal + span * (l / levels);
        for (int r = 0; r < ny - 1; r++) {
          for (int c = 0; c < nx - 1; c++) {
            final v00 = _valAt(r, c);
            final v10 = _valAt(r, c + 1);
            final v01 = _valAt(r + 1, c);
            final b00 = v00 >= iso;
            final b10 = v10 >= iso;
            final b01 = v01 >= iso;
            if (b00 != b10 || b00 != b01) {
              final x = (c + 0.5) / nx * size.width;
              final y = (r + 0.5) / ny * size.height;
              canvas.drawCircle(Offset(x, y), 0.9, contourPaint);
            }
          }
        }
      }
    }

    // Selected cell crosshair lines
    if (showCrosshair && selectedRow != null && selectedCol != null) {
      final sx = (selectedCol! + 0.5) / nx * size.width;
      final sy = (selectedRow! + 0.5) / ny * size.height;
      final crossPaint = Paint()
        ..color = Colors.white.withOpacity(0.55)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(sx, 0), Offset(sx, size.height), crossPaint);
      canvas.drawLine(Offset(0, sy), Offset(size.width, sy), crossPaint);
      canvas.drawCircle(
        Offset(sx, sy),
        6.0,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    // Pumping well marker at (wellRow, wellCol)
    final wx = (wellCol + 0.5) / nx * size.width;
    final wy = (wellRow + 0.5) / ny * size.height;
    canvas.drawCircle(
      Offset(wx, wy),
      11.0,
      Paint()..color = const Color(0xFF22D3EE).withOpacity(0.28),
    );
    canvas.drawCircle(
      Offset(wx, wy),
      5.5,
      Paint()..color = const Color(0xFF22D3EE),
    );
    canvas.drawCircle(
      Offset(wx, wy),
      5.5,
      Paint()
        ..color = const Color(0xFF060A12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant HydroHeatmapPainter oldDelegate) {
    return oldDelegate.grid != grid ||
        oldDelegate.minVal != minVal ||
        oldDelegate.maxVal != maxVal ||
        oldDelegate.rampName != rampName ||
        oldDelegate.showContours != showContours ||
        oldDelegate.selectedRow != selectedRow ||
        oldDelegate.selectedCol != selectedCol;
  }
}

class ChartSeries {
  final String label;
  final List<double> x;
  final List<double> y;
  final Color color;
  final bool fillArea;
  final bool dashed;

  const ChartSeries({
    required this.label,
    required this.x,
    required this.y,
    required this.color,
    this.fillArea = false,
    this.dashed = false,
  });
}

class HydroLineChartPainter extends CustomPainter {
  final List<ChartSeries> seriesList;
  final HydroColors colors;
  final String xLabel;
  final String yLabel;
  final double? vLineX;
  final String? vLineLabel;

  HydroLineChartPainter({
    required this.seriesList,
    required this.colors,
    this.xLabel = '',
    this.yLabel = '',
    this.vLineX,
    this.vLineLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (seriesList.isEmpty || seriesList.first.x.isEmpty) return;

    const double padL = 46.0;
    const double padR = 16.0;
    const double padT = 18.0;
    const double padB = 30.0;
    final double plotW = math.max(10.0, size.width - padL - padR);
    final double plotH = math.max(10.0, size.height - padT - padB);

    double minX = double.infinity, maxX = -double.infinity;
    double minY = double.infinity, maxY = -double.infinity;

    for (final s in seriesList) {
      for (final xv in s.x) {
        if (xv < minX) minX = xv;
        if (xv > maxX) maxX = xv;
      }
      for (final yv in s.y) {
        if (yv < minY) minY = yv;
        if (yv > maxY) maxY = yv;
      }
    }
    if ((maxY - minY).abs() < 1e-6) {
      maxY += 1.0;
      minY -= 1.0;
    } else {
      final pad = (maxY - minY) * 0.08;
      maxY += pad;
      minY -= pad;
    }
    final spanX = (maxX - minX).abs() < 1e-6 ? 1.0 : (maxX - minX);
    final spanY = (maxY - minY).abs() < 1e-6 ? 1.0 : (maxY - minY);

    double toPx(double xv) => padL + ((xv - minX) / spanX) * plotW;
    double toPy(double yv) => padT + (1.0 - (yv - minY) / spanY) * plotH;

    final gridPaint = Paint()
      ..color = colors.stroke
      ..strokeWidth = 1.0;

    // Horizontal grid lines + Y labels
    const int yTicks = 4;
    for (int i = 0; i <= yTicks; i++) {
      final frac = i / yTicks;
      final yVal = maxY - frac * spanY;
      final py = padT + frac * plotH;
      canvas.drawLine(Offset(padL, py), Offset(padL + plotW, py), gridPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: yVal.toStringAsFixed(1),
          style: TextStyle(
            color: colors.faint,
            fontSize: 10,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padL - tp.width - 6, py - tp.height / 2));
    }

    // X ticks
    const int xTicks = 5;
    for (int i = 0; i <= xTicks; i++) {
      final frac = i / xTicks;
      final xVal = minX + frac * spanX;
      final px = padL + frac * plotW;
      final tp = TextPainter(
        text: TextSpan(
          text: xVal.abs() >= 100
              ? xVal.toStringAsFixed(0)
              : xVal.toStringAsFixed(1),
          style: TextStyle(
            color: colors.faint,
            fontSize: 10,
            fontFamily: 'JetBrains Mono',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(px - tp.width / 2, padT + plotH + 6));
    }

    // Optional vertical reference line
    if (vLineX != null && vLineX! >= minX && vLineX! <= maxX) {
      final vx = toPx(vLineX!);
      final vPaint = Paint()
        ..color = colors.accent.withOpacity(0.55)
        ..strokeWidth = 1.3;
      canvas.drawLine(Offset(vx, padT), Offset(vx, padT + plotH), vPaint);
    }

    // Draw series
    for (final s in seriesList) {
      if (s.x.isEmpty) continue;
      final path = Path();
      for (int i = 0; i < s.x.length; i++) {
        final px = toPx(s.x[i]);
        final py = toPy(s.y[i]);
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }

      if (s.fillArea) {
        final fillPath = Path.from(path)
          ..lineTo(toPx(s.x.last), padT + plotH)
          ..lineTo(toPx(s.x.first), padT + plotH)
          ..close();
        final fillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              s.color.withOpacity(0.28),
              s.color.withOpacity(0.02),
            ],
          ).createShader(Rect.fromLTWH(padL, padT, plotW, plotH));
        canvas.drawPath(fillPath, fillPaint);
      }

      final linePaint = Paint()
        ..color = s.color
        ..strokeWidth = s.dashed ? 1.8 : 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, linePaint);

      // Draw point dots if <= 15 points
      if (s.x.length <= 15) {
        for (int i = 0; i < s.x.length; i++) {
          canvas.drawCircle(
            Offset(toPx(s.x[i]), toPy(s.y[i])),
            3.2,
            Paint()..color = s.color,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant HydroLineChartPainter oldDelegate) => true;
}

class HydroBarChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  final int highlightIndex;
  final HydroColors colors;
  final Color barColor;

  HydroBarChartPainter({
    required this.labels,
    required this.values,
    this.highlightIndex = 4,
    required this.colors,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const double padL = 42.0;
    const double padR = 12.0;
    const double padT = 18.0;
    const double padB = 34.0;
    final double plotW = math.max(10.0, size.width - padL - padR);
    final double plotH = math.max(10.0, size.height - padT - padB);

    final double maxV = values.reduce(math.max) * 1.15;
    final gridPaint = Paint()
      ..color = colors.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 4; i++) {
      final frac = i / 4.0;
      final py = padT + frac * plotH;
      final v = maxV * (1.0 - frac);
      canvas.drawLine(Offset(padL, py), Offset(padL + plotW, py), gridPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: v.toStringAsFixed(2),
          style: TextStyle(color: colors.faint, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padL - tp.width - 6, py - tp.height / 2));
    }

    final int n = values.length;
    final double slotW = plotW / n;
    final double barW = math.min(28.0, slotW * 0.64);

    for (int i = 0; i < n; i++) {
      final double h = (values[i] / (maxV + 1e-9)) * plotH;
      final double x = padL + i * slotW + (slotW - barW) / 2;
      final double y = padT + plotH - h;
      final isSel = i == highlightIndex;
      final paint = Paint()
        ..color = isSel ? colors.accent : barColor.withOpacity(0.65);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, h),
          const Radius.circular(4),
        ),
        paint,
      );

      final lblTp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: isSel ? colors.text : colors.faint,
            fontSize: 9.5,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      lblTp.paint(
          canvas, Offset(x + barW / 2 - lblTp.width / 2, padT + plotH + 6));
    }
  }

  @override
  bool shouldRepaint(covariant HydroBarChartPainter oldDelegate) => true;
}

class MatrixHeatmapPainter extends CustomPainter {
  final List<List<double>> matrix; // 10 rows x 33 cols
  final List<String> rowLabels;
  final HydroColors colors;

  MatrixHeatmapPainter({
    required this.matrix,
    required this.rowLabels,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (matrix.isEmpty) return;
    const double padL = 56.0;
    const double padR = 10.0;
    const double padT = 8.0;
    const double padB = 22.0;
    final double plotW = math.max(10.0, size.width - padL - padR);
    final double plotH = math.max(10.0, size.height - padT - padB);

    final int rows = matrix.length;
    final int cols = matrix.first.length;
    double minV = double.infinity, maxV = -double.infinity;
    for (final r in matrix) {
      for (final v in r) {
        if (v < minV) minV = v;
        if (v > maxV) maxV = v;
      }
    }
    final span = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);
    final cellW = plotW / cols;
    final cellH = plotH / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final norm = (matrix[r][c] - minV) / span;
        final color = HydroColorRamps.sample(HydroColorRamps.error, norm);
        canvas.drawRect(
          Rect.fromLTWH(
            padL + c * cellW,
            padT + r * cellH,
            cellW - 0.8,
            cellH - 0.8,
          ),
          Paint()..color = color,
        );
      }
      final tp = TextPainter(
        text: TextSpan(
          text: rowLabels[r],
          style: TextStyle(color: colors.faint, fontSize: 9.5),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          Offset(padL - tp.width - 6,
              padT + r * cellH + cellH / 2 - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant MatrixHeatmapPainter oldDelegate) => true;
}

class RiskGaugePainter extends CustomPainter {
  final int score; // 0..100
  final String label;
  final HydroColors colors;

  RiskGaugePainter({
    required this.score,
    required this.label,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.78);
    final radius = math.min(size.width * 0.40, size.height * 0.64);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final segments = [
      (0.0, 0.45, const Color(0xFF34D399)),
      (0.45, 0.65, const Color(0xFFFACC15)),
      (0.65, 0.85, const Color(0xFFFB923C)),
      (0.85, 1.00, const Color(0xFFFB7185)),
    ];

    for (final seg in segments) {
      final startAngle = math.pi + seg.$1 * math.pi;
      final sweepAngle = (seg.$2 - seg.$1) * math.pi - 0.02;
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = seg.$3.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14.0
          ..strokeCap = StrokeCap.butt,
      );
    }

    // Needle
    final angle = math.pi + (score.clamp(0, 100) / 100.0) * math.pi;
    final needleTip = Offset(
      center.dx + math.cos(angle) * (radius - 6),
      center.dy + math.sin(angle) * (radius - 6),
    );
    canvas.drawLine(
      center,
      needleTip,
      Paint()
        ..color = colors.text
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 6.0, Paint()..color = colors.accent);

    // Score text
    final scoreTp = TextPainter(
      text: TextSpan(
        text: '$score / 100',
        style: TextStyle(
          color: colors.text,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          fontFamily: 'JetBrains Mono',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    scoreTp.paint(
        canvas, Offset(center.dx - scoreTp.width / 2, center.dy - 44));

    final lblTp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: colors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    lblTp.paint(canvas, Offset(center.dx - lblTp.width / 2, center.dy + 8));
  }

  @override
  bool shouldRepaint(covariant RiskGaugePainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.label != label;
}
