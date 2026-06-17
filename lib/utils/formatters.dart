import 'package:intl/intl.dart';

final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _data = DateFormat('dd/MM/yyyy', 'pt_BR');
final _mesAno = DateFormat('MMMM yyyy', 'pt_BR');
final _diaMes = DateFormat("d 'de' MMMM", 'pt_BR');

String formatarMoeda(double valor) => _moeda.format(valor);
String formatarData(DateTime data) => _data.format(data);
String formatarMesAno(DateTime data) => _mesAno.format(data);
String formatarDiaMes(DateTime data) => _diaMes.format(data);
