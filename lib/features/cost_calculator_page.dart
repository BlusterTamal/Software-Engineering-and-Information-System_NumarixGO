/*
 * File: lib/features/cost_calculator_page.dart
 * Location: /c:/Users/Tamal/Documents/smart_numerix_v2/lib/features/cost_calculator_page.dart
 * Description: Expense tracking with Hive database storage
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive/hive.dart';
import '../widgets/add_expense_sheet.dart';
import 'dart:ui';

part 'cost_calculator_page.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final double cost;

  Expense({
    required this.id,
    required this.date,
    required this.type,
    required this.description,
    required this.cost,
  });
}

class CostCalculatorPage extends StatefulWidget {
  const CostCalculatorPage({super.key});

  @override
  State<CostCalculatorPage> createState() => _CostCalculatorPageState();
}

class _CostCalculatorPageState extends State<CostCalculatorPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final Map<DateTime, List<Expense>> _expenses = {};

  late final Box<Expense> _expenseBox;

  @override
  void initState() {
    super.initState();
    _selectedDay = _normalizeDate(_focusedDay);

    _expenseBox = Hive.box<Expense>('expenses');

    _loadExpensesFromDb();
  }

  void _loadExpensesFromDb() {
    _expenses.clear();

    for (final expense in _expenseBox.values) {
      final dayKey = _normalizeDate(expense.date);

      if (_expenses.containsKey(dayKey)) {
        _expenses[dayKey]!.add(expense);
      } else {
        _expenses[dayKey] = [expense];
      }
    }

    setState(() {});
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<Expense> _getExpensesForDay(DateTime day) {
    return _expenses[_normalizeDate(day)] ?? [];
  }

  void _showAddExpenseSheet() async {
    final newExpenses = await showModalBottomSheet<List<Expense>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExpenseSheet(selectedDate: _selectedDay),
    );

    if (newExpenses != null && newExpenses.isNotEmpty) {
      final Map<String, Expense> expensesToSave = {
        for (var e in newExpenses) e.id: e
      };
      _expenseBox.putAll(expensesToSave);
      setState(() {
        final dayKey = _normalizeDate(_selectedDay);
        if (_expenses.containsKey(dayKey)) {
          _expenses[dayKey]!.addAll(newExpenses);
        } else {
          _expenses[dayKey] = newExpenses;
        }
      });
    }
  }

  void _showSummaryOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Get Cost Summary',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today_rounded,
                    color: Colors.blueAccent),
                title: const Text('Daily Summary'),
                onTap: () {
                  Navigator.pop(context);
                  _showDailySummaryPicker();
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_view_week_rounded,
                    color: Colors.greenAccent),
                title: const Text('Weekly Summary'),
                onTap: () {
                  Navigator.pop(context);
                  _showDateRangeSummaryPicker(isWeekly: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_view_month_rounded,
                    color: Colors.purpleAccent),
                title: const Text('Monthly Summary'),
                onTap: () {
                  Navigator.pop(context);
                  _showDateRangeSummaryPicker(isWeekly: false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDailySummaryPicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      final expenses = _getExpensesForDay(pickedDate);
      _showResultDialog(
        title:
        'Daily Summary for ${DateFormat('dd MMM, yyyy').format(pickedDate)}',
        expenses: expenses,
      );
    }
  }

  Future<void> _showDateRangeSummaryPicker({bool isWeekly = true}) async {
    final initialStart = isWeekly
        ? _selectedDay.subtract(const Duration(days: 7))
        : DateTime(_selectedDay.year, _selectedDay.month, 1);
    final initialEnd =
    isWeekly ? _selectedDay : DateTime(_selectedDay.year, _selectedDay.month + 1, 0);

    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: initialStart,
        end: initialEnd,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedRange != null) {
      List<Expense> rangeExpenses = [];
      _expenses.forEach((date, expenses) {
        final normalizedDate = _normalizeDate(date);
        final normalizedStart = _normalizeDate(pickedRange.start);
        final normalizedEnd = _normalizeDate(pickedRange.end);

        if (!normalizedDate.isBefore(normalizedStart) &&
            !normalizedDate.isAfter(normalizedEnd)) {
          rangeExpenses.addAll(expenses);
        }
      });

      _showResultDialog(
          title: isWeekly ? 'Weekly Summary' : 'Monthly Summary',
          subtitle:
          '${DateFormat('dd MMM').format(pickedRange.start)} - ${DateFormat('dd MMM, yyyy').format(pickedRange.end)}',
          expenses: rangeExpenses);
    }
  }

  void _showResultDialog({
    required String title,
    String? subtitle,
    required List<Expense> expenses,
  }) {
    final Map<String, double> typeSummary = {};
    double total = 0.0;

    for (final expense in expenses) {
      total += expense.cost;
      typeSummary.update(
        expense.type,
            (value) => value + expense.cost,
        ifAbsent: () => expense.cost,
      );
    }
    final int itemCount = expenses.length;

    final sortedEntries = typeSummary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitle != null)
                Text(subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
              if (subtitle != null) const SizedBox(height: 16),

              if (expenses.isEmpty)
                const Text(
                  'No expenses found for this period.',
                  style: TextStyle(fontSize: 16),
                )
              else ...[
                Text('Total Cost: ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Total Items: $itemCount'),
                const Divider(height: 24, thickness: 1),

                const Text('Breakdown by Type:',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sortedEntries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key,
                              style:
                              const TextStyle(fontWeight: FontWeight.w500)),
                          Text(entry.value.toStringAsFixed(2)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedExpenses = _getExpensesForDay(_selectedDay);

    return Scaffold(
      backgroundColor: const Color(0xFF16213E),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title:
        const Text('Cost Tracker', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.summarize_rounded, color: Colors.white),
            onPressed: _showSummaryOptions,
            tooltip: 'Show Summary',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseSheet,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F23), Color(0xFF16213E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCalendarCard(),
              _buildExpenseListHeader(selectedExpenses.length),
              _buildExpenseList(selectedExpenses),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    return _GlassmorphicCard(
      margin: const EdgeInsets.all(16),
      child: TableCalendar(
        locale: 'en_US',
        focusedDay: _focusedDay,
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: CalendarFormat.month,
        eventLoader: _getExpensesForDay,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = _normalizeDate(selectedDay);
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(color: Colors.white70),
          weekendTextStyle: const TextStyle(color: Colors.redAccent),
          outsideTextStyle: const TextStyle(color: Colors.white24),
          selectedDecoration: const BoxDecoration(
            color: Colors.blueAccent,
            shape: BoxShape.circle,
          ),
          selectedTextStyle:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          todayDecoration: BoxDecoration(
            border: Border.all(color: Colors.blueAccent, width: 2),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
              color: Colors.blueAccent, fontWeight: FontWeight.bold),
          markerDecoration: const BoxDecoration(
            color: Colors.amber,
            shape: BoxShape.circle,
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.white54),
          weekendStyle: TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildExpenseListHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Expenses for ${DateFormat('dd MMM, yyyy').format(_selectedDay)}',
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '$count Items',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList(List<Expense> expenses) {
    return Expanded(
      child: expenses.isEmpty
          ? const Center(
        child: Text(
          'No expenses added for this day.\nClick the "+" button to add one.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return _GlassmorphicCard(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              contentPadding:
              const EdgeInsets.fromLTRB(16, 8, 8, 8), // Adjusted padding
              leading: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.1),
                child: Icon(_getIconForType(expense.type),
                    color: Colors.amber),
              ),
              title: Text(
                expense.description.isEmpty
                    ? expense.type
                    : expense.description,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: expense.description.isNotEmpty
                  ? Text(expense.type,
                  style: const TextStyle(color: Colors.white70))
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${expense.cost.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: () => _showDeleteConfirmation(expense),
                    tooltip: 'Delete Expense',
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'food':
        return Icons.fastfood_rounded;
      case 'transport':
        return Icons.directions_bus_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'health':
        return Icons.medical_services_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }

  void _showDeleteConfirmation(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text(
            'Are you sure you want to delete this item?\n"${expense.description.isNotEmpty ? expense.description : expense.type}" - ${expense.cost}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _expenseBox.delete(expense.id);
              setState(() {
                final dayKey = _normalizeDate(expense.date);
                _expenses[dayKey]?.removeWhere((e) => e.id == expense.id);
                if (_expenses[dayKey]?.isEmpty ?? false) {
                  _expenses.remove(dayKey);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  const _GlassmorphicCard({required this.child, this.margin, this.padding});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      margin: margin,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: padding ?? const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}