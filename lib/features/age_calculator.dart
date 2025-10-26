/*
 * File: lib/features/age_calculator.dart
 * Location: /c:/Users/Tamal/Documents/smart_numerix_v2/lib/features/age_calculator.dart
 * Description: Precise age calculator from birth date
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

// A simple data class to hold the calculated age components.
class Age {
  final int years;
  final int months;
  final int days;

  Age({this.years = 0, this.months = 0, this.days = 0});
}

class AgeCalculatorPage extends StatefulWidget {
  const AgeCalculatorPage({super.key});

  @override
  _AgeCalculatorPageState createState() => _AgeCalculatorPageState();
}

class _AgeCalculatorPageState extends State<AgeCalculatorPage> with TickerProviderStateMixin {
  DateTime? _dateOfBirth;
  DateTime _ageAtDate = DateTime.now(); // Default to today
  Age? _calculatedAge;
  String? _nextBirthdayInfo;
  bool _isBengali = true; // Language state

  late AnimationController _animationController;

  // --- Translation Data ---
  static const Map<String, Map<String, String>> _translations = {
    'app_title': {'bn': 'বয়স ক্যালকুলেটর', 'en': 'Age Calculator'},
    'select_dob_prompt': {'bn': 'আপনার বয়স গণনা করতে\nজন্ম তারিখ নির্বাচন করুন', 'en': 'Select your Date of Birth\nto calculate your age'},
    'select_dob': {'bn': 'জন্ম তারিখ নির্বাচন করুন', 'en': 'Select Date of Birth'},
    'dob_label': {'bn': 'জন্ম তারিখ', 'en': 'Date of Birth'},
    'age_at_date_label': {'bn': 'বয়স গণনার দিন', 'en': 'Age at Date of'},
    'today_label': {'bn': 'আজকের তারিখ', 'en': 'Today\'s Date'},
    'calculate_btn': {'bn': 'হিসাব করুন', 'en': 'Calculate'},
    'reset_btn': {'bn': 'রিসেট', 'en': 'Reset'},
    'your_age_label': {'bn': 'আপনার সঠিক বয়স', 'en': 'Your Exact Age'},
    'years_label': {'bn': 'বছর', 'en': 'Years'},
    'months_label': {'bn': 'মাস', 'en': 'Months'},
    'days_label': {'bn': 'দিন', 'en': 'Days'},
    'age_summary_label': {'bn': 'বয়সের সারাংশ', 'en': 'Age Summary'},
    'next_birthday_label': {'bn': 'পরবর্তী জন্মদিন', 'en': 'Next Birthday'},
    'total_months_label': {'bn': 'মোট মাস', 'en': 'Total Months'},
    'total_days_label': {'bn': 'মোট দিন', 'en': 'Total Days'},
    'total_hours_label': {'bn': 'মোট ঘন্টা', 'en': 'Total Hours'},
    'today_birthday': {'bn': 'আজ!', 'en': 'Today!'},
    'days_remaining': {'bn': 'দিন বাকি', 'en': 'days left'},
    'months_remaining': {'bn': 'মাস', 'en': 'months'},
    'dob_error': {'bn': 'জন্ম তারিখ ভবিষ্যতের হতে পারে না।', 'en': 'Date of Birth cannot be in the future.'},
    'select_dob_first': {'bn': 'অনুগ্রহ করে প্রথমে আপনার জন্ম তারিখ নির্বাচন করুন।', 'en': 'Please select your Date of Birth first.'},
    'select': {'bn': 'নির্বাচন করুন', 'en': 'Select'},
  };

  String _s(String key) {
    return _translations[key]?[_isBengali ? 'bn' : 'en'] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Shows a date picker and updates the state.
  Future<void> _selectDate(BuildContext context, {required bool isDateOfBirth}) async {
    final DateTime initial = isDateOfBirth ? (_dateOfBirth ?? DateTime(DateTime.now().year - 20)) : _ageAtDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
      helpText: _s(isDateOfBirth ? 'select_dob' : 'age_at_date_label'),
      locale: _isBengali ? const Locale('bn', 'BD') : const Locale('en', 'US'),
    );

    if (picked != null) {
      setState(() {
        if (isDateOfBirth) {
          _dateOfBirth = picked;
        } else {
          _ageAtDate = picked;
        }
        if (_dateOfBirth != null) {
          _calculateAge();
        }
      });
    }
  }

  void _calculateAge() {
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s('select_dob_first')),
          backgroundColor: Colors.amber.shade800,
        ),
      );
      return;
    }

    if (_dateOfBirth!.isAfter(_ageAtDate)) {
      setState(() {
        _calculatedAge = null;
        _nextBirthdayInfo = null;
        _animationController.reverse();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_s('dob_error')),
            backgroundColor: Colors.redAccent,
          ),
        );
      });
      return;
    }

    int years = _ageAtDate.year - _dateOfBirth!.year;
    int months = _ageAtDate.month - _dateOfBirth!.month;
    int days = _ageAtDate.day - _dateOfBirth!.day;

    if (days < 0) {
      months--;
      DateTime previousMonth = DateTime(_ageAtDate.year, _ageAtDate.month - 1);
      days += DateUtils.getDaysInMonth(previousMonth.year, previousMonth.month);
    }

    if (months < 0) {
      years--;
      months += 12;
    }

    setState(() {
      _calculatedAge = Age(years: years, months: months, days: days);
      _calculateNextBirthday();
      _animationController.forward(from: 0.0);
    });
  }

  void _calculateNextBirthday() {
    if (_dateOfBirth == null) return;

    DateTime today = DateTime.now();
    today = DateTime(today.year, today.month, today.day);
    DateTime nextBirthday = DateTime(today.year, _dateOfBirth!.month, _dateOfBirth!.day);

    if (nextBirthday.isBefore(today)) {
      nextBirthday = DateTime(today.year + 1, _dateOfBirth!.month, _dateOfBirth!.day);
    }

    final daysUntil = nextBirthday.difference(today).inDays;

    if (daysUntil == 0) {
      _nextBirthdayInfo = _s('today_birthday');
    } else if (daysUntil < 30) {
      _nextBirthdayInfo = '$daysUntil ${_s("days_remaining")}';
    } else {
      final months = (daysUntil / 30.44).floor();
      final days = daysUntil - (months * 30.44).floor();
      _nextBirthdayInfo = '$months ${_s("months_remaining")} $days ${_s("days_label")}';
    }
  }

  void _clear() {
    setState(() {
      _dateOfBirth = null;
      _ageAtDate = DateTime.now();
      _calculatedAge = null;
      _nextBirthdayInfo = null;
      _animationController.reverse();
    });
  }

  void _toggleLanguage() {
    setState(() {
      _isBengali = !_isBengali;
      // Recalculate birthday info to update language
      if (_calculatedAge != null) {
        _calculateNextBirthday();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: Text(_s('app_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _toggleLanguage,
            child: Text(
              _isBengali ? 'EN' : 'BN',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F23), Color(0xFF16213E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _calculatedAge != null
                        ? _buildResultSection()
                        : _buildInitialPrompt(),
                  ),
                ),
                _buildDateSelectorSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitialPrompt() {
    return Column(
      key: const ValueKey('prompt'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cake_outlined, color: Colors.white.withOpacity(0.3), size: 80),
        const SizedBox(height: 20),
        Text(
          _s('select_dob_prompt'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 18,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    final int totalDays = _ageAtDate.difference(_dateOfBirth!).inDays;
    final int totalMonths = (_calculatedAge!.years * 12) + _calculatedAge!.months;
    final int totalHours = totalDays * 24;

    return SingleChildScrollView(
      key: const ValueKey('results'),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(_s('your_age_label'), style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 10),
          _buildMainAgeDisplay(),
          const SizedBox(height: 30),
          _buildSummaryGrid(totalMonths, totalDays, totalHours),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMainAgeDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildAgeUnit(_calculatedAge!.years.toString(), _s('years_label')),
        const SizedBox(width: 16),
        _buildAgeUnit(_calculatedAge!.months.toString(), _s('months_label')),
        const SizedBox(width: 16),
        _buildAgeUnit(_calculatedAge!.days.toString(), _s('days_label')),
      ],
    );
  }

  Widget _buildAgeUnit(String value, String label) {
    final double fontSize = MediaQuery.of(context).size.width < 360 ? 48 : 56;
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1)),
        Text(label, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7))),
      ],
    );
  }

  Widget _buildSummaryGrid(int totalMonths, int totalDays, int totalHours) {
    // Gave items slightly more height to prevent overflow on small screens
    final double aspectRatio = MediaQuery.of(context).size.width < 380 ? 2.0 : 2.2;
    return Column(
      children: [
        Text(_s('age_summary_label'), style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.8))),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: aspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            if (_nextBirthdayInfo != null) _buildSummaryItem('🎂', _s('next_birthday_label'), _nextBirthdayInfo!),
            _buildSummaryItem('🗓️', _s('total_months_label'), '$totalMonths'),
            _buildSummaryItem('☀️', _s('total_days_label'), '$totalDays'),
            _buildSummaryItem('⏰', _s('total_hours_label'), NumberFormat.compact().format(totalHours)),
          ],
        ),
      ],
    );
  }

  // *** THIS WIDGET IS NOW FULLY RESPONSIVE AND WILL NOT OVERFLOW ***
  Widget _buildSummaryItem(String icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$icon $title',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Using Flexible allows the text to wrap if it's too long
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelectorSection() {
    return _GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPickerRow(
              icon: Icons.cake_outlined,
              label: _s('dob_label'),
              date: _dateOfBirth,
              onPressed: () => _selectDate(context, isDateOfBirth: true),
            ),
            const SizedBox(height: 12),
            _buildPickerRow(
              icon: Icons.calendar_today_outlined,
              label: _s('today_label'),
              date: _ageAtDate,
              onPressed: () => _selectDate(context, isDateOfBirth: false),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _calculateAge,
                    icon: const Icon(Icons.calculate_outlined),
                    label: Text(_s('calculate_btn')),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF007BFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _clear,
                  icon: const Icon(Icons.refresh),
                  tooltip: _s('reset_btn'),
                  style: IconButton.styleFrom(
                      foregroundColor: Colors.white.withOpacity(0.8),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      padding: const EdgeInsets.all(14)
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPickerRow({
    required IconData icon,
    required String label,
    required DateTime? date,
    required VoidCallback onPressed,
  }) {
    final locale = _isBengali ? 'bn_BD' : 'en_US';
    return Material(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70),
              const SizedBox(width: 16),
              Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
              const Spacer(),
              Text(
                date == null ? _s('select') : DateFormat('dd MMM, yyyy', locale).format(date),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}


class _GlassmorphicCard extends StatelessWidget {
  final Widget child;

  const _GlassmorphicCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}