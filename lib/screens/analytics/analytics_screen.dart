import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/application.dart';
import '../../services/firestore_service.dart';
import '../../utils/enums.dart';
import '../../theme/chart_colors.dart';

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
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }

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
        final totalNonArchived = applied + oa + interview + offer + rejected;
        final interviewRate = rate(interview + offer, totalNonArchived);
        final offerRate = rate(offer, totalNonArchived);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeaderCard(
              title: 'Analytics',
              subtitle: 'A quick snapshot of your pipeline and momentum.',
              icon: Icons.insights_outlined,
            ),
            const SizedBox(height: 12),

            _MetricCard(
              title: 'Pipeline Summary',
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
              title: 'Pipeline Breakdown',
              children: [
                SizedBox(
                  height: 230,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 46,
                      sections: _pieSections(
                        applied: applied,
                        oa: oa,
                        interview: interview,
                        offer: offer,
                        rejected: rejected,
                        archived: archived,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 10,
                  children: [
                    _legend('Applied', applied, ChartColors.applied),
                    _legend('OA', oa, ChartColors.oa),
                    _legend('Interview', interview, ChartColors.interview),
                    _legend('Offer', offer, ChartColors.offer),
                    _legend('Rejected', rejected, ChartColors.rejected),
                    _legend('Archived', archived, ChartColors.archived),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            _MetricCard(
              title: 'Progress Bars',
              children: [
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const labels = ['A', 'OA', 'I', 'O', 'R'];
                              final idx = value.toInt();
                              if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(labels[idx]),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        _bar(0, applied, ChartColors.applied),
                        _bar(1, oa, ChartColors.oa),
                        _bar(2, interview, ChartColors.interview),
                        _bar(3, offer, ChartColors.offer),
                        _bar(4, rejected, ChartColors.rejected),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A=Applied, I=Interview, O=Offer, R=Rejected',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
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
              title: 'Quick insight',
              children: [
                Text(
                  _insightText(applied: applied, oa: oa, interview: interview, offer: offer),
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<PieChartSectionData> _pieSections({
    required int applied,
    required int oa,
    required int interview,
    required int offer,
    required int rejected,
    required int archived,
  }) {
    final items = <_PieItem>[
      _PieItem('Applied', applied, ChartColors.applied),
      _PieItem('OA', oa, ChartColors.oa),
      _PieItem('Interview', interview, ChartColors.interview),
      _PieItem('Offer', offer, ChartColors.offer),
      _PieItem('Rejected', rejected, ChartColors.rejected),
      _PieItem('Archived', archived, ChartColors.archived),
    ];

    return items
        .where((e) => e.value > 0)
        .map((e) => PieChartSectionData(
      value: e.value.toDouble(),
      title: '${e.value}',
      radius: 62,
      color: e.color,
      titleStyle: const TextStyle(
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
    ))
        .toList();
  }

  static Widget _row(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
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
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          Text('$pct%'),
        ],
      ),
    );
  }

  static Widget _legend(String label, int value, Color color) {
    if (value == 0) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label: $value'),
      ],
    );
  }

  static BarChartGroupData _bar(int x, int y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y.toDouble(),
          width: 18,
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  static String _insightText({
    required int applied,
    required int oa,
    required int interview,
    required int offer,
  }) {
    if (offer > 0) return 'You have an offer in the pipeline. Track deadlines and prep your decision.';
    if (interview > 0) return 'Interviews are active. Add prep + thank-you tasks so you stay sharp.';
    if (oa > 0) return 'OAs are active. Put due dates on them and set reminders.';
    if (applied > 0) return 'You’re applying. Use follow-ups (7 days) to increase replies.';
    return 'Add applications and set follow-up tasks to build momentum.';
  }
}

class _PieItem {
  _PieItem(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Theme.of(context).hintColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}
