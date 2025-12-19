import 'package:flutter/material.dart';
import '../utils/enums.dart';

class PriorityChip extends StatelessWidget {
  const PriorityChip({super.key, required this.priority});

  final Priority priority;

  String get _label {
    switch (priority) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_label),
      visualDensity: VisualDensity.compact,
    );
  }
}
