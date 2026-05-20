import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceQueryScreen extends StatefulWidget {
  const VoiceQueryScreen({super.key});

  @override
  _VoiceQueryScreenState createState() => _VoiceQueryScreenState();
}

class _VoiceQueryScreenState extends State<VoiceQueryScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcribedText = '';
  bool _hasTranscribed = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
              _hasTranscribed = _transcribedText.isNotEmpty;
            });
          }
        },
      );
      if (available) {
        setState(() {
          _isListening = true;
          _transcribedText = '';
          _hasTranscribed = false;
        });
        _speech.listen(
          onResult: (val) {
            setState(() {
              _transcribedText = val.recognizedWords;
            });

            // if speech stops or final result received
            if (val.finalResult) {
              setState(() {
                _hasTranscribed = _transcribedText.isNotEmpty;
                _isListening = false;
              });
            }
          },
          localeId: 'hi_IN', // Hindi locale
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('माइक्रोफोन उपलब्ध नहीं है')),
        );
      }
    } else {
      setState(() {
        _isListening = false;
      });
      _speech.stop();
      if (_transcribedText.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 400), () {
          _confirmAndProceed();
        });
      }
      if (_transcribedText.isNotEmpty) {
        _hasTranscribed = true;
      }
    }
  }

  void _recordAgain() {
    setState(() {
      _transcribedText = '';
      _hasTranscribed = false;
      _isListening = false;
    });
  }

  void _confirmAndProceed() {
    if (_transcribedText.trim().isEmpty) return;

    Navigator.pushReplacementNamed(
      context,
      '/processing',
      arguments: {
        'query': _transcribedText.trim(),
        'type': 'voice',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('आवाज़ से पूछें'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isListening)
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mic,
                            size: 60,
                            color: Colors.blue,
                          ),
                        )
                      else if (_hasTranscribed)
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            size: 60,
                            color: Colors.green,
                          ),
                        )
                      else
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mic_none,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                      SizedBox(height: 30),
                      Text(
                        _isListening
                            ? 'बोलें… आपका सवाल रिकॉर्ड किया जा रहा है'
                            : _hasTranscribed
                                ? 'आपने कहा:'
                                : 'रिकॉर्डिंग शुरू करने के लिए बटन दबाएं',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_hasTranscribed && _transcribedText.isNotEmpty) ...[
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            '"$_transcribedText"',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade800,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_hasTranscribed) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _confirmAndProceed,
                    icon: Icon(Icons.check),
                    label: Text('पुष्टि करें'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _recordAgain,
                    icon: Icon(Icons.refresh),
                    label: Text('फिर से रिकॉर्ड करें'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _listen,
                    icon: Icon(_isListening ? Icons.stop : Icons.mic),
                    label: Text(_isListening ? 'रोकें' : 'रिकॉर्ड करें'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isListening ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}