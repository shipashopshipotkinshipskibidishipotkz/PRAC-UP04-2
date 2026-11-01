import 'package:flutter/material.dart';
import '../models/entity_kind.dart';
import 'workspace_scaffold.dart';

class AppScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;
  const AppScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => WorkspaceScaffold(
    location: EntityKind.values[selectedIndex].path,
    child: child,
  );
}
