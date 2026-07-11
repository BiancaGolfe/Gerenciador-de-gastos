import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class EmojiPickerField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final InputDecoration Function(BuildContext, String) inputDecoration;

  const EmojiPickerField({
    super.key,
    required this.controller,
    required this.hint,
    required this.inputDecoration,
  });

  @override
  State<EmojiPickerField> createState() => _EmojiPickerFieldState();
}

class _EmojiPickerFieldState extends State<EmojiPickerField> {
  bool _showEmojiPicker = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                decoration:
                    widget.inputDecoration(context, widget.hint).copyWith(
                          suffixIcon: _showEmojiPicker
                              ? null
                              : Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: IconButton(
                                    icon: Icon(Icons.emoji_emotions_outlined,
                                        color: cs.primary),
                                    tooltip: 'Escolher emoji',
                                    onPressed: () {
                                      _focusNode.unfocus();
                                      setState(() =>
                                          _showEmojiPicker = !_showEmojiPicker);
                                    },
                                  ),
                                ),
                        ),
                maxLength: 2,
                buildCounter: (_,
                        {required currentLength,
                        required isFocused,
                        maxLength}) =>
                    const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        
        if (_showEmojiPicker)
          Container(
            height: 250,
            color: cs.surface,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                widget.controller.text = emoji.emoji;
                setState(() => _showEmojiPicker = false);
              },
              onBackspacePressed: () {
                widget.controller.clear();
              },
              config: Config(
                height: 250,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  emojiSizeMax: 32 * (1.0),
                  gridPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  backgroundColor: cs.surface,
                  buttonMode: ButtonMode.CUPERTINO,
                ),
                skinToneConfig: SkinToneConfig(
                  enabled: true,
                  dialogBackgroundColor: cs.surface,
                  indicatorColor: cs.primary,
                ),
                categoryViewConfig: CategoryViewConfig(
                  iconColorSelected: cs.primary,
                  indicatorColor: cs.primary,
                  backgroundColor: cs.surface,
                  backspaceColor: cs.primary,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  enabled: false,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: cs.surface,
                  buttonIconColor: cs.primary,
                ),
              ),
            ),
          ),
        if (_showEmojiPicker)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _showEmojiPicker = false),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
