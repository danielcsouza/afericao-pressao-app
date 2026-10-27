// Gera store/imagem-destaque-1024x500.png (imagem de destaque da Play Store).
//
//   flutter test tool/gen_feature_graphic_test.dart
//
// Degradê vermelho do ícone, o coração branco da splash à esquerda e o nome do
// app com uma linha de apoio à direita. Texto em Roboto Bold (assets/fonts).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _w = 1024;
const _h = 500;

void main() {
  testWidgets('gera a imagem de destaque', (tester) async {
    final loader = FontLoader('RobotoBrand')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    await loader.load();

    await tester.runAsync(() async {
      final heartBytes = await File('assets/icons/splash_heart.png').readAsBytes();
      final codec = await ui.instantiateImageCodec(heartBytes);
      final heart = (await codec.getNextFrame()).image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Fundo: mesmo degradê do ícone (canto claro → canto escuro).
      canvas.drawRect(
        Rect.fromLTWH(0, 0, _w.toDouble(), _h.toDouble()),
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, 0),
            Offset(_w.toDouble(), _h.toDouble()),
            const [Color(0xFFD63A4A), Color(0xFFA81C34)],
          ),
      );

      // Coração (a imagem tem margem transparente: desenha maior e centraliza).
      const heartBox = 520.0;
      canvas.drawImageRect(
        heart,
        Rect.fromLTWH(0, 0, heart.width.toDouble(), heart.height.toDouble()),
        const Rect.fromLTWH(-40, (_h - heartBox) / 2, heartBox, heartBox),
        Paint()..filterQuality = FilterQuality.high,
      );

      TextPainter text(String s, double size, {double opacity = 1}) => TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: 'RobotoBrand',
            fontSize: size,
            height: 1.15,
            color: Colors.white.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 520);

      final title = text('Diário da Pressão Arterial', 64);
      final sub = text('Anote e leve ao médico', 30, opacity: .9);
      const x = 440.0;
      final total = title.height + 16 + sub.height;
      final top = (_h - total) / 2;
      title.paint(canvas, Offset(x, top));
      sub.paint(canvas, Offset(x, top + title.height + 16));

      final image = await recorder.endRecording().toImage(_w, _h);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      File('store/imagem-destaque-1024x500.png')
          .writeAsBytesSync(bytes.buffer.asUint8List());
    });
  });
}
