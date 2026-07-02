import 'package:uuid/uuid.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/storage/database/hive_boxes.dart';
import '../models/usage_stat_model.dart';

class CostTrackerService {
  final LocalStorageService _localStorage;
  final _uuid = const Uuid();

  CostTrackerService({required LocalStorageService localStorage})
      : _localStorage = localStorage;

  static const String _totalSpentKey = 'total_spent_all_time';
  static const String _monthlyBudgetKey = 'monthly_budget';

  Future<void> recordUsage({
    required String providerId,
    required String modelId,
    required String featureType,
    required int inputTokens,
    required int outputTokens,
    required double cost,
    required int durationMs,
  }) async {
    if (!_localStorage.usageTrackingEnabled) return;
    final stat = UsageStatModel(
      id: _uuid.v4(),
      providerId: providerId,
      modelId: modelId,
      featureType: featureType,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      cost: cost,
      requestCount: 1,
      date: DateTime.now(),
      durationMs: durationMs,
    );
    await HiveBoxes.usageStats.put(stat.id, stat);
    final current =
        _localStorage.getDoubleOrDefault(_totalSpentKey, 0.0);
    await _localStorage.setDouble(_totalSpentKey, current + cost);
  }

  double get totalSpentAllTime =>
      _localStorage.getDoubleOrDefault(_totalSpentKey, 0.0);

  double? get monthlyBudget {
    final v = _localStorage.getDouble(_monthlyBudgetKey);
    return (v == null || v == 0) ? null : v;
  }

  Future<void> setMonthlyBudget(double? amount) =>
      _localStorage.setDouble(_monthlyBudgetKey, amount ?? 0);

  double get currentMonthSpent {
    final now = DateTime.now();
    return HiveBoxes.usageStats.values
        .where((s) => s.date.year == now.year && s.date.month == now.month)
        .fold(0.0, (sum, s) => sum + s.cost);
  }

  bool get isOverBudget {
    final b = monthlyBudget;
    return b != null && currentMonthSpent >= b;
  }

  bool get isNearBudget {
    final b = monthlyBudget;
    return b != null && currentMonthSpent >= b * 0.8;
  }

  Map<String, double> getCostByProvider() {
    final map = <String, double>{};
    for (final s in HiveBoxes.usageStats.values) {
      map[s.providerId] = (map[s.providerId] ?? 0) + s.cost;
    }
    return map;
  }

  Map<String, double> getCostByFeature() {
    final map = <String, double>{};
    for (final s in HiveBoxes.usageStats.values) {
      map[s.featureType] = (map[s.featureType] ?? 0) + s.cost;
    }
    return map;
  }

  Map<String, int> getTokensByProvider() {
    final map = <String, int>{};
    for (final s in HiveBoxes.usageStats.values) {
      map[s.providerId] = (map[s.providerId] ?? 0) + s.totalTokens;
    }
    return map;
  }

  List<Map<String, dynamic>> getDailyUsage(int days) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final date =
          DateTime(now.year, now.month, now.day - (days - 1 - i));
      final stats = HiveBoxes.usageStats.values.where((s) =>
          s.date.year == date.year &&
          s.date.month == date.month &&
          s.date.day == date.day);
      return {
        'date': date,
        'cost': stats.fold(0.0, (sum, s) => sum + s.cost),
        'tokens': stats.fold<int>(0, (sum, s) => sum + s.totalTokens),
        'requests': stats.fold<int>(0, (sum, s) => sum + s.requestCount),
      };
    });
  }
}
