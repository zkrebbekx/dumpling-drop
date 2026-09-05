import 'dart:math';

import 'package:flutter/material.dart';

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
import '../widgets/stars_row.dart';
import '../widgets/steam_background.dart';

class GameScreen extends StatefulWidget {
  final LevelConfig level;
  final ProgressStore store;

  const GameScreen({super.key, required this.level, required this.store});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController _controller;
  final _random = Random();

  String? _banner;
  int _bannerId = 0;
  int _bestClearThisGame = 0;
  List<game_badges.Badge> _newBadges = [];
  bool _resultSaved = false;

  double _dragX = 0;
  double _dragY = 0;

  static const _praise = ['Yum!', 'Tasty!', 'Great!', 'Wow!', 'So good!'];

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    _controller = GameController(level: widget.level)
      ..addEventListener(_onGameEvent)
      ..addListener(_onStateChange);
    _banner = null;
    _bestClearThisGame = 0;
    _newBadges = [];
    _resultSaved = false;
  }

  @override
  void dispose() {
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
    }
    await store.recordGame(
      lines: _controller.linesCleared,
      feasts: _controller.feasts,
      maxCombo: _controller.maxCombo,
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

  void _onGameEvent(GameEvent event, {List<int>? rows}) {
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
      case GameEvent.clear:
        Sfx.instance.play(Sound.pop);
        _bestClearThisGame = max(_bestClearThisGame, rows?.length ?? 1);
        _showBanner(_praise[_random.nextInt(_praise.length)]);
      case GameEvent.feast:
        Sfx.instance.play(Sound.feast);
        _bestClearThisGame = max(_bestClearThisGame, rows?.length ?? 4);
        _showBanner('DUMPLING FEAST!');
      case GameEvent.combo:
        Sfx.instance.play(Sound.combo);
      case GameEvent.win:
        Sfx.instance.play(Sound.fanfare);
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

  void _restart() {
    _controller.removeListener(_onStateChange);
    _controller.dispose();
    setState(_newGame);
  }

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
    if (details.velocity.pixelsPerSecond.dy > 900 &&
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
                _GoalBar(
                  progress: _controller.goalProgress,
                  label:
                      '${_controller.linesCleared} / ${level.goalLines} lines',
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
            onPressed: _controller.moveLeft,
          ),
          BouncyIconButton(
            icon: Icons.chevron_right_rounded,
            color: DumplingTheme.sky,
            size: 68,
            onPressed: _controller.moveRight,
          ),
          BouncyIconButton(
            icon: Icons.rotate_right_rounded,
            color: DumplingTheme.lilac,
            size: 68,
            onPressed: _controller.rotate,
          ),
          BouncyIconButton(
            icon: Icons.keyboard_double_arrow_down_rounded,
            color: DumplingTheme.peach,
            size: 68,
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
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
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
    );
  }

  Widget _buildReadyOverlay() {
    return _overlayCard(children: [
      const DumplingMascot(size: 96),
      const SizedBox(height: 12),
      Text(widget.level.name, style: DumplingTheme.display(size: 30)),
      const SizedBox(height: 6),
      Text(
        'Clear ${widget.level.goalLines} lines!',
        style: DumplingTheme.body(size: 20, color: DumplingTheme.inkSoft),
      ),
      const SizedBox(height: 20),
      BouncyButton(
        color: DumplingTheme.mint,
        onPressed: _controller.start,
        child: Text("Let's Go!", style: DumplingTheme.display(size: 28)),
      ),
    ]);
  }

  Widget _buildPauseOverlay() {
    return _overlayCard(children: [
      Text('Paused', style: DumplingTheme.display(size: 34)),
      const SizedBox(height: 20),
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
    final nextLevel = widget.level.number < levels.length
        ? levels[widget.level.number]
        : null;
    return _overlayCard(children: [
      Text('Level Complete!', style: DumplingTheme.display(size: 30)),
      const SizedBox(height: 10),
      StarsRow(stars: stars, size: 54, animated: true),
      const SizedBox(height: 8),
      Text('Score: ${_controller.score}',
          style: DumplingTheme.body(size: 22)),
      if (_newBadges.isNotEmpty) ...[
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
                        Text(badge.emoji,
                            style: const TextStyle(fontSize: 34)),
                        Text(badge.name,
                            style: DumplingTheme.body(size: 14)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 18),
      if (nextLevel != null && widget.store.isUnlocked(nextLevel.number))
        BouncyButton(
          color: DumplingTheme.mint,
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) =>
                    GameScreen(level: nextLevel, store: widget.store),
              ),
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
    return _overlayCard(children: [
      const DumplingMascot(size: 90, color: DumplingTheme.sky),
      const SizedBox(height: 10),
      Text('Oh no, the basket\nis full!',
          textAlign: TextAlign.center,
          style: DumplingTheme.display(size: 26)),
      const SizedBox(height: 6),
      Text(
        'You cleared ${_controller.linesCleared} lines. '
        'You can do it!',
        textAlign: TextAlign.center,
        style: DumplingTheme.body(size: 18, color: DumplingTheme.inkSoft),
      ),
      const SizedBox(height: 18),
      BouncyButton(
        color: DumplingTheme.mint,
        onPressed: _restart,
        child: Text('Try Again!', style: DumplingTheme.display(size: 26)),
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
                  child: Container(color: DumplingTheme.mint),
                ),
              ],
            ),
          ),
        ),
        Text(label, style: DumplingTheme.body(size: 14)),
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
