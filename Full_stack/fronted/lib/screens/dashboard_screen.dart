import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/ram_model.dart';
import '../widgets/ram_circle_gauge.dart';
import '../widgets/ram_chart_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  ChartType _chartType = ChartType.bar;
  late AnimationController _staggerCtrl;

  @override
  void initState() {
    super.initState();
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _staggerCtrl.forward();
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final stats = provider.ramStats;
    final hasModel = provider.currentModel.isNotEmpty;

    return RefreshIndicator(
      color: const Color(0xFF7B61FF),
      backgroundColor: const Color(0xFF1A1A2E),
      onRefresh: provider.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner
            if (provider.statusMessage.isNotEmpty)
              _StatusBanner(
                message: provider.statusMessage,
                isError: provider.statusIsError,
                onDismiss: provider.clearStatus,
              ),

            if (!hasModel)
              _NoModelPlaceholder()
            else if (stats == null && provider.isLoading)
              _LoadingPlaceholder()
            else if (stats == null)
              _ErrorPlaceholder(onRetry: provider.refresh)
            else ...[
              // ── Stat cards ─────────────────────────────────────────
              _StatsRow(stats: stats, stagger: _staggerCtrl),
              const SizedBox(height: 20),

              // ── Gauge + Chart ───────────────────────────────────────
              LayoutBuilder(builder: (ctx, constraints) {
                final wide = constraints.maxWidth > 580;
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: _GaugeCard(stats: stats),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _ChartCard(
                              stats: stats,
                              chartType: _chartType,
                              onTypeChanged: (t) =>
                                  setState(() => _chartType = t),
                            ),
                          ),
                        ],
                      )
                    : Column(children: [
                        _GaugeCard(stats: stats),
                        const SizedBox(height: 16),
                        _ChartCard(
                          stats: stats,
                          chartType: _chartType,
                          onTypeChanged: (t) =>
                              setState(() => _chartType = t),
                        ),
                      ]);
              }),

              const SizedBox(height: 16),

              // ── Quick stats ──────────────────────────────────────────
              _QuickStatsCard(
                  stats: stats, entryCount: provider.dataEntries.length),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Stat cards row ───────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final RamStats stats;
  final AnimationController stagger;

  const _StatsRow({required this.stats, required this.stagger});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCardData(
        label: 'Total RAM',
        value: '${stats.totalRam.toStringAsFixed(2)} MB',
        subValue: 'Allocated',
        icon: Icons.memory_rounded,
        c1: const Color(0xFF7B61FF),
        c2: const Color(0xFF4FC3F7),
        delay: 0.0,
        progress: 1.0,
      ),
      _StatCardData(
        label: 'Used',
        value: '${stats.usedRam.toStringAsFixed(6)} MB',
        subValue: '${(stats.usedPercent * 100).toStringAsFixed(2)}%',
        icon: Icons.storage_rounded,
        c1: const Color(0xFFFF6B35),
        c2: const Color(0xFFFF3CAC),
        delay: 0.15,
        progress: stats.usedPercent.clamp(0.0, 1.0),
      ),
      _StatCardData(
        label: 'Remaining',
        value: '${stats.remainingRam.toStringAsFixed(2)} MB',
        subValue: '${(stats.remainingPercent * 100).toStringAsFixed(1)}% free',
        icon: Icons.check_circle_outline_rounded,
        c1: const Color(0xFF00F5A0),
        c2: const Color(0xFF00D9F5),
        delay: 0.30,
        progress: stats.remainingPercent.clamp(0.0, 1.0),
      ),
    ];

    return Row(
      children: cards
          .map((d) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: d == cards.last ? 0 : 10),
                  child: _AnimatedStatCard(data: d, ctrl: stagger),
                ),
              ))
          .toList(),
    );
  }
}

class _StatCardData {
  final String label;
  final String value;
  final String subValue;
  final IconData icon;
  final Color c1;
  final Color c2;
  final double delay;
  final double progress;

  const _StatCardData({
    required this.label,
    required this.value,
    required this.subValue,
    required this.icon,
    required this.c1,
    required this.c2,
    required this.delay,
    required this.progress,
  });
}

class _AnimatedStatCard extends StatelessWidget {
  final _StatCardData data;
  final AnimationController ctrl;

  const _AnimatedStatCard({required this.data, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, child) {
        final t = ((ctrl.value - data.delay) / (1.0 - data.delay)).clamp(0.0, 1.0);
        final curve = Curves.easeOutCubic.transform(t);
        return Opacity(
          opacity: curve,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - curve)),
            child: child,
          ),
        );
      },
      child: _StatCard(data: data),
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatCardData d;

  const _StatCard({required _StatCardData data}) : d = data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            d.c1.withValues(alpha: 0.18),
            d.c2.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: d.c1.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: d.c1.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon with glow
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [d.c1, d.c2]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: d.c1.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(d.icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 12),
          Text(
            d.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            d.label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: d.progress,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor: AlwaysStoppedAnimation(d.c1),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            d.subValue,
            style: TextStyle(color: d.c1, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Gauge card ───────────────────────────────────────────────────────────────

class _GaugeCard extends StatelessWidget {
  final RamStats stats;
  const _GaugeCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          _CardTitle(icon: Icons.donut_large_rounded, title: 'RAM Gauge',
              accent: const Color(0xFF7B61FF)),
          const SizedBox(height: 20),
          Center(child: RamCircleGauge(stats: stats)),
          const SizedBox(height: 16),
          // Two legend pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GaugePill(
                color: const Color(0xFFFF3CAC),
                label: 'Used',
                value: '${(stats.usedPercent * 100).toStringAsFixed(2)}%',
              ),
              const SizedBox(width: 12),
              _GaugePill(
                color: const Color(0xFF00F5A0),
                label: 'Free',
                value: '${(stats.remainingPercent * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePill extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _GaugePill(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 6)
                  ])),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9, letterSpacing: 0.5)),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Chart card ───────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final RamStats stats;
  final ChartType chartType;
  final ValueChanged<ChartType> onTypeChanged;

  const _ChartCard({
    required this.stats,
    required this.chartType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
              icon: Icons.analytics_rounded,
              title: 'RAM Analytics',
              accent: const Color(0xFFFF3CAC)),
          const SizedBox(height: 20),
          RamChartWidget(
            stats: stats,
            chartType: chartType,
            onChartTypeChanged: onTypeChanged,
          ),
        ],
      ),
    );
  }
}

// ── Quick stats card ─────────────────────────────────────────────────────────

class _QuickStatsCard extends StatelessWidget {
  final RamStats stats;
  final int entryCount;

  const _QuickStatsCard({required this.stats, required this.entryCount});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
              icon: Icons.speed_rounded,
              title: 'Quick Stats',
              accent: const Color(0xFF00D9F5)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _QuickStat(
                      icon: Icons.compress_rounded,
                      label: 'Usage',
                      value:
                          '${(stats.usedPercent * 100).toStringAsFixed(3)}%',
                      accent: const Color(0xFFFF3CAC))),
              _Divider(),
              Expanded(
                  child: _QuickStat(
                      icon: Icons.open_in_full_rounded,
                      label: 'Free',
                      value:
                          '${(stats.remainingPercent * 100).toStringAsFixed(1)}%',
                      accent: const Color(0xFF00F5A0))),
              _Divider(),
              Expanded(
                  child: _QuickStat(
                      icon: Icons.list_rounded,
                      label: 'Records',
                      value: '$entryCount',
                      accent: const Color(0xFF7B61FF))),
              _Divider(),
              Expanded(
                  child: _QuickStat(
                      icon: Icons.memory_rounded,
                      label: 'Alloc.',
                      value:
                          '${stats.totalRam.toStringAsFixed(0)} MB',
                      accent: const Color(0xFF00D9F5))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 40, color: Colors.white.withValues(alpha: 0.06));
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
              color: accent, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}

// ── Shared components ─────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accent;

  const _CardTitle(
      {required this.icon, required this.title, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: accent),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ── Placeholders ──────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _StatusBanner(
      {required this.message, required this.isError, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final color =
        isError ? const Color(0xFFFF3CAC) : const Color(0xFF00F5A0);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: color,
              size: 16),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: TextStyle(color: color, fontSize: 13))),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close_rounded,
                color: color.withValues(alpha: 0.6), size: 16),
          ),
        ],
      ),
    );
  }
}

class _NoModelPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B61FF), Color(0xFFFF3CAC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B61FF).withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.memory_rounded,
                  color: Colors.white, size: 48),
            ),
            const SizedBox(height: 28),
            const Text(
              'No Model Selected',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 10),
            Text(
              'Go to the Models tab to create\nor select a model to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35), fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Color(0xFF7B61FF)),
              strokeWidth: 2,
            ),
            SizedBox(height: 20),
            Text('Loading stats...',
                style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorPlaceholder({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            const Text('Could not connect',
                style: TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Check your server URL and try again',
                style: TextStyle(color: Colors.white30, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
