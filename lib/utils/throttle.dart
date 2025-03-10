import 'dart:async';

class Throttle {
  final void Function() action;
  final Duration delay;
  final bool leading;
  final bool trailing;

  bool _isThrottling = false;
  bool _shouldInvoke = false;

  Timer? timer;

  Throttle({
    required this.action,
    required this.delay,
    this.leading = true,
    this.trailing = true,
  });

  void call() {
    if (!_isThrottling) {
      if (leading) {
        _isThrottling = true;
        action();
        timer = Timer(delay, () {
          _isThrottling = false;
          timer = null;
          if (trailing && _shouldInvoke) {
            action();
            _shouldInvoke = false;
          }
        });
      } else if (trailing) {
        _isThrottling = true;
        _shouldInvoke = true;
        timer = Timer(delay, () {
          _isThrottling = false;
          timer = null;
          if (_shouldInvoke) {
            action();
            _shouldInvoke = false;
          }
        });
      }
    } else if (trailing) {
      _shouldInvoke = true;
    }
  }

  void cancel() {
    timer?.cancel();
  }
}
