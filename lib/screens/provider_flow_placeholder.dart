import 'package:flutter/material.dart';

class ProviderFlowPlaceholderScreen extends StatelessWidget {
  const ProviderFlowPlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title\n\nThis destination is wired in the shell and is implemented in the next task.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
