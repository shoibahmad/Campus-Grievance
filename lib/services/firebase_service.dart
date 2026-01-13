import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grievance.dart';

/// Firebase Service for managing grievances
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'grievances';

  /// Submit a new grievance
  Future<void> submitGrievance(Grievance grievance) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(grievance.id)
          .set(grievance.toMap());
    } catch (e) {
      throw Exception('Failed to submit grievance: $e');
    }
  }

  /// Get all grievances for a student
  Stream<List<Grievance>> getStudentGrievances(String studentId) {
    return _firestore
        .collection(_collection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          final grievances = snapshot.docs
              .map((doc) => Grievance.fromMap(doc.data()))
              .toList();
          
          // Sort by createdAt in memory to avoid composite index
          grievances.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return grievances;
        });
  }

  /// Get all grievances (for admin)
  Stream<List<Grievance>> getAllGrievances() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
          final grievances = snapshot.docs
              .map((doc) => Grievance.fromMap(doc.data()))
              .toList();
          
          // Sort by severity and then by createdAt in memory
          grievances.sort((a, b) {
            final severityCompare = b.severityScore.compareTo(a.severityScore);
            if (severityCompare != 0) return severityCompare;
            return b.createdAt.compareTo(a.createdAt);
          });
          return grievances;
        });
  }

  /// Update grievance status
  Future<void> updateGrievanceStatus(
    String grievanceId,
    String status, {
    String? adminResponse,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': Timestamp.now(),
      };

      if (adminResponse != null) {
        updateData['adminResponse'] = adminResponse;
      }

      await _firestore
          .collection(_collection)
          .doc(grievanceId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update grievance: $e');
    }
  }

  /// Get grievances by status
  Stream<List<Grievance>> getGrievancesByStatus(String status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
          final grievances = snapshot.docs
              .map((doc) => Grievance.fromMap(doc.data()))
              .toList();
          
          // Sort by severity in memory to avoid composite index
          grievances.sort((a, b) => b.severityScore.compareTo(a.severityScore));
          return grievances;
        });
  }

  /// Get statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final grievances = snapshot.docs
          .map((doc) => Grievance.fromMap(doc.data()))
          .toList();

      return {
        'total': grievances.length,
        'pending': grievances.where((g) => g.status == 'pending').length,
        'in_progress': grievances.where((g) => g.status == 'in_progress').length,
        'resolved': grievances.where((g) => g.status == 'resolved').length,
        'critical': grievances.where((g) => g.severityScore >= 8).length,
      };
    } catch (e) {
      return {
        'total': 0,
        'pending': 0,
        'in_progress': 0,
        'resolved': 0,
        'critical': 0,
      };
    }
  }

  /// Get statistics for a specific student
  Future<Map<String, int>> getStudentStatistics(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('studentId', isEqualTo: studentId)
          .get();
      
      final grievances = snapshot.docs
          .map((doc) => Grievance.fromMap(doc.data()))
          .toList();

      return {
        'total': grievances.length,
        'pending': grievances.where((g) => g.status == 'pending').length,
        'in_progress': grievances.where((g) => g.status == 'in_progress').length,
        'resolved': grievances.where((g) => g.status == 'resolved').length,
        'critical': grievances.where((g) => g.severityScore >= 8).length,
      };
    } catch (e) {
      return {
        'total': 0,
        'pending': 0,
        'in_progress': 0,
        'resolved': 0,
        'critical': 0,
      };
    }
  }
}
