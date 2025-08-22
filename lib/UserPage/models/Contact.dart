import 'package:cloud_firestore/cloud_firestore.dart';

class ContactModel {
  final String? id;
  final String name;
  final String email;
  final String? phone;
  final String subject;
  final String message;
  final DateTime createdAt;
  final ContactStatus status;

  ContactModel({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.subject,
    required this.message,
    DateTime? createdAt,
    this.status = ContactStatus.pending,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert ContactModel to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'subject': subject,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
    };
  }

  // Create ContactModel from Firebase document
  factory ContactModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ContactModel(
      id: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      subject: map['subject'] ?? '',
      message: map['message'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: ContactStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ContactStatus.pending,
      ),
    );
  }

  // Create ContactModel from Firebase DocumentSnapshot
  factory ContactModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return ContactModel.fromMap(data, snapshot.id);
  }

  // Copy with method for updating
  ContactModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? subject,
    String? message,
    DateTime? createdAt,
    ContactStatus? status,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'ContactModel(id: $id, name: $name, email: $email, phone: $phone, subject: $subject, message: $message, createdAt: $createdAt, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.subject == subject &&
        other.message == message &&
        other.createdAt == createdAt &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      email,
      phone,
      subject,
      message,
      createdAt,
      status,
    );
  }
}

enum ContactStatus {
  pending,
  inProgress,
  resolved,
  closed,
}

// Firebase Service for Contact operations
class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'contacts';

  // Add a new contact
  Future<String> addContact(ContactModel contact) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_collectionName)
          .add(contact.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add contact: $e');
    }
  }

  // Get all contacts
  Future<List<ContactModel>> getAllContacts() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ContactModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get contacts: $e');
    }
  }

  // Get contacts by status
  Future<List<ContactModel>> getContactsByStatus(ContactStatus status) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ContactModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get contacts by status: $e');
    }
  }

  // Get contact by ID
  Future<ContactModel?> getContactById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();

      if (doc.exists) {
        return ContactModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get contact: $e');
    }
  }

  // Update contact status
  Future<void> updateContactStatus(String id, ContactStatus status) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .update({'status': status.name});
    } catch (e) {
      throw Exception('Failed to update contact status: $e');
    }
  }

  // Delete contact
  Future<void> deleteContact(String id) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete contact: $e');
    }
  }

  // Stream contacts (real-time updates)
  Stream<List<ContactModel>> streamContacts() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContactModel.fromSnapshot(doc))
            .toList());
  }

  // Stream contacts by status
  Stream<List<ContactModel>> streamContactsByStatus(ContactStatus status) {
    return _firestore
        .collection(_collectionName)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContactModel.fromSnapshot(doc))
            .toList());
  }
}