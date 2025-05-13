import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(DinoGame());

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
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DinoGameScreen()),
            );
          },
          style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
          child: Text('Start Game', style: TextStyle(fontSize: 24)),
        ),
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
  final AudioPlayer _bgmPlayer = AudioPlayer();

  bool isJumping = false;
  bool isGameOver = false;
  bool isDarkMode = false;
  bool isPaused = false;
  int gameSpeed = 5;
  int score = 0;
  List<Obstacle> obstacles = [];

  double dinosaurSize = 0.1; // Taille relative du dinosaure
  double obstacleSize = 0.1; // Taille relative des obstacles
  double dinosaurYPosition = 0.6; // Position verticale fixe du dinosaure
  double dinosaurXPosition = 100; // Position horizontale du dinosaure

  @override
  void initState() {
    super.initState();
    _audioCache.loadAll(['jump.mp3', 'crash.mp3', 'bgm.mp3']);
    _audioCache.loop('bgm.mp3').then((player) => _bgmPlayer.setVolume(0.3));
    startGame();
    Timer.periodic(Duration(seconds: 1), (_) => increaseDifficulty());
  }

  void jump() {
    if (isJumping || isPaused || isGameOver) return;
    setState(() {
      isJumping = true;
    });
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
      if (obstacle.x < dinosaurXPosition + 50 && obstacle.x > dinosaurXPosition - 50 && !isJumping) {
        _audioCache.play('crash.mp3');
        setState(() => isGameOver = true);
        break;
      }
    }
  }

  void addObstacle() {
    if (!isPaused && !isGameOver) {
      setState(() {
        obstacles.add(Obstacle(x: 400, y: 150 + (50 * (obstacles.length % 3))));
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
          // Faire avancer le dinosaure à chaque tick
          dinosaurXPosition += 5;

          // Déplacer les obstacles
          for (var obstacle in obstacles) {
            obstacle.x -= gameSpeed;
          }
          obstacles.removeWhere((obstacle) => obstacle.x < 0);
          score++;
          checkCollisions();

          if (obstacles.length < 5) addObstacle();
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
    _bgmPlayer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenir les dimensions de l'écran
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Calculer les tailles des objets en fonction de l'écran
    double dinosaurWidth = screenWidth * dinosaurSize;
    double dinosaurHeight = screenHeight * dinosaurSize;
    double obstacleWidth = screenWidth * obstacleSize;
    double obstacleHeight = screenHeight * obstacleSize;

    return GestureDetector(
      onTap: jump,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Dino Game"),
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
            ? Center(child: _buildGameOverScreen())
            : Container(
                color: isDarkMode ? Colors.black : Colors.white,
                child: Stack(
                  children: [
                    // Obstacle
                    ...obstacles.map((o) => Positioned(
                          top: o.y,
                          left: o.x,
                          child: Container(
                            width: obstacleWidth,
                            height: obstacleHeight,
                            color: Colors.red,
                          ),
                        )),
                    // Dinosaure
                    Positioned(
                      top: isJumping ? screenHeight * 0.5 : screenHeight * dinosaurYPosition, // Ajuste vertical du saut
                      left: dinosaurXPosition,
                      child: Container(
                        width: dinosaurWidth,
                        height: dinosaurHeight,
                        color: Colors.green,
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
              gameSpeed = 5;
              dinosaurXPosition = 100; // Réinitialiser la position horizontale du dinosaure
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
  double y;
  Obstacle({required this.x, required this.y});
}
