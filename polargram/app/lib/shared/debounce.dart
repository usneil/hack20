class Debouncer {
  Debouncer({this.milliseconds});

  int lastRun = 0;

  final int milliseconds;

  void run(Function() action) {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (lastRun == null || (now - lastRun) > milliseconds) {
      lastRun = now;

      action();
    }
  }
}
