import 'package:flutter/material.dart';
import 'package:paperwise_pdf_maker/core/theme/app_tokens.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/screens/files_screen.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/screens/home_screen.dart';
import 'package:paperwise_pdf_maker/features/library/presentation/screens/tools_screen.dart';
import 'package:paperwise_pdf_maker/features/scan/presentation/screens/scan_screen.dart';
import 'package:paperwise_pdf_maker/features/settings/presentation/screens/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  Future<void> _openScan() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: const [
            HomeScreen(embedded: true),
            ToolsScreen(),
            FilesScreen(),
            SettingsScreen(embedded: true),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index >= 2 ? _index + 1 : _index,
        onDestinationSelected: (value) {
          if (value == 2) {
            _openScan();
            return;
          }
          setState(() => _index = value > 2 ? value - 1 : value);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Tools',
          ),
          NavigationDestination(
            icon: Container(
              width: AppTokens.navScanSize,
              height: AppTokens.navScanSize,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.document_scanner_outlined,
                color: scheme.onPrimary,
              ),
            ),
            label: 'Scan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Files',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
