class TokenCounterService {
  int estimateTokens(String text) {
    if (text.isEmpty) return 0;
    int tokens = 0;
    for (final word in text.trim().split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      if (word.length <= 6) {
        tokens += 1;
      } else if (word.length <= 12) {
        tokens += 2;
      } else {
        tokens += (word.length / 4).ceil();
      }
    }
    final punctCount = RegExp(r'[.,!?;:\-\n\r\t]').allMatches(text).length;
    tokens += (punctCount * 0.7).ceil();
    if (_isCode(text)) tokens = (tokens * 1.3).ceil();
    return tokens;
  }

  bool _isCode(String text) => RegExp(
        r'^\s*(def|function|class|import|const|let|var)\s|[{}();]|\b(if|else|for|while|return)\b',
        multiLine: true,
      ).hasMatch(text);

  int estimateConversationTokens(List<String> messages) {
    final overhead = messages.length * 4;
    return overhead +
        messages.fold<int>(0, (sum, m) => sum + estimateTokens(m));
  }

  double calculateCost({
    required String providerId,
    required String modelId,
    required int inputTokens,
    required int outputTokens,
  }) {
    return (inputTokens * _inputPrice(providerId, modelId)) +
        (outputTokens * _outputPrice(providerId, modelId));
  }

  double _inputPrice(String p, String m) {
    final prices = {
      'openai': {'gpt-4o': 0.0000025, 'gpt-4o-mini': 0.00000015, 'gpt-4-turbo': 0.00001, 'gpt-4': 0.00003, 'gpt-3.5-turbo': 0.0000005, 'o1': 0.000015, 'o1-mini': 0.000003, 'o3-mini': 0.0000011},
      'anthropic': {'claude-opus-4-5': 0.000015, 'claude-sonnet-4-5': 0.000003, 'claude-haiku-4-5': 0.00000025},
    };
    return prices[p]?[m] ?? _defaultInputPrice(p);
  }

  double _outputPrice(String p, String m) {
    final prices = {
      'openai': {'gpt-4o': 0.00001, 'gpt-4o-mini': 0.0000006, 'o1': 0.00006, 'o1-mini': 0.000012},
      'anthropic': {'claude-opus-4-5': 0.000075, 'claude-sonnet-4-5': 0.000015, 'claude-haiku-4-5': 0.00000125},
    };
    return prices[p]?[m] ?? _defaultOutputPrice(p);
  }

  double _defaultInputPrice(String p) {
    switch (p) {
      case 'google': return 0.00000025;
      case 'deepseek': return 0.00000014;
      case 'mistral': return 0.000002;
      case 'xai': return 0.000003;
      default: return 0.000002;
    }
  }

  double _defaultOutputPrice(String p) {
    switch (p) {
      case 'google': return 0.00000075;
      case 'deepseek': return 0.00000028;
      case 'mistral': return 0.000006;
      case 'xai': return 0.000015;
      default: return 0.000006;
    }
  }
}
