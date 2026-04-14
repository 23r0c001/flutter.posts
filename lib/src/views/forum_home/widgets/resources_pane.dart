import 'package:flutter/material.dart';

class ResourcesPane extends StatelessWidget {
  const ResourcesPane({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF9FAFB),
      child: Center(
        child: Text('Resources'),
      ),
    );
  }
}
