/*
 * File: lib/features/bmr_calculator.dart
 * Location: /c:/Users/Tamal/Documents/smart_numerix_v2/lib/features/bmr_calculator.dart
 * Description: Basal Metabolic Rate calculator for fitness planning
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;

enum Gender { male, female }
enum HeightUnit { cm, ftIn }

class BmrCalculatorPage extends StatefulWidget {
  const BmrCalculatorPage({super.key});

  @override
  State<BmrCalculatorPage> createState() => _BmrCalculatorPageState();
}

class _BmrCalculatorPageState extends State<BmrCalculatorPage> {
  final _formKey = GlobalKey<FormState>();

  final _ageController = TextEditingController(text: '25');
  final _weightController = TextEditingController(text: '70');
  final _heightCmController = TextEditingController(text: '175');
  final _heightFtController = TextEditingController(text: '5');
  final _heightInController = TextEditingController(text: '9');

  Gender _selectedGender = Gender.male;
  HeightUnit _selectedHeightUnit = HeightUnit.cm;
  String _activityLevelKey = 'sedentary';
  double? _bmrResult;
  double? _tdeeResult;
  String _currentLocale = 'bn';

  String tr(String key) => _localizedValues[_currentLocale]![key] ?? key;

  void _toggleLocale() => setState(() => _currentLocale = _currentLocale == 'bn' ? 'en' : 'bn');

  final Map<String, Map<String, dynamic>> _activityLevels = {
    'sedentary': {'en': 'Sedentary (little or no exercise)', 'bn': 'কর্মহীন (খুব কম বা কোনো ব্যায়াম নেই)', 'multiplier': 1.2},
    'lightly_active': {'en': 'Lightly active (exercise 1-3 days/week)', 'bn': 'হালকা সক্রিয় (সপ্তাহে ১-৩ দিন ব্যায়াম)', 'multiplier': 1.375},
    'moderately_active': {'en': 'Moderately active (exercise 3-5 days/week)', 'bn': 'মাঝারি সক্রিয় (সপ্তাহে ৩-৫ দিন ব্যায়াম)', 'multiplier': 1.55},
    'very_active': {'en': 'Very active (exercise 6-7 days/week)', 'bn': 'খুব সক্রিয় (সপ্তাহে ৬-৭ দিন ব্যায়াম)', 'multiplier': 1.725},
    'extra_active': {'en': 'Extra active (very hard exercise & physical job)', 'bn': 'অতিরিক্ত সক্রিয় (খুব কঠিন ব্যায়াম ও শারীরিক পরিশ্রম)', 'multiplier': 1.9},
  };

  void _calculateBmr() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      int age = int.tryParse(_ageController.text) ?? 0;
      double weight = double.tryParse(_weightController.text) ?? 0;
      double heightInCm;

      if (_selectedHeightUnit == HeightUnit.ftIn) {
        int feet = int.tryParse(_heightFtController.text) ?? 0;
        int inches = int.tryParse(_heightInController.text) ?? 0;
        heightInCm = (feet * 30.48) + (inches * 2.54);
      } else {
        heightInCm = double.tryParse(_heightCmController.text) ?? 0;
      }

      if (age <= 0 || weight <= 0 || heightInCm <= 0) {
        setState(() { _bmrResult = null; _tdeeResult = null; });
        return;
      }

      double bmr;
      if (_selectedGender == Gender.male) {
        bmr = 88.362 + (13.397 * weight) + (4.799 * heightInCm) - (5.677 * age);
      } else {
        bmr = 447.593 + (9.247 * weight) + (3.098 * heightInCm) - (4.330 * age);
      }

      double tdee = bmr * _activityLevels[_activityLevelKey]!['multiplier'];

      setState(() {
        _bmrResult = bmr;
        _tdeeResult = tdee;
      });
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightCmController.dispose();
    _heightFtController.dispose();
    _heightInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('appTitle')),
        backgroundColor: const Color(0xFF10141C).withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _toggleLocale,
              style: TextButton.styleFrom(foregroundColor: Colors.white, shape: const CircleBorder()),
              child: Text(_currentLocale == 'bn' ? 'EN' : 'BN', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: _AnimatedBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (_tdeeResult != null && _tdeeResult! > 0)
                _ResultGauge(tdeeResult: _tdeeResult!, bmrResult: _bmrResult!, locale: _currentLocale),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildGenderSelector(),
                    const SizedBox(height: 20),
                    _buildInputCard(),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _calculateBmr,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF007BFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      child: Text(tr('calculate')),
                    ),
                    const SizedBox(height: 24),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                      child: (_tdeeResult != null && _tdeeResult! > 0)
                          ? _buildSuggestionsSection()
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        Expanded(child: _GenderCard(
          icon: Icons.male,
          label: tr('male'),
          isSelected: _selectedGender == Gender.male,
          onTap: () => setState(() => _selectedGender = Gender.male),
        )),
        const SizedBox(width: 16),
        Expanded(child: _GenderCard(
          icon: Icons.female,
          label: tr('female'),
          isSelected: _selectedGender == Gender.female,
          onTap: () => setState(() => _selectedGender = Gender.female),
        )),
      ],
    );
  }

  Widget _buildInputCard() {
    return _StyledCard(
      child: Column(
        children: [
          _buildTextFormField(controller: _ageController, label: tr('age'), hint: tr('ageHint'), icon: Icons.cake_outlined),
          const SizedBox(height: 20),
          _buildTextFormField(controller: _weightController, label: tr('weight'), hint: tr('weightHint'), icon: Icons.monitor_weight_outlined),
          const SizedBox(height: 20),
          _buildHeightInput(),
          const SizedBox(height: 20),
          _buildActivitySelector(),
        ],
      ),
    );
  }

  Widget _buildHeightInput() {
    return Column(
      children: [
        ToggleButtons(
          isSelected: [_selectedHeightUnit == HeightUnit.cm, _selectedHeightUnit == HeightUnit.ftIn],
          onPressed: (index) => setState(() => _selectedHeightUnit = index == 0 ? HeightUnit.cm : HeightUnit.ftIn),
          borderRadius: BorderRadius.circular(30),
          color: Colors.white70, selectedColor: Colors.white,
          fillColor: const Color(0xFF007BFF).withOpacity(0.5),
          borderColor: const Color(0xFF007BFF), selectedBorderColor: const Color(0xFF007BFF),
          borderWidth: 1, constraints: const BoxConstraints(minHeight: 32, minWidth: 64),
          children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('cm')), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('ft/in'))],
        ),
        const SizedBox(height: 15),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _selectedHeightUnit == HeightUnit.cm
              ? _buildTextFormField(key: const ValueKey('cm'), controller: _heightCmController, label: tr('height_cm'), hint: tr('height_cm_hint'), icon: Icons.height_rounded)
              : Row(
            key: const ValueKey('ft_in'),
            children: [
              Expanded(child: _buildTextFormField(controller: _heightFtController, label: tr('feet'), hint: tr('feetHint'), icon: Icons.height_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _buildTextFormField(controller: _heightInController, label: tr('inches'), hint: tr('inchesHint'))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller, required String label,
    required String hint, IconData? icon, Key? key,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        labelStyle: TextStyle(color: Colors.blue.shade200.withOpacity(0.7)),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter a value';
        if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Invalid number';
        if (label == tr('inches') && double.parse(value) >= 12) return 'Must be < 12';
        return null;
      },
    );
  }

  Widget _buildActivitySelector() {
    return DropdownButtonFormField<String>(
      value: _activityLevelKey,
      isExpanded: true, // <-- FIX 1: Add this property
      decoration: InputDecoration(
        labelText: tr('activityLevel'),
        labelStyle: TextStyle(color: Colors.blue.shade200.withOpacity(0.7)),
        prefixIcon: const Icon(Icons.directions_run, color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      dropdownColor: const Color(0xFF1F2C50),
      style: const TextStyle(color: Colors.white),
      items: _activityLevels.keys.map((String key) {
        return DropdownMenuItem<String>(
          value: key,
          child: Text(
            '${_activityLevels[key]![_currentLocale]}',
            overflow: TextOverflow.ellipsis, // <-- FIX 2: Add this property
          ),
        );
      }).toList(),
      onChanged: (String? newValue) => setState(() => _activityLevelKey = newValue!),
    );
  }

  Widget _buildSuggestionsSection() {
    return Column(
      children: [
        _buildDetailedSuggestions(),
        const SizedBox(height: 24),
        _buildHealthDisclaimer(),
      ],
    );
  }

  Widget _buildHealthDisclaimer() {
    return _StyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              const SizedBox(width: 12),
              Text(tr('healthAlertTitle'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const Divider(height: 24, color: Colors.white24),
          Text(tr('alert1'), style: TextStyle(color: Colors.white.withOpacity(0.9), height: 1.5)),
          Text(tr('alert2'), style: TextStyle(color: Colors.white.withOpacity(0.9), height: 1.5)),
          Text(tr('alert3'), style: TextStyle(color: Colors.white.withOpacity(0.9), height: 1.5)),
          const SizedBox(height: 12),
          Text(tr('alert4'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildDetailedSuggestions() {
    final weightLossCalories = _tdeeResult! > 500 ? _tdeeResult! - 500 : _tdeeResult! * 0.8;
    final weightGainCalories = _tdeeResult! + 500;

    return _StyledCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('suggestionsTitle'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            _FoodSuggestionCard(
              icon: Icons.trending_down,
              color: const Color(0xFFF97316),
              title: tr('lossTitle'),
              calorieInfo: '≈ ${weightLossCalories.toStringAsFixed(0)} ${tr('caloriesSuffix')}',
              foods: _currentLocale == 'bn'
                  ? ['সবুজ শাকসবজি', 'মুরগির বুকের মাংস', 'ডিমের সাদা অংশ', 'টক দই', 'সালাদ']
                  : ['Green Vegetables', 'Chicken Breast', 'Egg Whites', 'Yogurt', 'Salad'],
            ),
            const SizedBox(height: 16),
            _FoodSuggestionCard(
              icon: Icons.sync,
              color: const Color(0xFF22C55E),
              title: tr('maintainTitle'),
              calorieInfo: '≈ ${_tdeeResult!.toStringAsFixed(0)} ${tr('caloriesSuffix')}',
              foods: _currentLocale == 'bn'
                  ? ['বাদামী চালের ভাত', 'আটার রুটি', 'ডাল', 'মাছ', 'মৌসুমি ফল']
                  : ['Brown Rice', 'Whole Wheat Bread', 'Lentils', 'Fish', 'Seasonal Fruits'],
            ),
            const SizedBox(height: 16),
            _FoodSuggestionCard(
              icon: Icons.trending_up,
              color: const Color(0xFF3B82F6),
              title: tr('gainTitle'),
              calorieInfo: '≈ ${weightGainCalories.toStringAsFixed(0)} ${tr('caloriesSuffix')}',
              foods: _currentLocale == 'bn'
                  ? ['দুধ ও কলার শেক', 'সম্পূর্ণ ডিম', 'আলু', 'লাল মাংস', 'পিনাট বাটার']
                  : ['Milk & Banana Shake', 'Whole Eggs', 'Potatoes', 'Red Meat', 'Peanut Butter'],
            ),
          ],
        ));
  }
}

class _GenderCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({ required this.icon, required this.label, required this.isSelected, required this.onTap });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007BFF).withOpacity(0.5) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF007BFF) : Colors.white.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ResultGauge extends StatelessWidget {
  final double tdeeResult;
  final double bmrResult;
  final String locale;

  const _ResultGauge({required this.tdeeResult, required this.bmrResult, required this.locale});

  String tr(String key) => _localizedValues[locale]![key] ?? key;


  @override
  Widget build(BuildContext context) {
    final double visualMax = math.max(3000, tdeeResult * 1.2);
    final double percentage = (tdeeResult / visualMax).clamp(0.0, 1.0);

    return _StyledCard(
      child: Column(
        children: [
          SizedBox(
            height: 180,
            width: 180,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: percentage),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 14,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007BFF)),
                      strokeCap: StrokeCap.round,
                    ),
                    child!,
                  ],
                );
              },
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tr('tdeeLabel'),
                      style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)),
                    ),
                    Text(
                      tdeeResult.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      tr('caloriesSuffix'),
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 30, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${tr('bmrLabel')}:',
                style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
              ),
              const SizedBox(width: 8),
              Text(
                '${bmrResult.toStringAsFixed(0)} ${tr('caloriesSuffix')}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _StyledCard extends StatelessWidget {
  final Widget child;
  const _StyledCard({required this.child});

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
        padding: const EdgeInsets.all(20.0),
        child: child,
      ),
    );
  }
}

class _FoodSuggestionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String calorieInfo;
  final List<String> foods;

  const _FoodSuggestionCard({ required this.icon, required this.color, required this.title, required this.calorieInfo, required this.foods });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color))),
              Text(calorieInfo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white.withOpacity(0.9))),
            ],
          ),
          const Divider(height: 20, color: Colors.white24),
          ...foods.map((food) => Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white54, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(food, style: const TextStyle(color: Colors.white, fontSize: 14))),
              ],
            ),
          )),
        ],
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
              colors: const [ Color(0xFF0A0F1A), Color(0xFF10141C), Color(0xFF0B2A4B), Color(0xFF3A2A5B), ],
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

const Map<String, Map<String, String>> _localizedValues = {
  'en': {
    'appTitle': 'BMR & Calorie Calculator',
    'male': 'Male',
    'female': 'Female',
    'age': 'Age',
    'ageHint': 'e.g., 25',
    'weight': 'Weight (kg)',
    'weightHint': 'e.g., 70',
    'height_cm': 'Height (cm)',
    'height_cm_hint': 'e.g., 175',
    'feet': 'Feet',
    'feetHint': 'e.g., 5',
    'inches': 'Inches',
    'inchesHint': 'e.g., 9',
    'activityLevel': 'Activity Level',
    'calculate': 'Calculate',
    'resultsTitle': 'Your Daily Calorie Needs',
    'bmrLabel': 'BMR (Resting Energy)',
    'tdeeLabel': 'TDEE (Active Energy)',
    'suggestionsTitle': 'Suggestions for You',
    'lossTitle': 'For Weight Loss',
    'maintainTitle': 'For Weight Maintenance',
    'gainTitle': 'For Weight Gain',
    'caloriesSuffix': 'Calories/day',
    'healthAlertTitle': 'Health Alert',
    'alert1': '• If you have diabetes, avoid sugary foods.',
    'alert2': '• If you have high blood pressure, reduce salt intake.',
    'alert3': '• If you have kidney problems, limit protein intake without consulting a doctor.',
    'alert4': 'Always consult a doctor or nutritionist before starting any diet.',
  },
  'bn': {
    'appTitle': 'বিএমআর ও ক্যালোরি ক্যালকুলেটর',
    'male': 'পুরুষ',
    'female': 'মহিলা',
    'age': 'বয়স',
    'ageHint': 'যেমন, ২৫',
    'weight': 'ওজন (কেজি)',
    'weightHint': 'যেমন, ৭০',
    'height_cm': 'উচ্চতা (সেমি)',
    'height_cm_hint': 'যেমন, ১৭৫',
    'feet': 'ফুট',
    'feetHint': 'যেমন, ৫',
    'inches': 'ইঞ্চি',
    'inchesHint': 'যেমন, ৯',
    'activityLevel': 'ক্রিয়াকলাপ স্তর',
    'calculate': 'হিসাব করুন',
    'resultsTitle': 'আপনার দৈনিক ক্যালোরির প্রয়োজন',
    'bmrLabel': 'বিএমআর (বিশ্রামের শক্তি)',
    'tdeeLabel': 'টিডিইই (সক্রিয় শক্তি)',
    'suggestionsTitle': 'আপনার জন্য পরামর্শ',
    'lossTitle': 'ওজন কমানোর জন্য',
    'maintainTitle': 'ওজন ঠিক রাখার জন্য',
    'gainTitle': 'ওজন বাড়ানোর জন্য',
    'caloriesSuffix': 'ক্যালোরি/দিন',
    'healthAlertTitle': 'স্বাস্থ্য সতর্কতা',
    'alert1': '• ডায়াবেটিস থাকলে চিনি ও মিষ্টি জাতীয় খাবার এড়িয়ে চলুন।',
    'alert2': '• উচ্চ রক্তচাপ থাকলে লবণ ও সোডিয়ামযুক্ত খাবার কম খান।',
    'alert3': '• কিডনির সমস্যা থাকলে ডাক্তারের পরামর্শ ছাড়া প্রোটিন গ্রহণ সীমিত করুন।',
    'alert4': 'যেকোনো ডায়েট শুরু করার আগে অবশ্যই ডাক্তার বা পুষ্টিবিদের পরামর্শ নিন।',
  },
};
