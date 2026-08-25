import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/layout.dart';
import '../theme/tokens.dart';
import '../widgets/brand_mark.dart';
import 'convert_screen.dart';
import 'csv_excel_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'pdf_to_images_screen.dart';
import 'profile_screen.dart';

/// Destinos da navegação principal, na ordem em que aparecem na tab bar e na
/// sidebar. O rótulo depende do idioma ativo, então vem de [label] (que
/// precisa de um [AppLocalizations]) em vez de um campo `const`.
enum AppTab {
  home(LucideIcons.house),
  history(LucideIcons.history),
  profile(LucideIcons.user);

  const AppTab(this.icon);

  final IconData icon;

  String label(AppLocalizations l10n) => switch (this) {
    AppTab.home => l10n.navHome,
    AppTab.history => l10n.navHistory,
    AppTab.profile => l10n.navProfile,
  };
}

/// Casca de navegação do app.
///
/// Abaixo de [kDesktopBreakpoint] usa a tab bar inferior das telas 02/05/06;
/// acima, a sidebar fixa das telas 13–17.
///
/// A aba Início tem um [Navigator] próprio para que Converter e Resultado
/// empilhem dentro dela: no mobile isso esconde a tab bar (como nas telas 03 e
/// 04, que não têm barra) e no desktop mantém a sidebar visível.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _homeNavigatorKey = GlobalKey<NavigatorState>();
  late final _homeObserver = _StackObserver(_syncHomeDepth);

  AppTab _tab = AppTab.home;
  bool _homeCanPop = false;

  void _syncHomeDepth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final canPop = _homeNavigatorKey.currentState?.canPop() ?? false;
      if (canPop != _homeCanPop) setState(() => _homeCanPop = canPop);
    });
  }

  void _select(AppTab tab) {
    // Tocar de novo na aba já ativa volta para a raiz dela.
    if (tab == _tab && tab == AppTab.home) {
      _homeNavigatorKey.currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _tab = tab);
  }

  void _openConverter() {
    _homeNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const ConvertScreen()),
    );
  }

  void _openPdfToImages() {
    _homeNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const PdfToImagesScreen()),
    );
  }

  void _openCsvExcel() {
    _homeNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const CsvExcelScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    // No desktop a sidebar continua visível durante o fluxo de conversão; no
    // mobile as telas 03 e 04 ocupam a tela inteira.
    final showBottomBar = !isDesktop && !(_tab == AppTab.home && _homeCanPop);

    final content = IndexedStack(
      index: _tab.index,
      children: [
        Navigator(
          key: _homeNavigatorKey,
          observers: [_homeObserver],
          onGenerateRoute: (settings) => MaterialPageRoute(
            settings: settings,
            builder: (_) => HomeScreen(
              onOpenConverter: _openConverter,
              onOpenPdfToImages: _openPdfToImages,
              onOpenCsvExcel: _openCsvExcel,
              onOpenProfile: () => _select(AppTab.profile),
            ),
          ),
        ),
        const HistoryScreen(),
        const ProfileScreen(),
      ],
    );

    return PopScope(
      canPop: !_homeCanPop || _tab != AppTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _homeNavigatorKey.currentState?.maybePop();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: isDesktop
              ? Row(
                  children: [
                    _Sidebar(active: _tab, onSelect: _select),
                    Expanded(child: content),
                  ],
                )
              : content,
        ),
        bottomNavigationBar: showBottomBar
            ? _BottomBar(active: _tab, onSelect: _select)
            : null,
      ),
    );
  }
}

/// Avisa o shell sempre que a pilha da aba Início muda de tamanho.
class _StackObserver extends NavigatorObserver {
  _StackObserver(this.onChanged);

  final VoidCallback onChanged;

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) =>
      onChanged();

  @override
  void didPop(Route<Object?> route, Route<Object?>? previousRoute) =>
      onChanged();

  @override
  void didRemove(Route<Object?> route, Route<Object?>? previousRoute) =>
      onChanged();

  @override
  void didReplace({Route<Object?>? newRoute, Route<Object?>? oldRoute}) =>
      onChanged();
}

/// Tab bar inferior das telas mobile.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.active, required this.onSelect});

  final AppTab active;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final tab in AppTab.values)
                _BottomBarItem(
                  tab: tab,
                  isActive: tab == active,
                  onTap: () => onSelect(tab),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final AppTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = isActive ? c.accentStrong : c.neutral500;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        hoverColor: c.text.withValues(alpha: 0.04),
        splashColor: c.text.withValues(alpha: 0.06),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tab.icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              tab.label(AppLocalizations.of(context)!),
              style: AppText.navLabel.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sidebar fixa do layout desktop: marca no topo, navegação abaixo.
class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.active, required this.onSelect});

  final AppTab active;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      width: kSidebarWidth,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: c.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(alignment: Alignment.centerLeft, child: BrandLockup()),
          const SizedBox(height: 36),
          for (final tab in AppTab.values) ...[
            if (tab != AppTab.values.first) const SizedBox(height: 4),
            _SidebarItem(
              tab: tab,
              isActive: tab == active,
              onTap: () => onSelect(tab),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final AppTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = isActive ? c.accentStrong : c.neutral700;

    return Material(
      color: isActive ? c.accentTint : Colors.transparent,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        hoverColor: c.text.withValues(alpha: 0.04),
        splashColor: c.text.withValues(alpha: 0.06),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(tab.icon, size: 18, color: color),
              const SizedBox(width: 12),
              Text(
                tab.label(AppLocalizations.of(context)!),
                style: AppText.body.copyWith(
                  color: color,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
