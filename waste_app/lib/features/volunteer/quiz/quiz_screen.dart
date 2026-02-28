import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/quiz_question.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../home/home_shell.dart';
import '../../../data/models/user_role.dart';

class VolunteerQuizScreen extends StatefulWidget {
  const VolunteerQuizScreen({super.key});

  @override
  State<VolunteerQuizScreen> createState() => _VolunteerQuizScreenState();
}

class _VolunteerQuizScreenState extends State<VolunteerQuizScreen> {
  final _repo = QuizRepository();
  bool _isLoading = true;
  String? _error;

  List<QuizQuestion> _questions = [];
  int _passScore = 0;
  int _attemptLimit = 3;
  int _currentAttempts = 0;
  
  int _currentQuestionIndex = 0;
  final List<int> _selectedAnswers = []; // Stores selected option index for each question
  bool _submitted = false;
  bool _passed = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final questions = await _repo.getVolunteerQuiz();
      final settings = await _repo.getQuizSettings();
      final attemptsCount = await _repo.getAttemptsCount(FirebaseAuth.instance.currentUser!.uid);

      setState(() {
        _questions = questions;
        _passScore = settings['passScore'] as int;
        _attemptLimit = settings['attemptLimit'] as int;
        _currentAttempts = attemptsCount;
        _selectedAnswers.addAll(List.filled(questions.length, -1)); // -1 = not answered
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _submitAnswer() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _calculateResult();
    }
  }

  Future<void> _calculateResult() async {
    setState(() => _isLoading = true);
    
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i].correctIndex) {
        score++;
      }
    }

    final passed = score >= _passScore;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      await _repo.submitQuizAttempt(
        uid: uid,
        selectedAnswers: _selectedAnswers,
        score: score,
        passed: passed,
      );
      
      setState(() {
        _submitted = true;
        _passed = passed;
        _score = score;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to submit results: $e";
        _isLoading = false;
      });
    }
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeShell(
          role: UserRole.volunteer,
          displayNameOrOrg: 'Volunteer',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('Error: $_error')),
      );
    }

    // Check if attempts exceeded
    if (!_submitted && _currentAttempts >= _attemptLimit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Volunteer Verification')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Attempt Limit Reached',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'You have used all $_attemptLimit attempts. Please contact support.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Volunteer Verification')),
        body: const Center(
          child: Text('No quiz questions available. Please contact admin.'),
        ),
      );
    }
    
    if (_submitted) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _passed ? Icons.check_circle : Icons.cancel,
                  size: 80,
                  color: _passed ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  _passed ? 'Congratulations!' : 'Test Failed',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'You scored $_score / ${_questions.length}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  _passed 
                      ? 'You are now a verified volunteer.' 
                      : 'You did not meet the passing score of $_passScore. You have ${_attemptLimit - _currentAttempts - 1} attempt(s) remaining.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 32),
                if (_passed)
                  ElevatedButton(
                    onPressed: _navigateToDashboard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Go to Dashboard', style: TextStyle(color: Colors.white)),
                  )
                else if (_currentAttempts + 1 < _attemptLimit)
                  ElevatedButton(
                    onPressed: () {
                      // Reload quiz
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const VolunteerQuizScreen()),
                      );
                    },
                    child: const Text('Retake Test'),
                  )
                else
                  ElevatedButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text('Sign Out'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final selectedOption = _selectedAnswers[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentQuestionIndex + 1}/${_questions.length}'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF2FBF6),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey[300],
              color: const Color(0xFF2563EB),
            ),
            const SizedBox(height: 24),
            Text(
              question.text,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ...List.generate(question.options.length, (index) {
              final isSelected = selectedOption == index;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedAnswers[_currentQuestionIndex] = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: isSelected ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            question.options[index],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            Text(
              'Attempt ${_currentAttempts + 1} of $_attemptLimit',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: selectedOption != -1 ? _submitAnswer : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF2563EB),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(
                _currentQuestionIndex == _questions.length - 1 ? 'Submit' : 'Next Question',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
