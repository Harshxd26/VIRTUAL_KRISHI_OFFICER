// screens/feedback_screen.dart
import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  bool? _isHelpful;
  bool _showThankYou = false;

  @override
  void initState() {
    super.initState();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _isHelpful = args?['helpful'] as bool?;
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _setHelpful(bool helpful) {
    setState(() {
      _isHelpful = helpful;
    });
  }

  Future<void> _submitFeedback() async {
    if (_isHelpful == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('कृपया पहले रेटिंग दें')),
      );
      return;
    }

    // Save feedback logic here (you can integrate with your backend)
    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      _showThankYou = true;
    });

    // Show thank you message for 2 seconds then navigate
    await Future.delayed(Duration(seconds: 2));

    if (mounted) {
      Navigator.popUntil(context, ModalRoute.withName('/home'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showThankYou) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.shade50,
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.green,
                    ),
                    SizedBox(height: 30),
                    Text(
                      'धन्यवाद!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'आपकी प्रतिक्रिया से हमें सुधार में मदद मिलेगी।',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('सुझाव दें'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'क्या यह सलाह उपयोगी थी?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _setHelpful(true),
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _isHelpful == true
                              ? Colors.green.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isHelpful == true
                                ? Colors.green
                                : Colors.grey.shade300,
                            width: _isHelpful == true ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.thumb_up,
                              size: 40,
                              color: _isHelpful == true
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '👍 हाँ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _isHelpful == true
                                    ? Colors.green.shade800
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _setHelpful(false),
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _isHelpful == false
                              ? Colors.red.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isHelpful == false
                                ? Colors.red
                                : Colors.grey.shade300,
                            width: _isHelpful == false ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.thumb_down,
                              size: 40,
                              color: _isHelpful == false
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '👎 नहीं',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _isHelpful == false
                                    ? Colors.red.shade800
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Text(
                'अपना सुझाव लिखें (वैकल्पिक)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _feedbackController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'अपना सुझाव लिखें...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'भेजें',
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