import 'package:flutter/material.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _output = "0";
  String _equation = "";
  String _operand = "";
  double _num1 = 0;
  double _num2 = 0;

  // --- CALCULATOR LOGIC ---
  void _buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == "C") {
        _output = "0";
        _equation = "";
        _num1 = 0;
        _num2 = 0;
        _operand = "";
      } else if (buttonText == "⌫") {
        if (_output.length > 1) {
          _output = _output.substring(0, _output.length - 1);
        } else {
          _output = "0";
        }
      } else if (buttonText == "+/-") {
        if (_output != "0") {
          if (_output.startsWith("-")) {
            _output = _output.substring(1);
          } else {
            _output = "-$_output";
          }
        }
      } else if (buttonText == "+" || buttonText == "-" || buttonText == "×" || buttonText == "÷") {
        _num1 = double.tryParse(_output) ?? 0;
        _operand = buttonText;
        _equation = "$_output $_operand";
        _output = "0";
      } else if (buttonText == ".") {
        if (!_output.contains(".")) {
          _output = _output + buttonText;
        }
      } else if (buttonText == "=") {
        _num2 = double.tryParse(_output) ?? 0;

        switch (_operand) {
          case "+":
            _output = (_num1 + _num2).toString();
            break;
          case "-":
            _output = (_num1 - _num2).toString();
            break;
          case "×":
            _output = (_num1 * _num2).toString();
            break;
          case "÷":
            _output = _num2 != 0 ? (_num1 / _num2).toString() : "Error";
            break;
        }

        // Clean up trailing zeros (e.g., 5.0 becomes 5)
        if (_output.endsWith(".0")) {
          _output = _output.substring(0, _output.length - 2);
        }

        _equation = "";
        _operand = "";
      } else {
        // Typing numbers
        if (_output == "0" || _output == "Error") {
          _output = buttonText;
        } else {
          _output = _output + buttonText;
        }
      }
    });
  }

  // --- UI WIDGETS ---
  Widget _buildButton(String text, {Color? textColor, Color? bgColor}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: InkWell(
          onTap: () => _buttonPressed(text),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            height: 75,
            decoration: BoxDecoration(
              color: bgColor ?? const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Inherits deep black from main_shell
      body: Column(
        children: [
          // 1. The Display Area
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _equation,
                    style: const TextStyle(fontSize: 24, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _output,
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          
          // 2. The Keypad Area
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF0A0A0A), // Extra layer to separate from display
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildButton("C", textColor: Colors.grey.shade400),
                      _buildButton("+/-", textColor: Colors.grey.shade400),
                      _buildButton("⌫", textColor: Colors.grey.shade400),
                      _buildButton("÷", textColor: const Color(0xFFD36B28)),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton("7"),
                      _buildButton("8"),
                      _buildButton("9"),
                      _buildButton("×", textColor: const Color(0xFFD36B28)),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton("4"),
                      _buildButton("5"),
                      _buildButton("6"),
                      _buildButton("-", textColor: const Color(0xFFD36B28)),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton("1"),
                      _buildButton("2"),
                      _buildButton("3"),
                      _buildButton("+", textColor: const Color(0xFFD36B28)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: InkWell(
                            onTap: () => _buttonPressed("0"),
                            borderRadius: BorderRadius.circular(20),
                            child: Ink(
                              height: 75,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF2A2A2A)),
                              ),
                              child: const Center(
                                child: Text("0", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _buildButton("."),
                      _buildButton("=", textColor: Colors.white, bgColor: const Color(0xFFD36B28)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}