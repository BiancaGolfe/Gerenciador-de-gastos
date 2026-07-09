import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'meta_limite.dart';

class MetaNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> avaliarEExibir({
    required int usuarioId,
    required double? limite,
    required double gastoAtual,
    required MetaLimiteStatus status,
    required int totalGastosMes,
  }) async {
    if (limite == null || limite <= 0) return;
    if (!status.perto && !status.atingida) return;

    final prefs = await SharedPreferences.getInstance();
    final mesAtual = '${DateTime.now().year}-${DateTime.now().month}';

    if (status.perto && !status.atingida) {
      final chaveNotificacao = 'meta_notificacao_perto_usuario_${usuarioId}_$mesAtual';
      if (prefs.getBool(chaveNotificacao) == true) return;
      await _mostrarNotificacao(
        id: 1001,
        titulo: 'Meta de gastos quase atingida',
        mensagem: 'Você está perto do limite da meta. Observe os próximos gastos.',
      );
      await prefs.setBool(chaveNotificacao, true);
      return;
    }

    if (status.atingida) {
      final chaveBase = 'meta_notificacao_atingida_usuario_${usuarioId}_$mesAtual';
      final notificacaoAtual = prefs.getInt(chaveBase) ?? 0;
      if (notificacaoAtual == 0) {
        await _mostrarNotificacao(
          id: 1002,
          titulo: 'Meta de gastos ultrapassada',
          mensagem: 'Você já ultrapassou sua meta mensal. Tente reduzir gastos não essenciais.',
        );
        await prefs.setInt(chaveBase, totalGastosMes);
        return;
      }

      if (totalGastosMes - notificacaoAtual >= 5) {
        await _mostrarNotificacao(
          id: 1003,
          titulo: 'Atenção: ainda acima da meta',
          mensagem: 'Já se passaram mais 5 gastos desde a última notificação. Evite despesas não necessárias.',
        );
        await prefs.setInt(chaveBase, totalGastosMes);
      }
    }
  }

  static Future<void> _mostrarNotificacao({
    required int id,
    required String titulo,
    required String mensagem,
  }) async {
    await _plugin.show(
      id,
      titulo,
      mensagem,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'meta_gastos',
          'Meta de gastos',
          channelDescription: 'Alertas sobre limite de gastos',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
