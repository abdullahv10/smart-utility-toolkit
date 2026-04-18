import 'package:flutter/material.dart';
import 'package:toolkit/screens/calculator_screen.dart';
import 'package:toolkit/screens/timer_screen.dart';
import 'package:toolkit/screens/todo_screen.dart';
import 'converter_screen.dart'; // Import the new screen!

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // These are placeholders. We will replace them with real screens!
  final List<Widget> _screens = [
    const ConverterScreen(),
    const TimerScreen(),
    const CalculatorScreen(),
    const TodoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _screens[_currentIndex], // Shows the active screen
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 1)),
        ),
        // 1. Wrap the BottomNavigationBar in a Theme
        child: Theme(
          // 2. Copy the current theme but make tap animations transparent
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            backgroundColor: const Color(0xFF0A0A0A),
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            selectedItemColor: const Color(0xFFD36B28), // The signature orange
            unselectedItemColor: Colors.grey.shade700,
            showUnselectedLabels: true,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Converter'),
              BottomNavigationBarItem(icon: Icon(Icons.timer_outlined), label: 'Timer'),
              BottomNavigationBarItem(icon: Icon(Icons.calculate_outlined), label: 'Calculator'),
              BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Tasks'),
            ],
          ),
        ),
      ),
    );
  }
}