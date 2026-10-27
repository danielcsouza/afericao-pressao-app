import 'package:flutter/material.dart';

/// Tokens de cor do app web (Adendo B do plano), claro e escuro.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.card,
    required this.ink,
    required this.muted,
    required this.line,
    required this.brand,
    required this.brandSoft,
    required this.ok,
    required this.okSoft,
    required this.warn,
    required this.warnSoft,
    required this.left,
    required this.right,
    required this.danger,
    required this.dangerLine,
    required this.statusBar,
  });

  final Color bg, card, ink, muted, line;
  final Color brand, brandSoft;
  final Color ok, okSoft, warn, warnSoft;
  final Color left, right;
  final Color danger, dangerLine;
  final Color statusBar;

  static const brandInk = Colors.white;

  static const light = AppColors(
    bg: Color(0xFFFBF7F6),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF2A1F1F),
    muted: Color(0xFF7A6A6A),
    line: Color(0xFFEADCD9),
    brand: Color(0xFFC0392B),
    brandSoft: Color(0xFFFBE6E3),
    ok: Color(0xFF2E8B57),
    okSoft: Color(0xFFE3F4EA),
    warn: Color(0xFFD98200),
    warnSoft: Color(0xFFFFF2DB),
    left: Color(0xFF2C6FBB),
    right: Color(0xFF8A4FB8),
    danger: Color(0xFFB3261E),
    dangerLine: Color(0xFFE8B8B4),
    statusBar: Color(0xFFC0392B),
  );

  static const dark = AppColors(
    bg: Color(0xFF171212),
    card: Color(0xFF241C1C),
    ink: Color(0xFFF5ECEB),
    muted: Color(0xFFB4A3A1),
    line: Color(0xFF3A2D2D),
    // O app web usa #e5594a como "brand" escuro em textos/bordas; cabeçalho e barra
    // continuam em #c0392b nos dois temas (ver [headerColor]).
    brand: Color(0xFFE5594A),
    brandSoft: Color(0xFF3A1F1C),
    ok: Color(0xFF4CC380),
    okSoft: Color(0xFF163223),
    warn: Color(0xFFF0A63A),
    warnSoft: Color(0xFF3A2A10),
    left: Color(0xFF6FA8EE),
    right: Color(0xFFC39AF0),
    danger: Color(0xFFFF8A80),
    dangerLine: Color(0xFF7A3A36),
    statusBar: Color(0xFF7A2018),
  );

  /// Cabeçalho e barra inferior: mesma cor nos dois temas.
  Color get headerColor => const Color(0xFFC0392B);

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) =>
      t < 0.5 ? this : (other as AppColors? ?? this);
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

const double cardRadius = 18;

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? AppColors.light : AppColors.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.light.brand,
        brightness: brightness,
      ).copyWith(
        primary: c.brand,
        onPrimary: AppColors.brandInk,
        surface: c.card,
        onSurface: c.ink,
        error: c.danger,
      );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    dividerColor: c.line,
    textTheme: Typography.material2021().black.apply(
      bodyColor: c.ink,
      displayColor: c.ink,
    ),
    extensions: [c],
  );
}
