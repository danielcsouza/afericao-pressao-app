/// Digitação "como se fala": só dígitos, no máximo 3, e o formato do aparelho (12882 → 128/82).
class FieldChange {
  const FieldChange({
    required this.value,
    this.systolic,
    required this.jumpToDiastolic,
  });

  /// Novo valor do campo editado.
  final String value;

  /// Novo valor da alta quando o campo editado era a baixa e o texto foi reorganizado.
  final String? systolic;

  /// Se o foco deve pular da alta para a baixa.
  final bool jumpToDiastolic;
}

/// [field]: 's', 'd' ou 'p'. [raw]: texto digitado. [currentSystolic]: alta atual (para 'd').
/// [inserting]: a edição foi uma inserção (não apagar). [diastolicEmpty]: baixa vazia (para 's').
FieldChange applyInput({
  required String field,
  required String raw,
  String currentSystolic = '',
  bool inserting = true,
  bool diastolicEmpty = true,
}) {
  final sep = RegExp(r'\D').hasMatch(raw); // vírgula, ponto, barra ou espaço
  var v = raw.replaceAll(RegExp(r'\D'), '');
  if (v.length > 3) v = v.substring(0, 3);
  String? newSystolic;

  if (field == 'd') {
    final sv = currentSystolic;
    final n = int.tryParse(sv);
    if (sv.length == 2 &&
        n != null &&
        n >= 10 &&
        n <= 26 &&
        (sv + v).length >= 5) {
      final all = sv + v;
      newSystolic = all.substring(0, 3);
      v = all.substring(3);
    }
  }

  final jump =
      field == 's' &&
      v.isNotEmpty &&
      inserting &&
      (sep || v.length == 3 || (v.length == 2 && diastolicEmpty));

  return FieldChange(value: v, systolic: newSystolic, jumpToDiastolic: jump);
}
