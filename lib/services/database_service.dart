import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/streak_data.dart';
import '../models/task.dart';
import '../core/app_constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ralph_cos.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add mantras table
      await db.execute('''
        CREATE TABLE mantras(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL UNIQUE,
          mantra TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      // Add challenge tables
      await db.execute('''
        CREATE TABLE challenge_config(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          template TEXT NOT NULL,
          startDate TEXT,
          currentDay INTEGER DEFAULT 0,
          isActive INTEGER DEFAULT 0,
          updatedAt TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE challenge_completions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          day INTEGER NOT NULL,
          date TEXT NOT NULL,
          dailyTask TEXT NOT NULL,
          reflection TEXT NOT NULL,
          emotion TEXT NOT NULL,
          oneSentence TEXT NOT NULL,
          aiSummary TEXT,
          completedAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      // Add evening reflections table
      await db.execute('''
        CREATE TABLE evening_reflections(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL UNIQUE,
          mantra TEXT NOT NULL,
          keptVow INTEGER NOT NULL,
          whatAvoided TEXT,
          inboxZero INTEGER NOT NULL,
          taskZero INTEGER NOT NULL,
          guiltZero INTEGER NOT NULL,
          reflection TEXT,
          createdAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      // Add day logs table for "Won/Lost" tracking
      await db.execute('''
        CREATE TABLE day_logs(
          date TEXT PRIMARY KEY,
          status TEXT CHECK(status IN ('WON', 'LOST')),
          locked INTEGER DEFAULT 0,
          updatedAt TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Streak table
    await db.execute('''
      CREATE TABLE streak(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        currentStreak INTEGER NOT NULL,
        passesAvailable INTEGER NOT NULL,
        lastCheckIn TEXT NOT NULL,
        totalDays INTEGER NOT NULL,
        longestStreak INTEGER NOT NULL
      )
    ''');

    // Tasks table
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        isCompleted INTEGER NOT NULL,
        dueDate TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Mantras table
    await db.execute('''
      CREATE TABLE mantras(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        mantra TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Challenge config table
    await db.execute('''
      CREATE TABLE challenge_config(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        template TEXT NOT NULL,
        startDate TEXT,
        currentDay INTEGER DEFAULT 0,
        isActive INTEGER DEFAULT 0,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Challenge completions table
    await db.execute('''
      CREATE TABLE challenge_completions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day INTEGER NOT NULL,
        date TEXT NOT NULL,
        dailyTask TEXT NOT NULL,
        reflection TEXT NOT NULL,
        emotion TEXT NOT NULL,
        oneSentence TEXT NOT NULL,
        aiSummary TEXT,
        completedAt TEXT NOT NULL
      )
    ''');

    // Evening reflections table
    await db.execute('''
      CREATE TABLE evening_reflections(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        mantra TEXT NOT NULL,
        keptVow INTEGER NOT NULL,
        whatAvoided TEXT,
        inboxZero INTEGER NOT NULL,
        taskZero INTEGER NOT NULL,
        guiltZero INTEGER NOT NULL,
        reflection TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Day logs table
    await db.execute('''
      CREATE TABLE day_logs(
        date TEXT PRIMARY KEY,
        status TEXT CHECK(status IN ('WON', 'LOST')),
        locked INTEGER DEFAULT 0,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Insert initial streak data
    await db.insert('streak', {
      'currentStreak': 0,
      'passesAvailable': 0,
      'lastCheckIn': DateTime.now().toIso8601String(),
      'totalDays': 0,
      'longestStreak': 0,
    });
  }

  // Streak operations
  Future<StreakData?> getStreakData() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('streak', limit: 1);

    if (maps.isEmpty) return null;
    return StreakData.fromMap(maps.first);
  }

  Future<void> updateStreakData(StreakData streak) async {
    final db = await database;
    await db.update(
      'streak',
      streak.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> checkIn() async {
    final streak = await getStreakData();
    if (streak == null) return;

    final now = DateTime.now();
    final lastCheckIn = streak.lastCheckIn;
    final daysSinceLastCheckIn = now.difference(lastCheckIn).inDays;

    if (daysSinceLastCheckIn == 1) {
      // Consecutive day
      int newStreak = streak.currentStreak + 1;
      int newPasses = streak.passesAvailable;

      // Award pass every X days (max Y)
      if (newStreak % AppConstants.daysPerPass == 0 && 
          newPasses < AppConstants.maxPasses) {
        newPasses++;
      }

      await updateStreakData(streak.copyWith(
        currentStreak: newStreak,
        passesAvailable: newPasses,
        lastCheckIn: now,
        totalDays: streak.totalDays + 1,
        longestStreak: newStreak > streak.longestStreak ? newStreak : streak.longestStreak,
      ));
    } else if (daysSinceLastCheckIn > 1) {
      // Missed a day - check for pass
      if (streak.passesAvailable > 0) {
        // Use a pass
        await updateStreakData(streak.copyWith(
          passesAvailable: streak.passesAvailable - 1,
          lastCheckIn: now,
          totalDays: streak.totalDays + 1,
        ));
      } else {
        // Streak broken
        await updateStreakData(streak.copyWith(
          currentStreak: 1,
          lastCheckIn: now,
          totalDays: streak.totalDays + 1,
        ));
      }
    }
    // If same day, do nothing
  }

  // Task operations
  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertTasks(List<Task> tasks) async {
    final db = await database;
    final batch = db.batch();
    for (var task in tasks) {
      batch.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<List<Task>> getTasksByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'category = ?',
      whereArgs: [category],
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllTasks() async {
    final db = await database;
    await db.delete('tasks');
  }

  // Mantra operations
  Future<String?> getTodayMantra() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'mantras',
      where: 'date = ?',
      whereArgs: [today],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first['mantra'] as String;
  }

  Future<void> saveMantra(String mantra) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'mantras',
      {
        'date': today,
        'mantra': mantra,
        'createdAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Challenge operations
  Future<Map<String, dynamic>?> getChallengeConfig() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'challenge_config',
      orderBy: 'id DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<void> saveChallengeConfig({
    required String template,
    required bool isActive,
    String? startDate,
    int currentDay = 0,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'challenge_config',
      {
        'template': template,
        'startDate': startDate,
        'currentDay': currentDay,
        'isActive': isActive ? 1 : 0,
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateChallengeDay(int day) async {
    final db = await database;
    final config = await getChallengeConfig();
    if (config == null) return;

    await db.update(
      'challenge_config',
      {
        'currentDay': day,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [config['id']],
    );
  }

  Future<void> saveChallengeCompletion({
    required int day,
    required String dailyTask,
    required String reflection,
    required String emotion,
    required String oneSentence,
    String? aiSummary,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final today = now.split('T')[0];

    await db.insert(
      'challenge_completions',
      {
        'day': day,
        'date': today,
        'dailyTask': dailyTask,
        'reflection': reflection,
        'emotion': emotion,
        'oneSentence': oneSentence,
        'aiSummary': aiSummary,
        'completedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getChallengeCompletionForDay(int day) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'challenge_completions',
      where: 'day = ?',
      whereArgs: [day],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<List<Map<String, dynamic>>> getAllChallengeCompletions() async {
    final db = await database;
    return await db.query(
      'challenge_completions',
      orderBy: 'day ASC',
    );
  }

  Future<int> getChallengeStreak() async {
    final completions = await getAllChallengeCompletions();
    if (completions.isEmpty) return 0;

    // Count consecutive days from day 1
    int streak = 0;
    for (int i = 1; i <= 30; i++) {
      final completion = completions.where((c) => c['day'] == i).firstOrNull;
      if (completion == null) break;
      streak++;
    }

    return streak;
  }

  // Evening reflection operations
  Future<Map<String, dynamic>?> getTodayEveningReflection() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'evening_reflections',
      where: 'date = ?',
      whereArgs: [today],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<void> saveEveningReflection({
    required String mantra,
    required bool keptVow,
    required String whatAvoided,
    required bool inboxZero,
    required bool taskZero,
    required bool guiltZero,
    String? reflection,
  }) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'evening_reflections',
      {
        'date': today,
        'mantra': mantra,
        'keptVow': keptVow ? 1 : 0,
        'whatAvoided': whatAvoided,
        'inboxZero': inboxZero ? 1 : 0,
        'taskZero': taskZero ? 1 : 0,
        'guiltZero': guiltZero ? 1 : 0,
        'reflection': reflection,
        'createdAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Day log operations
  Future<Map<String, dynamic>?> getDayLog(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'day_logs',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<void> saveDayLog({
    required String date,
    required String status,
    bool locked = false,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'day_logs',
      {
        'date': date,
        'status': status,
        'locked': locked ? 1 : 0,
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> lockDay(String date) async {
    final db = await database;
    await db.update(
      'day_logs',
      {'locked': 1, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  Future<List<Map<String, dynamic>>> getAllDayLogs() async {
    final db = await database;
    return await db.query('day_logs', orderBy: 'date DESC');
  }
}
