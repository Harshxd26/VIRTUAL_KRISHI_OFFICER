// text_query_screen.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../l10n/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TextQueryScreen extends StatefulWidget {
  const TextQueryScreen({super.key});

  @override
  _TextQueryScreenState createState() => _TextQueryScreenState();
}

class _TextQueryScreenState extends State<TextQueryScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  final TextEditingController _controller = TextEditingController();
  String? _previousQuery;
  dynamic _previousResponse;
  bool _hasReadArguments = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    _controller.addListener(() {
      setState(() {});
    });
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Microphone error: ${error.errorMsg}')),
          );
        },
      );

      if (available) {
        setState(() => _isListening = true);

        _speech.listen(
          localeId: 'hi_IN',
          onResult: (result) {
            final newText = result.recognizedWords;

            _controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: newText.length),
            );

            if (result.finalResult) {
              setState(() => _isListening = false);
              _speech.stop();

              if (_controller.text.trim().isNotEmpty) {
                Future.delayed(const Duration(milliseconds: 400), _sendQuery);
              }
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read route arguments only once, after dependencies are available
    if (!_hasReadArguments) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _previousQuery = args?['previousQuery'] as String?;
      _previousResponse = args?['previousResponse'];
      
      if (_previousQuery != null) {
        _controller.text = _previousQuery!;
      }
      
      _hasReadArguments = true;
    }
  }

  @override
  void dispose() {
    _speech.stop(); // ✅ stop mic safely
    _controller.dispose();
    super.dispose();
  }

  void _sendQuery() {
    if (_controller.text.trim().isNotEmpty) {
      FocusScope.of(context).unfocus(); // hide keyboard


      final currentLang =
          Localizations.localeOf(context).languageCode;

      Navigator.pushNamed(
        context,
        '/processing',
        arguments: {
          'query': _controller.text.trim(),
          'type': 'text',
          'language': currentLang,
        },
      );
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('text_query_title')),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_previousQuery != null) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green.shade700, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.t('previous_question', params: {'question': _previousQuery ?? ''}),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],
              Text(
                _previousQuery != null
                    ? loc.t('ask_next')
                    : loc.t('ask_question'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: loc.t('text_hint'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: EdgeInsets.all(16),

                    suffixIcon: IconButton(
                      icon: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _isListening
                              ? Colors.red.withOpacity(0.2)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: _isListening ? Colors.red : Colors.green,
                        ),
                      ),
                      onPressed: _toggleListening,
                    ),
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _controller.text.trim().isEmpty ? null : _sendQuery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    loc.t('send'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}