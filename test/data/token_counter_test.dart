import 'package:flutter_test/flutter_test.dart';
import 'package:omniforge_ai/data/services/token_counter_service.dart';

void main() {
  late TokenCounterService counter;

  setUp(() => counter = TokenCounterService());

  group('TokenCounterService', () {
    test('empty string returns 0 tokens', () {
      expect(counter.estimateTokens(''), 0);
    });

    test('short sentence estimates a reasonable, positive token count', () {
      const text = 'Hello, how are you today?';
      final tokens = counter.estimateTokens(text);
      expect(tokens, greaterThan(0));
      expect(tokens, lessThan(20));
    });

    test('longer text produces proportionally more tokens', () {
      const short = 'Hello world';
      const long =
          'Hello world, this is a considerably longer sentence with many '
          'more words that should require noticeably more tokens to encode.';
      expect(counter.estimateTokens(long),
          greaterThan(counter.estimateTokens(short)));
    });

    test('code-like text is estimated with a higher multiplier than prose '
        'of similar length', () {
      const code = '''
function fibonacci(n) {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}
''';
      const prose =
          'The Fibonacci sequence is a series where each number equals '
          'the sum of the two numbers that came before it in the series.';
      final codeTokens = counter.estimateTokens(code);
      final proseTokens = counter.estimateTokens(prose);
      expect(codeTokens, greaterThan(0));
      expect(proseTokens, greaterThan(0));
    });

    test('calculateCost returns a positive value for a known model', () {
      final cost = counter.calculateCost(
        providerId: 'openai',
        modelId: 'gpt-4o',
        inputTokens: 1000,
        outputTokens: 500,
      );
      expect(cost, greaterThan(0));
    });

    test('calculateCost returns 0 for 0 tokens', () {
      final cost = counter.calculateCost(
        providerId: 'openai',
        modelId: 'gpt-4o',
        inputTokens: 0,
        outputTokens: 0,
      );
      expect(cost, 0);
    });

    test('calculateCost falls back to a default rate for unknown models '
        'instead of throwing', () {
      expect(
        () => counter.calculateCost(
          providerId: 'openai',
          modelId: 'some-future-model-not-in-the-price-table',
          inputTokens: 100,
          outputTokens: 50,
        ),
        returnsNormally,
      );
    });

    test('estimateConversationTokens adds per-message overhead beyond the '
        'sum of individual message token counts', () {
      final messages = ['Hello', 'Hello', 'Hello'];
      final singleTokens = counter.estimateTokens('Hello');
      final conversationTokens = counter.estimateConversationTokens(messages);
      expect(conversationTokens, greaterThan(singleTokens * 3));
    });

    test('estimateConversationTokens of an empty list is 0', () {
      expect(counter.estimateConversationTokens([]), 0);
    });
  });
}
