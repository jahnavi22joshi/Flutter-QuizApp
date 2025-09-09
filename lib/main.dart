import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const QuizHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Question {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  Question({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });
}

class QuizHomePage extends StatefulWidget {
  const QuizHomePage({super.key});
  @override
  State<QuizHomePage> createState() => _QuizHomePageState();
}

class _QuizHomePageState extends State<QuizHomePage> {
  // Sample question bank (you can replace or load from JSON)
  final List<Question> _questions = [
    Question(
      question: 'What is the capital of France?',
      options: ['Berlin', 'Lisbon', 'Paris', 'Madrid'],
      correctIndex: 2,
      explanation: 'Paris has been France\'s capital since 508 A.D.',
    ),
    Question(
      question: 'Which language is used to build Flutter apps?',
      options: ['Kotlin', 'Dart', 'Swift', 'JavaScript'],
      correctIndex: 1,
      explanation: 'Flutter apps are written in Dart, developed by Google.',
    ),
    Question(
      question: 'Which widget is used for immutable UI in Flutter?',
      options: ['StatefulWidget', 'StatelessWidget', 'InheritedWidget', 'Builder'],
      correctIndex: 1,
      explanation: 'StatelessWidget is immutable and doesn\'t store state.',
    ),
    Question(
      question: 'Which operator is used for null-aware assignment in Dart?',
      options: ['??=', '?:', '!.', '??'],
      correctIndex: 0,
      explanation: '??= assigns a value only if the variable is null.',
    ),
    Question(
      question: 'Which of these is a NoSQL database commonly used with Node.js?',
      options: ['PostgreSQL', 'MySQL', 'MongoDB', 'SQLite'],
      correctIndex: 2,
      explanation: 'MongoDB is a popular document-oriented NoSQL DB.',
    ),
  ];

  // Quiz state
  int _currentIndex = 0;
  int _score = 0;
  final Map<int, int> _selectedAnswers = {}; // questionIndex -> selectedOptionIndex
  final Map<int, bool> _answeredCorrect = {}; // questionIndex -> correctness

  // Timer per question
  static const int questionTimeSeconds = 15;
  int _secondsLeft = questionTimeSeconds;
  Timer? _timer;

  // Flow control
  bool _isAnswered = false;
  bool _quizFinished = false;

  @override
  void initState() {
    super.initState();
    _startQuestionTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = questionTimeSeconds;
      _isAnswered = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
        _onTimeUp();
        return;
      }
      setState(() {
        _secondsLeft--;
      });
    });
  }

  void _onTimeUp() {
    // If user hasn't answered, mark as wrong (or skip)
    if (!_isAnswered) {
      _selectedAnswers[_currentIndex] = -1; // -1 -> no answer
      _answeredCorrect[_currentIndex] = false;
    }
    Future.delayed(const Duration(milliseconds: 600), () {
      _nextQuestion();
    });
  }

  void _selectAnswer(int optionIndex) {
    if (_isAnswered || _quizFinished) return;

    _timer?.cancel();
    final currentQuestion = _questions[_currentIndex];
    final isCorrect = optionIndex == currentQuestion.correctIndex;

    setState(() {
      _isAnswered = true;
      _selectedAnswers[_currentIndex] = optionIndex;
      _answeredCorrect[_currentIndex] = isCorrect;
      if (isCorrect) _score += 1;
    });

    // After short delay, move to next question automatically
    Future.delayed(const Duration(milliseconds: 800), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentIndex + 1 < _questions.length) {
      setState(() {
        _currentIndex += 1;
      });
      _startQuestionTimer();
    } else {
      _finishQuiz();
    }
  }

  void _previousQuestion() {
    if (_currentIndex == 0) return;
    setState(() {
      _currentIndex -= 1;
    });
    _startQuestionTimer();
    // If already answered, show that state (timer resets though)
    setState(() {
      // keep _isAnswered consistent with whether user already answered this question
      _isAnswered = _selectedAnswers.containsKey(_currentIndex) &&
          _selectedAnswers[_currentIndex] != -1;
    });
  }

  void _finishQuiz() {
    _timer?.cancel();
    setState(() {
      _quizFinished = true;
    });
  }

  void _restartQuiz() {
    _timer?.cancel();
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _selectedAnswers.clear();
      _answeredCorrect.clear();
      _quizFinished = false;
    });
    _startQuestionTimer();
  }

  Color _optionColor(int optionIndex) {
    if (!_isAnswered) return Colors.grey.shade200;
    final correctIndex = _questions[_currentIndex].correctIndex;
    final selected = _selectedAnswers[_currentIndex];
    if (optionIndex == correctIndex) return Colors.green.shade100;
    if (selected == optionIndex && selected != correctIndex) {
      return Colors.red.shade100;
    }
    return Colors.grey.shade200;
  }

  Widget _buildQuestionCard() {
    final q = _questions[_currentIndex];
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Question text
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Question ${_currentIndex + 1} / ${_questions.length}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              q.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),

            // Timer bar + countdown
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _secondsLeft / questionTimeSeconds,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Text('$_secondsLeft s',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 14),

            // Options
            Column(
              children: List.generate(q.options.length, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: InkWell(
                    onTap: () => _selectAnswer(i),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _optionColor(i),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade500),
                            ),
                            child: Text(String.fromCharCode(65 + i)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(q.options[i])),
                          if (_isAnswered &&
                              _questions[_currentIndex].correctIndex == i)
                            const Icon(Icons.check_circle, color: Colors.green),
                          if (_isAnswered &&
                              _selectedAnswers[_currentIndex] == i &&
                              _questions[_currentIndex].correctIndex != i)
                            const Icon(Icons.cancel, color: Colors.red),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),

            if (_isAnswered && q.explanation != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q.explanation!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Row(
      children: [
        IconButton(
          onPressed: _currentIndex > 0 ? _previousQuestion : null,
          icon: const Icon(Icons.arrow_back),
        ),
        Expanded(
          child: Text(
            _quizFinished
                ? 'Quiz finished'
                : 'Score: $_score | Answered: ${_selectedAnswers.length} / ${_questions.length}',
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          onPressed: !_quizFinished ? () => _finishQuiz() : null,
          icon: const Icon(Icons.flag),
        ),
      ],
    );
  }

  Widget _buildResultScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Score',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '$_score / ${_questions.length}',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Text(
              (_score / _questions.length * 100).toStringAsFixed(0) + '%',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _restartQuiz,
              icon: const Icon(Icons.replay),
              label: const Text('Restart Quiz'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                // navigate to review page
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReviewPage(
                      questions: _questions,
                      selectedAnswers: _selectedAnswers,
                      correctMap: _answeredCorrect,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.list),
              label: const Text('Review Answers'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _quizFinished ? _buildResultScreen() : _buildQuestionCard();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz App - MCQ'),
        centerTitle: true,
        actions: [
          if (!_quizFinished)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Center(child: Text('Q ${_currentIndex + 1}/${_questions.length}')),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: body,
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: _buildBottomBar(),
      ),
    );
  }
}

class ReviewPage extends StatelessWidget {
  final List<Question> questions;
  final Map<int, int> selectedAnswers;
  final Map<int, bool> correctMap;

  const ReviewPage({
    super.key,
    required this.questions,
    required this.selectedAnswers,
    required this.correctMap,
  });

  Color _bgFor(int qIndex, int optionIndex) {
    final correct = questions[qIndex].correctIndex;
    final selected = selectedAnswers[qIndex];
    if (optionIndex == correct) return Colors.green.shade50;
    if (selected == optionIndex && selected != correct) return Colors.red.shade50;
    return Colors.transparent;
  }

  Icon? _iconFor(int qIndex) {
    if (!selectedAnswers.containsKey(qIndex)) return null;
    final sel = selectedAnswers[qIndex]!;
    final correct = questions[qIndex].correctIndex;
    if (sel == -1) return const Icon(Icons.timelapse, color: Colors.orange);
    if (sel == correct) return const Icon(Icons.check_circle, color: Colors.green);
    return const Icon(Icons.cancel, color: Colors.red);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Answers'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: questions.length,
        itemBuilder: (context, i) {
          final q = questions[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Q${i + 1}. ${q.question}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (_iconFor(i) != null) _iconFor(i)!,
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: List.generate(q.options.length, (j) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _bgFor(i, j),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Text(String.fromCharCode(65 + j)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(q.options[j])),
                            if (j == q.correctIndex)
                              const Padding(
                                padding: EdgeInsets.only(left: 8.0),
                                child: Icon(Icons.check, color: Colors.green, size: 18),
                              )
                          ],
                        ),
                      );
                    }),
                  ),
                  if (q.explanation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(q.explanation!)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}