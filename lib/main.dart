import 'package:flutter/material.dart';

void main() {
  runApp(const CrossonicApp());
}

class CrossonicApp extends StatelessWidget {
  const CrossonicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Crossonic',
      debugShowCheckedModeBanner: true,
      home: Scaffold(body: Center(child: Text("Crossonic"))),
    );
  }
}
