import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class ModelManagerScreen extends StatefulWidget {
  const ModelManagerScreen({super.key});

  @override
  State<ModelManagerScreen> createState() => _ModelManagerScreenState();
}

class _ModelManagerScreenState extends State<ModelManagerScreen> {
  final _nameCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController(text: '100');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create Model Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7B61FF).withOpacity(0.15),
                  const Color(0xFF00D9F5).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF7B61FF).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B61FF), Color(0xFF00D9F5)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_box_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Create New Model',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Padding(
                  padding: EdgeInsets.only(left: 44),
                  child: Text(
                    'A model is a named RAM store with a fixed size.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
                _TextField(
                  ctrl: _nameCtrl,
                  hint: 'Model name (e.g. "cache", "session")',
                  icon: Icons.label_rounded,
                ),
                const SizedBox(height: 12),
                _TextField(
                  ctrl: _sizeCtrl,
                  hint: 'Size in MB (default: 100)',
                  icon: Icons.memory_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading
                        ? null
                        : () => _createModel(provider),
                    icon: provider.isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.rocket_launch_rounded, size: 16),
                    label: Text(
                        provider.isLoading ? 'Creating...' : 'Create Model'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B61FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Models list
          Row(
            children: [
              const Icon(Icons.folder_rounded,
                  color: Color(0xFF00F5A0), size: 16),
              const SizedBox(width: 8),
              const Text(
                'Active Models',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F5A0).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${provider.models.length}',
                  style: const TextStyle(
                      color: Color(0xFF00F5A0),
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (provider.models.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: const [
                    Icon(Icons.folder_open_rounded,
                        color: Colors.white24, size: 48),
                    SizedBox(height: 12),
                    Text('No models created yet',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.models.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final model = provider.models[i];
                final isActive = model == provider.currentModel;
                return _ModelCard(
                  name: model,
                  isActive: isActive,
                  onSelect: () => provider.setCurrentModel(model),
                  onDelete: () => _confirmDelete(context, provider, model),
                );
              },
            ),

          const SizedBox(height: 28),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00D9F5).withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF00D9F5).withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF00D9F5), size: 16),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Models live in the server\'s memory. Restarting the server clears all models. '
                    'Use the Data Explorer tab to browse, insert, and manage records.',
                    style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createModel(AppProvider provider) async {
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model name is required')),
      );
      return;
    }
    final size = int.tryParse(_sizeCtrl.text) ?? 100;
    final result = await provider.createModel(_nameCtrl.text, size);
    if (result == 'ok') {
      _nameCtrl.clear();
      _sizeCtrl.text = '100';
    }
  }

  void _confirmDelete(
      BuildContext context, AppProvider provider, String model) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Remove "$model" from list?',
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        content: const Text(
          'This only removes the model from this app\'s list. The server model continues to run.',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.removeModel(model);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3CAC)),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final String name;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const _ModelCard({
    required this.name,
    required this.isActive,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [
                  const Color(0xFF00F5A0).withOpacity(0.1),
                  const Color(0xFF00D9F5).withOpacity(0.05),
                ],
              )
            : null,
        color: isActive ? null : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? const Color(0xFF00F5A0).withOpacity(0.4)
              : Colors.white.withOpacity(0.08),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF00F5A0).withOpacity(0.15)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.storage_rounded,
                  size: 16,
                  color: isActive
                      ? const Color(0xFF00F5A0)
                      : Colors.white38,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (isActive)
                      const Text(
                        'Active',
                        style: TextStyle(
                            color: Color(0xFF00F5A0), fontSize: 11),
                      ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F5A0).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF00F5A0).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle_rounded,
                          size: 11, color: Color(0xFF00F5A0)),
                      SizedBox(width: 4),
                      Text('Selected',
                          style: TextStyle(
                              color: Color(0xFF00F5A0), fontSize: 11)),
                    ],
                  ),
                )
              else
                TextButton(
                  onPressed: onSelect,
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.white54,
                      textStyle: const TextStyle(fontSize: 12)),
                  child: const Text('Select'),
                ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded,
                    color: Colors.white24, size: 18),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _TextField({
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
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 1.5),
        ),
      ),
    );
  }
}
