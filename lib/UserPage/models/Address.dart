import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String address;
  final String city;
  final bool isDefault;

  Address({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'address': address,
      'city': city,
      'isDefault': isDefault,
    };
  }

  static Address fromMap(Map<String, dynamic> map, String id) {
    return Address(
      id: id,
      userId: map['userId'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      city: map['city'],
      isDefault: map['isDefault'] ?? false,
    );
  }

  static CollectionReference getUserAddresses(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('addresses');
  }

  static Stream<List<Address>> getAddresses(String userId) {
    return getUserAddresses(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Address.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  static Future<void> addAddress({
    required String userId,
    required String name,
    required String phone,
    required String address,
    required String city,
    bool isDefault = false,
  }) async {
    final addressData = {
      'userId': userId,
      'name': name,
      'phone': phone,
      'address': address,
      'city': city,
      'isDefault': isDefault,
    };

    if (isDefault) {
      // Update all other addresses to non-default
      final batch = FirebaseFirestore.instance.batch();
      final snapshots = await getUserAddresses(userId).get();
      for (var doc in snapshots.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }
      await batch.commit();
    }

    await getUserAddresses(userId).add(addressData);
  }
}