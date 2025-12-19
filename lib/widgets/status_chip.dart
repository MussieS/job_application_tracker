import 'package:flutter/material.dart';
import '../utils/enums.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final AppStatus status;

  String get _label {
    switch (status) {
      case AppStatus.applied:
        return 'Applied';
      case AppStatus.oa:
        return 'OA';
      case AppStatus.interview:
        return 'Interview';
      case AppStatus.offer:
        return 'Offer';
      case AppStatus.rejected:
        return 'Rejected';
      case AppStatus.archived:
        return 'Archived';
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
