import 'package:flutter/material.dart';

class ConfirmationDialog {
  final BuildContext _context;
  final String confirmationText;

  ConfirmationDialog({required this.confirmationText, required BuildContext context}) :
    _context = context;

  Future<bool?> open() async {
    return showDialog<bool>(
      context: _context,
      builder: (context) => AlertDialog(
        title: const Text('Внимание'),
        content: Text(confirmationText),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Нет')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Да'))
        ]
      )
    );
  }
}
