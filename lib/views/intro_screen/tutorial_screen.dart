import 'package:flutter/material.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({Key? key}) : super(key: key);

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  static const _gifAssets = [
    'assets/gifs/swipe_up.gif',
    'assets/gifs/swipe_right.gif',
    'assets/gifs/headline.gif',
    'assets/gifs/speaker.gif',
    'assets/gifs/redirect.gif',
    'assets/gifs/chatbot.gif',
  ];

  static const _labels = [
    'Swipe up to read more news',
    'Swipe right to open dashboard',
    'Tap headline to bookmark news',
    'Tap speaker icon to hear news',
    'Tap this icon to open full article',
    'Tap AI button to chat with assistant',
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step < _gifAssets.length - 1) {
      _fadeCtrl.reverse().then((_) {
        setState(() => _step++);
        _fadeCtrl.forward();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Phone container dimensions
    final containerWidth = size.width * 0.85;
    final containerHeight = containerWidth * 16 / 9;
    // Center Y of container
    final containerTop = (size.height - containerHeight) / 2;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _nextStep,
        child: Stack(
          children: [
            // Centered phone-screen container
            Positioned(
              top: containerTop,
              left: (size.width - containerWidth) / 2,
              width: containerWidth,
              height: containerHeight,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Image.asset(
                      _gifAssets[_step],
                      fit: BoxFit.cover,
                      repeat: ImageRepeat.repeat,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
            ),

            // Instruction box just below container
            Positioned(
              top: containerTop + containerHeight + 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF29C0FF).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  _labels[_step],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Step status at the very top
            Positioned(
              top: size.height * 0.06,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Step ${_step + 1} of ${_gifAssets.length} • Tap anywhere to continue',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
