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

  Future<void> _showAddItemDialog() async {
    await Get.dialog(
      _InventoryItemDialog(
        title: 'Add inventory item',
        submitLabel: 'Save item',
        successTitle: 'Inventory updated',
        successMessage: 'Item added successfully',
        onSubmit: (form) async {
          final success = await ref
              .read(inventoryProvider.notifier)
              .addInventoryItem(
                form.name,
                form.description,
                form.quantity,
                form.totalPrice,
                form.unitPrice,
                form.unitType,
                form.itemType,
              );
          return success;
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

  Future<void> _handleDelete(BuildContext context) async {
    if (item.itemId == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete inventory item'),
        content: Text(
          'Are you sure you want to delete "${item.itemName ?? 'this item'}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    final success = await ref
        .read(inventoryProvider.notifier)
        .deleteInventoryItem(item.itemId!);
    if (success) {
      Get.snackbar(
        'Inventory updated',
        'Item removed successfully',
        backgroundColor: AppColors.secondary,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleEdit(BuildContext context) async {
    if (item.itemId == null) {
      return;
    }
    await Get.dialog(
      _InventoryItemDialog(
        title: 'Edit inventory item',
        submitLabel: 'Update item',
        successTitle: 'Inventory updated',
        successMessage: 'Item details saved successfully',
        initialItem: item,
        onSubmit: (form) async {
          final success = await ref
              .read(inventoryProvider.notifier)
              .updateInventoryItem(item.itemId!, {
                'name': form.name,
                'description': form.description,
                'quantity': form.quantity,
                'price': form.totalPrice,
                'unitPrice': form.unitPrice,
                'unitType': form.unitType,
                'itemType': form.itemType,
              });
          return success;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.itemName ?? 'Untitled item',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Edit item',
                      onPressed: item.itemId == null
                          ? null
                          : () => _handleEdit(context),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete item',
                      onPressed: item.itemId == null
                          ? null
                          : () => _handleDelete(context),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.itemDescription ?? 'No description provided'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 12,
              children: [
                _InfoPill(
                  icon: Icons.inventory_2_outlined,
                  label: 'Quantity',
                  value: (item.quantity ?? 0).toString(),
                ),
                _InfoPill(
                  icon: Icons.attach_money,
                  label: 'Total price',
                  value: item.price != null
                      ? item.price!.toStringAsFixed(2)
                      : 'Not set',
                ),
                _InfoPill(
                  icon: Icons.payments_outlined,
                  label: 'Unit price',
                  value: item.unitPrice != null
                      ? item.unitPrice!.toStringAsFixed(2)
                      : 'Not set',
                ),
                _InfoPill(
                  icon: Icons.straighten,
                  label: 'Unit type',
                  value: (item.unitType == null || item.unitType!.isEmpty)
                      ? 'Not set'
                      : item.unitType!,
                ),
                _InfoPill(
                  icon: Icons.category_outlined,
                  label: 'Item type',
                  value: (item.itemType == null || item.itemType!.isEmpty)
                      ? 'Not set'
                      : item.itemType!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryFormData {
  const _InventoryFormData({
    required this.name,
    required this.description,
    required this.quantity,
    required this.totalPrice,
    required this.unitPrice,
    required this.unitType,
    required this.itemType,
  });

  final String name;
  final String description;
  final int quantity;
  final double totalPrice;
  final double unitPrice;
  final String unitType;
  final String itemType;
}

class _InventoryItemDialog extends StatefulWidget {
  const _InventoryItemDialog({
    required this.title,
    required this.submitLabel,
    required this.successTitle,
    required this.successMessage,
    required this.onSubmit,
    this.initialItem,
  });

  final String title;
  final String submitLabel;
  final String successTitle;
  final String successMessage;
  final inventoryItem? initialItem;
  final Future<bool> Function(_InventoryFormData form) onSubmit;

  @override
  State<_InventoryItemDialog> createState() => _InventoryItemDialogState();
}

class _InventoryItemDialogState extends State<_InventoryItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _unitTypeController = TextEditingController();
  final _itemTypeController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialItem;
    if (initial != null) {
      _nameController.text = initial.itemName ?? '';
      _descriptionController.text = initial.itemDescription ?? '';
      if (initial.quantity != null) {
        _quantityController.text = initial.quantity!.toString();
      }
      _priceController.text = initial.price != null
          ? initial.price!.toStringAsFixed(2)
          : '';
      _unitPriceController.text = initial.unitPrice != null
          ? initial.unitPrice!.toStringAsFixed(2)
          : '';
      _unitTypeController.text = initial.unitType ?? '';
      _itemTypeController.text = initial.itemType ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _unitPriceController.dispose();
    _unitTypeController.dispose();
    _itemTypeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final quantity = int.parse(_quantityController.text.trim());
    final totalPrice = double.parse(_priceController.text.trim());
    final unitPrice = double.parse(_unitPriceController.text.trim());
    final form = _InventoryFormData(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      quantity: quantity,
      totalPrice: totalPrice,
      unitPrice: unitPrice,
      unitType: _unitTypeController.text.trim(),
      itemType: _itemTypeController.text.trim(),
    );
    setState(() => _isSubmitting = true);
    final success = await widget.onSubmit(form);
    if (!mounted) {
      return;
    }
    if (success) {
      setState(() => _isSubmitting = false);
      FocusScope.of(context).unfocus();
      Get.back();
      Get.snackbar(
        widget.successTitle,
        widget.successMessage,
        backgroundColor: AppColors.secondary,
        colorText: Colors.white,
      );
    } else {
      setState(() => _isSubmitting = false);
    }
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
                    widget.title,
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
                decoration: const InputDecoration(labelText: 'Total price'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Total price is required';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitPriceController,
                decoration: const InputDecoration(labelText: 'Unit price'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Unit price is required';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitTypeController,
                decoration: const InputDecoration(labelText: 'Unit type'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Unit type is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _itemTypeController,
                decoration: const InputDecoration(labelText: 'Item type'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Item type is required';
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
                    child: Text(
                      _isSubmitting ? 'Saving...' : widget.submitLabel,
                    ),
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
