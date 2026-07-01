import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerField extends StatefulWidget {
  final String? selectedColor; // em formato hex (sem #)
  final ValueChanged<String?> onColorChanged;
  final String hint;

  const ColorPickerField({
    super.key,
    this.selectedColor,
    required this.onColorChanged,
    required this.hint,
  });

  @override
  State<ColorPickerField> createState() => _ColorPickerFieldState();
}

class _ColorPickerFieldState extends State<ColorPickerField> {
  late TextEditingController _colorController;

  static const List<String> predefinedColors = [
    'FF0000', // Vermelho
    '00FF00', // Verde
    '0000FF', // Azul
    'FFFF00', // Amarelo
    'FF00FF', // Magenta
    '00FFFF', // Ciano
    'FFA500', // Laranja
    'FF1493', // Rosa
    '9370DB', // Roxo
    '4169E1', // Azul Real
    '20B2AA', // Verde Escuro
    'FF6347', // Tomate
  ];

  @override
  void initState() {
    super.initState();
    _colorController = TextEditingController(text: widget.selectedColor ?? '');
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  String _colorToHex(Color color) {
    return color.value
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2)
        .toUpperCase();
  }

  Future<void> _openColorPicker() async {
    Color tempColor = _hexToColor(_colorController.text);
    final selected = await showDialog<Color?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecionar cor'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (value) {
                tempColor = value;
              },
              enableAlpha: false,
              displayThumbColor: true,
              pickerAreaHeightPercent: 0.8,
              labelTypes: const [],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(tempColor),
              child: const Text('Selecionar'),
            ),
          ],
        );
      },
    );

    if (selected != null) {
      final hex = _colorToHex(selected);
      setState(() {
        _colorController.text = hex;
      });
      widget.onColorChanged(hex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _hexToColor(_colorController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _colorController,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.35)),
                  filled: true,
                  fillColor: cs.onSurface.withOpacity(0.06),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  prefix: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 4),
                    child: Text('#',
                        style: TextStyle(color: cs.onSurface.withOpacity(0.5))),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                  widget.onColorChanged(value.isEmpty ? null : value);
                },
                maxLength: 6,
                buildCounter: (_,
                        {required currentLength,
                        required isFocused,
                        maxLength}) =>
                    const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: cs.surface,
              borderRadius: BorderRadius.circular(10),
              child: IconButton(
                icon: Icon(Icons.palette_outlined,
                    color: cs.onSurface.withOpacity(0.8)),
                onPressed: _openColorPicker,
                tooltip: 'Selecionar cor',
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: const EdgeInsets.all(8),
              ),
            ),
            const SizedBox(width: 8),
            // Preview da cor
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.onSurface.withOpacity(0.2)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Cores predefinidas:',
          style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.5)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: predefinedColors.map((colorHex) {
            final isSelected = _colorController.text.toUpperCase() == colorHex;
            final cor = _hexToColor(colorHex);
            return GestureDetector(
              onTap: () {
                setState(() => _colorController.text = colorHex);
                widget.onColorChanged(colorHex);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? cs.primary : Colors.transparent,
                    width: isSelected ? 3 : 0,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
