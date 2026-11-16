import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:hydropinn_flutter_web/core/constants/app_colors.dart';
import 'package:hydropinn_flutter_web/features/hydro_dashboard/presentation/widgets/custom_painters.dart';
import 'package:hydropinn_flutter_web/features/hydro_dashboard/presentation/state_management/hydro_controller.dart';

class HydroAppShell extends StatefulWidget {
  final HydroController ctrl;
  const HydroAppShell({super.key, required this.ctrl});

  @override
  State<HydroAppShell> createState() => _HydroAppShellState();
}

class _HydroAppShellState extends State<HydroAppShell> {
  final FocusNode _keyFocus = FocusNode();

  HydroController get ctrl => widget.ctrl;
  HydroColors get c => ctrl.colors;

  @override
  void dispose() {
    _keyFocus.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (isCtrl && key == LogicalKeyboardKey.keyK) {
      setState(() => ctrl.cmdOpen = !ctrl.cmdOpen);
      return;
    }
    if (key == LogicalKeyboardKey.escape) {
      setState(() {
        ctrl.cmdOpen = false;
        ctrl.savedOpen = false;
        ctrl.tourStep = null;
      });
      return;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      ctrl.setFrame((ctrl.frameIdx - 1).clamp(0, 5));
    } else if (key == LogicalKeyboardKey.arrowRight) {
      ctrl.setFrame((ctrl.frameIdx + 1).clamp(0, 5));
    } else if (key == LogicalKeyboardKey.space && ctrl.route == 'explore') {
      ctrl.togglePlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        final isRtl = ctrl.lang == 'ar';
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: KeyboardListener(
            focusNode: _keyFocus,
            autofocus: true,
            onKeyEvent: _handleKey,
            child: Scaffold(
              backgroundColor: c.bg,
              body: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 980;
                      return Row(
                        children: [
                          if (isWide)
                            SizedBox(
                              width: 268.w,
                              child: _buildSidebar(isMobileDrawer: false),
                            ),
                          Expanded(
                            child: Column(
                              children: [
                                _buildTopbar(isWide: isWide),
                                _buildQuickScenarioBar(),
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.all(20.r),
                                    child: _buildCurrentView(),
                                  ),
                                ),
                                _buildFooter(),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (ctrl.cmdOpen) _buildCommandPaletteOverlay(),
                  if (ctrl.savedOpen) _buildSavedScenariosDrawer(),
                  if (ctrl.tourStep != null) _buildGuidedTourOverlay(),
                  if (ctrl.toastMessage != null) _buildToastBanner(),
                ],
              ),
              drawer: MediaQuery.of(context).size.width < 980
                  ? Drawer(
                      backgroundColor: c.panel,
                      child: _buildSidebar(isMobileDrawer: true),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebar({required bool isMobileDrawer}) {
    final navItems = [
      ('overview', Icons.dashboard_rounded, ctrl.t('nav.overview')),
      ('explore', Icons.grid_on_rounded, ctrl.t('nav.explore')),
      ('compare', Icons.compare_arrows_rounded, ctrl.t('nav.compare')),
      ('risk', Icons.shield_outlined, ctrl.t('nav.risk')),
      ('accuracy', Icons.verified_outlined, ctrl.t('nav.accuracy')),
      ('data', Icons.table_chart_outlined, ctrl.t('nav.data')),
    ];

    return Container(
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(
          left:
              ctrl.lang == 'ar' ? BorderSide(color: c.stroke) : BorderSide.none,
          right:
              ctrl.lang == 'en' ? BorderSide(color: c.stroke) : BorderSide.none,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Brand block
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [c.accent, c.accent2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.water_drop_rounded,
                      color: Color(0xFF041019), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ctrl.t('brand.name'),
                        style: TextStyle(
                          color: c.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        ctrl.t('brand.sub'),
                        style: TextStyle(color: c.faint, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: c.accent2.withOpacity(0.12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: c.accent2.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: c.accent2, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      ctrl.t('model.online'),
                      style: TextStyle(
                          color: c.accent2,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              ctrl.t('nav.main'),
              style: TextStyle(
                  color: c.faint, fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...navItems.map((item) {
              final isActive = ctrl.route == item.$1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    ctrl.setRoute(item.$1);
                    if (isMobileDrawer) Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? c.accent.withOpacity(0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            ? c.accent.withOpacity(0.45)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(item.$2,
                            size: 18, color: isActive ? c.accent : c.muted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.$3,
                            style: TextStyle(
                              color: isActive ? c.text : c.muted,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Text(
              ctrl.t('nav.Shortcuts'),
              style: TextStyle(
                  color: c.faint, fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                ctrl.savedOpen = true;
                ctrl.notifyListeners();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.bookmark_border_rounded,
                        size: 18, color: c.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ctrl.t('nav.saved'),
                        style: TextStyle(color: c.muted, fontSize: 12.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.panel2,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${ctrl.savedScenarios.length}',
                        style: TextStyle(
                            color: c.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                ctrl.tourStep = 0;
                ctrl.notifyListeners();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.explore_outlined, size: 18, color: c.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ctrl.t('nav.tour'),
                        style: TextStyle(color: c.muted, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            // Aquifer meta card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.panel2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.stroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ctrl.t('meta.aquifer'),
                    style: TextStyle(
                        color: c.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _metaRow(ctrl.t('meta.grid'), '50×50 · 1 km²'),
                  _metaRow(ctrl.t('meta.horizon'), ctrl.t('meta.30days')),
                  _metaRow(ctrl.t('meta.well'), '(201.7, -98.3) m'),
                  _metaRow(ctrl.t('meta.speedup'), '238× vs MODFLOW',
                      highlight: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(String k, String v, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(color: c.faint, fontSize: 11)),
          Text(
            v,
            style: TextStyle(
              color: highlight ? c.accent2 : c.text2,
              fontSize: 11,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              fontFamily: 'JetBrains Mono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopbar({required bool isWide}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(bottom: BorderSide(color: c.stroke)),
      ),
      child: Row(
        children: [
          if (!isWide)
            Builder(
              builder: (ctx) => IconButton(
                icon: Icon(Icons.menu_rounded, color: c.text),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          Text(
            ctrl.t('crumb.system'),
            style: TextStyle(color: c.faint, fontSize: 12),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('/', style: TextStyle(color: c.faint)),
          ),
          Text(
            ctrl.t('nav.${ctrl.route}'),
            style: TextStyle(
                color: c.text, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          // Command Palette Trigger
          InkWell(
            onTap: () {
              ctrl.cmdOpen = true;
              ctrl.notifyListeners();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: c.panel2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.stroke),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 15, color: c.muted),
                  const SizedBox(width: 8),
                  Text(
                    ctrl.t('cmd.searchPlaceholder'),
                    style: TextStyle(color: c.muted, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.panel3,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Ctrl+K',
                      style: TextStyle(
                          color: c.faint,
                          fontSize: 10,
                          fontFamily: 'JetBrains Mono'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Theme',
            onPressed: ctrl.toggleTheme,
            icon: Icon(
              ctrl.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: c.text2,
              size: 19,
            ),
          ),
          TextButton(
            onPressed: ctrl.toggleLang,
            child: Text(
              ctrl.lang == 'ar' ? 'EN' : 'عربي',
              style: TextStyle(
                  color: c.accent, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickScenarioBar() {
    final s = ctrl.currentScenario;
    final pctSign = s.pct > 0
        ? '+${s.pct.toStringAsFixed(1)}%'
        : '${s.pct.toStringAsFixed(1)}%';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: c.bg2,
        border: Border(bottom: BorderSide(color: c.stroke)),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Scenario Selector
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${ctrl.t('qbar.rate')}: ',
                style: TextStyle(
                    color: c.muted, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              DropdownButtonHideUnderline(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.panel2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.strokeStrong),
                  ),
                  child: DropdownButton<int>(
                    value: ctrl.scenarioIdx,
                    dropdownColor: c.panel2,
                    isDense: true,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'JetBrains Mono',
                    ),
                    items: List.generate(ctrl.data.scenarios.length, (i) {
                      final sc = ctrl.data.scenarios[i];
                      final p = sc.pct > 0 ? '+${sc.pct}%' : '${sc.pct}%';
                      return DropdownMenuItem(
                        value: i,
                        child: Text('${sc.q.toInt()} m³/d ($p)'),
                      );
                    }),
                    onChanged: (v) {
                      if (v != null) ctrl.setScenario(v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: s.pct == 0
                      ? c.accent.withOpacity(0.15)
                      : (s.pct > 0
                          ? c.danger.withOpacity(0.15)
                          : c.good.withOpacity(0.15)),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  s.pct == 0
                      ? (ctrl.lang == 'ar' ? 'خط الأساس' : 'Baseline')
                      : pctSign,
                  style: TextStyle(
                    color:
                        s.pct == 0 ? c.accent : (s.pct > 0 ? c.danger : c.good),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          // Frame Time Pills
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${ctrl.t('qbar.day')}: ',
                style: TextStyle(
                    color: c.muted, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              ...List.generate(ctrl.data.meta.frameTimes.length, (fi) {
                final day = ctrl.data.meta.frameTimes[fi];
                final active = ctrl.frameIdx == fi;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => ctrl.setFrame(fi),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: active ? c.accent : c.panel2,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: active ? c.accent : c.stroke),
                      ),
                      child: Text(
                        '${day == day.roundToDouble() ? day.toInt() : day}d',
                        style: TextStyle(
                          color: active ? const Color(0xFF041019) : c.text2,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          // Save Scenario Button
          OutlinedButton.icon(
            onPressed: () => ctrl.saveCurrentScenario(),
            style: OutlinedButton.styleFrom(
              foregroundColor: c.accent,
              side: BorderSide(color: c.accent.withOpacity(0.45)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.bookmark_add_outlined, size: 16),
            label: Text(ctrl.t('qbar.saveScenario'),
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (ctrl.route) {
      case 'explore':
        return _buildExploreView();
      case 'compare':
        return _buildCompareView();
      case 'risk':
        return _buildRiskView();
      case 'accuracy':
        return _buildAccuracyView();
      case 'data':
        return _buildDataView();
      case 'overview':
      default:
        return _buildOverviewView();
    }
  }

  // ===========================================================================
  // VIEW 1: OVERVIEW
  // ===========================================================================
  Widget _buildOverviewView() {
    final s = ctrl.currentScenario;
    final fi = ctrl.frameIdx;
    final ti = [0, 3, 7, 12, 22, 32][fi];
    final wellHead = s.well[ti];
    final maxDD = s.maxDrawdown[ti];
    final aff = s.affected[fi];
    final rScore = ctrl.computeRiskScore(ctrl.scenarioIdx, ti);
    final rInfo = ctrl.riskLevelInfo(rScore);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero Banner
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.panel2, c.panel],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.strokeStrong),
          ),
          child: Wrap(
            spacing: 24,
            runSpacing: 20,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ctrl.t('ov.eyebrow'),
                      style: TextStyle(
                        color: c.accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ctrl.t('ov.title'),
                      style: TextStyle(
                        color: c.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ctrl.t('ov.desc'),
                      style: TextStyle(
                          color: c.muted, fontSize: 13.5, height: 1.55),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => ctrl.setRoute('explore'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.accent,
                            foregroundColor: const Color(0xFF041019),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          icon: const Icon(Icons.grid_on_rounded, size: 17),
                          label: Text(
                            ctrl.t('ov.ctaExplore'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => ctrl.setRoute('risk'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.text,
                            side: BorderSide(color: c.strokeStrong),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          icon: const Icon(Icons.shield_outlined, size: 17),
                          label: Text(ctrl.t('ov.ctaDecision')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Hero 3 stat cards
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _heroMetricBox(ctrl.t('ov.m1Label'), '90.0 m',
                      ctrl.t('ov.m1Sub'), c.accent),
                  _heroMetricBox(ctrl.t('ov.m2Label'), '110 ms',
                      ctrl.t('ov.m2Sub'), c.accent2),
                  _heroMetricBox(ctrl.t('ov.m3Label'), '0.978',
                      ctrl.t('ov.m3Sub'), c.violet),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // 4 KPI Cards
        LayoutBuilder(
          builder: (context, box) {
            final cols = box.maxWidth > 900 ? 4 : (box.maxWidth > 550 ? 2 : 1);
            final w = (box.maxWidth - (cols - 1) * 14) / cols;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: w,
                  child: _kpiCard(
                    title: ctrl.t('ov.kpiHead'),
                    value: '${wellHead.toStringAsFixed(2)} m',
                    sub: 'h₀ = 90.0m · Δ = -${maxDD.toStringAsFixed(2)}m',
                    color: c.accent,
                    icon: Icons.water_rounded,
                  ),
                ),
                SizedBox(
                  width: w,
                  child: _kpiCard(
                    title: ctrl.t('ov.kpiDrawdown'),
                    value: '${maxDD.toStringAsFixed(2)} m',
                    sub: 'Q = ${s.q.toInt()} m³/day',
                    color: c.warn,
                    icon: Icons.trending_down_rounded,
                  ),
                ),
                SizedBox(
                  width: w,
                  child: _kpiCard(
                    title: ctrl.t('ov.kpiAffected'),
                    value: '${aff.toStringAsFixed(1)}%',
                    sub: ctrl.t('ov.kpiAffectedUnit'),
                    color: c.violet,
                    icon: Icons.radar_rounded,
                  ),
                ),
                SizedBox(
                  width: w,
                  child: _kpiCard(
                    title: ctrl.t('ov.kpiRisk'),
                    value: '$rScore / 100',
                    sub: rInfo.label,
                    color: rInfo.color,
                    icon: Icons.shield_rounded,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        // Row of 3 Main Cards: Heatmap + Hydrograph + Risk Summary
        LayoutBuilder(
          builder: (context, box) {
            final isDesktop = box.maxWidth > 960;
            final cardW = isDesktop ? (box.maxWidth - 28) / 3 : box.maxWidth;
            final grid = ctrl.headGrid(ctrl.scenarioIdx, fi);
            final st = s.frameStats[fi];
            final baseS = ctrl.data.scenarios[4];

            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                // 1. Mini Heatmap Card
                SizedBox(
                  width: cardW,
                  child: _panelCard(
                    tag: ctrl.t('ov.mapTag'),
                    title: ctrl.t('ov.mapTitle'),
                    trailing: TextButton(
                      onPressed: () => ctrl.setRoute('explore'),
                      child: Text(ctrl.t('ov.openFullMap'),
                          style: TextStyle(color: c.accent, fontSize: 12)),
                    ),
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1.25,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CustomPaint(
                              painter: HydroHeatmapPainter(
                                grid: grid,
                                minVal: st.min,
                                maxVal: st.max,
                                rampName: 'head',
                                showContours: true,
                                showCrosshair: false,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _colorbarRow('head', '${st.min.toStringAsFixed(1)} m',
                            '${st.max.toStringAsFixed(1)} m'),
                      ],
                    ),
                  ),
                ),
                // 2. Well Hydrograph Card
                SizedBox(
                  width: cardW,
                  child: _panelCard(
                    tag: ctrl.t('ov.hydroTag'),
                    title: ctrl.t('ov.hydroTitle'),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 230,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: HydroLineChartPainter(
                              colors: c,
                              vLineX: ctrl.currentFrameDay,
                              seriesList: [
                                ChartSeries(
                                  label: ctrl.lang == 'ar'
                                      ? 'السيناريو الحالي'
                                      : 'Current Scenario',
                                  x: ctrl.data.meta.times,
                                  y: s.well,
                                  color: c.accent,
                                  fillArea: true,
                                ),
                                if (ctrl.scenarioIdx != 4)
                                  ChartSeries(
                                    label: ctrl.lang == 'ar'
                                        ? 'خط الأساس (-40,000)'
                                        : 'Baseline (-40,000)',
                                    x: ctrl.data.meta.times,
                                    y: baseS.well,
                                    color: c.faint,
                                    dashed: true,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _legendDot(c.accent, 'Q = ${s.q.toInt()} m³/d'),
                            const SizedBox(width: 16),
                            if (ctrl.scenarioIdx != 4)
                              _legendDot(c.faint, 'Baseline (-40,000 m³/d)'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // 3. Risk Assessment Card
                SizedBox(
                  width: cardW,
                  child: _panelCard(
                    tag: ctrl.t('ov.riskTag'),
                    title: ctrl.t('ov.riskTitle'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: rInfo.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: rInfo.color.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '$rScore',
                                style: TextStyle(
                                  color: rInfo.color,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'JetBrains Mono',
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rInfo.label,
                                      style: TextStyle(
                                        color: rInfo.color,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      rInfo.desc,
                                      style: TextStyle(
                                          color: c.text2,
                                          fontSize: 12,
                                          height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _metaRow(
                          ctrl.lang == 'ar'
                              ? 'هبوط اليوم 30 المتوقع'
                              : 'Day-30 Max Drawdown',
                          '${s.maxDrawdown.last.toStringAsFixed(2)} m',
                        ),
                        _metaRow(
                          ctrl.lang == 'ar'
                              ? 'منسوب البئر عند اليوم 30'
                              : 'Day-30 Well Head',
                          '${s.well.last.toStringAsFixed(2)} m',
                        ),
                        _metaRow(
                          ctrl.lang == 'ar'
                              ? 'المساحة المتأثرة (>2م)'
                              : 'Affected Basin Area',
                          '${s.affected.last.toStringAsFixed(1)}%',
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () => ctrl.setRoute('risk'),
                          icon: const Icon(Icons.calculate_outlined, size: 17),
                          label: Text(ctrl.t('ov.goToRisk'),
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // VIEW 2: AQUIFER EXPLORER
  // ===========================================================================
  Widget _buildExploreView() {
    final s = ctrl.currentScenario;
    final fi = ctrl.frameIdx;
    final isHead = ctrl.metric == 'head';
    final grid = isHead
        ? ctrl.headGrid(ctrl.scenarioIdx, fi)
        : ctrl.drawdownGrid(ctrl.scenarioIdx, fi);
    final st = s.frameStats[fi];
    final minV = isHead ? st.min : 0.0;
    final maxV = isHead ? st.max : st.maxDrawdown;

    final r = ctrl.selectedRow;
    final col = ctrl.selectedCol;
    final nx = ctrl.data.meta.nx;
    final ny = ctrl.data.meta.ny;
    final cellHead = ctrl.headGrid(ctrl.scenarioIdx, fi)[r * nx + col];
    final cellDD = ctrl.data.meta.initialHead - cellHead;
    final xCoord = -500.0 + (col / (nx - 1)) * 1000.0;
    final yCoord = -500.0 + (r / (ny - 1)) * 1000.0;
    final distWell = math.sqrt(
      math.pow(xCoord - ctrl.data.meta.well[0], 2) +
          math.pow(yCoord - ctrl.data.meta.well[1], 2),
    );

    // Cross-section profiles (East-West across row r, North-South across col)
    final xAxisCoords = List<double>.generate(
        nx, (cIdx) => -500.0 + (cIdx / (nx - 1)) * 1000.0);
    final ewSliceCurrent =
        List<double>.generate(nx, (cIdx) => grid[r * nx + cIdx]);
    final baseGrid = isHead ? ctrl.headGrid(4, fi) : ctrl.drawdownGrid(4, fi);
    final ewSliceBase =
        List<double>.generate(nx, (cIdx) => baseGrid[r * nx + cIdx]);
    final nsSliceCurrent =
        List<double>.generate(ny, (rIdx) => grid[rIdx * nx + col]);
    final nsSliceBase =
        List<double>.generate(ny, (rIdx) => baseGrid[rIdx * nx + col]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Explorer Toolbar
        _panelCard(
          tag: ctrl.t('ex.tag'),
          title: ctrl.t('ex.title'),
          trailing: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(ctrl.t('ex.mHead')),
                selected: isHead,
                onSelected: (_) {
                  ctrl.metric = 'head';
                  ctrl.notifyListeners();
                },
              ),
              ChoiceChip(
                label: Text(ctrl.t('ex.mDrawdown')),
                selected: !isHead,
                onSelected: (_) {
                  ctrl.metric = 'drawdown';
                  ctrl.notifyListeners();
                },
              ),
              FilterChip(
                label: Text(ctrl.t('ex.contours')),
                selected: ctrl.contours,
                onSelected: (v) {
                  ctrl.contours = v;
                  ctrl.notifyListeners();
                },
              ),
              ElevatedButton.icon(
                onPressed: ctrl.togglePlay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ctrl.playing ? c.warn : c.accent,
                  foregroundColor: const Color(0xFF041019),
                ),
                icon: Icon(
                    ctrl.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 18),
                label: Text(
                  ctrl.playing
                      ? (ctrl.lang == 'ar' ? 'إيقاف' : 'Pause')
                      : (ctrl.lang == 'ar' ? 'تشغيل الزمن' : 'Play Time'),
                ),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              final isWide = box.maxWidth > 860;
              return Wrap(
                spacing: 18,
                runSpacing: 18,
                children: [
                  // Interactive 50x50 Heatmap Canvas
                  SizedBox(
                    width: isWide ? box.maxWidth * 0.58 : box.maxWidth,
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1.08,
                          child: LayoutBuilder(
                            builder: (ctx, canvasBox) {
                              return GestureDetector(
                                onTapDown: (details) {
                                  final local = details.localPosition;
                                  final cIdx =
                                      ((local.dx / canvasBox.maxWidth) * nx)
                                          .floor();
                                  final rIdx =
                                      ((local.dy / canvasBox.maxHeight) * ny)
                                          .floor();
                                  ctrl.selectCell(rIdx, cIdx);
                                },
                                onPanUpdate: (details) {
                                  final local = details.localPosition;
                                  final cIdx =
                                      ((local.dx / canvasBox.maxWidth) * nx)
                                          .floor();
                                  final rIdx =
                                      ((local.dy / canvasBox.maxHeight) * ny)
                                          .floor();
                                  ctrl.selectCell(rIdx, cIdx);
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CustomPaint(
                                    painter: HydroHeatmapPainter(
                                      grid: grid,
                                      minVal: minV,
                                      maxVal: maxV,
                                      rampName: isHead ? 'head' : 'drawdown',
                                      showContours: ctrl.contours,
                                      selectedRow: r,
                                      selectedCol: col,
                                      showCrosshair: true,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        _colorbarRow(
                          isHead ? 'head' : 'drawdown',
                          '${minV.toStringAsFixed(2)} m',
                          '${maxV.toStringAsFixed(2)} m',
                        ),
                      ],
                    ),
                  ),
                  // Cell Inspector Side Panel
                  SizedBox(
                    width: isWide ? box.maxWidth * 0.38 : box.maxWidth,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: c.panel2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.stroke),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctrl.t('ex.inspectorTag'),
                            style: TextStyle(
                                color: c.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ctrl.t('ex.inspectorTitle'),
                            style: TextStyle(
                                color: c.text,
                                fontSize: 15,
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          _metaRow(ctrl.t('ex.cellCoords'),
                              '($r, $col) · (${xCoord.toStringAsFixed(0)}m, ${yCoord.toStringAsFixed(0)}m)'),
                          _metaRow(ctrl.t('ex.cellHead'),
                              '${cellHead.toStringAsFixed(2)} m',
                              highlight: true),
                          _metaRow(ctrl.t('ex.cellDrawdown'),
                              '${cellDD.toStringAsFixed(2)} m'),
                          _metaRow(ctrl.t('ex.cellDist'),
                              '${distWell.toStringAsFixed(0)} m'),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: ctrl.resetCellToWell,
                              icon: const Icon(Icons.my_location_rounded,
                                  size: 15),
                              label: Text(ctrl.t('ex.resetToWell'),
                                  style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            ctrl.t('ex.cellHistory'),
                            style: TextStyle(
                                color: c.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 150,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: HydroLineChartPainter(
                                colors: c,
                                vLineX: ctrl.currentFrameDay,
                                seriesList: [
                                  ChartSeries(
                                    label: 'Max Drawdown',
                                    x: ctrl.data.meta.times,
                                    y: s.maxDrawdown,
                                    color: c.warn,
                                    fillArea: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        // Cross-section profiles (EW & NS)
        LayoutBuilder(
          builder: (context, box) {
            final isWide = box.maxWidth > 860;
            final w = isWide ? (box.maxWidth - 16) / 2 : box.maxWidth;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: w,
                  child: _panelCard(
                    tag: ctrl.t('ex.sliceEWTag'),
                    title: '${ctrl.t('ex.sliceEWTitle')} (Row $r)',
                    child: SizedBox(
                      height: 210,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: HydroLineChartPainter(
                          colors: c,
                          vLineX: ctrl.data.meta.well[0],
                          seriesList: [
                            ChartSeries(
                              label: 'Current',
                              x: xAxisCoords,
                              y: ewSliceCurrent,
                              color: c.accent,
                              fillArea: true,
                            ),
                            ChartSeries(
                              label: 'Baseline',
                              x: xAxisCoords,
                              y: ewSliceBase,
                              color: c.faint,
                              dashed: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: w,
                  child: _panelCard(
                    tag: ctrl.t('ex.sliceNSTag'),
                    title: '${ctrl.t('ex.sliceNSTitle')} (Col $col)',
                    child: SizedBox(
                      height: 210,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: HydroLineChartPainter(
                          colors: c,
                          vLineX: ctrl.data.meta.well[1],
                          seriesList: [
                            ChartSeries(
                              label: 'Current',
                              x: xAxisCoords,
                              y: nsSliceCurrent,
                              color: c.accent2,
                              fillArea: true,
                            ),
                            ChartSeries(
                              label: 'Baseline',
                              x: xAxisCoords,
                              y: nsSliceBase,
                              color: c.faint,
                              dashed: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // VIEW 3: SCENARIO COMPARE
  // ===========================================================================
  Widget _buildCompareView() {
    final sA = ctrl.data.scenarios[ctrl.compareA];
    final sB = ctrl.data.scenarios[ctrl.compareB];
    final fi = ctrl.compareFrameIdx;
    final ti = [0, 3, 7, 12, 22, 32][fi];
    final gridA = ctrl.headGrid(ctrl.compareA, fi);
    final gridB = ctrl.headGrid(ctrl.compareB, fi);
    final diff = ctrl.diffGrid(ctrl.compareB, ctrl.compareA, fi);

    final minHead = math.min(sA.frameStats[fi].min, sB.frameStats[fi].min);
    final maxHead = math.max(sA.frameStats[fi].max, sB.frameStats[fi].max);
    double maxAbsDiff = 0.5;
    for (final v in diff) {
      if (v.abs() > maxAbsDiff) maxAbsDiff = v.abs();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _panelCard(
          tag: ctrl.t('cmp.tag'),
          title: ctrl.t('cmp.title'),
          trailing: OutlinedButton.icon(
            onPressed: () {
              final tmp = ctrl.compareA;
              ctrl.compareA = ctrl.compareB;
              ctrl.compareB = tmp;
              ctrl.notifyListeners();
            },
            icon: const Icon(Icons.swap_horiz_rounded, size: 17),
            label: Text(ctrl.t('cmp.swap')),
          ),
          child: Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              _scenarioDropdown(
                label: ctrl.t('cmp.scenA'),
                value: ctrl.compareA,
                onChanged: (v) {
                  ctrl.compareA = v;
                  ctrl.notifyListeners();
                },
              ),
              _scenarioDropdown(
                label: ctrl.t('cmp.scenB'),
                value: ctrl.compareB,
                onChanged: (v) {
                  ctrl.compareB = v;
                  ctrl.notifyListeners();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 3 Maps: A, B, Difference (B - A)
        LayoutBuilder(
          builder: (context, box) {
            final isWide = box.maxWidth > 960;
            final w = isWide ? (box.maxWidth - 28) / 3 : box.maxWidth;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: w,
                  child: _panelCard(
                    tag: 'SCENARIO A · Q = ${sA.q.toInt()}',
                    title: ctrl.t('cmp.mapATitle'),
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1.2,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CustomPaint(
                              painter: HydroHeatmapPainter(
                                grid: gridA,
                                minVal: minHead,
                                maxVal: maxHead,
                                rampName: 'head',
                                showCrosshair: false,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _colorbarRow('head', '${minHead.toStringAsFixed(1)}m',
                            '${maxHead.toStringAsFixed(1)}m'),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: w,
                  child: _panelCard(
                    tag: 'SCENARIO B · Q = ${sB.q.toInt()}',
                    title: ctrl.t('cmp.mapBTitle'),
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1.2,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CustomPaint(
                              painter: HydroHeatmapPainter(
                                grid: gridB,
                                minVal: minHead,
                                maxVal: maxHead,
                                rampName: 'head',
                                showCrosshair: false,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _colorbarRow('head', '${minHead.toStringAsFixed(1)}m',
                            '${maxHead.toStringAsFixed(1)}m'),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: w,
                  child: _panelCard(
                    tag: ctrl.t('cmp.diffTag'),
                    title: ctrl.t('cmp.diffTitle'),
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1.2,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CustomPaint(
                              painter: HydroHeatmapPainter(
                                grid: diff,
                                minVal: -maxAbsDiff,
                                maxVal: maxAbsDiff,
                                rampName: 'diverge',
                                showContours: false,
                                showCrosshair: false,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _colorbarRow(
                            'diverge',
                            '-${maxAbsDiff.toStringAsFixed(2)}m',
                            '+${maxAbsDiff.toStringAsFixed(2)}m'),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        // Comparison Table + Dual Well Hydrograph
        LayoutBuilder(
          builder: (context, box) {
            final isWide = box.maxWidth > 900;
            final w = isWide ? (box.maxWidth - 16) / 2 : box.maxWidth;
            final dWell = sB.well[ti] - sA.well[ti];
            final dDD = sB.maxDrawdown[ti] - sA.maxDrawdown[ti];
            final dAff = sB.affected[fi] - sA.affected[fi];

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: w,
                  child: _panelCard(
                    tag: ctrl.t('cmp.tableTag'),
                    title: ctrl.t('cmp.tableTitle'),
                    child: Column(
                      children: [
                        _cmpRow(
                          ctrl.lang == 'ar'
                              ? 'معدل الضخ اليومي'
                              : 'Pumping Rate',
                          '${sA.q.toInt()} m³/d',
                          '${sB.q.toInt()} m³/d',
                          '${(sB.q - sA.q).toInt()} m³/d',
                          goodIfPositive: true,
                        ),
                        _cmpRow(
                          ctrl.lang == 'ar'
                              ? 'منسوب البئر (م)'
                              : 'Well Head (m)',
                          '${sA.well[ti].toStringAsFixed(2)} m',
                          '${sB.well[ti].toStringAsFixed(2)} m',
                          '${dWell >= 0 ? '+' : ''}${dWell.toStringAsFixed(2)} m',
                          goodIfPositive: true,
                        ),
                        _cmpRow(
                          ctrl.lang == 'ar'
                              ? 'أقصى هبوط (م)'
                              : 'Max Drawdown (m)',
                          '${sA.maxDrawdown[ti].toStringAsFixed(2)} m',
                          '${sB.maxDrawdown[ti].toStringAsFixed(2)} m',
                          '${dDD >= 0 ? '+' : ''}${dDD.toStringAsFixed(2)} m',
                          goodIfPositive: false,
                        ),
                        _cmpRow(
                          ctrl.lang == 'ar'
                              ? 'المساحة المتأثرة'
                              : 'Affected Area',
                          '${sA.affected[fi].toStringAsFixed(1)}%',
                          '${sB.affected[fi].toStringAsFixed(1)}%',
                          '${dAff >= 0 ? '+' : ''}${dAff.toStringAsFixed(1)}%',
                          goodIfPositive: false,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: w,
                  child: _panelCard(
                    tag: ctrl.t('cmp.hydroTag'),
                    title: ctrl.t('cmp.hydroTitle'),
                    child: SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: HydroLineChartPainter(
                          colors: c,
                          seriesList: [
                            ChartSeries(
                              label: 'Scenario A (${sA.q.toInt()})',
                              x: ctrl.data.meta.times,
                              y: sA.well,
                              color: c.accent,
                            ),
                            ChartSeries(
                              label: 'Scenario B (${sB.q.toInt()})',
                              x: ctrl.data.meta.times,
                              y: sB.well,
                              color: c.accent2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // VIEW 4: RISK & DECISION (GOAL SEEK + EGYPT AQUIFER CONTEXT)
  // ===========================================================================
  Widget _buildRiskView() {
    final rScore = ctrl.computeRiskScore(ctrl.scenarioIdx, 32);
    final rInfo = ctrl.riskLevelInfo(rScore);
    final gs = ctrl.goalSeek(ctrl.riskLimit);

    final regions = [
      (
        id: 'west-delta',
        nameAr: 'حوض غرب الدلتا والمغرة',
        nameEn: 'West Delta & Moghra Basin',
        typeAr: 'خزان شبه محصور / متجدد جزئياً',
        typeEn: 'Semi-confined / Partially Renewable',
        depth: '120 – 450 m',
        recommendAr:
            'يُنصح بعدم تجاوز هبوط 9.5 متر لتفادي تداخل مياه البحر المتوسط المالحة.',
        recommendEn:
            'Keep drawdown ≤ 9.5m to prevent Mediterranean seawater intrusion.',
      ),
      (
        id: 'minya',
        nameAr: 'حوض غرب المنيا',
        nameEn: 'West Minya Limestone/Nubian Basin',
        typeAr: 'حجر جيري متشقق + رمل نوبي',
        typeEn: 'Fractured Eocene Limestone & Nubian',
        depth: '180 – 600 m',
        recommendAr:
            'تنظيم المسافات البينية بين الآبار الزراعية بحيث لا تقل عن 1,000 متر.',
        recommendEn:
            'Maintain minimum 1,000m spacing between agricultural production wells.',
      ),
      (
        id: 'farafra',
        nameAr: 'واحة الفرافرة (الحوض النوبي)',
        nameEn: 'Farafra Oasis (Nubian Sandstone)',
        typeAr: 'خزان جوفي عميق غير متجدد',
        typeEn: 'Deep Fossil Non-Renewable Aquifer',
        depth: '500 – 1,200 m',
        recommendAr:
            'تطبيق سيناريو الخفض (-25%، Q = -30,000) لإطالة العمر التشغيلي للآبار.',
        recommendEn:
            'Apply -25% conservation scenario (Q = -30,000) to extend wellfield life.',
      ),
      (
        id: 'toshka',
        nameAr: 'توشكى وشرق العوينات',
        nameEn: 'Toshka & East Oweinat',
        typeAr: 'خزان الحجر الرملي النوبي الرئيسي',
        typeEn: 'Primary Nubian Sandstone Aquifer',
        depth: '250 – 850 m',
        recommendAr:
            'مراقبة مخروط الانخفاض عبر حساسات القياس عن بعد وتفعيل الضخ الشمسي المتدرج.',
        recommendEn:
            'Monitor drawdown cones via telemetry and use staged solar pumping.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final isWide = box.maxWidth > 900;
            final w = isWide ? (box.maxWidth - 16) / 2 : box.maxWidth;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                // Risk Gauge Card
                SizedBox(
                  width: w,
                  child: _panelCard(
                    tag: ctrl.t('risk.gaugeTag'),
                    title: ctrl.t('risk.gaugeTitle'),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 185,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: RiskGaugePainter(
                              score: rScore,
                              label: rInfo.label,
                              colors: c,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          rInfo.desc,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: c.text2, fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                // Goal Seek Card
                SizedBox(
                  width: w,
                  child: _panelCard(
                    tag: ctrl.t('risk.gsTag'),
                    title: ctrl.t('risk.gsTitle'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          ctrl.t('risk.gsDesc'),
                          style: TextStyle(
                              color: c.muted, fontSize: 12.5, height: 1.45),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(ctrl.t('risk.gsLabel'),
                                style:
                                    TextStyle(color: c.text2, fontSize: 12.5)),
                            Text(
                              '${ctrl.riskLimit.toStringAsFixed(1)} m',
                              style: TextStyle(
                                color: c.accent,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'JetBrains Mono',
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: ctrl.riskLimit,
                          min: 6.5,
                          max: 15.0,
                          divisions: 85,
                          activeColor: c.accent,
                          onChanged: (v) {
                            ctrl.riskLimit = v;
                            ctrl.notifyListeners();
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: c.panel2,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: c.accent.withOpacity(0.4)),
                          ),
                          child: gs.ok
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ctrl.lang == 'ar'
                                          ? 'معدل الضخ اليومي الموصى به:'
                                          : 'Recommended Safe Pumping Rate:',
                                      style: TextStyle(
                                          color: c.faint, fontSize: 11.5),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${gs.q!.toStringAsFixed(0)} m³/day (${gs.pct! >= 0 ? '+' : ''}${gs.pct!.toStringAsFixed(1)}%)',
                                      style: TextStyle(
                                        color: c.accent2,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'JetBrains Mono',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        if (gs.idx != null) {
                                          ctrl.setScenario(gs.idx!);
                                          ctrl.showToast(
                                            ctrl.lang == 'ar'
                                                ? 'تم تطبيق السيناريو المطابق'
                                                : 'Applied matching scenario',
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: c.accent,
                                        foregroundColor:
                                            const Color(0xFF041019),
                                      ),
                                      icon: const Icon(
                                          Icons.check_circle_outline,
                                          size: 16),
                                      label: Text(ctrl.t('risk.gsApply')),
                                    ),
                                  ],
                                )
                              : Text(
                                  ctrl.lang == 'ar'
                                      ? 'الحد المطلوب أقل من أدنى سيناريو متاح (6.96 متر عند -25,000 م³/يوم).'
                                      : 'Target limit is below minimum scenario drawdown (6.96m at -25,000 m³/d).',
                                  style: TextStyle(
                                      color: c.danger, fontSize: 12.5),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        // Egyptian Strategic Groundwater Basins Context
        _panelCard(
          tag: ctrl.t('risk.egyptTag'),
          title: ctrl.t('risk.egyptTitle'),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: regions.map((reg) {
              return Container(
                width: 280,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.panel2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.stroke),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: c.accent, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            ctrl.lang == 'ar' ? reg.nameAr : reg.nameEn,
                            style: TextStyle(
                                color: c.text,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ctrl.lang == 'ar' ? reg.typeAr : reg.typeEn,
                      style: TextStyle(
                          color: c.accent2,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Depth: ${reg.depth}',
                      style: TextStyle(
                          color: c.faint,
                          fontSize: 11,
                          fontFamily: 'JetBrains Mono'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ctrl.lang == 'ar' ? reg.recommendAr : reg.recommendEn,
                      style:
                          TextStyle(color: c.text2, fontSize: 12, height: 1.45),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // VIEW 5: MODEL ACCURACY (PINN VS MODFLOW-2005)
  // ===========================================================================
  Widget _buildAccuracyView() {
    final sum = ctrl.data.metrics.summary;
    final perRate = ctrl.data.metrics.perRate;

    // Build 10x33 RMSE matrix
    final matrix = List.generate(10, (si) {
      final q = ctrl.data.scenarios[si].q;
      final items = ctrl.data.metrics.perTimestep
          .where((e) => (e.q - q).abs() < 1.0)
          .toList();
      return items.map((e) => e.rmse).toList();
    });
    final rowLabels =
        ctrl.data.scenarios.map((s) => '${(s.q / 1000).toInt()}k').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 4 Accuracy KPIs
        LayoutBuilder(
          builder: (context, box) {
            final cols = box.maxWidth > 900 ? 4 : 2;
            final w = (box.maxWidth - (cols - 1) * 14) / cols;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: w,
                  child: _kpiCard(
                    title: ctrl.t('acc.k1'),
                    value: '${sum['meanRmse']!.toStringAsFixed(4)} m',
                    sub: ctrl.t('acc.k1s'),
                    color: c.accent,
                    icon: Icons.analytics_outlined,
                  ),
                ),
                SizedBox(
                  width: w,
                  child: _kpiCard(
                    title: ctrl.t('acc.k2'),
                    value: '${sum['meanMae']!.toStringAsFixed(4)} m',
                    sub: ctrl.t('acc.k2s'),
                    color: c.accent2,
                    icon: Icons.straighten_rounded,
                  ),
                ),
                SizedBox(
                  width: w,
                  child: _kpiCard(
                    title: ctrl.t('acc.k3'),
                    value: sum['meanR2']!.toStringAsFixed(4),
                    sub: ctrl.t('acc.k3s'),
                    color: c.violet,
                    icon: Icons.verified_rounded,
                  ),
                ),
                SizedBox(
                  width: w,
                  child: _kpiCard(
                    title: ctrl.t('acc.k4'),
                    value: '${sum['rrmse']!.toStringAsFixed(2)}%',
                    sub: ctrl.t('acc.k4s'),
                    color: c.warn,
                    icon: Icons.percent_rounded,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        // RMSE by Pumping Rate Bar Chart + 10x33 Matrix Heatmap
        LayoutBuilder(
          builder: (context, box) {
            final isWide = box.maxWidth > 900;
            final w = isWide ? (box.maxWidth - 16) / 2 : box.maxWidth;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: w,
                  child: _panelCard(
                    tag: ctrl.t('acc.perRateTag'),
                    title: ctrl.t('acc.perRateTitle'),
                    child: SizedBox(
                      height: 240,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: HydroBarChartPainter(
                          labels: rowLabels,
                          values: perRate.map((e) => e.rmse).toList(),
                          highlightIndex: ctrl.scenarioIdx,
                          colors: c,
                          barColor: c.accent,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: w,
                  child: _panelCard(
                    tag: ctrl.t('acc.matrixTag'),
                    title: ctrl.t('acc.matrixTitle'),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 210,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: MatrixHeatmapPainter(
                              matrix: matrix,
                              rowLabels: rowLabels,
                              colors: c,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _colorbarRow('error', '0.03 m', '0.32 m'),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // VIEW 6: DATA & EXPORT + .NET 8 REST API CONTRACT
  // ===========================================================================
  Widget _buildDataView() {
    final csvText = ctrl.generateCsv();
    const dotnetContract = '''POST /api/v1/pinn/predict
Content-Type: application/json

// Request Payload (from Flutter Web / Mobile Client):
{
  "pumpingRateM3PerDay": -40000.0,
  "timeDays": 30.0,
  "gridResolution": 50,
  "includeContours": true
}

// Response Payload (200 OK · ~110 ms):
{
  "scenario": { "q": -40000.0, "pctVsBaseline": 0.0 },
  "kpis": {
    "wellHeadM": 78.57,
    "maxDrawdownM": 11.43,
    "affectedAreaPct": 29.5,
    "riskScore": 66,
    "riskLevel": "Elevated"
  },
  "validation": { "rmseM": 0.1412, "r2": 0.9841 }
}''';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _panelCard(
          tag: ctrl.t('data.tableTag'),
          title: ctrl.t('data.tableTitle'),
          trailing: ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvText));
              ctrl.showToast(
                ctrl.lang == 'ar'
                    ? 'تم نسخ جدول CSV إلى الحافظة بنجاح'
                    : 'CSV table copied to clipboard',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: c.accent,
              foregroundColor: const Color(0xFF041019),
            ),
            icon: const Icon(Icons.copy_all_rounded, size: 17),
            label: Text(ctrl.t('data.exportCSV')),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(c.panel2),
              columns: [
                DataColumn(
                    label: Text(ctrl.t('data.colQ'),
                        style: TextStyle(
                            color: c.text, fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text(ctrl.t('data.colPct'),
                        style: TextStyle(
                            color: c.text, fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text(ctrl.t('data.colWell30'),
                        style: TextStyle(
                            color: c.text, fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text(ctrl.t('data.colMaxDD'),
                        style: TextStyle(
                            color: c.text, fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text(ctrl.t('data.colAff'),
                        style: TextStyle(
                            color: c.text, fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text(ctrl.t('data.colRMSE'),
                        style: TextStyle(
                            color: c.text, fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text(ctrl.t('data.colR2'),
                        style: TextStyle(
                            color: c.text, fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text(ctrl.t('data.colRisk'),
                        style: TextStyle(
                            color: c.text, fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text(ctrl.t('data.colAction'),
                        style: TextStyle(
                            color: c.text, fontWeight: FontWeight.bold))),
              ],
              rows: List.generate(ctrl.data.scenarios.length, (i) {
                final s = ctrl.data.scenarios[i];
                final m = ctrl.data.metrics.perRate[i];
                final rScore = ctrl.computeRiskScore(i, 32);
                final rInfo = ctrl.riskLevelInfo(rScore);
                return DataRow(
                  selected: i == ctrl.scenarioIdx,
                  cells: [
                    DataCell(Text('${s.q.toInt()} m³/d',
                        style: TextStyle(
                            color: c.text, fontFamily: 'JetBrains Mono'))),
                    DataCell(Text('${s.pct >= 0 ? '+' : ''}${s.pct}%',
                        style: TextStyle(
                            color: c.muted, fontFamily: 'JetBrains Mono'))),
                    DataCell(Text('${s.well.last.toStringAsFixed(2)} m',
                        style: TextStyle(
                            color: c.accent, fontFamily: 'JetBrains Mono'))),
                    DataCell(Text('${s.maxDrawdown.last.toStringAsFixed(2)} m',
                        style: TextStyle(
                            color: c.warn, fontFamily: 'JetBrains Mono'))),
                    DataCell(Text('${s.affected.last.toStringAsFixed(1)}%',
                        style: TextStyle(
                            color: c.text2, fontFamily: 'JetBrains Mono'))),
                    DataCell(Text(m.rmse.toStringAsFixed(4),
                        style: TextStyle(
                            color: c.text2, fontFamily: 'JetBrains Mono'))),
                    DataCell(Text(m.r2.toStringAsFixed(4),
                        style: TextStyle(
                            color: c.accent2, fontFamily: 'JetBrains Mono'))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: rInfo.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '$rScore · ${rInfo.label}',
                          style: TextStyle(
                              color: rInfo.color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    DataCell(
                      TextButton(
                        onPressed: () {
                          ctrl.setScenario(i);
                          ctrl.setRoute('explore');
                        },
                        child: Text(ctrl.lang == 'ar' ? 'معاينة' : 'Inspect',
                            style: TextStyle(color: c.accent)),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _panelCard(
          tag: ctrl.t('data.apiTag'),
          title: ctrl.t('data.apiTitle'),
          trailing: IconButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: dotnetContract));
              ctrl.showToast(ctrl.lang == 'ar'
                  ? 'تم نسخ عقد الـ API'
                  : 'API contract copied');
            },
            icon: Icon(Icons.copy_rounded, color: c.accent, size: 18),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.stroke),
            ),
            child: const SelectableText(
              dotnetContract,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: Color(0xFFA7F3D0),
                fontSize: 12,
                fontFamily: 'JetBrains Mono',
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // OVERLAYS: COMMAND PALETTE, SAVED DRAWER, GUIDED TOUR, TOAST
  // ===========================================================================
  Widget _buildCommandPaletteOverlay() {
    final actions = [
      (
        Icons.dashboard_rounded,
        ctrl.t('nav.overview'),
        () => ctrl.setRoute('overview')
      ),
      (
        Icons.grid_on_rounded,
        ctrl.t('nav.explore'),
        () => ctrl.setRoute('explore')
      ),
      (
        Icons.compare_arrows_rounded,
        ctrl.t('nav.compare'),
        () => ctrl.setRoute('compare')
      ),
      (Icons.shield_outlined, ctrl.t('nav.risk'), () => ctrl.setRoute('risk')),
      (
        Icons.verified_outlined,
        ctrl.t('nav.accuracy'),
        () => ctrl.setRoute('accuracy')
      ),
      (
        Icons.table_chart_outlined,
        ctrl.t('nav.data'),
        () => ctrl.setRoute('data')
      ),
      (
        Icons.language_rounded,
        ctrl.lang == 'ar' ? 'Switch to English' : 'التبديل إلى العربية',
        () {
          ctrl.toggleLang();
          ctrl.cmdOpen = false;
        }
      ),
      (
        Icons.brightness_6_rounded,
        ctrl.lang == 'ar'
            ? 'تبديل المظهر (ليلي / نهاري)'
            : 'Toggle Dark / Light Theme',
        () {
          ctrl.toggleTheme();
          ctrl.cmdOpen = false;
        }
      ),
    ];

    return GestureDetector(
      onTap: () {
        ctrl.cmdOpen = false;
        ctrl.notifyListeners();
      },
      child: Container(
        color: Colors.black54,
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.only(top: 90),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 520,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.strokeStrong),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 24)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.terminal_rounded, color: c.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ctrl.t('cmd.searchPlaceholder'),
                        style: TextStyle(
                            color: c.text, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ctrl.cmdOpen = false;
                        ctrl.notifyListeners();
                      },
                      icon: Icon(Icons.close_rounded, color: c.muted, size: 18),
                    ),
                  ],
                ),
                Divider(color: c.stroke),
                ...actions.map((act) => ListTile(
                      dense: true,
                      leading: Icon(act.$1, color: c.accent, size: 19),
                      title: Text(act.$2,
                          style: TextStyle(color: c.text, fontSize: 13)),
                      onTap: act.$3,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedScenariosDrawer() {
    return GestureDetector(
      onTap: () {
        ctrl.savedOpen = false;
        ctrl.notifyListeners();
      },
      child: Container(
        color: Colors.black54,
        alignment:
            ctrl.lang == 'ar' ? Alignment.centerLeft : Alignment.centerRight,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: 360,
            height: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.panel,
              border: Border(
                right: ctrl.lang == 'ar'
                    ? BorderSide(color: c.strokeStrong)
                    : BorderSide.none,
                left: ctrl.lang == 'en'
                    ? BorderSide(color: c.strokeStrong)
                    : BorderSide.none,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ctrl.t('saved.title'),
                      style: TextStyle(
                          color: c.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      onPressed: () {
                        ctrl.savedOpen = false;
                        ctrl.notifyListeners();
                      },
                      icon: Icon(Icons.close_rounded, color: c.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => ctrl.saveCurrentScenario(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: const Color(0xFF041019),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(ctrl.t('saved.saveCurrent')),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    itemCount: ctrl.savedScenarios.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final item = ctrl.savedScenarios[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.panel2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: c.stroke),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: TextStyle(
                                  color: c.text,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(item.note,
                                style:
                                    TextStyle(color: c.muted, fontSize: 11.5)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      ctrl.applySavedScenario(item),
                                  child: Text(
                                    ctrl.lang == 'ar' ? 'تطبيق' : 'Apply',
                                    style: TextStyle(
                                        color: c.accent,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      ctrl.deleteSavedScenario(item.id),
                                  icon: Icon(Icons.delete_outline_rounded,
                                      color: c.danger, size: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuidedTourOverlay() {
    final steps = [
      (
        route: 'overview',
        titleAr: '1. نظرة عامة ومؤشرات الأداء الفورية',
        titleEn: '1. Executive Overview & Real-Time KPIs',
        bodyAr:
            'تعرض هذه الشاشة منسوب المياه عند البئر، أقصى هبوط، المساحة المتأثرة، ومؤشر المخاطر التشغيلي لأي سيناريو ضخ.',
        bodyEn:
            'Displays well head, maximum drawdown, affected basin area, and composite risk score for any pumping rate.',
      ),
      (
        route: 'explore',
        titleAr: '2. مستكشف الخزان التفاعلي (50×50)',
        titleEn: '2. Interactive Aquifer Explorer (50×50)',
        bodyAr:
            'انقر أو اسحب على أي نقطة في الخريطة الحرارية لفحص المنسوب المحلي وعرض المقاطع العرضية (شرق-غرب وشمال-جنوب).',
        bodyEn:
            'Click or drag anywhere on the heatmap to inspect local head and view East-West & North-South cross-sections.',
      ),
      (
        route: 'compare',
        titleAr: '3. مقارنة السيناريوهات (أ مقابل ب)',
        titleEn: '3. Side-by-Side Scenario Comparison',
        bodyAr:
            'قارن أي معدلين للضخ مع خريطة الفارق المكاني الصافي وجدول المفاضلة الكمية.',
        bodyEn:
            'Benchmark any two pumping rates with a spatial difference heatmap and quantitative trade-off table.',
      ),
      (
        route: 'risk',
        titleAr: '4. البحث العكسي عن القرار (Goal Seek)',
        titleEn: '4. Inverse Goal Seek & Egypt Basins',
        bodyAr:
            'حدد أقصى هبوط مسموح به ليقوم النظام بحساب أقصى معدل ضخ يومي آمن تلقائياً.',
        bodyEn:
            'Set your maximum allowable drawdown ceiling to automatically compute the safe daily extraction rate.',
      ),
      (
        route: 'accuracy',
        titleAr: '5. التحقق العلمي مقابل MODFLOW-2005',
        titleEn: '5. Scientific Validation vs MODFLOW-2005',
        bodyAr:
            'استعرض دقة نموذج HydroPINN (R² = 0.978) ومصفوفة الخطأ عبر 330 حالة اختبار.',
        bodyEn:
            'Inspect HydroPINN accuracy (R² = 0.978) and the full 10×33 spatiotemporal RMSE matrix.',
      ),
      (
        route: 'data',
        titleAr: '6. تصدير البيانات وعقد .NET API',
        titleEn: '6. Data Export & .NET 8 API Contract',
        bodyAr:
            'قم بتصدير جدول النتائج بصيغة CSV واستعرض مواصفات الربط البرمجي مع الخادم الخلفي.',
        bodyEn:
            'Export simulation results to CSV and inspect the REST API contract for backend integration.',
      ),
    ];

    final idx = ctrl.tourStep!.clamp(0, steps.length - 1);
    final st = steps[idx];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.panel2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.accent, width: 1.5),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 20)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${ctrl.t('tour.step')} ${idx + 1} / ${steps.length}',
                      style: TextStyle(
                          color: c.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        ctrl.tourStep = null;
                        ctrl.notifyListeners();
                      },
                      child: Text(ctrl.t('tour.skip'),
                          style: TextStyle(color: c.faint, fontSize: 12)),
                    ),
                  ],
                ),
                Text(
                  ctrl.lang == 'ar' ? st.titleAr : st.titleEn,
                  style: TextStyle(
                      color: c.text, fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  ctrl.lang == 'ar' ? st.bodyAr : st.bodyEn,
                  style: TextStyle(color: c.text2, fontSize: 13, height: 1.45),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (idx > 0)
                      OutlinedButton(
                        onPressed: () {
                          ctrl.tourStep = idx - 1;
                          ctrl.setRoute(steps[idx - 1].route);
                        },
                        child: Text(ctrl.t('tour.prev')),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (idx + 1 < steps.length) {
                          ctrl.tourStep = idx + 1;
                          ctrl.setRoute(steps[idx + 1].route);
                        } else {
                          ctrl.tourStep = null;
                          ctrl.notifyListeners();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: const Color(0xFF041019),
                      ),
                      child: Text(
                        idx + 1 < steps.length
                            ? ctrl.t('tour.next')
                            : (ctrl.lang == 'ar' ? 'إنهاء الجولة' : 'Finish'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToastBanner() {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: c.panel2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.accent),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 12)
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: c.accent2, size: 18),
                const SizedBox(width: 8),
                Text(
                  ctrl.toastMessage!,
                  style: TextStyle(
                      color: c.text, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(top: BorderSide(color: c.stroke)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(ctrl.t('foot.ready'),
              style: TextStyle(color: c.faint, fontSize: 11)),
          Text(ctrl.t('foot.source'),
              style: TextStyle(color: c.faint, fontSize: 11)),
        ],
      ),
    );
  }

  // ===========================================================================
  // REUSABLE UI HELPERS
  // ===========================================================================
  Widget _heroMetricBox(
      String label, String val, String sub, Color accentColor) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: c.faint, fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            val,
            style: TextStyle(
              color: accentColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(color: c.muted, fontSize: 10.5)),
        ],
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String sub,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      color: c.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Icon(icon, color: color, size: 19),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: c.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          const SizedBox(height: 4),
          Text(sub,
              style: TextStyle(
                  color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _panelCard({
    required String tag,
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag,
                      style: TextStyle(
                        color: c.accent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: TextStyle(
                          color: c.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _colorbarRow(String rampName, String minText, String maxText) {
    final stops = HydroColorRamps.byName(rampName);
    return Row(
      children: [
        Text(minText,
            style: TextStyle(
                color: c.faint, fontSize: 11, fontFamily: 'JetBrains Mono')),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: LinearGradient(
                colors: stops.map((s) => s.color).toList(),
                stops: stops.map((s) => s.pos).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(maxText,
            style: TextStyle(
                color: c.faint, fontSize: 11, fontFamily: 'JetBrains Mono')),
      ],
    );
  }

  Widget _legendDot(Color col, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: c.muted, fontSize: 11.5)),
      ],
    );
  }

  Widget _scenarioDropdown({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style: TextStyle(
                color: c.muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: value,
          dropdownColor: c.panel2,
          style: TextStyle(
              color: c.text, fontSize: 12.5, fontFamily: 'JetBrains Mono'),
          items: List.generate(ctrl.data.scenarios.length, (i) {
            final sc = ctrl.data.scenarios[i];
            return DropdownMenuItem(
              value: i,
              child: Text(
                  '${sc.q.toInt()} m³/d (${sc.pct >= 0 ? '+' : ''}${sc.pct}%)'),
            );
          }),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }

  Widget _cmpRow(String metric, String valA, String valB, String delta,
      {required bool goodIfPositive}) {
    final isPos = delta.startsWith('+');
    final col = isPos == goodIfPositive ? c.good : c.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              flex: 3,
              child: Text(metric,
                  style: TextStyle(color: c.text2, fontSize: 12.5))),
          Expanded(
              flex: 2,
              child: Text(valA,
                  style: TextStyle(
                      color: c.muted,
                      fontSize: 12,
                      fontFamily: 'JetBrains Mono'))),
          Expanded(
              flex: 2,
              child: Text(valB,
                  style: TextStyle(
                      color: c.text,
                      fontSize: 12,
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.bold))),
          Expanded(
            flex: 2,
            child: Text(
              delta,
              textAlign: TextAlign.end,
              style: TextStyle(
                  color: col,
                  fontSize: 12,
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
