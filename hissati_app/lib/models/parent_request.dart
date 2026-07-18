import 'package:cloud_firestore/cloud_firestore.dart';

class ParentRequest {
  final String requestId;
  final String parentUid;
  final String parentName;
  final String parentPhone;
  final String? subject;
  final String? eduLevel;
  final int? maxBudget;
  final String descriptionText;
  final GeoPoint locationGeo;
  final DateTime createdAt;
  double? distanceKm;

  ParentRequest({
    required this.requestId,
    required this.parentUid,
    required this.parentName,
    required this.parentPhone,
    this.subject,
    this.eduLevel,
    this.maxBudget,
    required this.descriptionText,
    required this.locationGeo,
    required this.createdAt,
    this.distanceKm,
  });

  factory ParentRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ParentRequest(
      requestId: doc.id,
      parentUid: data['parentUid'] ?? '',
      parentName: data['parentName'] ?? '',
      parentPhone: data['parentPhone'] ?? '',
      subject: data['subject'],
      eduLevel: data['eduLevel'],
      maxBudget: data['maxBudget'] as int?,
      descriptionText: data['descriptionText'] ?? '',
      locationGeo: data['locationGeo'] as GeoPoint? ?? const GeoPoint(0, 0),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap(Map<String, dynamic> geoData) {
    return {
      'parentUid': parentUid,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'subject': subject,
      'eduLevel': eduLevel,
      'maxBudget': maxBudget,
      'descriptionText': descriptionText,
      'locationGeo': locationGeo,
      'position': geoData,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
