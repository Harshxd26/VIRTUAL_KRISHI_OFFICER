import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;

  Future<void> initSpeech() async {
    _available = await _speech.initialize();
  }

  Future<String?> startListening() async {
    if (!_available) return null;
    String resultText = '';
    await _speech.listen(onResult: (val) {
      resultText = val.recognizedWords;
    });
    return resultText;
  }

  void stopListening() {
    _speech.stop();
  }
}
