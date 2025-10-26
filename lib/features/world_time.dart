/*
 * File: lib/features/world_time.dart
 * Location: /c:/Users/Tamal/Documents/smart_numerix_v2/lib/features/world_time.dart
 * Description: World clock with multiple timezones, analog and digital displays
 */

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorldClock {
  String location;
  final String timezone;
  int? gmtOffset;
  bool isLoading;
  String? error;

  WorldClock({
    required this.location,
    required this.timezone,
    this.gmtOffset,
    this.isLoading = false,
    this.error,
  });

  DateTime getCurrentTime(DateTime utcNow) {
    if (gmtOffset == null) {
      return utcNow;
    }
    return utcNow.add(Duration(seconds: gmtOffset!));
  }

  Map<String, dynamic> toJson() => {
    'location': location,
    'timezone': timezone,
    if (gmtOffset != null) 'gmtOffset': gmtOffset,
  };

  factory WorldClock.fromJson(Map<String, dynamic> json) {
    return WorldClock(
      location: json['location'] as String,
      timezone: json['timezone'] as String,
      gmtOffset: json['gmtOffset'] as int?,
      isLoading: false,
    );
  }
}

class WorldClockDesign extends StatefulWidget {
  const WorldClockDesign({super.key});

  @override
  State<WorldClockDesign> createState() => _WorldClockDesignState();
}

class _WorldClockDesignState extends State<WorldClockDesign> {
  final StreamController<DateTime> _timeStreamController = StreamController<DateTime>.broadcast();
  late final Stream<DateTime> _timeStream;
  Timer? _timer;

  List<WorldClock> _savedClocks = [];
  List<WorldClock> _filteredClocks = [];
  String _featuredTimezone = 'Asia/Dhaka';
  String _featuredLocation = 'Dhaka';
  final TextEditingController _listSearchController = TextEditingController();
  String _searchQuery = '';
  List<String> _allTimezones = [];
  bool _isFetchingTimezones = true;
  bool _isInitializing = true;

  final String _timeZoneDbApiKey = 'VDK6I9PIZJQJ';
  final String _timeZoneDbBaseUrl = 'https://api.timezonedb.com/v2.1';

  @override
  void initState() {
    super.initState();
    _timeStream = _timeStreamController.stream;
    _listSearchController.addListener(_updateFilteredClocks);
    _initializeApp();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeStreamController.close();
    _listSearchController.removeListener(_updateFilteredClocks);
    _listSearchController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (!_timeStreamController.isClosed) {
      _timeStreamController.add(DateTime.now().toUtc());
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_timeStreamController.isClosed) {
        _timeStreamController.add(DateTime.now().toUtc());
      }
    });
  }

  Future<void> _initializeApp() async {
    await _fetchAndStructureTimezones();
    await _loadSavedClocks();
    _startTimer();
    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  void _updateFilteredClocks() {
    _searchQuery = _listSearchController.text;
    setState(() {
      _filteredClocks = _savedClocks.where((clock) {
        final locationLower = clock.location?.toLowerCase() ?? '';
        final timezoneLower = clock.timezone.toLowerCase();
        final queryLower = _searchQuery.toLowerCase();
        return locationLower.contains(queryLower) || timezoneLower.contains(queryLower);
      }).toList();
    });
  }

  Future<void> _loadSavedClocks() async {
    final prefs = await SharedPreferences.getInstance();
    final savedClocksJson = prefs.getStringList('saved_clocks') ?? [];

    List<WorldClock> loadedClocks = [];
    if (savedClocksJson.isEmpty) {
      loadedClocks = await _getDefaultClocks();
      if (mounted && loadedClocks.isNotEmpty) {
        _setFeaturedClock(loadedClocks.first);
      }
    } else {
      loadedClocks = savedClocksJson.map((jsonStr) {
        try {
          return WorldClock.fromJson(jsonDecode(jsonStr));
        } catch (e) {
          print("Error decoding clock: $jsonStr, Error: $e");
          return WorldClock(location: 'Error', timezone: 'Error', error: 'Load Error');
        }
      }).where((clock) => clock.timezone != 'Error').toList();

      if (mounted && loadedClocks.isNotEmpty) {
        _setFeaturedClock(loadedClocks.first);
      }
    }

    if (mounted) {
      setState(() {
        _savedClocks = loadedClocks;
        _updateFilteredClocks();
      });
    }
    if (savedClocksJson.isEmpty) {
      await _saveClocksToPrefs();
    }
  }

  Future<List<WorldClock>> _getDefaultClocks() async {
    final defaultTimezones = [
      {'timezone': 'Asia/Dhaka', 'location': 'Dhaka'},
      {'timezone': 'Europe/London', 'location': 'London'},
      {'timezone': 'America/New_York', 'location': 'New York'},
      {'timezone': 'Asia/Tokyo', 'location': 'Tokyo'},
    ];

    List<WorldClock> defaultClocks = [];
    for (var tzData in defaultTimezones) {
      final clock = WorldClock(
          location: tzData['location']!,
          timezone: tzData['timezone']!,
          isLoading: true
      );
      defaultClocks.add(clock);
      _fetchGmtOffset(tzData['timezone']!).then((offset) {
        if (mounted) {
          setState(() {
            final index = _savedClocks.indexWhere((c) => c.timezone == tzData['timezone']);
            if (index != -1) {
              _savedClocks[index].gmtOffset = offset;
              _savedClocks[index].isLoading = false;
              _savedClocks[index].error = offset == null ? "Failed to load offset" : null;
              _updateFilteredClocks();
            }
          });
          _saveClocksToPrefs();
        }
      });
    }
    return defaultClocks;
  }

  Future<void> _saveClocksToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> clocksJsonList = _savedClocks
        .where((c) => !c.isLoading && c.error == null && c.gmtOffset != null)
        .map((clock) => jsonEncode(clock.toJson()))
        .toList();
    await prefs.setStringList('saved_clocks', clocksJsonList);
  }

  Future<int?> _fetchGmtOffset(String timezone) async {
    final uri = Uri.parse('$_timeZoneDbBaseUrl/get-time-zone?key=$_timeZoneDbApiKey&format=json&by=zone&zone=$timezone');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['gmtOffset'] != null) {
          return data['gmtOffset'] as int;
        } else {
          print('TimeZoneDB API Error for $timezone: ${data['message']}');
          return null;
        }
      } else {
        print('HTTP Error fetching offset for $timezone: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Network error fetching offset for $timezone: $e');
      return null;
    }
  }

  void _addClock(String timezone) {
    if (_savedClocks.any((c) => c.timezone == timezone && !c.isLoading)) {
      _showSnackbar("Clock for this city already exists.", isError: true);
      return;
    }

    final locationName = timezone.split('/').last.replaceAll('_', ' ');

    final newClock = WorldClock(
      location: locationName,
      timezone: timezone,
      isLoading: true,
    );

    if (mounted) {
      setState(() {
        _savedClocks.add(newClock);
        _updateFilteredClocks();
      });
    }

    _fetchGmtOffset(timezone).then((offset) {
      if (mounted) {
        final index = _savedClocks.indexWhere((c) => c.timezone == timezone);
        if (index != -1) {
          setState(() {
            _savedClocks[index].isLoading = false;
            if (offset != null) {
              _savedClocks[index].gmtOffset = offset;
              _savedClocks[index].error = null;
              _saveClocksToPrefs();
              _showSnackbar("Added clock for $locationName");
            } else {
              _savedClocks[index].error = 'Failed to load details';
              _showSnackbar("Failed to add clock for $locationName", isError: true);
            }
            _updateFilteredClocks();
          });
        }
      }
    });
  }

  void _removeClock(String timezone) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _savedClocks.removeWhere((clock) => clock.timezone == timezone);
      if (timezone == _featuredTimezone) {
        if (_savedClocks.isNotEmpty) {
          _setFeaturedClock(_savedClocks.first);
        } else {
          _featuredTimezone = 'Asia/Dhaka';
          _featuredLocation = 'Dhaka';
        }
      }
      _updateFilteredClocks();
    });
    _saveClocksToPrefs();
  }

  void _setFeaturedClock(WorldClock clock) {
    if (clock.isLoading || clock.error != null || clock.gmtOffset == null) {
      _showSnackbar("Cannot feature clock until details are loaded.", isError: true);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _featuredTimezone = clock.timezone;
      _featuredLocation = clock.location;
    });
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent.withOpacity(0.9) : Colors.green.withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _fetchAndStructureTimezones() async {
    if (!mounted) return;
    setState(() => _isFetchingTimezones = true);

    final uri = Uri.parse('$_timeZoneDbBaseUrl/list-time-zone?key=$_timeZoneDbApiKey&format=json');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['zones'] != null) {
          final List zones = data['zones'];
          if (mounted) {
            setState(() {
              _allTimezones = zones.map((zone) => zone['zoneName'] as String).toList()..sort();
              _isFetchingTimezones = false;
            });
          }
        } else {
          throw Exception('API Error: ${data['message']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching timezone list: $e');
      if (mounted) {
        setState(() => _isFetchingTimezones = false);
        _showSnackbar('Could not load timezone list. Please check internet.', isError: true);
      }
    }
  }

  void _showAddTimezoneDialog() {
    if (_isFetchingTimezones) {
      _showSnackbar('Still loading timezone list...', isError: false);
      return;
    }
    if (_allTimezones.isEmpty) {
      _showSnackbar('Timezone list is unavailable. Cannot add clocks.', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => TimezoneSelectionDialog(
        isFetching: _isFetchingTimezones,
        allTimezones: _allTimezones,
        onTimezoneSelected: (timezone) {
          if (timezone.isNotEmpty) {
            _addClock(timezone);
          }
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Color(0xFF1a233b),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final featuredClock = _savedClocks.firstWhere(
            (c) => c.timezone == _featuredTimezone,
        orElse: () => WorldClock(
            location: _featuredLocation,
            timezone: _featuredTimezone,
            isLoading: true
        )
    );

    if (featuredClock.gmtOffset == null && !featuredClock.isLoading && featuredClock.error == null) {
      _fetchGmtOffset(featuredClock.timezone).then((offset){
        if (mounted && offset != null) {
          setState(() {
            final index = _savedClocks.indexWhere((c) => c.timezone == featuredClock.timezone);
            if (index != -1) _savedClocks[index].gmtOffset = offset;
          });
        }
      });
    }

    bool isDayTime = true;
    if (featuredClock.gmtOffset != null) {
      final hour = DateTime.now().toUtc().add(Duration(seconds: featuredClock.gmtOffset!)).hour;
      isDayTime = hour >= 6 && hour < 18;
    }
    final String bgImagePath = isDayTime ? 'assets/images/day_sky.jpg' : 'assets/images/night_sky.jpg';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('World Clock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Container(
        key: ValueKey<String>(bgImagePath + featuredClock.timezone),
        decoration: BoxDecoration(
          color: const Color(0xFF1a233b),
          image: DecorationImage(
            image: AssetImage(bgImagePath),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(isDayTime ? 0.30 : 0.60),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              StreamBuilder<DateTime>(
                stream: _timeStream,
                initialData: DateTime.now().toUtc(),
                builder: (context, snapshot) {
                  final utcNow = snapshot.data ?? DateTime.now().toUtc();
                  return _buildFeaturedClock(featuredClock, utcNow);
                },
              ),
              const Divider(color: Colors.white24, height: 32, indent: 20, endIndent: 20),
              _buildSearchAndAddControls(),
              Expanded(
                child: _savedClocks.isEmpty
                    ? const Center(
                  child: Text(
                    'Press "Add City" to start.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
                    : _filteredClocks.isEmpty && _searchQuery.isNotEmpty
                    ? Center(
                  child: Text(
                    'No clocks found for "$_searchQuery".',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredClocks.length,
                  itemBuilder: (context, index) {
                    final currentlyFeatured = _savedClocks.firstWhere(
                            (c) => c.timezone == _featuredTimezone,
                        orElse: () => featuredClock
                    );
                    return _buildClockCard(_filteredClocks[index], currentlyFeatured);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedClock(WorldClock clock, DateTime utcNow) {
    if (clock.isLoading) {
      return const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator(color: Colors.white))
      );
    }
    if (clock.error != null || clock.gmtOffset == null) {
      return _GlassmorphicCard(
        child: SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                const SizedBox(height: 10),
                Text(clock.location ?? clock.timezone, style: const TextStyle(color: Colors.white, fontSize: 24)),
                const SizedBox(height: 5),
                Text(clock.error ?? 'Offset unavailable', style: const TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
        ),
      );
    }

    final currentTime = clock.getCurrentTime(utcNow);
    return _GlassmorphicCard(
      child: Column(
        children: [
          Text(clock.location, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(DateFormat('E, d MMM yyyy').format(currentTime), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
          const SizedBox(height: 16),
          SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(painter: AnalogClockPainter(currentTime)),
          ),
          const SizedBox(height: 16),
          Text(DateFormat('h:mm:ss a').format(currentTime), style: const TextStyle(color: Colors.white, fontSize: 48, fontFamily: 'monospace', fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSearchAndAddControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _GlassmorphicCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _listSearchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search saved clocks...',
                  hintStyle: const TextStyle(color: Color(0x80FFFFFF)),
                  icon: const Icon(Icons.search, color: Colors.white70, size: 20),
                  border: InputBorder.none,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                    onPressed: () {
                      _listSearchController.clear();
                    },
                  )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _showAddTimezoneDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add City'),
            style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0x26FFFFFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                side: const BorderSide(color: Color(0x4DFFFFFF))),
          ),
        ],
      ),
    );
  }

  Widget _buildClockCard(WorldClock clock, WorldClock featuredClock) {
    final bool isFeatured = clock.timezone == featuredClock.timezone;

    return StreamBuilder<DateTime>(
        stream: _timeStream,
        initialData: DateTime.now().toUtc(),
        builder: (context, snapshot) {
          final utcNow = snapshot.data!;

          if (clock.isLoading) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: _GlassmorphicCard(
                child: Row(
                  children: [
                    const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
                    const SizedBox(width: 16),
                    Expanded(child: Text(clock.location ?? clock.timezone, style: const TextStyle(color: Colors.white70, fontSize: 18))),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                      onPressed: () => _removeClock(clock.timezone),
                    ),
                  ],
                ),
              ),
            );
          }
          if (clock.error != null || clock.gmtOffset == null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: _GlassmorphicCard(
                borderColor: Colors.redAccent.withOpacity(0.5),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clock.location ?? clock.timezone, style: const TextStyle(color: Colors.white, fontSize: 18)),
                          Text(clock.error ?? 'Offset unavailable', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                      onPressed: () => _removeClock(clock.timezone),
                    ),
                  ],
                ),
              ),
            );
          }

          final currentTime = clock.getCurrentTime(utcNow);
          final hour = currentTime.hour;
          final isDayTime = hour >= 6 && hour < 18;

          String diffText = '';
          if (featuredClock.gmtOffset != null) {
            final differenceInSeconds = clock.gmtOffset! - featuredClock.gmtOffset!;
            final differenceInHours = (differenceInSeconds / 3600);

            if (differenceInHours != 0) {
              final String hoursFormatted = differenceInHours == differenceInHours.truncateToDouble()
                  ? differenceInHours.toInt().toString()
                  : differenceInHours.toStringAsFixed(1);
              diffText = '${differenceInHours > 0 ? '+' : ''}$hoursFormatted HRS';
            } else {
              diffText = 'Same time';
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: InkWell(
              onTap: () => _setFeaturedClock(clock),
              borderRadius: BorderRadius.circular(20),
              child: _GlassmorphicCard(
                borderColor: isFeatured ? Colors.cyanAccent.withOpacity(0.7) : const Color(0x33FFFFFF),
                child: Row(
                  children: [
                    Icon(isDayTime ? Icons.wb_sunny_rounded : Icons.nightlight_round, color: isDayTime ? Colors.yellow[600] : Colors.blue[200]),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clock.location, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          if (diffText.isNotEmpty) Text(diffText, style: TextStyle(color: Colors.cyanAccent.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(child: Text(DateFormat('h:mm a').format(currentTime), style: const TextStyle(color: Colors.white, fontSize: 22, fontFamily: 'monospace', fontWeight: FontWeight.w500))),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                      onPressed: () => _removeClock(clock.timezone),
                      tooltip: 'Remove Clock',
                    ),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }
}

class TimezoneSelectionDialog extends StatefulWidget {
  final bool isFetching;
  final List<String> allTimezones;
  final Function(String) onTimezoneSelected;

  const TimezoneSelectionDialog({
    super.key,
    required this.isFetching,
    required this.allTimezones,
    required this.onTimezoneSelected,
  });

  @override
  _TimezoneSelectionDialogState createState() => _TimezoneSelectionDialogState();
}

class _TimezoneSelectionDialogState extends State<TimezoneSelectionDialog> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredTimezones = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _updateFilteredList(_searchController.text);
    });
  }

  void _updateFilteredList(String query) {
    if (!mounted) return;
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredTimezones = [];
      } else {
        _filteredTimezones = widget.allTimezones.where((tz) {
          final String displayName = tz.split('/').last.replaceAll('_', ' ');
          return displayName.toLowerCase().contains(query.toLowerCase()) ||
              tz.split('/').first.toLowerCase().contains(query.toLowerCase()) ||
              tz.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1a233b).withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0x4DFFFFFF)),
      ),
      title: const Text('Search for a City', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'e.g., London, Tokyo, New York...',
                hintStyle: TextStyle(color: Color(0x80FFFFFF)),
                prefixIcon: Icon(Icons.search, color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0x4DFFFFFF)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.cyanAccent),
                ),
              ),
            ),
            const SizedBox(height: 16),
            widget.isFetching
                ? const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.white)))
                : Expanded(
              child: _searchQuery.isEmpty
                  ? const Center(
                child: Text(
                  'Start typing a city name to search.',
                  style: TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              )
                  : _filteredTimezones.isEmpty
                  ? const Center(
                child: Text(
                  'No cities found.',
                  style: TextStyle(color: Colors.white54),
                ),
              )
                  : ListView.builder(
                itemCount: _filteredTimezones.length,
                itemBuilder: (context, index) {
                  final fullTimezone = _filteredTimezones[index];
                  final parts = fullTimezone.split('/');
                  String displayCity = parts.last.replaceAll('_', ' ');
                  String displayRegion = parts.length > 1 ? parts.first.replaceAll('_', ' ') : '';
                  if (parts.length > 2) {
                    displayRegion = parts.sublist(0, parts.length -1).join('/').replaceAll('_', ' ');
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    title: Text(displayCity, style: const TextStyle(color: Colors.white)),
                    subtitle: displayRegion.isNotEmpty
                        ? Text(displayRegion, style: const TextStyle(color: Color(0x99FFFFFF)))
                        : null,
                    onTap: () => widget.onTimezoneSelected(fullTimezone),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel', style: TextStyle(color: Colors.white)))],
    );
  }
}

class AnalogClockPainter extends CustomPainter {
  final DateTime dateTime;
  AnalogClockPainter(this.dateTime);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final center = Offset(centerX, centerY);
    final radius = min(centerX, centerY);

    final fillBrush = Paint()..color = Colors.transparent;
    final outlineBrush = Paint()..color = const Color(0x99FFFFFF)..style = PaintingStyle.stroke..strokeWidth = 3;
    final centerDotBrush = Paint()..color = Colors.white;
    final centerDotInnerBrush = Paint()..color = const Color(0xFF2d2f41);

    final secHandBrush = Paint()..color = Colors.redAccent..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 2;
    final minHandBrush = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 4;
    final hourHandBrush = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeWidth = 6;

    canvas.drawCircle(center, radius - 2, fillBrush);
    canvas.drawCircle(center, radius - 2, outlineBrush);

    final textPainter = TextPainter(textAlign: TextAlign.center, textDirection: ui.TextDirection.ltr);
    final tickPaint = Paint()..color = const Color(0xCCFFFFFF);

    for (int i = 0; i < 60; i++) {
      final angle = (i * 6 - 90) * (pi / 180);
      final isHourMark = i % 5 == 0;
      final tickLength = isHourMark ? 12 : 5;
      final tickWidth = isHourMark ? 2.5 : 1.5;
      tickPaint.strokeWidth = tickWidth;

      final tickStart = radius - tickLength - 4;
      final tickEnd = radius - 4;

      final p1 = Offset(centerX + tickStart * cos(angle), centerY + tickStart * sin(angle));
      final p2 = Offset(centerX + tickEnd * cos(angle), centerY + tickEnd * sin(angle));
      canvas.drawLine(p1, p2, tickPaint);

      if (i % 15 == 0) {
        final hourNum = i == 0 ? 12 : i ~/ 5;
        final numRadius = radius * 0.82;
        final textPosition = Offset(centerX + numRadius * cos(angle), centerY + numRadius * sin(angle));

        textPainter.text = const TextSpan(
          text: '12', // This will be overridden below
          style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Color(0x80000000), blurRadius: 2, offset: Offset(1,1))]
          ),
        );

        // Set actual text and layout
        textPainter.text = TextSpan(
          text: '$hourNum',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Color(0x80000000), blurRadius: 2, offset: Offset(1,1))]
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, textPosition - Offset(textPainter.width / 2, textPainter.height / 2));
      }
    }

    final hourAngle = (dateTime.hour % 12 + dateTime.minute / 60) * 30 - 90;
    final minAngle = (dateTime.minute + dateTime.second / 60) * 6 - 90;
    final secAngle = dateTime.second * 6 - 90;

    final hourRad = hourAngle * (pi / 180);
    final minRad = minAngle * (pi / 180);
    final secRad = secAngle * (pi / 180);

    final hourHandLength = radius * 0.45;
    final minHandLength = radius * 0.65;
    final secHandLength = radius * 0.75;

    final hourHandEnd = Offset(centerX + hourHandLength * cos(hourRad), centerY + hourHandLength * sin(hourRad));
    final minHandEnd = Offset(centerX + minHandLength * cos(minRad), centerY + minHandLength * sin(minRad));
    final secHandEnd = Offset(centerX + secHandLength * cos(secRad), centerY + secHandLength * sin(secRad));

    canvas.drawLine(center, hourHandEnd, hourHandBrush);
    canvas.drawLine(center, minHandEnd, minHandBrush);
    canvas.drawLine(center, secHandEnd, secHandBrush);

    canvas.drawCircle(center, 8, centerDotBrush);
    canvas.drawCircle(center, 5, centerDotInnerBrush);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is! AnalogClockPainter || oldDelegate.dateTime != dateTime;
}

class _GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final EdgeInsets? padding;
  const _GlassmorphicCard({required this.child, this.borderColor, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x26FFFFFF), // Colors.white.withOpacity(0.15)
                Color(0x0DFFFFFF), // Colors.white.withOpacity(0.05)
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor ?? const Color(0x33FFFFFF)),
          ),
          child: child,
        ),
      ),
    );
  }
}