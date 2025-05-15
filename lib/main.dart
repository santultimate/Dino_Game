import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(DinoGame());

enum Difficulty { Easy, Medium, Hard }

Difficulty selectedDifficulty = Difficulty.Medium;

class DinoGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: StartScreen(),
    );
  }
}

class StartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🐾 Dino Game 🦖',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DifficultySelectionScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text('Start Game', style: TextStyle(fontSize: 24)),
            ),
          ],
        ),
      ),
    );
  }
}

class DifficultySelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Choisissez un niveau', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 30),
            _buildDifficultyButton(context, 'Facile', Difficulty.Easy),
            _buildDifficultyButton(context, 'Moyen', Difficulty.Medium),
            _buildDifficultyButton(context, 'Difficile', Difficulty.Hard),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(BuildContext context, String label, Difficulty level) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: () {
          selectedDifficulty = level;
          Navigator.push(context, MaterialPageRoute(builder: (_) => DinoGameScreen()));
        },
        style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
        child: Text(label, style: TextStyle(fontSize: 22)),
      ),
    );
  }
}

class DinoGameScreen extends StatefulWidget {
  @override
  _DinoGameScreenState createState() => _DinoGameScreenState();
}

class _DinoGameScreenState extends State<DinoGameScreen> {
  final AudioCache _audioCache = AudioCache(prefix: 'assets/');
  AudioPlayer? _bgmPlayer;
  AudioPlayer? _effectPlayer;

  bool isJumping = false;
  bool isGameOver = false;
  bool isDarkMode = false;
  bool isPaused = false;
  int gameSpeed = 5;
  int score = 0;
  List<Obstacle> obstacles = [];
  Random random = Random();

  double dinosaurSize = 0.1;
  double obstacleSize = 0.1;

  double gameOverOpacity = 0;
  double gameOverScale = 0.8;

  @override
  void initState() {
    super.initState();

    switch (selectedDifficulty) {
      case Difficulty.Easy:
        gameSpeed = 3;
        break;
      case Difficulty.Medium:
        gameSpeed = 5;
        break;
      case Difficulty.Hard:
        gameSpeed = 7;
        break;
    }

    _initializeAudio();
    startGame();
    Timer.periodic(Duration(seconds: 1), (_) => increaseDifficulty());
  }

  Future<void> _initializeAudio() async {
    await _audioCache.loadAll(['jump.mp3', 'crash.mp3', 'bgm.mp3', 'gameover.mp3']);
    _bgmPlayer?.stop();
    _bgmPlayer = await _audioCache.loop('bgm.mp3');
    _bgmPlayer?.setVolume(0.3);
  }

  void jump() {
    if (isJumping || isPaused || isGameOver) return;
    setState(() => isJumping = true);
    _audioCache.play('jump.mp3');
    Timer(Duration(milliseconds: 500), () => setState(() => isJumping = false));
  }

  void increaseDifficulty() {
    if (!isPaused && !isGameOver) {
      setState(() => gameSpeed += 1);
    }
  }

  void checkCollisions() {
    for (var obstacle in obstacles) {
      if (obstacle.x < 100 + 50 && obstacle.x > 100 - 50 && !isJumping) {
        _audioCache.play('crash.mp3');
        _audioCache.play('gameover.mp3');
        _bgmPlayer?.stop();
        setState(() {
          isGameOver = true;
          gameOverOpacity = 0;
          gameOverScale = 0.8;
        });
        Future.delayed(Duration(milliseconds: 50), () {
          setState(() {
            gameOverOpacity = 1;
            gameOverScale = 1.0;
          });
        });
        break;
      }
    }
  }

  void addObstacle() {
    if (!isPaused && !isGameOver) {
      setState(() {
        double randomOffset = random.nextInt(200).toDouble();
        obstacles.add(Obstacle(x: 400 + randomOffset));
      });
    }
  }

  void saveBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    int? bestScore = prefs.getInt('bestScore') ?? 0;
    if (score > bestScore) prefs.setInt('bestScore', score);
  }

  Future<int> loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('bestScore') ?? 0;
  }

  void startGame() {
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (isGameOver) {
        timer.cancel();
        return;
      }
      if (!isPaused) {
        setState(() {
          for (var obstacle in obstacles) {
            obstacle.x -= gameSpeed;
          }
          obstacles.removeWhere((obstacle) => obstacle.x < 0);
          score++;
          checkCollisions();
          if (obstacles.length < 3) addObstacle();
        });
      }
    });
  }

  void togglePause() {
    setState(() => isPaused = !isPaused);
  }

  void toggleTheme() {
    setState(() => isDarkMode = !isDarkMode);
  }

  @override
  void dispose() {
    _bgmPlayer?.stop();
    _bgmPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double dinosaurWidth = screenWidth * dinosaurSize;
    double dinosaurHeight = screenHeight * dinosaurSize;
    double obstacleWidth = screenWidth * obstacleSize;
    double obstacleHeight = screenHeight * obstacleSize;

    return GestureDetector(
      onTap: jump,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Dino Game - \${selectedDifficulty.name}"),
          actions: [
            IconButton(
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
              onPressed: togglePause,
            ),
            Switch(
              value: isDarkMode,
              onChanged: (_) => toggleTheme(),
            ),
          ],
          backgroundColor: isDarkMode ? Colors.black : Colors.green,
        ),
        body: isGameOver
            ? AnimatedOpacity(
                opacity: gameOverOpacity,
                duration: Duration(milliseconds: 500),
                child: AnimatedScale(
                  scale: gameOverScale,
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeOutBack,
                  child: Center(child: _buildGameOverScreen()),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/background.png'),
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                    scale: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    ...obstacles.map((o) => Positioned(
                          bottom: 0,
                          left: o.x,
                          child: Image.asset(
                            'assets/cactus.png',
                            width: obstacleWidth,
                            height: obstacleHeight,
                          ),
                        )),
                    Positioned(
                      bottom: isJumping ? screenHeight * 0.2 : screenHeight * 0.1,
                      left: 100,
                      child: Image.asset(
                        'assets/dino.png',
                        width: dinosaurWidth,
                        height: dinosaurHeight,
                      ),
                    ),
                    _buildScore(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildScore() {
    return Positioned(
      top: 20,
      left: 20,
      child: Text(
        'Score: $score',
        style: TextStyle(fontSize: 30, color: isDarkMode ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _buildGameOverScreen() {
    saveBestScore();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Game Over',
          style: TextStyle(fontSize: 50, color: isDarkMode ? Colors.white : Colors.black),
        ),
        SizedBox(height: 20),
        Text(
          'Niveau: ${selectedDifficulty.name}',
          style: TextStyle(fontSize: 25, color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
        SizedBox(height: 10),
        Text(
          'Score: $score',
          style: TextStyle(fontSize: 30, color: isDarkMode ? Colors.white : Colors.black),
        ),
        SizedBox(height: 10),
        FutureBuilder<int>(
          future: loadBestScore(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Text(
                'Best Score: ${snapshot.data}',
                style: TextStyle(fontSize: 30, color: isDarkMode ? Colors.white : Colors.black),
              );
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            setState(() {
              isGameOver = false;
              obstacles.clear();
              score = 0;
              gameOverOpacity = 0;
              gameOverScale = 0.8;
              switch (selectedDifficulty) {
                case Difficulty.Easy:
                  gameSpeed = 3;
                  break;
                case Difficulty.Medium:
                  gameSpeed = 5;
                  break;
                case Difficulty.Hard:
                  gameSpeed = 7;
                  break;
              }
              _initializeAudio();
              startGame();
            });
          },
          child: Text('Play Again'),
        ),
      ],
    );
  }
}

class Obstacle {
  double x;
  Obstacle({required this.x});
}
