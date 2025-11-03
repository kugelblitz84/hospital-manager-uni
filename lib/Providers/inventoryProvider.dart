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
  inventoryItem({
    this.itemId,
    this.itemName,
    this.itemDescription,
    this.quantity,
    this.price,
  });
}

class InventoryNotifier extends Notifier<List<inventoryItem>> {
  @override
  List<inventoryItem> build() {
    return [];
  }

  void setInventoryItems() async {
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
    for (var doc in res['items']) {
      items.add(
        inventoryItem(
          itemId: doc['itemId'],
          itemName: doc['itemName'],
          itemDescription: doc['itemDescription'],
          quantity: doc['quantity'],
          price: doc['price'],
        ),
      );
    }
    state = items;
  }

  void addInventoryItem(
    String name,
    String description,
    int quantity,
    double price,
  ) async {
    final res = await InventoryServices.addInventoryItem(
      name,
      description,
      quantity,
      price,
    );
    if (res['status'] != 'success') {
      Get.snackbar(
        "Error",
        res['message'] ?? "Failed to add inventory item",
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      );
      return;
    }
    setInventoryItems();
  }

  void updateInventoryItem(String itemId, Map<String, dynamic> data) async {
    final res = await InventoryServices.updateInventoryItem(itemId, data);
    if (res['status'] != 'success') {
      Get.snackbar(
        "Error",
        res['message'] ?? "Failed to update inventory item",
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      );
      return;
    }
    setInventoryItems();
  }

  void deleteInventoryItem(String itemId) async {
    final res = await InventoryServices.deleteInventoryItem(itemId);
    if (res['status'] != 'success') {
      Get.snackbar(
        "Error",
        res['message'] ?? "Failed to delete inventory item",
        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
      );
      return;
    }
    setInventoryItems();
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
