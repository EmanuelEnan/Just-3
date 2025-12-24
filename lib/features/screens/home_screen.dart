import 'package:confetti/confetti.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:just_3/core/constants/app_colors.dart';
import 'package:just_3/core/constants/app_text_style.dart';
import 'package:just_3/features/screens/history_screen.dart';
import 'package:just_3/features/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  const HomeScreen({super.key, required this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late List<bool> checkboxStates; // Use late, don't initialize here
  late List<String?> taskNames;
  // List<String?> taskNames = List.generate(3, (index) => null);

  List<AnimationController> scaleControllers = [];
  List<AnimationController> strikeControllers = [];
  List<Animation<double>> scaleAnimations = [];
  List<Animation<double>> strikeAnimations = [];
  final _myBox = Hive.box('My_Box');
  int currentStreak = 0;
  late ConfettiController _confettiController;
  bool _hasShownConfetti = false;

  bool get allCompleted => checkboxStates.every((state) => state == true);

  // Count how many tasks exist
  int get existingTasksCount => taskNames.where((task) => task != null).length;

  // Get today's date as a string key (YYYY-MM-DD)
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    print('🚀 initState called - Widget hashCode: $hashCode');

    // Firebase analytics
    FirebaseAnalytics.instance.logEvent(name: 'home_opened');

    // 1. Initialize empty lists first
    checkboxStates = List.generate(3, (index) => false);
    taskNames = List.generate(3, (index) => null);

    // Initialize confetti controller
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // 2. Initialize animation controllers
    for (int i = 0; i < 3; i++) {
      // Scale animation controller
      final scaleController = AnimationController(
        duration: Duration(milliseconds: 400),
        vsync: this,
      );

      // Strike-through animation controller
      final strikeController = AnimationController(
        duration: Duration(milliseconds: 500),
        vsync: this,
      );

      scaleControllers.add(scaleController);
      strikeControllers.add(strikeController);

      // Scale animation: 0.8 → 1.1 → 1.0
      scaleAnimations.add(
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.1), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 40),
        ]).animate(
          CurvedAnimation(parent: scaleController, curve: Curves.easeInOut),
        ),
      );

      // Strike-through animation: 0.0 → 1.0
      strikeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: strikeController, curve: Curves.easeOut),
        ),
      );
    }

    // 3. THEN load tasks from Hive
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadTasksForToday();
    });

    // 4. Schedule midnight check
    _scheduleMidnightCheck();
  }

  // Calculate streak based on history
  void _calculateStreak() {
    int streak = 0;
    DateTime currentDate = DateTime.now();

    // Check today first
    String todayKey = _getTodayKeyValue();
    Map<dynamic, dynamic>? todayData = _myBox.get(todayKey);

    if (todayData != null) {
      int completedCount = todayData['completedCount'] ?? 0;
      int totalTasks = todayData['totalTasks'] ?? 0;

      // Today must be complete (all tasks done)
      if (totalTasks == 3 && completedCount == totalTasks) {
        streak = 1;

        // Check previous days
        for (int i = 1; i < 365; i++) {
          // Check up to a year back
          DateTime previousDate = currentDate.subtract(Duration(days: i));
          String previousKey = _getDateKey(previousDate);

          Map<dynamic, dynamic>? previousData = _myBox.get(previousKey);

          if (previousData != null) {
            int prevCompleted = previousData['completedCount'] ?? 0;
            int prevTotal = previousData['totalTasks'] ?? 0;

            if (prevTotal > 0 && prevCompleted == prevTotal) {
              streak++;
            } else {
              // Streak broken
              break;
            }
          } else {
            // No data for this day, streak broken
            break;
          }
        }
      }
    }

    setState(() {
      currentStreak = streak;
    });

    // Save streak
    _myBox.put('currentStreak', streak);
    _myBox.put('lastStreakUpdate', DateTime.now().toIso8601String());
  }

  // Helper to get date key for any date
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Update your existing _getTodayKey to use the helper
  String _getTodayKeyValue() {
    return _getDateKey(DateTime.now());
  }

  // Call this whenever tasks are completed
  void _onTasksChanged() {
    _saveTasksToHive();
    _calculateStreak();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    for (var controller in scaleControllers) {
      controller.dispose();
    }
    for (var controller in strikeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTasksForToday() async {
    String todayKey = _getTodayKey();

    print('📦 Loading from Hive - Key: $todayKey');
    print('All box keys: ${_myBox.keys.toList()}');

    await Future.delayed(Duration(milliseconds: 10));

    Map<dynamic, dynamic>? todayData = _myBox.get(todayKey);

    print('Retrieved data: $todayData');

    if (todayData != null) {
      List<dynamic> savedTasks = todayData['tasks'] ?? [];
      List<dynamic> savedStates = todayData['checkboxStates'] ?? [];

      print('Saved tasks: $savedTasks');
      print('Saved states: $savedStates');

      setState(() {
        taskNames = List.generate(3, (index) {
          if (index < savedTasks.length && savedTasks[index] != null) {
            return savedTasks[index] as String?;
          }
          return null;
        });

        checkboxStates = List.generate(3, (index) {
          if (index < savedStates.length) {
            return savedStates[index] as bool;
          }
          return false;
        });
      });

      print(
        'After setState - taskNames: $taskNames, checkboxStates: $checkboxStates',
      );

      // Animation restoration
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (int i = 0; i < checkboxStates.length; i++) {
          if (i < strikeControllers.length) {
            if (checkboxStates[i]) {
              strikeControllers[i].value = 1.0;
            } else {
              strikeControllers[i].value = 0.0;
            }
          }
        }
        if (mounted) {
          setState(() {});
        }
      });

      // Load saved streak
      int savedStreak = _myBox.get('currentStreak', defaultValue: 0);
      setState(() {
        currentStreak = savedStreak;
      });
      _calculateStreak();
    } else {
      print('❌ No data found for today');
      setState(() {
        taskNames = List.generate(3, (index) => null);
        checkboxStates = List.generate(3, (index) => false);
      });

      // Recalculate streak for new day
      _calculateStreak();
    }
  }

  // Save tasks to Hive with today's date
  Future<void> _saveTasksToHive() async {
    String todayKey = _getTodayKey();

    Map<String, dynamic> todayData = {
      'tasks': taskNames,
      'checkboxStates': checkboxStates,
      'completedCount': checkboxStates.where((state) => state == true).length,
      'totalTasks': existingTasksCount,
      'date': todayKey,
    };

    print('💾 SAVING to Hive (Web):');
    print('  Box name: ${_myBox.name}');
    print('  Box isOpen: ${_myBox.isOpen}');
    print('  Key: $todayKey');
    print('  Data: $todayData');

    try {
      await _myBox.put(todayKey, todayData);
      await _myBox.flush(); // Force write

      // Verify save
      var saved = _myBox.get(todayKey);
      print('✅ Verified saved data: $saved');
    } catch (e) {
      print('❌ Error saving: $e');
    }
  }

  // Schedule a check for midnight
  void _scheduleMidnightCheck() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = tomorrow.difference(now);

    Future.delayed(durationUntilMidnight, () {
      if (mounted) {
        // Check if yesterday was completed
        DateTime yesterday = now.subtract(Duration(days: 1));
        String yesterdayKey = _getDateKey(yesterday);
        Map<dynamic, dynamic>? yesterdayData = _myBox.get(yesterdayKey);

        bool yesterdayComplete = false;
        if (yesterdayData != null) {
          int completed = yesterdayData['completedCount'] ?? 0;
          int total = yesterdayData['totalTasks'] ?? 0;
          yesterdayComplete = (total > 0 && completed == total);
        }

        // If yesterday wasn't complete, reset streak
        if (!yesterdayComplete) {
          setState(() {
            currentStreak = 0;
          });
          _myBox.put('currentStreak', 0);
        }

        // Load new day's tasks
        setState(() {
          _loadTasksForToday();
        });

        // _scheduleMidnightCheck();
        _calculateStreak(); // Schedule next check
      }
    });
  }

  Widget _buildStreakDisplay() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: currentStreak > 0
            ? Colors.orange.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔥', style: TextStyle(fontSize: 20)),
          SizedBox(width: 4),
          Text(
            'Streak: $currentStreak ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: currentStreak > 0 ? Colors.orange : Colors.grey,
            ),
          ),
          SizedBox(width: 2),
          Text(
            currentStreak == 1 || currentStreak == 0 ? 'Day' : 'Days',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Check if all tasks are complete
  bool get allTasksComplete {
    if (existingTasksCount != 3) return false;
    return checkboxStates.every((state) => state == true);
  }

  void _handleCheckboxChange(int index, bool? value) {
    if (index < 0 || index >= checkboxStates.length) return;
    if (index >= scaleControllers.length || index >= strikeControllers.length)
      return;

    bool wasAllComplete = allTasksComplete;

    setState(() {
      checkboxStates[index] = value ?? false;

      if (checkboxStates[index]) {
        scaleControllers[index].forward(from: 0.0);
        strikeControllers[index].forward();
      } else {
        strikeControllers[index].reverse();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _saveTasksToHive();
      _calculateStreak();

      // Check if all tasks just became complete
      if (!wasAllComplete && allTasksComplete && !_hasShownConfetti) {
        _celebrateCompletion();
      }

      // Reset confetti flag if unchecking
      if (!allTasksComplete) {
        _hasShownConfetti = false;
      } // Recalculate streak after saving
    });
  }

  void _celebrateCompletion() {
    _hasShownConfetti = true;
    _confettiController.play();

    // Optional: Show a dialog or snackbar
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Row(
    //       children: [
    //         Text('🎉'),
    //         SizedBox(width: 8),
    //         Text('All tasks completed! Great job!'),
    //       ],
    //     ),
    //     backgroundColor: Colors.green,
    //     duration: Duration(seconds: 2),
    //   ),
    // );
  }

  // Add a new task
  void _addTask() {
    final TextEditingController textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Task'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter task name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              FirebaseAnalytics.instance.logEvent(name: 'add_tasks_clicked');
              if (textController.text.trim().isNotEmpty) {
                setState(() {
                  // Find first empty slot
                  for (int i = 0; i < taskNames.length; i++) {
                    if (taskNames[i] == null) {
                      taskNames[i] = textController.text.trim();
                      // _myBox.put('Tasks', taskNames);
                      _saveTasksToHive();
                      break;
                    }
                  }
                });

                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  // Edit existing task
  void _editTask(int index) {
    final TextEditingController textController = TextEditingController(
      text: taskNames[index] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Task #${index + 1}'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Edit task',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                setState(() {
                  taskNames[index] = textController.text.trim();
                  _saveTasksToHive();
                });
                Navigator.pop(context);
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  // Show options to edit which task
  void _showEditOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Task to Edit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < taskNames.length; i++)
              if (taskNames[i] != null)
                ListTile(
                  title: Text(taskNames[i]!),
                  subtitle: Text('Task #${i + 1}'),
                  onTap: () {
                    Navigator.pop(context);
                    _editTask(i);
                  },
                ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Handle FAB press
  void _handleFabPress() {
    if (existingTasksCount < 3) {
      _addTask();
    } else {
      _showEditOptions();
    }
  }

  @override
  Widget build(BuildContext context) {
    double taskCardWidth = 400;
    double animatedTaskCardWidth = 550;
    print('currentStreak: $currentStreak');

    return Scaffold(
      // appBar: AppBar(
      //   actions: [
      //     // In your AppBar actions, add this debug button
      //     IconButton(
      //       icon: Icon(Icons.refresh),
      //       onPressed: () {
      //         print('🔄 Manual streak recalculation');
      //         _calculateStreak();
      //       },
      //     ),
      //   ],
      // ),
      // floatingActionButton: allCompleted && existingTasksCount == 3
      //     ? Container()
      //     : FloatingActionButton(
      //         onPressed: _handleFabPress,
      //         shape: CircleBorder(),
      //         foregroundColor: Colors.white,
      //         backgroundColor: Colors.blue,
      //         tooltip: existingTasksCount < 3 ? 'Add Task' : 'Edit Task',
      //         child: Icon(existingTasksCount < 3 ? Icons.add : Icons.edit),
      //       ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: Center(
          child: Container(
            width: MediaQuery.sizeOf(context).width * .6,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Just 3',
                  style: kLargeHeading.copyWith(
                    fontSize: MediaQuery.of(context).size.width * .05,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '3 Tasks Per Day, ',
                      style: kHeading.copyWith(
                        fontSize: MediaQuery.of(context).size.width < 600
                            ? 16
                            : 20,
                        // fontSize: MediaQuery.of(context).size.width * .028,
                      ),
                    ),
                    Text(
                      'NO MORE',
                      style: kSemiLargeHeading.copyWith(
                        fontSize: MediaQuery.of(context).size.width < 600
                            ? 23
                            : 28,
                        // fontSize: MediaQuery.of(context).size.width * .036,
                        color: AppColors.pastelGreenColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40),

                _buildStreakDisplay(),
                SizedBox(height: 8),
                Text(
                  DateFormat('E, d MMM').format(DateTime.now()).toString(),
                  style: kSemiHeading.copyWith(
                    color: AppColors.pastelGreenColor,
                  ),
                ),
                SizedBox(height: 20),
                if (!allCompleted)
                  for (int i = 0; i < 3; i++)
                    // Only show task if it exists
                    if (taskNames.length > i && taskNames[i] != null)
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          scaleControllers[i],
                          strikeControllers[i],
                        ]),
                        builder: (context, child) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Container(
                              width: animatedTaskCardWidth,
                              padding: EdgeInsets.only(
                                top: 5,
                                bottom: 5,
                                right: 5,
                              ),

                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: AppColors.warmOrangeColor,
                              ),
                              child: Row(
                                children: [
                                  // Animated Checkbox with scale
                                  Transform.scale(
                                    scale:
                                        scaleControllers.length > i &&
                                            scaleAnimations.length > i
                                        ? scaleAnimations[i].value
                                        : 1.0,
                                    child: Checkbox(
                                      value: checkboxStates.length > i
                                          ? checkboxStates[i]
                                          : false,
                                      onChanged: (value) =>
                                          _handleCheckboxChange(i, value),
                                    ),
                                  ),

                                  // Task text with strike-through and opacity
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        // Text with fade effect
                                        AnimatedOpacity(
                                          opacity: checkboxStates[i]
                                              ? 0.6
                                              : 1.0,
                                          duration: Duration(milliseconds: 300),
                                          child: Text(
                                            taskNames[i]!,
                                            style: kHeading,
                                          ),
                                        ),

                                        // Animated strike-through line
                                        if (checkboxStates[i])
                                          Positioned.fill(
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: CustomPaint(
                                                painter: StrikeThroughPainter(
                                                  progress:
                                                      strikeAnimations[i].value,
                                                ),
                                                child: Container(height: 1),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                if (existingTasksCount == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(15),
                          width: taskCardWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.blueGrey,
                          ),
                          child: Text('Task #1', style: kRegular),
                        ),
                        SizedBox(height: 7),
                        Container(
                          padding: EdgeInsets.all(15),
                          width: taskCardWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.blueGrey,
                          ),
                          child: Text('Task #2', style: kRegular),
                        ),
                        SizedBox(height: 7),
                        Container(
                          padding: EdgeInsets.all(15),
                          width: taskCardWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.blueGrey,
                          ),
                          child: Text('Task #3', style: kRegular),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 6),
                if (existingTasksCount == 1)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(15),
                          width: taskCardWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.blueGrey,
                          ),
                          child: Text('Task #2', style: kRegular),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(15),
                          width: taskCardWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.blueGrey,
                          ),
                          child: Text('Task #3', style: kRegular),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 6),
                if (existingTasksCount == 2)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(15),
                          width: taskCardWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.blueGrey,
                          ),
                          child: Text('Task #3', style: kRegular),
                        ),
                      ],
                    ),
                  ),

                // Show "Completed" message when all are checked
                if (allCompleted && existingTasksCount == 3)
                  Container(
                    margin: EdgeInsets.only(top: 5, bottom: 13),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.pastelGreenColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '✓ Completed',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // Confetti overlay
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: 3.14 / 2, // Down
                    blastDirectionality: BlastDirectionality.explosive,
                    emissionFrequency: 0.05,
                    numberOfParticles: 20,
                    maxBlastForce: 20,
                    minBlastForce: 5,
                    gravity: 0.3,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple,
                      Colors.yellow,
                    ],
                  ),
                ),
                allCompleted && existingTasksCount == 3
                    ? Container()
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          onPressed: _handleFabPress,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 12,
                            ),
                            child: Text(
                              existingTasksCount < 3 ? 'Add' : 'Edit',
                              style: kHeading.copyWith(color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => HistoryScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'History',
                        style: TextStyle(color: AppColors.pastelGreenColor),
                      ),
                    ),
                    Text(' | '),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SettingsScreen(
                              onThemeChanged: widget.onThemeChanged,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Settings',
                        style: TextStyle(color: AppColors.pastelGreenColor),
                      ),
                    ),
                  ],
                ),
                // if (allCompleted) Text('Completed'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for animated strike-through line
class StrikeThroughPainter extends CustomPainter {
  final double progress;

  StrikeThroughPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final startPoint = Offset(0, size.height / 2);
    final endPoint = Offset(size.width * progress, size.height / 2);

    canvas.drawLine(startPoint, endPoint, paint);
  }

  @override
  bool shouldRepaint(StrikeThroughPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
