import 'package:flutter/material.dart';

/// Mobile drawer for community navigation/actions.
class MobileCommunityDrawer extends StatelessWidget {
  const MobileCommunityDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final double drawerWidth = MediaQuery.sizeOf(context).width * 0.85;

    return Drawer(
      width: drawerWidth,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: const [
            _StartCommunityRow(),
            Divider(height: 1),
            _ExpandableSection(title: 'Recently Visited'),
            Divider(height: 1),
            _ExpandableSection(title: 'Your Communities'),
          ],
        ),
      ),
    );
  }
}

class _StartCommunityRow extends StatelessWidget {
  const _StartCommunityRow();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.add),
      title: const Text('Start a Community'),
      onTap: () {},
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;

  const _ExpandableSection({required this.title});

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(widget.title),
          trailing: Icon(
            _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
          ),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(''),
            ),
          ),
      ],
    );
  }
}
