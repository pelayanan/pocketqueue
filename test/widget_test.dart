import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_queue/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('welcome screen exposes primary onboarding actions', (
    tester,
  ) async {
    final store = QueueStore();
    await tester.pumpWidget(PocketQueueApp(store: store));
    expect(find.text('Pocket Queue'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('View Demo'), findsOneWidget);
  });

  test(
    'queue numbers, priority ordering, and service transitions work',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = QueueStore();
      await store.load();
      store.prefix = 'A';
      store.numberLength = 3;
      final regular = store.generate();
      final priority = store.generate(type: 'Priority');
      expect(regular, 'A-001');
      expect(priority, 'P-002');
      expect(store.nextUp?.number, 'P-002');

      store.callNext();
      expect(store.serving?.number, 'P-002');
      expect(store.waitingCount, 1);
      store.recall();
      expect(store.serving?.recallCount, 1);
      store.finish();
      expect(store.servedCount, 1);
      expect(store.serving, isNull);
    },
  );

  test('reset moves active queues into history and resets numbering', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = QueueStore();
    await store.load();
    store.generate();
    store.callNext();
    store.resetActive();
    expect(store.serving, isNull);
    expect(store.skippedCount, 1);
    expect(store.nextNumber, 1);
  });
}
