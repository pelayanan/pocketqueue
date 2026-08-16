import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const primary = Color(0xFF2563EB);
const ink = Color(0xFF0F172A);
const canvas = Color(0xFFF8FAFC);
const success = Color(0xFF16A34A);
const warning = Color(0xFFF59E0B);
const danger = Color(0xFFDC2626);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = QueueStore();
  await store.load();
  runApp(PocketQueueApp(store: store));
}

enum QueueStatus { waiting, serving, completed, skipped }

class QueueEntry {
  QueueEntry({
    required this.number,
    required this.type,
    required this.createdAt,
    this.status = QueueStatus.waiting,
    this.calledAt,
    this.startedAt,
    this.completedAt,
    this.skippedAt,
    this.lastCalledAt,
    this.recallCount = 0,
  });

  final String number;
  final String type;
  final DateTime createdAt;
  QueueStatus status;
  DateTime? calledAt;
  DateTime? startedAt;
  DateTime? completedAt;
  DateTime? skippedAt;
  DateTime? lastCalledAt;
  int recallCount;

  Duration get waitingDuration =>
      (calledAt ?? DateTime.now()).difference(createdAt);
  Duration? get serviceDuration => startedAt == null
      ? null
      : (completedAt ?? DateTime.now()).difference(startedAt!);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'number': number,
    'type': type,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'calledAt': calledAt?.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'skippedAt': skippedAt?.toIso8601String(),
    'lastCalledAt': lastCalledAt?.toIso8601String(),
    'recallCount': recallCount,
  };

  factory QueueEntry.fromJson(Map<String, dynamic> json) {
    return QueueEntry(
      number: json['number'] as String,
      type: (json['type'] as String?) ?? 'Regular',
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: QueueStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => QueueStatus.waiting,
      ),
      calledAt: _parseDate(json['calledAt']),
      startedAt: _parseDate(json['startedAt']),
      completedAt: _parseDate(json['completedAt']),
      skippedAt: _parseDate(json['skippedAt']),
      lastCalledAt: _parseDate(json['lastCalledAt']),
      recallCount: (json['recallCount'] as int?) ?? 0,
    );
  }

  static DateTime? _parseDate(dynamic value) =>
      value is String ? DateTime.tryParse(value) : null;
}

class QueueStore extends ChangeNotifier {
  SharedPreferences? _preferences;

  bool onboardingComplete = false;
  bool paused = false;
  String businessName = 'Happy Smile Clinic';
  String counterName = 'Registration';
  String operatorName = 'Reception Desk';
  String address = '';
  String phone = '';
  String openingHours = '08:00 – 17:00';
  String prefix = 'A';
  int nextNumber = 1;
  int maxNumber = 999;
  int numberLength = 3;
  String resetMode = 'Every Day';
  bool priorityEnabled = true;
  bool appointmentEnabled = true;
  bool soundEnabled = true;
  bool voiceEnabled = false;
  bool showClock = true;
  bool showDate = true;
  bool showNextQueues = true;
  double volume = .8;

  final List<QueueEntry> entries = <QueueEntry>[];

  Future<void> load() async {
    _preferences = await SharedPreferences.getInstance();
    onboardingComplete = _preferences?.getBool('onboardingComplete') ?? false;
    businessName = _preferences?.getString('businessName') ?? businessName;
    counterName = _preferences?.getString('counterName') ?? counterName;
    operatorName = _preferences?.getString('operatorName') ?? operatorName;
    address = _preferences?.getString('address') ?? address;
    phone = _preferences?.getString('phone') ?? phone;
    openingHours = _preferences?.getString('openingHours') ?? openingHours;
    prefix = _preferences?.getString('prefix') ?? prefix;
    nextNumber = _preferences?.getInt('nextNumber') ?? nextNumber;
    maxNumber = _preferences?.getInt('maxNumber') ?? maxNumber;
    numberLength = _preferences?.getInt('numberLength') ?? numberLength;
    resetMode = _preferences?.getString('resetMode') ?? resetMode;
    paused = _preferences?.getBool('paused') ?? paused;
    priorityEnabled =
        _preferences?.getBool('priorityEnabled') ?? priorityEnabled;
    appointmentEnabled =
        _preferences?.getBool('appointmentEnabled') ?? appointmentEnabled;
    soundEnabled = _preferences?.getBool('soundEnabled') ?? soundEnabled;
    voiceEnabled = _preferences?.getBool('voiceEnabled') ?? voiceEnabled;
    showClock = _preferences?.getBool('showClock') ?? showClock;
    showDate = _preferences?.getBool('showDate') ?? showDate;
    showNextQueues = _preferences?.getBool('showNextQueues') ?? showNextQueues;
    volume = _preferences?.getDouble('volume') ?? volume;
    final raw = _preferences?.getString('entries');
    if (raw != null && raw.isNotEmpty) {
      entries.addAll(
        (jsonDecode(raw) as List<dynamic>).map(
          (item) => QueueEntry.fromJson(item as Map<String, dynamic>),
        ),
      );
    }
  }

  Future<void> _persist() async {
    final prefs = _preferences;
    if (prefs == null) return;
    await prefs.setBool('onboardingComplete', onboardingComplete);
    await prefs.setBool('paused', paused);
    await prefs.setString('businessName', businessName);
    await prefs.setString('counterName', counterName);
    await prefs.setString('operatorName', operatorName);
    await prefs.setString('address', address);
    await prefs.setString('phone', phone);
    await prefs.setString('openingHours', openingHours);
    await prefs.setString('prefix', prefix);
    await prefs.setInt('nextNumber', nextNumber);
    await prefs.setInt('maxNumber', maxNumber);
    await prefs.setInt('numberLength', numberLength);
    await prefs.setString('resetMode', resetMode);
    await prefs.setBool('priorityEnabled', priorityEnabled);
    await prefs.setBool('appointmentEnabled', appointmentEnabled);
    await prefs.setBool('soundEnabled', soundEnabled);
    await prefs.setBool('voiceEnabled', voiceEnabled);
    await prefs.setBool('showClock', showClock);
    await prefs.setBool('showDate', showDate);
    await prefs.setBool('showNextQueues', showNextQueues);
    await prefs.setDouble('volume', volume);
    await prefs.setString(
      'entries',
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  List<QueueEntry> get waiting {
    final result = entries
        .where((entry) => entry.status == QueueStatus.waiting)
        .toList();
    result.sort((a, b) {
      final aPriority = a.type == 'Priority' ? 1 : 0;
      final bPriority = b.type == 'Priority' ? 1 : 0;
      if (aPriority != bPriority) return bPriority.compareTo(aPriority);
      return a.createdAt.compareTo(b.createdAt);
    });
    return result;
  }

  QueueEntry? get serving {
    for (final entry in entries) {
      if (entry.status == QueueStatus.serving) return entry;
    }
    return null;
  }

  QueueEntry? get nextUp => waiting.isEmpty ? null : waiting.first;
  List<QueueEntry> get upcoming => waiting.take(3).toList();
  int get waitingCount => waiting.length;
  int get servedCount =>
      entries.where((e) => e.status == QueueStatus.completed).length;
  int get skippedCount =>
      entries.where((e) => e.status == QueueStatus.skipped).length;

  String _format(int number, String ticketPrefix) =>
      '$ticketPrefix-${number.toString().padLeft(numberLength, '0')}';

  String generate({String type = 'Regular'}) {
    final ticketPrefix = type == 'Priority'
        ? 'P'
        : type == 'Appointment'
        ? 'T'
        : prefix;
    var number = _format(nextNumber, ticketPrefix);
    while (entries.any(
      (entry) =>
          entry.number == number &&
          (entry.status == QueueStatus.waiting ||
              entry.status == QueueStatus.serving),
    )) {
      nextNumber++;
      number = _format(nextNumber, ticketPrefix);
    }
    entries.add(
      QueueEntry(number: number, type: type, createdAt: DateTime.now()),
    );
    nextNumber = nextNumber >= maxNumber ? 1 : nextNumber + 1;
    _persist();
    notifyListeners();
    return number;
  }

  void callNext() {
    if (paused || serving != null || waiting.isEmpty) return;
    final entry = waiting.first;
    entry.status = QueueStatus.serving;
    entry.calledAt = DateTime.now();
    entry.startedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  void recall() {
    final entry = serving;
    if (entry == null) return;
    entry.lastCalledAt = DateTime.now();
    entry.recallCount++;
    _persist();
    notifyListeners();
  }

  void finish() {
    final entry = serving;
    if (entry == null) return;
    entry.status = QueueStatus.completed;
    entry.completedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  void skip() {
    final entry = serving;
    if (entry == null) return;
    entry.status = QueueStatus.skipped;
    entry.skippedAt = DateTime.now();
    _persist();
    notifyListeners();
  }

  void setPaused(bool value) {
    paused = value;
    _persist();
    notifyListeners();
  }

  void resetActive() {
    for (final entry in entries) {
      if (entry.status == QueueStatus.waiting ||
          entry.status == QueueStatus.serving) {
        entry.status = QueueStatus.skipped;
        entry.skippedAt = DateTime.now();
      }
    }
    nextNumber = 1;
    _persist();
    notifyListeners();
  }

  void deleteHistory() {
    entries.removeWhere(
      (entry) =>
          entry.status == QueueStatus.completed ||
          entry.status == QueueStatus.skipped,
    );
    _persist();
    notifyListeners();
  }

  void saveBusiness({
    required String business,
    required String counter,
    required String operator,
    required String newAddress,
    required String newPhone,
    required String hours,
  }) {
    businessName = business.trim().isEmpty ? businessName : business.trim();
    counterName = counter.trim().isEmpty ? counterName : counter.trim();
    operatorName = operator.trim();
    address = newAddress.trim();
    phone = newPhone.trim();
    openingHours = hours.trim();
    _persist();
    notifyListeners();
  }

  void saveQueue({
    required String newPrefix,
    required int start,
    required int maximum,
    required String reset,
  }) {
    prefix = newPrefix.trim().isEmpty ? 'A' : newPrefix.trim().toUpperCase();
    nextNumber = start.clamp(1, maximum);
    maxNumber = maximum < 1 ? 999 : maximum;
    resetMode = reset;
    onboardingComplete = true;
    _persist();
    notifyListeners();
  }

  void updateDisplay({
    bool? clock,
    bool? date,
    bool? next,
    bool? sound,
    bool? voice,
    double? newVolume,
  }) {
    if (clock != null) showClock = clock;
    if (date != null) showDate = date;
    if (next != null) showNextQueues = next;
    if (sound != null) soundEnabled = sound;
    if (voice != null) voiceEnabled = voice;
    if (newVolume != null) volume = newVolume;
    _persist();
    notifyListeners();
  }

  void setQueueFeatures({bool? priority, bool? appointment, String? reset}) {
    if (priority != null) priorityEnabled = priority;
    if (appointment != null) appointmentEnabled = appointment;
    if (reset != null) resetMode = reset;
    _persist();
    notifyListeners();
  }

  void seedDemo() {
    if (entries.isNotEmpty) return;
    onboardingComplete = true;
    for (var i = 1; i <= 5; i++) {
      final entry = QueueEntry(
        number: 'A-${i.toString().padLeft(3, '0')}',
        type: 'Regular',
        createdAt: DateTime.now().subtract(Duration(minutes: 40 - i * 4)),
        status: i < 3 ? QueueStatus.completed : QueueStatus.waiting,
      );
      if (i < 3) {
        entry.calledAt = entry.createdAt.add(const Duration(minutes: 8));
        entry.startedAt = entry.calledAt;
        entry.completedAt = entry.startedAt!.add(const Duration(minutes: 5));
      }
      entries.add(entry);
    }
    nextNumber = 6;
    _persist();
    notifyListeners();
  }

  String csv() {
    final output = StringBuffer(
      'queue_number,status,created_at,called_at,completed_at,waiting_minutes,service_minutes\n',
    );
    for (final entry in entries) {
      output.writeln(
        '${entry.number},${entry.status.name.toUpperCase()},${entry.createdAt.toIso8601String()},${entry.calledAt?.toIso8601String() ?? ''},${entry.completedAt?.toIso8601String() ?? ''},${entry.waitingDuration.inMinutes},${entry.serviceDuration?.inMinutes ?? ''}',
      );
    }
    return output.toString();
  }

  Future<void> resetApplication() async {
    entries.clear();
    onboardingComplete = false;
    nextNumber = 1;
    await _persist();
    notifyListeners();
  }
}

class PocketQueueApp extends StatelessWidget {
  const PocketQueueApp({super.key, required this.store});
  final QueueStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, child) {
        final screen = Uri.base.queryParameters['screen'];
        final initialIndex = screen == 'display'
            ? 1
            : screen == 'history'
            ? 2
            : screen == 'settings'
            ? 3
            : 0;
        Widget home;
        if (!store.onboardingComplete && screen == 'setup') {
          home = SetupPage(store: store);
        } else if (!store.onboardingComplete && screen == 'configure') {
          home = ConfigurePage(store: store);
        } else if (!store.onboardingComplete) {
          home = WelcomePage(store: store);
        } else if (screen == 'statistics') {
          home = StatisticsPage(store: store);
        } else if (screen == 'detail') {
          final completed = store.entries
              .where((entry) => entry.status == QueueStatus.completed)
              .toList();
          home = completed.isEmpty
              ? HistoryPage(store: store)
              : QueueDetailPage(entry: completed.first);
        } else {
          home = MainShell(store: store, initialIndex: initialIndex);
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Pocket Queue',
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: canvas,
            colorScheme: ColorScheme.fromSeed(seedColor: primary),
            fontFamily: 'Arial',
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.blueGrey.shade100),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.blueGrey.shade100),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: primary, width: 2),
              ),
            ),
          ),
          home: home,
        );
      },
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(size * .28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: size * .48,
            height: size * .6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          Text(
            '01',
            style: TextStyle(
              color: primary,
              fontSize: size * .17,
              fontWeight: FontWeight.w900,
            ),
          ),
          Positioned(
            bottom: size * .13,
            child: Row(
              children: List<Widget>.generate(
                3,
                (index) => Container(
                  width: size * .08,
                  height: size * .08,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.store});
  final QueueStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const BrandMark(size: 66),
                  const SizedBox(height: 34),
                  const Text(
                    'Pocket Queue',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Take a number. Know your turn.',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Manage your customer queue quickly and easily.',
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.5,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                  const SizedBox(height: 38),
                  const FeatureRow(
                    icon: Icons.wifi_off_rounded,
                    title: 'Works offline',
                    subtitle: 'Your queue stays on this device.',
                  ),
                  const FeatureRow(
                    icon: Icons.touch_app_rounded,
                    title: 'Simple operations',
                    subtitle: 'Call, finish, skip and recall in one tap.',
                  ),
                  const FeatureRow(
                    icon: Icons.tv_rounded,
                    title: 'Display ready',
                    subtitle: 'Show the current number on any screen.',
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SetupPage(store: store),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: Text('Get Started'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        store.seedDemo();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: Text('View Demo'),
                      ),
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
}

class FeatureRow extends StatelessWidget {
  const FeatureRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.blueGrey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SetupPage extends StatefulWidget {
  const SetupPage({super.key, required this.store});
  final QueueStore store;

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final business = TextEditingController(text: 'Happy Smile Clinic');
  final counter = TextEditingController(text: 'Registration');
  final operator = TextEditingController(text: 'Reception Desk');

  @override
  void dispose() {
    business.dispose();
    counter.dispose();
    operator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingForm(
      step: 'STEP 1 OF 2',
      title: 'Set up your counter',
      description: 'Tell us a little about the service desk. You can change these details later in Settings.',
      fields: <Widget>[
        TextField(
          label: 'Business Name',
          controller: business,
          icon: Icons.storefront_rounded,
        ),
        TextField(
          label: 'Counter Name',
          controller: counter,
          icon: Icons.desk_rounded,
        ),
        TextField(
          label: 'Operator Name',
          controller: operator,
          icon: Icons.person_outline_rounded,
        ),
      ],
      buttonText: 'Continue',
      onPressed: () {
        widget.store.saveBusiness(
          business: business.text,
          counter: counter.text,
          operator: operator.text,
          newAddress: widget.store.address,
          newPhone: widget.store.phone,
          hours: widget.store.openingHours,
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ConfigurePage(store: widget.store)),
        );
      },
    );
  }
}

class ConfigurePage extends StatefulWidget {
  const ConfigurePage({super.key, required this.store});
  final QueueStore store;

  @override
  State<ConfigurePage> createState() => _ConfigurePageState();
}

class _ConfigurePageState extends State<ConfigurePage> {
  final prefix = TextEditingController(text: 'A');
  final start = TextEditingController(text: '1');
  final maximum = TextEditingController(text: '999');
  String reset = 'Every Day';

  @override
  void dispose() {
    prefix.dispose();
    start.dispose();
    maximum.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingForm(
      step: 'STEP 2 OF 2',
      title: 'Configure your queue',
      description: 'Choose how queue numbers should look and when your day should reset.',
      fields: <Widget>[
        TextField(
          label: 'Queue Prefix',
          controller: prefix,
          icon: Icons.confirmation_number_outlined,
          helper: 'Examples: A, REG, PAY',
        ),
        TextField(
          label: 'Starting Number',
          controller: start,
          icon: Icons.looks_one_outlined,
          keyboardType: TextInputType.number,
        ),
        TextField(
          label: 'Maximum Number',
          controller: maximum,
          icon: Icons.format_list_numbered_rounded,
          keyboardType: TextInputType.number,
        ),
      ],
      extra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Auto Reset',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: <String>['Every Day', 'Never', 'Manual Reset']
                .map(
                  (item) => ChoiceChip(
                    label: Text(item),
                    selected: reset == item,
                    onSelected: (_) => setState(() => reset = item),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      buttonText: 'Save Queue',
      onPressed: () {
        widget.store.saveQueue(
          newPrefix: prefix.text,
          start: int.tryParse(start.text) ?? 1,
          maximum: int.tryParse(maximum.text) ?? 999,
          reset: reset,
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MainShell(store: widget.store)),
          (_) => false,
        );
      },
    );
  }
}

class OnboardingForm extends StatelessWidget {
  const OnboardingForm({
    super.key,
    required this.step,
    required this.title,
    required this.description,
    required this.fields,
    required this.buttonText,
    required this.onPressed,
    this.extra,
  });
  final String step;
  final String title;
  final String description;
  final List<Widget> fields;
  final Widget? extra;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    step,
                    style: const TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.blueGrey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ...fields.expand(
                    (field) => <Widget>[field, const SizedBox(height: 16)],
                  ),
                  extra ?? const SizedBox.shrink(),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onPressed,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Text(buttonText),
                      ),
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
}

class TextField extends StatelessWidget {
  const TextField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.helper,
    this.keyboardType,
  });
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? helper;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.store, this.initialIndex = 0});
  final QueueStore store;
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      QueuePage(
        store: widget.store,
        onNavigate: (index) => setState(() => selected = index),
      ),
      DisplayPage(store: widget.store),
      HistoryPage(store: widget.store),
      SettingsPage(store: widget.store),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 860;
    return Scaffold(
      body: Row(
        children: <Widget>[
          if (wide)
            NavigationRail(
              selectedIndex: selected,
              onDestinationSelected: (index) =>
                  setState(() => selected = index),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.only(top: 20, bottom: 26),
                child: BrandMark(),
              ),
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.confirmation_number_outlined),
                  selectedIcon: Icon(Icons.confirmation_number),
                  label: Text('Queue'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.tv_outlined),
                  selectedIcon: Icon(Icons.tv),
                  label: Text('Display'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: Text('History'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
          Expanded(
            child: IndexedStack(index: selected, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (index) =>
                  setState(() => selected = index),
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.confirmation_number_outlined),
                  selectedIcon: Icon(Icons.confirmation_number),
                  label: 'Queue',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tv_outlined),
                  selectedIcon: Icon(Icons.tv),
                  label: 'Display',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
    );
  }
}

class QueuePage extends StatelessWidget {
  const QueuePage({super.key, required this.store, required this.onNavigate});
  final QueueStore store;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return AppPage(
      title: store.businessName,
      subtitle: '${store.counterName} · ${store.operatorName}',
      leading: const BrandMark(size: 44),
      actions: <Widget>[
        IconButton(
          tooltip: 'Settings',
          onPressed: () => onNavigate(3),
          icon: const Icon(Icons.settings_outlined),
        ),
        IconButton(
          tooltip: 'Display mode',
          onPressed: () => onNavigate(1),
          icon: const Icon(Icons.fullscreen_rounded),
        ),
      ],
      child: Column(
        children: <Widget>[
          if (store.paused)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: warning.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(Icons.pause_circle_outline, color: warning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Queue is paused. Resume to call the next customer.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: wide ? 6 : 1,
                child: CurrentCard(store: store),
              ),
              if (wide)
                const SizedBox(width: 18)
              else
                const SizedBox(height: 18),
              Expanded(
                flex: wide ? 5 : 1,
                child: NextCard(store: store),
              ),
            ],
          ),
          const SizedBox(height: 18),
          StatsRow(store: store),
          const SizedBox(height: 24),
          ActionBar(store: store, onNavigate: onNavigate),
        ],
      ),
    );
  }
}

class CurrentCard extends StatelessWidget {
  const CurrentCard({super.key, required this.store});
  final QueueStore store;

  @override
  Widget build(BuildContext context) {
    final current = store.serving;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const StatusPill(text: 'NOW SERVING', color: primary),
            const SizedBox(height: 18),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                current?.number ?? '—',
                style: const TextStyle(
                  fontSize: 66,
                  fontWeight: FontWeight.w900,
                  color: ink,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              current == null
                  ? 'No active customer'
                  : 'Counter 1 · ${store.counterName}',
              style: TextStyle(color: Colors.blueGrey.shade600),
            ),
            const SizedBox(height: 23),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: current == null
                        ? null
                        : () {
                            store.recall();
                            showToast(
                              context,
                              'Queue ${current.number} recalled',
                            );
                          },
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('Recall'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: success),
                    onPressed: current == null
                        ? null
                        : () async {
                            final ok = await confirmDialog(
                              context,
                              'Finish service for ${current.number}?',
                              'This queue will move to completed history.',
                            );
                            if (ok) {
                              store.finish();
                              if (context.mounted) {
                                showToast(context, 'Service finished');
                              }
                            }
                          },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Finish'),
                  ),
                ),
              ],
            ),
            if (current != null)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () async {
                    final ok = await confirmDialog(
                      context,
                      'Skip queue ${current.number}?',
                      'This number will be recorded as skipped.',
                    );
                    if (ok) {
                      store.skip();
                      if (context.mounted) showToast(context, 'Queue skipped');
                    }
                  },
                  icon: const Icon(Icons.skip_next_rounded, color: danger),
                  label: const Text(
                    'Skip this queue',
                    style: TextStyle(color: danger),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class NextCard extends StatelessWidget {
  const NextCard({super.key, required this.store});
  final QueueStore store;

  @override
  Widget build(BuildContext context) {
    final next = store.nextUp;
    return Card(
      color: primary,
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const StatusPill(
              text: 'NEXT CUSTOMER',
              color: Colors.white,
              background: Color(0x332563EB),
            ),
            const SizedBox(height: 18),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                next?.number ?? '—',
                style: const TextStyle(
                  fontSize: 58,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              next == null
                  ? 'Generate a number to begin'
                  : '${store.waitingCount} customer${store.waitingCount == 1 ? '' : 's'} waiting',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: next == null || store.paused
                    ? null
                    : () {
                        store.callNext();
                        showToast(
                          context,
                          'Now serving ${store.serving?.number ?? ''}',
                        );
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                ),
                child: const Text(
                  'CALL NEXT',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsRow extends StatelessWidget {
  const StatsRow({super.key, required this.store});
  final QueueStore store;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: SmallStat(
            label: 'Waiting',
            value: '${store.waitingCount}',
            icon: Icons.groups_outlined,
            color: primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SmallStat(
            label: 'Served',
            value: '${store.servedCount}',
            icon: Icons.check_circle_outline,
            color: success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SmallStat(
            label: 'Skipped',
            value: '${store.skippedCount}',
            icon: Icons.remove_circle_outline,
            color: danger,
          ),
        ),
      ],
    );
  }
}

class SmallStat extends StatelessWidget {
  const SmallStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: <Widget>[
            Icon(icon, color: color),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionBar extends StatelessWidget {
  const ActionBar({super.key, required this.store, required this.onNavigate});
  final QueueStore store;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: () => addQueueSheet(context, store),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Queue Number'),
        ),
        OutlinedButton.icon(
          onPressed: store.serving == null ? null : store.recall,
          icon: const Icon(Icons.campaign_outlined),
          label: const Text('Recall'),
        ),
        OutlinedButton.icon(
          onPressed: () => store.setPaused(!store.paused),
          icon: Icon(
            store.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          ),
          label: Text(store.paused ? 'Resume Queue' : 'Pause Queue'),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            if (await confirmDialog(
              context,
              'Reset today\'s queue?',
              'Active queue numbers will be moved to skipped history.',
            )) {
              store.resetActive();
              if (context.mounted) showToast(context, 'Active queue reset');
            }
          },
          icon: const Icon(Icons.restart_alt_rounded, color: danger),
          label: const Text('Reset Queue', style: TextStyle(color: danger)),
        ),
        TextButton.icon(
          onPressed: () => onNavigate(2),
          icon: const Icon(Icons.history_rounded),
          label: const Text('View history'),
        ),
      ],
    );
  }
}

class DisplayPage extends StatelessWidget {
  const DisplayPage({super.key, required this.store});
  final QueueStore store;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: const Color(0xFF071328),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 34,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const BrandMark(size: 38),
                          const SizedBox(width: 12),
                          Text(
                            store.businessName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 46),
                      const Text(
                        'NOW SERVING',
                        style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        child: Text(
                          store.serving?.number ?? '—',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 150,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                      Text(
                        store.counterName.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 20,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 46),
                      if (store.showNextQueues)
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            children: <Widget>[
                              const Text(
                                'NEXT IN LINE',
                                style: TextStyle(
                                  color: Colors.white60,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: store.upcoming
                                    .map(
                                      (entry) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Text(
                                          entry.number,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (store.showDate)
                            Text(
                              '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          if (store.showDate && store.showClock)
                            const Text(
                              '  ·  ',
                              style: TextStyle(color: Colors.white38),
                            ),
                          if (store.showClock)
                            Text(
                              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                tooltip: 'Exit display mode',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.store});
  final QueueStore store;

  @override
  Widget build(BuildContext context) {
    final history = store.entries
        .where(
          (entry) =>
              entry.status == QueueStatus.completed ||
              entry.status == QueueStatus.skipped,
        )
        .toList()
        .reversed
        .toList();
    Widget content;
    if (history.isEmpty) {
      content = EmptyState(
        icon: Icons.history_rounded,
        title: 'No history yet',
        message: 'Completed and skipped queues will appear here.',
        buttonText: 'Generate a queue',
        onPressed: () => addQueueSheet(context, store),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'TODAY',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: ink,
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in history)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QueueDetailPage(entry: entry),
                  ),
                ),
                leading: CircleAvatar(
                  backgroundColor: entry.status == QueueStatus.completed
                      ? success.withValues(alpha: .12)
                      : danger.withValues(alpha: .12),
                  child: Icon(
                    entry.status == QueueStatus.completed
                        ? Icons.check_rounded
                        : Icons.skip_next_rounded,
                    color: entry.status == QueueStatus.completed
                        ? success
                        : danger,
                  ),
                ),
                title: Text(
                  entry.number,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(
                  '${entry.status.name.capitalize()} · ${formatTime(entry.completedAt ?? entry.skippedAt)}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
        ],
      );
    }
    return AppPage(
      title: 'History',
      subtitle: 'Today\'s completed and skipped queues',
      actions: <Widget>[
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StatisticsPage(store: store)),
          ),
          icon: const Icon(Icons.bar_chart_rounded),
          label: const Text('Statistics'),
        ),
        OutlinedButton.icon(
          onPressed: () => exportCsv(context, store),
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Export CSV'),
        ),
      ],
      child: content,
    );
  }
}

class QueueDetailPage extends StatelessWidget {
  const QueueDetailPage({super.key, required this.entry});
  final QueueEntry entry;

  @override
  Widget build(BuildContext context) {
    final statusColor = entry.status == QueueStatus.completed
        ? success
        : danger;
    return Scaffold(
      appBar: AppBar(title: const Text('Queue details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: <Widget>[
                    const BrandMark(),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'QUEUE NUMBER',
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          entry.number,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        StatusPill(
                          text: entry.status.name.toUpperCase(),
                          color: statusColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: <Widget>[
                  DetailRow(
                    label: 'Created',
                    value: formatDateTime(entry.createdAt),
                  ),
                  DetailRow(
                    label: 'Called',
                    value: formatDateTime(entry.calledAt),
                  ),
                  DetailRow(
                    label: 'Started',
                    value: formatDateTime(entry.startedAt),
                  ),
                  DetailRow(
                    label: 'Completed',
                    value: formatDateTime(entry.completedAt ?? entry.skippedAt),
                  ),
                  DetailRow(
                    label: 'Waiting time',
                    value: formatDuration(entry.waitingDuration),
                  ),
                  DetailRow(
                    label: 'Service time',
                    value: formatDuration(entry.serviceDuration),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key, required this.store});
  final QueueStore store;

  @override
  Widget build(BuildContext context) {
    final completed = store.entries
        .where((entry) => entry.status == QueueStatus.completed)
        .toList();
    final waits = completed
        .map((entry) => entry.waitingDuration.inMinutes)
        .toList();
    final services = completed
        .map((entry) => entry.serviceDuration?.inMinutes ?? 0)
        .toList();
    final avgWait = waits.isEmpty
        ? 0
        : waits.reduce((a, b) => a + b) ~/ waits.length;
    final avgService = services.isEmpty
        ? 0
        : services.reduce((a, b) => a + b) ~/ services.length;
    return AppPage(
      title: 'Daily statistics',
      subtitle: 'A quick operational summary for today',
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SmallStat(
                  label: 'Total generated',
                  value: '${store.entries.length}',
                  icon: Icons.confirmation_number_outlined,
                  color: primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SmallStat(
                  label: 'Total served',
                  value: '${store.servedCount}',
                  icon: Icons.check_circle_outline,
                  color: success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: SmallStat(
                  label: 'Total skipped',
                  value: '${store.skippedCount}',
                  icon: Icons.remove_circle_outline,
                  color: danger,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SmallStat(
                  label: 'Current waiting',
                  value: '${store.waitingCount}',
                  icon: Icons.groups_outlined,
                  color: warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'SERVICE OVERVIEW',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.2,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  MetricRow(
                    label: 'Average waiting time',
                    value: '$avgWait min',
                  ),
                  MetricRow(
                    label: 'Average service time',
                    value: '$avgService min',
                  ),
                  MetricRow(
                    label: 'Longest waiting time',
                    value:
                        '${waits.isEmpty ? 0 : waits.reduce((a, b) => a > b ? a : b)} min',
                  ),
                  const MetricRow(
                    label: 'Busiest hour',
                    value: '10:00 – 11:00',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'CUSTOMERS SERVED',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.2,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const BarRow(label: '08:00', value: .35, count: 3),
                  const BarRow(label: '09:00', value: .55, count: 5),
                  const BarRow(label: '10:00', value: .9, count: 8),
                  const BarRow(label: '11:00', value: .65, count: 6),
                  const BarRow(label: '12:00', value: .3, count: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.store});
  final QueueStore store;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController business;
  late final TextEditingController counter;
  late final TextEditingController operator;
  late final TextEditingController address;
  late final TextEditingController phone;
  late final TextEditingController hours;
  late final TextEditingController prefix;

  @override
  void initState() {
    super.initState();
    final store = widget.store;
    business = TextEditingController(text: store.businessName);
    counter = TextEditingController(text: store.counterName);
    operator = TextEditingController(text: store.operatorName);
    address = TextEditingController(text: store.address);
    phone = TextEditingController(text: store.phone);
    hours = TextEditingController(text: store.openingHours);
    prefix = TextEditingController(text: store.prefix);
  }

  @override
  void dispose() {
    business.dispose();
    counter.dispose();
    operator.dispose();
    address.dispose();
    phone.dispose();
    hours.dispose();
    prefix.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return AppPage(
      title: 'Settings',
      subtitle: 'Tune your queue, display, and data preferences',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SettingSection(
            title: 'Business',
            icon: Icons.storefront_outlined,
            children: <Widget>[
              TextField(
                label: 'Business Name',
                controller: business,
                icon: Icons.storefront_outlined,
              ),
              const SizedBox(height: 12),
              TextField(
                label: 'Counter Name',
                controller: counter,
                icon: Icons.desk_outlined,
              ),
              const SizedBox(height: 12),
              TextField(
                label: 'Operator Name',
                controller: operator,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              TextField(
                label: 'Address',
                controller: address,
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),
              TextField(
                label: 'Phone',
                controller: phone,
                icon: Icons.phone_outlined,
              ),
              const SizedBox(height: 12),
              TextField(
                label: 'Opening Hours',
                controller: hours,
                icon: Icons.schedule_outlined,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  store.saveBusiness(
                    business: business.text,
                    counter: counter.text,
                    operator: operator.text,
                    newAddress: address.text,
                    newPhone: phone.text,
                    hours: hours.text,
                  );
                  showToast(context, 'Business settings saved');
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save business details'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingSection(
            title: 'Queue',
            icon: Icons.confirmation_number_outlined,
            children: <Widget>[
              TextField(
                label: 'Prefix',
                controller: prefix,
                icon: Icons.short_text_rounded,
              ),
              const SizedBox(height: 12),
              SettingSwitch(
                title: 'Priority queue',
                subtitle: 'Prioritize P- numbers before regular queues.',
                value: store.priorityEnabled,
                onChanged: (value) => store.setQueueFeatures(priority: value),
              ),
              SettingSwitch(
                title: 'Appointment queue',
                subtitle: 'Allow appointment ticket types.',
                value: store.appointmentEnabled,
                onChanged: (value) =>
                    store.setQueueFeatures(appointment: value),
              ),
              SettingRow(
                label: 'Reset schedule',
                trailing: DropdownButton<String>(
                  value: store.resetMode,
                  underline: const SizedBox(),
                  items: <String>['Every Day', 'Never', 'Manual Reset']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) store.setQueueFeatures(reset: value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingSection(
            title: 'Display & sound',
            icon: Icons.tv_outlined,
            children: <Widget>[
              SettingSwitch(
                title: 'Show clock',
                subtitle: 'Show current time in display mode.',
                value: store.showClock,
                onChanged: (value) => store.updateDisplay(clock: value),
              ),
              SettingSwitch(
                title: 'Show date',
                subtitle: 'Show current date in display mode.',
                value: store.showDate,
                onChanged: (value) => store.updateDisplay(date: value),
              ),
              SettingSwitch(
                title: 'Show next queues',
                subtitle: 'Show the next three numbers.',
                value: store.showNextQueues,
                onChanged: (value) => store.updateDisplay(next: value),
              ),
              SettingSwitch(
                title: 'Enable sound',
                subtitle: 'Prepare announcements for a connected speaker.',
                value: store.soundEnabled,
                onChanged: (value) => store.updateDisplay(sound: value),
              ),
              SettingSwitch(
                title: 'Enable voice',
                subtitle: 'Use optional queue announcement voice.',
                value: store.voiceEnabled,
                onChanged: (value) => store.updateDisplay(voice: value),
              ),
              Text(
                'Volume',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.blueGrey.shade700,
                ),
              ),
              Slider(
                value: store.volume,
                onChanged: (value) => store.updateDisplay(newVolume: value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingSection(
            title: 'Data & privacy',
            icon: Icons.shield_outlined,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () => exportCsv(context, store),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Export CSV'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  if (await confirmDialog(
                    context,
                    'Delete history?',
                    'Completed and skipped queues will be removed.',
                  )) {
                    store.deleteHistory();
                    if (context.mounted) showToast(context, 'History deleted');
                  }
                },
                icon: const Icon(Icons.delete_outline, color: danger),
                label: const Text(
                  'Delete history',
                  style: TextStyle(color: danger),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  if (await confirmDialog(
                    context,
                    'Reset application?',
                    'This clears local settings and queue data and returns to setup.',
                  )) {
                    await store.resetApplication();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => WelcomePage(store: store),
                        ),
                        (_) => false,
                      );
                    }
                  }
                },
                icon: const Icon(Icons.warning_amber_rounded, color: danger),
                label: const Text(
                  'Reset application',
                  style: TextStyle(color: danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const <Widget>[],
    this.leading,
  });
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 44 : 20, 30, wide ? 44 : 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (leading != null) ...<Widget>[
                        leading!,
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: TextStyle(color: Colors.blueGrey.shade600),
                            ),
                          ],
                        ),
                      ),
                      if (actions.isNotEmpty)
                        Wrap(spacing: 8, runSpacing: 8, children: actions),
                    ],
                  ),
                  const SizedBox(height: 26),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });
  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(38),
        child: Center(
          child: Column(
            children: <Widget>[
              Icon(icon, size: 52, color: primary),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey.shade600),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add_rounded),
                label: Text(buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.text,
    required this.color,
    this.background,
  });
  final String text;
  final Color color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          letterSpacing: .8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.blueGrey.shade600)),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, color: ink),
        ),
      ],
    ),
  );
}

class MetricRow extends StatelessWidget {
  const MetricRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.blueGrey.shade700)),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, color: ink),
        ),
      ],
    ),
  );
}

class BarRow extends StatelessWidget {
  const BarRow({
    super.key,
    required this.label,
    required this.value,
    required this.count,
  });
  final String label;
  final double value;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      children: <Widget>[
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 13,
              color: primary,
              backgroundColor: primary.withValues(alpha: .1),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class SettingSection extends StatelessWidget {
  const SettingSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    ),
  );
}

class SettingSwitch extends StatelessWidget {
  const SettingSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
    value: value,
    onChanged: onChanged,
  );
}

class SettingRow extends StatelessWidget {
  const SettingRow({super.key, required this.label, required this.trailing});
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      trailing,
    ],
  );
}

Future<void> addQueueSheet(BuildContext context, QueueStore store) async {
  var type = 'Regular';
  var quantity = 1;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            10,
            22,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Add queue number',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Generate one or more tickets for the waiting line.',
                style: TextStyle(color: Colors.blueGrey.shade600),
              ),
              const SizedBox(height: 22),
              const Text(
                'Queue type',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children:
                    <String>[
                          'Regular',
                          if (store.priorityEnabled) 'Priority',
                          if (store.appointmentEnabled) 'Appointment',
                        ]
                        .map(
                          (item) => ChoiceChip(
                            label: Text(item),
                            selected: type == item,
                            onSelected: (_) => setState(() => type = item),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Quantity',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: quantity > 1
                        ? () => setState(() => quantity--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$quantity',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  IconButton(
                    onPressed: quantity < 10
                        ? () => setState(() => quantity++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final numbers = List<String>.generate(
                      quantity,
                      (_) => store.generate(type: type),
                    );
                    Navigator.pop(sheetContext);
                    showToast(
                      context,
                      '${numbers.join(', ')} created successfully',
                    );
                  },
                  icon: const Icon(Icons.confirmation_number_outlined),
                  label: const Text('Generate Number'),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<void> exportCsv(BuildContext context, QueueStore store) async {
  await SharePlus.instance.share(
    ShareParams(text: store.csv(), subject: 'Pocket Queue CSV export'),
  );
  if (context.mounted) showToast(context, 'CSV export ready to share');
}

Future<bool> confirmDialog(
  BuildContext context,
  String title,
  String message,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;
}

void showToast(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

String formatTime(DateTime? date) => date == null
    ? '—'
    : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
String formatDateTime(DateTime? date) => date == null
    ? '—'
    : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${formatTime(date)}';
String formatDuration(Duration? duration) {
  if (duration == null) return '—';
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60);
  return minutes > 0 ? '$minutes min' : '$seconds sec';
}

extension Capitalize on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
