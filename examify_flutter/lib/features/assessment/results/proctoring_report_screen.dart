import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/providers/proctoring_provider.dart';

// ─────────────────────────────────────────
//  Theme constants (white/violet palette)
// ─────────────────────────────────────────
const _kViolet       = Color(0xFF6E4CF5);
const _kVioletLight  = Color(0xFFEDE8FF);
const _kTextDark     = Color(0xFF24364E);
const _kTextSub      = Color(0xFF8B98AE);
const _kCardBg       = Colors.white;
const _kBorder       = Color(0xFFE1E8F2);
const _kBgPage       = Color(0xFFF4F7FF);

// ─────────────────────────────────────────
//  Status helpers
// ─────────────────────────────────────────
enum _Status { normal, suspicious, cheating }

_Status _statusFor(int n) {
  if (n >= 3) return _Status.cheating;   // Strike 3 and above
  if (n >= 1) return _Status.suspicious; // Strike 1 and 2
  return _Status.normal;                 // No violations
}

Color _statusColor(_Status s) {
  switch (s) {
    case _Status.cheating:   return const Color(0xFFEF4444);
    case _Status.suspicious: return const Color(0xFFF59E0B);
    case _Status.normal:     return const Color(0xFF10B981);
  }
}

String _statusLabel(_Status s) {
  switch (s) {
    case _Status.cheating:   return 'Cheating';
    case _Status.suspicious: return 'Suspicious';
    case _Status.normal:     return 'Normal';
  }
}

IconData _statusIcon(_Status s) {
  switch (s) {
    case _Status.cheating:   return Icons.dangerous_rounded;
    case _Status.suspicious: return Icons.warning_amber_rounded;
    case _Status.normal:     return Icons.check_circle_rounded;
  }
}

// ─────────────────────────────────────────
//  Data models
// ─────────────────────────────────────────
class _GroupedViolation {
  final String eventType, remark, platform;
  final DateTime latestTimestamp;
  final int count;
  const _GroupedViolation({
    required this.eventType,
    required this.remark,
    required this.platform,
    required this.latestTimestamp,
    required this.count,
  });
}

class _StudentReport {
  final String name;
  final int totalViolations;
  final _Status status;
  final List<_GroupedViolation> grouped;
  final List<ProctoringSnapshotEntry> snapshots;
  const _StudentReport({
    required this.name,
    required this.totalViolations,
    required this.status,
    required this.grouped,
    required this.snapshots,
  });
}

// ─────────────────────────────────────────
//  Screen
// ─────────────────────────────────────────
class ProctoringReportScreen extends ConsumerStatefulWidget {
  final String assessmentId;
  const ProctoringReportScreen({super.key, required this.assessmentId});
  @override
  ConsumerState<ProctoringReportScreen> createState() => _ProctoringReportScreenState();
}

class _ProctoringReportScreenState extends ConsumerState<ProctoringReportScreen> {
  Timer? _timer;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        ref.invalidate(proctoringReportProvider(int.parse(widget.assessmentId)));
        setState(() => _lastUpdated = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<_StudentReport> _parse(List<ProctoringReport> raw) {
    return raw.map((r) {
      final Map<String, List<ProctoringLogEntry>> byType = {};
      for (final log in r.logs) {
        byType.putIfAbsent(log.eventType, () => []).add(log);
      }
      final grouped = byType.entries.map((e) {
        final logs = e.value..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return _GroupedViolation(
          eventType: e.key,
          remark: logs.first.remark ?? e.key,
          platform: logs.first.platform,
          latestTimestamp: logs.first.timestamp,
          count: logs.length,
        );
      }).toList()..sort((a, b) => b.count.compareTo(a.count));

      return _StudentReport(
        name: r.student.name,
        totalViolations: r.totalViolations,
        status: _statusFor(r.totalViolations),
        grouped: grouped,
        snapshots: r.snapshots,
      );
    }).toList()..sort((a, b) => b.totalViolations.compareTo(a.totalViolations));
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(proctoringReportProvider(int.parse(widget.assessmentId)));

    reportAsync.whenData((_) => _lastUpdated ??= DateTime.now());

    final updatedText = _lastUpdated != null
        ? 'Updated ${DateFormat('hh:mm:ss a').format(_lastUpdated!)}'
        : 'Loading…';

    return Scaffold(
      backgroundColor: _kBgPage,
      appBar: AppBar(
        backgroundColor: _kViolet,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Proctoring Logs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            Text('Detailed Exam Report',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75), fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/assessment/${widget.assessmentId}/analytics'),
            icon: const Icon(Icons.bar_chart_rounded, size: 18, color: Colors.white),
            label: const Text('Exam Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _kViolet)),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (raw) {
          final reports = _parse(raw);
          final normal     = reports.where((r) => r.status == _Status.normal).length;
          final suspicious = reports.where((r) => r.status == _Status.suspicious).length;
          final cheating   = reports.where((r) => r.status == _Status.cheating).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Live indicator ──────────────────────────────────
                _LiveBar(updatedText: updatedText, onRefresh: () {
                  setState(() => _lastUpdated = DateTime.now());
                  ref.invalidate(proctoringReportProvider(int.parse(widget.assessmentId)));
                }),
                const SizedBox(height: 20),

                // ── Summary stat cards ──────────────────────────────
                Row(children: [
                  _StatCard(label: 'Students',  value: '${reports.length}',  color: _kViolet,                   icon: Icons.people_alt_rounded),
                  const SizedBox(width: 12),
                  _StatCard(label: 'Normal',    value: '$normal',    color: const Color(0xFF10B981), icon: Icons.check_circle_rounded),
                  const SizedBox(width: 12),
                  _StatCard(label: 'Suspicious',value: '$suspicious', color: const Color(0xFFF59E0B), icon: Icons.warning_amber_rounded),
                  const SizedBox(width: 12),
                  _StatCard(label: 'Cheating',  value: '$cheating',  color: const Color(0xFFEF4444), icon: Icons.dangerous_rounded),
                ]),
                const SizedBox(height: 24),

                // ── Section title ────────────────────────────────────
                Row(children: [
                  Container(
                    width: 4, height: 20,
                    decoration: BoxDecoration(color: _kViolet, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 10),
                  const Text('Student Monitoring',
                      style: TextStyle(color: _kTextDark, fontSize: 15, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 10),
                  Text('${reports.length} student${reports.length == 1 ? '' : 's'}',
                      style: const TextStyle(color: _kTextSub, fontSize: 13)),
                ]),
                const SizedBox(height: 14),

                // ── Student tiles ─────────────────────────────────────
                if (reports.isEmpty)
                  _EmptyState()
                else
                  ...reports.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StudentTile(report: r),
                  )),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Live indicator bar
// ─────────────────────────────────────────
class _LiveBar extends StatelessWidget {
  final String updatedText;
  final VoidCallback onRefresh;
  const _LiveBar({required this.updatedText, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        // Pulsing dot
        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
        const SizedBox(width: 8),
        const Text('Live Monitoring', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(width: 6),
        const Text('· updates every 5 s', style: TextStyle(color: _kTextSub, fontSize: 12)),
        const Spacer(),
        Text(updatedText, style: const TextStyle(color: _kTextSub, fontSize: 12)),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onRefresh,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: _kVioletLight, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.refresh_rounded, size: 16, color: _kViolet),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────
//  Stat card
// ─────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color, height: 1)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: _kTextSub, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Student expandable tile
// ─────────────────────────────────────────
class _StudentTile extends StatefulWidget {
  final _StudentReport report;
  const _StudentTile({required this.report});
  @override
  State<_StudentTile> createState() => _StudentTileState();
}

class _StudentTileState extends State<_StudentTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.report.status;
    final sc = _statusColor(s);

    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sc.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        // ── Header row ─────────────────────────────
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              // Left status stripe
              Container(
                width: 4, height: 40,
                decoration: BoxDecoration(color: sc, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 12),
              // Avatar
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_kViolet, const Color(0xFF47A2FF)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    widget.report.name.isNotEmpty ? widget.report.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name + meta
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.report.name,
                    style: const TextStyle(color: _kTextDark, fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text(
                  '${widget.report.totalViolations} violation${widget.report.totalViolations == 1 ? '' : 's'} · ${widget.report.grouped.length} type${widget.report.grouped.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: _kTextSub, fontSize: 12),
                ),
              ])),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sc.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_statusIcon(s), size: 14, color: sc),
                  const SizedBox(width: 5),
                  Text(_statusLabel(s), style: TextStyle(color: sc, fontWeight: FontWeight.w800, fontSize: 12)),
                ]),
              ),
              const SizedBox(width: 8),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: _kTextSub, size: 20),
            ]),
          ),
        ),

        // ── Expanded violations ─────────────────────
        if (_expanded) ...[
          Container(height: 1, color: _kBorder, margin: const EdgeInsets.symmetric(horizontal: 16)),
          
          // ── Snapshots section ─────────────────────
          if (widget.report.snapshots.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      const Icon(Icons.camera_alt_rounded, size: 14, color: _kViolet),
                      const SizedBox(width: 6),
                      const Text('Proctoring Snapshots', 
                          style: TextStyle(color: _kViolet, fontSize: 12, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Text('${widget.report.snapshots.length} images', 
                          style: const TextStyle(color: _kTextSub, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.report.snapshots.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final snap = widget.report.snapshots[index];
                        return Column(
                          children: [
                            Container(
                              width: 140,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _kBorder),
                                image: DecorationImage(
                                  image: NetworkImage(snap.url),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(DateFormat('hh:mm a').format(snap.capturedAt), 
                                style: const TextStyle(color: _kTextSub, fontSize: 10)),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: _kBorder, margin: const EdgeInsets.symmetric(horizontal: 16)),
          ],

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(children: [
              // Header row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: _kVioletLight, borderRadius: BorderRadius.circular(8)),
                child: const Row(children: [
                  _CH('Event',    flex: 2),
                  _CH('Remark',   flex: 4),
                  _CH('Platform', flex: 2),
                  _CH('Count',    flex: 1),
                  _CH('Last Seen',flex: 2),
                ]),
              ),
              const SizedBox(height: 6),
              ...widget.report.grouped.map((g) => _ViolationRow(g: g)),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────
//  Column header helper
// ─────────────────────────────────────────
class _CH extends StatelessWidget {
  final String text;
  final int flex;
  const _CH(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(text,
        style: const TextStyle(color: _kViolet, fontSize: 11, fontWeight: FontWeight.w800)),
  );
}

// ─────────────────────────────────────────
//  Grouped violation row
// ─────────────────────────────────────────
class _ViolationRow extends StatelessWidget {
  final _GroupedViolation g;
  const _ViolationRow({required this.g});

  @override
  Widget build(BuildContext context) {
    final countColor = g.count >= 5 ? const Color(0xFFEF4444)
        : g.count >= 3 ? const Color(0xFFF59E0B)
        : _kTextSub;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Event chip
        Expanded(flex: 2, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
          ),
          child: Text(g.eventType,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
        )),
        // Remark
        Expanded(flex: 4, child: Text(g.remark,
            style: const TextStyle(color: _kTextDark, fontSize: 12))),
        // Platform
        Expanded(flex: 2, child: Text(g.platform,
            style: const TextStyle(color: _kTextSub, fontSize: 12))),
        // Count badge
        Expanded(flex: 1, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: countColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('×${g.count}',
              style: TextStyle(color: countColor, fontWeight: FontWeight.w900, fontSize: 12)),
        )),
        // Last seen
        Expanded(flex: 2, child: Text(
          DateFormat('hh:mm a').format(g.latestTimestamp),
          style: const TextStyle(color: _kTextSub, fontSize: 11),
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────
//  Empty state
// ─────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 16),
          const Text('All Clear', style: TextStyle(color: _kTextDark, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('No violations detected for this exam.', style: TextStyle(color: _kTextSub, fontSize: 14)),
        ]),
      ),
    );
  }
}
