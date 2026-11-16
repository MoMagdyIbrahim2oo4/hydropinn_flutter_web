import 'dart:convert';

class HydroData {
  final HydroMeta meta;
  final List<HydroScenario> scenarios;
  final HydroMetrics metrics;

  HydroData({
    required this.meta,
    required this.scenarios,
    required this.metrics,
  });

  factory HydroData.fromJson(Map<String, dynamic> json) {
    return HydroData(
      meta: HydroMeta.fromJson(json['meta'] as Map<String, dynamic>),
      scenarios: (json['scenarios'] as List<dynamic>)
          .map((e) => HydroScenario.fromJson(e as Map<String, dynamic>))
          .toList(),
      metrics: HydroMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
    );
  }
}

class HydroMeta {
  final String source;
  final String license;
  final Map<String, double> domain;
  final int nx;
  final int ny;
  final List<double> well;
  final double initialHead;
  final double qMin;
  final double qMax;
  final double qBaseline;
  final List<double> times;
  final List<double> frameTimes;

  HydroMeta({
    required this.source,
    required this.license,
    required this.domain,
    required this.nx,
    required this.ny,
    required this.well,
    required this.initialHead,
    required this.qMin,
    required this.qMax,
    required this.qBaseline,
    required this.times,
    required this.frameTimes,
  });

  factory HydroMeta.fromJson(Map<String, dynamic> json) {
    final dom = (json['domain'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    final grid = json['grid'] as Map<String, dynamic>;
    return HydroMeta(
      source: json['source'] as String? ?? '',
      license: json['license'] as String? ?? '',
      domain: dom,
      nx: (grid['nx'] as num).toInt(),
      ny: (grid['ny'] as num).toInt(),
      well: (json['well'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      initialHead: (json['initialHead'] as num).toDouble(),
      qMin: (json['qMin'] as num).toDouble(),
      qMax: (json['qMax'] as num).toDouble(),
      qBaseline: (json['qBaseline'] as num).toDouble(),
      times: (json['times'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      frameTimes: (json['frameTimes'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}

class FrameStat {
  final double min;
  final double max;
  final double maxDrawdown;

  FrameStat({required this.min, required this.max, required this.maxDrawdown});

  factory FrameStat.fromJson(Map<String, dynamic> json) {
    return FrameStat(
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
      maxDrawdown: (json['maxDrawdown'] as num).toDouble(),
    );
  }
}

class HydroScenario {
  final double q;
  final double pct;
  final List<double> well;
  final List<double> maxDrawdown;
  final List<double> meanHead;
  final List<double> affected;
  final List<List<int>> frames;
  final List<FrameStat> frameStats;

  HydroScenario({
    required this.q,
    required this.pct,
    required this.well,
    required this.maxDrawdown,
    required this.meanHead,
    required this.affected,
    required this.frames,
    required this.frameStats,
  });

  factory HydroScenario.fromJson(Map<String, dynamic> json) {
    final frames = (json['frames'] as List<dynamic>)
        .map(
            (f) => (f as List<dynamic>).map((v) => (v as num).toInt()).toList())
        .toList();
    final meanHead = json['meanHead'] as List<dynamic>? ??
        frames
            .map((frame) => frame.isEmpty
                ? 0.0
                : frame.reduce((a, b) => a + b) / frame.length / 10.0)
            .toList();

    return HydroScenario(
      q: (json['q'] as num).toDouble(),
      pct: (json['pct'] as num).toDouble(),
      well: (json['well'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      maxDrawdown: (json['maxDrawdown'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      meanHead: meanHead.map((e) => (e as num).toDouble()).toList(),
      affected: (json['affected'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      frames: frames,
      frameStats: (json['frameStats'] as List<dynamic>)
          .map((s) => FrameStat.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HydroMetrics {
  final Map<String, double> summary;
  final List<RateMetric> perRate;
  final List<TimestepMetric> perTimestep;
  final List<Day30Metric> day30;

  HydroMetrics({
    required this.summary,
    required this.perRate,
    required this.perTimestep,
    required this.day30,
  });

  factory HydroMetrics.fromJson(Map<String, dynamic> json) {
    final sumMap = (json['summary'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    return HydroMetrics(
      summary: sumMap,
      perRate: (json['perRate'] as List<dynamic>)
          .map((e) => RateMetric.fromJson(e as Map<String, dynamic>))
          .toList(),
      perTimestep: (json['perTimestep'] as List<dynamic>)
          .map((e) => TimestepMetric.fromJson(e as Map<String, dynamic>))
          .toList(),
      day30: (json['day30'] as List<dynamic>)
          .map((e) => Day30Metric.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RateMetric {
  final double q;
  final double pct;
  final double rmse;
  final double mae;
  final double maxErr;
  final double r2;

  RateMetric({
    required this.q,
    required this.pct,
    required this.rmse,
    required this.mae,
    required this.maxErr,
    required this.r2,
  });

  factory RateMetric.fromJson(Map<String, dynamic> json) {
    return RateMetric(
      q: (json['q'] as num).toDouble(),
      pct: (json['pct'] as num).toDouble(),
      rmse: (json['rmse'] as num).toDouble(),
      mae: (json['mae'] as num).toDouble(),
      maxErr: ((json['maxErr'] ?? json['maxAbs'] ?? 0) as num).toDouble(),
      r2: (json['r2'] as num).toDouble(),
    );
  }
}

class TimestepMetric {
  final double q;
  final double t;
  final double rmse;
  final double mae;
  final double maxErr;

  TimestepMetric({
    required this.q,
    required this.t,
    required this.rmse,
    required this.mae,
    required this.maxErr,
  });

  factory TimestepMetric.fromJson(Map<String, dynamic> json) {
    return TimestepMetric(
      q: (json['q'] as num).toDouble(),
      t: (json['t'] as num).toDouble(),
      rmse: (json['rmse'] as num).toDouble(),
      mae: (json['mae'] as num).toDouble(),
      maxErr: ((json['maxErr'] ?? json['maxAbs'] ?? 0) as num).toDouble(),
    );
  }
}

class Day30Metric {
  final double q;
  final double pct;
  final double rmse;
  final double mae;
  final double maxErr;
  final double r2;

  Day30Metric({
    required this.q,
    required this.pct,
    required this.rmse,
    required this.mae,
    required this.maxErr,
    required this.r2,
  });

  factory Day30Metric.fromJson(Map<String, dynamic> json) {
    return Day30Metric(
      q: (json['q'] as num).toDouble(),
      pct: (json['pct'] as num).toDouble(),
      rmse: (json['rmse'] as num).toDouble(),
      mae: (json['mae'] as num).toDouble(),
      maxErr: ((json['maxErr'] ?? json['maxAbs'] ?? 0) as num).toDouble(),
      r2: (json['r2'] as num).toDouble(),
    );
  }
}

class SavedScenario {
  final String id;
  final String name;
  final int scenarioIdx;
  final int frameIdx;
  final String note;
  final int created;

  SavedScenario({
    required this.id,
    required this.name,
    required this.scenarioIdx,
    required this.frameIdx,
    required this.note,
    required this.created,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'scenarioIdx': scenarioIdx,
        'frameIdx': frameIdx,
        'note': note,
        'created': created,
      };

  factory SavedScenario.fromJson(Map<String, dynamic> json) {
    return SavedScenario(
      id: json['id'] as String,
      name: json['name'] as String,
      scenarioIdx: (json['scenarioIdx'] as num).toInt(),
      frameIdx: (json['frameIdx'] as num).toInt(),
      note: json['note'] as String? ?? '',
      created: (json['created'] as num).toInt(),
    );
  }

  static String encodeList(List<SavedScenario> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<SavedScenario> decodeList(String raw) {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => SavedScenario.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class GoalSeekResult {
  final bool ok;
  final int? idx;
  final double? q;
  final double? pct;
  final bool interpolated;
  final bool unbound;
  final int? lowerIdx;
  final int? upperIdx;

  GoalSeekResult({
    required this.ok,
    this.idx,
    this.q,
    this.pct,
    this.interpolated = false,
    this.unbound = false,
    this.lowerIdx,
    this.upperIdx,
  });
}
