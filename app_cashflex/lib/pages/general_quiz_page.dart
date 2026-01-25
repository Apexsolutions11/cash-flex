import 'dart:async';
import '../theme/app_theme.dart';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme/app_theme.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../theme/app_theme.dart';

import '../models/user_data_model.dart';
import '../theme/app_theme.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../services/mintegral_ad_service.dart';
import '../theme/app_theme.dart';
import '../utils/helper/toast_manager.dart';
import '../theme/app_theme.dart';
import '../utils/constant/constant.dart';
import '../theme/app_theme.dart';

enum QuizState { start, playing, gameOver }

class Question {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String category;

  Question({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.category,
  });
}

class GeneralQuizPage extends ConsumerStatefulWidget {
  const GeneralQuizPage({super.key});

  @override
  ConsumerState<GeneralQuizPage> createState() => _GeneralQuizPageState();
}

class _GeneralQuizPageState extends ConsumerState<GeneralQuizPage> {
  QuizState _quizState = QuizState.start;

  List<Question> _currentQuestions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  int? _selectedAnswer;
  bool _hasAnswered = false;

  Timer? _timer;
  int _timeLeft = 15;
  final int _timePerQuestion = 15;
  final int _totalQuestions = 5;

  // Question bank
  final List<Question> _questionBank = [
    // Science
    Question(
      question: 'What is the chemical symbol for gold?',
      options: ['Go', 'Au', 'Gd', 'Ag'],
      correctIndex: 1,
      category: 'Science',
    ),
    Question(
      question: 'What planet is known as the Red Planet?',
      options: ['Venus', 'Jupiter', 'Mars', 'Saturn'],
      correctIndex: 2,
      category: 'Science',
    ),
    Question(
      question: 'How many bones are in the human body?',
      options: ['186', '206', '226', '246'],
      correctIndex: 1,
      category: 'Science',
    ),
    Question(
      question: 'What is the speed of light?',
      options: ['300,000 km/s', '150,000 km/s', '450,000 km/s', '600,000 km/s'],
      correctIndex: 0,
      category: 'Science',
    ),
    Question(
      question: 'What is the largest organ in the human body?',
      options: ['Heart', 'Brain', 'Liver', 'Skin'],
      correctIndex: 3,
      category: 'Science',
    ),

    // History
    Question(
      question: 'In which year did World War II end?',
      options: ['1943', '1944', '1945', '1946'],
      correctIndex: 2,
      category: 'History',
    ),
    Question(
      question: 'Who was the first President of the United States?',
      options: [
        'Thomas Jefferson',
        'George Washington',
        'John Adams',
        'Benjamin Franklin',
      ],
      correctIndex: 1,
      category: 'History',
    ),
    Question(
      question: 'The Great Wall of China was built during which dynasty?',
      options: ['Ming Dynasty', 'Qing Dynasty', 'Han Dynasty', 'Tang Dynasty'],
      correctIndex: 0,
      category: 'History',
    ),
    Question(
      question: 'Who painted the Mona Lisa?',
      options: ['Michelangelo', 'Leonardo da Vinci', 'Raphael', 'Donatello'],
      correctIndex: 1,
      category: 'History',
    ),
    Question(
      question: 'When did the Titanic sink?',
      options: ['1910', '1911', '1912', '1913'],
      correctIndex: 2,
      category: 'History',
    ),

    // Geography
    Question(
      question: 'What is the capital of Australia?',
      options: ['Sydney', 'Melbourne', 'Canberra', 'Brisbane'],
      correctIndex: 2,
      category: 'Geography',
    ),
    Question(
      question: 'Which is the longest river in the world?',
      options: ['Amazon', 'Nile', 'Yangtze', 'Mississippi'],
      correctIndex: 1,
      category: 'Geography',
    ),
    Question(
      question: 'How many continents are there?',
      options: ['5', '6', '7', '8'],
      correctIndex: 2,
      category: 'Geography',
    ),
    Question(
      question: 'What is the smallest country in the world?',
      options: ['Monaco', 'Vatican City', 'San Marino', 'Liechtenstein'],
      correctIndex: 1,
      category: 'Geography',
    ),
    Question(
      question: 'Mount Everest is located in which mountain range?',
      options: ['Alps', 'Andes', 'Himalayas', 'Rockies'],
      correctIndex: 2,
      category: 'Geography',
    ),

    // Sports
    Question(
      question: 'How many players are on a soccer team?',
      options: ['9', '10', '11', '12'],
      correctIndex: 2,
      category: 'Sports',
    ),
    Question(
      question: 'In which sport would you perform a slam dunk?',
      options: ['Volleyball', 'Basketball', 'Tennis', 'Baseball'],
      correctIndex: 1,
      category: 'Sports',
    ),
    Question(
      question: 'How many rings are on the Olympic flag?',
      options: ['4', '5', '6', '7'],
      correctIndex: 1,
      category: 'Sports',
    ),
    Question(
      question: 'What is the national sport of Japan?',
      options: ['Karate', 'Judo', 'Sumo Wrestling', 'Kendo'],
      correctIndex: 2,
      category: 'Sports',
    ),
    Question(
      question: 'How long is a marathon?',
      options: ['26.2 miles', '20 miles', '30 miles', '25 miles'],
      correctIndex: 0,
      category: 'Sports',
    ),

    // Entertainment
    Question(
      question: 'Who directed the movie "Titanic"?',
      options: [
        'Steven Spielberg',
        'James Cameron',
        'Christopher Nolan',
        'Martin Scorsese',
      ],
      correctIndex: 1,
      category: 'Entertainment',
    ),
    Question(
      question: 'What is the highest-grossing film of all time?',
      options: ['Titanic', 'Avatar', 'Avengers: Endgame', 'Star Wars'],
      correctIndex: 1,
      category: 'Entertainment',
    ),
    Question(
      question: 'How many Harry Potter books are there?',
      options: ['5', '6', '7', '8'],
      correctIndex: 2,
      category: 'Entertainment',
    ),
    Question(
      question: 'Who sang "Thriller"?',
      options: ['Prince', 'Michael Jackson', 'Elvis Presley', 'Madonna'],
      correctIndex: 1,
      category: 'Entertainment',
    ),
    Question(
      question: 'What year did Netflix launch?',
      options: ['1995', '1997', '1999', '2001'],
      correctIndex: 1,
      category: 'Entertainment',
    ),

    // General Knowledge
    Question(
      question: 'What is the largest ocean on Earth?',
      options: ['Atlantic', 'Indian', 'Arctic', 'Pacific'],
      correctIndex: 3,
      category: 'General',
    ),
    Question(
      question: 'How many days are in a leap year?',
      options: ['364', '365', '366', '367'],
      correctIndex: 2,
      category: 'General',
    ),
    Question(
      question: 'What is the hardest natural substance on Earth?',
      options: ['Gold', 'Iron', 'Diamond', 'Platinum'],
      correctIndex: 2,
      category: 'General',
    ),
    Question(
      question: 'What language is spoken in Brazil?',
      options: ['Spanish', 'Portuguese', 'French', 'Italian'],
      correctIndex: 1,
      category: 'General',
    ),
    Question(
      question: 'How many colors are in a rainbow?',
      options: ['5', '6', '7', '8'],
      correctIndex: 2,
      category: 'General',
    ),
    Question(
      question: 'What is the currency of Japan?',
      options: ['Yuan', 'Won', 'Yen', 'Ringgit'],
      correctIndex: 2,
      category: 'General',
    ),
    Question(
      question: 'Who invented the telephone?',
      options: [
        'Thomas Edison',
        'Alexander Graham Bell',
        'Nikola Tesla',
        'Benjamin Franklin',
      ],
      correctIndex: 1,
      category: 'General',
    ),
    Question(
      question: 'What is the largest mammal in the world?',
      options: ['African Elephant', 'Blue Whale', 'Giraffe', 'Polar Bear'],
      correctIndex: 1,
      category: 'General',
    ),
    Question(
      question: 'How many sides does a hexagon have?',
      options: ['5', '6', '7', '8'],
      correctIndex: 1,
      category: 'General',
    ),
    Question(
      question: 'What is the boiling point of water?',
      options: ['90°C', '100°C', '110°C', '120°C'],
      correctIndex: 1,
      category: 'General',
    ),
    Question(
      question: 'Which planet is closest to the Sun?',
      options: ['Venus', 'Earth', 'Mercury', 'Mars'],
      correctIndex: 2,
      category: 'General',
    ),
    Question(
      question: 'What is the capital of France?',
      options: ['London', 'Berlin', 'Paris', 'Rome'],
      correctIndex: 2,
      category: 'General',
    ),
    Question(
      question: 'How many minutes are in a day?',
      options: ['1440', '1340', '1540', '1240'],
      correctIndex: 0,
      category: 'General',
    ),
    Question(
      question: 'What is the largest desert in the world?',
      options: ['Sahara', 'Arabian', 'Gobi', 'Antarctic'],
      correctIndex: 3,
      category: 'General',
    ),
    Question(
      question: 'Who wrote "Romeo and Juliet"?',
      options: [
        'Charles Dickens',
        'William Shakespeare',
        'Jane Austen',
        'Mark Twain',
      ],
      correctIndex: 1,
      category: 'General',
    ),
    Question(
      question: 'What is the smallest prime number?',
      options: ['0', '1', '2', '3'],
      correctIndex: 2,
      category: 'General',
    ),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startQuiz() {
    // Select random questions
    final shuffled = List<Question>.from(_questionBank)..shuffle();
    _currentQuestions = shuffled.take(_totalQuestions).toList();

    setState(() {
      _quizState = QuizState.playing;
      _currentQuestionIndex = 0;
      _score = 0;
      _correctAnswers = 0;
      _selectedAnswer = null;
      _hasAnswered = false;
      _timeLeft = _timePerQuestion;
    });

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _nextQuestion();
      }
    });
  }

  void _selectAnswer(int index) {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswer = index;
      _hasAnswered = true;
    });

    _timer?.cancel();

    if (index == _currentQuestions[_currentQuestionIndex].correctIndex) {
      _correctAnswers++;
      _score += 10;
    }

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _currentQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _hasAnswered = false;
        _timeLeft = _timePerQuestion;
      });
      _startTimer();
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    _timer?.cancel();
    setState(() {
      _quizState = QuizState.gameOver;
    });

    // Increment game count
    try {
      await ApiService.incrementGameCount();
      ref.invalidate(currentUserProvider);
    } catch (e) {
      debugPrint('Error incrementing game count: $e');
    }

    _showResultDialog();
  }

  void _showResultDialog() {
    final userAsync = ref.read(currentUserProvider);
    int dailyGameCount = 0;
    userAsync.when(
      data: (user) => dailyGameCount = user?.dailyGameCount ?? 0,
      loading: () => dailyGameCount = 0,
      error: (_, __) => dailyGameCount = 0,
    );
    final gameLimit = dailyGameLimit;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ResultDialog(
        score: _score,
        correctAnswers: _correctAnswers,
        totalQuestions: _totalQuestions,
        dailyGameCount: dailyGameCount,
        dailyGameLimit: gameLimit,
        onPlayAgain: () {
          // Navigator.of(context).pop();
          _startQuiz();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(TablerIcons.arrow_left, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'General Quiz',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildUserStatusChips(userAsync),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildUserStatusChips(AsyncValue<UserDataModel?> userAsync) {
    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final dailyGameCount = user.dailyGameCount ?? 0;
        final gameLimit = dailyGameLimit;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Coins chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/coin.png', width: 16, height: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${user.coins}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Games today chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    TablerIcons.device_gamepad_2,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$dailyGameCount/$gameLimit',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBody() {
    if (_quizState == QuizState.start) {
      return _buildStartScreen();
    }
    return _buildQuizScreen();
  }

  Widget _buildStartScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF10B981).withOpacity(0.05),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Game Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    TablerIcons.brain,
                    size: 80,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'General Knowledge Quiz',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Test your knowledge!',
                  style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Game Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Quiz Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoItem(
                          TablerIcons.list_numbers,
                          '$_totalQuestions',
                          'Questions',
                          const Color(0xFF10B981),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoItem(
                          TablerIcons.clock,
                          '$_timePerQuestion sec',
                          'Per Question',
                          const Color(0xFF3B82F6),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoItem(
                          TablerIcons.coin,
                          'Up to 20',
                          'Coins Reward',
                          const Color(0xFFFBBF24),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                // Start Button
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: AppTheme.buildGradientButton(
                      onPressed: _startQuiz,
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: const Text(
                        'Start Quiz',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQuizScreen() {
    final question = _currentQuestions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _totalQuestions;

    return SafeArea(
      child: Column(
        children: [
          // Progress and Timer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1}/$_totalQuestions',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _timeLeft <= 5
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            TablerIcons.clock,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_timeLeft',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF10B981),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          // Question Card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                          ),
                          child: Text(
                            question.category,
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          question.question,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Options
                  ...List.generate(
                    question.options.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildOptionButton(
                        question.options[index],
                        index,
                        question.correctIndex,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Score
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  TablerIcons.trophy,
                  color: Color(0xFFFBBF24),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Score: $_score',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String option, int index, int correctIndex) {
    Color? backgroundColor;
    Color? borderColor;
    Color? textColor;

    if (_hasAnswered) {
      if (index == correctIndex) {
        backgroundColor = const Color(0xFF10B981).withOpacity(0.1);
        borderColor = const Color(0xFF10B981);
        textColor = const Color(0xFF10B981);
      } else if (index == _selectedAnswer) {
        backgroundColor = const Color(0xFFEF4444).withOpacity(0.1);
        borderColor = const Color(0xFFEF4444);
        textColor = const Color(0xFFEF4444);
      }
    } else if (index == _selectedAnswer) {
      backgroundColor = const Color(0xFF3B82F6).withOpacity(0.1);
      borderColor = const Color(0xFF3B82F6);
      textColor = const Color(0xFF3B82F6);
    }

    return InkWell(
      onTap: () => _selectAnswer(index),
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          border: Border.all(
            color: borderColor ?? const Color(0xFFE2E8F0),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (textColor ?? const Color(0xFF64748B)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: TextStyle(
                    color: textColor ?? const Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? const Color(0xFF1E293B),
                ),
                overflow: TextOverflow.visible,
                softWrap: true,
                maxLines: 3,
              ),
            ),
            if (_hasAnswered && index == correctIndex)
              const Icon(TablerIcons.check, color: Color(0xFF10B981), size: 24),
            if (_hasAnswered &&
                index == _selectedAnswer &&
                index != correctIndex)
              const Icon(TablerIcons.x, color: Color(0xFFEF4444), size: 24),
          ],
        ),
      ),
    );
  }
}

class _ResultDialog extends ConsumerStatefulWidget {
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final int dailyGameCount;
  final int dailyGameLimit;
  final VoidCallback onPlayAgain;

  const _ResultDialog({
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.dailyGameCount,
    required this.dailyGameLimit,
    required this.onPlayAgain,
  });

  @override
  ConsumerState<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends ConsumerState<_ResultDialog> {
  bool _hasClaimed = false;
  bool _isClaiming = false;
  bool _isRetrying = false;

  Future<void> _claimCoins() async {
    if (_isClaiming || _hasClaimed) return;

    setState(() => _isClaiming = true);

    try {
      final coins = _calculateCoins();
      if (coins <= 0) {
        setState(() => _hasClaimed = true);
        setState(() => _isClaiming = false);
        return;
      }

      // Try to show interstitial ad (but don't wait for success)
      if (MintegralAdService.isInitialized) {
        try {
          await MintegralAdService.showInterstitialAd();
        } catch (e) {
          debugPrint('Error showing interstitial ad: $e');
        }
      }

      // Always award coins regardless of ad success/failure
      await ApiService.claimCoins(coins, 'GENERAL_QUIZ');
      ref.invalidate(currentUserProvider);

      if (mounted) {
        ToastManager.success('Congratulations! You earned $coins coins! 🎉');
      }

      setState(() => _hasClaimed = true);

      // Automatically restart the game after a short delay
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pop();
        widget.onPlayAgain();
      }
    } catch (e) {
      debugPrint('Error claiming coins: $e');
      // Ad failed - silently close dialog and restart game without rewarding coins
      if (mounted) {
        Navigator.of(context).pop();
        widget.onPlayAgain();
      }
    }
  }

  Future<void> _retry() async {
    if (_isRetrying) return;

    setState(() => _isRetrying = true);

    try {
      // Show interstitial ad
      if (MintegralAdService.isInitialized) {
        try {
          await MintegralAdService.showInterstitialAd();
        } catch (e) {
          debugPrint('Error showing interstitial ad: $e');
        }
      }

      // Restart the game
      if (mounted) {
        Navigator.of(context).pop();
        widget.onPlayAgain();
      }
    } catch (e) {
      debugPrint('Error retrying: $e');
      // Restart the game even if ad fails
      if (mounted) {
        Navigator.of(context).pop();
        widget.onPlayAgain();
      }
    }
  }

  int _calculateCoins() {
    final accuracy = (widget.correctAnswers / widget.totalQuestions * 100)
        .round();
    if (accuracy >= 90) return 20;
    if (accuracy >= 70) return 15;
    if (accuracy >= 50) return 10;
    if (accuracy >= 30) return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = (widget.correctAnswers / widget.totalQuestions * 100)
        .round();
    final coins = _calculateCoins();
    final isPerfect = widget.correctAnswers == widget.totalQuestions;

    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          boxShadow: AppTheme.cardShadowMedium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isPerfect
                    ? const Color(0xFFFBBF24).withOpacity(0.1)
                    : const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPerfect ? TablerIcons.trophy : TablerIcons.check,
                size: 48,
                color: isPerfect
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              isPerfect ? 'Perfect Score!' : 'Quiz Complete!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 24,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 24),
            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                border: Border.all(
                  color: theme.colorScheme.surfaceContainerHighest,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildStatRow('Score', '${widget.score}'),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    'Correct Answers',
                    '${widget.correctAnswers}/${widget.totalQuestions}',
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow('Accuracy', '$accuracy%'),
                  if (coins > 0) ...[
                    const SizedBox(height: 12),
                    _buildStatRow('Coins Earned', '+$coins'),
                  ],
                  const SizedBox(height: 12),
                  _buildStatRow(
                    'Games Today',
                    '${widget.dailyGameCount}/${widget.dailyGameLimit}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Show "Claim Coins" button only if coins > 0 (win case)
            if (coins > 0 && !_hasClaimed) ...[
              SizedBox(
                width: double.infinity,
                child: AppTheme.buildGradientButton(
                  onPressed: _isClaiming ? null : _claimCoins,
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.warningOrange,
                      AppTheme.warningOrange.withOpacity(0.8),
                    ],
                  ),
                  child: _isClaiming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/coin.png',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Claim $coins Coins',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ] else if (coins == 0) ...[
              // Show "Retry" button only if coins == 0 (loss case)
              SizedBox(
                width: double.infinity,
                child: AppTheme.buildGradientButton(
                  onPressed: _isRetrying ? null : _retry,
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: _isRetrying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
