import 'package:flutter/material.dart';
import '../main.dart';

class AddExpenseScreen extends StatefulWidget {
  final Map<String, dynamic>? initialExpense;
  final int? index;

  const AddExpenseScreen({super.key, this.initialExpense, this.index});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _category;
  String? _paymentMethod;
  DateTime _selectedDate = DateTime.now();

  final _categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Health', 'Education', 'Others'];
  final _methods = ['UPI', 'Cash', 'Card'];

  @override
  void initState() {
    super.initState();

    if (widget.initialExpense != null) {
      _amountController.text = widget.initialExpense!['amount'].toString();
      _category = widget.initialExpense!['category'];
      _paymentMethod = widget.initialExpense!['paymentMethod'];

      try {
        final parts = widget.initialExpense!['date'].split('/');
        _selectedDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      } catch (_) {
        _selectedDate = DateTime.now();
      }

      _noteController.text = widget.initialExpense!['note'] ?? '';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _amountController.text.length),
      );
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<bool> _confirm() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirm'),
            content: const Text('Save expense?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialExpense != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Expense' : 'Add Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Must be > 0';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                hint: const Text('Select category'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                hint: const Text('Select method'),
                items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _paymentMethod = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              ListTile(
                title: Text(
                  'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[700]!),
                ),
                tileColor: Colors.grey.shade800,
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
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final ok = await _confirm();
                    if (ok) {
                      final exp = {
                        'amount': double.parse(_amountController.text),
                        'category': _category!,
                        'paymentMethod': _paymentMethod!,
                        'date': '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        'note': _noteController.text.isEmpty ? null : _noteController.text,
                      };

                      if (widget.initialExpense != null && widget.index != null) {
                        expenses[widget.index!] = exp;
                      } else {
                        expenses.add(exp);
                      }

                      Navigator.pop(context);
                    }
                  }
                },
                child: Text(isEdit ? 'Update' : 'Save'),
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
    super.dispose();
  }
}