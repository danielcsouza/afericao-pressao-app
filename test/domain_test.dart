import 'package:diario_pressao/domain/dates.dart';
import 'package:diario_pressao/domain/input.dart';
import 'package:diario_pressao/domain/models.dart';
import 'package:diario_pressao/domain/rules.dart';
import 'package:flutter_test/flutter_test.dart';

Notebook _nb({Config config = const Config()}) => Notebook(config: config);

Entry _both(String s, String d, {String p = ''}) => Entry(
  left: Reading(s: s, d: d, p: p),
  right: Reading(s: s, d: d, p: p),
);

void main() {
  group('norm / fmtAvg', () {
    test('valores curtos valem dez vezes', () {
      expect(norm('13'), 130);
      expect(norm('8'), 80);
      expect(norm('30'), 300);
      expect(norm('31'), 31);
      expect(norm('130'), 130);
      expect(norm(''), isNull);
    });
    test('formata com vírgula', () {
      expect(fmtAvg(128), '12,8');
      expect(fmtAvg(null), '–');
    });
  });

  group('regras com configuração padrão (30 dias, 2 braços, 3 períodos)', () {
    test('contagens', () {
      var nb = _nb();
      nb = nb.withEntry(0, Period.m, _both('130', '80'));
      nb = nb.withEntry(
        0,
        Period.t,
        const Entry(
          left: Reading(s: '120', d: '70'),
        ),
      );
      final r = Rules(nb);
      expect(r.periodDone(0, Period.m), 2);
      expect(r.periodDone(0, Period.t), 1);
      expect(r.dayDone(0), 3);
      expect(r.totalDone(), 3);
      expect(nb.config.totalSlots, 180);
    });

    test('médias e diferença entre braços', () {
      var nb = _nb();
      nb = nb.withEntry(
        0,
        Period.m,
        const Entry(
          left: Reading(s: '13', d: '8', p: '70'),
          right: Reading(s: '120', d: '80', p: '72'),
        ),
      );
      final r = Rules(nb);
      final av = r.averages();
      expect(av[Arm.left]!.s, 130);
      expect(av[Arm.left]!.p, 70);
      expect(av[Arm.right]!.s, 120);
      final df = r.armDiff()!;
      expect(df.avg, 10);
      expect(df.n, 1);
    });

    test('periodHasData considera hora e qualquer campo', () {
      var nb = _nb().withEntry(2, Period.n, const Entry(time: '22:00'));
      expect(Rules(nb).periodHasData(2, Period.n), isTrue);
      nb = nb.clearPeriod(2, Period.n);
      expect(Rules(nb).periodHasData(2, Period.n), isFalse);
    });
  });

  group('configuração flexível', () {
    test('um braço só: período completo com um braço e sem diferença', () {
      final cfg = const Config(
        arms: ArmsMode.right,
        days: 7,
        periods: [Period.m],
      );
      var nb = _nb(config: cfg).withEntry(
        0,
        Period.m,
        const Entry(
          right: Reading(s: '12', d: '8'),
        ),
      );
      final r = Rules(nb);
      expect(cfg.totalSlots, 7);
      expect(r.periodComplete(0, Period.m), isTrue);
      expect(r.armDiff(), isNull);
      expect(r.averages().keys, [Arm.right]);
      expect(r.progressPercent(), (1 / 7 * 100).round());
    });

    test('só períodos ativos entram na contagem', () {
      final cfg = const Config(periods: [Period.m, Period.t]);
      var nb = _nb(config: cfg)
          .withEntry(0, Period.n, _both('130', '80'))
          .withEntry(0, Period.m, _both('130', '80'));
      expect(Rules(nb).dayDone(0), 2);
      expect(cfg.totalSlots, 30 * 4);
    });

    test('pulso desligado ignora a média de pulso', () {
      final cfg = const Config(pulse: false);
      var nb = _nb(config: cfg)
          .withEntry(0, Period.m, _both('130', '80', p: '70'));
      expect(Rules(nb).averages()[Arm.left]!.p, isNull);
    });

    test('dias ficam entre 1 e 365', () {
      expect(const Config().copyWith(days: 0).days, 1);
      expect(const Config().copyWith(days: 999).days, 365);
    });

    test('lastDayWithData', () {
      var nb = _nb().withEntry(4, Period.t, _both('130', '80'));
      expect(Rules(nb).lastDayWithData(), 4);
      expect(Rules(_nb()).lastDayWithData(), -1);
    });
  });

  group('JSON', () {
    test('ida e volta preserva tudo', () {
      var nb =
          Notebook(
            name: 'Maria',
            start: '2026-03-01',
            configured: true,
            config: const Config(
              days: 15,
              arms: ArmsMode.left,
              pulse: false,
              periods: [Period.m, Period.n],
            ),
          ).withEntry(
            3,
            Period.m,
            const Entry(
              time: '08:00',
              left: Reading(s: '13', d: '8'),
            ),
          );
      final back = Notebook.fromJson(nb.toJson());
      expect(back.name, 'Maria');
      expect(back.config.days, 15);
      expect(back.config.arms, ArmsMode.left);
      expect(back.config.periods, [Period.m, Period.n]);
      expect(back.entry(3, Period.m).left.s, '13');
      expect(back.entry(3, Period.m).time, '08:00');
    });

    test('entrada inválida vira caderno vazio padrão', () {
      final nb = Notebook.fromJson('lixo');
      expect(nb.config.days, 30);
      expect(nb.configured, isFalse);
    });
  });

  group('datas', () {
    test('todayIndex', () {
      expect(todayIndex('2026-03-01', DateTime(2026, 3, 1, 23, 59)), 0);
      expect(todayIndex('2026-03-01', DateTime(2026, 3, 11)), 10);
      expect(todayIndex('2026-03-10', DateTime(2026, 3, 1)), -9);
      expect(todayIndex('', DateTime(2026, 3, 1)), isNull);
    });
    test('dateOf cruza o mês', () {
      expect(isoOf(dateOf('2026-01-30', 3)!), '2026-02-02');
    });
  });

  group('digitação', () {
    test('só dígitos e até 3', () {
      expect(applyInput(field: 's', raw: '1a3b4').value, '134');
      expect(applyInput(field: 's', raw: '12345').value, '123');
    });
    test(
      'pula para a baixa com 3 dígitos, separador ou 2 dígitos com baixa vazia',
      () {
        expect(applyInput(field: 's', raw: '130').jumpToDiastolic, isTrue);
        expect(applyInput(field: 's', raw: '13/').jumpToDiastolic, isTrue);
        expect(applyInput(field: 's', raw: '13').jumpToDiastolic, isTrue);
        expect(
          applyInput(
            field: 's',
            raw: '13',
            diastolicEmpty: false,
          ).jumpToDiastolic,
          isFalse,
        );
        expect(applyInput(field: 's', raw: '1').jumpToDiastolic, isFalse);
        expect(
          applyInput(field: 's', raw: '130', inserting: false).jumpToDiastolic,
          isFalse,
        );
      },
    );
    test('formato do aparelho 12882 → 128/82', () {
      final c = applyInput(field: 'd', raw: '882', currentSystolic: '12');
      expect(c.systolic, '128');
      expect(c.value, '82');
    });
    test('baixa normal não reorganiza', () {
      final c = applyInput(field: 'd', raw: '8', currentSystolic: '12');
      expect(c.systolic, isNull);
      expect(c.value, '8');
    });
  });
}
