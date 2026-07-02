import '../datasources/remote/elevenlabs_datasource.dart';
import '../datasources/remote/openai_datasource.dart';

class VoiceRepositoryImpl {
  final ElevenLabsDatasource _elevenLabs;
  final OpenAIDatasource _openAI;

  VoiceRepositoryImpl({
    required ElevenLabsDatasource elevenLabs,
    required OpenAIDatasource openAI,
  })  : _elevenLabs = elevenLabs,
        _openAI = openAI;

  Future<String> transcribe({
    required List<int> audioBytes,
    required String filename,
    String? language,
  }) =>
      _openAI.transcribeAudio(
          audioBytes: audioBytes, filename: filename, language: language);

  Future<List<int>> synthesize({
    required String text,
    String provider = 'openai',
    String voice = 'alloy',
    String? elevenLabsVoiceId,
  }) async {
    if (provider == 'elevenlabs' && elevenLabsVoiceId != null) {
      return _elevenLabs.textToSpeech(text: text, voiceId: elevenLabsVoiceId);
    }
    return _openAI.textToSpeech(text: text, voice: voice);
  }

  Stream<List<int>> streamSynthesize(
          {required String text, String voiceId = 'rachel'}) =>
      _elevenLabs.streamTextToSpeech(text: text, voiceId: voiceId);

  Future<List<ElevenLabsVoice>> getElevenLabsVoices() =>
      _elevenLabs.getVoices();
}
