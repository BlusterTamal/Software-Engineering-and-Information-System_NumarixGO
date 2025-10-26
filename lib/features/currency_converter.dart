/*
 * File: lib/features/currency_converter.dart
 * Location: /c:/Users/Tamal/Documents/smart_numerix_v2/lib/features/currency_converter.dart
 * Description: Real-time currency conversion with historical charts and multiple API fallbacks
 */

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import 'currency_service.dart';

class CurrencyConverterPage extends StatefulWidget {
  const CurrencyConverterPage({super.key});

  @override
  _CurrencyConverterPageState createState() => _CurrencyConverterPageState();
}

class _CurrencyConverterPageState extends State<CurrencyConverterPage> {
  final CurrencyService _currencyService = CurrencyService();
  final TextEditingController _amountController = TextEditingController(text: '1.00');

  String _fromCurrency = 'USD';
  String _toCurrency = 'BDT';
  double _amount = 1.0;
  double _convertedAmount = 0.0;
  Map<String, double> _rates = {};
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _lastUpdated;
  bool _isBengali = true;

  String _s(String key) => _translations[key]?[_isBengali ? 'bn' : 'en'] ?? key;
  String _n(String key, String langKey) => _currencyNames[key]?[langKey] ?? key;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _toggleLanguage() {
    setState(() => _isBengali = !_isBengali);
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final futures = await Future.wait([
        _currencyService.getLatestRates(_fromCurrency),
        _currencyService.getCacheTimestamp(),
      ]);

      final latestData = futures[0] as Map<String, dynamic>;
      _lastUpdated = futures[1] as DateTime?;

      if (!latestData.containsKey('rates')) throw Exception('Invalid data received');

      final ratesData = latestData['rates'] as Map<String, dynamic>;
      _rates = ratesData.map((key, value) => MapEntry(key, (value as num).toDouble()));
      _rates[latestData['base'] ?? _fromCurrency] = 1.0;

      if (mounted) {
        _convertCurrency();
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _s('error_message');
          _isLoading = false;
        });
      }
    }
  }

  void _convertCurrency() {
    if (_rates.containsKey(_toCurrency)) {
      final rate = _rates[_toCurrency]!;
      setState(() => _convertedAmount = _amount * rate);
    }
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _loadData();
  }

  void _onAmountChanged(String value) {
    setState(() {
      _amount = double.tryParse(value) ?? 0;
      _convertCurrency();
    });
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
          bottom: false,
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator(radius: 18, color: Colors.white))
              : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildConverterSection(),
        const SizedBox(height: 16),
        if(_lastUpdated != null)
          Center(
            child: Text(
              '${_s('last_updated')}: ${DateFormat.yMMMd().add_jm().format(_lastUpdated!)}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
        _buildQuickInfoCard(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: _StyledCard(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.wifi_exclamationmark, size: 50, color: Colors.orangeAccent),
              const SizedBox(height: 20),
              Text(
                _s('error_title'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(_s('retry_btn')),
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007BFF), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConverterSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            _ConverterPod(
              label: _s('you_send'),
              amountController: _amountController,
              selectedCurrency: _fromCurrency,
              onCurrencyChanged: (val) {
                if (val != null) setState(() { _fromCurrency = val; _loadData(); });
              },
              isInput: true,
              onAmountChanged: _onAmountChanged,
            ),
            const SizedBox(height: 8),
            _ConverterPod(
              label: _s('they_get'),
              amount: _convertedAmount.toStringAsFixed(2),
              selectedCurrency: _toCurrency,
              onCurrencyChanged: (val) {
                if (val != null) setState(() { _toCurrency = val; _loadData(); });
              },
              isInput: false,
            ),
          ],
        ),
        Transform.translate(
          offset: const Offset(0, 4),
          child: InkWell(
            onTap: _swapCurrencies,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF007BFF), Colors.blueAccent]),
                boxShadow: [BoxShadow(color: Colors.blueAccent, blurRadius: 15, offset: Offset(0, 5))],
              ),
              child: const Icon(CupertinoIcons.arrow_2_circlepath, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInfoCard() {
    final rate = _rates[_toCurrency];
    if (rate == null || rate == 0) return const SizedBox.shrink();

    final inverseRate = (1 / rate).toStringAsFixed(6);
    final langKey = _isBengali ? 'bn' : 'en';

    return _StyledCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_s('quick_info'), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text(_s('inverse_rate'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            '1 $_toCurrency = $inverseRate $_fromCurrency',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const Divider(height: 24, color: Colors.white24),
          Text(_s('full_name'), style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(_currencyFlags[_fromCurrency] ?? '🏳️', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _n(_fromCurrency, langKey),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(_currencyFlags[_toCurrency] ?? '🏳️', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _n(_toCurrency, langKey),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConverterPod extends StatelessWidget {
  final String label;
  final String selectedCurrency;
  final ValueChanged<String?> onCurrencyChanged;
  final bool isInput;
  final TextEditingController? amountController;
  final String? amount;
  final ValueChanged<String>? onAmountChanged;

  const _ConverterPod({
    required this.label, required this.selectedCurrency,
    required this.onCurrencyChanged, required this.isInput,
    this.amountController, this.amount, this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _StyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: isInput
                    ? TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  decoration: const InputDecoration.collapsed(hintText: '0.00', hintStyle: TextStyle(color: Colors.white30)),
                  onChanged: onAmountChanged,
                )
                    : Text(amount ?? '0.00', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: selectedCurrency,
                  isExpanded: true,
                  decoration: const InputDecoration(border: InputBorder.none),
                  dropdownColor: const Color(0xFF1F2C50),
                  icon: const Icon(CupertinoIcons.chevron_down, color: Colors.white70, size: 18),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  items: _currencyFlags.keys.map((String currency) {
                    return DropdownMenuItem<String>(
                      value: currency,
                      child: Row(
                        children: [
                          Text(_currencyFlags[currency] ?? '🏳️', style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(currency, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: onCurrencyChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StyledCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  const _StyledCard({required this.child, this.padding, this.margin});

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

const Map<String, Map<String, String>> _translations = {
  'app_title': {'bn': 'মুদ্রা রূপান্তরকারী', 'en': 'Currency Converter'},
  'you_send': {'bn': 'আপনি পাঠাচ্ছেন', 'en': 'You Send'},
  'they_get': {'bn': 'তারা পাবে', 'en': 'They Get'},
  'last_updated': {'bn': 'সর্বশেষ আপডেট', 'en': 'Last Updated'},
  'error_title': {'bn': 'সংযোগ ত্রুটি', 'en': 'Connection Error'},
  'error_message': {'bn': 'ডেটা আনা যায়নি। আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন।', 'en': 'Could not fetch data. Please check your internet connection.'},
  'retry_btn': {'bn': 'আবার চেষ্টা করুন', 'en': 'Retry'},
  'quick_info': {'bn': 'দ্রুত তথ্য', 'en': 'Quick Info'},
  'inverse_rate': {'bn': 'বিপরীত হার', 'en': 'Inverse Rate'},
  'full_name': {'bn': 'পুরো নাম', 'en': 'Full Name'},
};

const Map<String, String> _currencyFlags = {
  'AED': '🇦🇪', // UAE Dirham
  'AFN': '🇦🇫', // Afghan Afghani
  'ALL': '🇦🇱', // Albanian Lek
  'AMD': '🇦🇲', // Armenian Dram
  'ANG': '🇳🇱', // Netherlands Antillean Guilder (Uses NL flag as it's part of the Kingdom)
  'AOA': '🇦🇴', // Angolan Kwanza
  'ARS': '🇦🇷', // Argentine Peso
  'AUD': '🇦🇺', // Australian Dollar
  'AWG': '🇦🇼', // Aruban Florin
  'AZN': '🇦🇿', // Azerbaijani Manat
  'BAM': '🇧🇦', // Bosnia-Herzegovina Convertible Mark
  'BBD': '🇧🇧', // Barbadian Dollar
  'BDT': '🇧🇩', // Bangladeshi Taka
  'BGN': '🇧🇬', // Bulgarian Lev
  'BHD': '🇧🇭', // Bahraini Dinar
  'BIF': '🇧🇮', // Burundian Franc
  'BMD': '🇧🇲', // Bermudan Dollar
  'BND': '🇧🇳', // Brunei Dollar
  'BOB': '🇧🇴', // Bolivian Boliviano
  'BRL': '🇧🇷', // Brazilian Real
  'BSD': '🇧🇸', // Bahamian Dollar
  'BTN': '🇧🇹', // Bhutanese Ngultrum
  'BWP': '🇧🇼', // Botswanan Pula
  'BYN': '🇧🇾', // Belarusian Ruble
  'BZD': '🇧🇿', // Belize Dollar
  'CAD': '🇨🇦', // Canadian Dollar
  'CDF': '🇨🇩', // Congolese Franc
  'CHF': '🇨🇭', // Swiss Franc
  'CKD': '🇨🇰', // Cook Islands Dollar
  'CLP': '🇨🇱', // Chilean Peso
  'CNY': '🇨🇳', // Chinese Yuan
  'COP': '🇨🇴', // Colombian Peso
  'CRC': '🇨🇷', // Costa Rican Colón
  'CUP': '🇨🇺', // Cuban Peso
  'CVE': '🇨🇻', // Cape Verdean Escudo
  'CZK': '🇨🇿', // Czech Koruna
  'DJF': '🇩🇯', // Djiboutian Franc
  'DKK': '🇩🇰', // Danish Krone
  'DOP': '🇩🇴', // Dominican Peso
  'DZD': '🇩🇿', // Algerian Dinar
  'EGP': '🇪🇬', // Egyptian Pound
  'ERN': '🇪🇷', // Eritrean Nakfa
  'ETB': '🇪🇹', // Ethiopian Birr
  'EUR': '🇪🇺', // Euro
  'FJD': '🇫🇯', // Fijian Dollar
  'FKP': '🇫🇰', // Falkland Islands Pound
  'FOK': '🇫🇴', // Faroese Króna
  'GBP': '🇬🇧', // British Pound
  'GEL': '🇬🇪', // Georgian Lari
  'GGP': '🇬🇬', // Guernsey Pound
  'GHS': '🇬🇭', // Ghanaian Cedi
  'GIP': '🇬🇮', // Gibraltar Pound
  'GMD': '🇬🇲', // Gambian Dalasi
  'GNF': '🇬🇳', // Guinean Franc
  'GTQ': '🇬🇹', // Guatemalan Quetzal
  'GYD': '🇬🇾', // Guyanaese Dollar
  'HKD': '🇭🇰', // Hong Kong Dollar
  'HNL': '🇭🇳', // Honduran Lempira
  'HRK': '🇭🇷', // Croatian Kuna (largely replaced by EUR)
  'HTG': '🇭🇹', // Haitian Gourde
  'HUF': '🇭🇺', // Hungarian Forint
  'IDR': '🇮🇩', // Indonesian Rupiah
  'ILS': '🇮🇱', // Israeli New Shekel
  'IMP': '🇮🇲', // Manx Pound
  'INR': '🇮🇳', // Indian Rupee
  'IQD': '🇮🇶', // Iraqi Dinar
  'IRR': '🇮🇷', // Iranian Rial
  'ISK': '🇮🇸', // Icelandic Króna
  'JEP': '🇯🇪', // Jersey Pound
  'JMD': '🇯🇲', // Jamaican Dollar
  'JOD': '🇯🇴', // Jordanian Dinar
  'JPY': '🇯🇵', // Japanese Yen
  'KES': '🇰🇪', // Kenyan Shilling
  'KGS': '🇰🇬', // Kyrgystani Som
  'KHR': '🇰🇭', // Cambodian Riel
  'KID': '🇰🇮', // Kiribati Dollar
  'KMF': '🇰🇲', // Comorian Franc
  'KPW': '🇰🇵', // North Korean Won
  'KRW': '🇰🇷', // South Korean Won
  'KWD': '🇰🇼', // Kuwaiti Dinar
  'KYD': '🇰🇾', // Cayman Islands Dollar
  'KZT': '🇰🇿', // Kazakhstani Tenge
  'LAK': '🇱🇦', // Laotian Kip
  'LBP': '🇱🇧', // Lebanese Pound
  'LKR': '🇱🇰', // Sri Lankan Rupee
  'LRD': '🇱🇷', // Liberian Dollar
  'LSL': '🇱🇸', // Lesotho Loti
  'LYD': '🇱🇾', // Libyan Dinar
  'MAD': '🇲🇦', // Moroccan Dirham
  'MDL': '🇲🇩', // Moldovan Leu
  'MGA': '🇲🇬', // Malagasy Ariary
  'MKD': '🇲🇰', // Macedonian Denar
  'MMK': '🇲🇲', // Myanmar Kyat
  'MNT': '🇲🇳', // Mongolian Tugrik
  'MOP': '🇲🇴', // Macanese Pataca
  'MRU': '🇲🇷', // Mauritanian Ouguiya
  'MUR': '🇲🇺', // Mauritian Rupee
  'MVR': '🇲🇻', // Maldivian Rufiyaa
  'MWK': '🇲🇼', // Malawian Kwacha
  'MXN': '🇲🇽', // Mexican Peso
  'MYR': '🇲🇾', // Malaysian Ringgit
  'MZN': '🇲🇿', // Mozambican Metical
  'NAD': '🇳🇦', // Namibian Dollar
  'NGN': '🇳🇬', // Nigerian Naira
  'NIO': '🇳🇮', // Nicaraguan Córdoba
  'NOK': '🇳🇴', // Norwegian Krone
  'NPR': '🇳🇵', // Nepalese Rupee
  'NZD': '🇳🇿', // New Zealand Dollar
  'OMR': '🇴🇲', // Omani Rial
  'PAB': '🇵🇦', // Panamanian Balboa
  'PEN': '🇵🇪', // Peruvian Sol
  'PGK': '🇵🇬', // Papua New Guinean Kina
  'PHP': '🇵🇭', // Philippine Peso
  'PKR': '🇵🇰', // Pakistani Rupee
  'PLN': '🇵🇱', // Polish Złoty
  'PYG': '🇵🇾', // Paraguayan Guarani
  'QAR': '🇶🇦', // Qatari Riyal
  'RON': '🇷🇴', // Romanian Leu
  'RSD': '🇷🇸', // Serbian Dinar
  'RUB': '🇷🇺', // Russian Ruble
  'RWF': '🇷🇼', // Rwandan Franc
  'SAR': '🇸🇦', // Saudi Riyal
  'SBD': '🇸🇧', // Solomon Islands Dollar
  'SCR': '🇸🇨', // Seychellois Rupee
  'SDG': '🇸🇩', // Sudanese Pound
  'SEK': '🇸🇪', // Swedish Krona
  'SGD': '🇸🇬', // Singapore Dollar
  'SHP': '🇸🇭', // Saint Helena Pound
  'SLE': '🇸🇱', // Sierra Leonean Leone (New)
  'SLL': '🇸🇱', // Sierra Leonean Leone (Old, still common)
  'SOS': '🇸🇴', // Somali Shilling
  'SRD': '🇸🇷', // Surinamese Dollar
  'SSP': '🇸🇸', // South Sudanese Pound
  'STN': '🇸🇹', // São Tomé and Príncipe Dobra
  'SVC': '🇸🇻', // Salvadoran Colón (largely replaced by USD)
  'SYP': '🇸🇾', // Syrian Pound
  'SZL': '🇸🇿', // Swazi Lilangeni
  'THB': '🇹🇭', // Thai Baht
  'TJS': '🇹🇯', // Tajikistani Somoni
  'TMT': '🇹🇲', // Turkmenistani Manat
  'TND': '🇹🇳', // Tunisian Dinar
  'TOP': '🇹🇴', // Tongan Paʻanga
  'TRY': '🇹🇷', // Turkish Lira
  'TTD': '🇹🇹', // Trinidad and Tobago Dollar
  'TVD': '🇹🇻', // Tuvaluan Dollar
  'TWD': '🇹🇼', // New Taiwan Dollar
  'TZS': '🇹🇿', // Tanzanian Shilling
  'UAH': '🇺🇦', // Ukrainian Hryvnia
  'UGX': '🇺🇬', // Ugandan Shilling
  'USD': '🇺🇸', // US Dollar
  'UYU': '🇺🇾', // Uruguayan Peso
  'UZS': '🇺🇿', // Uzbekistani Som
  'VES': '🇻🇪', // Venezuelan Bolívar Soberano
  'VND': '🇻🇳', // Vietnamese Đồng
  'VUV': '🇻🇺', // Vanuatu Vatu
  'WST': '🇼🇸', // Samoan Tālā
  'XAF': '🇨🇲', // CFA Franc BEAC (Cameroon flag for Central Africa)
  'XAG': '🥈', // Silver (Troy Ounce) - Using medal emoji
  'XAU': '🥇', // Gold (Troy Ounce) - Using medal emoji
  'XCD': '🇦🇬', // East Caribbean Dollar (Antigua & Barbuda flag often used)
  'XDR': '🌍', // Special Drawing Rights (IMF) - Using globe emoji
  'XOF': '🇨🇫', // CFA Franc BCEAO (Central African Republic flag for West Africa)
  'XPD': '⚫', // Palladium (Troy Ounce) - Using black circle placeholder
  'XPF': '🇵🇫', // CFP Franc (French Polynesia flag often used)
  'XPT': '⚪', // Platinum (Troy Ounce) - Using white circle placeholder
  'YER': '🇾🇪', // Yemeni Rial
  'ZAR': '🇿🇦', // South African Rand
  'ZMW': '🇿🇲', // Zambian Kwacha
  'ZWL': '🇿🇼'  // Zimbabwean Dollar
};

const Map<String, Map<String, String>> _currencyNames = {
  'AED': {'bn': 'ইউএই দিরহাম', 'en': 'UAE Dirham'},
  'AFN': {'bn': 'আফগান আফগানি', 'en': 'Afghan Afghani'},
  'ALL': {'bn': 'আলবেনিয়ান লেক', 'en': 'Albanian Lek'},
  'AMD': {'bn': 'আর্মেনিয়ান ড্রাম', 'en': 'Armenian Dram'},
  'ANG': {'bn': 'নেদারল্যান্ডস অ্যান্টিলিয়ান গিল্ডার', 'en': 'Netherlands Antillean Guilder'},
  'AOA': {'bn': 'অ্যাঙ্গোলান কোয়ানজা', 'en': 'Angolan Kwanza'},
  'ARS': {'bn': 'আর্জেন্টাইন পেসো', 'en': 'Argentine Peso'},
  'AUD': {'bn': 'অস্ট্রেলিয়ান ডলার', 'en': 'Australian Dollar'},
  'AWG': {'bn': 'আরুবান ফ্লোরিন', 'en': 'Aruban Florin'},
  'AZN': {'bn': 'আজারবাইজানি মানাত', 'en': 'Azerbaijani Manat'},
  'BAM': {'bn': 'বসনিয়া-হার্জেগোভিনা রূপান্তরযোগ্য মার্ক', 'en': 'Bosnia-Herzegovina Convertible Mark'},
  'BBD': {'bn': 'বার্বাডিয়ান ডলার', 'en': 'Barbadian Dollar'},
  'BDT': {'bn': 'বাংলাদেশী টাকা', 'en': 'Bangladeshi Taka'},
  'BGN': {'bn': 'বুলগেরিয়ান লেভ', 'en': 'Bulgarian Lev'},
  'BHD': {'bn': 'বাহরাইনি দিনার', 'en': 'Bahraini Dinar'},
  'BIF': {'bn': 'বুরুন্ডিয়ান ফ্রাঁ', 'en': 'Burundian Franc'},
  'BMD': {'bn': 'বারমুডান ডলার', 'en': 'Bermudan Dollar'},
  'BND': {'bn': 'ব্রুনাই ডলার', 'en': 'Brunei Dollar'},
  'BOB': {'bn': 'বলিভিয়ান বলিভিয়ানো', 'en': 'Bolivian Boliviano'},
  'BRL': {'bn': 'ব্রাজিলিয়ান রিয়েল', 'en': 'Brazilian Real'},
  'BSD': {'bn': 'বাহামিয়ান ডলার', 'en': 'Bahamian Dollar'},
  'BTN': {'bn': 'ভুটানিজ এনগুলট্রাম', 'en': 'Bhutanese Ngultrum'},
  'BWP': {'bn': 'বতসোয়ানান পুলা', 'en': 'Botswanan Pula'},
  'BYN': {'bn': 'বেলারুশিয়ান রুবেল', 'en': 'Belarusian Ruble'},
  'BZD': {'bn': 'বেলিজ ডলার', 'en': 'Belize Dollar'},
  'CAD': {'bn': 'কানাডিয়ান ডলার', 'en': 'Canadian Dollar'},
  'CDF': {'bn': 'কঙ্গোলিজ ফ্রাঁ', 'en': 'Congolese Franc'},
  'CHF': {'bn': 'সুইস ফ্রাঁ', 'en': 'Swiss Franc'},
  'CKD': {'bn': 'কুক দ্বীপপুঞ্জ ডলার', 'en': 'Cook Islands Dollar'},
  'CLP': {'bn': 'চিলিয়ান পেসো', 'en': 'Chilean Peso'},
  'CNY': {'bn': 'চাইনিজ ইউয়ান', 'en': 'Chinese Yuan'},
  'COP': {'bn': 'কলম্বিয়ান পেসো', 'en': 'Colombian Peso'},
  'CRC': {'bn': 'কোস্টারিকান কোলন', 'en': 'Costa Rican Colón'},
  'CUP': {'bn': 'কিউবান পেসো', 'en': 'Cuban Peso'},
  'CVE': {'bn': 'কেপ ভার্ডিয়ান এসকুডো', 'en': 'Cape Verdean Escudo'},
  'CZK': {'bn': 'চেক কোরুনা', 'en': 'Czech Koruna'},
  'DJF': {'bn': 'জিবুতিয়ান ফ্রাঁ', 'en': 'Djiboutian Franc'},
  'DKK': {'bn': 'ডেনিশ ক্রোন', 'en': 'Danish Krone'},
  'DOP': {'bn': 'ডোমিনিকান পেসো', 'en': 'Dominican Peso'},
  'DZD': {'bn': 'আলজেরিয়ান দিনার', 'en': 'Algerian Dinar'},
  'EGP': {'bn': 'মিশরীয় পাউন্ড', 'en': 'Egyptian Pound'},
  'ERN': {'bn': 'ইরিত্রিয়ান নাকফা', 'en': 'Eritrean Nakfa'},
  'ETB': {'bn': 'ইথিওপিয়ান বির', 'en': 'Ethiopian Birr'},
  'EUR': {'bn': 'ইউরো', 'en': 'Euro'},
  'FJD': {'bn': 'ফিজিয়ান ডলার', 'en': 'Fijian Dollar'},
  'FKP': {'bn': 'ফকল্যান্ড দ্বীপপুঞ্জ পাউন্ড', 'en': 'Falkland Islands Pound'},
  'FOK': {'bn': 'ফ্যারোজি ক্রোনা', 'en': 'Faroese Króna'},
  'GBP': {'bn': 'ব্রিটিশ পাউন্ড', 'en': 'British Pound'},
  'GEL': {'bn': 'জর্জিয়ান লারি', 'en': 'Georgian Lari'},
  'GGP': {'bn': 'গার্নসি পাউন্ড', 'en': 'Guernsey Pound'},
  'GHS': {'bn': 'ঘানাইয়ান সিডি', 'en': 'Ghanaian Cedi'},
  'GIP': {'bn': 'জিব্রাল্টার পাউন্ড', 'en': 'Gibraltar Pound'},
  'GMD': {'bn': 'গাম্বিয়ান ডালাসি', 'en': 'Gambian Dalasi'},
  'GNF': {'bn': 'গিনিয়ান ফ্রাঁ', 'en': 'Guinean Franc'},
  'GTQ': {'bn': 'গুয়াতেমালান কুয়েটজাল', 'en': 'Guatemalan Quetzal'},
  'GYD': {'bn': 'গায়ানিজ ডলার', 'en': 'Guyanaese Dollar'},
  'HKD': {'bn': 'হংকং ডলার', 'en': 'Hong Kong Dollar'},
  'HNL': {'bn': 'হন্ডুরান লেম্পিরা', 'en': 'Honduran Lempira'},
  'HRK': {'bn': 'ক্রোয়েশিয়ান কুনা', 'en': 'Croatian Kuna'}, // Note: Replaced by EUR
  'HTG': {'bn': 'হাইতিয়ান গুর্ড', 'en': 'Haitian Gourde'},
  'HUF': {'bn': 'হাঙ্গেরিয়ান ফোরিন্ট', 'en': 'Hungarian Forint'},
  'IDR': {'bn': 'ইন্দোনেশিয়ান রুপিয়াহ', 'en': 'Indonesian Rupiah'},
  'ILS': {'bn': 'ইসরায়েলি নিউ শেকেল', 'en': 'Israeli New Shekel'},
  'IMP': {'bn': 'আইল অফ ম্যান পাউন্ড', 'en': 'Manx Pound'},
  'INR': {'bn': 'ভারতীয় রুপি', 'en': 'Indian Rupee'},
  'IQD': {'bn': 'ইরাকি দিনার', 'en': 'Iraqi Dinar'},
  'IRR': {'bn': 'ইরানিয়ান রিয়াল', 'en': 'Iranian Rial'},
  'ISK': {'bn': 'আইসল্যান্ডিক ক্রোনা', 'en': 'Icelandic Króna'},
  'JEP': {'bn': 'জার্সি পাউন্ড', 'en': 'Jersey Pound'},
  'JMD': {'bn': 'জ্যামাইকান ডলার', 'en': 'Jamaican Dollar'},
  'JOD': {'bn': 'জর্ডানিয়ান দিনার', 'en': 'Jordanian Dinar'},
  'JPY': {'bn': 'জাপানিজ ইয়েন', 'en': 'Japanese Yen'},
  'KES': {'bn': 'কেনিয়ান শিলিং', 'en': 'Kenyan Shilling'},
  'KGS': {'bn': 'কিরগিজস্তানি সোম', 'en': 'Kyrgystani Som'},
  'KHR': {'bn': 'কম্বোডিয়ান রিয়েল', 'en': 'Cambodian Riel'},
  'KID': {'bn': 'কিরিবাটি ডলার', 'en': 'Kiribati Dollar'},
  'KMF': {'bn': 'কোমোরিয়ান ফ্রাঁ', 'en': 'Comorian Franc'},
  'KPW': {'bn': 'উত্তর কোরিয়ান ওন', 'en': 'North Korean Won'},
  'KRW': {'bn': 'দক্ষিণ কোরিয়ান ওন', 'en': 'South Korean Won'},
  'KWD': {'bn': 'কুয়েতি দিনার', 'en': 'Kuwaiti Dinar'},
  'KYD': {'bn': 'কেম্যান দ্বীপপুঞ্জ ডলার', 'en': 'Cayman Islands Dollar'},
  'KZT': {'bn': 'কাজাখস্তানি টেঙ্গে', 'en': 'Kazakhstani Tenge'},
  'LAK': {'bn': 'লাওশিয়ান কিপ', 'en': 'Laotian Kip'},
  'LBP': {'bn': 'লেবানিজ পাউন্ড', 'en': 'Lebanese Pound'},
  'LKR': {'bn': 'শ্রীলঙ্কান রুপি', 'en': 'Sri Lankan Rupee'},
  'LRD': {'bn': 'লাইবেরিয়ান ডলার', 'en': 'Liberian Dollar'},
  'LSL': {'bn': 'লেসোথো লোতি', 'en': 'Lesotho Loti'},
  'LYD': {'bn': 'লিবিয়ান দিনার', 'en': 'Libyan Dinar'},
  'MAD': {'bn': 'মরক্কোর দিরহাম', 'en': 'Moroccan Dirham'},
  'MDL': {'bn': 'মোলডোভান লিউ', 'en': 'Moldovan Leu'},
  'MGA': {'bn': 'মালাগাসি আরিয়ারি', 'en': 'Malagasy Ariary'},
  'MKD': {'bn': 'ম্যাসেডোনিয়ান দিনার', 'en': 'Macedonian Denar'},
  'MMK': {'bn': 'মায়ানমার কিয়াট', 'en': 'Myanmar Kyat'},
  'MNT': {'bn': 'মঙ্গোলিয়ান তুগরিক', 'en': 'Mongolian Tugrik'},
  'MOP': {'bn': 'ম্যাকানিজ প্যাটাকা', 'en': 'Macanese Pataca'}, // Corrected
  'MRU': {'bn': 'মৌরিতানিয়ান ওগুইয়া', 'en': 'Mauritanian Ouguiya'},
  'MUR': {'bn': 'মরিশিয়ান রুপি', 'en': 'Mauritian Rupee'},
  'MVR': {'bn': 'মালদ্বীপিয়ান রুফিয়া', 'en': 'Maldivian Rufiyaa'},
  'MWK': {'bn': 'মালাউইয়ান কোয়াচা', 'en': 'Malawian Kwacha'},
  'MXN': {'bn': 'মেক্সিকান পেসো', 'en': 'Mexican Peso'},
  'MYR': {'bn': 'মালয়েশিয়ান রিঙ্গিত', 'en': 'Malaysian Ringgit'},
  'MZN': {'bn': 'মোজাম্বিকান মেটিক্যাল', 'en': 'Mozambican Metical'},
  'NAD': {'bn': 'নামিবিয়ান ডলার', 'en': 'Namibian Dollar'},
  'NGN': {'bn': 'নাইজেরিয়ান নাইরা', 'en': 'Nigerian Naira'},
  'NIO': {'bn': 'নিকারাগুয়ান কর্ডোবা', 'en': 'Nicaraguan Córdoba'},
  'NOK': {'bn': 'নরওয়েজিয়ান ক্রোন', 'en': 'Norwegian Krone'},
  'NPR': {'bn': 'নেপালি রুপি', 'en': 'Nepalese Rupee'},
  'NZD': {'bn': 'নিউজিল্যান্ড ডলার', 'en': 'New Zealand Dollar'},
  'OMR': {'bn': 'ওমানি রিয়াল', 'en': 'Omani Rial'},
  'PAB': {'bn': 'পানামানিয়ান বালবোয়া', 'en': 'Panamanian Balboa'},
  'PEN': {'bn': 'পেরুভিয়ান সল', 'en': 'Peruvian Sol'},
  'PGK': {'bn': 'পাপুয়া নিউ গিনিয়ান কিনা', 'en': 'Papua New Guinean Kina'},
  'PHP': {'bn': 'ফিলিপাইন পেসো', 'en': 'Philippine Peso'},
  'PKR': {'bn': 'পাকিস্তানি রুপি', 'en': 'Pakistani Rupee'},
  'PLN': {'bn': 'পোলিশ জ্লটি', 'en': 'Polish Złoty'},
  'PYG': {'bn': 'প্যারাগুয়ান গুয়ারানি', 'en': 'Paraguayan Guarani'},
  'QAR': {'bn': 'কাতারি রিয়াল', 'en': 'Qatari Riyal'},
  'RON': {'bn': 'রোমানিয়ান লিউ', 'en': 'Romanian Leu'},
  'RSD': {'bn': 'সার্বিয়ান দিনার', 'en': 'Serbian Dinar'},
  'RUB': {'bn': 'রাশিয়ান রুবেল', 'en': 'Russian Ruble'},
  'RWF': {'bn': 'রুয়ান্ডান ফ্রাঁ', 'en': 'Rwandan Franc'},
  'SAR': {'bn': 'সৌদি রিয়াল', 'en': 'Saudi Riyal'},
  'SBD': {'bn': 'সলোমন দ্বীপপুঞ্জ ডলার', 'en': 'Solomon Islands Dollar'},
  'SCR': {'bn': 'সেশেলোয়িস রুপি', 'en': 'Seychellois Rupee'},
  'SDG': {'bn': 'সুদানিজ পাউন্ড', 'en': 'Sudanese Pound'},
  'SEK': {'bn': 'সুইডিশ ক্রোনা', 'en': 'Swedish Krona'},
  'SGD': {'bn': 'সিঙ্গাপুর ডলার', 'en': 'Singapore Dollar'},
  'SHP': {'bn': 'সেন্ট হেলেনা পাউন্ড', 'en': 'Saint Helena Pound'},
  'SLE': {'bn': 'সিয়েরা লিওনিয়ান লিওন', 'en': 'Sierra Leonean Leone'}, // Note: SLL is still often used
  'SLL': {'bn': 'সিয়েরা লিওনিয়ান লিওন', 'en': 'Sierra Leonean Leone'},
  'SOS': {'bn': 'সোমালি শিলিং', 'en': 'Somali Shilling'},
  'SRD': {'bn': 'সুরিনামিজ ডলার', 'en': 'Surinamese Dollar'},
  'SSP': {'bn': 'দক্ষিণ সুদানিজ পাউন্ড', 'en': 'South Sudanese Pound'},
  'STN': {'bn': 'সাও তোমে এবং প্রিন্সিপে ডোবরা', 'en': 'São Tomé and Príncipe Dobra'},
  'SVC': {'bn': 'সালভাডোরান কোলন', 'en': 'Salvadoran Colón'},
  'SYP': {'bn': 'সিরিয়ান পাউন্ড', 'en': 'Syrian Pound'},
  'SZL': {'bn': 'সোয়াজি লিলাঙ্গেনি', 'en': 'Swazi Lilangeni'},
  'THB': {'bn': 'থাই বাত', 'en': 'Thai Baht'},
  'TJS': {'bn': 'তাজিকিস্তানি সোমোনি', 'en': 'Tajikistani Somoni'},
  'TMT': {'bn': 'তুর্কমেনিস্তানি মানাত', 'en': 'Turkmenistani Manat'},
  'TND': {'bn': 'তিউনিসিয়ান দিনার', 'en': 'Tunisian Dinar'},
  'TOP': {'bn': 'টোঙ্গান পা’ঙ্গা', 'en': 'Tongan Paʻanga'},
  'TRY': {'bn': 'তুর্কি লিরা', 'en': 'Turkish Lira'},
  'TTD': {'bn': 'ত্রিনিদাদ ও টোবাগো ডলার', 'en': 'Trinidad and Tobago Dollar'},
  'TVD': {'bn': 'টুভালুয়ান ডলার', 'en': 'Tuvaluan Dollar'},
  'TWD': {'bn': 'নতুন তাইওয়ান ডলার', 'en': 'New Taiwan Dollar'},
  'TZS': {'bn': 'তানজানিয়ান শিলিং', 'en': 'Tanzanian Shilling'},
  'UAH': {'bn': 'ইউক্রেনীয় রিভনিয়া', 'en': 'Ukrainian Hryvnia'},
  'UGX': {'bn': 'উগান্ডান শিলিং', 'en': 'Ugandan Shilling'},
  'USD': {'bn': 'ইউএস ডলার', 'en': 'US Dollar'},
  'UYU': {'bn': 'উরুগুয়ান পেসো', 'en': 'Uruguayan Peso'},
  'UZS': {'bn': 'উজবেকিস্তানি সোম', 'en': 'Uzbekistani Som'},
  'VES': {'bn': 'ভেনিজুয়েলান বলিভার সোবেরানো', 'en': 'Venezuelan Bolívar Soberano'},
  'VND': {'bn': 'ভিয়েতনামী ডং', 'en': 'Vietnamese Đồng'},
  'VUV': {'bn': 'ভানুয়াতু ভাতু', 'en': "Vanuatu Vatu"},
  'WST': {'bn': 'সামোয়ান তা’লা', 'en': 'Samoan Tālā'},
  'XAF': {'bn': 'সিএফএ ফ্রাঁ বিইএসি', 'en': 'CFA Franc BEAC'},
  'XAG': {'bn': 'রূপা (ট্রয় আউন্স)', 'en': 'Silver (Troy Ounce)'},
  'XAU': {'bn': 'স্বর্ণ (ট্রয় আউন্স)', 'en': 'Gold (Troy Ounce)'},
  'XCD': {'bn': 'পূর্ব ক্যারিবিয়ান ডলার', 'en': 'East Caribbean Dollar'},
  'XDR': {'bn': 'বিশেষ ড্রয়িং রাইটস', 'en': 'Special Drawing Rights'},
  'XOF': {'bn': 'সিএফএ ফ্রাঁ বিসিইএও', 'en': 'CFA Franc BCEAO'},
  'XPD': {'bn': 'প্যালাডিয়াম (ট্রয় আউন্স)', 'en': 'Palladium (Troy Ounce)'},
  'XPF': {'bn': 'সিএফপি ফ্রাঁ', 'en': 'CFP Franc'},
  'XPT': {'bn': 'প্লাটিনাম (ট্রয় আউন্স)', 'en': 'Platinum (Troy Ounce)'},
  'YER': {'bn': 'ইয়েমেনি রিয়াল', 'en': 'Yemeni Rial'},
  'ZAR': {'bn': 'দক্ষিণ আফ্রিকান র্যান্ড', 'en': 'South African Rand'},
  'ZMW': {'bn': 'জাম্বিয়ান কোয়াচা', 'en': 'Zambian Kwacha'},
  'ZWL': {'bn': 'জিম্বাবুয়ান ডলার', 'en': 'Zimbabwean Dollar'},
};