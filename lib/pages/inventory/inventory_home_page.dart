import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import 'package:medicare/Providers/UserProvides.dart';
import 'package:medicare/Providers/inventoryProvider.dart';
import 'package:medicare/theme/app_theme.dart';

class InventoryHomePage extends ConsumerStatefulWidget {
  const InventoryHomePage({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  ConsumerState<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends ConsumerState<InventoryHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryProvider.notifier).setInventoryItems();
    });
  }

  Future<void> _signOut() async {
    await ref.read(appStateProvider.notifier).signOutUser();
  }

  Future<void> _refresh() async {
    ref.read(inventoryProvider.notifier).setInventoryItems();
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  void _showAddItemDialog() {
    Get.dialog(
      _AddInventoryItemDialog(
        onSubmit: (name, description, quantity, price) {
          ref
              .read(inventoryProvider.notifier)
              .addInventoryItem(name, description, quantity, price);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inventory · ${widget.user['name'] ?? widget.user['email'] ?? ''}',
        ),
        actions: [
          TextButton.icon(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: AppColors.secondary),
            label: const Text('Sign out'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('Add item'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: Get.width * 0.04,
            vertical: Get.height * 0.03,
          ),
          children: [
            _SectionHeader(title: 'Inventory items (${items.length})'),
            if (items.isEmpty)
              const _EmptyState(
                message: 'Inventory is empty. Add your first item.',
              )
            else
              ...items.map(
                (inventoryItem item) => _InventoryCard(item: item, ref: ref),
              ),
          ],
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.item, required this.ref});

  final inventoryItem item;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.itemName ?? 'Untitled item',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (item.itemId != null) {
                      ref
                          .read(inventoryProvider.notifier)
                          .deleteInventoryItem(item.itemId!);
                    }
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.itemDescription ?? 'No description provided'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              children: [
                _InfoPill(
                  icon: Icons.inventory_2_outlined,
                  label: 'Quantity',
                  value: (item.quantity ?? 0).toString(),
                ),
                _InfoPill(
                  icon: Icons.attach_money,
                  label: 'Price',
                  value: item.price != null
                      ? item.price!.toStringAsFixed(2)
                      : 'Not set',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddInventoryItemDialog extends StatefulWidget {
  const _AddInventoryItemDialog({required this.onSubmit});

  final void Function(
    String name,
    String description,
    int quantity,
    double price,
  )
  onSubmit;

  @override
  State<_AddInventoryItemDialog> createState() =>
      _AddInventoryItemDialogState();
}

class _AddInventoryItemDialogState extends State<_AddInventoryItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSubmitting = true);
    widget.onSubmit(
      _nameController.text.trim(),
      _descriptionController.text.trim(),
      int.parse(_quantityController.text.trim()),
      double.parse(_priceController.text.trim()),
    );
    setState(() => _isSubmitting = false);
    Get.back();
    Get.snackbar(
      'Inventory updated',
      'Item added successfully',
      backgroundColor: AppColors.secondary,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: Get.width * 0.25,
        vertical: Get.height * 0.2,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add inventory item',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting ? null : Get.back,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Quantity is required';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Price is required';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_isSubmitting ? 'Saving...' : 'Save item'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(value),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
