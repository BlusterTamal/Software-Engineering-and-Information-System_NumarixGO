/*
 * File: lib/home_page.dart
 * Location: /c:/Users/Tamal/Documents/smart_numerix_v2/lib/home_page.dart
 * Description: Main dashboard/home screen with quick access to all calculators
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'features/age_calculator.dart';
import 'features/bmi_calculator.dart';
import 'features/bmr_calculator.dart';
import 'features/currency_converter.dart';
import 'features/gpa_calculator.dart';
import 'features/land_size_calculator.dart';
import 'features/password_generator.dart';
import 'features/scientific_calculator.dart';
import 'features/unit_converter.dart';
import 'features/world_time.dart';
import 'features/cost_calculator_page.dart';

class Tool {
  final String name;
  final IconData icon;
  final Color color;
  final Widget page;

  Tool({
    required this.name,
    required this.icon,
    required this.color,
    required this.page,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _numPages = 0;

  late final List<Tool> _allTools;

  Timer? _timer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _allTools = [
      Tool(
        name: 'Scientific Calculator',
        icon: Icons.calculate_rounded,
        color: const Color(0xFF26a69a),
        page: const ScientificCalculatorPage(),
      ),
      Tool(
        name: 'Currency Converter',
        icon: Icons.currency_exchange_rounded,
        color: const Color(0xFF42a5f5),
        page: const CurrencyConverterPage(),
      ),
      Tool(
        name: 'Unit Converter',
        icon: Icons.swap_horiz_rounded,
        color: const Color(0xFFab47bc),
        page: const UnitConverterPage(),
      ),
      Tool(
        name: 'BMI Calculator',
        icon: Icons.monitor_weight_rounded,
        color: const Color(0xFFef5350),
        page: const BmiCalculatorPage(),
      ),
      Tool(
        name: 'Age Calculator',
        icon: Icons.cake_rounded,
        color: const Color(0xFFffa726),
        page: const AgeCalculatorPage(),
      ),
      Tool(
        name: 'Password Generator',
        icon: Icons.password_rounded,
        color: const Color(0xFF5c6bc0),
        page: const PasswordGeneratorPage(),
      ),
      Tool(
        name: 'BMR Calculator',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFff7043),
        page: const BmrCalculatorPage(),
      ),
      Tool(
        name: 'GPA Calculator',
        icon: Icons.school_rounded,
        color: const Color(0xFF29b6f6),
        page: const GpaCalculatorPage(),
      ),
      Tool(
        name: 'World Clock',
        icon: Icons.public_rounded,
        color: const Color(0xFF66bb6a),
        page: const WorldClockDesign(),
      ),
      Tool(
        name: 'Land Size Calculator',
        icon: Icons.square_foot_rounded,
        color: const Color(0xFF7e57c2),
        page: const LandSizeCalculatorPage(),
      ),
      Tool(
        name: 'Cost Tracker',
        icon: Icons.paid_rounded,
        color: const Color(0xFFd4e157), // A new lime color
        page: const CostCalculatorPage(),
      ),
    ];

    _numPages = (_allTools.length / 4).ceil();

    _pageController.addListener(() {
      int nextPage = _pageController.page?.round() ?? 0;
      if (_currentPage != nextPage) {
        setState(() {
          _currentPage = nextPage;
        });
      }
    });

    _currentTime = _formatCurrentTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = _formatCurrentTime();
        });
      }
    });
  }

  String _formatCurrentTime() {
    return DateFormat('hh:mm:ss a').format(DateTime.now());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildAppBar(context),
      body: _buildDashboardBody(),
    );
  }

  Widget _buildDashboardBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildAllToolsHeader(),
          _buildToolsSection(),
        ],
      ),
    );
  }


  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.background,
      elevation: 0,
      title: Text(
        'NumarixGO',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            themeNotifier.toggleTheme();
          },
          icon: Icon(
            themeNotifier.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _showAboutDialog();
          },
          icon: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A74CF), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: const Text(
                'Hello, Welcome Back!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentTime,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ready to tackle some numbers? Your tools are just a tap away.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
    );
  }

  Widget _buildAllToolsHeader() {
    return _buildSectionHeader('All Tools');
  }

  Widget _buildToolsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardSide = (screenWidth - 16 * 2 - 16) / 2;
    final containerHeight = (cardSide * 2 + 16).clamp(0.0, double.infinity);

    return Column(
      children: [
        SizedBox(
          height: containerHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _numPages,
            itemBuilder: (context, pageIndex) {
              final startIndex = pageIndex * 4;
              final endIndex = (startIndex + 4 > _allTools.length)
                  ? _allTools.length
                  : startIndex + 4;
              final pageTools = _allTools.sublist(startIndex, endIndex);

              return _buildToolPage(pageTools);
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildPageIndicator(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildToolPage(List<Tool> tools) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: tools.map((tool) {
        return _buildToolGridCard(
          tool: tool, // Pass the whole tool object
        );
      }).toList(),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_numPages, (index) {
        return _buildDotIndicator(isActive: index == _currentPage);
      }),
    );
  }

  Widget _buildDotIndicator({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 10,
      width: isActive ? 24 : 10,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _buildToolGridCard({required Tool tool}) {
    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();

        await Future.delayed(const Duration(milliseconds: 50));

        if (mounted) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => tool.page,
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return child; // Just return the child page directly
              },
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: tool.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(tool.icon, color: tool.color, size: 32),
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tool.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About NumarixGO'),
        content: const Text(
          'NumarixGO is your ultimate calculator and utility hub. '
              'Get access to scientific calculators, converters, generators, '
              'and more tools to make your calculations smart and efficient.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}