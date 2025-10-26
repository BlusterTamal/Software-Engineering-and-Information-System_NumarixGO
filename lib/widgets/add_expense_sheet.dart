/*
 * File: lib/widgets/add_expense_sheet.dart
 * Location: /c:/Users/Tamal/Documents/smart_numerix_v2/lib/widgets/add_expense_sheet.dart
 * Description: Bottom sheet for adding/editing expenses
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../features/cost_calculator_page.dart';

class _ExpenseInputControllers {
  final TextEditingController typeController;
  final TextEditingController descriptionController;
  final TextEditingController costController;

  _ExpenseInputControllers()
      : typeController = TextEditingController(),
        descriptionController = TextEditingController(),
        costController = TextEditingController();

  void dispose() {
    typeController.dispose();
    descriptionController.dispose();
    costController.dispose();
  }
}

class AddExpenseSheet extends StatefulWidget {
  final DateTime selectedDate;
  const AddExpenseSheet({super.key, required this.selectedDate});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final List<_ExpenseInputControllers> _controllers = [];
  final ScrollController _scrollController = ScrollController();
  final List<String> _commonTypes = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Health',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _addNewRow();
  }

  @override
  void dispose() {
    for (var controllerSet in _controllers) {
      controllerSet.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _addNewRow() {
    setState(() {
      _controllers.add(_ExpenseInputControllers());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeRow(int index) {
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  void _saveExpenses() {
    final List<Expense> newExpenses = [];
    for (var controllerSet in _controllers) {
      final cost = double.tryParse(controllerSet.costController.text) ?? 0;
      final type = controllerSet.typeController.text.isEmpty
          ? 'General'
          : controllerSet.typeController.text;
      final description = controllerSet.descriptionController.text;

      if (cost > 0) {
        newExpenses.add(
          Expense(
            id: DateTime.now().millisecondsSinceEpoch.toString() +
                newExpenses.length.toString(),
            date: widget.selectedDate,
            type: type,
            description: description,
            cost: cost,
          ),
        );
      }
    }
    Navigator.pop(context, newExpenses);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(),
      child: Padding(
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
              color: const Color(0xFF16213E).withOpacity(0.9),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(color: Colors.white.withOpacity(0.2))),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildExpenseInputList(),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add Expenses for ${DateFormat('dd MMM, yyyy').format(widget.selectedDate)}',
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseInputList() {
    return Flexible(
      child: ListView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        itemCount: _controllers.length,
        itemBuilder: (context, index) {
          return _buildExpenseRow(_controllers[index], index);
        },
      ),
    );
  }

  Widget _buildExpenseRow(_ExpenseInputControllers controllerSet, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Cost Item ${index + 1}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (index > 0) // Don't allow deleting the first row
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                  onPressed: () => _removeRow(index),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // --- Cost Type Field (with suggestions) ---
          Text('Cost Type',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          _buildTypeField(controllerSet.typeController),
          const SizedBox(height: 12),
          Row(
            children: [
              // --- Description Field ---
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Description (Optional)',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    _buildTextField(
                      controller: controllerSet.descriptionController,
                      hint: 'e.g., Groceries',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // --- Cost Field ---
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cost',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    _buildTextField(
                      controller: controllerSet.costController,
                      hint: '0.00',
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(controller: controller, hint: 'e.g., Food'),
        const SizedBox(height: 8),
        // Quick select chips
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _commonTypes
              .map((type) => InkWell(
            onTap: () {
              controller.text = type;
            },
            child: Chip(
              label: Text(type),
              backgroundColor: Colors.white.withOpacity(0.2),
              labelStyle: const TextStyle(color: Colors.white),
              padding: const EdgeInsets.all(4),
            ),
          ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        isDense: true,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // "Add Item" Button
          Expanded(
            child: TextButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Another Item'),
              onPressed: _addNewRow,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // "Save" Button
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save'),
              onPressed: _saveExpenses,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}