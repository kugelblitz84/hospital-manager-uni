import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryServices {
  static Future<dynamic> addInventoryItem(
    String name,
    String description,
    int quantity,
    double price,
    double unitPrice,
    String unitType,
    String itemType,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final itemDoc = await firestore.collection('inventory').add({
        'name': name,
        'description': description,
        'quantity': quantity,
        'price': price,
        'unitPrice': unitPrice,
        'unitType': unitType,
        'itemType': itemType,
      });
      return {"status": "success", "itemId": itemDoc.id};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<dynamic> getInventoryItems() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore.collection('inventory').get();
      final items = querySnapshot.docs
          .map((doc) => {'itemId': doc.id, ...doc.data()})
          .toList();
      return {"status": "success", "items": items};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<dynamic> updateInventoryItem(
    String itemId,
    Map<String, dynamic> data,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('inventory').doc(itemId).update(data);
      return {"status": "success"};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<dynamic> deleteInventoryItem(String itemId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('inventory').doc(itemId).delete();
      return {"status": "success"};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }
}
