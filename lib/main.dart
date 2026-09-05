import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio/sfx.dart';
import 'game/progress_store.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  final store = await ProgressStore.open();
  Sfx.instance.enabled = store.soundOn;
  await Sfx.instance.init();
  runApp(DumplingDropApp(store: store));
}

class DumplingDropApp extends StatelessWidget {
  final ProgressStore store;

  const DumplingDropApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dumpling Drop',
      debugShowCheckedModeBanner: false,
      theme: DumplingTheme.themeData(),
      home: HomeScreen(store: store),
    );
  }
}
