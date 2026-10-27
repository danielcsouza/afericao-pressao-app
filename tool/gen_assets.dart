// Gera as camadas de ícone e splash a partir de reference/icons/maskable-512.png.
//
//   dart run tool/gen_assets.dart
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
//
// O coração branco é isolado pela cor (no fundo vermelho o canal verde é
// baixo; no coração é 255), e a linha de pulso vira um "buraco" transparente.
import 'dart:io';

import 'package:image/image.dart' as img;

const _source = 'reference/icons/maskable-512.png';

void main(List<String> args) {
  final src = img.decodePng(File(_source).readAsBytesSync())!;
  final heart = _extractHeart(src);

  // Cantos do degradê do ícone original, para recriar o fundo em outra resolução.
  final tl = src.getPixel(2, 2);
  final br = src.getPixel(src.width - 3, src.height - 3);

  Directory('assets/icons').createSync(recursive: true);
  final foreground = _layer(heart, 432, .56);
  final background = _gradient(432, tl, br);
  _save('assets/icons/ic_foreground.png', foreground);
  _save('assets/icons/ic_background.png', background);

  // `--preview caminho.png`: foreground sobre background, como o launcher mostra
  // (recortado no círculo central de 72/108 só para conferência).
  final preview = args.indexOf('--preview');
  if (preview >= 0 && preview + 1 < args.length) {
    final composed = background.clone();
    img.compositeImage(composed, foreground);
    _save(args[preview + 1], composed);
  }
  _save('assets/icons/splash_heart.png', _layer(heart, 768, .5));

  // Ícone pequeno das notificações (branco sobre transparente, 24dp).
  const densities = {'mdpi': 24, 'hdpi': 36, 'xhdpi': 48, 'xxhdpi': 72, 'xxxhdpi': 96};
  densities.forEach((name, px) {
    final dir = 'android/app/src/main/res/drawable-$name';
    Directory(dir).createSync(recursive: true);
    _save('$dir/ic_notification.png', _layer(heart, px, .88));
  });
  stdout.writeln('ok');
}

/// Coração recortado (branco, com alfa), sem as margens.
img.Image _extractHeart(img.Image src) {
  final mask = img.Image(width: src.width, height: src.height, numChannels: 4);
  var minX = src.width, minY = src.height, maxX = 0, maxY = 0;
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      final g = src.getPixel(x, y).g.toDouble();
      final a = ((g - 70) / (255 - 70)).clamp(0.0, 1.0);
      mask.setPixelRgba(x, y, 255, 255, 255, (a * 255).round());
      if (a > .5) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  return img.copyCrop(mask, x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);
}

/// Tela [size]×[size] transparente com o coração centralizado, ocupando
/// [widthFraction] da largura.
img.Image _layer(img.Image heart, int size, double widthFraction) {
  final w = (size * widthFraction).round();
  final resized = img.copyResize(heart, width: w, interpolation: img.Interpolation.cubic);
  final canvas = img.Image(width: size, height: size, numChannels: 4);
  img.compositeImage(
    canvas,
    resized,
    dstX: (size - resized.width) ~/ 2,
    dstY: (size - resized.height) ~/ 2,
  );
  return canvas;
}

img.Image _gradient(int size, img.Pixel a, img.Pixel b) {
  final out = img.Image(width: size, height: size, numChannels: 4);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final t = (x + y) / (2 * (size - 1));
      out.setPixelRgba(
        x,
        y,
        (a.r + (b.r - a.r) * t).round(),
        (a.g + (b.g - a.g) * t).round(),
        (a.b + (b.b - a.b) * t).round(),
        255,
      );
    }
  }
  return out;
}

void _save(String path, img.Image image) => File(path).writeAsBytesSync(img.encodePng(image));
