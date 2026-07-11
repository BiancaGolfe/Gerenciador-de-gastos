import 'package:flutter/material.dart';

final categoriasNotifier = ValueNotifier<int>(0);
final gastosNotifier = ValueNotifier<int>(0);

final mesSelecionado = ValueNotifier<DateTime>(
	DateTime(DateTime.now().year, DateTime.now().month, 1),
);
