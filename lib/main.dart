import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:vibration/vibration.dart';

void main() {
  runApp(const DinoGame());
}

class DinoGame extends StatelessWidget {
  const DinoGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dino Game',
      theme: ThemeData.dark(),
      home: const StartScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GameScreen()),
          );
        },
        child: Stack(
          children: [
            Center(
              child: Image.asset('assets/start_screen_image.png'),
            ),
            const Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Text(
                'TAP TO START',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, color: Colors.white70),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  double dinoY = 1;
  bool isJumping = false;
  double time = 0;
  double height = 0;
  double initialHeight = 1;
  int score = 0;
  int bestScore = 0;
  double cactusX = 1;
  bool gameStarted = false;

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();

  late SharedPreferences prefs;
  late Timer gameTimer;

  final double characterOffsetY = 0.2; // Décalage vers le haut

  @override
  void initState() {
    super.initState();
    initPrefs();
    _initializeAudio();
  }

  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    bestScore = prefs.getInt('bestScore') ?? 0;
    setState(() {});
  }

  Future<void> _initializeAudio() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setSource(AssetSource('bgm.mp3'));
    await _bgmPlayer.setVolume(0.4);
    await _bgmPlayer.resume();
  }

  void jump() {
    if (!isJumping) {
      _effectPlayer.play(AssetSource('jump.mp3'));
      isJumping = true;
      time = 0;
      initialHeight = dinoY;
      Timer.periodic(const Duration(milliseconds: 50), (timer) {
        time += 0.05;
        height = -4.9 * time * time + 5 * time;

        setState(() {
          dinoY = initialHeight - height;
        });

        if (dinoY > 1) {
          dinoY = 1;
          isJumping = false;
          timer.cancel();
        }
      });
    }
  }

  void startGame() {
    gameStarted = true;
    cactusX = 1;

    gameTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        cactusX -= 0.02;
        if (cactusX < -1.2) {
          cactusX = 1;
          score++;
        }

        // Collision
        if (cactusX < 0.2 && cactusX > -0.2 && dinoY > 0.7) {
          _effectPlayer.play(AssetSource('crash.mp3'));
          Vibration.vibrate(duration: 300);
          gameOver();
          timer.cancel();
        }
      });
    });
  }

  void gameOver() async {
    await _bgmPlayer.pause();
    await _effectPlayer.play(AssetSource('gameover.mp3'));

    if (score > bestScore) {
      bestScore = score;
      await prefs.setInt('bestScore', bestScore);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Game Over"),
        content: Text("Score: $score\nBest: $bestScore"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              resetGame();
            },
            child: const Text("Retry"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Menu"),
          ),
        ],
      ),
    );
  }

  void resetGame() async {
    setState(() {
      dinoY = 1;
      isJumping = false;
      time = 0;
      height = 0;
      initialHeight = 1;
      score = 0;
      cactusX = 1;
      gameStarted = false;
    });
    await _bgmPlayer.resume();
  }

  @override
  void dispose() {
    _bgmPlayer.dispose();
    _effectPlayer.dispose();
    if (gameTimer.isActive) gameTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!gameStarted) {
          startGame();
        } else {
          jump();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset('assets/background.png', fit: BoxFit.cover),
            ),
            AnimatedContainer(
              alignment: Alignment(0, dinoY - characterOffsetY),
              duration: const Duration(milliseconds: 0),
              child: Image.asset('assets/dino.png', height: 80),
            ),
            AnimatedContainer(
              alignment: Alignment(cactusX, 1 - characterOffsetY),
              duration: const Duration(milliseconds: 0),
              child: Image.asset('assets/cactus.png', height: 60),
            ),
            Positioned(
              top: 40,
              left: 20,
              child: Text("Score: $score", style: const TextStyle(fontSize: 22, color: Colors.white)),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: Text("Best: $bestScore", style: const TextStyle(fontSize: 22, color: Colors.white70)),
            ),
            if (!gameStarted)
              const Center(
                child: Text(
                  "TAP TO START",
                  style: TextStyle(fontSize: 28, color: Colors.white70),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
