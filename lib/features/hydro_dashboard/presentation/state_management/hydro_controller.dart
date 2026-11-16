import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hydropinn_flutter_web/core/constants/app_colors.dart';
import 'package:hydropinn_flutter_web/core/localization/hydro_strings.dart';
import 'package:hydropinn_flutter_web/features/hydro_dashboard/data/models/hydro_models.dart';

class HydroController extends ChangeNotifier {
  final HydroData data;

  String lang = 'ar';
  bool isDark = true;
  String route = 'overview';

  int scenarioIdx = 4; // Baseline Q = -40,000 m³/day
  int frameIdx = 5; // Day 30
  String metric = 'head'; // 'head' | 'drawdown'
  bool contours = true;
  int selectedRow = 20;
  int selectedCol = 34;

  bool playing = false;
  Timer? _playTimer;

  int compareA = 4;
  int compareB = 8;
  int compareFrameIdx = 5;

  double riskLimit = 10.0;
  String region = 'all';
  String accScenario = 'all';
  String tableSearch = '';

  bool cmdOpen = false;
  bool savedOpen = false;
  int? tourStep;
  String? toastMessage;
  Timer? _toastTimer;

  late List<SavedScenario> savedScenarios;

  HydroController(this.data) {
    savedScenarios = [
      SavedScenario(
        id: 'seed-1',
        name: 'السيناريو المرجعي القياسي (Q = -40,000)',
        scenarioIdx: 4,
        frameIdx: 5,
        note: 'خط الأساس التشغيلي بعد 30 يوماً',
        created: DateTime.now().millisecondsSinceEpoch - 3600000 * 24,
      ),
      SavedScenario(
        id: 'seed-2',
        name: 'خطة ترشيد مستدامة (-25% ضخ)',
        scenarioIdx: 8,
        frameIdx: 5,
        note: 'خفض الهبوط إلى 8.42 متر وتقليص المساحة المتأثرة',
        created: DateTime.now().millisecondsSinceEpoch - 3600000 * 12,
      ),
    ];
  }

  HydroColors get colors => isDark ? HydroColors.dark : HydroColors.light;
  String t(String key) => HydroStrings.tr(lang, key);

  HydroScenario get currentScenario => data.scenarios[scenarioIdx];
  double get currentFrameDay => data.meta.frameTimes[frameIdx];

  int get wellRow => 20;
  int get wellCol => 34;

  void setRoute(String r) {
    route = r;
    cmdOpen = false;
    notifyListeners();
  }

  void toggleLang() {
    lang = lang == 'ar' ? 'en' : 'ar';
    notifyListeners();
  }

  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
  }

  void setScenario(int idx) {
    scenarioIdx = idx.clamp(0, data.scenarios.length - 1);
    notifyListeners();
  }

  void setFrame(int idx) {
    frameIdx = idx.clamp(0, data.meta.frameTimes.length - 1);
    notifyListeners();
  }

  void togglePlay() {
    playing = !playing;
    _playTimer?.cancel();
    if (playing) {
      _playTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
        frameIdx = (frameIdx + 1) % data.meta.frameTimes.length;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void selectCell(int r, int c) {
    selectedRow = r.clamp(0, data.meta.ny - 1);
    selectedCol = c.clamp(0, data.meta.nx - 1);
    notifyListeners();
  }

  void resetCellToWell() {
    selectedRow = wellRow;
    selectedCol = wellCol;
    notifyListeners();
  }

  void showToast(String msg) {
    toastMessage = msg;
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 3), () {
      toastMessage = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void saveCurrentScenario([String? customName]) {
    final s = currentScenario;
    final day = currentFrameDay;
    final name = customName ??
        (lang == 'ar'
            ? 'سيناريو Q=${s.q.toInt()} · اليوم $day'
            : 'Scenario Q=${s.q.toInt()} · Day $day');
    savedScenarios.insert(
      0,
      SavedScenario(
        id: 'sc-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        scenarioIdx: scenarioIdx,
        frameIdx: frameIdx,
        note: 'Max DD: ${s.maxDrawdown.last.toStringAsFixed(2)}m',
        created: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    showToast(lang == 'ar' ? 'تم حفظ السيناريو بنجاح' : 'Scenario saved');
  }

  void applySavedScenario(SavedScenario item) {
    scenarioIdx = item.scenarioIdx;
    frameIdx = item.frameIdx;
    savedOpen = false;
    showToast(
        lang == 'ar' ? 'تم تطبيق: ${item.name}' : 'Applied: ${item.name}');
  }

  void deleteSavedScenario(String id) {
    savedScenarios.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void clearSavedScenarios() {
    savedScenarios.clear();
    notifyListeners();
  }

  List<double> headGrid(int si, int fi) {
    final raw = data.scenarios[si].frames[fi];
    return List<double>.generate(raw.length, (i) => raw[i] / 10.0);
  }

  List<double> drawdownGrid(int si, int fi) {
    final raw = data.scenarios[si].frames[fi];
    final h0 = data.meta.initialHead;
    return List<double>.generate(raw.length, (i) => h0 - raw[i] / 10.0);
  }

  List<double> diffGrid(int bi, int ai, int fi) {
    final rawB = data.scenarios[bi].frames[fi];
    final rawA = data.scenarios[ai].frames[fi];
    final diff =
        List<double>.generate(rawB.length, (i) => (rawB[i] - rawA[i]) / 10.0);
    return smoothGrid(diff);
  }

  List<double> smoothGrid(List<double> src) {
    final nx = data.meta.nx;
    final ny = data.meta.ny;
    final out = List<double>.filled(src.length, 0.0);
    for (int r = 0; r < ny; r++) {
      for (int c = 0; c < nx; c++) {
        double sum = 0.0;
        int cnt = 0;
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            final rr = r + dr;
            final cc = c + dc;
            if (rr >= 0 && rr < ny && cc >= 0 && cc < nx) {
              sum += src[rr * nx + cc];
              cnt++;
            }
          }
        }
        out[r * nx + c] = sum / cnt;
      }
    }
    return out;
  }

  int computeRiskScore(int si, [int ti = 32]) {
    final dd = data.scenarios[si].maxDrawdown[ti];
    final fi = ti == 32 ? 5 : frameIdx;
    final af = data.scenarios[si].affected[fi];
    final ddScore = ((dd / 18.0) * 100.0).clamp(0.0, 100.0);
    final afScore = ((af / 40.0) * 100.0).clamp(0.0, 100.0);
    return (ddScore * 0.7 + afScore * 0.3).round();
  }

  ({String key, String label, Color color, String desc}) riskLevelInfo(
      int score) {
    if (score < 45) {
      return (
        key: 'low',
        label: lang == 'ar' ? 'منخفض (آمن)' : 'Low (Safe)',
        color: const Color(0xFF34D399),
        desc: lang == 'ar'
            ? 'معدل السحب ضمن الحدود الآمنة لاستدامة الخزان الجوفي ولا يسبب إجهاداً هيدروليكياً حرجاً.'
            : 'Extraction rate is within sustainable aquifer bounds with minimal hydraulic stress.'
      );
    } else if (score < 65) {
      return (
        key: 'moderate',
        label: lang == 'ar' ? 'متوسط (مراقبة)' : 'Moderate (Watch)',
        color: const Color(0xFFFACC15),
        desc: lang == 'ar'
            ? 'هبوط معتدل للمنسوب يتطلب مراقبة دورية لمناسيب آبار المراقبة المحيطة كل 10 أيام.'
            : 'Moderate drawdown requiring periodic monitoring of surrounding observation wells.'
      );
    } else if (score < 85) {
      return (
        key: 'elevated',
        label: lang == 'ar' ? 'مرتفع (تحذير)' : 'Elevated (Warning)',
        color: const Color(0xFFFB923C),
        desc: lang == 'ar'
            ? 'اتساع ملحوظ لمخروط الانخفاض (>25% من الحوض). يُوصى بتخفيض ساعات الضخ أو جدولة الراحة.'
            : 'Significant cone of depression expansion (>25% area). Pumping schedule reduction advised.'
      );
    } else {
      return (
        key: 'critical',
        label: lang == 'ar' ? 'حرج (خطر استنزاف)' : 'Critical (Depletion Risk)',
        color: const Color(0xFFFB7185),
        desc: lang == 'ar'
            ? 'تجاوز الحد الآمن للهبوط مع خطر تداخل المخاريط الهيدروليكية وارتفاع تكلفة الطاقة للرفع.'
            : 'Exceeds safe drawdown threshold with high risk of well interference and pumping cost surge.'
      );
    }
  }

  GoalSeekResult goalSeek(double limit) {
    final scenarios = data.scenarios;
    int best = -1;
    for (int i = 0; i < scenarios.length; i++) {
      if (scenarios[i].maxDrawdown.last <= limit) {
        best = i;
        break;
      }
    }
    if (best == -1) {
      return GoalSeekResult(ok: false);
    }
    if (best == 0 ||
        (best == scenarios.length - 1 &&
            scenarios.last.maxDrawdown.last < limit)) {
      return GoalSeekResult(
        ok: true,
        idx: best,
        q: scenarios[best].q,
        pct: scenarios[best].pct,
        interpolated: false,
        unbound: best == 0,
      );
    }
    final a = best - 1;
    final b = best;
    final d0 = scenarios[a].maxDrawdown.last;
    final d1 = scenarios[b].maxDrawdown.last;
    final k = (limit - d0) / (d1 - d0);
    final q = scenarios[a].q + (scenarios[b].q - scenarios[a].q) * k;
    final pct = (q / data.meta.qBaseline - 1.0) * 100.0;
    return GoalSeekResult(
      ok: true,
      idx: b,
      q: q,
      pct: pct,
      interpolated: true,
      lowerIdx: a,
      upperIdx: b,
    );
  }

  String generateCsv() {
    final sb = StringBuffer();
    sb.writeln(
        'Scenario_Index,Pumping_Rate_m3_day,Pct_vs_Baseline,Well_Head_Day30_m,Max_Drawdown_Day30_m,Affected_Area_Pct,RMSE_m,MAE_m,R2_Score,Risk_Score');
    for (int i = 0; i < data.scenarios.length; i++) {
      final s = data.scenarios[i];
      final m = data.metrics.perRate[i];
      final rScore = computeRiskScore(i, 32);
      sb.writeln(
          '$i,${s.q.toStringAsFixed(0)},${s.pct.toStringAsFixed(1)},${s.well.last.toStringAsFixed(2)},${s.maxDrawdown.last.toStringAsFixed(2)},${s.affected.last.toStringAsFixed(1)},${m.rmse.toStringAsFixed(4)},${m.mae.toStringAsFixed(4)},${m.r2.toStringAsFixed(4)},$rScore');
    }
    return sb.toString();
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }
}
