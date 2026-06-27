import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/data_explorer_screen.dart';
import 'screens/model_manager_screen.dart';

import 'package:bitsdojo_window/bitsdojo_window.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const RamChainApp(),
    ),
  );

  doWhenWindowReady(() {
    const initialSize = Size(1000, 700);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.title = 'RAMChain';
    appWindow.show();
  });
}

class RamChainApp extends StatelessWidget {
  const RamChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAMChain',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7B61FF),
          secondary: Color(0xFF00F5A0),
          surface: Color(0xFF0D0D1A),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1A1A2E),
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const AppRouter(),
    );
  }
}

/// Routes: Splash → MainShell
class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _splashDone
          ? const MainShell(key: ValueKey('main'))
          : SplashScreen(
              key: const ValueKey('splash'),
              onComplete: () => setState(() => _splashDone = true),
            ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
  final _urlCtrl = TextEditingController();
  bool _urlEditing = false;
  late AnimationController _navAnim;

  final List<_NavItem> _navItems = const [
    _NavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    _NavItem(
      icon: Icons.table_rows_outlined,
      activeIcon: Icons.table_rows_rounded,
      label: 'Explorer',
    ),
    _NavItem(
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder_rounded,
      label: 'Models',
    ),
  ];

  final List<Widget> _screens = const [
    DashboardScreen(),
    DataExplorerScreen(),
    ModelManagerScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _navAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _navAnim.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _urlCtrl.text = context.read<AppProvider>().baseUrl;
    });
  }

  @override
  void dispose() {
    _navAnim.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _switchTab(int i) {
    if (i == _tab) return;
    _navAnim.forward(from: 0);
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              provider: provider,
              urlCtrl: _urlCtrl,
              urlEditing: _urlEditing,
              onUrlTap: () => setState(() => _urlEditing = true),
              onUrlSubmit: (url) {
                provider.setBaseUrl(url);
                setState(() => _urlEditing = false);
              },
              onUrlCancel: () {
                _urlCtrl.text = provider.baseUrl;
                setState(() => _urlEditing = false);
              },
            ),
            // Page content
            Expanded(
              child: AnimatedBuilder(
                animation: _navAnim,
                builder: (_, child) => FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _navAnim,
                    curve: Curves.easeOut,
                  ),
                  child: child,
                ),
                child: IndexedStack(index: _tab, children: _screens),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        items: _navItems,
        selectedIndex: _tab,
        onTap: _switchTab,
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

final _buttonColors = WindowButtonColors(
  iconNormal: Colors.white,
  mouseOver: const Color(0xFF7B61FF).withValues(alpha: 0.2),
  mouseDown: const Color(0xFF7B61FF).withValues(alpha: 0.4),
  iconMouseOver: Colors.white,
  iconMouseDown: Colors.white,
);

final _closeButtonColors = WindowButtonColors(
  mouseOver: const Color(0xFFD32F2F),
  mouseDown: const Color(0xFFB71C1C),
  iconNormal: Colors.white,
  iconMouseOver: Colors.white,
);

class _TopBar extends StatelessWidget {
  final AppProvider provider;
  final TextEditingController urlCtrl;
  final bool urlEditing;
  final VoidCallback onUrlTap;
  final ValueChanged<String> onUrlSubmit;
  final VoidCallback onUrlCancel;

  const _TopBar({
    required this.provider,
    required this.urlCtrl,
    required this.urlEditing,
    required this.onUrlTap,
    required this.onUrlSubmit,
    required this.onUrlCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        children: [
          // ── Brand + controls row ──
          SizedBox(
            height: 42,
            child: Row(
              children: [
                Expanded(
                  child: MoveWindow(
                    child: Row(
                      children: [
                        // Logo (Custom Glass Circle)
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                            color: const Color(
                              0xFF2A2A4A,
                            ).withValues(alpha: 0.3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF7B61FF,
                                ).withValues(alpha: 0.15),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Soft glow behind the icon
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              // Glass reflection at top left
                              Positioned(
                                top: 2,
                                left: 6,
                                child: Container(
                                  width: 16,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.4),
                                        Colors.white.withValues(alpha: 0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              // Center Icon
                              const Icon(
                                Icons.memory_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'RAMChain',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (provider.currentModel.isNotEmpty)
                              Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00F5A0),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    provider.currentModel,
                                    style: const TextStyle(
                                      color: Color(0xFF00F5A0),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                'No model selected',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                // Refresh
                if (provider.currentModel.isNotEmpty)
                  _IconBtn(
                    onTap: provider.isLoading ? null : provider.refresh,
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF7B61FF),
                            ),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white54,
                            size: 16,
                          ),
                  ),
                // Model dropdown
                if (provider.models.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _ModelDropdown(
                    models: provider.models,
                    current: provider.currentModel,
                    onChanged: provider.setCurrentModel,
                  ),
                ],
                const SizedBox(width: 12),
                // Window Buttons
                Row(
                  children: [
                    MinimizeWindowButton(colors: _buttonColors),
                    MaximizeWindowButton(colors: _buttonColors),
                    CloseWindowButton(colors: _closeButtonColors),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── URL bar ──
          _UrlBar(
            ctrl: urlCtrl,
            editing: urlEditing,
            onTap: onUrlTap,
            onSubmit: onUrlSubmit,
            onCancel: onUrlCancel,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _IconBtn({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: child,
      ),
    );
  }
}

// ── URL bar ───────────────────────────────────────────────────────────────────

class _UrlBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool editing;
  final VoidCallback onTap;
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;

  const _UrlBar({
    required this.ctrl,
    required this.editing,
    required this.onTap,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: editing
            ? const Color(0xFF7B61FF).withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: editing
              ? const Color(0xFF7B61FF).withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.08),
          width: editing ? 1.5 : 1,
        ),
        boxShadow: editing
            ? [
                BoxShadow(
                  color: const Color(0xFF7B61FF).withValues(alpha: 0.2),
                  blurRadius: 16,
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.link_rounded,
              size: 14,
              color: editing
                  ? const Color(0xFF7B61FF)
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              onTap: onTap,
              onSubmitted: onSubmit,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'http://localhost:8000',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          if (editing) ...[
            GestureDetector(
              onTap: () => onSubmit(ctrl.text),
              child: Container(
                margin: const EdgeInsets.all(5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B61FF), Color(0xFFFF3CAC)],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B61FF).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: onCancel,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                'BASE URL',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Model dropdown ────────────────────────────────────────────────────────────

class _ModelDropdown extends StatelessWidget {
  final List<String> models;
  final String current;
  final ValueChanged<String> onChanged;

  const _ModelDropdown({
    required this.models,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF00F5A0).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF00F5A0).withValues(alpha: 0.25),
        ),
      ),
      child: DropdownButton<String>(
        value: current.isEmpty ? null : current,
        hint: Text(
          'Select',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
          ),
        ),
        underline: const SizedBox(),
        isDense: true,
        dropdownColor: const Color(0xFF1A1A30),
        borderRadius: BorderRadius.circular(12),
        style: const TextStyle(
          color: Color(0xFF00F5A0),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        icon: const Icon(
          Icons.expand_more_rounded,
          color: Color(0xFF00F5A0),
          size: 16,
        ),
        items: models
            .map(
              (m) => DropdownMenuItem(
                value: m,
                child: Text(
                  m,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

// ── Bottom navigation ─────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _BottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 4,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with pill indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? const LinearGradient(
                                colors: [Color(0xFF7B61FF), Color(0xFFFF3CAC)],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF7B61FF,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        selected ? item.activeIcon : item.icon,
                        size: 20,
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF7B61FF)
                            : Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
