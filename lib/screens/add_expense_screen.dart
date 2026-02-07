import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:intl/intl.dart';

class AddExpenseScreen extends StatefulWidget {
  final Map<String, dynamic>? initialItem;
  final int? index;
  const AddExpenseScreen({super.key, this.initialItem, this.index});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _newCategoryController = TextEditingController();

  String _type = 'expense';
  String? _category;
  String? _paymentMethod;
  DateTime _selectedDate = DateTime.now();

  // ── Category Icons & Colors ────────────────────────────────────────────────
  final Map<String, Map<String, dynamic>> _expenseCategories = {
    'Food': {'icon': Icons.restaurant, 'color': Colors.red},
    'Transport': {'icon': Icons.directions_car, 'color': Colors.amber},
    'Shopping': {'icon': Icons.shopping_bag, 'color': Colors.purple},
    'Bills': {'icon': Icons.receipt_long, 'color': Colors.blueGrey},
    'Entertainment': {'icon': Icons.movie, 'color': Colors.indigo},
    'Health': {'icon': Icons.local_hospital, 'color': Colors.teal},
    'Education': {'icon': Icons.school, 'color': Colors.blue},
    'Others': {'icon': Icons.more_horiz, 'color': Colors.grey},
  };

  final Map<String, Map<String, dynamic>> _incomeCategories = {
    'Salary': {'icon': Icons.account_balance_wallet, 'color': Colors.green},
    'Freelance': {'icon': Icons.work, 'color': Colors.lightGreen},
    'Gift': {'icon': Icons.card_giftcard, 'color': Colors.teal},
    'Refund': {'icon': Icons.replay, 'color': Colors.cyan},
    'Interest': {'icon': Icons.trending_up, 'color': Colors.blue},
    'Investment Return': {'icon': Icons.trending_up, 'color': Colors.green},
    'Others': {'icon': Icons.more_horiz, 'color': Colors.grey},
  };

  final _methods = ['UPI', 'Cash', 'Card', 'Bank Transfer'];

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

  @override
  void initState() {
    super.initState();
    if (widget.initialItem != null) {
      final item = widget.initialItem!;
      _amountController.text = item['amount'].toString();
      _category = item['category'];
      _paymentMethod = item['paymentMethod'];
      _type = item['type'] ?? 'expense';
      _selectedDate = _safeParseDate(item['date'] as String?) ?? DateTime.now();
      _noteController.text = item['note'] ?? '';
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _addCustomCategory() {
    final newCat = _newCategoryController.text.trim();
    if (newCat.isNotEmpty) {
      setState(() {
        final map = _type == 'income' ? _incomeCategories : _expenseCategories;
        if (!map.containsKey(newCat)) {
          map[newCat] = {'icon': Icons.more_horiz, 'color': Colors.grey};
        }
        _category = newCat;
        _newCategoryController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialItem != null;
    final categories = _type == 'income' ? _incomeCategories : _expenseCategories;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit' : 'Add ${_type == 'income' ? 'Income' : 'Expense'}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Expense')),
                  ButtonSegment(value: 'income', label: Text('Income')),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() {
                  _type = v.first;
                  _category = null;
                }),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final val = double.tryParse(v);
                  if (val == null || val <= 0) return 'Must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Category dropdown with icons & colors
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: categories.entries.map((entry) {
                  final cat = entry.key;
                  final data = entry.value;
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(data['icon'] as IconData, color: data['color'] as Color?, size: 24),
                        const SizedBox(width: 12),
                        Text(cat),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _newCategoryController,
                      decoration: const InputDecoration(labelText: 'Add custom category', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addCustomCategory,
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _paymentMethod = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              ListTile(
                title: Text('Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: Colors.black),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final item = {
                      'type': _type,
                      'amount': double.parse(_amountController.text),
                      'category': _category!,
                      'paymentMethod': _paymentMethod!,
                      'date': _selectedDate.toIso8601String().substring(0, 10),
                      'note': _noteController.text.isEmpty ? null : _noteController.text,
                    };
                    if (widget.index != null) {
                      transactions[widget.index!] = item;
                    } else {
                      transactions.add(item);
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(isEdit ? 'Update' : 'Save', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }
}