import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'database/usuario_helper.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/tema.dart';
import 'utils/notificacoes_meta.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await carregarTema();
  await MetaNotificationService.initialize();
  runApp(const ControleGastosApp());
}

class ControleGastosApp extends StatelessWidget {
  const ControleGastosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: temaEscuro,
      builder: (_, escuro, __) => MaterialApp(
        title: 'Controle de Gastos',
        debugShowCheckedModeBanner: false,
        themeMode: escuro ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF534AB7)),  
          scaffoldBackgroundColor: const Color(0xFFF8F7FC),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            titleTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            elevation: 8,
            selectedItemColor: Color(0xFF534AB7),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF534AB7),
            brightness: Brightness.dark,
            surface: const Color(0xFF1E1E2E),
            background: const Color(0xFF181825),
          ),
          scaffoldBackgroundColor: const Color(0xFF181825),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E2E),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1E1E2E),
            selectedItemColor: Color(0xFF534AB7),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF2E2E3E), width: 0.5),
            ),
          ),
        ),
        home: const _SplashRouter(),
      ),
    );
  }
}

class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    
    temaEscuro.addListener(() => salvarTema(temaEscuro.value));
    _verificarSessao();
  }

  Future<void> _verificarSessao() async {
    final usuario = await UsuarioHelper.instance.buscarLogado();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(usuario: usuario),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
