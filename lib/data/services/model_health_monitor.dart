import 'dart:collection';

class ProviderHealthStatus {
  final String providerId;
  final String modelId;
  int successCount = 0;
  int failureCount = 0;
  final Queue<int> recentLatencies = Queue();
  DateTime? lastFailure;
  DateTime? lastSuccess;

  ProviderHealthStatus({required this.providerId, required this.modelId});

  double get errorRate {
    final total = successCount + failureCount;
    return total == 0 ? 0.0 : failureCount / total;
  }

  double get averageLatency {
    if (recentLatencies.isEmpty) return 0.0;
    return recentLatencies.reduce((a, b) => a + b) / recentLatencies.length;
  }

  bool get isHealthy {
    if (errorRate > 0.3 &&
        lastFailure != null &&
        DateTime.now().difference(lastFailure!).inMinutes < 5) {
      return false;
    }
    return true;
  }

  int get healthScore {
    final latencyScore =
        averageLatency > 0 ? (100 - (averageLatency / 50).clamp(0, 100)).toInt() : 50;
    final reliabilityScore = ((1 - errorRate) * 100).toInt();
    return ((latencyScore + reliabilityScore) / 2).toInt();
  }
}

class ModelHealthMonitor {
  final Map<String, ProviderHealthStatus> _statusMap = {};

  String _key(String p, String m) => '$p:$m';

  ProviderHealthStatus _getOrCreate(String p, String m) =>
      _statusMap[_key(p, m)] ??= ProviderHealthStatus(providerId: p, modelId: m);

  void recordRequestStart(String p, String m) => _getOrCreate(p, m);

  void recordRequestSuccess(String p, String m, int latencyMs) {
    final s = _getOrCreate(p, m);
    s.successCount++;
    s.lastSuccess = DateTime.now();
    s.recentLatencies.add(latencyMs);
    if (s.recentLatencies.length > 20) s.recentLatencies.removeFirst();
  }

  void recordRequestFailure(String p, String m) {
    final s = _getOrCreate(p, m);
    s.failureCount++;
    s.lastFailure = DateTime.now();
  }

  ProviderHealthStatus? getStatus(String p, String m) =>
      _statusMap[_key(p, m)];

  Future<String?> getBestProvider(List<String> providerIds) async {
    if (providerIds.isEmpty) return null;
    if (providerIds.length == 1) return providerIds.first;

    String? best;
    int bestScore = -1;

    for (final id in providerIds) {
      final statuses = _statusMap.entries
          .where((e) => e.key.startsWith('$id:'))
          .map((e) => e.value)
          .toList();
      if (statuses.isNotEmpty && statuses.every((s) => !s.isHealthy)) continue;
      final avgScore = statuses.isEmpty
          ? 50
          : (statuses.fold<int>(0, (s, p) => s + p.healthScore) ~/
              statuses.length);
      if (avgScore > bestScore) {
        bestScore = avgScore;
        best = id;
      }
    }

    return best ?? providerIds.first;
  }

  void reset(String p, String m) => _statusMap.remove(_key(p, m));
  void resetAll() => _statusMap.clear();
}
