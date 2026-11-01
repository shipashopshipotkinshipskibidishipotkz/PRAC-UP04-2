import 'package:flutter/material.dart';

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? columns;
  final double spacing;
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.columns,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final count =
          columns ??
          (constraints.maxWidth < 600
              ? 1
              : constraints.maxWidth < 1000
              ? 2
              : 3);
      final width = (constraints.maxWidth - spacing * (count - 1)) / count;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}
