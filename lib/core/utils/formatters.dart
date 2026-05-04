import 'package:flutter/services.dart';

class StudentIdFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    // Remove all non-digit characters
    text = text.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to 10 digits (4 + 1 + 2 + 3)
    if (text.length > 10) {
      text = text.substring(0, 10);
    }

    var newString = '';
    for (var i = 0; i < text.length; i++) {
      newString += text[i];
      if (i == 3 || i == 4 || i == 6) {
        if (i != text.length - 1) {
          newString += '-';
        }
      }
    }

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
