import 'package:controle_gastos/utils/meta_limite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MetaLimiteService', () {
    test('marca como perto do limite quando o gasto chega a 80%', () {
      final status = MetaLimiteService.calcularStatus(80, 100);

      expect(status.percentual, 0.8);
      expect(status.perto, isTrue);
      expect(status.atingida, isFalse);
      expect(status.restante, 20);
    });

    test('marca como atingida quando o gasto ultrapassa o limite', () {
      final status = MetaLimiteService.calcularStatus(120, 100);

      expect(status.percentual, 1.2);
      expect(status.atingida, isTrue);
      expect(status.perto, isTrue);
      expect(status.restante, -20);
    });

    test('retorna estado neutro quando não há limite definido', () {
      final status = MetaLimiteService.calcularStatus(50, null);

      expect(status.percentual, 0.0);
      expect(status.perto, isFalse);
      expect(status.atingida, isFalse);
      expect(status.restante, 0.0);
    });
  });
}
