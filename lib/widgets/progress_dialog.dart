import 'dart:async';

import 'package:flutter/material.dart';

class ProgressDialog {
  Completer<void> _routeOpenCompleter = Completer();
  Completer<void> _routeCloseCompleter = Completer();

  final BuildContext _context;

  ProgressDialog({required BuildContext context}) :
    _context = context;

  Future<void> open() async {
    DialogRoute route = DialogRoute(
      context: _context,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator())
      ),
      barrierDismissible: false
    );
    NavigatorState state = Navigator.of(_context);
    state.push(route);
    await _routeOpenCompleter.future;
    state.removeRoute(route);

    _routeCloseCompleter.complete();
    _routeCloseCompleter = Completer();
  }

  Future<void> close() async {
    _routeOpenCompleter.complete();
    _routeOpenCompleter = Completer();

    await _routeCloseCompleter.future;
  }
}
