import 'package:cloud_firestore/cloud_firestore.dart';

/// Grievance Model
/// Represents a complaint/grievance in the system
class Grievance {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String title;
  final String description;
  final String category;
  final int severityScore;
  final String status; // pending, in_progress, resolved, rejected
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? adminResponse;
  final String? imageUrl;
  final String location;

  Grievance({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.title,
    required this.description,
    required this.category,
    required this.severityScore,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
    this.adminResponse,
    this.imageUrl,
    required this.location,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'title': title,
      'description': description,
      'category': category,
      'severityScore': severityScore,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'adminResponse': adminResponse,
      'imageUrl': imageUrl,
      'location': location,
    };
  }

  // Create from Firestore Document
  factory Grievance.fromMap(Map<String, dynamic> map) {
    return Grievance(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentEmail: map['studentEmail'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Other',
      severityScore: map['severityScore'] ?? 0,
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
      adminResponse: map['adminResponse'],
      imageUrl: map['imageUrl'],
      location: map['location'] ?? '',
    );
  }

  // Copy with method for updates
  Grievance copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentEmail,
    String? title,
    String? description,
    String? category,
    int? severityScore,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminResponse,
    String? imageUrl,
    String? location,
  }) {
    return Grievance(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      severityScore: severityScore ?? this.severityScore,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminResponse: adminResponse ?? this.adminResponse,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
    );
  }

  // Get severity color
  String getSeverityColor() {
    if (severityScore >= 8) return '#FF3B30'; // Red - Critical
    if (severityScore >= 6) return '#FF9500'; // Orange - High
    if (severityScore >= 4) return '#FFCC00'; // Yellow - Medium
    return '#34C759'; // Green - Low
  }

  // Get severity label
  String getSeverityLabel() {
    if (severityScore >= 8) return 'Critical';
    if (severityScore >= 6) return 'High';
    if (severityScore >= 4) return 'Medium';
    return 'Low';
  }

  // Get status color
  String getStatusColor() {
    switch (status) {
      case 'resolved':
        return '#34C759'; // Green
      case 'in_progress':
        return '#007AFF'; // Blue
      case 'rejected':
        return '#FF3B30'; // Red
      default:
        return '#8E8E93'; // Gray
    }
  }
}
