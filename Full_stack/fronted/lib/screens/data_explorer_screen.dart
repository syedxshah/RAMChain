import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/data_table_widget.dart';

class DataExplorerScreen extends StatefulWidget {
  const DataExplorerScreen({super.key});

  @override
  State<DataExplorerScreen> createState() => _DataExplorerScreenState();
}

class _DataExplorerScreenState extends State<DataExplorerScreen> {
  final _keyCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _ttlCtrl = TextEditingController();
  final _fetchKeyCtrl = TextEditingController();
  String? _fetchedData;
  bool _showInsertForm = false;

  @override
  void dispose() {
    _keyCtrl.dispose();
    _valueCtrl.dispose();
    _ttlCtrl.dispose();
    _fetchKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final hasModel = provider.currentModel.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasModel)
            _NoModelBanner()
          else ...[
            // Insert panel
            _InsertPanel(
              expanded: _showInsertForm,
              onToggle: () => setState(() => _showInsertForm = !_showInsertForm),
              keyCtrl: _keyCtrl,
              valueCtrl: _valueCtrl,
              ttlCtrl: _ttlCtrl,
              onInsert: () => _insertData(provider),
            ),

            const SizedBox(height: 16),

            // Fetch panel
            _FetchPanel(
              keyCtrl: _fetchKeyCtrl,
              onFetch: () => _fetchData(provider),
              fetchedData: _fetchedData,
            ),

            const SizedBox(height: 24),

            // Data table
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.table_rows_rounded,
                        color: Color(0xFF7B61FF), size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Data Records',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B61FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${provider.dataEntries.length}',
                        style: const TextStyle(
                            color: Color(0xFF7B61FF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: provider.refresh,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF7B61FF),
                            ),
                          )
                        : const Icon(Icons.refresh_rounded,
                            color: Colors.white54, size: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const DataTableWidget(),
          ],
        ],
      ),
    );
  }

  Future<void> _insertData(AppProvider provider) async {
    if (_keyCtrl.text.isEmpty || _valueCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Key and value are required')),
      );
      return;
    }
    final ttl = int.tryParse(_ttlCtrl.text);
    await provider.insertData(_keyCtrl.text, _valueCtrl.text, ttl);
    _keyCtrl.clear();
    _valueCtrl.clear();
    _ttlCtrl.clear();
    setState(() => _showInsertForm = false);
  }

  Future<void> _fetchData(AppProvider provider) async {
    if (_fetchKeyCtrl.text.isEmpty) return;
    final result = await provider.getData(_fetchKeyCtrl.text);
    setState(() {
      if (result.containsKey('Data')) {
        final d = result['Data'];
        _fetchedData =
            'Key: ${d[0]}\nValue: ${d[1]}\nTTL: ${d[2] ?? '∞'}\nAccess Count: ${d[3]}';
      } else {
        _fetchedData = result['message'] ?? 'Not found';
      }
    });
  }
}

class _InsertPanel extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final TextEditingController keyCtrl;
  final TextEditingController valueCtrl;
  final TextEditingController ttlCtrl;
  final VoidCallback onInsert;

  const _InsertPanel({
    required this.expanded,
    required this.onToggle,
    required this.keyCtrl,
    required this.valueCtrl,
    required this.ttlCtrl,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7B61FF).withOpacity(0.12),
            const Color(0xFFFF3CAC).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7B61FF).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B61FF), Color(0xFFFF3CAC)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Insert New Record',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _InputField(ctrl: keyCtrl, hint: 'Key', icon: Icons.key_rounded),
                  const SizedBox(height: 10),
                  _InputField(
                      ctrl: valueCtrl, hint: 'Value', icon: Icons.data_object_rounded),
                  const SizedBox(height: 10),
                  _InputField(
                    ctrl: ttlCtrl,
                    hint: 'TTL (seconds, optional)',
                    icon: Icons.timer_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onInsert,
                      icon: const Icon(Icons.save_rounded, size: 16),
                      label: const Text('Insert Record'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B61FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FetchPanel extends StatelessWidget {
  final TextEditingController keyCtrl;
  final VoidCallback onFetch;
  final String? fetchedData;

  const _FetchPanel({
    required this.keyCtrl,
    required this.onFetch,
    required this.fetchedData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search_rounded,
                  color: Color(0xFF00D9F5), size: 16),
              const SizedBox(width: 8),
              const Text(
                'Fetch Record by Key',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InputField(
                    ctrl: keyCtrl, hint: 'Enter key...', icon: Icons.key_rounded),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onFetch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9F5).withOpacity(0.2),
                  foregroundColor: const Color(0xFF00D9F5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Fetch'),
              ),
            ],
          ),
          if (fetchedData != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00D9F5).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF00D9F5).withOpacity(0.25)),
              ),
              child: Text(
                fetchedData!,
                style: const TextStyle(
                    color: Color(0xFF00D9F5),
                    fontFamily: 'monospace',
                    fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _InputField({
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white38, size: 16),
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF7B61FF), width: 1.5),
        ),
      ),
    );
  }
}

class _NoModelBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Colors.white24, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No Model Active',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Go to the Models tab to create\nor select a model first.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
