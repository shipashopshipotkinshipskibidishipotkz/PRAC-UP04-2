import 'package:flutter/material.dart';

class TableScroll extends StatefulWidget {
  final double minWidth;
  final Widget child;
  const TableScroll({super.key, required this.minWidth, required this.child});
  @override
  State<TableScroll> createState() => _TableScrollState();
}

class _TableScrollState extends State<TableScroll> {
  final _vertical = ScrollController();
  final _horizontal = ScrollController();
  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 560),
    child: Scrollbar(
      controller: _horizontal,
      thumbVisibility: true,
      notificationPredicate:
          (notification) => notification.metrics.axis == Axis.horizontal,
      child: Scrollbar(
        controller: _vertical,
        thumbVisibility: true,
        notificationPredicate:
            (notification) => notification.metrics.axis == Axis.vertical,
        child: SingleChildScrollView(
          controller: _vertical,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: widget.minWidth),
              child: widget.child,
            ),
          ),
        ),
      ),
    ),
  );
}
