import 'package:flutter/material.dart';

/// Right-rail "resources" pane shown on desktop only.
///
/// This is where curated links, community resources, and (eventually,
/// in a deliberate v2) affiliate-friendly recommendations live. For v1
/// it's a placeholder so the 2/5/3 column split renders.
///
/// Not shown on mobile by design — auxiliary content should never fight
/// for the limited mobile width.
class ResourcesPane extends StatelessWidget {
  const ResourcesPane({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF9FAFB),
      child: Center(child: Text('Resources')),
    );
  }
}
