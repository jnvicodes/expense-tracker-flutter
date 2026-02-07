import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/add_expense_screen.dart';
import 'package:intl/intl.dart';

final List<Map<String, dynamic>> transactions = [];

void main() {
  runApp(const FlutterApplication1());
}

class FlutterApplication1 extends StatefulWidget {
  const FlutterApplication1({super.key});

  @override
  State<FlutterApplication1> createState() => _FlutterApplication1State();
}

class _FlutterApplication1State extends State<FlutterApplication1> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FLUTTER_APPLICATION_1',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          bodyLarge: TextStyle(color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Colors.black54),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: const Color(0xFF1F1F1F),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
          bodyLarge: TextStyle(color: Colors.white70),
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
      ),
      home: HomeScreen(toggleTheme: _toggleTheme),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final void Function(bool isDark) toggleTheme;

  const HomeScreen({super.key, required this.toggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String searchQuery = '';
  String? selectedMonth;

  // ── Category Icons & Colors ────────────────────────────────────────────────
  static const Map<String, IconData> categoryIcons = {
    // Expense
    'Food': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Bills': Icons.receipt_long,
    'Entertainment': Icons.movie,
    'Health': Icons.local_hospital,
    'Education': Icons.school,
    'Others': Icons.more_horiz,
    // Income
    'Salary': Icons.account_balance_wallet,
    'Freelance': Icons.work,
    'Gift': Icons.card_giftcard,
    'Refund': Icons.replay,
    'Interest': Icons.trending_up,
    'Investment Return': Icons.trending_up,
  };

  static const Map<String, Color> categoryColors = {
    // Expense (warm/red tones in light, brighter in dark)
    'Food': Colors.red,
    'Transport': Colors.amber,
    'Shopping': Colors.purple,
    'Bills': Colors.blueGrey,
    'Entertainment': Colors.indigo,
    'Health': Colors.teal,
    'Education': Colors.blue,
    'Others': Colors.grey,
    // Income (green tones)
    'Salary': Colors.green,
    'Freelance': Colors.lightGreen,
    'Gift': Colors.teal,
    'Refund': Colors.cyan,
    'Interest': Colors.blue,
    'Investment Return': Colors.green,
  };

  static IconData getPaymentIcon(String? method) {
    switch (method) {
      case 'UPI':
        return Icons.phone_android;
      case 'Cash':
        return Icons.money;
      case 'Card':
        return Icons.credit_card;
      case 'Bank Transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  DateTime? _safeParseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    } catch (_) {}
    return null;
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    return transactions.where((t) {
      final date = _safeParseDate(t['date'] as String?);
      if (date == null) return false;

      final matchesSearch = searchQuery.isEmpty ||
          (t['category'] as String).toLowerCase().contains(searchQuery.toLowerCase()) ||
          (t['note'] as String? ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
          (t['amount'] as double).toStringAsFixed(0).contains(searchQuery);

      if (selectedMonth == null || selectedMonth == 'All') return matchesSearch;

      final yearMonth = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      return matchesSearch && yearMonth == selectedMonth;
    }).toList()
      ..sort((a, b) {
        final da = _safeParseDate(a['date'] as String?);
        final db = _safeParseDate(b['date'] as String?);
        if (da == null || db == null) return 0;
        return db.compareTo(da);
      });
  }

  Map<String, dynamic> _getMonthlyStats() {
    final filtered = _getFilteredTransactions();

    double income = 0, expense = 0;
    Map<String, double> methodBreakdown = {};

    for (var t in filtered) {
      final amt = t['amount'] as double;
      final type = t['type'] as String? ?? 'expense';
      final method = t['paymentMethod'] as String? ?? 'Unknown';
      if (type == 'income') income += amt;
      else expense += amt;
      methodBreakdown.update(method, (v) => v + amt, ifAbsent: () => amt);
    }

    return {
      'income': income,
      'expense': expense,
      'net': income - expense,
      'methodBreakdown': methodBreakdown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStats = _getMonthlyStats();
    final income = currentStats['income'] as double;
    final expense = currentStats['expense'] as double;
    final net = currentStats['net'] as double;
    final filtered = _getFilteredTransactions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('FLUTTER_APPLICATION_1'),
        centerTitle: true,
        elevation: 0,
        actions: [
          Switch(
            value: isDark,
            onChanged: widget.toggleTheme,
            activeColor: Colors.teal,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              setState(() => transactions.clear());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All cleared')),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earned ₹${income.toStringAsFixed(0)}, Spent ₹${expense.toStringAsFixed(0)} → Saved ₹${net.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: net >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Search (category, note, amount)',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                            ),
                            onChanged: (v) => setState(() => searchQuery = v),
                          ),
                        ),
                        if (searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => searchQuery = ''),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<String>(
                      value: selectedMonth ?? 'All',
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: 'All', child: Text('All Time')),
                        ...List.generate(12, (i) {
                          final d = DateTime.now().subtract(Duration(days: 30 * i));
                          final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
                          return DropdownMenuItem(
                            value: key,
                            child: Text(DateFormat('MMMM yyyy').format(d)),
                          );
                        }),
                      ],
                      onChanged: (v) => setState(() => selectedMonth = v),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No matching transactions'))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final date = _safeParseDate(item['date'] as String?);
                          final isIncome = (item['type'] as String? ?? 'expense') == 'income';
                          final category = item['category'] as String;
                          final paymentMethod = item['paymentMethod'] as String? ?? 'Unknown';

                          final categoryIcon = categoryIcons[category] ?? Icons.more_horiz;
                          final categoryColor = categoryColors[category] ?? (isIncome ? Colors.green : Colors.red);

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: categoryColor.withOpacity(isDark ? 0.25 : 0.15),
                                child: Icon(
                                  categoryIcon,
                                  color: categoryColor,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    isIncome ? '+ ' : '- ',
                                    style: TextStyle(color: categoryColor, fontWeight: FontWeight.bold),
                                  ),
                                  Text('₹${(item['amount'] as double).toStringAsFixed(0)} • $category'),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Icon(
                                    getPaymentIcon(paymentMethod),
                                    size: 16,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                  const SizedBox(width: 4),
                                  Text('$paymentMethod • ${date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Invalid date'}'),
                                ],
                              ),
                              trailing: item['note'] != null ? const Icon(Icons.note_alt) : null,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AddExpenseScreen(initialItem: item, index: transactions.indexOf(item))),
                              ).then((_) => setState(() {})),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          _buildSummary(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isDark ? Colors.teal : Colors.black,
        onPressed: _openAddScreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Summary'),
        ],
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor: isDark ? Colors.teal : Colors.black,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  void _openAddScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    ).then((_) => setState(() {}));
  }

  Widget _buildSummary() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart, size: 80, color: Colors.grey),
          SizedBox(height: 24),
          Text('Summary & Charts', style: TextStyle(fontSize: 24)),
          SizedBox(height: 8),
          Text('Coming soon...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}