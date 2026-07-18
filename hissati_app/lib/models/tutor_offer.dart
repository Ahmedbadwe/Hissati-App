import 'package:cloud_firestore/cloud_firestore.dart';

class TutorOffer {
  final String offerId;
  final String tutorUid;
  final String tutorName;
  final String tutorPhone;
  final String? eduLevel;
  final String? subject;
  final int? priceCenter;
  final int? pricePrivate;
  final List<String> availableTimes;
  final GeoPoint locationGeo;
  final DateTime createdAt;
  double? distanceKm;

  TutorOffer({
    required this.offerId,
    required this.tutorUid,
    required this.tutorName,
    required this.tutorPhone,
    this.eduLevel,
    this.subject,
    this.priceCenter,
    this.pricePrivate,
    required this.availableTimes,
    required this.locationGeo,
    required this.createdAt,
    this.distanceKm,
  });

  factory TutorOffer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TutorOffer(
      offerId: doc.id,
      tutorUid: data['tutorUid'] ?? '',
      tutorName: data['tutorName'] ?? '',
      tutorPhone: data['tutorPhone'] ?? '',
      eduLevel: data['eduLevel'],
      subject: data['subject'],
      priceCenter: data['priceCenter'] as int?,
      pricePrivate: data['pricePrivate'] as int?,
      availableTimes: List<String>.from(data['availableTimes'] ?? []),
      locationGeo: data['locationGeo'] as GeoPoint? ?? const GeoPoint(0, 0),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap(Map<String, dynamic> geoData) {
    return {
      'tutorUid': tutorUid,
      'tutorName': tutorName,
      'tutorPhone': tutorPhone,
      'eduLevel': eduLevel,
      'subject': subject,
      'priceCenter': priceCenter,
      'pricePrivate': pricePrivate,
      'availableTimes': availableTimes,
      'locationGeo': locationGeo,
      'position': geoData,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
