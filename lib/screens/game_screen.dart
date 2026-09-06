import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/sfx.dart';
import '../game/badges.dart' as game_badges;
import '../game/game_controller.dart';
import '../game/levels.dart';
import '../game/piece.dart';
import '../game/progress_store.dart';
import '../theme.dart';
import '../widgets/board_view.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/confetti.dart';
import '../widgets/dumpling.dart';
import '../widgets/motion.dart';
import '../widgets/painted_icons.dart';
import '../widgets/stars_row.dart';
import '../widgets/steam_background.dart';
import '../widgets/sticker_art.dart';

class GameScreen extends StatefulWidget {
  final LevelConfig level;
  final ProgressStore store;

  const GameScreen({super.key, required this.level, required this.store});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver {
  late GameController _controller;
  final _random = Random();

  String? _banner;
  int _bannerId = 0;
  int _bestClearThisGame = 0;
  int _startLines = 0;
  List<game_badges.Badge> _newBadges = [];
  bool _resultSaved = false;

  double _dragX = 0;
  double _dragY = 0;

  static const _praise = [
    'Yum!',
    'Tasty!',
    'Great!',
    'Wow!',
    'So good!',
    'Delish!',
    'Nice one!',
    'Chef move!',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _newGame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A child switching apps or locking the screen must not lose the
    // game to gravity ticking in the background.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _controller.pause();
    }
  }

  void _newGame({int startLines = 0}) {
    _startLines = startLines;
    _controller = GameController(level: widget.level, startLines: startLines)
      ..addEventListener(_onGameEvent)
      ..addListener(_onStateChange);
    _banner = null;
    _bestClearThisGame = 0;
    _newBadges = [];
    _resultSaved = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (!mounted) return;
    if ((_controller.phase == GamePhase.won ||
            _controller.phase == GamePhase.lost) &&
        !_resultSaved) {
      _resultSaved = true;
      _saveResult();
    }
    setState(() {});
  }

  Future<void> _saveResult() async {
    final store = widget.store;
    final won = _controller.phase == GamePhase.won;
    if (won) {
      await store.recordWin(
        widget.level.number,
        _controller.starsForScore(),
        _controller.score,
      );
    } else if (widget.level.endless) {
      await store.recordBestScore(widget.level.number, _controller.score);
    }
    await store.recordGame(
      // A head-start run only banks the lines it really cleared.
      lines: _controller.linesCleared - _startLines,
      feasts: _controller.feasts,
      maxCombo: _controller.maxCombo,
      special: isSpecialLevel(widget.level.number),
    );
    final fresh = await store.grantNewBadges(store.statsSnapshot(
      gameLines: _controller.linesCleared,
      gameBestClear: _bestClearThisGame,
      gameScore: _controller.score,
    ));
    if (fresh.isNotEmpty) {
      Sfx.instance.play(Sound.badge);
    }
    if (mounted) setState(() => _newBadges = fresh);
  }

  void _onGameEvent(GameEvent event, {List<int>? rows, int? points}) {
    switch (event) {
      case GameEvent.move:
        Sfx.instance.play(Sound.move);
      case GameEvent.rotate:
        Sfx.instance.play(Sound.rotate);
      case GameEvent.softDrop:
        break;
      case GameEvent.hardDrop:
        Sfx.instance.play(Sound.drop);
      case GameEvent.lock:
        Sfx.instance.play(Sound.squish);
        HapticFeedback.lightImpact();
      case GameEvent.clear:
        // Combo pops climb in pitch: each clear in a row sounds higher.
        Sfx.instance.play(Sound.pop,
            pitch: min(1.6, 1.0 + (_controller.combo - 1) * 0.12));
        _bestClearThisGame = max(_bestClearThisGame, rows?.length ?? 1);
        _showBanner(_controller.combo >= 2
            ? 'Combo x${_controller.combo}!'
            : _praise[_random.nextInt(_praise.length)]);
      case GameEvent.feast:
        Sfx.instance.play(Sound.feast);
        HapticFeedback.mediumImpact();
        _bestClearThisGame = max(_bestClearThisGame, rows?.length ?? 4);
        _showBanner('DUMPLING FEAST!');
      case GameEvent.combo:
        Sfx.instance.play(Sound.combo);
      case GameEvent.win:
        Sfx.instance.play(Sound.fanfare);
        HapticFeedback.mediumImpact();
      case GameEvent.lose:
        Sfx.instance.play(Sound.sad);
    }
  }

  void _showBanner(String text) {
    final id = ++_bannerId;
    setState(() => _banner = text);
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted && _bannerId == id) setState(() => _banner = null);
    });
  }

  void _restart({int startLines = 0}) {
    _controller.removeListener(_onStateChange);
    _controller.dispose();
    setState(() => _newGame(startLines: startLines));
  }

  /// Long levels offer a head start after a loss: half the cleared
  /// lines carry over, so a near miss at line 28 of 30 does not mean
  /// starting from zero.
  bool get _mercyOffered =>
      !widget.level.endless &&
      widget.level.goalLines >= 20 &&
      _controller.linesCleared >= 8;

  // ---- Gestures on the board ----

  void _onPanUpdate(DragUpdateDetails details, double cellWidth) {
    _dragX += details.delta.dx;
    _dragY += details.delta.dy;
    while (_dragX > cellWidth * 0.8) {
      _controller.moveRight();
      _dragX -= cellWidth * 0.8;
    }
    while (_dragX < -cellWidth * 0.8) {
      _controller.moveLeft();
      _dragX += cellWidth * 0.8;
    }
    while (_dragY > cellWidth * 0.9) {
      _controller.softDrop();
      _dragY -= cellWidth * 0.9;
    }
    if (_dragY < 0) _dragY = 0;
  }

  void _onPanEnd(DragEndDetails details) {
    if (details.velocity.pixelsPerSecond.dy > 650 &&
        details.velocity.pixelsPerSecond.dy >
            details.velocity.pixelsPerSecond.dx.abs() * 1.5) {
      _controller.hardDrop();
    }
    _dragX = 0;
    _dragY = 0;
  }

  @override
  Widget build(BuildContext context) {
    final phase = _controller.phase;
    return Scaffold(
      body: SteamBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHud(),
                  Expanded(child: _buildBoard()),
                  _buildControls(),
                ],
              ),
              if (_banner != null) _buildBanner(),
              if (phase == GamePhase.ready) _buildReadyOverlay(),
              if (phase == GamePhase.paused) _buildPauseOverlay(),
              if (phase == GamePhase.won) _buildWinOverlay(),
              if (phase == GamePhase.lost) _buildLoseOverlay(),
              if (phase == GamePhase.won) const ConfettiOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHud() {
    final level = widget.level;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BouncyIconButton(
            icon: Icons.pause_rounded,
            color: DumplingTheme.lemon,
            size: 48,
            label: 'Pause',
            onPressed: () {
              Sfx.instance.play(Sound.click);
              _controller.pause();
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Level ${level.number}',
                        style: DumplingTheme.display(size: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        level.name,
                        overflow: TextOverflow.ellipsis,
                        style: DumplingTheme.body(
                            size: 16, color: DumplingTheme.inkSoft),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (level.endless)
                  Text(
                    '${_controller.linesCleared} lines · '
                    'Best ${widget.store.bestScoreFor(level.number)}',
                    style: DumplingTheme.body(
                        size: 15, color: DumplingTheme.inkSoft),
                  )
                else
                  _GoalBar(
                    progress: _controller.goalProgress,
                    label: '${_controller.linesCleared} / '
                        '${level.goalLines}',
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              Text('${_controller.score}',
                  style: DumplingTheme.display(size: 24)),
              _NextPreview(piece: _controller.next),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = min(
            constraints.maxWidth / widget.level.cols,
            constraints.maxHeight / widget.level.rows,
          );
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _controller.rotate,
            onPanUpdate: (d) => _onPanUpdate(d, cellWidth),
            onPanEnd: _onPanEnd,
            child: BoardView(controller: _controller),
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BouncyIconButton(
            icon: Icons.chevron_left_rounded,
            color: DumplingTheme.sky,
            size: 68,
            repeat: true,
            label: 'Move left',
            onPressed: _controller.moveLeft,
          ),
          BouncyIconButton(
            icon: Icons.chevron_right_rounded,
            color: DumplingTheme.sky,
            size: 68,
            repeat: true,
            label: 'Move right',
            onPressed: _controller.moveRight,
          ),
          BouncyIconButton(
            icon: Icons.rotate_right_rounded,
            color: DumplingTheme.lilac,
            size: 68,
            label: 'Turn',
            onPressed: _controller.rotate,
          ),
          BouncyIconButton(
            icon: Icons.keyboard_double_arrow_down_rounded,
            color: DumplingTheme.peach,
            size: 68,
            label: 'Drop',
            onPressed: _controller.hardDrop,
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: const Alignment(0, -0.45),
          child: TweenAnimationBuilder<double>(
            key: ValueKey(_bannerId),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 350),
            curve: Curves.elasticOut,
            builder: (context, t, child) =>
                Transform.scale(scale: t, child: child),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
              decoration: BoxDecoration(
                color: DumplingTheme.star,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10),
                ],
              ),
              child: Text(_banner ?? '',
                  style: DumplingTheme.display(size: 30)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _overlayCard({required List<Widget> children}) {
    return Positioned.fill(
      child: Container(
        color: DumplingTheme.ink.withValues(alpha: 0.35),
        alignment: Alignment.center,
        child: PopIn(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 30, vertical: 24),
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: DumplingTheme.cream,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: DumplingTheme.bamboo, width: 4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The "New sticker!" panel, shown on win and on loss alike so a
  /// reward never plays its chime invisibly.
  List<Widget> _newBadgeCards() {
    if (_newBadges.isEmpty) return const [];
    return [
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DumplingTheme.lemon.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('New sticker${_newBadges.length > 1 ? 's' : ''}!',
                style: DumplingTheme.display(size: 20)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final badge in _newBadges)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StickerArt(badgeId: badge.id, size: 44),
                      Text(badge.name,
                          style: DumplingTheme.body(size: 14)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Widget _starTarget(int stars, int score) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < stars; i++)
          const Icon(Icons.star_rounded,
              size: 22, color: DumplingTheme.star),
        const SizedBox(width: 6),
        Text('$score', style: DumplingTheme.body(size: 18)),
      ],
    );
  }

  Widget _hintRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: DumplingTheme.ink),
          const SizedBox(width: 8),
          Text(text, style: DumplingTheme.body(size: 17)),
        ],
      ),
    );
  }

  Widget _buildReadyOverlay() {
    final level = widget.level;
    final showHints = level.number <= 2 || level.endless;
    return _overlayCard(children: [
      const DumplingMascot(size: 88),
      const SizedBox(height: 10),
      Text(level.name, style: DumplingTheme.display(size: 30)),
      const SizedBox(height: 6),
      Text(
        level.endless
            ? 'How long can you go?'
            : 'Clear ${level.goalLines} lines!',
        style: DumplingTheme.body(size: 20, color: DumplingTheme.inkSoft),
      ),
      if (!level.endless) ...[
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _starTarget(2, level.twoStarScore),
            const SizedBox(width: 18),
            _starTarget(3, level.threeStarScore),
          ],
        ),
      ],
      if (showHints) ...[
        const SizedBox(height: 12),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: DumplingTheme.lemon.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hintRow(Icons.touch_app_rounded, 'Tap = turn'),
              _hintRow(Icons.swipe_rounded, 'Slide = move'),
              _hintRow(Icons.swipe_down_alt_rounded, 'Flick down = drop'),
            ],
          ),
        ),
      ],
      const SizedBox(height: 18),
      BouncyButton(
        color: DumplingTheme.mint,
        onPressed: _controller.start,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow_rounded,
                size: 34, color: DumplingTheme.ink),
            Text("Let's Go!", style: DumplingTheme.display(size: 28)),
          ],
        ),
      ),
    ]);
  }

  Widget _buildPauseOverlay() {
    final store = widget.store;
    return _overlayCard(children: [
      Text('Paused', style: DumplingTheme.display(size: 34)),
      const SizedBox(height: 12),
      BouncyIconButton(
        icon: store.soundOn
            ? Icons.volume_up_rounded
            : Icons.volume_off_rounded,
        color: DumplingTheme.lemon,
        size: 56,
        label: store.soundOn ? 'Turn sound off' : 'Turn sound on',
        onPressed: () async {
          final next = !store.soundOn;
          await store.setSoundOn(next);
          Sfx.instance.setEnabled(next);
          if (next) await Sfx.instance.startMusic();
          if (mounted) setState(() {});
        },
      ),
      const SizedBox(height: 12),
      BouncyButton(
        color: DumplingTheme.mint,
        onPressed: _controller.resume,
        child: Text('Keep Playing', style: DumplingTheme.display(size: 24)),
      ),
      const SizedBox(height: 12),
      BouncyButton(
        color: DumplingTheme.lemon,
        onPressed: _restart,
        child: Text('Restart', style: DumplingTheme.display(size: 24)),
      ),
      const SizedBox(height: 12),
      BouncyButton(
        color: DumplingTheme.pink,
        onPressed: () => Navigator.of(context).pop(),
        child: Text('Level Map', style: DumplingTheme.display(size: 24)),
      ),
    ]);
  }

  Widget _buildWinOverlay() {
    final stars = _controller.starsForScore();
    final isFinale = widget.level.number == levels.length;
    final nextLevel = widget.level.number < levels.length
        ? levels[widget.level.number]
        : null;
    return _overlayCard(children: [
      if (isFinale) ...[
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DumplingMascot(size: 64, color: DumplingTheme.mint),
            DumplingMascot(size: 84, color: DumplingTheme.lemon),
            DumplingMascot(size: 64, color: DumplingTheme.pink),
          ],
        ),
        const SizedBox(height: 8),
        Text('You beat the game!',
            textAlign: TextAlign.center,
            style: DumplingTheme.display(size: 30)),
        Text('Dumpling Master!',
            style: DumplingTheme.body(
                size: 20, color: DumplingTheme.inkSoft)),
      ] else
        Text('Level Complete!', style: DumplingTheme.display(size: 30)),
      const SizedBox(height: 10),
      StarsRow(stars: stars, size: 54, animated: true),
      const SizedBox(height: 8),
      CountUp(
        value: _controller.score,
        prefix: 'Score: ',
        style: DumplingTheme.body(size: 22),
      ),
      Text('Best: ${widget.store.bestScoreFor(widget.level.number)}',
          style:
              DumplingTheme.body(size: 16, color: DumplingTheme.inkSoft)),
      if (stars < 3) ...[
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Next goal:  ',
                style: DumplingTheme.body(
                    size: 16, color: DumplingTheme.inkSoft)),
            _starTarget(
                stars + 1,
                stars >= 2
                    ? widget.level.threeStarScore
                    : widget.level.twoStarScore),
          ],
        ),
      ],
      ..._newBadgeCards(),
      const SizedBox(height: 18),
      if (nextLevel != null)
        BouncyButton(
          color: DumplingTheme.mint,
          onPressed: () {
            Navigator.of(context).pushReplacement(
              bouncyRoute(
                  GameScreen(level: nextLevel, store: widget.store)),
            );
          },
          child: Text('Next Level!', style: DumplingTheme.display(size: 26)),
        ),
      const SizedBox(height: 12),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BouncyButton(
            color: DumplingTheme.lemon,
            onPressed: _restart,
            child: Text('Again', style: DumplingTheme.display(size: 22)),
          ),
          const SizedBox(width: 12),
          BouncyButton(
            color: DumplingTheme.pink,
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Map', style: DumplingTheme.display(size: 22)),
          ),
        ],
      ),
    ]);
  }

  Widget _buildLoseOverlay() {
    final endless = widget.level.endless;
    return _overlayCard(children: [
      DumplingMascot(
          size: 90,
          color: endless ? DumplingTheme.lemon : DumplingTheme.sky),
      const SizedBox(height: 10),
      Text(
          endless ? 'Great snacking!' : 'Oh no, the basket\nis full!',
          textAlign: TextAlign.center,
          style: DumplingTheme.display(size: 26)),
      const SizedBox(height: 6),
      Text(
        endless
            ? '${_controller.linesCleared} lines · Score '
                '${_controller.score}\n'
                'Best: ${widget.store.bestScoreFor(widget.level.number)}'
            : 'You cleared ${_controller.linesCleared} lines. '
                'You can do it!',
        textAlign: TextAlign.center,
        style: DumplingTheme.body(size: 18, color: DumplingTheme.inkSoft),
      ),
      ..._newBadgeCards(),
      const SizedBox(height: 18),
      if (_mercyOffered) ...[
        BouncyButton(
          color: DumplingTheme.lemon,
          onPressed: () =>
              _restart(startLines: _controller.linesCleared ~/ 2),
          child: Column(
            children: [
              Text('Head Start!', style: DumplingTheme.display(size: 24)),
              Text(
                'Keep ${_controller.linesCleared ~/ 2} lines',
                style: DumplingTheme.body(
                    size: 15, color: DumplingTheme.inkSoft),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
      BouncyButton(
        color: DumplingTheme.mint,
        onPressed: _restart,
        child: Text(endless ? 'Play Again!' : 'Try Again!',
            style: DumplingTheme.display(size: 26)),
      ),
      const SizedBox(height: 12),
      BouncyButton(
        color: DumplingTheme.pink,
        onPressed: () => Navigator.of(context).pop(),
        child: Text('Level Map', style: DumplingTheme.display(size: 22)),
      ),
    ]);
  }
}

class _GoalBar extends StatelessWidget {
  final double progress;
  final String label;

  const _GoalBar({required this.progress, required this.label});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 22,
            child: Stack(
              children: [
                Container(color: DumplingTheme.creamDark),
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  widthFactor: progress.clamp(0.02, 1.0),
                  heightFactor: 1,
                  alignment: Alignment.centerLeft,
                  child: Container(color: DumplingTheme.mintDark),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          decoration: BoxDecoration(
            color: DumplingTheme.cream.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: DumplingTheme.body(size: 14)),
              const SizedBox(width: 3),
              const PaintedIcon(GameIcon.dumpling, size: 13),
            ],
          ),
        ),
      ],
    );
  }
}

class _NextPreview extends StatelessWidget {
  final Piece piece;

  const _NextPreview({required this.piece});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DumplingTheme.boardWell,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: DumplingTheme.bamboo.withValues(alpha: 0.6), width: 2),
      ),
      child: CustomPaint(
        size: const Size(56, 30),
        painter: _NextPainter(piece),
      ),
    );
  }
}

class _NextPainter extends CustomPainter {
  final Piece piece;

  _NextPainter(this.piece);

  @override
  void paint(Canvas canvas, Size size) {
    final cells = piece.cells(0);
    final minRow = cells.map((c) => c.row).reduce(min);
    final maxRow = cells.map((c) => c.row).reduce(max);
    final minCol = cells.map((c) => c.col).reduce(min);
    final maxCol = cells.map((c) => c.col).reduce(max);
    final cols = maxCol - minCol + 1;
    final rows = maxRow - minRow + 1;
    final cell = min(size.width / cols, size.height / rows);
    final left = (size.width - cell * cols) / 2;
    final top = (size.height - cell * rows) / 2;
    for (final c in cells) {
      paintDumpling(
        canvas,
        Rect.fromLTWH(
          left + (c.col - minCol) * cell,
          top + (c.row - minRow) * cell,
          cell,
          cell,
        ),
        piece.color(DumplingTheme.fillings),
        face: false,
      );
    }
  }

  @override
  bool shouldRepaint(_NextPainter old) => old.piece.kind != piece.kind;
}
