import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/application.dart';
import '../../services/firestore_service.dart';
import '../../utils/enums.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => FirestoreService(),
      child: _AnalyticsBody(uid: uid),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();

    return StreamBuilder<List<Application>>(
      stream: fs.watchApplications(uid),
      builder: (context, snap) {
        final apps = snap.data ?? const [];

        int count(AppStatus s) => apps.where((a) => a.status == s).length;

        final applied = count(AppStatus.applied);
        final oa = count(AppStatus.oa);
        final interview = count(AppStatus.interview);
        final offer = count(AppStatus.offer);
        final rejected = count(AppStatus.rejected);
        final archived = count(AppStatus.archived);

        final activeTotal = applied + oa + interview + offer;
        double rate(int num, int den) => den == 0 ? 0 : (num / den);

        final interviewRate = rate(interview + offer, applied + oa + interview + offer + rejected);
        final offerRate = rate(offer, applied + oa + interview + offer + rejected);

        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MetricCard(
                title: 'Pipeline',
                children: [
                  _row('Applied', applied),
                  _row('OA', oa),
                  _row('Interview', interview),
                  _row('Offer', offer),
                  _row('Rejected', rejected),
                  _row('Archived', archived),
                  const Divider(),
                  _row('Active total', activeTotal),
                ],
              ),
              const SizedBox(height: 12),
              _MetricCard(
                title: 'Conversion',
                children: [
                  _percentRow('Interview rate (rough)', interviewRate),
                  _percentRow('Offer rate (rough)', offerRate),
                ],
              ),
              const SizedBox(height: 12),
              _MetricCard(
                title: 'Quick insights',
                children: [
                  Text(
                    _insightText(applied: applied, oa: oa, interview: interview, offer: offer),
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _row(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('$value'),
        ],
      ),
    );
  }

  static Widget _percentRow(String label, double value) {
    final pct = (value * 100).toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text('$pct%'),
        ],
      ),
    );
  }

  static String _insightText({
    required int applied,
    required int oa,
    required int interview,
    required int offer,
  }) {
    if (offer > 0) {
      return 'You have at least one offer—nice. Keep your follow-ups tight and track deadlines in Today tasks.';
    }
    if (interview > 0) {
      return 'You’re getting interviews. Focus on prep tasks and send thank-you notes within 24 hours.';
    }
    if (oa > 0) {
      return 'OAs are active. Add due dates and prep tasks so nothing slips.';
    }
    if (applied > 0) {
      return 'You’re applying. Set follow-up tasks (7 days) to increase responses.';
    }
    return 'Start by adding applications and creating follow-up tasks.';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
