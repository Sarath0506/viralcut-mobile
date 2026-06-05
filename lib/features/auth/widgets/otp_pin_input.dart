import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/token_colors.dart';
import 'auth_ui.dart';

/// Six separate boxes; focus moves forward on digit, back on delete.
class OtpPinInput extends StatefulWidget {
  const OtpPinInput({
    super.key,
    required this.onCompleted,
    this.enabled = true,
  });

  final ValueChanged<String> onCompleted;
  final bool enabled;

  @override
  State<OtpPinInput> createState() => OtpPinInputState();
}

class OtpPinInputState extends State<OtpPinInput> {
  static const _length = 6;
  final _nodes = List.generate(_length, (_) => FocusNode());
  final _controllers = List.generate(_length, (_) => TextEditingController());

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    if (mounted) setState(() {});
    _nodes.first.requestFocus();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _notifyIfComplete() {
    final code = _code;
    if (code.length == _length) {
      widget.onCompleted(code);
    }
  }

  void _onChanged(int index, String value) {
    final digit = value.replaceAll(RegExp(r'\D'), '');
    if (digit.length > 1) {
      _controllers[index].text = digit[digit.length - 1];
      _controllers[index].selection = const TextSelection.collapsed(offset: 1);
    } else {
      _controllers[index].text = digit;
    }

    if (digit.isNotEmpty && index < _length - 1) {
      _nodes[index + 1].requestFocus();
    }
    if (digit.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }

    setState(() {});
    _notifyIfComplete();
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _nodes[index - 1].requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_length, (i) {
        final hasFocus = _nodes[i].hasFocus;
        final filled = _controllers[i].text.isNotEmpty;
        return SizedBox(
          width: 46,
          height: 54,
          child: Focus(
            onKeyEvent: (node, event) => _onKey(i, event),
            child: TextField(
              controller: _controllers[i],
              focusNode: _nodes[i],
              enabled: widget.enabled,
              autofocus: i == 0,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: AuthUi.bodyFont(context).copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: ViralCutTokenColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: filled || hasFocus
                        ? Theme.of(context).colorScheme.primary
                        : ViralCutTokenColors.borderLight,
                    width: hasFocus ? 1.5 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (v) => _onChanged(i, v),
            ),
          ),
        );
      }),
    );
  }
}
