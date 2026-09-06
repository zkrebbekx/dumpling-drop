import 'dart:async';

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
  // Never await playback before the first frame: a blocked audio
  // start (web autoplay policy, slow codec init) must not hold the
  // whole app on a blank screen.
  unawaited(Sfx.instance.startMusic());
  runApp(DumplingDropApp(store: store));
}

class DumplingDropApp extends StatefulWidget {
  final ProgressStore store;

  const DumplingDropApp({super.key, required this.store});

  @override
  State<DumplingDropApp> createState() => _DumplingDropAppState();
}

class _DumplingDropAppState extends State<DumplingDropApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Silence the music when the app leaves the foreground.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      Sfx.instance.stopMusic();
    } else if (state == AppLifecycleState.resumed) {
      Sfx.instance.startMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dumpling Drop',
      debugShowCheckedModeBanner: false,
      theme: DumplingTheme.themeData(),
      home: HomeScreen(store: widget.store),
    );
  }
}
