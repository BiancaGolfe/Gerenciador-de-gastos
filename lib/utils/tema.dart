import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final temaEscuro = ValueNotifier<bool>(false);

Future<void> carregarTema() async {
  final prefs = await SharedPreferences.getInstance();
  temaEscuro.value = prefs.getBool('tema_escuro') ?? false;
}

Future<void> salvarTema(bool escuro) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('tema_escuro', escuro);
}
