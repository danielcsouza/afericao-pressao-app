// Gera assets/icons/splash_brand.png: o nome do app (branco, fundo transparente)
// que a splash mostra embaixo do coração. A splash nativa não renderiza texto,
// então ele vai como imagem 800x320 (tamanho exigido pelo Android 12+).
//
//   flutter test tool/gen_splash_brand_test.dart
//   dart run flutter_native_splash:create
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _name = 'Diário da Pressão';
const _width = 800;
const _height = 320;

void main() {
  testWidgets('gera a imagem do nome para a splash', (tester) async {
    final loader = FontLoader('RobotoBrand')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    await loader.load();

    await tester.runAsync(() async {
      TextPainter paint(double size) => TextPainter(
        text: TextSpan(
          text: _name,
          style: TextStyle(fontFamily: 'RobotoBrand', fontSize: size, color: Colors.white),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Ajusta o corpo para o texto ocupar ~92% da largura da imagem.
      final probe = paint(100);
      final tp = paint(100 * (_width * .92) / probe.width);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      tp.paint(canvas, Offset((_width - tp.width) / 2, (_height - tp.height) / 2));
      final image = await recorder.endRecording().toImage(_width, _height);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      File('assets/icons/splash_brand.png').writeAsBytesSync(bytes.buffer.asUint8List());
    });
  });
}
