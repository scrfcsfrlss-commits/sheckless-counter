import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShecklessCounterApp());
}

class ShecklessCounterApp extends StatelessWidget {
  const ShecklessCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sheckless Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const CounterScreen(),
    );
  }
}

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  double _total = 0.0;
  int _count = 0;
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadPersistedData();
  }

  Future<void> _loadPersistedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _total = prefs.getDouble('counter_total') ?? 0.0;
      _count = prefs.getInt('counter_count') ?? 0;
    });
  }

  Future<void> _savePersistedData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('counter_total', _total);
    await prefs.setInt('counter_count', _count);
  }

  String _formatCurrency(double val) {
    if (val == 0) return "€0";
    double absVal = val.abs();
    String suffix = "";
    double formattedVal = val;

    if (absVal >= 1e12) {
      formattedVal = val / 1e12;
      suffix = "T";
    } else if (absVal >= 1e9) {
      formattedVal = val / 1e9;
      suffix = "B";
    } else if (absVal >= 1e6) {
      formattedVal = val / 1e6;
      suffix = "M";
    } else if (absVal >= 1e3) {
      formattedVal = val / 1e3;
      suffix = "K";
    }

    String numStr = formattedVal.toStringAsFixed(2);
    if (numStr.contains('.')) {
      numStr = numStr.replaceAll(RegExp(r'0+$'), '');
      if (numStr.endsWith('.')) {
        numStr = numStr.substring(0, numStr.length - 1);
      }
    }
    return "€$numStr$suffix";
  }

  void _handleInputSubmit() {
    final double? enteredVal = double.tryParse(_inputController.text);
    if (enteredVal == null || enteredVal <= 0) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid positive amount."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _total += (enteredVal * 1000000);
      _count += 1;
      _inputController.clear();
    });

    _savePersistedData();
    HapticFeedback.lightCheck();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Transaction Added: +${_formatCurrency(enteredVal * 1000000)}"),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showResetConfirmation() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Reset Counter"),
          content: const Text("Are you sure you want to reset all data?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _total = 0.0;
                  _count = 0;
                  _inputController.clear();
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                HapticFeedback.heavyImpact();
              },
              child: const Text("Reset", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          "COUNTER",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Total display layout card
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Total Amount",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.slate400 : Colors.slate500,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatCurrency(_total),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(width: 40, height: 2, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        "Transactions",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.slate400 : Colors.slate500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Count: $_count",
                        style: const TextStyle(
                          fontSize: 20,
                          fontFamily: "monospace",
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Entry and action block
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  top: BorderSide(color: isDark ? Colors.slate800 : Colors.grey.shade200),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Input text field
                  TextField(
                    controller: _inputController,
                    focusNode: _focusNode,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "Amount (e.g. 1.5)",
                      suffixText: "M",
                      suffixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions Group (2fr Input, 1fr Reset)
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _handleInputSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "INPUT",
                            style: TextStyle(fontWeight: FontWeight.extrabold, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          onPressed: _showResetConfirmation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "RESET",
                            style: TextStyle(fontWeight: FontWeight.extrabold, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
