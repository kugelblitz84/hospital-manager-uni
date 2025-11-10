import 'package:medicare/services/authServices.dart';
import 'package:medicare/services/inventoryServices.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'dart:ui';

class inventoryManager {
  String? name;
  String? email;
  String? uid;
  String? createdAt;
}

class inventoryItem {
  String? itemId;
  String? itemName;
  String? itemDescription;
  int? quantity;
  double? price;
  double? unitPrice;
  String? unitType;
  String? itemType;
  inventoryItem({
    this.itemId,
    this.itemName,
    this.itemDescription,
    this.quantity,
    this.price,
    this.unitPrice,
    this.unitType,
    this.itemType,
  });
}

class InventoryNotifier extends Notifier<List<inventoryItem>> {
  @override
  List<inventoryItem> build() {
    return [];
  }

  Future<void> setInventoryItems() async {
    final res = await InventoryServices.getInventoryItems();
    if (res['status'] != 'success') {
      Get.snackbar(
        "Error",
        res['message'] ?? "Failed to retrieve inventory items",
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      );
      return;
    }
    List<inventoryItem> items = [];
    for (final dynamic raw in res['items'] ?? []) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }
      final data = Map<String, dynamic>.from(raw);
      final quantityRaw = data['quantity'];
      final priceRaw = data['price'];
      final unitPriceRaw = data['unitPrice'];
      final unitTypeRaw = data['unitType'] ?? data['unit_type'];
      final itemTypeRaw = data['itemType'] ?? data['item_type'];
      items.add(
        inventoryItem(
          itemId: data['itemId'] as String?,
          itemName: data['name'] as String? ?? data['itemName'] as String?,
          itemDescription:
              data['description'] as String? ??
              data['itemDescription'] as String?,
          quantity: quantityRaw is int
              ? quantityRaw
              : int.tryParse(quantityRaw?.toString() ?? ''),
          price: priceRaw is num
              ? priceRaw.toDouble()
              : double.tryParse(priceRaw?.toString() ?? ''),
          unitPrice: unitPriceRaw is num
              ? unitPriceRaw.toDouble()
              : double.tryParse(unitPriceRaw?.toString() ?? ''),
          unitType: unitTypeRaw?.toString(),
          itemType: itemTypeRaw?.toString(),
        ),
      );
    }
    state = items;
  }

  Future<bool> addInventoryItem(
    String name,
    String description,
    int quantity,
    double price,
    double unitPrice,
    String unitType,
    String itemType,
  ) async {
    final res = await InventoryServices.addInventoryItem(
      name,
      description,
      quantity,
      price,
      unitPrice,
      unitType,
      itemType,
    );
    if (res['status'] != 'success') {
      Get.snackbar(
        "Error",
        res['message'] ?? "Failed to add inventory item",
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      );
      return false;
    }
    await setInventoryItems();
    return true;
  }

  Future<bool> updateInventoryItem(
    String itemId,
    Map<String, dynamic> data,
  ) async {
    final res = await InventoryServices.updateInventoryItem(itemId, data);
    if (res['status'] != 'success') {
      Get.snackbar(
        "Error",
        res['message'] ?? "Failed to update inventory item",
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      );
      return false;
    }
    await setInventoryItems();
    return true;
  }

  Future<bool> deleteInventoryItem(String itemId) async {
    final res = await InventoryServices.deleteInventoryItem(itemId);
    if (res['status'] != 'success') {
      Get.snackbar(
        "Error",
        res['message'] ?? "Failed to delete inventory item",
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      );
      return false;
    }
    await setInventoryItems();
    return true;
  }
}

class InvantoryManagerList extends Notifier<List<inventoryManager>> {
  @override
  List<inventoryManager> build() {
    return [];
  }

  void setInventoryManagers() async {
    final res = await firebaseServices.getUserList('inventoryManager');
    if (res['status'] != 'success') {
      Get.snackbar(
        "Error",
        res['message'] ?? "Failed to retrieve inventory managers",
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      );
      return;
    }
    List<inventoryManager> managers = [];
    for (var doc in res['data']) {
      inventoryManager manager = inventoryManager();
      manager.name = doc['name'];
      manager.email = doc['email'];
      manager.uid = doc['uid'];
      manager.createdAt = doc['createdAt'];
      managers.add(manager);
    }
    state = managers;
  }
}

final inventoryProvider =
    NotifierProvider<InventoryNotifier, List<inventoryItem>>(
      () => InventoryNotifier(),
    );

final inventoryManagerListProvider =
    NotifierProvider<InvantoryManagerList, List<inventoryManager>>(
      () => InvantoryManagerList(),
    );
