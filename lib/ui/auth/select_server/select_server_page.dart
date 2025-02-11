import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class ConnectServerPage extends StatelessWidget {
  const ConnectServerPage({super.key, this.onServerSelected});

  final void Function()? onServerSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Connect Server"),
        leading: AutoLeadingButton(),
      ),
      body: Text("Select Server Page"),
    );
  }
}
