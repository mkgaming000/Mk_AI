import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AiProvider {
  openAI, anthropic, google, xAI, deepSeek, mistral,
  openRouter, huggingFace, together, qwen, ollama, lmStudio,
  stabilityAI, replicate, runway, pika, luma, kling,
  suno, udio, elevenLabs,
}

class ProviderConstants {
  ProviderConstants._();

  static const Map<AiProvider, String> providerNames = {
    AiProvider.openAI: 'OpenAI',
    AiProvider.anthropic: 'Anthropic',
    AiProvider.google: 'Google Gemini',
    AiProvider.xAI: 'xAI Grok',
    AiProvider.deepSeek: 'DeepSeek',
    AiProvider.mistral: 'Mistral AI',
    AiProvider.openRouter: 'OpenRouter',
    AiProvider.huggingFace: 'HuggingFace',
    AiProvider.together: 'Together AI (Llama)',
    AiProvider.qwen: 'Alibaba Qwen',
    AiProvider.ollama: 'Ollama (Local)',
    AiProvider.lmStudio: 'LM Studio (Local)',
    AiProvider.stabilityAI: 'Stability AI',
    AiProvider.replicate: 'Replicate',
    AiProvider.runway: 'Runway',
    AiProvider.pika: 'Pika',
    AiProvider.luma: 'Luma Dream Machine',
    AiProvider.kling: 'Kling AI',
    AiProvider.suno: 'Suno',
    AiProvider.udio: 'Udio',
    AiProvider.elevenLabs: 'ElevenLabs',
  };

  static const Map<AiProvider, String> providerShortNames = {
    AiProvider.openAI: 'OpenAI',
    AiProvider.anthropic: 'Claude',
    AiProvider.google: 'Gemini',
    AiProvider.xAI: 'Grok',
    AiProvider.deepSeek: 'DeepSeek',
    AiProvider.mistral: 'Mistral',
    AiProvider.openRouter: 'OpenRouter',
    AiProvider.huggingFace: 'HuggingFace',
    AiProvider.together: 'Llama',
    AiProvider.qwen: 'Qwen',
    AiProvider.ollama: 'Local',
    AiProvider.lmStudio: 'LM Studio',
    AiProvider.stabilityAI: 'Stability',
    AiProvider.replicate: 'Replicate',
    AiProvider.runway: 'Runway',
    AiProvider.pika: 'Pika',
    AiProvider.luma: 'Luma',
    AiProvider.kling: 'Kling',
    AiProvider.suno: 'Suno',
    AiProvider.udio: 'Udio',
    AiProvider.elevenLabs: 'ElevenLabs',
  };

  static const List<AiProvider> chatProviders = [
    AiProvider.openAI, AiProvider.anthropic, AiProvider.google,
    AiProvider.xAI, AiProvider.deepSeek, AiProvider.mistral,
    AiProvider.openRouter, AiProvider.huggingFace, AiProvider.together,
    AiProvider.qwen, AiProvider.ollama, AiProvider.lmStudio,
  ];

  static const List<AiProvider> imageProviders = [
    AiProvider.openAI, AiProvider.stabilityAI, AiProvider.replicate,
  ];

  static const List<AiProvider> videoProviders = [
    AiProvider.runway, AiProvider.pika, AiProvider.luma, AiProvider.kling,
  ];

  static const List<AiProvider> musicProviders = [
    AiProvider.suno, AiProvider.udio,
  ];

  static const List<AiProvider> voiceProviders = [
    AiProvider.elevenLabs, AiProvider.openAI,
  ];

  static const List<AiProvider> localProviders = [
    AiProvider.ollama, AiProvider.lmStudio,
  ];

  static Color colorForProvider(AiProvider p) {
    const colors = {
      AiProvider.openAI: AppColors.openAIColor,
      AiProvider.anthropic: AppColors.anthropicColor,
      AiProvider.google: AppColors.googleColor,
      AiProvider.xAI: AppColors.xAIColor,
      AiProvider.deepSeek: AppColors.deepSeekColor,
      AiProvider.mistral: AppColors.mistralColor,
      AiProvider.openRouter: AppColors.openRouterColor,
      AiProvider.huggingFace: AppColors.huggingFaceColor,
      AiProvider.together: AppColors.llamaColor,
      AiProvider.qwen: AppColors.qwenColor,
      AiProvider.ollama: AppColors.ollamaColor,
      AiProvider.stabilityAI: AppColors.stabilityColor,
      AiProvider.replicate: AppColors.replicateColor,
      AiProvider.runway: AppColors.runwayColor,
      AiProvider.pika: AppColors.pikaColor,
      AiProvider.luma: AppColors.lumaColor,
      AiProvider.suno: AppColors.sunoColor,
      AiProvider.udio: AppColors.udioColor,
      AiProvider.elevenLabs: AppColors.elevenLabsColor,
    };
    return colors[p] ?? AppColors.darkPrimary;
  }

  static String emojiForProvider(AiProvider p) {
    const emojis = {
      AiProvider.openAI: '🤖', AiProvider.anthropic: '🧠',
      AiProvider.google: '🔮', AiProvider.xAI: '⚡',
      AiProvider.deepSeek: '🌊', AiProvider.mistral: '🌪️',
      AiProvider.openRouter: '🔀', AiProvider.huggingFace: '🤗',
      AiProvider.together: '🦙', AiProvider.qwen: '🌸',
      AiProvider.ollama: '🏠', AiProvider.lmStudio: '🖥️',
      AiProvider.stabilityAI: '✨', AiProvider.replicate: '🌀',
      AiProvider.runway: '🎬', AiProvider.pika: '🎥',
      AiProvider.luma: '💫', AiProvider.kling: '🎞️',
      AiProvider.suno: '🎵', AiProvider.udio: '🎶',
      AiProvider.elevenLabs: '🗣️',
    };
    return emojis[p] ?? '🔑';
  }
}
