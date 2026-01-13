import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

/// Service for managing user data in Firestore
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'user';

  /// Create a new user in Firestore
  Future<void> createUser(User user) async {
    try {
      await _firestore.collection(_collection).doc(user.id).set(user.toMap());
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  /// Get user by ID
  Future<User?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return User.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  /// Update user's last login time
  Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'lastLogin': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  /// Update user profile
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(userId).update(updates);
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  /// Check if user exists by email
  Future<bool> userExistsByEmail(String email) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  /// Get user by email
  Future<User?> getUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return User.fromMap(query.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  /// Stream user data
  Stream<User?> streamUser(String userId) {
    return _firestore
        .collection(_collection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return User.fromMap(doc.data()!);
      }
      return null;
    });
  }
}
