import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:just_3/core/constants/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  HistoryScreenState createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  late Box _myBox;
  List<Map<String, dynamic>> historyData = [];

  @override
  void initState() {
    super.initState();
    _myBox = Hive.box('My_Box');
    _loadHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('🔄 HistoryScreen became visible, reloading...');
    _loadHistory();
  }

  void _loadHistory() {
    print('📜 Loading history from box: ${_myBox.name}');
    print('📦 All keys in box: ${_myBox.keys.toList()}');

    List<Map<String, dynamic>> tempHistory = [];

    // Get all keys from Hive box
    for (var key in _myBox.keys) {
      print('🔍 Checking key: $key');

      // Check if key is a date format (YYYY-MM-DD)
      if (key.toString().contains('-')) {
        Map<dynamic, dynamic>? dayData = _myBox.get(key);
        print('  Data for $key: $dayData');

        if (dayData != null) {
          int completedCount = dayData['completedCount'] ?? 0;
          int totalTasks = dayData['totalTasks'] ?? 0;

          print('  ✓ Completed: $completedCount/$totalTasks');

          // Only add to history if there are tasks for that day
          if (totalTasks > 0) {
            tempHistory.add({
              'date': key.toString(),
              'completedCount': completedCount,
              'totalTasks': totalTasks,
              'tasks': dayData['tasks'] ?? [],
              'checkboxStates': dayData['checkboxStates'] ?? [],
            });
          }
        }
      }
    }

    // Sort by date (most recent first)
    tempHistory.sort((a, b) => b['date'].compareTo(a['date']));

    print('✅ History loaded: ${tempHistory.length} entries');

    setState(() {
      historyData = tempHistory;
    });
  }

  String _formatDate(String dateKey) {
    try {
      final parts = dateKey.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      final date = DateTime(year, month, day);
      final monthNames = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      return '${day} ${monthNames[month - 1]} ${year}';
    } catch (e) {
      return dateKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * .6,
            padding: const EdgeInsets.all(24.0),
            child: historyData.isEmpty
                ? Center(
                    child: Text(
                      'No history yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: historyData.length,
                    padding: EdgeInsets.all(10),
                    itemBuilder: (context, index) {
                      final dayData = historyData[index];
                      final completedCount = dayData['completedCount'];
                      final totalTasks = dayData['totalTasks'];
                      final isFullyCompleted =
                          completedCount == totalTasks && totalTasks == 3;

                      return Expanded(
                        child: Card(
                          margin: EdgeInsets.only(bottom: 10),
                          elevation: 2,
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: isFullyCompleted
                                  ? Colors.green
                                  : Colors.orange,
                              child: Icon(
                                isFullyCompleted ? Icons.check : Icons.pending,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              _formatDate(dayData['date']),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              '$completedCount/$totalTasks tasks completed',
                              style: TextStyle(
                                color: isFullyCompleted
                                    ? Colors.green
                                    : Colors.grey[600],
                              ),
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (
                                      int i = 0;
                                      i < (dayData['tasks'] as List).length;
                                      i++
                                    )
                                      if (dayData['tasks'][i] != null)
                                        Padding(
                                          padding: EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            children: [
                                              Icon(
                                                (dayData['checkboxStates'][i]
                                                        as bool)
                                                    ? Icons.check_box
                                                    : Icons
                                                          .check_box_outline_blank,
                                                color:
                                                    (dayData['checkboxStates'][i]
                                                        as bool)
                                                    ? Colors.green
                                                    : Colors.grey,
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  dayData['tasks'][i].toString(),
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    decoration:
                                                        (dayData['checkboxStates'][i]
                                                            as bool)
                                                        ? TextDecoration
                                                              .lineThrough
                                                        : TextDecoration.none,
                                                    color:
                                                        (dayData['checkboxStates'][i]
                                                            as bool)
                                                        ? Colors.grey
                                                        : AppColors
                                                              .pastelGreenColor,
                                                  ),
                                                ),
                                              ),
                                            ],
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
          ),
        ),
      ),
    );
  }
}
