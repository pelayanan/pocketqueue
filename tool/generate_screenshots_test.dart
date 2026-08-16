import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_queue/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> capturePage(WidgetTester tester, Widget page, String name) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey<String>('capture-root'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: canvas,
          colorScheme: ColorScheme.fromSeed(seedColor: primary),
          fontFamily: 'Arial',
        ),
        home: page,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 250));
  final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey<String>('capture-root')),
  );
  final image = await boundary.toImage(pixelRatio: 1.0);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('docs/screenshots/$name.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(data!.buffer.asUint8List());
  image.dispose();
}

Future<QueueStore> storeForScreens() async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final store = QueueStore();
  await store.load();
  store.onboardingComplete = true;
  store.seedDemo();
  return store;
}

void main() {
  testWidgets('capture final Pocket Queue page surfaces', (tester) async {
    tester.view.physicalSize = const ui.Size(1280, 820);
    tester.view.devicePixelRatio = 1.0;

    final onboarding = QueueStore();
    await capturePage(tester, WelcomePage(store: onboarding), 'welcome');
    await capturePage(tester, SetupPage(store: onboarding), 'setup');

    final store = await storeForScreens();
    await capturePage(
      tester,
      QueuePage(store: store, onNavigate: (_) {}),
      'queue',
    );
    await capturePage(tester, DisplayPage(store: store), 'display');
    await capturePage(tester, HistoryPage(store: store), 'history');

    final completed = store.entries.firstWhere(
      (entry) => entry.status == QueueStatus.completed,
    );
    await capturePage(
      tester,
      QueueDetailPage(entry: completed),
      'queue_detail',
    );
    await capturePage(tester, StatisticsPage(store: store), 'statistics');
    await capturePage(tester, SettingsPage(store: store), 'settings');

    // These two names document the queue workflow states. They are captured from
    // the same final queue surface after exercising the corresponding store state.
    store.generate();
    await capturePage(
      tester,
      QueuePage(store: store, onNavigate: (_) {}),
      'queue_add',
    );
    store.callNext();
    await capturePage(
      tester,
      QueuePage(store: store, onNavigate: (_) {}),
      'queue_serving',
    );

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    exit(0);
  });
}
