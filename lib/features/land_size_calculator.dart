/*
 * File: lib/features/land_size_calculator.dart
 * Location: /c:/Users/Tamal/Documents/smart_numerix_v2/lib/features/land_size_calculator.dart
 * Description: Land area measurement and conversion calculator
 */

import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
// *** FIX: Added the missing import for the 'math' library ***
import 'dart:math' as math;

enum LandShape {
  rectangle,
  triangle,
  quadrilateral,
}

enum CalculationMode {
  area,
  distribution,
}

enum LengthUnit { feet, meters, yards, cubits }
enum AreaUnit { sqFeet, sqMeters, decimal, katha, bigha, acre }

class LandSizeCalculatorPage extends StatefulWidget {
  const LandSizeCalculatorPage({super.key});

  @override
  State<LandSizeCalculatorPage> createState() => _LandSizeCalculatorPageState();
}

class _LandSizeCalculatorPageState extends State<LandSizeCalculatorPage> {
  String _currentLocale = 'bn'; // 'bn' for Bengali, 'en' for English

  LandShape _selectedShape = LandShape.rectangle;
  CalculationMode _calculationMode = CalculationMode.area;
  LengthUnit _inputUnit = LengthUnit.feet;
  AreaUnit _outputUnit = AreaUnit.decimal;

  final _sideAController = TextEditingController();
  final _sideBController = TextEditingController();
  final _sideCController = TextEditingController();
  final _sideDController = TextEditingController();
  final _diagonalController = TextEditingController();
  final _sharesController = TextEditingController(text: '2');

  String _result = '';
  List<double> _dimensions = [];

  String tr(String key) => _localizedValues[_currentLocale]![key] ?? key;
  void _toggleLocale() => setState(() => _currentLocale = _currentLocale == 'bn' ? 'en' : 'bn');

  double _convertToBaseUnit(double value) {
    const conversions = { LengthUnit.feet: 1.0, LengthUnit.meters: 3.28084, LengthUnit.yards: 3.0, LengthUnit.cubits: 1.5 };
    return value * conversions[_inputUnit]!;
  }

  String _convertFromBaseArea(double areaInSqFeet, AreaUnit unit) {
    const conversions = { AreaUnit.sqFeet: 1.0, AreaUnit.sqMeters: 10.764, AreaUnit.decimal: 435.6, AreaUnit.katha: 720.0, AreaUnit.bigha: 14400.0, AreaUnit.acre: 43560.0 };
    final unitNames = { AreaUnit.sqFeet: tr('sqFeet'), AreaUnit.sqMeters: tr('sqMeters'), AreaUnit.decimal: tr('decimal'), AreaUnit.katha: tr('katha'), AreaUnit.bigha: tr('bigha'), AreaUnit.acre: tr('acre') };
    final convertedArea = areaInSqFeet / conversions[unit]!;
    return '${convertedArea.toStringAsFixed(3)} ${unitNames[unit]}';
  }

  String _getUnitName(LengthUnit unit) {
    const names = { LengthUnit.feet: 'feet', LengthUnit.meters: 'meters', LengthUnit.yards: 'yards', LengthUnit.cubits: 'cubits' };
    return tr(names[unit]!);
  }

  void _calculate() {
    FocusScope.of(context).unfocus();

    final double sideA = _convertToBaseUnit(double.tryParse(_sideAController.text) ?? 0);
    final double sideB = _convertToBaseUnit(double.tryParse(_sideBController.text) ?? 0);
    final double sideC = _convertToBaseUnit(double.tryParse(_sideCController.text) ?? 0);
    final double sideD = _convertToBaseUnit(double.tryParse(_sideDController.text) ?? 0);
    final double diagonal = _convertToBaseUnit(double.tryParse(_diagonalController.text) ?? 0);

    double area = 0;
    String calculationDetails = '';

    try {
      switch (_selectedShape) {
        case LandShape.rectangle:
          if (sideA <= 0 || sideB <= 0) throw Exception(tr('errorInvalidLengthWidth'));
          area = sideA * sideB;
          _dimensions = [sideA, sideB];
          break;
        case LandShape.triangle:
          if (sideA <= 0 || sideB <= 0 || sideC <= 0) throw Exception(tr('errorInvalidSides'));
          final double s = (sideA + sideB + sideC) / 2;
          if (s <= sideA || s <= sideB || s <= sideC) throw Exception(tr('errorTriangleInequality'));
          area = sqrt(s * (s - sideA) * (s - sideB) * (s - sideC));
          _dimensions = [sideA, sideB, sideC];
          break;
        case LandShape.quadrilateral:
          if (sideA <= 0 || sideB <= 0 || sideC <= 0 || sideD <= 0 || diagonal <= 0) throw Exception(tr('errorInvalidQuad'));
          final double s1 = (sideA + sideB + diagonal) / 2;
          final double s2 = (sideC + sideD + diagonal) / 2;
          if (s1 <= sideA || s1 <= sideB || s1 <= diagonal || s2 <= sideC || s2 <= sideD || s2 <= diagonal) throw Exception(tr('errorQuadInequality'));
          final area1 = sqrt(s1 * (s1 - sideA) * (s1 - sideB) * (s1 - diagonal));
          final area2 = sqrt(s2 * (s2 - sideC) * (s2 - sideD) * (s2 - diagonal));
          area = area1 + area2;
          _dimensions = [sideA, sideB, sideC, sideD, diagonal];
          break;
      }

      if (_calculationMode == CalculationMode.distribution) {
        final int shares = int.tryParse(_sharesController.text) ?? 0;
        if (shares <= 0) throw Exception(tr('errorInvalidShares'));
        calculationDetails = '${tr('totalArea')}: ${_convertFromBaseArea(area, _outputUnit)}\n${tr('areaPerShare')} ${_convertFromBaseArea(area / shares, _outputUnit)}';
      } else {
        calculationDetails = '${tr('totalArea')}: ${_convertFromBaseArea(area, _outputUnit)}';
      }

      setState(() => _result = calculationDetails);
    } catch (e) {
      setState(() {
        _result = e.toString().replaceFirst('Exception: ', '');
        _dimensions = [];
      });
    }
  }

  void _resetFields() {
    _sideAController.clear();
    _sideBController.clear();
    _sideCController.clear();
    _sideDController.clear();
    _diagonalController.clear();
    _sharesController.text = '2';
    setState(() {
      _result = '';
      _dimensions = [];
    });
  }


  @override
  void dispose() {
    _sideAController.dispose(); _sideBController.dispose(); _sideCController.dispose();
    _sideDController.dispose(); _diagonalController.dispose(); _sharesController.dispose();
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
          TextButton(
            onPressed: _toggleLocale,
            style: TextButton.styleFrom(foregroundColor: Colors.white, shape: const CircleBorder()),
            child: Text(_currentLocale == 'bn' ? 'EN' : 'BN', style: const TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: _AnimatedBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildModeAndShapeSelector(),
              const SizedBox(height: 24),
              _buildVisualRepresentation(),
              const SizedBox(height: 24),
              _StyledCard(
                child: Column(
                  children: [
                    _buildUnitSelectors(),
                    const SizedBox(height: 20),
                    _buildInputFields(),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _calculate,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      child: Text(_calculationMode == CalculationMode.distribution ? tr('distribute') : tr('calculate')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _resetFields,
                    icon: const Icon(Icons.refresh),
                    tooltip: "Reset",
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white70,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              AnimatedSize(
                duration: const Duration(milliseconds: 400),
                child: _result.isNotEmpty ? _buildResultDisplay() : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeAndShapeSelector() {
    return _StyledCard(
      child: Column(
        children: [
          _buildDropdown(
            label: tr('calculationType'),
            value: _calculationMode,
            items: [
              DropdownMenuItem(value: CalculationMode.area, child: Text(tr('modeArea'))),
              DropdownMenuItem(value: CalculationMode.distribution, child: Text(tr('modeDistribution'))),
            ],
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() { _calculationMode = newValue; _resetFields(); });
              }
            },
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: tr('shapeType'),
            value: _selectedShape,
            items: [
              DropdownMenuItem(value: LandShape.rectangle, child: Text(tr('shapeRectangle'))),
              DropdownMenuItem(value: LandShape.triangle, child: Text(tr('shapeTriangle'))),
              DropdownMenuItem(value: LandShape.quadrilateral, child: Text(tr('shapeQuadrilateral'))),
            ],
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() { _selectedShape = newValue; _resetFields(); });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnitSelectors() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            label: tr('inputUnit'),
            value: _inputUnit,
            items: LengthUnit.values.map((unit) => DropdownMenuItem(value: unit, child: Text(_getUnitName(unit)))).toList(),
            onChanged: (val) => setState(() => _inputUnit = val!),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDropdown(
            label: tr('outputUnit'),
            value: _outputUnit,
            items: [
              DropdownMenuItem(value: AreaUnit.decimal, child: Text(tr('decimal'))),
              DropdownMenuItem(value: AreaUnit.katha, child: Text(tr('katha'))),
              DropdownMenuItem(value: AreaUnit.bigha, child: Text(tr('bigha'))),
              DropdownMenuItem(value: AreaUnit.acre, child: Text(tr('acre'))),
              DropdownMenuItem(value: AreaUnit.sqFeet, child: Text(tr('sqFeet'))),
              DropdownMenuItem(value: AreaUnit.sqMeters, child: Text(tr('sqMeters'))),
            ],
            onChanged: (val) => setState(() => _outputUnit = val!),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualRepresentation() {
    return _StyledCard(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 180,
        child: Center(
          child: CustomPaint(
            size: const Size(200, 160),
            painter: LandShapePainter(
              shape: _selectedShape,
              dimensions: _dimensions,
              strokeColor: const Color(0xFF22C55E),
              textColor: Colors.white,
              locale: _currentLocale,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    final unitName = _getUnitName(_inputUnit);
    List<Widget> fields = [];

    switch (_selectedShape) {
      case LandShape.rectangle:
        fields.addAll([
          _buildTextField(_sideAController, '${tr('length')} ($unitName)'),
          const SizedBox(height: 16),
          _buildTextField(_sideBController, '${tr('width')} ($unitName)'),
        ]);
        break;
      case LandShape.triangle:
        fields.addAll([
          _buildTextField(_sideAController, '${tr('side1')} ($unitName)'),
          const SizedBox(height: 16),
          _buildTextField(_sideBController, '${tr('side2')} ($unitName)'),
          const SizedBox(height: 16),
          _buildTextField(_sideCController, '${tr('side3')} ($unitName)'),
        ]);
        break;
      case LandShape.quadrilateral:
        fields.addAll([
          _buildTextField(_sideAController, '${tr('sideA_AB')} ($unitName)'),
          const SizedBox(height: 16),
          _buildTextField(_sideBController, '${tr('sideB_BC')} ($unitName)'),
          const SizedBox(height: 16),
          _buildTextField(_sideCController, '${tr('sideC_CD')} ($unitName)'),
          const SizedBox(height: 16),
          _buildTextField(_sideDController, '${tr('sideD_DA')} ($unitName)'),
          const SizedBox(height: 16),
          _buildTextField(_diagonalController, '${tr('diagonal_AC')} ($unitName)'),
        ]);
        break;
    }

    if (_calculationMode == CalculationMode.distribution && fields.isNotEmpty) {
      fields.addAll([
        const SizedBox(height: 24),
        _buildTextField(_sharesController, tr('shares'), isNumber: true),
      ]);
    }

    return Column(children: fields);
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.green.shade200.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildResultDisplay() {
    return _StyledCard(
      child: Center(
        child: Text(
          _result,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, height: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({ required String label, required T value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged, }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: const Color(0xFF1F2C50),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
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

class LandShapePainter extends CustomPainter {
  final LandShape shape; final List<double> dimensions;
  final Color strokeColor; final Color textColor; final String locale;

  LandShapePainter({ required this.shape, required this.dimensions, required this.strokeColor, required this.textColor, required this.locale });

  String tr(String key) => _painterLocalizedValues[locale]![key] ?? key;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = strokeColor..strokeWidth = 2..style = PaintingStyle.stroke;
    final textPainter = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    final textStyle = TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold);

    void drawText(String text, Offset position) {
      textPainter.text = TextSpan(text: text, style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, position - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    switch (shape) {
      case LandShape.rectangle:
        final rect = Rect.fromCenter(center: size.center(Offset.zero), width: size.width * 0.8, height: size.height * 0.6);
        canvas.drawRect(rect, paint);
        drawText(tr('length'), Offset(rect.center.dx, rect.top - 15));
        drawText(tr('width'), Offset(rect.left - 30, rect.center.dy));
        break;
      case LandShape.triangle:
        final p1 = Offset(size.width * 0.2, size.height * 0.8);
        final p2 = Offset(size.width * 0.8, size.height * 0.8);
        final p3 = Offset(size.width * 0.5, size.height * 0.2);
        final path = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close();
        canvas.drawPath(path, paint);
        drawText(tr('side1'), (p1 + p2) / 2 + const Offset(0, 10));
        drawText(tr('side2'), (p2 + p3) / 2 + const Offset(20, 0));
        drawText(tr('side3'), (p3 + p1) / 2 - const Offset(20, 0));
        break;
      case LandShape.quadrilateral:
        final pA = Offset(size.width * 0.1, size.height * 0.5); final pB = Offset(size.width * 0.4, size.height * 0.8);
        final pC = Offset(size.width * 0.9, size.height * 0.6); final pD = Offset(size.width * 0.7, size.height * 0.1);
        final path = Path()..moveTo(pA.dx, pA.dy)..lineTo(pB.dx, pB.dy)..lineTo(pC.dx, pC.dy)..lineTo(pD.dx, pD.dy)..close();
        canvas.drawPath(path, paint);
        final dashedPaint = Paint()..color = strokeColor.withOpacity(0.7)..strokeWidth = 1.5..style = PaintingStyle.stroke;
        _drawDashedLine(canvas, pA, pC, dashedPaint);
        drawText('A', pA - const Offset(12, 12)); drawText('B', pB + const Offset(-12, 12));
        drawText('C', pC + const Offset(12, 12)); drawText('D', pD + const Offset(12, -12));
        drawText(tr('diagonal'), (pA + pC) / 2);
        break;
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 5.0, dashSpace = 3.0;
    final path = Path();
    final dX = p2.dx - p1.dx; final dY = p2.dy - p1.dy;
    final totalLength = sqrt(dX * dX + dY * dY);
    double start = 0.0;
    while (start < totalLength) {
      path.moveTo(p1.dx + (start / totalLength) * dX, p1.dy + (start / totalLength) * dY);
      path.lineTo(p1.dx + (min(start + dashWidth, totalLength) / totalLength) * dX, p1.dy + (min(start + dashWidth, totalLength) / totalLength) * dY);
      start += dashWidth + dashSpace;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LandShapePainter oldDelegate) => oldDelegate.shape != shape || oldDelegate.locale != locale;
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
              colors: const [ Color(0xFF0A0F1A), Color(0xFF10141C), Color(0xFF0b3d1c), Color(0xFF3A2A5B), ],
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

const Map<String, Map<String, String>> _painterLocalizedValues = {
  'en': { 'length': 'Length', 'width': 'Width', 'side1': 'Side A', 'side2': 'Side B', 'side3': 'Side C', 'diagonal': 'Diagonal', },
  'bn': { 'length': 'দৈর্ঘ্য', 'width': 'প্রস্থ', 'side1': 'বাহু ক', 'side2': 'বাহু খ', 'side3': 'বাহু গ', 'diagonal': 'কর্ণ', }
};

const Map<String, Map<String, String>> _localizedValues = {
  'en': {
    'appTitle': 'Land Area Calculator',
    'shapeRectangle': 'Rectangle',
    'shapeTriangle': 'Triangle',
    'shapeQuadrilateral': 'Quadrilateral (Irregular)',
    'modeArea': 'Calculate Area',
    'modeDistribution': 'Distribute Land',
    'inputUnit': 'Input Unit',
    'outputUnit': 'Result Unit',
    'calculate': 'Calculate',
    'distribute': 'Distribute',
    'result': 'Result',
    'length': 'Length',
    'width': 'Width',
    'side1': 'First Side',
    'side2': 'Second Side',
    'side3': 'Third Side',
    'sideA_AB': 'Side (AB)',
    'sideB_BC': 'Side (BC)',
    'sideC_CD': 'Side (CD)',
    'sideD_DA': 'Side (DA)',
    'diagonal_AC': 'Diagonal (AC)',
    'shares': 'Number of Shares',
    'errorInvalidLengthWidth': 'Please provide valid length and width.',
    'errorInvalidSides': 'Please provide three valid side lengths.',
    'errorTriangleInequality': 'A triangle cannot be formed with these sides.',
    'errorInvalidQuad': 'Please provide four valid sides and a diagonal.',
    'errorQuadInequality': 'A quadrilateral cannot be formed with these sides and diagonal.',
    'errorInvalidShares': 'Please provide a valid number of shares.',
    'totalArea': 'Total Area',
    'areaPerShare': 'Area Per Share:',
    'feet': 'Feet', 'meters': 'Meters', 'yards': 'Yards', 'cubits': 'Cubits',
    'sqFeet': 'Sq. Feet', 'sqMeters': 'Sq. Meters', 'decimal': 'Decimal',
    'katha': 'Katha', 'bigha': 'Bigha', 'acre': 'Acre',
    'shapeType': 'Shape Type',
    'calculationType': 'Calculation Type',
  },
  'bn': {
    'appTitle': 'জমির পরিমাপ ক্যালকুলেটর',
    'shapeRectangle': 'আয়তাকার জমি',
    'shapeTriangle': 'ত্রিভুজাকার জমি',
    'shapeQuadrilateral': 'সাধারণ জমি (চতুর্ভুজ)',
    'modeArea': 'জমির পরিমাপ করুন',
    'modeDistribution': 'জমি বন্টন করুন',
    'inputUnit': 'ইনপুট একক',
    'outputUnit': 'ফলাফলের একক',
    'calculate': 'হিসাব করুন',
    'distribute': 'বন্টন করুন',
    'result': 'ফলাফল',
    'length': 'দৈর্ঘ্য',
    'width': 'প্রস্থ',
    'side1': 'প্রথম বাহু',
    'side2': 'দ্বিতীয় বাহু',
    'side3': 'তৃতীয় বাহু',
    'sideA_AB': 'প্রথম বাহু (AB)',
    'sideB_BC': 'দ্বিতীয় বাহু (BC)',
    'sideC_CD': 'তৃতীয় বাহু (CD)',
    'sideD_DA': 'চতুর্থ বাহু (DA)',
    'diagonal_AC': 'কর্ণ (AC)',
    'shares': 'ভাগের সংখ্যা',
    'errorInvalidLengthWidth': 'অনুগ্রহ করে সঠিক দৈর্ঘ্য ও প্রস্থ দিন।',
    'errorInvalidSides': 'অনুগ্রহ করে তিনটি বাহুর সঠিক দৈর্ঘ্য দিন।',
    'errorTriangleInequality': 'এই বাহুগুলো দিয়ে ত্রিভুজ গঠন সম্ভব নয়।',
    'errorInvalidQuad': 'অনুগ্রহ করে চারটি বাহু এবং কর্ণের সঠিক দৈর্ঘ্য দিন।',
    'errorQuadInequality': 'এই বাহু ও কর্ণ দিয়ে চতুর্ভুজ গঠন সম্ভব নয়।',
    'errorInvalidShares': 'অনুগ্রহ করে সঠিক ভাগের সংখ্যা দিন।',
    'totalArea': 'মোট ক্ষেত্রফল',
    'areaPerShare': 'প্রতি ভাগে জমির পরিমাণ:',
    'feet': 'ফুট', 'meters': 'মিটার', 'yards': 'গজ', 'cubits': 'হাত',
    'sqFeet': 'বর্গফুট', 'sqMeters': 'বর্গমিটার', 'decimal': 'শতক',
    'katha': 'কাঠা', 'bigha': 'বিঘা', 'acre': 'একর',
    'shapeType': 'জমির ধরন',
    'calculationType': 'হিসাবের ধরন',
  },
};