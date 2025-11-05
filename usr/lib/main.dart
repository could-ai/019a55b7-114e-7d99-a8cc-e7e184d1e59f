import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MarioGame());
}

class MarioGame extends StatelessWidget {
  const MarioGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mario Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Mario position and physics
  double marioX = 0.1;
  double marioY = 0.5;
  double marioVelocityY = 0;
  double gravity = 0.8;
  double jumpStrength = -12.0;
  bool isJumping = false;
  
  // Game state
  bool gameStarted = false;
  int score = 0;
  bool gameOver = false;
  
  // Obstacles
  List<Obstacle> obstacles = [];
  double obstacleSpeed = 0.02;
  
  // Animation
  Timer? gameLoop;
  int marioFrame = 0;
  Timer? animationTimer;
  
  // Mario direction
  bool facingRight = true;
  double moveSpeed = 0.03;
  bool movingLeft = false;
  bool movingRight = false;

  @override
  void initState() {
    super.initState();
    _initializeObstacles();
  }

  void _initializeObstacles() {
    obstacles = [
      Obstacle(x: 1.5, width: 0.15, height: 0.3, type: ObstacleType.pipe),
      Obstacle(x: 2.5, width: 0.15, height: 0.4, type: ObstacleType.pipe),
      Obstacle(x: 4.0, width: 0.2, height: 0.2, type: ObstacleType.block),
      Obstacle(x: 5.5, width: 0.15, height: 0.3, type: ObstacleType.pipe),
    ];
  }

  void startGame() {
    setState(() {
      gameStarted = true;
      gameOver = false;
      score = 0;
      marioX = 0.1;
      marioY = 0.5;
      marioVelocityY = 0;
      _initializeObstacles();
    });
    
    gameLoop = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      updateGame();
    });
    
    animationTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      setState(() {
        marioFrame = (marioFrame + 1) % 2;
      });
    });
  }

  void updateGame() {
    if (gameOver) return;
    
    setState(() {
      // Apply gravity
      marioVelocityY += gravity;
      marioY += marioVelocityY * 0.01;
      
      // Ground collision
      if (marioY > 0.5) {
        marioY = 0.5;
        marioVelocityY = 0;
        isJumping = false;
      }
      
      // Horizontal movement
      if (movingRight) {
        marioX += moveSpeed;
        facingRight = true;
      }
      if (movingLeft && marioX > 0) {
        marioX -= moveSpeed;
        facingRight = false;
      }
      
      // Move obstacles
      for (var obstacle in obstacles) {
        obstacle.x -= obstacleSpeed;
        
        // Reset obstacle position when it goes off screen
        if (obstacle.x < -0.5) {
          obstacle.x = obstacles.map((o) => o.x).reduce((a, b) => a > b ? a : b) + 1.5;
          score += 10;
        }
        
        // Check collision
        if (checkCollision(obstacle)) {
          endGame();
        }
      }
      
      // Prevent Mario from going off screen
      if (marioX > 1.2) marioX = 1.2;
    });
  }

  bool checkCollision(Obstacle obstacle) {
    double marioWidth = 0.1;
    double marioHeight = 0.15;
    
    return marioX < obstacle.x + obstacle.width &&
           marioX + marioWidth > obstacle.x &&
           marioY < 0.5 &&
           marioY + marioHeight > 0.5 - obstacle.height;
  }

  void jump() {
    if (!isJumping && gameStarted && !gameOver) {
      setState(() {
        marioVelocityY = jumpStrength;
        isJumping = true;
      });
    }
  }

  void endGame() {
    gameOver = true;
    gameLoop?.cancel();
    animationTimer?.cancel();
  }

  @override
  void dispose() {
    gameLoop?.cancel();
    animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (!gameStarted) {
            startGame();
          } else {
            jump();
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5C94FC), Color(0xFF5C94FC), Color(0xFF8BC34A)],
              stops: [0.0, 0.7, 0.7],
            ),
          ),
          child: Stack(
            children: [
              // Ground
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: screenHeight * 0.3,
                  color: const Color(0xFFD2691E),
                  child: Stack(
                    children: [
                      // Ground pattern
                      ...List.generate(20, (index) {
                        return Positioned(
                          left: index * screenWidth * 0.1,
                          top: 10,
                          child: Container(
                            width: screenWidth * 0.08,
                            height: 5,
                            color: const Color(0xFFA0522D),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              
              // Obstacles
              ...obstacles.map((obstacle) => Positioned(
                left: obstacle.x * screenWidth,
                bottom: screenHeight * 0.3,
                child: Container(
                  width: obstacle.width * screenWidth,
                  height: obstacle.height * screenHeight,
                  decoration: BoxDecoration(
                    color: obstacle.type == ObstacleType.pipe 
                        ? Colors.green[700] 
                        : Colors.brown[400],
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: obstacle.type == ObstacleType.block
                        ? BorderRadius.circular(5)
                        : BorderRadius.zero,
                  ),
                  child: obstacle.type == ObstacleType.pipe
                      ? Column(
                          children: [
                            Container(
                              height: 20,
                              color: Colors.green[800],
                            ),
                            Expanded(
                              child: Container(
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Text(
                            '?',
                            style: TextStyle(
                              color: Colors.yellow[700],
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              )),
              
              // Mario
              Positioned(
                left: marioX * screenWidth,
                top: marioY * screenHeight,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(facingRight ? 1.0 : -1.0, 1.0),
                  child: SizedBox(
                    width: 50,
                    height: 60,
                    child: CustomPaint(
                      painter: MarioPainter(frame: marioFrame),
                    ),
                  ),
                ),
              ),
              
              // Score
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'النقاط: $score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Controls
              if (gameStarted && !gameOver)
                Positioned(
                  bottom: 40,
                  left: 20,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTapDown: (_) => setState(() => movingLeft = true),
                        onTapUp: (_) => setState(() => movingLeft = false),
                        onTapCancel: () => setState(() => movingLeft = false),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 35),
                        ),
                      ),
                      const SizedBox(width: 15),
                      GestureDetector(
                        onTapDown: (_) => setState(() => movingRight = true),
                        onTapUp: (_) => setState(() => movingRight = false),
                        onTapCancel: () => setState(() => movingRight = false),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.arrow_forward, color: Colors.white, size: 35),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Jump button
              if (gameStarted && !gameOver)
                Positioned(
                  bottom: 40,
                  right: 20,
                  child: GestureDetector(
                    onTap: jump,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Center(
                        child: Text(
                          'قفز',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Start screen
              if (!gameStarted)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '🍄 لعبة ماريو 🍄',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'ابدأ اللعبة',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'اضغط للقفز - تجنب العقبات',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Game over screen
              if (gameOver)
                Container(
                  color: Colors.black.withOpacity(0.8),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '💥 انتهت اللعبة 💥',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'النقاط النهائية: $score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              gameStarted = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'العب مرة أخرى',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class Obstacle {
  double x;
  double width;
  double height;
  ObstacleType type;
  
  Obstacle({
    required this.x,
    required this.width,
    required this.height,
    required this.type,
  });
}

enum ObstacleType {
  pipe,
  block,
}

class MarioPainter extends CustomPainter {
  final int frame;
  
  MarioPainter({required this.frame});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Red hat
    paint.color = Colors.red;
    canvas.drawRect(Rect.fromLTWH(10, 5, 30, 15), paint);
    
    // Face
    paint.color = const Color(0xFFFFDBB3);
    canvas.drawRect(Rect.fromLTWH(10, 20, 30, 20), paint);
    
    // Eyes
    paint.color = Colors.black;
    canvas.drawCircle(const Offset(20, 28), 3, paint);
    canvas.drawCircle(const Offset(30, 28), 3, paint);
    
    // Mustache
    paint.color = Colors.brown[900]!;
    canvas.drawRect(Rect.fromLTWH(15, 33, 20, 5), paint);
    
    // Body (red shirt)
    paint.color = Colors.red;
    canvas.drawRect(Rect.fromLTWH(15, 40, 20, 15), paint);
    
    // Blue overalls
    paint.color = Colors.blue[900]!;
    canvas.drawRect(Rect.fromLTWH(12, 45, 8, 10), paint);
    canvas.drawRect(Rect.fromLTWH(30, 45, 8, 10), paint);
    
    // Legs (animated)
    paint.color = Colors.blue[700]!;
    if (frame == 0) {
      canvas.drawRect(Rect.fromLTWH(15, 55, 7, 5), paint);
      canvas.drawRect(Rect.fromLTWH(28, 55, 7, 5), paint);
    } else {
      canvas.drawRect(Rect.fromLTWH(13, 55, 7, 5), paint);
      canvas.drawRect(Rect.fromLTWH(30, 55, 7, 5), paint);
    }
  }
  
  @override
  bool shouldRepaint(MarioPainter oldDelegate) => oldDelegate.frame != frame;
}
