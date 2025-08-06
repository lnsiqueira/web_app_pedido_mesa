import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

class ConexaoWrapper extends StatefulWidget {
  final Widget child;
  const ConexaoWrapper({super.key, required this.child});

  @override
  State<ConexaoWrapper> createState() => _ConexaoWrapperState();
}

class _ConexaoWrapperState extends State<ConexaoWrapper> {
  bool? isOnline = html.window.navigator.onLine;

  @override
  void initState() {
    super.initState();
    html.window.onOnline.listen((event) => setState(() => isOnline = true));
    html.window.onOffline.listen((event) => setState(() => isOnline = false));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!isOnline!)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.wifi_off, color: Colors.white, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Sem conexão com a internet',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
