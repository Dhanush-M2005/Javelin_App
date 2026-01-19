import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/dataset_provider.dart';
import '../providers/throw_selection_provider.dart';
import '../models/javelin_throw.dart';

class ThrowsScreen extends StatefulWidget {
  final VoidCallback? onAnalyze;

  const ThrowsScreen({super.key, this.onAnalyze});

  @override
  State<ThrowsScreen> createState() => _ThrowsScreenState();
}

class _ThrowsScreenState extends State<ThrowsScreen> {
  DateTime _selectedMonth = DateTime.now();
  final Set<String> _expandedDates = {};
  bool _shouldAutoExpand = true; // Flag to trigger auto-expansion

  @override
  void initState() {
    super.initState();
    // loadDatasets is called in main.dart on app start
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DatasetProvider, ThrowSelectionProvider>(
      builder: (context, datasetProvider, selectionProvider, child) {
        if (datasetProvider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
        }

        final allThrows = datasetProvider.allThrows;
        if (allThrows.isEmpty) {
          return _buildEmptyState(context);
        }

        // Group throws by date and filter by selected month
        final groupedByDate = _groupThrowsByDate(allThrows, _selectedMonth);

        // Auto-expand logic
        if (_shouldAutoExpand && groupedByDate.isNotEmpty) {
           // Provide a microtax delay or just do it? 
           // Since we are in build, we can't call setState, but we can mutate _expandedDates.
           // However, if we mutate it, the ListView will pick it up immediately.
           // We need to ensure we don't cause side effects.
           // Mutating the set is fine as long as we don't trigger rebuild loop.
           
           final latestDate = groupedByDate.keys.first;
           _expandedDates.clear(); // Clear previous if any (though usually cleared on month change)
           _expandedDates.add(latestDate);
           _shouldAutoExpand = false;
        }

        return Column(
          children: [
            _buildMonthSelector(allThrows),
            Expanded(
              child: groupedByDate.isEmpty
                  ? _buildNoThrowsInMonth()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: groupedByDate.length,
                      itemBuilder: (context, index) {
                        final dateStr = groupedByDate.keys.elementAt(index);
                        final throws = groupedByDate[dateStr]!;
                        final isExpanded = _expandedDates.contains(dateStr);

                        return _buildDateSection(dateStr, throws, isExpanded, selectionProvider);
                      },
                    ),
            ),
            if (selectionProvider.canCompare)
              _buildAnalyticsButton(context, selectionProvider, allThrows),
          ],
        );
      },
    );
  }

  Widget _buildMonthSelector(List<JavelinThrow> allThrows) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1E1E1E),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                _shouldAutoExpand = true; // Trigger auto-expand for new month
                _expandedDates.clear();
              });
            },
          ),
          InkWell(
            onTap: () => _showCalendarPicker(context, allThrows),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0096FF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF0096FF)),
              ),
              child: Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                _shouldAutoExpand = true; // Trigger auto-expand for new month
                _expandedDates.clear();
              });
            },
          ),
        ],
      ),
    );
  }



  void _showCalendarPicker(BuildContext context, List<JavelinThrow> allThrows) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _CalendarPickerContent(
          initialMonth: _selectedMonth,
          allThrows: allThrows,
          onMonthChanged: (date) {
            setState(() {
              _selectedMonth = date;
              _shouldAutoExpand = true;
              _expandedDates.clear();
            });
          },
          onClose: () {
             setState(() {
               _shouldAutoExpand = false;
               _expandedDates.clear();
               _expandedDates.add(DateFormat('dd.MM.yyyy').format(_selectedMonth));
             });
             Navigator.pop(context);
          },
        );
      },
    );
  }


  Widget _buildDateSection(String dateStr, List<JavelinThrow> throws, bool isExpanded, ThrowSelectionProvider selectionProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              isExpanded ? Icons.expand_more : Icons.chevron_right,
              color: const Color(0xFF0096FF),
            ),
            title: Text(
              dateStr,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0096FF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${throws.length} throw${throws.length > 1 ? 's' : ''}',
                style: const TextStyle(color: Color(0xFF0096FF), fontWeight: FontWeight.bold),
              ),
            ),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedDates.remove(dateStr);
                } else {
                  _expandedDates.clear(); // Auto-close other dates
                  _expandedDates.add(dateStr);
                }
              });
            },
          ),
          if (isExpanded)
            ...throws.asMap().entries.map((entry) {
              final index = entry.key;
              final throwItem = entry.value;
              final isSelected = selectionProvider.isSelected(throwItem.id);

              return ListTile(
                onTap: () {
                  final success = selectionProvider.toggleThrow(throwItem.id);
                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You can compare at most 5 throws')),
                    );
                  }
                },
                leading: Checkbox(
                  value: isSelected,
                  activeColor: const Color(0xFF0096FF),
                  onChanged: (value) {
                    final success = selectionProvider.toggleThrow(throwItem.id);
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You can compare at most 5 throws')),
                      );
                    }
                  },
                ),
                title: Text(
                  'Throw ${index + 1} - ${throwItem.distance}m',
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF0096FF) : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  'Speed: ${throwItem.releaseSpeed.toStringAsFixed(1)} m/s • Angle: ${throwItem.angle.toStringAsFixed(1)}°',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: Icon(
                  Icons.bar_chart,
                  color: isSelected ? const Color(0xFF0096FF) : Colors.grey,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAnalyticsButton(BuildContext context, ThrowSelectionProvider selectionProvider, List<JavelinThrow> allThrows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {
            widget.onAnalyze?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0096FF),
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            selectionProvider.selectedCount == 1 
              ? 'View Analytics' 
              : 'Compare ${selectionProvider.selectedCount} Throws',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Map<String, List<JavelinThrow>> _groupThrowsByDate(List<JavelinThrow> throws, DateTime selectedMonth) {
    final Map<String, List<JavelinThrow>> grouped = {};

    for (final throwItem in throws) {
      final throwDate = DateFormat('yyyy-MM-dd').parse(throwItem.date);

      if (throwDate.year != selectedMonth.year || throwDate.month != selectedMonth.month) {
        continue;
      }

      final dateStr = DateFormat('dd.MM.yyyy').format(throwDate);

      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(throwItem);
    }

    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) {
        final dateA = DateFormat('dd.MM.yyyy').parse(a.key);
        final dateB = DateFormat('dd.MM.yyyy').parse(b.key);
        return dateB.compareTo(dateA);
      });

    return Map.fromEntries(sortedEntries);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No throws found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect to WiFi to download data',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoThrowsInMonth() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No throws in ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// Helper widget to manage internal state of the picker (View switching)
class _CalendarPickerContent extends StatefulWidget {
  final DateTime initialMonth;
  final List<JavelinThrow> allThrows;
  final ValueChanged<DateTime> onMonthChanged;
  final VoidCallback onClose;

  const _CalendarPickerContent({
    required this.initialMonth,
    required this.allThrows,
    required this.onMonthChanged,
    required this.onClose,
  });

  @override
  AppCalendarPickerState createState() => AppCalendarPickerState();
}

class AppCalendarPickerState extends State<_CalendarPickerContent> {
  late DateTime _currentMonth;
  CalendarView _currentView = CalendarView.calendar;
  
  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 16),
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Navigation Header
            _buildHeader(),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: _buildPickerContent(scrollController),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Action
           if (_currentView == CalendarView.calendar)
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                  });
                   widget.onMonthChanged(_currentMonth);
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                     if (_currentView == CalendarView.month) {
                        _currentView = CalendarView.year;
                      } else {
                        _currentView = CalendarView.calendar;
                      }
                  });
                },
              ),

          // Title / Trigger
           InkWell(
              onTap: () {
                if (_currentView == CalendarView.calendar) {
                  setState(() {
                    _currentView = CalendarView.year;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: _currentView == CalendarView.calendar 
                  ? BoxDecoration(
                      color: const Color(0xFF0096FF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0096FF)),
                    )
                  : null,
                child: Row(
                  children: [
                    Text(
                      _currentView == CalendarView.year 
                        ? 'Select Year' 
                        : _currentView == CalendarView.month 
                          ? 'Select Month'
                          : DateFormat('MMMM yyyy').format(_currentMonth),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_currentView == CalendarView.calendar)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(Icons.arrow_drop_down, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),

          // Right Action
          if (_currentView == CalendarView.calendar)
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                  });
                  widget.onMonthChanged(_currentMonth);
                },
              )
            else
              const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPickerContent(ScrollController scrollController) {
    switch (_currentView) {
      case CalendarView.year:
        return _buildYearPicker();
      case CalendarView.month:
        return _buildMonthPicker();
      case CalendarView.calendar:
        return _buildCalendarGrid(scrollController);
    }
  }

  Widget _buildYearPicker() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 15, // 2020 to 2034
      itemBuilder: (context, index) {
        final year = 2020 + index;
        final isSelected = year == _currentMonth.year;
        return InkWell(
          onTap: () {
            setState(() {
              _currentMonth = DateTime(year, _currentMonth.month);
              _currentView = CalendarView.month; // Year -> Month
            });
            widget.onMonthChanged(_currentMonth);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0096FF).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: const Color(0xFF0096FF)) : null,
            ),
            alignment: Alignment.center,
            child: Text(
              year.toString(),
              style: TextStyle(
                color: isSelected ? const Color(0xFF0096FF) : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthPicker() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final date = DateTime(2000, month);
        final isSelected = month == _currentMonth.month;
        return InkWell(
          onTap: () {
            setState(() {
              _currentMonth = DateTime(_currentMonth.year, month);
              _currentView = CalendarView.calendar; // Month -> Calendar
            });
            widget.onMonthChanged(_currentMonth);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0096FF).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: isSelected ? Border.all(color: const Color(0xFF0096FF)) : null,
            ),
            alignment: Alignment.center,
            child: Text(
              DateFormat('MMM').format(date),
              style: TextStyle(
                color: isSelected ? const Color(0xFF0096FF) : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

   Widget _buildCalendarGrid(ScrollController scrollController) {
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final weekdayOffset = firstDayOfMonth.weekday - 1;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          // Swipe Right -> Previous Month
          setState(() {
             _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
          });
          widget.onMonthChanged(_currentMonth);
        } else if (details.primaryVelocity! < 0) {
          // Swipe Left -> Next Month
           setState(() {
             _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
          });
          widget.onMonthChanged(_currentMonth);
        }
      },
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), 
            itemCount: daysInMonth + weekdayOffset,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < weekdayOffset) {
                return const SizedBox();
              }
              final day = index - weekdayOffset + 1;
              final date = DateTime(_currentMonth.year, _currentMonth.month, day);
              
              final hasThrows = widget.allThrows.any((t) {
                final tDate = DateFormat('yyyy-MM-dd').parse(t.date);
                // simple check
                return tDate.year == date.year && tDate.month == date.month && tDate.day == date.day;
              });

              return GestureDetector(
                onTap: () {
                  widget.onMonthChanged(date); 
                  widget.onClose();
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: hasThrows ? Colors.green : Colors.red, // Colors based on throw? Or just presence?
                             // Original code used presence.
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

enum CalendarView { calendar, year, month }