// image_query_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../config/app_config.dart';
import '../l10n/app_localizations.dart';

class ImageQueryScreen extends StatefulWidget {
  const ImageQueryScreen({super.key});

  @override
  _ImageQueryScreenState createState() => _ImageQueryScreenState();
}

class _ImageQueryScreenState extends State<ImageQueryScreen> {
  File? _image;
  final picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('फोटो लोड करने में त्रुटि: $e')),
      );
    }
  }

  void _sendImage() {
    if (_image == null) return;

    Navigator.pushNamed(
      context,
      '/processing',
      arguments: {
        'query': 'Analyze crop image',
        'type': 'image',
        'imagePath': _image!.path,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('image_title')),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: _image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 20),
                            Text(loc.t('image instruction')),
                          ],
                        )
                      : Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _image!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                ),
              ),
              SizedBox(height: 20),
              if (_image == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.camera_alt),
                          label: Text(loc.t('open_camera')),
                          onPressed: _isLoading
                              ? null
                              : () => _pickImage(ImageSource.camera),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.photo),
                          label: Text(loc.t('choose_gallery')),
                          onPressed: _isLoading
                              ? null
                              : () => _pickImage(ImageSource.gallery),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade300,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.refresh),
                          label: Text(loc.t('change')),
                          onPressed: _isLoading
                              ? null
                              : () => setState(() => _image = null),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.send),
                          label: Text(loc.t('send')),
                          onPressed: _sendImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 18),

                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: 3),
                        duration: const Duration(seconds: 4),
                        builder: (context, value, child) {
                          final steps = [
                            "🔍 Scanning crop image...",
                            "🦠 Detecting disease...",
                            "💊 Preparing treatment...",
                            "✅ Finalizing diagnosis..."
                          ];

                          return Text(
                            steps[value],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}