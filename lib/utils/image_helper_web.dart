import 'dart:html' as html;
import 'dart:async';

Future<String?> tirarFotoWeb() async {
  final completer = Completer<String?>();

  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..setAttribute('capture', 'environment');

  input.onChange.listen((_) {
    final file = input.files?.first;
    if (file == null) {
      completer.complete(null);
      return;
    }
    final url = html.Url.createObjectUrl(file);
    completer.complete(url);
  });

  input.click();
  return completer.future;
}
