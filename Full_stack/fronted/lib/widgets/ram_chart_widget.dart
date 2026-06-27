import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/ram_model.dart';

enum ChartType { bar, pie, line }

class RamChartWidget extends StatefulWidget {
  final RamStats stats;
  final ChartType chartType;
  final ValueChanged<ChartType> onChartTypeChanged;

  const RamChartWidget({
    super.key,
    required this.stats,
    required this.chartType,
    required this.onChartTypeChanged,
  });

  @override
  State<RamChartWidget> createState() => _RamChartWidgetState();
}

class _RamChartWidgetState extends State<RamChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(RamChartWidget old) {
    super.didUpdateWidget(old);
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart type selector
        _ChartSelector(
          current: widget.chartType,
          onChange: widget.onChartTypeChanged,
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, _) => SizedBox(
            height: 200,
            child: widget.chartType == ChartType.bar
                ? _buildBar()
                : widget.chartType == ChartType.pie
                    ? _buildPie()
                    : _buildLine(),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  Widget _buildBar() {
    final used = widget.stats.usedRam * _anim.value;
    final rem = widget.stats.remainingRam * _anim.value;
    final total = widget.stats.totalRam; // always = remaining + used (correct)
    // maxY must be at least the largest bar value with 10% headroom
    final maxY = (total * 1.1).clamp(0.0001, double.infinity);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1A1A35),
            getTooltipItem: (group, gi, rod, ri) {
              const labels = ['Used', 'Remaining', 'Total'];
              return BarTooltipItem(
                '${labels[gi]}\n${rod.toY.toStringAsFixed(6)} MB',
                const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                const labels = ['Used', 'Remaining', 'Total'];
                final i = val.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(labels[i],
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          letterSpacing: 0.5)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (val, meta) {
                if (val == meta.max) return const SizedBox();
                return Text(
                  _formatMB(val),
                  style:
                      const TextStyle(color: Colors.white30, fontSize: 9),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeBar(0, used, const Color(0xFFFF6B35), const Color(0xFFFF3CAC)),
          _makeBar(1, rem, const Color(0xFF00F5A0), const Color(0xFF00D9F5)),
          _makeBar(2, total, const Color(0xFF7B61FF), const Color(0xFF4FC3F7)),
        ],
      ),
    );
  }

  String _formatMB(double val) {
    if (val < 0.001) return '${(val * 1000000).toStringAsFixed(0)}µ';
    if (val < 1) return val.toStringAsFixed(3);
    return val.toStringAsFixed(1);
  }

  BarChartGroupData _makeBar(int x, double val, Color c1, Color c2) =>
      BarChartGroupData(
        x: x,
        barRods: [
          BarChartRodData(
            toY: val < 0 ? 0 : val,
            gradient: LinearGradient(
              colors: [c1, c2],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 28,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(10)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: widget.stats.totalRam * 1.1,
              color: Colors.white.withValues(alpha: 0.03),
            ),
          ),
        ],
      );

  Widget _buildPie() {
    final used = widget.stats.usedRam;
    final rem = widget.stats.remainingRam;
    final safeTotal = (used + rem) > 0 ? (used + rem) : 1.0;
    final usedPct = used / safeTotal * 100;
    final remPct = rem / safeTotal * 100;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 4,
              centerSpaceRadius: 55,
              sections: [
                PieChartSectionData(
                  value: usedPct * _anim.value,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF3CAC)],
                  ),
                  title: usedPct < 1
                      ? '< 1%'
                      : '${(usedPct * _anim.value).toStringAsFixed(1)}%',
                  titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                  radius: 65,
                ),
                PieChartSectionData(
                  value: remPct * _anim.value,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)],
                  ),
                  title: '${(remPct * _anim.value).toStringAsFixed(1)}%',
                  titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                  radius: 65,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PieInfo(
                label: 'Used',
                value: '${used.toStringAsFixed(6)} MB',
                pct: usedPct,
                c1: const Color(0xFFFF6B35),
                c2: const Color(0xFFFF3CAC),
              ),
              const SizedBox(height: 16),
              _PieInfo(
                label: 'Free',
                value: '${rem.toStringAsFixed(2)} MB',
                pct: remPct,
                c1: const Color(0xFF00F5A0),
                c2: const Color(0xFF00D9F5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLine() {
    final used = widget.stats.usedRam;
    final rem = widget.stats.remainingRam;
    final total = widget.stats.totalRam;
    final maxY = (total * 1.15).clamp(0.001, double.infinity);

    return LineChart(
      LineChartData(
        maxY: maxY,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
            dashArray: [4, 6],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (val, _) {
                const labels = ['Used', 'Remaining', 'Total'];
                final i = val.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(labels[i],
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (val, meta) {
                if (val == meta.max) return const SizedBox();
                return Text(
                  _formatMB(val),
                  style:
                      const TextStyle(color: Colors.white30, fontSize: 9),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              FlSpot(0, used * _anim.value),
              FlSpot(1, rem * _anim.value),
              FlSpot(2, total),
            ],
            isCurved: true,
            curveSmoothness: 0.4,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF3CAC), Color(0xFF7B61FF), Color(0xFF00D9F5)],
            ),
            barWidth: 3,
            shadow: const Shadow(
              color: Color(0xFFFF3CAC),
              blurRadius: 8,
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 6,
                color: [
                  const Color(0xFFFF3CAC),
                  const Color(0xFF7B61FF),
                  const Color(0xFF00D9F5),
                ][idx],
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF3CAC).withValues(alpha: 0.25),
                  const Color(0xFF7B61FF).withValues(alpha: 0.1),
                  const Color(0xFF00D9F5).withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(
            c1: const Color(0xFFFF6B35),
            c2: const Color(0xFFFF3CAC),
            label: 'Used'),
        const SizedBox(width: 20),
        _LegendDot(
            c1: const Color(0xFF00F5A0),
            c2: const Color(0xFF00D9F5),
            label: 'Remaining'),
        const SizedBox(width: 20),
        _LegendDot(
            c1: const Color(0xFF7B61FF),
            c2: const Color(0xFF4FC3F7),
            label: 'Total'),
      ],
    );
  }
}

// ── Chart Selector ────────────────────────────────────────────────────────────

class _ChartSelector extends StatelessWidget {
  final ChartType current;
  final ValueChanged<ChartType> onChange;

  const _ChartSelector({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(
            icon: Icons.bar_chart_rounded,
            label: 'Bar',
            active: current == ChartType.bar,
            onTap: () => onChange(ChartType.bar),
          ),
          _Tab(
            icon: Icons.donut_large_rounded,
            label: 'Pie',
            active: current == ChartType.pie,
            onTap: () => onChange(ChartType.pie),
          ),
          _Tab(
            icon: Icons.show_chart_rounded,
            label: 'Line',
            active: current == ChartType.line,
            onTap: () => onChange(ChartType.line),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Tab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFF7B61FF), Color(0xFFFF3CAC)],
                )
              : null,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFF7B61FF).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active ? Colors.white : Colors.white38),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white38,
                fontSize: 12,
                fontWeight:
                    active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pie chart info ────────────────────────────────────────────────────────────

class _PieInfo extends StatelessWidget {
  final String label;
  final String value;
  final double pct;
  final Color c1;
  final Color c2;

  const _PieInfo({
    required this.label,
    required this.value,
    required this.pct,
    required this.c1,
    required this.c2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c1, c2], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            Text(value, style: TextStyle(color: c2, fontSize: 12, fontWeight: FontWeight.bold)),
            Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white30, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

// ── Legend ────────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color c1;
  final Color c2;
  final String label;

  const _LegendDot({required this.c1, required this.c2, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c1, c2]),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: c1.withValues(alpha: 0.5), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
