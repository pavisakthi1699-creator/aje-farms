import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityScope extends StatefulWidget {
  const ConnectivityScope({
    required this.child,
    super.key,
  });

  final Widget child;

  static ConnectivityScopeState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_ConnectivityInherited>();
    assert(scope != null, 'ConnectivityScope was not found in the tree.');
    return scope!.notifier;
  }

  static ConnectivityScopeState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_ConnectivityInherited>()
        ?.notifier;
  }

  @override
  State<ConnectivityScope> createState() => ConnectivityScopeState();
}

class ConnectivityScopeState extends State<ConnectivityScope> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      await _syncStatus();
      _subscription = _connectivity.onConnectivityChanged.listen((_) {
        unawaited(_syncStatus());
      });
    } catch (_) {
      isOnline = true;
    }
  }

  Future<void> _syncStatus() async {
    final results = await _connectivity.checkConnectivity();
    final online = results.any((result) => result != ConnectivityResult.none);
    if (!mounted || online == isOnline) return;
    setState(() => isOnline = online);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ConnectivityInherited(
      notifier: this,
      isOnline: isOnline,
      child: widget.child,
    );
  }
}

class _ConnectivityInherited extends InheritedWidget {
  const _ConnectivityInherited({
    required this.notifier,
    required this.isOnline,
    required super.child,
  });

  final ConnectivityScopeState notifier;
  final bool isOnline;

  @override
  bool updateShouldNotify(_ConnectivityInherited oldWidget) =>
      isOnline != oldWidget.isOnline;
}

extension ConnectivityContext on BuildContext {
  bool get isDeviceOnline => ConnectivityScope.maybeOf(this)?.isOnline ?? true;
}
