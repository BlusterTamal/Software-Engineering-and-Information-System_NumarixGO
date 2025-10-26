/*
 * File: lib/features/bmi_calculator.dart
 * Location: /c:/Users/Tamal/Documents/smart_numerix_v2/lib/features/bmi_calculator.dart
 * Description: Body Mass Index calculator with color-coded results and history tracking
 */

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'dart:math' as math;

enum HeightUnit { cm, ftIn }

class BmiRecord {
  final double bmi;
  final String category;
  final double weight;
  final double height; // Always stored in cm for consistency
  final String date;

  BmiRecord({
    required this.bmi,
    required this.category,
    required this.weight,
    required this.height,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'bmi': bmi, 'category': category, 'weight': weight, 'height': height, 'date': date,
  };

  factory BmiRecord.fromJson(Map<String, dynamic> json) => BmiRecord(
    bmi: json['bmi'], category: json['category'], weight: json['weight'],
    height: json['height'], date: json['date'],
  );
}

class BmiCalculatorPage extends StatefulWidget {
  const BmiCalculatorPage({super.key});

  @override
  _BmiCalculatorPageState createState() => _BmiCalculatorPageState();
}

class _BmiCalculatorPageState extends State<BmiCalculatorPage> {
  final TextEditingController _heightCmController = TextEditingController(text: '170');
  final TextEditingController _heightFeetController = TextEditingController(text: '5');
  final TextEditingController _heightInchesController = TextEditingController(text: '7');
  final TextEditingController _weightController = TextEditingController(text: '70');

  double? _bmi;
  String? _category;
  String? _suggestion;

  HeightUnit _heightUnit = HeightUnit.cm;
  List<BmiRecord> _history = [];
  static const String _historyKey = 'bmi_history';
  bool _isBengali = true;

  String _s(String key) => _translations[key]?[_isBengali ? 'bn' : 'en'] ?? key;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _calculateBMI(fromButton: false);
  }

  @override
  void dispose() {
    _heightCmController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _toggleLanguage() {
    setState(() {
      _isBengali = !_isBengali;
      if (_bmi != null) {
        _calculateBMI(fromButton: false);
      }
    });
  }

  void _calculateBMI({bool fromButton = true}) {
    if (fromButton) FocusScope.of(context).unfocus();

    double heightCm = 0;
    final double weight = double.tryParse(_weightController.text) ?? 0;

    if (_heightUnit == HeightUnit.ftIn) {
      final double feet = double.tryParse(_heightFeetController.text) ?? 0;
      final double inches = double.tryParse(_heightInchesController.text) ?? 0;
      heightCm = (feet * 30.48) + (inches * 2.54);
    } else {
      heightCm = double.tryParse(_heightCmController.text) ?? 0;
    }

    if (heightCm <= 0 || weight <=0) {
      if(fromButton) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_s('invalid_input_error')), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    double heightInMeters = heightCm / 100;
    double bmi = weight / (heightInMeters * heightInMeters);
    String category;
    String suggestion;

    if (bmi < 18.5) {
      category = _s('cat_underweight');
      suggestion = _s('sugg_underweight');
    } else if (bmi < 25) {
      category = _s('cat_normal');
      suggestion = _s('sugg_normal');
    } else if (bmi < 30) {
      category = _s('cat_overweight');
      suggestion = _s('sugg_overweight');
    } else {
      category = _s('cat_obese');
      suggestion = _s('sugg_obese');
    }

    setState(() {
      _bmi = bmi;
      _category = category;
      _suggestion = suggestion;
    });

    if (fromButton) _saveRecord(heightCm, weight);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString(_historyKey);
    if (historyString != null) {
      final List<dynamic> historyJson = jsonDecode(historyString);
      setState(() {
        _history = historyJson.map((json) => BmiRecord.fromJson(json)).toList();
      });
    }
  }

  Future<void> _saveRecord(double height, double weight) async {
    if (_bmi == null || _category == null) return;
    final prefs = await SharedPreferences.getInstance();
    final newRecord = BmiRecord(
      bmi: _bmi!,
      category: _category!,
      weight: weight,
      height: height,
      date: DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
    );

    setState(() { _history.insert(0, newRecord); });
    final String historyString = jsonEncode(_history.map((record) => record.toJson()).toList());
    await prefs.setString(_historyKey, historyString);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_s('save_success'))),
    );
  }

  Future<void> _deleteRecord(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _history.removeAt(index); });
    final String historyString = jsonEncode(_history.map((record) => record.toJson()).toList());
    await prefs.setString(_historyKey, historyString);
  }

  Future<void> _clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _history.clear(); });
    await prefs.remove(_historyKey);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_s('app_title')),
        backgroundColor: const Color(0xFF10141C).withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        actions: [
          TextButton(
            onPressed: _toggleLanguage,
            style: TextButton.styleFrom(foregroundColor: Colors.white, shape: const CircleBorder()),
            child: Text(_isBengali ? 'EN' : 'BN', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: _AnimatedBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (_bmi != null && _category != null) _buildResultCard(),
              const SizedBox(height: 24),
              _buildInputSection(),
              if (_suggestion != null) ...[
                const SizedBox(height: 24),
                _buildSuggestionCard(),
              ],
              const SizedBox(height: 24),
              _buildBmiCategoriesInfo(),
              const SizedBox(height: 24),
              if (_history.isNotEmpty) _buildHistorySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return _StyledCard(
      child: Column(
        children: [
          _buildHeightInputCard(),
          const SizedBox(height: 16),
          _buildWeightInputCard(),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.calculate_outlined), label: Text(_s('calculate_btn')),
            onPressed: _calculateBMI,
            style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF007BFF),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightInputCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_s('weight_label'), style: const TextStyle(fontSize: 16, color: Colors.white70)),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _weightController,
          icon: Icons.monitor_weight_outlined,
          suffixText: 'kg',
        )
      ],
    );
  }

  Widget _buildHeightInputCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_s('height_label'), style: const TextStyle(fontSize: 16, color: Colors.white70)),
            ToggleButtons(
              isSelected: [_heightUnit == HeightUnit.cm, _heightUnit == HeightUnit.ftIn],
              onPressed: (index) {
                setState(() { _heightUnit = index == 0 ? HeightUnit.cm : HeightUnit.ftIn; });
              },
              borderRadius: BorderRadius.circular(30.0),
              color: Colors.white70,
              selectedColor: Colors.white,
              fillColor: const Color(0xFF007BFF).withOpacity(0.5),
              borderColor: const Color(0xFF007BFF),
              selectedBorderColor: const Color(0xFF007BFF),
              borderWidth: 1,
              constraints: const BoxConstraints(minHeight: 32, minWidth: 64),
              children: const [ Text('cm'), Text('ft/in')],
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _heightUnit == HeightUnit.cm
              ? _buildTextField(controller: _heightCmController, icon: Icons.straighten_outlined, suffixText: 'cm')
              : Row(
            children: [
              Expanded(child: _buildTextField(controller: _heightFeetController, icon: Icons.straighten_outlined, suffixText: 'ft')),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(controller: _heightInchesController, icon: null, suffixText: 'in')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({required TextEditingController controller, IconData? icon, required String suffixText}) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
        suffixText: suffixText,
        suffixStyle: const TextStyle(color: Colors.white70, fontSize: 16),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildResultCard() {
    final double normalizedBmi = (_bmi!.clamp(10, 40) - 10) / 30;

    return Center(
      child: SizedBox(
        height: 220,
        width: 220,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: normalizedBmi),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: value, strokeWidth: 16,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor()),
                ),
                child!,
              ],
            );
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_s('your_bmi'), style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7))),
                Text(_bmi!.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(_category!, style: TextStyle(fontSize: 20, color: _getCategoryColor(), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionCard() {
    return _StyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Colors.yellow),
              const SizedBox(width: 8),
              Text(_s('suggestion_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const Divider(height: 24, color: Colors.white24),
          Text(_suggestion!, style: TextStyle(fontSize: 15, height: 1.6, color: Colors.white.withOpacity(0.9))),
        ],
      ),
    );
  }

  Widget _buildBmiCategoriesInfo() {
    return _StyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_s('categories_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          _buildCategoryRow(_s('cat_underweight'), '< 18.5', const Color(0xFF3B82F6)),
          _buildCategoryRow(_s('cat_normal'), '18.5 - 24.9', const Color(0xFF22C55E)),
          _buildCategoryRow(_s('cat_overweight'), '25 - 29.9', const Color(0xFFF97316)),
          _buildCategoryRow(_s('cat_obese'), '≥ 30', const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return _StyledCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        iconColor: Colors.white,
        collapsedIconColor: Colors.white70,
        title: Text(_s('history_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: const Icon(Icons.history, color: Colors.white70),
        trailing: IconButton(
          icon: const Icon(Icons.delete_sweep_outlined),
          tooltip: _s('clear_history'),
          onPressed: () => showDialog(
            context: context, builder: (ctx) => AlertDialog(
            title: Text(_s('confirm_clear')), content: Text(_s('confirm_clear_message')),
            actions: [
              TextButton(child: Text(_s('cancel')), onPressed: () => Navigator.of(ctx).pop()),
              TextButton(child: Text(_s('delete'), style: const TextStyle(color: Colors.redAccent)), onPressed: _clearAllHistory),
            ],
          ),
          ),
          color: Colors.redAccent.withOpacity(0.8),
        ),
        children: _history.map((record) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColorForRecord(record.category),
              child: Text(record.bmi.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            title: Text(record.category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('W: ${record.weight.toStringAsFixed(1)}kg, H: ${record.height.toStringAsFixed(1)}cm\n${record.date}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteRecord(_history.indexOf(record)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryRow(String category, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(category, style: const TextStyle(fontSize: 16, color: Colors.white)),
          const Spacer(),
          Text(range, style: const TextStyle(fontSize: 16, color: Colors.white70)),
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    if (_category == _s('cat_underweight')) return const Color(0xFF3B82F6);
    if (_category == _s('cat_normal')) return const Color(0xFF22C55E);
    if (_category == _s('cat_overweight')) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  Color _getCategoryColorForRecord(String category) {
    if (category == _s('cat_underweight')) return const Color(0xFF3B82F6);
    if (category == _s('cat_normal')) return const Color(0xFF22C55E);
    if (category == _s('cat_overweight')) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }
}

class _StyledCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const _StyledCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: const Color(0xFF1A1F2C).withOpacity(0.5),
      shadowColor: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.15))
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20.0),
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
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat(reverse: true);
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
              colors: const [ Color(0xFF0A0F1A), Color(0xFF10141C), Color(0xFF042f2e), Color(0xFF021a2a), ],
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

const Map<String, Map<String, String>> _translations = {
  'app_title': {'bn': 'BMI ক্যালকুলেটর', 'en': 'BMI Calculator'},
  'your_bmi': {'bn': 'আপনার BMI', 'en': 'Your BMI'},
  'calculate_btn': {'bn': 'হিসাব করুন এবং সংরক্ষণ করুন', 'en': 'Calculate & Save'},
  'weight_label': {'bn': 'ওজন', 'en': 'Weight'},
  'height_label': {'bn': 'উচ্চতা', 'en': 'Height'},
  'invalid_input_error': {'bn': 'অনুগ্রহ করে সঠিক ওজন এবং উচ্চতা লিখুন।', 'en': 'Please enter a valid weight and height.'},
  'save_success': {'bn': 'ফলাফল ইতিহাসে সংরক্ষণ করা হয়েছে!', 'en': 'Result saved to history!'},
  'suggestion_title': {'bn': 'বিস্তারিত পরামর্শ', 'en': 'Detailed Suggestion'},
  'categories_title': {'bn': 'BMI বিভাগ', 'en': 'BMI Categories'},
  'history_title': {'bn': 'ইতিহাস', 'en': 'History'},
  'clear_history': {'bn': 'সব মুছুন', 'en': 'Clear All'},
  'confirm_clear': {'bn': 'নিশ্চিত করুন', 'en': 'Confirm Clear'},
  'confirm_clear_message': {'bn': 'আপনি কি সব ইতিহাস মুছে ফেলতে চান?', 'en': 'Are you sure you want to delete all history?'},
  'cancel': {'bn': 'বাতিল', 'en': 'Cancel'},
  'delete': {'bn': 'মুছে ফেলুন', 'en': 'Delete'},
  'cat_underweight': {'bn': 'স্বল্প ওজন', 'en': 'Underweight'},
  'cat_normal': {'bn': 'স্বাভাবিক', 'en': 'Normal'},
  'cat_overweight': {'bn': 'অতিরিক্ত ওজন', 'en': 'Overweight'},
  'cat_obese': {'bn': 'স্থূল', 'en': 'Obese'},
  'sugg_underweight': {'bn': 'আপনার ওজন স্বাভাবিকের চেয়ে কম।\n\nখাবার: পুষ্টিকর এবং ক্যালোরিযুক্ত খাবার যেমন - বাদাম, খেজুর, দুধ, ডিম, এবং স্বাস্থ্যকর ফ্যাট গ্রহণ করুন।\n\nব্যায়াম: ওজন বাড়ানোর জন্য হালকা ব্যায়াম যেমন - যোগব্যায়াম বা ওয়েট ট্রেনিং করুন।', 'en': 'Your weight is lower than normal.\n\nFood: Consume nutritious and calorie-rich foods like nuts, dates, milk, eggs, and healthy fats.\n\nExercise: Do light exercises like yoga or weight training to gain weight.'},
  'sugg_normal': {'bn': 'অভিনন্দন! আপনার ওজন সঠিক আছে।\n\nখাবার: সুষম খাদ্য গ্রহণ করুন। আপনার প্লেটে অর্ধেক সবজি, এক চতুর্থাংশ প্রোটিন এবং এক চতুর্থাংশ কার্বোহাইড্রেট রাখুন।\n\nব্যায়াম: সপ্তাহে অন্তত ১৫০ মিনিট মাঝারি তীব্রতার ব্যায়াম করুন, যেমন - দ্রুত হাঁটা বা সাঁতার।', 'en': 'Congratulations! Your weight is perfect.\n\nFood: Maintain a balanced diet. Fill half your plate with vegetables, a quarter with protein, and a quarter with carbs.\n\nExercise: Engage in at least 150 minutes of moderate-intensity exercise per week, such as brisk walking or swimming.'},
  'sugg_overweight': {'bn': 'আপনার ওজন স্বাভাবিকের চেয়ে বেশি।\n\nখাবার: ফাইবারযুক্ত খাবার যেমন - ফল, সবজি, এবং ডাল বেশি করে খান। ভাজা খাবার ও ফাস্ট ফুড এড়িয়ে চলুন।\n\nব্যায়াম: ওজন কমাতে কার্ডিও ব্যায়াম (দৌড়ানো, সাঁতার) এবং ওয়েট ট্রেনিংয়ের সমন্বয় করুন।', 'en': 'Your weight is higher than normal.\n\nFood: Eat more fiber-rich foods like fruits, vegetables, and lentils. Avoid fried foods and fast food.\n\nExercise: Combine cardio exercises (running, swimming) and weight training to lose weight.'},
  'sugg_obese': {'bn': 'আপনি স্থূলতায় ভুগছেন। এটি স্বাস্থ্যের জন্য ঝুঁকিপূর্ণ।\n\nখাবার: কম ক্যালোরিযুক্ত এবং উচ্চ পুষ্টির খাবার গ্রহণ করুন। চিনি এবং অস্বাস্থ্যকর চর্বিযুক্ত খাবার বাদ দিন।\n\nব্যায়াম: বিশেষজ্ঞ ডাক্তার বা পুষ্টিবিদের পরামর্শ নিন। সাঁতার বা সাইকেল চালানোর মতো লো-ইমপ্যাক্ট ব্যায়াম দিয়ে শুরু করুন।', 'en': 'You are suffering from obesity. This is a health risk.\n\nFood: Consume low-calorie and high-nutrition meals. Avoid sugar and unhealthy fats.\n\nExercise: Consult a doctor or nutritionist. Start with low-impact exercises like swimming or cycling.'},
};