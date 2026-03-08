import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/add_expense_screen.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return HomeScreen(toggleTheme: _toggleTheme);
          }
          return const AuthScreen();
        },
      ),
    );
  }
}

// ── Login / Signup Screen ────────────────────────────────────────────────────
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill all fields');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Authentication failed');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
              ),
              obscureText: true,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    child: Text(_isLogin ? 'Login' : 'Sign Up'),
                  ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? 'Create account' : 'Already have account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── HomeScreen ───────────────────────────────────────────────────────────────
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

  List<Map<String, dynamic>> transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        transactions = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();

      setState(() {
        transactions = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;

          // Safe normalization
          data['type'] = data['type'] is String ? data['type'] : 'expense';
          data['category'] = data['category'] is String ? data['category'] : 'Others';
          data['paymentMethod'] = data['paymentMethod'] is String ? data['paymentMethod'] : 'Unknown';
          data['amount'] = (data['amount'] is num) ? (data['amount'] as num).toDouble() : 0.0;
          // date stays as-is (string or Timestamp)

          return data;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load expenses: $e')),
      );
    }
  }

  Future<void> _saveTransaction(Map<String, dynamic> transaction) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .add(transaction);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save expense: $e')),
      );
    }
  }

  Future<void> _updateTransaction(String id, Map<String, dynamic> transaction) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(id)
          .update(transaction);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update expense: $e')),
      );
    }
  }

  Future<void> _deleteTransaction(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(id)
          .delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete expense: $e')),
      );
    }
  }

  Future<void> _clearAllTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear expenses: $e')),
      );
    }
  }

  // ── Category Icons & Colors ────────────────────────────────────────────────
  static const Map<String, IconData> categoryIcons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Bills': Icons.receipt_long,
    'Entertainment': Icons.movie,
    'Health': Icons.local_hospital,
    'Education': Icons.school,
    'Others': Icons.more_horiz,
    'Salary': Icons.account_balance_wallet,
    'Freelance': Icons.work,
    'Gift': Icons.card_giftcard,
    'Refund': Icons.replay,
    'Interest': Icons.trending_up,
    'Investment Return': Icons.trending_up,
  };

  static const Map<String, Color> categoryColors = {
    'Food': Colors.red,
    'Transport': Colors.amber,
    'Shopping': Colors.purple,
    'Bills': Colors.blueGrey,
    'Entertainment': Colors.indigo,
    'Health': Colors.teal,
    'Education': Colors.blue,
    'Others': Colors.grey,
    'Salary': Colors.green,
    'Freelance': Colors.lightGreen,
    'Gift': Colors.teal,
    'Refund': Colors.cyan,
    'Interest': Colors.blue,
    'Investment Return': Colors.green,
  };

  static IconData getPaymentIcon(String? method) {
    switch (method) {
      case 'UPI': return Icons.phone_android;
      case 'Cash': return Icons.money;
      case 'Card': return Icons.credit_card;
      case 'Bank Transfer': return Icons.account_balance;
      default: return Icons.payment;
    }
  }

  DateTime? _safeParseDate(dynamic dateValue) {
    if (dateValue == null) return null;

    if (dateValue is Timestamp) {
      return dateValue.toDate();
    }

    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (_) {}
      try {
        final parts = dateValue.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            return DateTime(year, month, day);
          }
        }
      } catch (_) {}
    }
    return null;
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    return transactions.where((t) {
      final date = _safeParseDate(t['date']);
      if (date == null) return false;

      final matchesSearch = searchQuery.isEmpty ||
          (t['category'] as String? ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
          (t['note'] as String? ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
          (t['amount'] as num? ?? 0).toStringAsFixed(0).contains(searchQuery);

      if (selectedMonth == null || selectedMonth == 'All') return matchesSearch;

      final yearMonth = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      return matchesSearch && yearMonth == selectedMonth;
    }).toList()
      ..sort((a, b) {
        final da = _safeParseDate(a['date']);
        final db = _safeParseDate(b['date']);
        if (da == null || db == null) return 0;
        return db.compareTo(da);
      });
  }

  Map<String, dynamic> _getMonthlyStats() {
    final filtered = _getFilteredTransactions();

    double income = 0, expense = 0;
    Map<String, double> methodBreakdown = {};

    for (var t in filtered) {
      final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
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

  Map<String, double> _getExpenseCategoryBreakdown() {
    final filtered = _getFilteredTransactions();
    Map<String, double> categoryTotals = {};

    for (var t in filtered) {
      final type = t['type'] as String? ?? 'expense';
      if (type == 'expense') {
        final category = t['category'] as String? ?? 'Others';
        final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
        categoryTotals.update(category, (value) => value + amount, ifAbsent: () => amount);
      }
    }
    return categoryTotals;
  }

  void _showCategoryDetails(String category) {
    final filtered = _getFilteredTransactions();
    final itemsInCategory = filtered.where((t) =>
        (t['type'] as String? ?? 'expense') == 'expense' && (t['category'] as String? ?? '') == category).toList();

    final total = itemsInCategory.fold<double>(0, (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                '$category Details',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'Total: ₹${total.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: itemsInCategory.isEmpty
                    ? const Center(child: Text('No transactions found'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: itemsInCategory.length,
                        itemBuilder: (context, index) {
                          final item = itemsInCategory[index];
                          final date = _safeParseDate(item['date']);
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.arrow_outward, color: Colors.red),
                              title: Text('₹${(item['amount'] as num?)?.toDouble().toStringAsFixed(0) ?? '0'}'),
                              subtitle: Text('${date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Invalid date'} • ${item['paymentMethod'] ?? 'Unknown'}'),
                              trailing: item['note'] != null ? Text(item['note'] as String, style: const TextStyle(fontSize: 13)) : null,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getMonthlyTrendData() {
    final now = DateTime.now();
    final trend = <Map<String, dynamic>>[];

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      double income = 0, expense = 0;

      for (var t in transactions) {
        final date = _safeParseDate(t['date']);
        if (date != null && date.year == monthDate.year && date.month == monthDate.month) {
          final amt = (t['amount'] as num?)?.toDouble() ?? 0.0;
          if ((t['type'] as String? ?? 'expense') == 'income') income += amt;
          else expense += amt;
        }
      }

      trend.add({
        'month': DateFormat('MMM').format(monthDate),
        'income': income,
        'expense': expense,
      });
    }
    return trend;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentStats = _getMonthlyStats();
    final income = currentStats['income'] as double;
    final expense = currentStats['expense'] as double;
    final net = currentStats['net'] as double;
    final filtered = _getFilteredTransactions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('FLUTTER_APPLICATION_1', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        actions: [
          Switch(
            value: isDark,
            onChanged: widget.toggleTheme,
            activeColor: Colors.tealAccent,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear all transactions',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All?'),
                  content: const Text('This will delete all your transactions permanently.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _clearAllTransactions();
                        await _loadTransactions();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All transactions cleared')),
                        );
                      },
                      child: const Text('Clear', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
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
              Container(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earned ₹${income.toStringAsFixed(0)}  •  Spent ₹${expense.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 16, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Saved ₹${net.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: net >= 0 ? Colors.green[400] : Colors.red[400],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search category, note, amount...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => searchQuery = ''))
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      ),
                      onChanged: (v) => setState(() => searchQuery = v),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                      ),
                      child: DropdownButton<String>(
                        value: selectedMonth ?? 'All',
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        items: [
                          const DropdownMenuItem(value: 'All', child: Text('All Time')),
                          ...List.generate(12, (i) {
                            final d = DateTime.now().subtract(Duration(days: 30 * i));
                            final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
                            return DropdownMenuItem(value: key, child: Text(DateFormat('MMMM yyyy').format(d)));
                          }),
                        ],
                        onChanged: (v) => setState(() => selectedMonth = v),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wallet_outlined, size: 96, color: isDark ? Colors.white24 : Colors.black26),
                            const SizedBox(height: 32),
                            Text(
                              'No transactions yet',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tap the + button to add your first expense or income',
                              style: TextStyle(fontSize: 16, color: isDark ? Colors.white54 : Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final date = _safeParseDate(item['date']);
                          final isIncome = (item['type'] as String? ?? 'expense') == 'income';
                          final category = item['category'] as String? ?? 'Others';
                          final paymentMethod = item['paymentMethod'] as String? ?? 'Unknown';
                          final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;

                          final categoryIcon = categoryIcons[category] ?? Icons.more_horiz;
                          final categoryColor = categoryColors[category] ?? (isIncome ? Colors.green : Colors.red);

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: isDark ? 3 : 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              onLongPress: () async {  // Added long-press for edit (matches Phase 1 checklist)
                                final updatedItem = await Navigator.push<Map<String, dynamic>>(
                                  context,
                                  MaterialPageRoute(builder: (_) => AddExpenseScreen(initialItem: item)),
                                );

                                if (updatedItem != null) {
                                  final id = item['id'] as String?;
                                  if (id != null) {
                                    await _updateTransaction(id, updatedItem);
                                    await _loadTransactions();
                                  }
                                }
                              },
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundColor: categoryColor.withOpacity(isDark ? 0.25 : 0.15),
                                child: Icon(categoryIcon, color: categoryColor, size: 24),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    isIncome ? '+ ' : '- ',
                                    style: TextStyle(color: categoryColor, fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '₹${amount.toStringAsFixed(0)} • $category',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    Icon(getPaymentIcon(paymentMethod), size: 18, color: isDark ? Colors.white60 : Colors.black54),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$paymentMethod • ${date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Invalid date'}',
                                      style: TextStyle(fontSize: 15, color: isDark ? Colors.white60 : Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    final updatedItem = await Navigator.push<Map<String, dynamic>>(
                                      context,
                                      MaterialPageRoute(builder: (_) => AddExpenseScreen(initialItem: item)),
                                    );

                                    if (updatedItem != null) {
                                      final id = item['id'] as String?;
                                      if (id != null) {
                                        await _updateTransaction(id, updatedItem);
                                        await _loadTransactions();
                                      }
                                    }
                                  } else if (value == 'delete') {
                                    final id = item['id'] as String?;
                                    if (id != null) {
                                      final deletedItem = Map<String, dynamic>.from(item);

                                      await _deleteTransaction(id);

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Transaction deleted'),
                                          action: SnackBarAction(
                                            label: 'UNDO',
                                            onPressed: () async {
                                              await _saveTransaction(deletedItem);
                                              await _loadTransactions();
                                            },
                                          ),
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );

                                      await _loadTransactions();
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')])),
                                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                                ],
                              ),
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
        foregroundColor: Colors.white,
        elevation: 8,
        onPressed: _openAddScreen,
        child: const Icon(Icons.add, size: 32),
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
        selectedFontSize: 13,
        unselectedFontSize: 13,
        elevation: 12,
      ),
    );
  }

  void _openAddScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    ).then((result) async {
      if (result != null && result is Map<String, dynamic>) {
        await _saveTransaction(result);
        await Future.delayed(const Duration(milliseconds: 600)); // reliable refresh delay
        await _loadTransactions();
        setState(() {}); // force rebuild
      }
    });
  }

  Widget _buildSummary() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = _getMonthlyStats();
    final income = stats['income'] as double;
    final expense = stats['expense'] as double;
    final net = stats['net'] as double;

    final categoryBreakdown = _getExpenseCategoryBreakdown();

    final totalExpense = categoryBreakdown.values.fold<double>(0, (sum, value) => sum + value);

    final pieSections = categoryBreakdown.entries.map((entry) {
      final category = entry.key;
      final amount = entry.value;
      final percentage = totalExpense > 0 ? (amount / totalExpense * 100) : 0.0;
      final color = categoryColors[category] ?? Colors.grey;

      return PieChartSectionData(
        value: amount,
        title: '${category}\n₹${amount.toStringAsFixed(0)}\n${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 80,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    final monthlyTrend = _getMonthlyTrendData();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Income', income, Colors.green, isDark),
              _buildStatCard('Expense', expense, Colors.red, isDark),
              _buildStatCard('Net', net, net >= 0 ? Colors.green : Colors.red, isDark),
            ],
          ),
          const SizedBox(height: 32),
          Text('Expense Breakdown by Category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: categoryBreakdown.isEmpty
                ? Center(child: Text('No expenses this period', style: TextStyle(fontSize: 16, color: isDark ? Colors.white54 : Colors.black54)))
                : PieChart(
                    PieChartData(
                      sections: pieSections,
                      centerSpaceRadius: 50,
                      sectionsSpace: 2,
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          if (event is FlTapUpEvent && pieTouchResponse?.touchedSection != null) {
                            final touchedIndex = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                            if (touchedIndex >= 0) {
                              final category = categoryBreakdown.keys.elementAt(touchedIndex);
                              _showCategoryDetails(category);
                            }
                          }
                        },
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 32),
          Text('Legend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 12),
          ...categoryBreakdown.entries.map((entry) {
            final category = entry.key;
            final amount = entry.value;
            final color = categoryColors[category] ?? Colors.grey;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Text('$category — ₹${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 40),
          Text('Monthly Trend (Last 6 Months)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 16),
          SizedBox(
            height: 320,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: monthlyTrend.isEmpty ? 100 : monthlyTrend.map((e) => (e['income'] as double) + (e['expense'] as double)).reduce((a, b) => a > b ? a : b) * 1.1,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < monthlyTrend.length) {
                          return Text(monthlyTrend[value.toInt()]['month'], style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: monthlyTrend.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(toY: data['income'] as double, color: Colors.green, width: 16, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
                      BarChartRodData(toY: data['expense'] as double, color: Colors.red, width: 16, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, double value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 8),
          Text('₹${value.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}