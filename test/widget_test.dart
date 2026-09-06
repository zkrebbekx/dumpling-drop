import 'package:dumpling_drop/game/progress_store.dart';
import 'package:dumpling_drop/main.dart';
import 'package:dumpling_drop/screens/level_map_screen.dart';
import 'package:dumpling_drop/screens/sticker_book_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressStore> freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return ProgressStore(await SharedPreferences.getInstance());
}

void main() {
  testWidgets('home screen shows title and menu', (tester) async {
    final store = await freshStore();
    await tester.pumpWidget(DumplingDropApp(store: store));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Dumpling'), findsOneWidget);
    expect(find.text('DROP!'), findsOneWidget);
    expect(find.text('PLAY!'), findsOneWidget);
    expect(find.text('Sticker Book'), findsOneWidget);
  });

  testWidgets('play opens the level map with locked levels', (tester) async {
    final store = await freshStore();
    await tester.pumpWidget(DumplingDropApp(store: store));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('PLAY!'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(LevelMapScreen), findsOneWidget);
    expect(find.text('Pick a Basket!'), findsOneWidget);
    expect(find.text('First Bite'), findsOneWidget);
    // Levels 2+ and the free-play baskets start locked. The lazy list
    // only builds what fits the viewport, so assert a floor.
    expect(find.byIcon(Icons.lock_rounded), findsAtLeastNWidgets(8));
  });

  testWidgets('sticker book lists every badge slot', (tester) async {
    final store = await freshStore();
    await tester.pumpWidget(
        MaterialApp(home: StickerBookScreen(store: store)));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Sticker Book'), findsOneWidget);
    expect(find.text('0 of 14 collected'), findsOneWidget);
    // Nothing is owned yet, so names are hidden.
    expect(find.text('???'), findsWidgets);
  });
}
