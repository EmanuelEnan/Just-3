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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Determine responsive values
            bool isMobile = constraints.maxWidth < 600;
            bool isTablet =
                constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
            bool isDesktop = constraints.maxWidth >= 1200;

            double containerWidth;
            if (isDesktop) {
              containerWidth = constraints.maxWidth * 0.5;
            } else if (isTablet) {
              containerWidth = constraints.maxWidth * 0.7;
            } else {
              containerWidth = constraints.maxWidth * 0.95;
            }

            return Center(
              child: Container(
                width: containerWidth,
                constraints: BoxConstraints(maxWidth: 900, minWidth: 300),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                  vertical: isMobile ? 16 : 24,
                ),
                child: historyData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: isMobile ? 64 : 80,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No history yet',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Complete tasks to see your history',
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                color: Colors.grey.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: historyData.length,
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 8 : 16,
                        ),
                        itemBuilder: (context, index) {
                          final dayData = historyData[index];
                          final completedCount = dayData['completedCount'];
                          final totalTasks = dayData['totalTasks'];
                          final isFullyCompleted =
                              completedCount == totalTasks && totalTasks == 3;

                          return Card(
                            margin: EdgeInsets.only(
                              bottom: isMobile ? 12 : 16,
                              left: isMobile ? 0 : 8,
                              right: isMobile ? 0 : 8,
                            ),
                            elevation: isMobile ? 1 : 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                isMobile ? 12 : 16,
                              ),
                            ),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 20,
                                vertical: isMobile ? 8 : 12,
                              ),
                              childrenPadding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 20,
                                vertical: isMobile ? 12 : 16,
                              ),
                              leading: CircleAvatar(
                                radius: isMobile ? 20 : 24,
                                backgroundColor: isFullyCompleted
                                    ? Colors.green
                                    : Colors.orange,
                                child: Icon(
                                  isFullyCompleted
                                      ? Icons.check
                                      : Icons.pending,
                                  color: Colors.white,
                                  size: isMobile ? 20 : 24,
                                ),
                              ),
                              title: Text(
                                _formatDate(dayData['date']),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 15 : 17,
                                ),
                              ),
                              subtitle: Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  '$completedCount/$totalTasks tasks completed',
                                  style: TextStyle(
                                    fontSize: isMobile ? 13 : 14,
                                    color: isFullyCompleted
                                        ? Colors.green
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (
                                      int i = 0;
                                      i < (dayData['tasks'] as List).length;
                                      i++
                                    )
                                      if (dayData['tasks'][i] != null)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            bottom: isMobile ? 10 : 12,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                                size: isMobile ? 20 : 24,
                                              ),
                                              SizedBox(
                                                width: isMobile ? 10 : 12,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  dayData['tasks'][i]
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontSize: isMobile
                                                        ? 14
                                                        : 15,
                                                    height: 1.4,
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
                                                        : Theme.of(context)
                                                              .textTheme
                                                              .bodyLarge
                                                              ?.color,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
