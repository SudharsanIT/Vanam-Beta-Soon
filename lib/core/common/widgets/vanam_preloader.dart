import 'package:flutter/material.dart';

class VanamPreloader extends StatefulWidget {
  final bool isDark;

  const VanamPreloader({super.key, required this.isDark});

  @override
  State<VanamPreloader> createState() => _VanamPreloaderState();
}

class _VanamPreloaderState extends State<VanamPreloader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // 🔥 அனிமேஷன் 3 நொடிகள் (Slow) 'ஒரே ஒரு முறை' (forward) மட்டும் ஓடும்!
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    // அனிமேஷனை ஸ்டார்ட் பண்றோம் (No repeat)
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theme-க்கு ஏத்த Background Color
    final bgColor = widget.isDark ? const Color(0xFF07110D) : const Color(0xFFF4F8F5);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        // 🔥 SHADER MASK: லோகோ மேல மட்டும் அந்த Golden Shine-ஐ அப்ளை பண்ணும்!
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment(_animation.value - 1, -1.0),
                  end: Alignment(_animation.value + 1, 1.0),
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    const Color(0xFFFFD700).withOpacity(0.8), // Golden Shine
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                ).createShader(bounds);
              },
              child: child,
            );
          },
          // 🔥 சின்னதா சென்டர்ல உன்னோட லோகோ இமேஜ்
          child: SizedBox(
            width: 350, // உனக்கு தேவையான அளவு சின்னதா ஆக்கிக்கோ
            height: 350,
            // உன்னோட மான் லோகோ எங்க இருக்கோ அந்த File Path-ஐ இங்க போடு
            child: Image.asset(
              'assets/images/logo.png', // <--- IMPORTANT: உன்னோட லோகோ Asset Path-ஐ இங்க மாத்து
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // ஒருவேளை asset path தப்பா இருந்தா Error வராம இருக்க Backup Icon
                return const Icon(Icons.eco_rounded, size: 100, color: Color(0xFF9BE15D));
              },
            ),
          ),
        ),
      ),
    );
  }
}