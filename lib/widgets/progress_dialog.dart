part of u_app_utils;

class ProgressDialog {
  Completer<void> _dialogCompleter = Completer();

  final BuildContext _context;

  ProgressDialog({required BuildContext context}) :
    _context = context;

  Future<void> open() async {
    DialogRoute route = DialogRoute(
      context: _context,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(child: CircularProgressIndicator())
      ),
      barrierDismissible: false
    );
    NavigatorState state = Navigator.of(_context);
    state.push(route);
    await _dialogCompleter.future;
    state.removeRoute(route);
  }

  void close() {
    _dialogCompleter.complete();
    _dialogCompleter = Completer();
  }
}
