import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:developer';

class QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color color;
  final Color backgroundColor;

  const QrCodeWidget({
    super.key,
    required this.data,
    required this.size,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final qrPainter = QrPainter(
        data: data,
        version: QrVersions.auto,
        dataModuleStyle: QrDataModuleStyle(color: color),
        eyeStyle: QrEyeStyle(color: color),
      );

      return Container(
        width: size,
        height: size,
        color: backgroundColor,
        child: CustomPaint(size: Size(size, size), painter: qrPainter),
      );
    } catch (e) {
      log('QR painting failed');
      return Container(
        width: size,
        height: size,
        color: backgroundColor,
        child: Center(
          child: Icon(Icons.error_outline, size: size * 0.3, color: color),
        ),
      );
    }
  }
}
