import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Retorna o widget correto para exibir imagem em qualquer plataforma.
/// [imagemPath] pode ser um caminho de arquivo (mobile) ou URL blob (web).
Widget exibirImagem(String imagemPath, {BoxFit fit = BoxFit.cover}) {
  if (kIsWeb) {
    return Image.network(imagemPath, fit: fit);
  }
  return Image.file(File(imagemPath), fit: fit);
}

/// Abre o seletor de imagem e salva no disco (mobile) ou retorna URL blob (web).
/// Retorna o path/URL para armazenar, ou null se cancelado.
Future<String?> selecionarImagem(ImageSource source) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(source: source, imageQuality: 80);
  if (picked == null) return null;

  if (kIsWeb) {
    // Na web, o path já é uma URL blob utilizável com Image.network
    return picked.path;
  }

  // No mobile, copia para pasta permanente do app
  final bytes = await picked.readAsBytes();
  return salvarImagemPermanente(bytes, picked.name);
}

/// Salva bytes de imagem na pasta de documentos do app (mobile).
Future<String> salvarImagemPermanente(Uint8List bytes, String nomeArquivo) async {
  final dir = await getApplicationDocumentsDirectory();
  final pasta = Directory(p.join(dir.path, 'comprovantes'));
  if (!await pasta.exists()) await pasta.create(recursive: true);

  final arquivo = File(p.join(pasta.path, nomeArquivo));
  await arquivo.writeAsBytes(bytes);
  return arquivo.path;
}
