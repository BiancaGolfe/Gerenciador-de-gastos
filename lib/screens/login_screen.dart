import 'package:flutter/material.dart';
import '../database/usuario_helper.dart';
import '../models/usuario.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _modoLogin = true;

  void _alternarModo() => setState(() => _modoLogin = !_modoLogin);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.receipt_long_outlined, color: cs.onPrimary, size: 28),
              ),
              const SizedBox(height: 20),
              Text(
                _modoLogin ? 'Bem-vindo de volta!' : 'Criar conta',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                _modoLogin
                    ? 'Faça login para continuar'
                    : 'Preencha os dados para começar',
                style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.5)),
              ),
              const SizedBox(height: 36),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _modoLogin
                    ? _FormLogin(key: const ValueKey('login'), onAlternar: _alternarModo)
                    : _FormCadastro(key: const ValueKey('cadastro'), onAlternar: _alternarModo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Formulário de Login ───────────────────────────────────────────────────────

class _FormLogin extends StatefulWidget {
  final VoidCallback onAlternar;
  const _FormLogin({super.key, required this.onAlternar});

  @override
  State<_FormLogin> createState() => _FormLoginState();
}

class _FormLoginState extends State<_FormLogin> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    setState(() { _carregando = true; _erro = null; });

    final usuario = await UsuarioHelper.instance.buscarPorEmail(
      _emailController.text.trim().toLowerCase(),
    );

    if (!mounted) return;

    if (usuario == null || usuario.senha != _senhaController.text) {
      setState(() { _erro = 'E-mail ou senha incorretos.'; _carregando = false; });
      return;
    }

    await UsuarioHelper.instance.salvarSessao(usuario.id!);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(usuario: usuario)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('E-mail'),
        const SizedBox(height: 6),
        _Campo(controller: _emailController, hint: 'seu@email.com', tipo: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _Label('Senha'),
        const SizedBox(height: 6),
        _Campo(
          controller: _senhaController,
          hint: '••••••••',
          obscuro: !_senhaVisivel,
          sufixo: IconButton(
            icon: Icon(
              _senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: cs.onSurface.withOpacity(0.4),
            ),
            onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
          ),
        ),
        if (_erro != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_erro!, style: const TextStyle(color: Color(0xFFA32D2D), fontSize: 13)),
          ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: _carregando ? null : _entrar,
            child: _carregando
                ? SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                : const Text('Entrar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: widget.onAlternar,
            child: RichText(
              text: TextSpan(
                text: 'Não tem conta? ',
                style: TextStyle(color: cs.onSurface.withOpacity(0.5), fontSize: 14),
                children: [
                  TextSpan(
                    text: 'Criar conta',
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Formulário de Cadastro ────────────────────────────────────────────────────

class _FormCadastro extends StatefulWidget {
  final VoidCallback onAlternar;
  const _FormCadastro({super.key, required this.onAlternar});

  @override
  State<_FormCadastro> createState() => _FormCadastroState();
}

class _FormCadastroState extends State<_FormCadastro> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final senha = _senhaController.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos.');
      return;
    }
    if (senha.length < 6) {
      setState(() => _erro = 'A senha deve ter ao menos 6 caracteres.');
      return;
    }

    setState(() { _carregando = true; _erro = null; });

    final existente = await UsuarioHelper.instance.buscarPorEmail(email);
    if (!mounted) return;

    if (existente != null) {
      setState(() { _erro = 'Este e-mail já está cadastrado.'; _carregando = false; });
      return;
    }

    final usuario = await UsuarioHelper.instance.inserir(
      Usuario(nome: nome, email: email, senha: senha),
    );
    await UsuarioHelper.instance.salvarSessao(usuario.id!);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(usuario: usuario)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('Nome completo'),
        const SizedBox(height: 6),
        _Campo(controller: _nomeController, hint: 'Seu nome'),
        const SizedBox(height: 14),
        _Label('E-mail'),
        const SizedBox(height: 6),
        _Campo(controller: _emailController, hint: 'seu@email.com', tipo: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _Label('Senha'),
        const SizedBox(height: 6),
        _Campo(
          controller: _senhaController,
          hint: 'Mínimo 6 caracteres',
          obscuro: !_senhaVisivel,
          sufixo: IconButton(
            icon: Icon(
              _senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: cs.onSurface.withOpacity(0.4),
            ),
            onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
          ),
        ),
        if (_erro != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_erro!, style: const TextStyle(color: Color(0xFFA32D2D), fontSize: 13)),
          ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: _carregando ? null : _cadastrar,
            child: _carregando
                ? SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                : const Text('Criar conta', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: widget.onAlternar,
            child: RichText(
              text: TextSpan(
                text: 'Já tem conta? ',
                style: TextStyle(color: cs.onSurface.withOpacity(0.5), fontSize: 14),
                children: [
                  TextSpan(
                    text: 'Fazer login',
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
}

class _Campo extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType tipo;
  final bool obscuro;
  final Widget? sufixo;

  const _Campo({
    required this.controller,
    required this.hint,
    this.tipo = TextInputType.text,
    this.obscuro = false,
    this.sufixo,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: tipo,
      obscureText: obscuro,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.35)),
        filled: true,
        fillColor: cs.surface,
        suffixIcon: sufixo,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.onSurface.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.onSurface.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.primary),
        ),
      ),
    );
  }
}
