/*
 * File: lib/features/gpa_calculator.dart
 * Location: /c:/Users/Tamal/Documents/smart_numerix_v2/lib/features/gpa_calculator.dart
 * Description: GPA and CGPA calculator for academic tracking
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:math' as math;

class SubjectRecord {
  final String name;
  final String value;
  final String? credits;

  SubjectRecord({required this.name, required this.value, this.credits});
}

class CalculationRecord {
  final String result;
  final String? grade;
  final String timestamp;
  final List<SubjectRecord> subjects;
  final SubjectRecord? optionalSubject;

  CalculationRecord({
    required this.result,
    this.grade,
    required this.timestamp,
    required this.subjects,
    this.optionalSubject,
  });
}

// ##################################################################
// # Main Page with Tabs
// ##################################################################

class GpaCalculatorPage extends StatefulWidget {
  const GpaCalculatorPage({super.key});

  @override
  State<GpaCalculatorPage> createState() => _GpaCalculatorPageState();
}

class _GpaCalculatorPageState extends State<GpaCalculatorPage> {
  bool _isBengali = true;

  void _toggleLanguage() {
    setState(() {
      _isBengali = !_isBengali;
    });
  }

  String _s(String key) => _translations[key]?[_isBengali ? 'bn' : 'en'] ?? key;


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_s('app_bar_title')),
          backgroundColor: const Color(0xFF10141C).withOpacity(0.8),
          elevation: 0,
          centerTitle: true,
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _toggleLanguage,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
              ),
              child: Text(
                _isBengali ? 'EN' : 'BN',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
          bottom: TabBar(
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: const Color(0xFF007BFF),
            ),
            indicatorPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: _s('gpa_tab')),
              Tab(text: _s('cgpa_tab')),
            ],
          ),
        ),
        body: _AnimatedBackground(
          child: SafeArea(
            top: false,
            child: TabBarView(
              children: [
                GpaCalculatorTab(isBengali: _isBengali),
                CgpaCalculatorTab(isBengali: _isBengali),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum InputType { marks, grade }

class GpaSubject {
  final TextEditingController nameController;
  final TextEditingController valueController;
  InputType inputType;
  final Key key = UniqueKey();

  GpaSubject()
      : nameController = TextEditingController(),
        valueController = TextEditingController(),
        inputType = InputType.marks;
}

class GpaCalculatorTab extends StatefulWidget {
  final bool isBengali;
  const GpaCalculatorTab({super.key, required this.isBengali});

  @override
  State<GpaCalculatorTab> createState() => _GpaCalculatorTabState();
}

class _GpaCalculatorTabState extends State<GpaCalculatorTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<GpaSubject> _subjects = [GpaSubject()];
  final GpaSubject _optionalSubject = GpaSubject();
  double? _gpaResult;
  String? _gradeResult;
  final List<CalculationRecord> _history = [];

  String _s(String key) => _translations[key]?[widget.isBengali ? 'bn' : 'en'] ?? key;

  final Map<String, double> gpaGradeMap = { 'A+': 5.0, 'A': 4.0, 'A-': 3.5, 'B': 3.0, 'C': 2.0, 'D': 1.0, 'F': 0.0 };
  final Map<String, String> gpaGradeWithMarksMap = { 'A+ (80-100)': 'A+', 'A (70-79)': 'A', 'A- (60-69)': 'A-', 'B (50-59)': 'B', 'C (40-49)': 'C', 'D (33-39)': 'D', 'F (0-32)': 'F' };

  void _addSubject() => setState(() => _subjects.add(GpaSubject()));
  void _removeSubject(int index) => setState(() => _subjects.removeAt(index));

  double _getGpaPointFromMarks(double marks) {
    if (marks >= 80) return 5.0; if (marks >= 70) return 4.0; if (marks >= 60) return 3.5;
    if (marks >= 50) return 3.0; if (marks >= 40) return 2.0; if (marks >= 33) return 1.0;
    return 0.0;
  }

  String _getGpaGradeFromGpa(double gpa) {
    if (gpa >= 5.0) return 'A+'; if (gpa >= 4.0) return 'A'; if (gpa >= 3.5) return 'A-';
    if (gpa >= 3.0) return 'B'; if (gpa >= 2.0) return 'C'; if (gpa >= 1.0) return 'D';
    return 'F';
  }

  void _calculateGpa() {
    FocusScope.of(context).unfocus();
    double totalPoints = 0;
    bool hasFailed = false;
    List<SubjectRecord> subjectRecords = [];

    if (_subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s('add_subject_warning')), backgroundColor: Colors.amber));
      return;
    }

    for (var subject in _subjects) {
      double point = 0;
      if (subject.inputType == InputType.marks) {
        double marks = double.tryParse(subject.valueController.text) ?? 0;
        if (marks < 33) hasFailed = true;
        point = _getGpaPointFromMarks(marks);
      } else {
        point = gpaGradeMap[subject.valueController.text] ?? 0.0;
        if (point == 0.0 && subject.valueController.text.isNotEmpty) hasFailed = true;
      }
      totalPoints += point;
      subjectRecords.add(SubjectRecord(name: subject.nameController.text.isEmpty ? _s('unnamed_subject') : subject.nameController.text, value: subject.valueController.text));
    }

    SubjectRecord? optionalRecord;
    if (_optionalSubject.valueController.text.isNotEmpty) {
      double optionalPoint = 0;
      if (_optionalSubject.inputType == InputType.marks) {
        double marks = double.tryParse(_optionalSubject.valueController.text) ?? 0;
        optionalPoint = _getGpaPointFromMarks(marks);
      } else {
        optionalPoint = gpaGradeMap[_optionalSubject.valueController.text] ?? 0.0;
      }
      totalPoints += (optionalPoint > 2.0 ? optionalPoint - 2.0 : 0.0);
      optionalRecord = SubjectRecord(name: _optionalSubject.nameController.text.isEmpty ? _s('optional_subject') : _optionalSubject.nameController.text, value: _optionalSubject.valueController.text);
    }

    double finalGpa = hasFailed ? 0.0 : totalPoints / _subjects.length;
    if (finalGpa > 5.0) finalGpa = 5.0;
    String finalGrade = _getGpaGradeFromGpa(finalGpa);

    setState(() {
      _gpaResult = finalGpa;
      _gradeResult = finalGrade;
      _history.insert(0, CalculationRecord(result: finalGpa.toStringAsFixed(2), grade: finalGrade, timestamp: DateFormat('yyyy-MM-dd – hh:mm a').format(DateTime.now()), subjects: subjectRecords, optionalSubject: optionalRecord));
    });
  }

  void _clearAll() {
    setState(() {
      _subjects.clear();
      _subjects.add(GpaSubject());
      _optionalSubject.nameController.clear(); _optionalSubject.valueController.clear();
      _gpaResult = null; _gradeResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _ResultGauge(result: _gpaResult, grade: _gradeResult, maxResult: 5.0, isBengali: widget.isBengali),
        const SizedBox(height: 24),
        _buildSectionHeader(_s('main_subjects')),
        ..._subjects.map((s) => _buildGpaSubjectInput(_subjects.indexOf(s))).toList(),
        _buildAddButton(_addSubject, _s('add_subject')),
        const Divider(height: 40, color: Colors.white24),
        _buildSectionHeader(_s('optional_subject')),
        _buildGpaSubjectInput(-1),
        const SizedBox(height: 30),
        _buildCalculateButton(onCalculate: _calculateGpa, onClear: _clearAll, label: _s('calculate_gpa'), isBengali: widget.isBengali),
        const SizedBox(height: 24),
        if (_history.isNotEmpty) _HistorySection(history: _history, onClear: () => setState(_history.clear), isBengali: widget.isBengali),
      ],
    );
  }

  Widget _buildGpaSubjectInput(int index) {
    final isOptional = index == -1;
    final subject = isOptional ? _optionalSubject : _subjects[index];

    return _StyledCard(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTextField(controller: subject.nameController, labelText: _s('subject_name'))),
              if (!isOptional && _subjects.length > 1) IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), onPressed: () => _removeSubject(index)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: subject.inputType == InputType.marks
                    ? _buildTextField(controller: subject.valueController, labelText: _s('marks_label'), isNumeric: true)
                    : _buildGradeDropdown(gpaGradeWithMarksMap, subject.valueController, _s('select_grade')),
              ),
              const SizedBox(width: 12),
              _buildToggleButtons(
                subject: subject,
                onPressed: (newIndex) {
                  setState(() {
                    subject.inputType = newIndex == 0 ? InputType.marks : InputType.grade;
                    subject.valueController.clear();
                  });
                },
                isBengali: widget.isBengali,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CgpaSubject {
  final TextEditingController nameController;
  final TextEditingController creditController;
  final TextEditingController valueController;
  InputType inputType;

  CgpaSubject()
      : nameController = TextEditingController(),
        creditController = TextEditingController(),
        valueController = TextEditingController(),
        inputType = InputType.marks;
}

class CgpaCalculatorTab extends StatefulWidget {
  final bool isBengali;
  const CgpaCalculatorTab({super.key, required this.isBengali});

  @override
  State<CgpaCalculatorTab> createState() => _CgpaCalculatorTabState();
}

class _CgpaCalculatorTabState extends State<CgpaCalculatorTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<CgpaSubject> _subjects = [CgpaSubject()];
  double? _cgpaResult;
  final List<CalculationRecord> _history = [];

  String _s(String key) => _translations[key]?[widget.isBengali ? 'bn' : 'en'] ?? key;

  final Map<String, double> cgpaGradeMap = { 'A+': 4.0, 'A': 3.75, 'A-': 3.5, 'B+': 3.25, 'B': 3.0, 'B-': 2.75, 'C+': 2.5, 'C': 2.25, 'D': 2.0, 'F': 0.0 };
  final Map<String, String> cgpaGradeWithMarksMap = { 'A+ (80+)': 'A+', 'A (75-79)': 'A', 'A- (70-74)': 'A-', 'B+ (65-69)': 'B+', 'B (60-64)': 'B', 'B- (55-59)': 'B-', 'C+ (50-54)': 'C+', 'C (45-49)': 'C', 'D (40-44)': 'D', 'F (<40)': 'F' };

  void _addSubject() => setState(() => _subjects.add(CgpaSubject()));
  void _removeSubject(int index) => setState(() => _subjects.removeAt(index));

  double _getCgpaPointFromMarks(double marks) {
    if (marks >= 80) return 4.00; if (marks >= 75) return 3.75; if (marks >= 70) return 3.50;
    if (marks >= 65) return 3.25; if (marks >= 60) return 3.00; if (marks >= 55) return 2.75;
    if (marks >= 50) return 2.50; if (marks >= 45) return 2.25; if (marks >= 40) return 2.00;
    return 0.00;
  }

  void _calculateCgpa() {
    FocusScope.of(context).unfocus();
    double totalCredits = 0;
    double weightedPoints = 0;
    List<SubjectRecord> subjectRecords = [];
    bool hasFailedAny = false;

    if (_subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_s('add_subject_warning')), backgroundColor: Colors.amber));
      return;
    }

    for (var subject in _subjects) {
      double credits = double.tryParse(subject.creditController.text) ?? 0;
      double point = 0;
      if (credits <= 0) continue;

      if (subject.inputType == InputType.marks) {
        double marks = double.tryParse(subject.valueController.text) ?? 0;
        point = _getCgpaPointFromMarks(marks);
      } else {
        point = cgpaGradeMap[subject.valueController.text] ?? 0.0;
      }

      if (point == 0.0 && subject.valueController.text.isNotEmpty) hasFailedAny = true;

      totalCredits += credits;
      weightedPoints += (credits * point);
      subjectRecords.add(SubjectRecord(name: subject.nameController.text.isEmpty ? _s('unnamed_subject') : subject.nameController.text, credits: subject.creditController.text, value: subject.valueController.text));
    }

    double finalCgpa = (totalCredits > 0 && !hasFailedAny) ? weightedPoints / totalCredits : 0.0;
    if (finalCgpa > 4.0) finalCgpa = 4.0;

    setState(() {
      _cgpaResult = finalCgpa;
      _history.insert(0, CalculationRecord(result: finalCgpa.toStringAsFixed(2), timestamp: DateFormat('yyyy-MM-dd – hh:mm a').format(DateTime.now()), subjects: subjectRecords));
    });
  }

  void _clearAll() {
    setState(() {
      _subjects.clear();
      _subjects.add(CgpaSubject());
      _cgpaResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _ResultGauge(result: _cgpaResult, maxResult: 4.0, isBengali: widget.isBengali),
        const SizedBox(height: 24),
        ..._subjects.map((s) => _buildCgpaSubjectInput(_subjects.indexOf(s))).toList(),
        _buildAddButton(_addSubject, _s('add_subject')),
        const SizedBox(height: 30),
        _buildCalculateButton(onCalculate: _calculateCgpa, onClear: _clearAll, label: _s('calculate_cgpa'), isBengali: widget.isBengali),
        const SizedBox(height: 24),
        if (_history.isNotEmpty) _HistorySection(history: _history, onClear: () => setState(_history.clear), isBengali: widget.isBengali),
      ],
    );
  }

  Widget _buildCgpaSubjectInput(int index) {
    final subject = _subjects[index];
    return _StyledCard(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTextField(controller: subject.nameController, labelText: _s('subject_name_optional'))),
              if (_subjects.length > 1) IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), onPressed: () => _removeSubject(index)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(flex: 2, child: _buildTextField(controller: subject.creditController, labelText: _s('credits_label'), isNumeric: true)),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: subject.inputType == InputType.marks
                    ? _buildTextField(controller: subject.valueController, labelText: _s('marks_label'), isNumeric: true)
                    : _buildGradeDropdown(cgpaGradeWithMarksMap, subject.valueController, _s('select_grade')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildToggleButtons(
            subject: subject,
            onPressed: (newIndex) {
              setState(() {
                subject.inputType = newIndex == 0 ? InputType.marks : InputType.grade;
                subject.valueController.clear();
              });
            },
            isBengali: widget.isBengali,
          ),
        ],
      ),
    );
  }
}

const Map<String, Map<String, String>> _translations = {
  'app_bar_title': {'bn': 'GPA এবং CGPA ক্যালকুলেটর', 'en': 'GPA & CGPA Calculator'},
  'gpa_tab': {'bn': 'GPA', 'en': 'GPA'},
  'cgpa_tab': {'bn': 'CGPA', 'en': 'CGPA'},
  'result': {'bn': 'ফলাফল', 'en': 'Result'},
  'main_subjects': {'bn': 'প্রধান বিষয়', 'en': 'Main Subjects'},
  'add_subject': {'bn': 'বিষয় যোগ করুন', 'en': 'Add Subject'},
  'optional_subject': {'bn': 'ঐচ্ছিক বিষয়', 'en': 'Optional Subject'},
  'calculate_gpa': {'bn': 'GPA হিসাব করুন', 'en': 'Calculate GPA'},
  'calculate_cgpa': {'bn': 'CGPA হিসাব করুন', 'en': 'Calculate CGPA'},
  'history': {'bn': 'হিসাবের ইতিহাস', 'en': 'Calculation History'},
  'clear_history': {'bn': 'সব মুছুন', 'en': 'Clear All'},
  'confirm_clear': {'bn': 'নিশ্চিত করুন', 'en': 'Confirm Clear'},
  'confirm_clear_message': {'bn': 'আপনি কি সব ইতিহাস মুছে ফেলতে চান?', 'en': 'Are you sure you want to delete all history?'},
  'cancel': {'bn': 'বাতিল', 'en': 'Cancel'},
  'delete': {'bn': 'মুছে ফেলুন', 'en': 'Delete'},
  'subject_name': {'bn': 'বিষয়ের নাম (ঐচ্ছিক)', 'en': 'Subject Name (Optional)'},
  'subject_name_optional': {'bn': 'বিষয়ের নাম (ঐচ্ছিক)', 'en': 'Subject Name (Optional)'},
  'marks_label': {'bn': 'নম্বর (১০০ এর মধ্যে)', 'en': 'Marks (Out of 100)'},
  'select_grade': {'bn': 'গ্রেড নির্বাচন করুন', 'en': 'Select Grade'},
  'marks_toggle': {'bn': 'নম্বর', 'en': 'Marks'},
  'grade_toggle': {'bn': 'গ্রেড', 'en': 'Grade'},
  'credits_label': {'bn': 'ক্রেডিট', 'en': 'Credits'},
  'add_subject_warning': {'bn': 'অনুগ্রহ করে অন্তত একটি প্রধান বিষয় যোগ করুন।', 'en': 'Please add at least one main subject.'},
  'unnamed_subject': {'bn': 'নামবিহীন বিষয়', 'en': 'Unnamed Subject'},
  'reset_btn': {'bn': 'রিসেট', 'en': 'Reset'},
};


class _ResultGauge extends StatelessWidget {
  final double? result;
  final String? grade;
  final double maxResult;
  final bool isBengali;

  const _ResultGauge({this.result, this.grade, required this.maxResult, required this.isBengali});

  String _s(String key) => _translations[key]?[isBengali ? 'bn' : 'en'] ?? key;

  @override
  Widget build(BuildContext context) {
    final hasResult = result != null;
    final percentage = (result ?? 0.0) / maxResult;
    final Color progressColor = Color.lerp(Colors.redAccent, Colors.greenAccent.shade400, percentage)!;

    return _StyledCard(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 160, height: 160,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: hasResult ? percentage : 0.0),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return CircularProgressIndicator(
                    value: value, strokeWidth: 12,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    strokeCap: StrokeCap.round,
                  );
                },
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
              child: hasResult
                  ? Column(
                key: ValueKey(result),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(result!.toStringAsFixed(2), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, fontFeatures: [FontFeature.tabularFigures()])),
                  if (grade != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: progressColor, borderRadius: BorderRadius.circular(30)),
                      child: Text(grade!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                  ],
                ],
              )
                  : Text( _s('result'), key: const ValueKey('prompt'), style: TextStyle(fontSize: 22, color: Colors.white.withOpacity(0.5))),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final List<CalculationRecord> history;
  final VoidCallback onClear;
  final bool isBengali;

  const _HistorySection({required this.history, required this.onClear, required this.isBengali});

  String _s(String key) => _translations[key]?[isBengali ? 'bn' : 'en'] ?? key;

  @override
  Widget build(BuildContext context) {
    return _StyledCard(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: ExpansionTile(
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        title: Text(_s('history'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: const Icon(Icons.history, color: Colors.white70),
        trailing: IconButton(
          icon: const Icon(Icons.delete_sweep_outlined),
          tooltip: _s('clear_history'),
          onPressed: () => showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(_s('confirm_clear')),
              content: Text(_s('confirm_clear_message')),
              actions: [
                TextButton(child: Text(_s('cancel')), onPressed: () => Navigator.of(ctx).pop()),
                TextButton(
                  child: Text(_s('delete'), style: const TextStyle(color: Colors.redAccent)),
                  onPressed: () { onClear(); Navigator.of(ctx).pop(); },
                ),
              ],
            ),
          ),
          color: Colors.redAccent.withOpacity(0.8),
        ),
        children: history.map((record) {
          String title = record.grade != null
              ? 'GPA: ${record.result}, Grade: ${record.grade}'
              : 'CGPA: ${record.result}';

          return ExpansionTile(
            iconColor: Colors.white54,
            collapsedIconColor: Colors.white54,
            title: Text(title, style: const TextStyle(color: Colors.white)),
            subtitle: Text(record.timestamp, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            children: [
              ...record.subjects.map((sub) => ListTile(
                dense: true,
                title: Text(sub.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(sub.credits != null ? '${_s("credits_label")}: ${sub.credits}, Value: ${sub.value}' : 'Value: ${sub.value}', style: const TextStyle(color: Colors.white70)),
              )),
              if (record.optionalSubject != null)
                ListTile(
                  dense: true,
                  title: Text(record.optionalSubject!.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text('Value: ${record.optionalSubject!.value}', style: const TextStyle(color: Colors.white70)),
                  leading: const Icon(Icons.star_border, color: Colors.amberAccent),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

Widget _buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 4, top: 8),
    child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
  );
}

Widget _buildTextField({required TextEditingController controller, required String labelText, bool isNumeric = false}) {
  return TextFormField(
    controller: controller,
    keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.blue.shade200.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.black.withOpacity(0.2),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}

Widget _buildGradeDropdown(Map<String, String> gradeMap, TextEditingController controller, String hint) {
  return DropdownButtonFormField<String>(
    value: gradeMap.values.contains(controller.text) ? controller.text : null,
    hint: Text(hint, style: TextStyle(color: Colors.blue.shade200.withOpacity(0.7))),
    isExpanded: true,
    dropdownColor: const Color(0xFF1F2C50),
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: Colors.black.withOpacity(0.2),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
    items: gradeMap.entries.map((entry) => DropdownMenuItem(value: entry.value, child: Text(entry.key))).toList(),
    onChanged: (value) => controller.text = value ?? '',
  );
}

Widget _buildToggleButtons({required dynamic subject, required void Function(int) onPressed, required bool isBengali}) {
  String _s(String key) => _translations[key]?[isBengali ? 'bn' : 'en'] ?? key;
  return Material(
    color: Colors.black.withOpacity(0.2),
    borderRadius: BorderRadius.circular(10),
    child: ToggleButtons(
      isSelected: [subject.inputType == InputType.marks, subject.inputType == InputType.grade],
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(10),
      color: Colors.white70,
      selectedColor: Colors.black,
      fillColor: const Color(0xFF007BFF),
      borderColor: Colors.white24,
      selectedBorderColor: const Color(0xFF007BFF),
      renderBorder: false,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(_s('marks_toggle'))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(_s('grade_toggle'))),
      ],
    ),
  );
}


Widget _buildAddButton(VoidCallback onPressed, String label) {
  return Center(
    child: TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_circle_outline),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF007BFF),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
  );
}

Widget _buildCalculateButton({required VoidCallback onCalculate, required VoidCallback onClear, required String label, required bool isBengali}) {
  String _s(String key) => _translations[key]?[isBengali ? 'bn' : 'en'] ?? key;
  return Row(
    children: [
      Expanded(
        child: ElevatedButton(
          onPressed: onCalculate,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFF007BFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(width: 12),
      IconButton(
        onPressed: onClear,
        icon: const Icon(Icons.refresh),
        tooltip: _s('reset_btn'),
        style: IconButton.styleFrom(
          foregroundColor: Colors.white70,
          backgroundColor: Colors.white.withOpacity(0.1),
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      )
    ],
  );
}


class _StyledCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  const _StyledCard({required this.child, this.margin, this.padding});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: const Color(0xFF1A1F2C).withOpacity(0.5),
      shadowColor: Colors.black.withOpacity(0.5),
      margin: margin,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.15))
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}

class _AnimatedBackground extends StatefulWidget {
  final Widget child;
  const _AnimatedBackground({required this.child});

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [
                Color(0xFF0A0F1A), // Darker base
                Color(0xFF10141C), // Dark base
                Color(0xFF0B2A4B), // Dark blue
                Color(0xFF3A2A5B), // Dark purple
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: GradientRotation(_controller.value * 2 * math.pi),
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}