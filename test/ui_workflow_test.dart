import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_queue/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<QueueStore> store({required bool onboarded}) async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final queueStore = QueueStore();
  await queueStore.load();
  queueStore.onboardingComplete = onboarded;
  if (onboarded) queueStore.seedDemo();
  return queueStore;
}

Future<void> settle(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 350));

void main() {
  testWidgets('onboarding surfaces expose all required buttons', (
    tester,
  ) async {
    final queueStore = await store(onboarded: false);
    await tester.pumpWidget(PocketQueueApp(store: queueStore));
    await settle(tester);
    expect(find.text('Pocket Queue'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('View Demo'), findsOneWidget);

    await tester.pumpWidget(MaterialApp(home: SetupPage(store: queueStore)));
    await settle(tester);
    expect(find.text('Set up your counter'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: ConfigurePage(store: queueStore)),
    );
    await settle(tester);
    expect(find.text('Configure your queue'), findsOneWidget);
    expect(find.text('Save Queue'), findsOneWidget);
  });

  testWidgets('queue controls are present and store transitions work', (
    tester,
  ) async {
    final queueStore = await store(onboarded: true);
    await tester.pumpWidget(
      MaterialApp(
        home: QueuePage(store: queueStore, onNavigate: (_) {}),
      ),
    );
    await settle(tester);
    expect(find.text('Add Queue Number'), findsOneWidget);
    expect(find.text('CALL NEXT'), findsOneWidget);
    expect(find.text('Pause Queue'), findsOneWidget);
    expect(find.text('Reset Queue'), findsOneWidget);

    final first = queueStore.nextUp;
    expect(first, isNotNull);
    queueStore.callNext();
    expect(queueStore.serving?.number, first?.number);
    queueStore.recall();
    expect(queueStore.serving?.recallCount, 1);
    queueStore.finish();
    expect(queueStore.servedCount, greaterThan(0));
    queueStore.callNext();
    queueStore.skip();
    expect(queueStore.skippedCount, greaterThan(0));
  });

  testWidgets(
    'display, history, detail, statistics, and settings pages render',
    (tester) async {
      final queueStore = await store(onboarded: true);
      final completed = queueStore.entries.firstWhere(
        (entry) => entry.status == QueueStatus.completed,
      );

      await tester.pumpWidget(
        MaterialApp(home: DisplayPage(store: queueStore)),
      );
      await settle(tester);
      expect(find.text('NOW SERVING'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(home: HistoryPage(store: queueStore)),
      );
      await settle(tester);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('Export CSV'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(home: QueueDetailPage(entry: completed)),
      );
      await settle(tester);
      expect(find.text('QUEUE NUMBER'), findsOneWidget);
      expect(find.text('Waiting time'), findsOneWidget);
      expect(find.text('Service time'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(home: StatisticsPage(store: queueStore)),
      );
      await settle(tester);
      expect(find.text('Daily statistics'), findsOneWidget);
      expect(find.text('CUSTOMERS SERVED'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(home: SettingsPage(store: queueStore)),
      );
      await settle(tester);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('Queue'), findsOneWidget);
      expect(find.text('Display & sound'), findsOneWidget);
    },
  );
}
