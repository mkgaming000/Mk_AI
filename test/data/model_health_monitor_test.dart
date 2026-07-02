import 'package:flutter_test/flutter_test.dart';
import 'package:omniforge_ai/data/services/model_health_monitor.dart';

void main() {
  late ModelHealthMonitor monitor;

  setUp(() => monitor = ModelHealthMonitor());

  group('ModelHealthMonitor', () {
    test('status is null before any requests are recorded', () {
      expect(monitor.getStatus('openai', 'gpt-4o'), isNull);
    });

    test('records a successful request and updates counters', () {
      monitor.recordRequestStart('openai', 'gpt-4o');
      monitor.recordRequestSuccess('openai', 'gpt-4o', 350);

      final status = monitor.getStatus('openai', 'gpt-4o');
      expect(status, isNotNull);
      expect(status!.successCount, 1);
      expect(status.failureCount, 0);
      expect(status.errorRate, 0.0);
      expect(status.isHealthy, true);
    });

    test('records a failure and increases the error rate', () {
      monitor.recordRequestStart('openai', 'gpt-4o');
      monitor.recordRequestSuccess('openai', 'gpt-4o', 300);
      monitor.recordRequestStart('openai', 'gpt-4o');
      monitor.recordRequestFailure('openai', 'gpt-4o');

      final status = monitor.getStatus('openai', 'gpt-4o');
      expect(status!.errorRate, closeTo(0.5, 0.01));
    });

    test('repeated recent failures mark a model unhealthy', () {
      for (int i = 0; i < 10; i++) {
        monitor.recordRequestStart('anthropic', 'claude-haiku-4-5');
        monitor.recordRequestFailure('anthropic', 'claude-haiku-4-5');
      }
      final status = monitor.getStatus('anthropic', 'claude-haiku-4-5');
      expect(status!.isHealthy, false);
    });

    test('getBestProvider prefers a healthy provider over a failing one',
        () async {
      monitor.recordRequestStart('openai', 'gpt-4o');
      monitor.recordRequestSuccess('openai', 'gpt-4o', 300);

      for (int i = 0; i < 10; i++) {
        monitor.recordRequestStart('anthropic', 'claude-haiku-4-5');
        monitor.recordRequestFailure('anthropic', 'claude-haiku-4-5');
      }

      final best = await monitor.getBestProvider(['openai', 'anthropic']);
      expect(best, 'openai');
    });

    test('getBestProvider returns the sole candidate when only one is given',
        () async {
      final best = await monitor.getBestProvider(['openai']);
      expect(best, 'openai');
    });

    test('getBestProvider returns null for an empty candidate list',
        () async {
      final best = await monitor.getBestProvider([]);
      expect(best, isNull);
    });

    test('reset clears tracked status for a specific provider/model', () {
      monitor.recordRequestStart('openai', 'gpt-4o');
      monitor.recordRequestSuccess('openai', 'gpt-4o', 300);
      monitor.reset('openai', 'gpt-4o');
      expect(monitor.getStatus('openai', 'gpt-4o'), isNull);
    });

    test('averageLatency is the mean of recorded latencies', () {
      for (final latency in [100, 200, 300]) {
        monitor.recordRequestStart('openai', 'gpt-4o');
        monitor.recordRequestSuccess('openai', 'gpt-4o', latency);
      }
      final status = monitor.getStatus('openai', 'gpt-4o');
      expect(status!.averageLatency, closeTo(200, 1));
    });

    test('resetAll clears every tracked provider/model', () {
      monitor.recordRequestStart('openai', 'gpt-4o');
      monitor.recordRequestSuccess('openai', 'gpt-4o', 300);
      monitor.recordRequestStart('anthropic', 'claude-sonnet-4-5');
      monitor.recordRequestSuccess('anthropic', 'claude-sonnet-4-5', 300);

      monitor.resetAll();

      expect(monitor.getStatus('openai', 'gpt-4o'), isNull);
      expect(monitor.getStatus('anthropic', 'claude-sonnet-4-5'), isNull);
    });
  });
}
