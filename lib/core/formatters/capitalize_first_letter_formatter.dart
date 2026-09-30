import 'package:flutter/services.dart';

class CapitalizeFirstLetterFormatter extends TextInputFormatter {
  const CapitalizeFirstLetterFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    final firstLetterIndex = text.indexOf(RegExp('[A-Za-z]'));
    if (firstLetterIndex == -1) {
      return newValue;
    }

    final firstLetter = text[firstLetterIndex];
    final capitalizedLetter = firstLetter.toUpperCase();
    if (firstLetter == capitalizedLetter) {
      return newValue;
    }

    final updatedText =
        text.substring(0, firstLetterIndex) +
        capitalizedLetter +
        text.substring(firstLetterIndex + 1);

    return newValue.copyWith(
      text: updatedText,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
