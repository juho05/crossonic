import 'dart:async';
import 'dart:collection';

import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/result.dart';

typedef SequentialRequestFn<T> = Future<T> Function();
typedef SequentialRequestAllDoneFn = Future<void> Function();
typedef SequentialRequestErrorFn = Future<void> Function(Exception e,
    [StackTrace? st]);

class _SequentialRequest {
  final Future<void> Function() fn;
  final SequentialRequestErrorFn errFn;

  _SequentialRequest({required this.fn, required this.errFn});
}

class SequentialRequestQueue {
  final Queue<_SequentialRequest> _queue;

  final SequentialRequestAllDoneFn? _allDoneFn;

  bool get isEmpty => _queue.isEmpty;
  bool get isNotEmpty => !isEmpty;

  bool get done => !_loopRunning && _queue.isEmpty;

  SequentialRequestQueue({
    SequentialRequestAllDoneFn? onAllDone,
  })  : _queue = DoubleLinkedQueue(),
        _allDoneFn = onAllDone;

  Future<Result<T>> run<T>(SequentialRequestFn<Result<T>> request,
      {SequentialRequestErrorFn? restorePrevState}) {
    final completer = Completer<Result<T>>();
    _queue.add(_SequentialRequest(
      fn: () async {
        final value = await request();
        completer.complete(value);
      },
      errFn: (e, [st]) async {
        if (restorePrevState != null) {
          try {
            await restorePrevState(e, st);
          } catch (e, st) {
            Log.error("Failed to execute sequential queue run onError callback",
                e: e, st: st);
          }
        }
        completer.complete(Result.error(e));
      },
    ));
    _runLoop();
    return completer.future;
  }

  bool _running = false;
  bool _loopRunning = false;
  Future<void> _runLoop() async {
    if (_running) return;
    _running = true;
    _loopRunning = true;
    while (_queue.isNotEmpty) {
      final req = _queue.removeFirst();
      try {
        await req.fn();
      } on Exception catch (e, st) {
        while (_queue.isNotEmpty) {
          final r = _queue.removeLast();
          try {
            await r.errFn(const CanceledException());
          } catch (e, st) {
            Log.error("Failed to execute sequential queue error callback",
                e: e, st: st);
          }
        }
        try {
          await req.errFn(e, st);
        } catch (e, st) {
          Log.error("Failed to execute sequential queue error callback",
              e: e, st: st);
        }
      }
    }
    _loopRunning = false;
    if (_allDoneFn != null) {
      try {
        await _allDoneFn();
      } catch (e, st) {
        Log.error("Failed to execute sequential queue all done callback",
            e: e, st: st);
      }
    }
    _running = false;
    if (_queue.isNotEmpty) {
      _runLoop();
    }
  }
}
