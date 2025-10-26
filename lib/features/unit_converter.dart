/*
 * File: lib/features/unit_converter.dart
 * Location: /c:/Users/Tamal/Documents/smart_numerix_v2/lib/features/unit_converter.dart
 * Description: Universal unit converter for length, weight, volume, temperature, area, speed
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;

class UnitConverterPage extends StatefulWidget {
  const UnitConverterPage({super.key});

  @override
  _UnitConverterPageState createState() => _UnitConverterPageState();
}

class _UnitConverterPageState extends State<UnitConverterPage> {
  String _selectedCategoryKey = 'Length';
  double _inputValue = 1.0;
  String? _fromUnitKey;
  String? _toUnitKey;
  double _outputValue = 0.0;
  bool _isBengali = true;

  final TextEditingController _inputController = TextEditingController(text: '1.0');

  String tr(String key) => _localizedValues[key]?[_isBengali ? 'bn' : 'en'] ?? key;
  void _toggleLocale() => setState(() {
    _isBengali = !_isBengali;
    _convert();
  });

  final Map<String, Map<String, double>> _unitData = {
    'Length': { 'm': 1.0, 'km': 1000.0, 'cm': 0.01, 'mm': 0.001, 'mi': 1609.34, 'yd': 0.9144, 'ft': 0.3048, 'in': 0.0254 },
    'Weight': { 'kg': 1.0, 'g': 0.001, 'mg': 1e-6, 'lb': 0.453592, 'oz': 0.0283495 },
    'Temp': { 'C': 0.0, 'F': 0.0, 'K': 0.0 },
    'Area': { 'sqm': 1.0, 'sqkm': 1e6, 'ha': 10000.0, 'acre': 4046.86, 'sqft': 0.092903, 'sqin': 0.00064516 },
    'Volume': { 'L': 1.0, 'm3': 1000.0, 'ml': 0.001, 'gal': 3.78541, 'pt': 0.473176 },
    'Speed': { 'mps': 1.0, 'kph': 0.277778, 'mph': 0.44704, 'knot': 0.514444 },
    'Time': { 's': 1.0, 'min': 60.0, 'hr': 3600.0, 'day': 86400.0, 'wk': 604800.0 },
  };

  @override
  void initState() {
    super.initState();
    _resetUnits();
    _convert();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _resetUnits() {
    final units = _unitData[_selectedCategoryKey]?.keys.toList();
    if (units != null && units.isNotEmpty) {
      _fromUnitKey = units.first;
      _toUnitKey = units.length > 1 ? units.elementAt(1) : units.first;
    } else {
      _fromUnitKey = null;
      _toUnitKey = null;
    }
  }

  void _convert() {
    if (_fromUnitKey == null || _toUnitKey == null) return;

    if (_selectedCategoryKey == 'Temp') {
      _convertTemperature();
      return;
    }

    double fromFactor = _unitData[_selectedCategoryKey]![_fromUnitKey!]!;
    double toFactor = _unitData[_selectedCategoryKey]![_toUnitKey!]!;
    setState(() {
      _outputValue = (_inputValue * fromFactor) / toFactor;
    });
  }

  void _convertTemperature() {
    double output;
    if (_fromUnitKey == 'C' && _toUnitKey == 'F') output = (_inputValue * 9 / 5) + 32;
    else if (_fromUnitKey == 'F' && _toUnitKey == 'C') output = (_inputValue - 32) * 5 / 9;
    else if (_fromUnitKey == 'C' && _toUnitKey == 'K') output = _inputValue + 273.15;
    else if (_fromUnitKey == 'K' && _toUnitKey == 'C') output = _inputValue - 273.15;
    else if (_fromUnitKey == 'F' && _toUnitKey == 'K') output = (_inputValue - 32) * 5 / 9 + 273.15;
    else if (_fromUnitKey == 'K' && _toUnitKey == 'F') output = (_inputValue - 273.15) * 9 / 5 + 32;
    else output = _inputValue;
    setState(() => _outputValue = output);
  }

  void _swapUnits() {
    setState(() {
      final tempKey = _fromUnitKey;
      _fromUnitKey = _toUnitKey;
      _toUnitKey = tempKey;

      _inputValue = _outputValue;
      _inputController.text = _outputValue.toStringAsFixed(_outputValue.truncateToDouble() == _outputValue ? 0 : 4);
      _convert();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('app_title')),
        backgroundColor: const Color(0xFF10141C).withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        actions: [
          TextButton(
            onPressed: _toggleLocale,
            style: TextButton.styleFrom(foregroundColor: Colors.white, shape: const CircleBorder()),
            child: Text(_isBengali ? 'EN' : 'BN', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: _AnimatedBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildCategorySelector(),
              const SizedBox(height: 32),
              _buildConverterHub(),
              const SizedBox(height: 32),
              _buildFormulaDisplay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return _StyledCard(
      child: DropdownButtonFormField<String>(
        value: _selectedCategoryKey,
        dropdownColor: const Color(0xFF1F2C50), // Darker dropdown background
        style: const TextStyle(color: Colors.white, fontSize: 16),
        icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF007BFF)),
        decoration: InputDecoration(
          labelText: tr('category_label'),
          labelStyle: TextStyle(color: Colors.blue.shade200.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8), // Adjusted padding
        ),
        items: _unitData.keys.map((String key) {
          return DropdownMenuItem<String>(
            value: key,
            child: Text(tr(key), style: const TextStyle(fontSize: 18)), // Larger font
          );
        }).toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            _selectedCategoryKey = value;
            _resetUnits();
            _inputValue = 1.0;
            _inputController.text = '1.0';
            _convert();
          });
        },
      ),
    );
  }

  Widget _buildConverterHub() {
    final categoryUnits = _unitData[_selectedCategoryKey]?.keys.toList() ?? [];

    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            _StyledCard(child: _buildConversionPane(true, categoryUnits)),
            const SizedBox(height: 8),
            _StyledCard(child: _buildConversionPane(false, categoryUnits)),
          ],
        ),
        Transform.translate(
          offset: const Offset(0, 4),
          child: InkWell(
            onTap: _swapUnits,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF007BFF), Colors.blueAccent]),
                boxShadow: [BoxShadow(color: Colors.blueAccent, blurRadius: 15, offset: Offset(0, 5))],
              ),
              child: const Icon(Icons.swap_vert_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversionPane(bool isFromPane, List<String> units) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Reduced padding inside card
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isFromPane ? tr('from_label') : tr('to_label'),
                style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              SizedBox(
                width: 150, // Constrain width
                child: DropdownButton<String>(
                  value: isFromPane ? _fromUnitKey : _toUnitKey,
                  items: units.map((String key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text( tr(key), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16)), // Translate unit name
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      if (isFromPane) _fromUnitKey = value; else _toUnitKey = value;
                      _convert();
                    });
                  },
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  dropdownColor: const Color(0xFF1F2C50),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isFromPane)
            TextFormField(
              controller: _inputController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              decoration: InputDecoration.collapsed(hintText: '0', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3))),
              onChanged: (value) {
                setState(() {
                  _inputValue = double.tryParse(value) ?? 0.0;
                  _convert();
                });
              },
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _outputValue.toStringAsFixed(4),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF22C55E)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormulaDisplay() {
    String formula = _getConversionFormula();
    if (formula.isEmpty) return const SizedBox.shrink();

    return _StyledCard(
      child: Column(
        children: [
          Text(
            tr('formula_label'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formula,
              style: TextStyle(fontSize: 18, color: Colors.cyanAccent.shade400, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getConversionFormula() {
    if (_fromUnitKey == null || _toUnitKey == null || _fromUnitKey == _toUnitKey) return '';

    final fromUnitName = tr(_fromUnitKey!);
    final toUnitName = tr(_toUnitKey!);

    if (_selectedCategoryKey == 'Temp') {
      if (_fromUnitKey == 'C' && _toUnitKey == 'F') return '°F = (°C × 9/5) + 32';
      if (_fromUnitKey == 'F' && _toUnitKey == 'C') return '°C = (°F - 32) × 5/9';
      if (_fromUnitKey == 'C' && _toUnitKey == 'K') return 'K = °C + 273.15';
      if (_fromUnitKey == 'K' && _toUnitKey == 'C') return '°C = K - 273.15';
      if (_fromUnitKey == 'F' && _toUnitKey == 'K') return 'K = (°F - 32) × 5/9 + 273.15';
      if (_fromUnitKey == 'K' && _toUnitKey == 'F') return '°F = (K - 273.15) × 9/5 + 32';
    } else {
      final fromFactor = _unitData[_selectedCategoryKey]![_fromUnitKey!]!;
      final toFactor = _unitData[_selectedCategoryKey]![_toUnitKey!]!;
      final relation = (fromFactor / toFactor);
      String formattedRelation = relation.toStringAsFixed(6);
      if (relation > 10000) formattedRelation = relation.toStringAsExponential(2);
      else if (relation < 0.0001 && relation > 0) formattedRelation = relation.toStringAsExponential(2);

      formattedRelation = formattedRelation.replaceAll(RegExp(r'0+$'), '');
      if (formattedRelation.endsWith('.')) formattedRelation = formattedRelation.substring(0, formattedRelation.length - 1);

      return '1 $fromUnitName ≈ $formattedRelation $toUnitName';
    }
    return '';
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
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [ Color(0xFF0A0F1A), Color(0xFF10141C), Color(0xFF0B2A4B), Color(0xFF3A2A5B), ],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
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
  'app_title': {'bn': 'একক রূপান্তরকারী', 'en': 'Unit Converter'},
  'category_label': {'bn': 'বিভাগ', 'en': 'Category'},
  'from_label': {'bn': 'থেকে', 'en': 'From'},
  'to_label': {'bn': 'প্রতি', 'en': 'To'},
  'formula_label': {'bn': 'রূপান্তর সূত্র', 'en': 'Conversion Formula'},
  'Length': {'bn': 'দৈর্ঘ্য', 'en': 'Length'},
  'Weight': {'bn': 'ওজন/ভর', 'en': 'Weight/Mass'},
  'Temp': {'bn': 'তাপমাত্রা', 'en': 'Temperature'},
  'Area': {'bn': 'ক্ষেত্রফল', 'en': 'Area'},
  'Volume': {'bn': 'আয়তন', 'en': 'Volume'},
  'Speed': {'bn': 'গতি', 'en': 'Speed'},
  'Time': {'bn': 'সময়', 'en': 'Time'},
  'm': {'bn': 'মিটার', 'en': 'Meters'},
  'km': {'bn': 'কিলোমিটার', 'en': 'Kilometers'},
  'cm': {'bn': 'সেন্টিমিটার', 'en': 'Centimeters'},
  'mm': {'bn': 'মিলিমিটার', 'en': 'Millimeters'},
  'mi': {'bn': 'মাইল', 'en': 'Miles'},
  'yd': {'bn': 'গজ', 'en': 'Yards'},
  'ft': {'bn': 'ফুট', 'en': 'Feet'},
  'in': {'bn': 'ইঞ্চি', 'en': 'Inches'},
  'kg': {'bn': 'কিলোগ্রাম', 'en': 'Kilograms'},
  'g': {'bn': 'গ্রাম', 'en': 'Grams'},
  'mg': {'bn': 'মিলিগ্রাম', 'en': 'Milligrams'},
  'lb': {'bn': 'পাউন্ড', 'en': 'Pounds'},
  'oz': {'bn': 'আউন্স', 'en': 'Ounces'},
  'C': {'bn': 'সেলসিয়াস', 'en': 'Celsius'},
  'F': {'bn': 'ফারেনহাইট', 'en': 'Fahrenheit'},
  'K': {'bn': 'কেলভিন', 'en': 'Kelvin'},
  'sqm': {'bn': 'বর্গ মিটার', 'en': 'Square Meters'},
  'sqkm': {'bn': 'বর্গ কিমি', 'en': 'Square Kilometers'},
  'ha': {'bn': 'হেক্টর', 'en': 'Hectares'},
  'acre': {'bn': 'একর', 'en': 'Acres'},
  'sqft': {'bn': 'বর্গ ফুট', 'en': 'Square Feet'},
  'sqin': {'bn': 'বর্গ ইঞ্চি', 'en': 'Square Inches'},
  'L': {'bn': 'লিটার', 'en': 'Liters'},
  'm3': {'bn': 'ঘন মিটার', 'en': 'Cubic Meters'},
  'ml': {'bn': 'মিলিলিটার', 'en': 'Milliliters'},
  'gal': {'bn': 'গ্যালন (মার্কিন)', 'en': 'Gallons (US)'},
  'pt': {'bn': 'পিন্ট (মার্কিন)', 'en': 'Pints (US)'},
  'mps': {'bn': 'মি/সেকেন্ড', 'en': 'Meters/second (m/s)'},
  'kph': {'bn': 'কিমি/ঘন্টা', 'en': 'Kilometers/hour (km/h)'},
  'mph': {'bn': 'মাইল/ঘন্টা', 'en': 'Miles/hour (mph)'},
  'knot': {'bn': 'নট', 'en': 'Knots'},
  's': {'bn': 'সেকেন্ড', 'en': 'Seconds'},
  'min': {'bn': 'মিনিট', 'en': 'Minutes'},
  'hr': {'bn': 'ঘন্টা', 'en': 'Hours'},
  'day': {'bn': 'দিন', 'en': 'Days'},
  'wk': {'bn': 'সপ্তাহ', 'en': 'Weeks'},
};
