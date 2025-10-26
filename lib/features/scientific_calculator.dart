/*
 * File: lib/features/scientific_calculator.dart
 * Location: /c:/Users/Tamal/Documents/smart_numerix_v2/lib/features/scientific_calculator.dart
 * Description: Scientific calculator with advanced mathematical functions
 */

import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'dart:math' as math;
import 'dart:ui';

enum CalculatorMode { calculator, numberSystem, matrix }

class ScientificCalculatorPage extends StatefulWidget {
  const ScientificCalculatorPage({super.key});

  @override
  _ScientificCalculatorPageState createState() =>
      _ScientificCalculatorPageState();
}

class _ScientificCalculatorPageState extends State<ScientificCalculatorPage>
    with TickerProviderStateMixin {
  String _expression = '';
  String _result = '0';
  bool _isRadians = true;
  final List<Map<String, String>> _history = [];
  CalculatorMode _mode = CalculatorMode.calculator;

  bool _isEnglish = true;

  static const Map<String, String> _bnTranslations = {
    'Calculator': 'ক্যালকুলেটর',
    'Number Base': 'সংখ্যা পদ্ধতি',
    'Matrix': 'ম্যাট্রিক্স',
    'বাংলা': 'বাংলা',
    'English': 'English',
    'Binary': 'বাইনারি',
    'Octal': 'অক্টাল',
    'Decimal': 'দশমিক',
    'Hexadecimal': 'হেক্সাডেসিমাল',
    'Input': 'ইনপুট',
    'Convert': 'রূপান্তর',
    'Invalid input for': 'এর জন্য অবৈধ ইনপুট',
    'Error': 'ত্রুটি',
    'Addition': 'যোগ',
    'Subtraction': 'বিয়োগ',
    'Multiplication': 'গুণ',
    'Determinant': 'নির্ণায়ক',
    'Cofactors': 'সহগুণক',
    'Inverse': 'বিপরীত',
    'Matrix Size:': 'ম্যাট্রিক্স আকার:',
    'Matrix A': 'ম্যাট্রিক্স A',
    'Matrix B': 'ম্যাট্রিক্স B',
    'Calculate': 'হিসাব করুন',
    'Result Matrix': 'ফলাফল ম্যাট্রিক্স',
    'Determinant:': 'নির্ণায়ক:',
    'Singular Matrix (Determinant is 0)': 'একক ম্যাট্রিক্স (নির্ণায়ক 0)',
    'Scientific Functions': 'বৈজ্ঞানিক ফাংশন',
    'Settings': 'সেটিংস',
    'Length': 'দৈর্ঘ্য',
    'Include Uppercase (A-Z)': 'বড় হাতের অক্ষর (A-Z)',
    'Include Lowercase (a-z)': 'ছোট হাতের অক্ষর (a-z)',
    'Include Numbers (0-9)': 'সংখ্যা (0-9)',
    'Include Symbols (!@#)': 'প্রতীক (!@#)',
    'History': 'হিস্টোরি',
    'Clear All': 'সব মুছে ফেলুন',
    'No history yet': 'এখনো কোনো হিস্টোরি নেই',
  };

  String _tr(String key) {
    if (_isEnglish) return key;
    return _bnTranslations[key] ?? key;
  }

  late AnimationController _sciPanelController;
  late Animation<double> _sciPanelAnimation;
  bool _isScientificPanelOpen = false;

  String _numberSystem = 'Decimal';
  String _numberInput = '';
  Map<String, String> _conversionResults = {};

  String _matrixOperation = 'Addition';
  List<List<TextEditingController>> _matrixAControllers = [];
  List<List<TextEditingController>> _matrixBControllers = [];
  List<List<String>> _matrixResult = [];
  int _matrixSize = 2;

  @override
  void initState() {
    super.initState();
    _initializeMatrices();
    _sciPanelController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _sciPanelAnimation =
        CurvedAnimation(parent: _sciPanelController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _sciPanelController.dispose();
    for (var row in _matrixAControllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    for (var row in _matrixBControllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _initializeMatrices() {
    for (var row in _matrixAControllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    for (var row in _matrixBControllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }

    _matrixAControllers = List.generate(
        _matrixSize, (_) =>
        List.generate(_matrixSize, (_) => TextEditingController()));
    _matrixBControllers = List.generate(
        _matrixSize, (_) =>
        List.generate(_matrixSize, (_) => TextEditingController()));
  }

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _expression = '';
        _result = '0';
      } else if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (value == '=') {
        _calculateResult();
      } else if (value == 'DEG/RAD') {
        _isRadians = !_isRadians;
      } else if (value == '±') {
        if (_expression.startsWith('-(') && _expression.endsWith(')')) {
          _expression = _expression.substring(2, _expression.length - 1);
        } else if (_expression.startsWith('-')) {
          _expression = _expression.substring(1);
        } else if (_expression.isNotEmpty) {
          _expression = '-($_expression)';
        } else if (_result != '0' && _result != 'Error') {
          _expression = '-($_result)';
          _result = '0';
        }
      } else if (value == 'x²') {
        _expression += '^2';
      } else if (value == 'x³') {
        _expression += '^3';
      }
      else
      if (['sin', 'cos', 'tan', 'log', 'ln', '√', 'sin⁻¹', 'cos⁻¹', 'tan⁻¹']
          .contains(value)) {
        _expression += '$value(';
      } else if (value == 'nCr') {
        _expression += 'nCr(';
      } else if (value == '^') {
        _expression += '^';
      } else if (value == '!') {
        if (_expression.isNotEmpty && RegExp(r'[\d)]$').hasMatch(_expression)) {
          _expression += '!';
        }
      } else if (value == ',') {
        _expression += ',';
      } else if (value == 'π') {
        _expression += 'π';
      } else if (value == 'e') {
        _expression += 'e';
      } else {
        _expression += value;
      }
    });
  }

  void _calculateResult() {
    try {
      if (_expression.isEmpty) {
        if (_result != '0' && _result != 'Error') {
          _expression = _result;
        } else {
          return;
        }
      }

      String expressionToParse = _expression;

      expressionToParse = _replaceConstantsWithValues(expressionToParse);
      expressionToParse = expressionToParse
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('√', 'sqrt')
          .replaceAll('ln', 'log');

      expressionToParse = _handleTrigFunctions(expressionToParse);

      expressionToParse = _handleInverseTrigFunctions(expressionToParse);

      expressionToParse = expressionToParse.replaceAllMapped(
        RegExp(r'(?<![a-zA-Z])log\(([^)]+)\)'),
            (match) => 'log(10,${match.group(1)})',
      );

      expressionToParse = _parseCombinationFunction(expressionToParse);

      expressionToParse = _parseFactorialFunction(expressionToParse);

      print("Parsing expression: $expressionToParse");

      Parser p = Parser();
      Expression exp = p.parse(expressionToParse);
      ContextModel cm = ContextModel();

      double eval = exp.evaluate(EvaluationType.REAL, cm);

      String formattedResult;
      if (eval.isNaN || eval.isInfinite) {
        formattedResult = 'Error';
      } else if (eval == eval.truncateToDouble()) {
        formattedResult = eval.toInt().toString();
      } else {
        formattedResult = _removeTrailingZeros(eval.toStringAsFixed(10));
      }

      setState(() {
        if (formattedResult != 'Error') {
          if (_history.length >= 20) _history.removeAt(0);
          _history.add({'expression': _expression, 'result': formattedResult});
        }
        _result = formattedResult;
      });
    } catch (e) {
      print("Calculation Error: $e");
      setState(() {
        _result = 'Error';
      });
    }
  }

  String _replaceConstantsWithValues(String expression) {
    expression = expression.replaceAllMapped(RegExp(r'π'), (match) {
      return math.pi.toString();
    });

    expression = expression.replaceAllMapped(RegExp(r'\be\b'), (match) {
      return math.e.toString();
    });

    return expression;
  }

  String _handleTrigFunctions(String expression) {
    if (_isRadians) return expression;

    
    expression = _processTrigFunction(
        expression, 'sin', (x) => math.sin(x * math.pi / 180));
    expression = _processTrigFunction(
        expression, 'cos', (x) => math.cos(x * math.pi / 180));
    expression = _processTrigFunction(
        expression, 'tan', (x) => math.tan(x * math.pi / 180));

    return expression;
  }

  String _processTrigFunction(String expression, String funcName,
      double Function(double) func) {
    final pattern = RegExp(r'\b' + RegExp.escape(funcName) + r'\(([^)(]*)\)');

    int safetyCounter = 0;
    while (expression.contains(pattern) && safetyCounter < 100) {
      safetyCounter++;
      expression = expression.replaceFirstMapped(pattern, (match) {
        try {
          String innerExpression = match.group(1)!;

          innerExpression = _replaceConstantsWithValues(innerExpression);

          innerExpression = _handleTrigFunctions(innerExpression);
          innerExpression = _handleInverseTrigFunctions(innerExpression);

          Parser p = Parser();
          Expression innerExp = p.parse(innerExpression);
          ContextModel cm = ContextModel();
          double innerValue = innerExp.evaluate(EvaluationType.REAL, cm);

          double result = func(innerValue);

          if (result.abs() < 1e-12) result = 0.0;

          return result.toString();
        } catch (e) {
          print("Error processing $funcName: $e");
          return 'Error';
        }
      });
      if (expression.contains('Error')) break;
    }
    return expression;
  }

  String _handleInverseTrigFunctions(String expression) {
    // Process inverse trigonometric functions
    expression =
        _processInverseTrigFunction(expression, 'sin⁻¹', (x) => math.asin(x));
    expression =
        _processInverseTrigFunction(expression, 'cos⁻¹', (x) => math.acos(x));
    expression =
        _processInverseTrigFunction(expression, 'tan⁻¹', (x) => math.atan(x));

    return expression;
  }

  String _processInverseTrigFunction(String expression, String funcName,
      double Function(double) func) {
    final pattern = RegExp(RegExp.escape(funcName) + r'\(([^)(]*)\)');

    int safetyCounter = 0;
    while (expression.contains(pattern) && safetyCounter < 100) {
      safetyCounter++;
      expression = expression.replaceFirstMapped(pattern, (match) {
        try {
          String innerExpression = match.group(1)!;

          innerExpression = _replaceConstantsWithValues(innerExpression);

          innerExpression = _handleTrigFunctions(innerExpression);
          innerExpression = _handleInverseTrigFunctions(innerExpression);

          Parser p = Parser();
          Expression innerExp = p.parse(innerExpression);
          ContextModel cm = ContextModel();
          double innerValue = innerExp.evaluate(EvaluationType.REAL, cm);

          double result = func(innerValue);

          if (!_isRadians) {
            result = result * (180 / math.pi);
          }

          if (result.abs() < 1e-12) result = 0.0;

          return result.toString();
        } catch (e) {
          print("Error processing $funcName: $e");
          return 'Error';
        }
      });
      if (expression.contains('Error')) break;
    }
    return expression;
  }

  String _parseCombinationFunction(String expression) {
    final nCrRegex = RegExp(r'nCr\(([^,]+),([^)]+)\)');

    int safetyCounter = 0;
    while (expression.contains(nCrRegex) && safetyCounter < 100) {
      safetyCounter++;
      expression = expression.replaceFirstMapped(nCrRegex, (match) {
        try {
          final nStr = match.group(1)!;
          final rStr = match.group(2)!;

          // Evaluate arguments recursively (handles constants, simple functions)
          String evaluatedN = _evaluateSubExpression(nStr);
          String evaluatedR = _evaluateSubExpression(rStr);

          final n = double.parse(evaluatedN).toInt();
          final r = double.parse(evaluatedR).toInt();

          if (r < 0 || r > n) return '0'; // nCr is 0 in these cases

          double result = _combination(n, r);
          return result.toString();
        } catch (e) {
          print("Error parsing nCr arguments: $e");
          return 'Error';
        }
      });
      if (expression.contains('Error')) break;
    }
    return expression;
  }

  String _parseFactorialFunction(String expression) {
    // Regex to find numbers followed by !, but not already part of evaluated number
    final factorialRegex = RegExp(r'(?<![0-9.])(\d+)!');

    int safetyCounter = 0;
    while (expression.contains(factorialRegex) && safetyCounter < 100) {
      safetyCounter++;
      expression = expression.replaceFirstMapped(factorialRegex, (match) {
        try {
          final number = int.parse(match.group(1)!);
          if (number < 0) return 'Error'; // Factorial not defined for negative
          return _factorial(number).toString();
        } catch (e) {
          print("Error parsing factorial: $e");
          return 'Error';
        }
      });
      if (expression.contains('Error')) break;
    }
    return expression;
  }

  // --- NEW Helper to evaluate sub-expressions before functions like nCr ---
  String _evaluateSubExpression(String subExpr) {
    try {
      String processed = _replaceConstantsWithValues(subExpr);
      processed = _handleTrigFunctions(processed);
      processed = _handleInverseTrigFunctions(processed);
      // Add other simple function handling if needed (like sqrt, log etc.)

      Parser p = Parser();
      Expression exp = p.parse(processed);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      return eval.toString();
    } catch (e) {
      print("Sub-expression evaluation error: $e");
      throw Exception("Invalid sub-expression: $subExpr");
    }
  }

  //---------------------------------------------------------------------

  double _combination(int n, int r) {
    if (r < 0 || r > n) return 0.0;
    if (r == 0 || r == n) return 1.0;
    if (r > n - r) r = n - r; // Optimization

    double result = 1.0;
    for (int i = 1; i <= r; i++) {
      result = result * (n - i + 1) / i;
    }
    // Check for potential overflow or very large numbers
    if (result.isInfinite || result.isNaN) {
      throw Exception("Combination result too large");
    }
    return result;
  }

  double _factorial(int n) {
    if (n < 0) throw Exception("Factorial of negative");
    if (n > 170) throw Exception(
        "Factorial result too large"); // Limit for double precision
    if (n == 0) return 1.0;
    double result = 1.0;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  String _removeTrailingZeros(String number) {
    if (!number.contains('.')) return number;

    String cleaned = number.replaceAll(RegExp(r'0+$'), '');
    if (cleaned.endsWith('.')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }

  // --- Number System Logic ---

  void _convertNumber() {
    try {
      int decimalValue;
      // _numberSystem state is ALWAYS in English.
      switch (_numberSystem) {
        case 'Binary':
          decimalValue = int.parse(_numberInput, radix: 2);
          break;
        case 'Octal':
          decimalValue = int.parse(_numberInput, radix: 8);
          break;
        case 'Hexadecimal':
          decimalValue = int.parse(_numberInput, radix: 16);
          break;
        default:
          decimalValue = int.parse(_numberInput);
          break;
      }
      setState(() {
        _conversionResults = {
          // Keys are always English for _tr()
          'Binary': decimalValue.toRadixString(2),
          'Octal': decimalValue.toRadixString(8),
          'Decimal': decimalValue.toString(),
          'Hexadecimal': decimalValue.toRadixString(16).toUpperCase(),
        };
      });
    } catch (e) {
      setState(() =>
      _conversionResults = {
        'Error': 'Invalid input for $_numberSystem'
      }); // Error key will be translated by _buildNumberSystemTab
    }
  }

  // --- Matrix Logic ---

  void _calculateMatrix() {
    try {
      List<List<double>> matrixA = _matrixAControllers
          .map((row) =>
          row
              .map((controller) => double.tryParse(controller.text) ?? 0)
              .toList())
          .toList();
      List<List<double>> matrixB = [];

      List<List<double>> result = [];
      List<List<String>> stringResult = [];

      // Only parse Matrix B if needed
      if (['Addition', 'Subtraction', 'Multiplication']
          .contains(_matrixOperation)) {
        matrixB = _matrixBControllers
            .map((row) =>
            row
                .map((controller) => double.tryParse(controller.text) ?? 0)
                .toList())
            .toList();
      }

      switch (_matrixOperation) {
        case 'Addition':
          result = _matrixAddition(matrixA, matrixB);
          break;
        case 'Subtraction':
          result = _matrixSubtraction(matrixA, matrixB);
          break;
        case 'Multiplication':
          result = _matrixMultiplication(matrixA, matrixB);
          break;
        case 'Determinant':
          double det = _matrixDeterminant(matrixA);
          stringResult = [
            [
              '${_tr('Determinant:')} ${_removeTrailingZeros(
                  det.toStringAsFixed(4))}'
            ] // Format determinant nicely
          ];
          break;
        case 'Cofactors':
          result = _matrixCofactors(matrixA);
          break;
        case 'Inverse':
          result = _matrixInverse(matrixA);
          break;
      }

      setState(() {
        if (stringResult.isNotEmpty) {
          _matrixResult = stringResult;
        } else {
          _matrixResult = result
              .map((row) =>
              row
                  .map((value) => _removeTrailingZeros(value.toStringAsFixed(4)))
                  .toList()) // Format results nicely
              .toList();
        }
      });
    } catch (e) {
      setState(() =>
      _matrixResult = [
        [_tr(e.toString().replaceFirst('Exception: ', ''))]
      ]);
    }
  }

  List<List<double>> _matrixAddition(List<List<double>> a,
      List<List<double>> b) {
    return List.generate(
        a.length, (i) => List.generate(a[i].length, (j) => a[i][j] + b[i][j]));
  }

  List<List<double>> _matrixSubtraction(List<List<double>> a,
      List<List<double>> b) {
    return List.generate(
        a.length, (i) => List.generate(a[i].length, (j) => a[i][j] - b[i][j]));
  }

  List<List<double>> _matrixMultiplication(List<List<double>> a,
      List<List<double>> b) {
    if (a.isEmpty || b.isEmpty || a[0].length != b.length) {
      throw Exception('Invalid matrix dimensions for multiplication');
    }
    List<List<double>> result =
    List.generate(a.length, (_) => List.filled(b[0].length, 0.0));
    for (int i = 0; i < a.length; i++) {
      for (int j = 0; j < b[0].length; j++) {
        for (int k = 0; k < a[0].length; k++) {
          result[i][j] += a[i][k] * b[k][j];
        }
      }
    }
    return result;
  }

  double _matrixDeterminant(List<List<double>> matrix) {
    if (_matrixSize == 2) {
      return (matrix[0][0] * matrix[1][1]) - (matrix[0][1] * matrix[1][0]);
    } else if (_matrixSize == 3) {
      final a = matrix; // shorthand
      return a[0][0] * (a[1][1] * a[2][2] - a[1][2] * a[2][1]) -
          a[0][1] * (a[1][0] * a[2][2] - a[1][2] * a[2][0]) +
          a[0][2] * (a[1][0] * a[2][1] - a[1][1] * a[2][0]);
    }
    return 0; // Should not happen for size 2 or 3
  }

  List<List<double>> _matrixCofactors(List<List<double>> matrix) {
    if (_matrixSize == 2) {
      return [
        [matrix[1][1], -matrix[1][0]],
        [-matrix[0][1], matrix[0][0]]
      ];
    } else if (_matrixSize == 3) {
      final a = matrix;
      return [
        [
          (a[1][1] * a[2][2] - a[1][2] * a[2][1]),
          -(a[1][0] * a[2][2] - a[1][2] * a[2][0]),
          (a[1][0] * a[2][1] - a[1][1] * a[2][0])
        ],
        [
          -(a[0][1] * a[2][2] - a[0][2] * a[2][1]),
          (a[0][0] * a[2][2] - a[0][2] * a[2][0]),
          -(a[0][0] * a[2][1] - a[0][1] * a[2][0])
        ],
        [
          (a[0][1] * a[1][2] - a[0][2] * a[1][1]),
          -(a[0][0] * a[1][2] - a[0][2] * a[1][0]),
          (a[0][0] * a[1][1] - a[0][1] * a[1][0])
        ]
      ];
    }
    return []; // Should not happen
  }

  List<List<double>> _matrixTranspose(List<List<double>> matrix) {
    return List.generate(
        _matrixSize, (i) => List.generate(_matrixSize, (j) => matrix[j][i]));
  }

  List<List<double>> _matrixInverse(List<List<double>> matrix) {
    final det = _matrixDeterminant(matrix);
    if (det.abs() < 1e-10) {
      // Check for zero determinant
      throw Exception(_tr('Singular Matrix (Determinant is 0)'));
    }

    final cofactors = _matrixCofactors(matrix);
    final adjugate = _matrixTranspose(cofactors);

    return adjugate
        .map((row) => row.map((val) => val / det).toList())
        .toList();
  }

  void _changeMatrixSize(int newSize) {
    setState(() {
      _matrixSize = newSize;
      _initializeMatrices();
      _matrixResult = [];
    });
  }

  // --- UI Build Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tr('Calculator')),
        // Localized title
        backgroundColor: const Color(0xFF10141C).withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRRect(
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent))),
      ),
      body: _AnimatedBackground(
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700), // Max width
              child: Column(
                children: [
                  _buildModeSwitcher(),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _buildCurrentModeView(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentModeView() {
    switch (_mode) {
      case CalculatorMode.numberSystem:
        return _buildNumberSystemTab();
      case CalculatorMode.matrix:
        return _buildMatrixTab();
      case CalculatorMode.calculator:
      default:
        return _buildCalculatorTab();
    }
  }

  Widget _buildModeSwitcher() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          SegmentedButton<CalculatorMode>(
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.2),
              foregroundColor: Colors.white70,
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: const Color(0xFF007BFF).withOpacity(0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            segments: [
              ButtonSegment(
                  value: CalculatorMode.calculator,
                  label: Text(_tr('Calculator')),
                  icon: const Icon(Icons.calculate)),
              ButtonSegment(
                  value: CalculatorMode.numberSystem,
                  label: Text(_tr('Number Base')),
                  icon: const Icon(Icons.looks_two)),
              ButtonSegment(
                  value: CalculatorMode.matrix,
                  label: Text(_tr('Matrix')),
                  icon: const Icon(Icons.grid_on)),
            ],
            selected: {_mode},
            onSelectionChanged: (newSelection) =>
                setState(() => _mode = newSelection.first),
          ),
          const SizedBox(height: 8),
          if (_mode != CalculatorMode.calculator)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _isEnglish = !_isEnglish),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.2),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(_isEnglish ? _tr('বাংলা') : _tr('English'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalculatorTab() {
    // Reverted to Expanded layout to fit on one screen
    return Column(
      children: [
        _buildDisplay(), // Display takes its natural height
        Expanded(child: _buildCalculatorPad()), // Pad fills remaining space
      ],
    );
  }


  Widget _buildDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => _onButtonPressed('DEG/RAD'),
                child: Text(_isRadians ? 'RAD' : 'DEG',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
              IconButton(
                onPressed: () => _showHistoryDialog(),
                icon: const Icon(Icons.history_outlined,
                    color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_expression.isEmpty ? '0' : _expression.replaceAll('⁻¹', '-1'), // <-- THE FIX IS HERE
                    style: const TextStyle(color: Colors.white70, fontSize: 24),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Text(_result,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2C),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_tr('History'), // Localized
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      if (_history.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() => _history.clear());
                            setState(() {});
                          },
                          icon: const Icon(Icons.delete_sweep_outlined,
                              color: Colors.redAccent),
                          label: Text(_tr('Clear All'), // Localized
                              style: const TextStyle(color: Colors.redAccent)),
                        )
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  Expanded(
                    child: _history.isEmpty
                        ? Center(
                        child: Text(_tr('No history yet'), // Localized
                            style: const TextStyle(color: Colors.white70)))
                        : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history.reversed.toList()[index];
                        return ListTile(
                          title: Text(item['expression']!,
                              style:
                              const TextStyle(color: Colors.white)),
                          subtitle: Text('= ${item['result']!}',
                              style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold)),
                          onTap: () {
                            setState(() {
                              _expression = item['expression']!;
                              _result = item['result']!;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCalculatorPad() {
    // Scientific buttons (define or fetch as before)
    final List<String> scientificButtons = [
      'sin', 'cos', 'tan', 'sin⁻¹', 'cos⁻¹', 'tan⁻¹', 'log', 'ln', '√', '^',
      'π', 'e', 'x²', 'x³', 'nCr', '!', ','
    ];

    // Reverted to Expanded layout for main pad
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          _buildExpandableScientificPad(scientificButtons),
          // Takes natural height
          const SizedBox(height: 16),
          Expanded( // Main pad fills space BELOW scientific panel
            child: _buildMainPad(),
          ),
        ],
      ),
    );
  }


  Widget _buildExpandableScientificPad(List<String> buttons) {
    return Column(
      children: [
        Material( // Toggle button
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() => _isScientificPanelOpen = !_isScientificPanelOpen);
              if (_isScientificPanelOpen) {
                _sciPanelController.forward();
              } else {
                _sciPanelController.reverse();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_tr("Scientific Functions"), // Localized
                      style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  RotationTransition(
                    turns:
                    Tween(begin: 0.0, end: 0.5).animate(_sciPanelController),
                    child: const Icon(Icons.expand_more, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizeTransition( // Animation wrapper
          sizeFactor: _sciPanelAnimation,
          axisAlignment: -1.0,
          child: Container(
            padding: const EdgeInsets.only(top: 16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: buttons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                // --- MODIFIED GRID for compactness ---
                crossAxisCount: 6, // 6 buttons per row
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1.6, // Adjust ratio for 6 columns
                // --- END MODIFICATION ---
              ),
              itemBuilder: (context, index) {
                return _buildButton(buttons[index], isScientific: true);
              },
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildMainPad() {
    final buttonLayout = [
      ['C', '(', ')', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '⌫', '='],
    ];

    return Column(
      children: buttonLayout.map((row) {
        return Expanded( // Each row takes equal vertical space
          child: Row(
            children: row.map((buttonText) {
              final flex = (buttonText == '0') ? 2 : 1; // '0' button is wider
              return Expanded( // Each button takes horizontal space (flex allows '0' to be wider)
                flex: flex,
                child: Padding(
                  padding: const EdgeInsets.all(6.0), // Spacing around button
                  child: _buildButton(buttonText), // Build the actual button
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNumberSystemTab() {
    final List<String> numberSystems = [
      'Binary', 'Octal', 'Decimal', 'Hexadecimal'
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StyledCard(
          child: Column(children: [
            _buildDropdown<String>(
              _numberSystem,
              numberSystems,
                  (value) => setState(() => _numberSystem = value!),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                  labelText: '${_tr('Input')} (${_tr(_numberSystem)})',
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none)),
              style: const TextStyle(color: Colors.white, fontSize: 18),
              onChanged: (value) => setState(() => _numberInput = value),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: _convertNumber, child: Text(_tr('Convert'))),
          ]),
        ),
        const SizedBox(height: 20),
        if (_conversionResults.isNotEmpty)
          _StyledCard(
            child: Column(
              children: _conversionResults.entries.map((entry) {
                final bool isError = entry.key == 'Error';
                final String title = _tr(entry.key);
                final String subtitle = isError
                    ? '${_tr('Invalid input for')} ${_tr(_numberSystem)}'
                    : entry.value;

                return ListTile(
                  title: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white70)),
                  subtitle: SelectableText(subtitle,
                      style: TextStyle(
                          fontSize: 16,
                          color: isError ? Colors.redAccent : Colors.white)),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildMatrixTab() {
    final List<String> matrixOperations = [
      'Addition', 'Subtraction', 'Multiplication',
      'Determinant', 'Cofactors', 'Inverse'
    ];
    final bool needsMatrixB =
    ['Addition', 'Subtraction', 'Multiplication'].contains(_matrixOperation);

    return ListView(
      key: ValueKey('matrix_$_matrixSize'),
      padding: const EdgeInsets.all(16),
      children: [
        _StyledCard(
            child: Column(
              children: [
                _buildDropdown<String>(
                    _matrixOperation,
                    matrixOperations,
                        (value) =>
                        setState(() {
                          _matrixOperation = value!;
                          _matrixResult = [];
                        })),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_tr('Matrix Size:'),
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(width: 10),
                    DropdownButton<int>(
                      value: _matrixSize,
                      dropdownColor: const Color(0xFF1F2C50),
                      style: const TextStyle(color: Colors.white),
                      items: [2, 3]
                          .map((size) =>
                          DropdownMenuItem(
                              value: size, child: Text('$size x $size')))
                          .toList(),
                      onChanged: (value) => _changeMatrixSize(value!),
                    ),
                  ],
                ),
              ],
            )),
        const SizedBox(height: 20),
        _buildMatrixInput(_tr('Matrix A'), _matrixAControllers),
        if (needsMatrixB)
          Column(
            children: [
              const SizedBox(height: 20),
              _buildMatrixInput(_tr('Matrix B'), _matrixBControllers),
            ],
          ),
        const SizedBox(height: 20),
        ElevatedButton(
            onPressed: _calculateMatrix, child: Text(_tr('Calculate'))),
        if (_matrixResult.isNotEmpty) _buildMatrixResult(),
      ],
    );
  }

  Widget _buildMatrixInput(String label,
      List<List<TextEditingController>> matrixControllers) {
    return _StyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Column(
            children: List.generate(_matrixSize, (i) {
              return Row(
                children: List.generate(_matrixSize, (j) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextField(
                        controller: matrixControllers[i][j],
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.zero,
                            hintText: '0',
                            hintStyle: TextStyle(color: Colors.white30)),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixResult() {
    final bool isSingleValue =
        _matrixResult.length == 1 && _matrixResult[0].length == 1;

    return Padding( // Added padding for spacing
      padding: const EdgeInsets.only(top: 20.0),
      child: _StyledCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_tr('Result Matrix'),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const Divider(height: 24),
            if (isSingleValue)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                  _matrixResult[0][0],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _matrixResult[0][0].contains(_tr('Error')) ||
                          _matrixResult[0][0].contains(_tr('Singular'))
                          ? Colors.redAccent
                          : Colors.white),
                ),
              )
            else
              Column(
                children: List.generate(_matrixResult.length, (i) {
                  return Row(
                    children: List.generate(_matrixResult[i].length, (j) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(_matrixResult[i][j],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white)),
                        ),
                      );
                    }),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>(T value, List<String> items,
      ValueChanged<T?> onChanged) {
    return DropdownButton<T>(
      value: value,
      isExpanded: true,
      dropdownColor: const Color(0xFF1F2C50),
      style: const TextStyle(color: Colors.white),
      items: items
          .map((e) =>
          DropdownMenuItem(
              value: e as T,
              child: Text(_tr(e)))) // Translate the item text
          .toList(),
      onChanged: onChanged,
      // Add underline for better visibility
      underline: Container(
        height: 1,
        color: Colors.white54,
      ),
      iconEnabledColor: Colors.white70, // Make dropdown arrow visible
    );
  }

  Widget _buildButton(String text, {bool isScientific = false}) {
    Color buttonColor;
    Color textColor;

    if (text == '=') {
      buttonColor = const Color(0xFF007BFF);
      textColor = Colors.white;
    } else if (['C', '⌫'].contains(text)) {
      buttonColor = Colors.white.withOpacity(0.1);
      textColor = Colors.redAccent;
    } else if (['÷', '×', '-', '+', '^', '%', '(', ')', ','].contains(text)) {
      buttonColor = Colors.white.withOpacity(0.1);
      textColor = const Color(0xFF007BFF);
    } else if (isScientific) {
      buttonColor = Colors.black.withOpacity(0.2);
      textColor = Colors.white70;
    } else {
      buttonColor = Colors.white.withOpacity(0.1);
      textColor = Colors.white;
    }

    // Determine font size for non-inverse buttons
    double fontSize;
    if (isScientific) {
      fontSize = 14;
    } else {
      fontSize = 24; // Larger for main pad
    }

    // --- NEW: Create the child widget dynamically ---
    Widget childWidget;
    // Check for the specific strings that need custom rendering
    final bool isInverseTrig = isScientific &&
        (text == 'sin⁻¹' || text == 'cos⁻¹' || text == 'tan⁻¹');

    if (isInverseTrig) {
      // Get the base text ("sin", "cos", or "tan")
      final base = text.substring(0, 3);

      childWidget = RichText(
        text: TextSpan(
          // Default style (must include color and font family)
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
            fontFamily: DefaultTextStyle.of(context).style.fontFamily, // Inherit font
          ),
          children: [
            TextSpan(text: base, style: const TextStyle(fontSize: 14)), // Base text
            TextSpan(
              text: '-1', // Use "-1" instead of "⁻¹"
              style: const TextStyle(
                fontSize: 11, // Smaller size for superscript
                // This feature hints to the renderer to use superscript alignment
                fontFeatures: [FontFeature.superscripts()],
              ),
            ),
          ],
        ),
      );
    } else {
      // Original Text widget for all other buttons
      childWidget = Text(
        text,
        style: TextStyle(
          // Special case for x² and x³ which are usually in fonts
          fontSize: (text == 'x²' || text == 'x³') ? 18 : fontSize,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1, // Prevent text wrapping
      );
    }


    return ElevatedButton(
      onPressed: () => _onButtonPressed(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor,
        // Make scientific buttons slightly rounder, main buttons more square-ish
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isScientific ? 10 : 16)),
        padding: EdgeInsets.zero,
        // Let FittedBox handle sizing
        elevation: 0,
      ),
      child: Center(
        child: FittedBox( // Ensure text fits within the button
          fit: BoxFit.scaleDown,
          child: Padding( // Add minimal padding inside FittedBox
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: childWidget, // Use the dynamically created widget
          ),
        ),
      ),
    );
  }
}

// Reusable Animated Background (Keep as is)
class _AnimatedBackground extends StatefulWidget {
  final Widget child;
  const _AnimatedBackground({required this.child});

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 25))
      ..repeat(reverse: true);
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
                Color(0xFF0A0F1A),
                Color(0xFF10141C),
                Color(0xFF0B2A4B),
                Color(0xFF3A2A5B),
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

// Reusable Styled Card (Keep as is)
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
          side: BorderSide(color: Colors.white.withOpacity(0.15))),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: child,
      ),
    );
  }
}