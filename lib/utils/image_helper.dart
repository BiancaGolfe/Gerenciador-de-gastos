import 'dart:io' show Directory, File, Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;


Widget exibirImagem(String imagemPath, {BoxFit fit = BoxFit.cover}) {
  if (kIsWeb) {
    return Image.network(imagemPath, fit: fit);
  }
  return Image.file(File(imagemPath), fit: fit);
}


Future<String?> selecionarImagem(ImageSource source) async {
  
  if (!kIsWeb && source == ImageSource.camera &&
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    source = ImageSource.gallery;
  }

  final picker = ImagePicker();
  final picked = await picker.pickImage(source: source, imageQuality: 80);
  if (picked == null) return null;

  if (kIsWeb) {
    return picked.path;
  }

  final bytes = await picked.readAsBytes();
  return salvarImagemPermanente(bytes, p.basename(picked.path));
}


Future<String> salvarImagemPermanente(Uint8List bytes, String nomeArquivo) async {
  final dir = await getApplicationDocumentsDirectory();
  final pasta = Directory(p.join(dir.path, 'comprovantes'));
  if (!await pasta.exists()) await pasta.create(recursive: true);

  final arquivo = File(p.join(pasta.path, nomeArquivo));
  await arquivo.writeAsBytes(bytes);
  return arquivo.path;
}