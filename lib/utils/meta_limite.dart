import 'package:shared_preferences/shared_preferences.dart';

class MetaLimiteStatus {
  final double percentual;
  final bool perto;
  final bool atingida;
  final double restante;

  const MetaLimiteStatus({
    required this.percentual,
    required this.perto,
    required this.atingida,
    required this.restante,
  });
}

class MetaLimiteService {
  static const String _keyLimitePrefix = 'meta_limite_mensal_usuario_';
  static const double _limiarPerigo = 0.8;

  static String _chaveLimite(int usuarioId) => '$_keyLimitePrefix$usuarioId';

  static MetaLimiteStatus calcularStatus(double gastoAtual, double? limite) {
    if (limite == null || limite <= 0) {
      return const MetaLimiteStatus(
        percentual: 0,
        perto: false,
        atingida: false,
        restante: 0,
      );
    }

    final percentual = gastoAtual / limite;
    final atingida = gastoAtual >= limite;
    final perto = percentual >= _limiarPerigo;
    final restante = limite - gastoAtual;

    return MetaLimiteStatus(
      percentual: percentual,
      perto: perto,
      atingida: atingida,
      restante: restante,
    );
  }

  static Future<double?> carregarLimite(int usuarioId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_chaveLimite(usuarioId));
  }

  static Future<void> salvarLimite(double valor, int usuarioId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_chaveLimite(usuarioId), valor);
  }

  static Future<void> limparLimite(int usuarioId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chaveLimite(usuarioId));
  }
}
