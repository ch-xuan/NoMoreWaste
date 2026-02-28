import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_question.dart';

class QuizRepository {
  QuizRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Hardcoded volunteer quiz questions
  static final List<QuizQuestion> _volunteerQuizQuestions = [
    // Food Safety
    QuizQuestion(
      id: 'q1',
      text: 'What is the danger zone temperature range for food storage?',
      options: ['0°C to 4°C', '5°C to 60°C', '-18°C to 0°C', '60°C to 100°C'],
      correctIndex: 1,
    ),
    QuizQuestion(
      id: 'q2',
      text: 'How long can perishable food be left at room temperature before it becomes unsafe?',
      options: ['30 minutes', '1 hour', '2 hours', '4 hours'],
      correctIndex: 2,
    ),
    QuizQuestion(
      id: 'q3',
      text: 'What should you do if a food donation has passed its expiry date?',
      options: [
        'Deliver it anyway if it looks fine',
        'Refuse to transport it and notify the donor',
        'Taste it to check if it\'s still good',
        'Only deliver if the recipient agrees'
      ],
      correctIndex: 1,
    ),
    
    // Hygiene
    QuizQuestion(
      id: 'q4',
      text: 'When should you wash your hands during food handling?',
      options: [
        'Only before starting',
        'Only after finishing',
        'Before, during (if contaminated), and after',
        'Not necessary if wearing gloves'
      ],
      correctIndex: 2,
    ),
    QuizQuestion(
      id: 'q5',
      text: 'What is the minimum hand-washing duration recommended?',
      options: ['5 seconds', '10 seconds', '20 seconds', '30 seconds'],
      correctIndex: 2,
    ),
    
    // Hot & Cold Food Handling
    QuizQuestion(
      id: 'q6',
      text: 'At what temperature should hot food be kept during transport?',
      options: ['Above 40°C', 'Above 50°C', 'Above 60°C', 'Above 70°C'],
      correctIndex: 2,
    ),
    QuizQuestion(
      id: 'q7',
      text: 'Cold food should be kept at or below what temperature?',
      options: ['10°C', '7°C', '4°C', '0°C'],
      correctIndex: 2,
    ),
    
    // Ethical Behavior
    QuizQuestion(
      id: 'q8',
      text: 'What should you do if you cannot complete a delivery you accepted?',
      options: [
        'Ignore it and let them figure it out',
        'Notify the NGO and donor immediately',
        'Wait until the pickup time has passed',
        'Ask a friend to do it without informing anyone'
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      id: 'q9',
      text: 'Can you keep some of the donated food for yourself?',
      options: [
        'Yes, volunteers deserve compensation',
        'Yes, but only if there\'s extra',
        'No, all donations must go to the recipient',
        'Only if the donor approves'
      ],
      correctIndex: 2,
    ),
    QuizQuestion(
      id: 'q10',
      text: 'What should you do if you notice the donated food is contaminated?',
      options: [
        'Deliver it and let the NGO decide',
        'Throw it away yourself',
        'Immediately notify the platform and take photos as evidence',
        'Continue the delivery but warn the recipient'
      ],
      correctIndex: 2,
    ),
  ];

  // Quiz Settings
  static const int passScore = 7; // 70%
  static const int attemptLimit = 3;
  static const int questionCount = 10;

  /// Get the volunteer quiz questions (hardcoded)
  Future<List<QuizQuestion>> getVolunteerQuiz() async {
    return _volunteerQuizQuestions;
  }

  /// Get quiz settings
  Future<Map<String, dynamic>> getQuizSettings() async {
    return {
      'passScore': passScore,
      'attemptLimit': attemptLimit,
      'questionCount': questionCount,
      'enabled': true,
    };
  }

  /// Submit Quiz Result and store attempt
  Future<void> submitQuizAttempt({
    required String uid,
    required List<int> selectedAnswers,
    required int score,
    required bool passed,
  }) async {
    final attemptId = _db.collection('quiz_attempts').doc().id;

    // Create detailed answers array
    final answers = List.generate(_volunteerQuizQuestions.length, (index) {
      return {
        'questionId': _volunteerQuizQuestions[index].id,
        'selectedIndex': selectedAnswers[index],
        'correctIndex': _volunteerQuizQuestions[index].correctIndex,
      };
    });

    // Store attempt in quiz_attempts/{uid}/attempts/{attemptId}
    await _db
        .collection('quiz_attempts')
        .doc(uid)
        .collection('attempts')
        .doc(attemptId)
        .set({
      'attemptId': attemptId,
      'scorePercent': (score / _volunteerQuizQuestions.length * 100).round(),
      'passed': passed,
      'totalQuestions': _volunteerQuizQuestions.length,
      'correctCount': score,
      'answers': answers,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update user's volunteerTest field
    final userRef = _db.collection('users').doc(uid);
    final userDoc = await userRef.get();
    final userData = userDoc.data() ?? {};
    final currentAttempts = (userData['volunteerTest']?['attemptsUsed'] ?? 0) as int;

    await userRef.update({
      'volunteerTest.passed': passed,
      'volunteerTest.scorePercent': (score / _volunteerQuizQuestions.length * 100).round(),
      'volunteerTest.attemptsUsed': currentAttempts + 1,
      'volunteerTest.lastAttemptAt': FieldValue.serverTimestamp(),
      if (passed) 'volunteerTest.passedAt': FieldValue.serverTimestamp(),
      // verificationStatus remains pending until Admin approves
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get user's quiz attempts
  Future<List<Map<String, dynamic>>> getUserAttempts(String uid) async {
    final snapshot = await _db
        .collection('quiz_attempts')
        .doc(uid)
        .collection('attempts')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Get attempts count for a user
  Future<int> getAttemptsCount(String uid) async {
    final snapshot = await _db
        .collection('quiz_attempts')
        .doc(uid)
        .collection('attempts')
        .get();
    
    return snapshot.docs.length;
  }
}
