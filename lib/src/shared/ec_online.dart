import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';

class EcOnline extends StatefulWidget {
  const EcOnline({super.key, required this.child});

  final Widget child;

  @override
  _EcOnlineState createState() => _EcOnlineState();
}

class _EcOnlineState extends State<EcOnline> {
  @override
  Widget build(BuildContext context) => OfflineBuilder(
        connectivityBuilder: (
          BuildContext context,
          ConnectivityResult connectivity,
          Widget child,
        ) {
          final bool connected = connectivity != ConnectivityResult.none;
          if (connected) {
            return widget.child;
          } else {
            return Container();
          }
        },
        child: const Text('oi'),
      );
}

class EcOffline extends StatefulWidget {
  const EcOffline({super.key, required this.child});

  final Widget child;

  @override
  _EcOfflineState createState() => _EcOfflineState();
}

class _EcOfflineState extends State<EcOffline> {
  @override
  Widget build(BuildContext context) => OfflineBuilder(
        connectivityBuilder: (
          BuildContext context,
          ConnectivityResult connectivity,
          Widget child,
        ) {
          final bool connected = connectivity != ConnectivityResult.none;
          if (!connected) {
            return widget.child;
          } else {
            return Container();
          }
        },
        child: const Text('oi'),
      );
}
