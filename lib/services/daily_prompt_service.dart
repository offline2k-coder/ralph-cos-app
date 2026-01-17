class DailyPromptService {
  static final DailyPromptService _instance = DailyPromptService._internal();
  factory DailyPromptService() => _instance;
  DailyPromptService._internal();

  final List<Map<String, String>> _prompts = [
    {
      'question': 'What are you avoiding right now?',
      'action': 'Face it. Name it. Own it.',
    },
    {
      'question': 'What would you do if you weren\'t afraid?',
      'action': 'Fear is your enemy. Eliminate it.',
    },
    {
      'question': 'What\'s the ONE thing that would make today great?',
      'action': 'Focus. Execute. No excuses.',
    },
    {
      'question': 'What distraction is stealing your time?',
      'action': 'Cut it out. Now.',
    },
    {
      'question': 'Who do you need to become to achieve your vision?',
      'action': 'Embody that person today.',
    },
    {
      'question': 'What are you tolerating that you shouldn\'t?',
      'action': 'Raise your standards. Immediately.',
    },
    {
      'question': 'What\'s the hard conversation you\'re avoiding?',
      'action': 'Have it. Today.',
    },
    {
      'question': 'What would the future you regret NOT doing today?',
      'action': 'Do it. No negotiation.',
    },
    {
      'question': 'What comfort zone are you clinging to?',
      'action': 'Break it. Growth happens outside comfort.',
    },
    {
      'question': 'What\'s your Anti-Vision showing you today?',
      'action': 'That\'s your Game Over. Choose differently.',
    },
  ];

  Map<String, String> getDailyPrompt() {
    // Get prompt based on day of year for consistency
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final index = dayOfYear % _prompts.length;
    return _prompts[index];
  }

  Map<String, String> getRandomPrompt() {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final index = seed % _prompts.length;
    return _prompts[index];
  }
}
