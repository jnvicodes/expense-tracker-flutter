import 'package:flutter/material.dart';
import 'screens/add_expense_screen.dart';

// Global in-memory list
final List<Map<String, dynamic>> expenses = [];

void main() {
  runApp(const ExpenseApp());
}

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
        cardColor: Colors.grey.shade800,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showOptionsBottomSheet(BuildContext context, Map<String, dynamic> exp, int originalIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blueAccent),
            title: const Text('Edit Expense', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddExpenseScreen(
                    initialExpense: exp,
                    index: originalIndex,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.redAccent),
            title: const Text('Delete Expense', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);

              final deletedExpense = Map<String, dynamic>.from(exp);

              setState(() {
                expenses.removeAt(originalIndex);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Expense deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      setState(() {
                        expenses.insert(originalIndex, deletedExpense);
                      });
                    },
                  ),
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reversedExpenses = expenses.reversed.toList();
    final double total = expenses.fold<double>(0, (sum, e) => sum + (e['amount'] as double));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            tooltip: 'Clear all (debug)',
            onPressed: () {
              setState(() {
                expenses.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All expenses cleared'),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: expenses.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 24),
                  Text('No expenses yet', style: TextStyle(fontSize: 24)),
                  SizedBox(height: 8),
                  Text('Tap + to add one', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  color: Colors.teal.withOpacity(0.15),
                  child: Text(
                    'Total: ₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    itemCount: reversedExpenses.length,
                    itemBuilder: (context, index) {
                      final exp = reversedExpenses[index];
                      final originalIndex = expenses.length - 1 - index;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.teal.shade800,
                            child: Text(
                              exp['category'][0],
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            '₹${(exp['amount'] as double).toStringAsFixed(2)} - ${exp['category']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${exp['paymentMethod']} • ${exp['date']}',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                          trailing: exp['note'] != null
                              ? Icon(Icons.note_alt_outlined, size: 20, color: Colors.grey[400])
                              : null,
                          onTap: () => _showOptionsBottomSheet(context, exp, originalIndex),
                          onLongPress: () => _showOptionsBottomSheet(context, exp, originalIndex),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          ).then((_) => setState(() {}));
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}