import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class BatteryView extends StatefulWidget{
  final int? battery;

  BatteryView(this.battery);

  @override
  State<StatefulWidget> createState() {
    return BatteryState();
  }
}

class BatteryState extends State<BatteryView> with TickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> animation;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(duration: Duration(seconds: 1), vsync: this);
    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
          setState(() {});
        });
      }
    });
    animation = Tween(begin: 100.0, end: (widget.battery ?? 0).toDouble())
        .animate(animationController);
    animationController.forward();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Container(
        width: width,
        height: width * 0.6,
        color: Color(0xff121a2a),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return CustomPaint(
              painter: BatteryInfoPainter(animation.value.toInt()),
            );
          },
        ));
  }
}

class BatteryInfoPainter extends CustomPainter {
  var godPaint = Paint();
  var battery = 100;
  static const double perimeter = 2 * pi;
  static const double start = perimeter * -0.25;
  double waterOff = 0;
  double off = 8;
  final Color normalColor = Color(0xff4B7EEC);
  final Color useNormalColor = Color(0x704B7EEC);
  final Color lowColor = Color(0xffD50000);
  final Color useLowColor = Color(0x70D50000);
  late Color color;
  late Color useColor;

  BatteryInfoPainter(this.battery) {
    if (battery >= 20) {
      color = normalColor;
      useColor = useNormalColor;
    } else {
      color = lowColor;
      useColor = useLowColor;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    var outRadius = size.width / 4;
    var centerPoint = Offset(size.width / 2, size.height / 2);

    paintOutBattery(canvas, centerPoint, outRadius);
    var innerRadius = outRadius * 2 / 3;
    paintMoire(
      canvas,
      centerPoint,
      innerRadius,
    );
    paintInnerBattery(canvas, centerPoint, innerRadius);
  }

  void paintInnerBattery(Canvas canvas, Offset center, double radius) {
    //画内部圆
    godPaint.color = Colors.white;
    godPaint.style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, godPaint);
    //画剩余电量百分比
    var paragraphBuilder =
    ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
      ..pushStyle(ui.TextStyle(color: Colors.white, fontSize: 30))
      ..addText("$battery")
      ..pop()
      ..pushStyle(ui.TextStyle(color: Colors.white, fontSize: 16))
      ..addText("%")
      ..pop()
      ..pushStyle(ui.TextStyle(color: Colors.white, fontSize: 9))
      ..addText("\n剩余电量");
    var paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: 60));
    Offset offset = center - Offset(25, 15);
    canvas.drawParagraph(paragraph, offset);
  }

  //画水波纹
  void paintMoire(Canvas canvas, Offset center, double radius) {
    double percent = battery / 100.0;
    canvas.clipRRect(RRect.fromRectAndRadius(
        Rect.fromCircle(center: center, radius: radius),
        Radius.circular(radius)));
    var path = Path();
    double dy = center.dy + radius - radius * 2 * percent;

    Rect rect = Rect.fromCenter(
        center: Offset(center.dx, dy), width: radius * 2, height: 30);

    path.moveTo(rect.left, (rect.bottom + rect.top) / 2);
    if (waterOff > rect.width)
      off = -off;
    else if (waterOff < 0) off = -off;
    waterOff += off;
    path.quadraticBezierTo(rect.left + waterOff, rect.top, rect.right,
        (rect.bottom + rect.top) / 2);
    path.lineTo(center.dx + radius, center.dy + radius);
    path.lineTo(center.dx - radius, center.dy + radius);
    path.lineTo(center.dx - radius, (rect.bottom + rect.top) / 2);
    godPaint.color = color;
    canvas.drawPath(path, godPaint);
  }

  void paintOutBattery(Canvas canvas, Offset center, double radius) {
    godPaint.color = useColor;
    godPaint.strokeWidth = 2;
    godPaint.style = PaintingStyle.stroke;
    var rect = Rect.fromCircle(center: center, radius: radius);
    //已经消耗的电量
    double area = perimeter * (100 - battery) / 100;
    canvas.drawArc(rect, start, area, false, godPaint);

    //剩余电量
    godPaint.color = color;
    var begin = area;
    area = perimeter - area;
    canvas.drawArc(rect, start + begin, area, false, godPaint);
    //画剩余电量的起点
    godPaint.style = PaintingStyle.fill;
    double angel = 360 * (100 - battery) / 100 - 90;
    Offset batteryPoint = Offset(center.dx + radius * cos(angel * pi / 180),
        center.dy + radius * sin(angel * pi / 180));
    canvas.drawCircle(batteryPoint, 4, godPaint);

    //画顶部的正常  低电量
    var paragraphBuilder =
    ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
      ..pushStyle(ui.TextStyle(color: Colors.white, fontSize: 8))
      ..addText(battery<20?"低电量":"正常");
    var paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: 30));
    Offset offset = rect.topCenter - Offset(15, 6);
    var background =
    Rect.fromCenter(center: rect.topCenter, width: 30, height: 14);
    var b = RRect.fromRectXY(background, 5, 5);
    godPaint.style = PaintingStyle.fill;
    canvas.drawRRect(b, godPaint);
    canvas.drawParagraph(paragraph, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    var b = oldDelegate as BatteryInfoPainter;
    waterOff = b.waterOff;
    off = b.off;
    if (battery >= 20) {
      color = normalColor;
      useColor = useNormalColor;
    } else {
      color = lowColor;
      useColor = useLowColor;
    }
    return true;
  }
}
