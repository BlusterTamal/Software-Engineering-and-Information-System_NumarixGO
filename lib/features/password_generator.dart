/*
 * File: lib/features/password_generator.dart
 * Location: /c:/Users/Tamal/Documents/smart_numerix_v2/lib/features/password_generator.dart
 * Description: Secure password generator with customizable options
 */

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class PasswordHistoryEntry {
  String name;
  final String password;
  final DateTime date;

  PasswordHistoryEntry({required this.name, required this.password, required this.date});
}

enum GenerationMode { random, fromWords }
enum PasswordDifficulty { easy, medium, hard }

class PasswordGeneratorPage extends StatefulWidget {
  const PasswordGeneratorPage({super.key});

  @override
  State<PasswordGeneratorPage> createState() => _PasswordGeneratorPageState();
}

class _PasswordGeneratorPageState extends State<PasswordGeneratorPage> {
  double _passwordLength = 16.0;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSymbols = true;
  String _generatedPassword = '';
  PasswordStrength _strength = PasswordStrength.weak;

  GenerationMode _generationMode = GenerationMode.random;
  PasswordDifficulty _difficulty = PasswordDifficulty.medium;
  final TextEditingController _userWordsController = TextEditingController();

  final List<PasswordHistoryEntry> _passwordHistory = [];
  bool _isBengali = true;

  String tr(String key) => _localizedValues[_isBengali ? 'bn' : 'en']![key] ?? key;
  void _toggleLocale() => setState(() => _isBengali = !_isBengali);

  @override
  void initState() {
    super.initState();
    _generateRandomPassword();
  }

  @override
  void dispose() {
    _userWordsController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    FocusScope.of(context).unfocus();
    switch (_generationMode) {
      case GenerationMode.random:
        _generateRandomPassword();
        break;
      case GenerationMode.fromWords:
        _generatePasswordFromWords();
        break;
    }
  }

  void _generateRandomPassword() {
    const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lower = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String chars = '';
    if (_includeLowercase) chars += lower;
    if (_includeUppercase) chars += upper;
    if (_includeNumbers) chars += numbers;
    if (_includeSymbols) chars += symbols;

    if (chars.isEmpty) {
      setState(() {
        _generatedPassword = tr('error_no_chars');
        _strength = PasswordStrength.weak;
      });
      return;
    }

    final random = Random.secure();
    final password = String.fromCharCodes(Iterable.generate(
      _passwordLength.toInt(),
          (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));

    setState(() {
      _generatedPassword = password;
      _strength = _checkPasswordStrength(password);
    });
  }

  void _generatePasswordFromWords() {
    final words = _userWordsController.text.trim().split(RegExp(r'[\s,]+')).where((s) => s.isNotEmpty).toList();

    if (words.length < 2) {
      setState(() {
        _generatedPassword = tr('error_min_words');
        _strength = PasswordStrength.weak;
      });
      return;
    }

    String password = '';
    final random = Random.secure();
    const symbols = '!@#\$%^&*()_+-=';
    const numbers = '0123456789';

    switch (_difficulty) {
      case PasswordDifficulty.easy:
        password = words.map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join('-');
        break;
      case PasswordDifficulty.medium:
        final leetMap = {'a': '4', 'e': '3', 'i': '1', 'o': '0', 's': '5'};
        String transformed = words.map((w) => w.toLowerCase().split('').map((c) => leetMap[c] ?? c).join()).join('');
        password = '$transformed${numbers[random.nextInt(numbers.length)]}${symbols[random.nextInt(symbols.length)]}';
        break;
      case PasswordDifficulty.hard:
        words.shuffle(random);
        final leetMap = {'a': '@', 'e': '3', 'i': '!', 'o': '0', 's': '\$'};
        String base = words.map((w) => w.toLowerCase().split('').map((c) => leetMap[c] ?? c).join()).join('');
        int upperPos = random.nextInt(base.length);
        base = base.substring(0, upperPos) + base[upperPos].toUpperCase() + base.substring(upperPos + 1);
        int numPos = random.nextInt(base.length);
        password = base.substring(0, numPos) + numbers[random.nextInt(numbers.length)] + base.substring(numPos);
        break;
    }

    setState(() {
      _generatedPassword = password;
      _strength = _checkPasswordStrength(password);
    });
  }

  PasswordStrength _checkPasswordStrength(String password) {
    if (password.isEmpty || password.length < 8 || password.startsWith(tr('error_prefix'))) return PasswordStrength.weak;
    int score = 0;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*()_+\-=[\]{}|;:,.<>?]'))) score++;
    if (password.length >= 16 && score >= 4) return PasswordStrength.veryStrong;
    if (password.length >= 12 && score >= 3) return PasswordStrength.strong;
    if (score >= 2) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  void _copyToClipboard() {
    if (_generatedPassword.isNotEmpty && !_generatedPassword.startsWith(tr('error_prefix'))) {
      Clipboard.setData(ClipboardData(text: _generatedPassword));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('copied_message'))));
    }
  }

  Future<void> _savePassword() async {
    if (_generatedPassword.isEmpty || _generatedPassword.startsWith(tr('error_prefix'))) return;
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('save_dialog_title')),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(hintText: tr('save_dialog_hint')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(context, nameController.text), child: Text(tr('save'))),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      setState(() => _passwordHistory.insert(0, PasswordHistoryEntry(name: name, password: _generatedPassword, date: DateTime.now())));
    }
  }

  Future<void> _editHistoryItemName(int index) async {
    final entry = _passwordHistory[index];
    final nameController = TextEditingController(text: entry.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('edit_dialog_title')),
        content: TextField(controller: nameController, autofocus: true, decoration: InputDecoration(hintText: tr('edit_dialog_hint'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(context, nameController.text), child: Text(tr('update'))),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() => entry.name = newName);
    }
  }

  void _deleteHistoryItem(int index) => setState(() => _passwordHistory.removeAt(index));

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('clear_history_title')),
        content: Text(tr('clear_history_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(tr('delete'), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) setState(() => _passwordHistory.clear());
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
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildDisplayCard(),
              const SizedBox(height: 24),
              _buildModeSwitcher(),
              const SizedBox(height: 24),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: _generationMode == GenerationMode.random
                    ? _buildRandomSettingsCard()
                    : _buildFromWordsSettingsCard(),
              ),
              const SizedBox(height: 24),
              if (_passwordHistory.isNotEmpty) _buildHistorySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayCard() {
    return _StyledCard(
      child: Column(
        children: [
          SelectableText(
            _generatedPassword,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: _strength.color.withOpacity(0.5), blurRadius: 10)],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _PasswordStrengthIndicator(strength: _strength, isBengali: _isBengali),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(icon: Icons.copy_all_outlined, label: tr('copy'), onPressed: _copyToClipboard),
              _ActionButton(icon: Icons.save_outlined, label: tr('save'), onPressed: _savePassword),
              _ActionButton(icon: Icons.refresh_rounded, label: tr('regenerate'), onPressed: _generatePassword),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return SegmentedButton<GenerationMode>(
      style: SegmentedButton.styleFrom(
        backgroundColor: Colors.black.withOpacity(0.2),
        foregroundColor: Colors.white70,
        selectedForegroundColor: Colors.white,
        selectedBackgroundColor: const Color(0xFF007BFF).withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      segments: [
        ButtonSegment(value: GenerationMode.random, label: Text(tr('random_mode')), icon: const Icon(Icons.shuffle)),
        ButtonSegment(value: GenerationMode.fromWords, label: Text(tr('words_mode')), icon: const Icon(Icons.text_fields)),
      ],
      selected: {_generationMode},
      onSelectionChanged: (newSelection) {
        setState(() {
          _generationMode = newSelection.first;
          _generatePassword();
        });
      },
    );
  }

  Widget _buildFromWordsSettingsCard() {
    return _StyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('settings'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(height: 24, color: Colors.white24),
          TextField(
            controller: _userWordsController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: tr('words_input_label'),
              labelStyle: TextStyle(color: Colors.blue.shade200.withOpacity(0.7)),
              hintText: tr('words_input_hint'),
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.black.withOpacity(0.2),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _generatePassword(),
          ),
          const SizedBox(height: 20),
          Text(tr('difficulty'), style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 12),
          SegmentedButton<PasswordDifficulty>(
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.2),
              foregroundColor: Colors.white70,
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: const Color(0xFF007BFF).withOpacity(0.5),
            ),
            segments: [
              ButtonSegment(value: PasswordDifficulty.easy, label: Text(tr('easy'))),
              ButtonSegment(value: PasswordDifficulty.medium, label: Text(tr('medium'))),
              ButtonSegment(value: PasswordDifficulty.hard, label: Text(tr('hard'))),
            ],
            selected: {_difficulty},
            onSelectionChanged: (selection) => setState(() { _difficulty = selection.first; _generatePassword(); }),
          ),
        ],
      ),
    );
  }

  Widget _buildRandomSettingsCard() {
    return _StyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('settings'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(height: 24, color: Colors.white24),
          Text('${tr("length")}: ${_passwordLength.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 16)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF007BFF),
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF007BFF).withOpacity(0.3),
            ),
            child: Slider(
              value: _passwordLength, min: 6, max: 32, divisions: 26,
              label: _passwordLength.toInt().toString(),
              onChanged: (value) => setState(() => _passwordLength = value),
              onChangeEnd: (_) => _generatePassword(),
            ),
          ),
          _buildSwitchTile(tr('include_uppercase'), _includeUppercase, (val) => setState(() => _includeUppercase = val)),
          _buildSwitchTile(tr('include_lowercase'), _includeLowercase, (val) => setState(() => _includeLowercase = val)),
          _buildSwitchTile(tr('include_numbers'), _includeNumbers, (val) => setState(() => _includeNumbers = val)),
          _buildSwitchTile(tr('include_symbols'), _includeSymbols, (val) => setState(() => _includeSymbols = val)),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile.adaptive(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: value,
      onChanged: (val) { onChanged(val); _generatePassword(); },
      activeColor: const Color(0xFF007BFF),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildHistorySection() {
    return _StyledCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('history'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: _clearAllHistory,
                icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                label: Text(tr('clear_all')),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _passwordHistory.length,
            itemBuilder: (context, index) {
              final entry = _passwordHistory[index];
              return ListTile(
                title: Text(entry.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(entry.password, style: const TextStyle(fontFamily: 'monospace', color: Colors.white70)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white70), onPressed: () => _editHistoryItemName(index), tooltip: tr('edit')),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: () => _deleteHistoryItem(index), tooltip: tr('delete')),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}

enum PasswordStrength { weak, medium, strong, veryStrong }

extension on PasswordStrength {
  Color get color {
    switch (this) {
      case PasswordStrength.weak: return Colors.redAccent;
      case PasswordStrength.medium: return Colors.orangeAccent;
      case PasswordStrength.strong: return Colors.lightGreenAccent;
      case PasswordStrength.veryStrong: return Colors.cyanAccent;
    }
  }

  String text(bool isBengali) {
    final key = 'strength_${name}';
    return _localizedValues[isBengali ? 'bn' : 'en']![key] ?? name;
  }

  double get value {
    switch (this) {
      case PasswordStrength.weak: return 0.25; case PasswordStrength.medium: return 0.5;
      case PasswordStrength.strong: return 0.75; case PasswordStrength.veryStrong: return 1.0;
    }
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  const _PasswordStrengthIndicator({required this.strength, required this.isBengali});
  final PasswordStrength strength;
  final bool isBengali;

  String tr(String key) => _localizedValues[isBengali ? 'bn' : 'en']![key] ?? key;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: strength.value, backgroundColor: strength.color.withOpacity(0.2), color: strength.color, minHeight: 10),
        ),
        const SizedBox(height: 8),
        Text('${tr("strength")}: ${strength.text(isBengali)}', style: TextStyle(color: strength.color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
          iconSize: 24,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))
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
    'app_title': 'Password Generator',
    'copy': 'Copy', 'save': 'Save', 'regenerate': 'Regenerate',
    'random_mode': 'Random', 'words_mode': 'From Words',
    'settings': 'Settings',
    'words_input_label': 'Enter words (separated by spaces)',
    'words_input_hint': 'e.g., correct horse battery',
    'difficulty': 'Difficulty',
    'easy': 'Easy', 'medium': 'Medium', 'hard': 'Hard',
    'length': 'Password Length',
    'include_uppercase': 'Include Uppercase (A-Z)',
    'include_lowercase': 'Include Lowercase (a-z)',
    'include_numbers': 'Include Numbers (0-9)',
    'include_symbols': 'Include Symbols (!@#)',
    'history': 'History',
    'clear_all': 'Clear All',
    'strength': 'Strength',
    'strength_weak': 'Weak',
    'strength_medium': 'Medium',
    'strength_strong': 'Strong',
    'strength_veryStrong': 'Very Strong',
    'copied_message': 'Password copied to clipboard!',
    'save_dialog_title': 'Save Password',
    'save_dialog_hint': 'Enter a name (e.g., "Email")',
    'cancel': 'Cancel',
    'edit_dialog_title': 'Edit Name',
    'edit_dialog_hint': 'Enter a new name',
    'update': 'Update',
    'clear_history_title': 'Clear History',
    'clear_history_confirm': 'Are you sure you want to delete all saved passwords?',
    'delete': 'Delete',
    'edit': 'Edit',
    'error_prefix': 'Error',
    'error_no_chars': 'Error: Select at least one character type',
    'error_min_words': 'Error: Enter at least 2 words',
  },
  'bn': {
    'app_title': 'পাসওয়ার্ড জেনারেটর',
    'copy': 'কপি', 'save': 'সংরক্ষণ', 'regenerate': 'পুনরায় তৈরি',
    'random_mode': 'এলোমেলো', 'words_mode': 'শব্দ থেকে',
    'settings': 'সেটিংস',
    'words_input_label': 'শব্দ লিখুন (স্পেস দ্বারা পৃথক)',
    'words_input_hint': 'যেমন, সঠিক ঘোড়া ব্যাটারি',
    'difficulty': 'কঠিনতা',
    'easy': 'সহজ', 'medium': 'মাঝারি', 'hard': 'কঠিন',
    'length': 'পাসওয়ার্ডের দৈর্ঘ্য',
    'include_uppercase': 'বড় হাতের অক্ষর (A-Z)',
    'include_lowercase': 'ছোট হাতের অক্ষর (a-z)',
    'include_numbers': 'সংখ্যা (0-9)',
    'include_symbols': 'প্রতীক (!@#)',
    'history': 'ইতিহাস',
    'clear_all': 'সব মুছুন',
    'strength': 'শক্তি',
    'strength_weak': 'দুর্বল',
    'strength_medium': 'মাঝারি',
    'strength_strong': 'শক্তিশালী',
    'strength_veryStrong': 'খুব শক্তিশালী',
    'copied_message': 'পাসওয়ার্ড ক্লিপবোর্ডে কপি করা হয়েছে!',
    'save_dialog_title': 'পাসওয়ার্ড সংরক্ষণ করুন',
    'save_dialog_hint': 'একটি নাম লিখুন (যেমন, "ইমেল")',
    'cancel': 'বাতিল',
    'edit_dialog_title': 'নাম সম্পাদনা করুন',
    'edit_dialog_hint': 'একটি নতুন নাম লিখুন',
    'update': 'আপডেট',
    'clear_history_title': 'ইতিহাস মুছুন',
    'clear_history_confirm': 'আপনি কি সব সংরক্ষিত পাসওয়ার্ড মুছে ফেলতে চান?',
    'delete': 'মুছে ফেলুন',
    'edit': 'সম্পাদনা',
    'error_prefix': 'ত্রুটি',
    'error_no_chars': 'ত্রুটি: অন্তত একটি অক্ষরের ধরন নির্বাচন করুন',
    'error_min_words': 'ত্রুটি: অন্তত ২টি শব্দ লিখুন',
  },
};