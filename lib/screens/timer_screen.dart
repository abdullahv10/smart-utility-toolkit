import 'dart:async';
import 'package:flutter/material.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // --- UI Colors ---
  static const orange = Color(0xFFD36B28);
  static const darkGray = Color(0xFF1A1A1A);
  static const gridColor = Color(0xFF2A2A2A);

  // --- Toggle State ---
  bool _isCountdownMode = false; // Starts on Stopwatch based on your screenshot

  // --- Countdown State ---
  Timer? _countdownTimer;
  int _countdownSeconds = 0;
  bool _isCountdownRunning = false;
  final List<int> _presets = [60, 300, 600, 900, 1800]; 

  // --- Stopwatch State ---
  Timer? _stopwatchTimer;
  int _elapsedMs = 0;
  bool _isStopwatchRunning = false;

  // --- Logic Methods ---
  void _toggleMode(bool toCountdown) {
    setState(() {
      _isCountdownMode = toCountdown;
      // Stop everything when switching modes
      _stopCountdown();
      _stopStopwatch();
    });
  }

  void _startCountdown() {
    if (_countdownSeconds > 0 && !_isCountdownRunning) {
      setState(() => _isCountdownRunning = true);
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_countdownSeconds > 0) {
          setState(() => _countdownSeconds--);
        } else {
          _stopCountdown();
        }
      });
    }
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    setState(() => _isCountdownRunning = false);
  }

  void _startStopwatch() {
    if (!_isStopwatchRunning) {
      setState(() => _isStopwatchRunning = true);
      _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
        setState(() => _elapsedMs += 30);
      });
    }
  }

  void _stopStopwatch() {
    _stopwatchTimer?.cancel();
    setState(() => _isStopwatchRunning = false);
  }

  String _formatCountdown(int sec) {
    return '${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}';
  }

  String _formatStopwatch(int ms) {
    int mins = ms ~/ 60000;
    int secs = (ms % 60000) ~/ 1000;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _stopwatchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header
              const Text('Timer & Stopwatch', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('Track time with precision', style: TextStyle(color: orange, fontSize: 13)),
              
              const SizedBox(height: 30),
              
              // Mode Switcher
              Row(
                children: [
                  _buildTab('Stopwatch', Icons.timer_outlined, !_isCountdownMode),
                  const SizedBox(width: 12),
                  _buildTab('Countdown', Icons.av_timer_outlined, _isCountdownMode),
                ],
              ),

              const SizedBox(height: 30),

              // The Main Display Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: darkGray, borderRadius: BorderRadius.circular(24), border: Border.all(color: gridColor)),
                child: CustomPaint(
                  painter: GridPainter(color: gridColor.withOpacity(0.4)),
                  child: Column(
                    children: [
                      Text(_isCountdownMode ? "COUNTDOWN" : "STOPWATCH", style: const TextStyle(color: orange, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
                      const SizedBox(height: 20),
                      Text(
                        _isCountdownMode ? _formatCountdown(_countdownSeconds) : _formatStopwatch(_elapsedMs),
                        style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1),
                      ),
                      
                      const SizedBox(height: 30),

                      // Show presets ONLY if in countdown mode
                      if (_isCountdownMode) ...[
                        _buildPresets(),
                        const SizedBox(height: 30),
                      ],

                      // Control Buttons (Now correctly spaced!)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMainBtn(
                            label: _isCountdownMode 
                                ? (_isCountdownRunning ? 'Pause' : 'Start')
                                : (_isStopwatchRunning ? 'Stop' : 'Start'),
                            icon: _isCountdownMode 
                                ? (_isCountdownRunning ? Icons.pause : Icons.play_arrow)
                                : (_isStopwatchRunning ? Icons.stop : Icons.play_arrow),
                            onTap: _isCountdownMode 
                                ? (_isCountdownRunning ? _stopCountdown : _startCountdown)
                                : (_isStopwatchRunning ? _stopStopwatch : _startStopwatch),
                            isPrimary: true,
                          ),
                          const SizedBox(width: 16),
                          _buildMainBtn(
                            label: 'Reset',
                            icon: Icons.refresh,
                            onTap: () {
                              _isCountdownMode ? setState(() => _countdownSeconds = 0) : setState(() => _elapsedMs = 0);
                              _stopCountdown(); _stopStopwatch();
                            },
                            isPrimary: false,
                          ),
                        ],
                      )
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

  Widget _buildTab(String label, IconData icon, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _toggleMode(label == 'Countdown'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2A1C14) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? orange : gridColor, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? orange : Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: selected ? orange : Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresets() {
    return Wrap(
      spacing: 10, runSpacing: 10,
      alignment: WrapAlignment.center,
      children: _presets.map((s) => GestureDetector(
        onTap: () => setState(() => _countdownSeconds = s),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: gridColor)),
          child: Text('${s ~/ 60}m', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
      )).toList(),
    );
  }

  Widget _buildMainBtn({required String label, required IconData icon, required VoidCallback onTap, required bool isPrimary}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? orange : darkGray,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: gridColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 0.5;
    for (double i = 0; i < size.width; i += 35) { canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint); }
    for (double i = 0; i < size.height; i += 35) { canvas.drawLine(Offset(0, i), Offset(size.width, i), paint); }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}