class ApiConstants {
  ApiConstants._();

  // OpenAI
  static const String openAIBaseUrl = 'https://api.openai.com/v1';
  static const String openAIChatEndpoint = '/chat/completions';
  static const String openAIModelsEndpoint = '/models';
  static const String openAIImagesEndpoint = '/images/generations';
  static const String openAISpeechEndpoint = '/audio/speech';
  static const String openAITranscriptionEndpoint = '/audio/transcriptions';
  static const String openAIEmbeddingsEndpoint = '/embeddings';

  static const List<String> openAIModels = [
    'gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'gpt-4',
    'gpt-3.5-turbo', 'o1', 'o1-mini', 'o3-mini',
  ];

  static const Map<String, int> openAIContextWindows = {
    'gpt-4o': 128000, 'gpt-4o-mini': 128000, 'gpt-4-turbo': 128000,
    'gpt-4': 8192, 'gpt-3.5-turbo': 16385, 'o1': 200000, 'o1-mini': 128000,
  };

  // Anthropic
  static const String anthropicBaseUrl = 'https://api.anthropic.com/v1';
  static const String anthropicMessagesEndpoint = '/messages';
  static const String anthropicVersion = '2023-06-01';

  static const List<String> anthropicModels = [
    'claude-opus-4-5', 'claude-sonnet-4-5', 'claude-haiku-4-5',
    'claude-3-5-sonnet-20241022', 'claude-3-5-haiku-20241022',
    'claude-3-opus-20240229', 'claude-3-haiku-20240307',
  ];

  static const Map<String, int> anthropicContextWindows = {
    'claude-opus-4-5': 200000, 'claude-sonnet-4-5': 200000,
    'claude-haiku-4-5': 200000, 'claude-3-5-sonnet-20241022': 200000,
    'claude-3-opus-20240229': 200000,
  };

  // Google Gemini
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  static const List<String> geminiModels = [
    'gemini-2.0-flash-exp', 'gemini-1.5-pro', 'gemini-1.5-flash',
    'gemini-1.5-flash-8b',
  ];

  // xAI Grok
  static const String xAIBaseUrl = 'https://api.x.ai/v1';

  static const List<String> xAIModels = [
    'grok-3', 'grok-3-mini', 'grok-2-1212', 'grok-beta',
  ];

  // DeepSeek
  static const String deepSeekBaseUrl = 'https://api.deepseek.com/v1';

  static const List<String> deepSeekModels = [
    'deepseek-chat', 'deepseek-reasoner',
  ];

  // Mistral
  static const String mistralBaseUrl = 'https://api.mistral.ai/v1';

  static const List<String> mistralModels = [
    'mistral-large-latest', 'mistral-medium-latest',
    'mistral-small-latest', 'codestral-latest',
    'open-mistral-7b', 'open-mixtral-8x7b',
  ];

  // OpenRouter
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  static const String openRouterModelsEndpoint = '/models';
  static const String openRouterAppUrl = 'https://omniforge.ai';
  static const String openRouterAppName = 'OmniForge AI';

  // HuggingFace
  static const String huggingFaceBaseUrl =
      'https://api-inference.huggingface.co';

  static const List<String> huggingFacePopularModels = [
    'meta-llama/Meta-Llama-3-70B-Instruct',
    'meta-llama/Meta-Llama-3-8B-Instruct',
    'mistralai/Mixtral-8x7B-Instruct-v0.1',
    'Qwen/Qwen2-72B-Instruct',
  ];

  // Together AI (Llama)
  static const String togetherBaseUrl = 'https://api.together.xyz/v1';

  static const List<String> llamaModels = [
    'meta-llama/Llama-3-70b-chat-hf',
    'meta-llama/Llama-3-8b-chat-hf',
    'meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo',
    'meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo',
  ];

  // Qwen / DashScope
  static const String qwenBaseUrl =
      'https://dashscope.aliyuncs.com/compatible-mode/v1';

  static const List<String> qwenModels = [
    'qwen-max', 'qwen-plus', 'qwen-turbo',
  ];

  // Stability AI
  static const String stabilityBaseUrl = 'https://api.stability.ai/v2beta';

  // Replicate
  static const String replicateBaseUrl = 'https://api.replicate.com/v1';
  static const String replicatePredictionsEndpoint = '/predictions';

  // ElevenLabs
  static const String elevenLabsBaseUrl = 'https://api.elevenlabs.io/v1';
  static const String elevenLabsTTSEndpoint = '/text-to-speech';
  static const String elevenLabsVoicesEndpoint = '/voices';
  static const String elevenLabsVoiceCloneEndpoint = '/voices/add';
}
