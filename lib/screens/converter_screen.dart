import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  // --- UI COLORS & DESIGN ANCHORS ---
  static const Color orange = Color(0xFFD36B28);
  static const Color darkGray = Color(0xFF1A1A1A);
  static const Color gridColor = Color(0xFF2A2A2A);
  static const Color accentBrown = Color(0xFF4A2A18);

  // --- CATEGORY DATA ---
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Length', 'icon': Icons.straighten},
    {'name': 'Temp', 'icon': Icons.thermostat_outlined},
    {'name': 'Weight', 'icon': Icons.fitness_center_outlined},
    {'name': 'Currency', 'icon': Icons.attach_money},
  ];

  // --- CONVERSION RATES ---
  final Map<String, double> _lengthRates = {
    'Meters': 1.0, 'Feet': 3.28084, 'Inches': 39.3701, 'Kilometers': 0.001,
  };
  final Map<String, double> _weightRates = {
    'Kilograms': 1.0, 'Grams': 1000.0, 'Pounds': 2.20462, 'Ounces': 35.274,
  };
  final List<String> _tempUnits = ['Celsius', 'Fahrenheit', 'Kelvin'];
  
  // Currency rates are no longer final so the API can update them dynamically
  Map<String, double> _currencyRates = {
    'US Dollar': 1.0, 'Euro': 0.92, 'British Pound': 0.79, 'Japanese Yen': 150.0, 'Pakistani Rupee': 278.0, 
  };
  bool _isFetchingAPI = false;

  // --- STATE VARIABLES ---
  String _currentCategory = 'Length';
  late String _fromUnit;
  late String _toUnit;
  final TextEditingController _fromController = TextEditingController(text: "1");
  final TextEditingController _toController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fromUnit = 'Meters';
    _toUnit = 'Feet';
    
    // Defer the initial calculation until after the first frame to prevent startup crashes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateConversion();
      _fetchLiveCurrencyRates(); // Pull real-time data silently in the background
    });
  }

  // --- LIVE INTERNET API ---
  Future<void> _fetchLiveCurrencyRates() async {
    setState(() => _isFetchingAPI = true);
    try {
      // Connect to a free, open exchange rate API
      final request = await HttpClient().getUrl(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        final rates = data['rates'] as Map<String, dynamic>;
        
        if (mounted) {
          setState(() {
            _currencyRates = {
              'US Dollar': 1.0,
              'Euro': (rates['EUR'] ?? 0.92).toDouble(),
              'British Pound': (rates['GBP'] ?? 0.79).toDouble(),
              'Japanese Yen': (rates['JPY'] ?? 150.0).toDouble(),
              'Pakistani Rupee': (rates['PKR'] ?? 278.0).toDouble(),
              'Canadian Dollar': (rates['CAD'] ?? 1.35).toDouble(),
              'Australian Dollar': (rates['AUD'] ?? 1.50).toDouble(),
            };
          });
          // If the user is already looking at Currency, instantly update the numbers
          if (_currentCategory == 'Currency') _calculateConversion();
        }
      }
    } catch (e) {
      // If no internet, silently fail and use the offline fallback rates
    } finally {
      if (mounted) setState(() => _isFetchingAPI = false);
    }
  }

  List<String> get _activeUnits {
    switch (_currentCategory) {
      case 'Temp': return _tempUnits;
      case 'Weight': return _weightRates.keys.toList();
      case 'Currency': return _currencyRates.keys.toList();
      default: return _lengthRates.keys.toList();
    }
  }

  // --- CORE LOGIC ENGINE ---
  void _switchCategory(String newCategory) {
    if (_currentCategory == newCategory) return;
    
    setState(() {
      _currentCategory = newCategory;
      final units = _activeUnits;
      _fromUnit = units[0];
      _toUnit = units[1];
      _fromController.text = "1";
      _calculateConversion();
    });
  }

  // Pure math function to prevent state-build crashes
  double _calculateRawValue(double inputVal, String from, String to, String category) {
    if (category == 'Temp') {
      if (from == 'Celsius' && to == 'Fahrenheit') return (inputVal * 9 / 5) + 32;
      if (from == 'Celsius' && to == 'Kelvin') return inputVal + 273.15;
      if (from == 'Fahrenheit' && to == 'Celsius') return (inputVal - 32) * 5 / 9;
      if (from == 'Fahrenheit' && to == 'Kelvin') return (inputVal - 32) * 5 / 9 + 273.15;
      if (from == 'Kelvin' && to == 'Celsius') return inputVal - 273.15;
      if (from == 'Kelvin' && to == 'Fahrenheit') return (inputVal - 273.15) * 9 / 5 + 32;
      return inputVal;
    } else {
      Map<String, double> activeRates = category == 'Weight' ? _weightRates : (category == 'Currency' ? _currencyRates : _lengthRates);
      double baseValue = inputVal / (activeRates[from] ?? 1.0); 
      return baseValue * (activeRates[to] ?? 1.0);      
    }
  }

  void _calculateConversion() {
    setState(() {
      final String input = _fromController.text.trim();
      if (input.isEmpty) {
        _toController.clear();
        return;
      }
      final double fromValue = double.tryParse(input) ?? 0;
      double result = _calculateRawValue(fromValue, _fromUnit, _toUnit, _currentCategory);
      _toController.text = _formatValue(result);
    });
  }

  void _swapUnits() {
    setState(() {
      final tempUnit = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = tempUnit;

      final tempValue = _fromController.text;
      _fromController.text = _toController.text;
      _toController.text = tempValue;
      
      _calculateConversion();
    });
  }

  // Crash-proof formatter (No more .toInt() errors on huge numbers)
  String _formatValue(double value) {
    if (value.isNaN || value.isInfinite) return "0";
    String str = value.toStringAsFixed(5);
    if (str.contains('.')) str = str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return str;
  }

  // --- UI BUILD METHODS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 30),
              _buildCategoryChips(),
              const SizedBox(height: 30),
              _buildMainConverterCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unit Converter', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
        SizedBox(height: 4),
        Text('Fast, accurate calculations', style: TextStyle(color: orange, fontSize: 13)),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          bool isSelected = _currentCategory == cat['name'];
          
          return GestureDetector(
            onTap: () => _switchCategory(cat['name']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? accentBrown : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? orange : gridColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(cat['icon'], color: isSelected ? orange : Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(cat['name'], style: TextStyle(color: isSelected ? orange : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainConverterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: darkGray, borderRadius: BorderRadius.circular(24), border: Border.all(color: gridColor)),
      child: CustomPaint(
        painter: GridPainter(color: gridColor.withOpacity(0.4)),
        child: Column(
          children: [
            Row(
              children: [
                Icon(_categories.firstWhere((c) => c['name'] == _currentCategory)['icon'], color: orange),
                const SizedBox(width: 12),
                Text('$_currentCategory Converter', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 32),
            _buildInputSection('From', _fromController, _fromUnit, (newUnit) => setState(() { _fromUnit = newUnit; _calculateConversion(); })),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Divider(color: gridColor),
                  IconButton(
                    onPressed: _swapUnits,
                    icon: const Icon(Icons.swap_vert, color: orange, size: 28),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF0A0A0A), padding: const EdgeInsets.all(12), side: const BorderSide(color: gridColor)),
                  ),
                ],
              ),
            ),

            _buildInputSection('To', _toController, _toUnit, (newUnit) => setState(() { _toUnit = newUnit; _calculateConversion(); }), isReadOnly: true),
            const SizedBox(height: 32),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(String label, TextEditingController controller, String currentUnit, ValueChanged<String> onUnitChanged, {bool isReadOnly = false}) {
    const double targetHeight = 72.0; 
    final BorderRadius roundedEdges = BorderRadius.circular(16);
    const Color inputBg = Color(0xFF0A0A0A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                height: targetHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft, 
                decoration: BoxDecoration(color: inputBg, borderRadius: roundedEdges, border: Border.all(color: isReadOnly ? orange : gridColor, width: isReadOnly ? 2.0 : 1.5)),
                child: TextField(
                  controller: controller,
                  readOnly: isReadOnly,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: isReadOnly ? null : (_) => _calculateConversion(),
                  style: TextStyle(fontSize: isReadOnly ? 42 : 32, fontWeight: FontWeight.bold, color: isReadOnly ? orange : Colors.white),
                  decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true, hintText: '0', hintStyle: TextStyle(color: gridColor)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Container(
                height: targetHeight,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center, 
                decoration: BoxDecoration(color: darkGray, borderRadius: roundedEdges, border: Border.all(color: gridColor, width: 1.5)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentUnit,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: orange, size: 22),
                    dropdownColor: darkGray,
                    borderRadius: roundedEdges,
                    menuMaxHeight: 300,
                    items: _activeUnits.map((String unit) {
                      return DropdownMenuItem<String>(value: unit, child: Text(unit, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)));
                    }).toList(),
                    onChanged: (String? newValue) { if (newValue != null) onUnitChanged(newValue); },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend() {
    if (_currentCategory == 'Currency' && _isFetchingAPI) {
      return const Text('Fetching live rates...', style: TextStyle(color: orange, fontStyle: FontStyle.italic));
    }

    double rate = _calculateRawValue(1.0, _fromUnit, _toUnit, _currentCategory);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('1 $_fromUnit', style: const TextStyle(color: orange, fontWeight: FontWeight.bold)),
        const Text(' = ', style: TextStyle(color: Colors.white)),
        Text('${_formatValue(rate)} $_toUnit', style: const TextStyle(color: Colors.white70)),
      ],
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