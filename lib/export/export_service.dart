import 'dart:typed_data';

import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Saída dos documentos: diálogo de impressão e compartilhamento de arquivos.
/// Fica atrás de uma interface para os testes não dependerem do Android.
abstract class ExportService {
  /// Abre o diálogo de impressão do sistema (que também salva em PDF).
  Future<void> printPdf(Uint8List pdf, String name);

  /// Abre a folha de compartilhamento (WhatsApp, e-mail, Drive…).
  Future<void> shareFile(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  });
}

class PlatformExportService implements ExportService {
  const PlatformExportService();

  @override
  Future<void> printPdf(Uint8List pdf, String name) async {
    await Printing.layoutPdf(
      onLayout: (_) async => pdf,
      name: name,
      // O layout é A4 deitado; sem isso o Android mostra a folha em retrato.
      format: PdfPageFormat.a4.landscape,
    );
  }

  @override
  Future<void> shareFile(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Diário da Pressão',
        files: [XFile.fromData(bytes, mimeType: mimeType, name: filename)],
        fileNameOverrides: [filename],
      ),
    );
  }
}
