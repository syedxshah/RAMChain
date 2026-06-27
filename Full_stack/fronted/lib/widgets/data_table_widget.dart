import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/ram_model.dart';

class DataTableWidget extends StatefulWidget {
  const DataTableWidget({super.key});

  @override
  State<DataTableWidget> createState() => _DataTableWidgetState();
}

class _DataTableWidgetState extends State<DataTableWidget> {
  String _search = '';
  String _sortBy = 'key';
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final entries = _filterAndSort(provider.dataEntries);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search and sort bar
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search keys...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.07),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _SortChip(
              label: 'Key',
              active: _sortBy == 'key',
              ascending: _ascending,
              onTap: () => setState(() {
                if (_sortBy == 'key') {
                  _ascending = !_ascending;
                } else { _sortBy = 'key'; _ascending = true; }
              }),
            ),
            const SizedBox(width: 6),
            _SortChip(
              label: 'Access',
              active: _sortBy == 'access',
              ascending: _ascending,
              onTap: () => setState(() {
                if (_sortBy == 'access') {
                  _ascending = !_ascending;
                } else { _sortBy = 'access'; _ascending = false; }
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Header
        _TableHeader(),
        const SizedBox(height: 6),

        // Rows
        if (entries.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.inbox_rounded, color: Colors.white24, size: 48),
                  const SizedBox(height: 12),
                  const Text('No data in this model',
                      style: TextStyle(color: Colors.white38, fontSize: 14)),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, i) =>
                _DataRow(entry: entries[i], index: i),
          ),
      ],
    );
  }

  List<DataEntry> _filterAndSort(List<DataEntry> entries) {
    var list = entries.where((e) =>
        _search.isEmpty ||
        e.key.toLowerCase().contains(_search.toLowerCase()) ||
        e.value.toLowerCase().contains(_search.toLowerCase())).toList();

    if (_sortBy == 'key') {
      list.sort((a, b) =>
          _ascending ? a.key.compareTo(b.key) : b.key.compareTo(a.key));
    } else {
      list.sort((a, b) => _ascending
          ? a.accessCount.compareTo(b.accessCount)
          : b.accessCount.compareTo(a.accessCount));
    }
    return list;
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('KEY',
                style: TextStyle(
                    color: Colors.white38, fontSize: 11, letterSpacing: 1.5)),
          ),
          Expanded(
            flex: 4,
            child: Text('VALUE',
                style: TextStyle(
                    color: Colors.white38, fontSize: 11, letterSpacing: 1.5)),
          ),
          Expanded(
            flex: 2,
            child: Text('TTL',
                style: TextStyle(
                    color: Colors.white38, fontSize: 11, letterSpacing: 1.5)),
          ),
          Expanded(
            flex: 2,
            child: Text('ACCESS',
                style: TextStyle(
                    color: Colors.white38, fontSize: 11, letterSpacing: 1.5)),
          ),
          SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _DataRow extends StatefulWidget {
  final DataEntry entry;
  final int index;

  const _DataRow({required this.entry, required this.index});

  @override
  State<_DataRow> createState() => _DataRowState();
}

class _DataRowState extends State<_DataRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final accent = _accentColor(widget.index);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(_expanded ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _expanded ? accent.withOpacity(0.4) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.entry.key,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      widget.entry.value,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      widget.entry.ttl != null
                          ? '${widget.entry.ttl}s'
                          : '∞',
                      style: TextStyle(
                          color: widget.entry.ttl != null
                              ? const Color(0xFFFFB347)
                              : Colors.white38,
                          fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.entry.accessCount}x',
                        style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: Colors.white38,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _ActionBtn(
                    icon: Icons.edit_rounded,
                    label: 'Update',
                    color: const Color(0xFF7B61FF),
                    onTap: () => _showUpdateDialog(context, provider),
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    icon: Icons.delete_rounded,
                    label: 'Delete',
                    color: const Color(0xFFFF3CAC),
                    onTap: () => _deleteEntry(context, provider),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _accentColor(int index) {
    const colors = [
      Color(0xFFFF3CAC),
      Color(0xFF00F5A0),
      Color(0xFF7B61FF),
      Color(0xFF00D9F5),
      Color(0xFFFF6B35),
      Color(0xFFFFD700),
    ];
    return colors[index % colors.length];
  }

  void _showUpdateDialog(BuildContext context, AppProvider provider) {
    final ctrl = TextEditingController(text: widget.entry.value);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Update "${widget.entry.key}"',
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'New value',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.updateData(widget.entry.key, ctrl.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B61FF),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteEntry(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Delete "${widget.entry.key}"?',
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteData(widget.entry.key);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3CAC),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool ascending;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.active,
    required this.ascending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF7B61FF).withOpacity(0.2)
              : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? const Color(0xFF7B61FF).withOpacity(0.6)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(
                    color: active ? const Color(0xFF7B61FF) : Colors.white54,
                    fontSize: 11)),
            if (active) ...[
              const SizedBox(width: 4),
              Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 10,
                color: const Color(0xFF7B61FF),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
