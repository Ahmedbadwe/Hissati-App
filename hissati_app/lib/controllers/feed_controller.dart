import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import '../models/tutor_offer.dart';
import '../models/parent_request.dart';
import '../services/location_service.dart';
import 'filter_controller.dart';

enum FeedStatus { idle, loading, loaded, error }

/// Drives the Home/Cards Feed. Runs a Firestore geohash radius query
/// (via geoflutterfire2) scoped to the user's current location, then
/// applies the remaining filters (edu level, subject, price range)
/// client-side, and finally sorts by distance ascending.
///
/// Role-aware: tutors see `parent_requests`, parents see `tutor_offers`.
class FeedController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final GeoFlutterFire _geo = GeoFlutterFire();

  final FilterController filterController;
  final bool isTutorViewer; // true = logged-in user is a tutor (sees parent_requests)

  FeedController({
    required this.filterController,
    required this.isTutorViewer,
  }) {
    filterController.addListener(refresh);
  }

  FeedStatus status = FeedStatus.idle;
  String? errorMessage;
  List<TutorOffer> tutorOffers = [];
  List<ParentRequest> parentRequests = [];

  GeoFirePoint? _myLocation;

  Future<void> initAndLoad() async {
    status = FeedStatus.loading;
    notifyListeners();
    try {
      final point = await LocationService.instance.getCurrentGeoPoint();
      _myLocation = _geo.point(
        latitude: point.latitude,
        longitude: point.longitude,
      );
      await refresh();
    } catch (e) {
      status = FeedStatus.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_myLocation == null) return;
    status = FeedStatus.loading;
    notifyListeners();

    try {
      final radiusKm = filterController.radiusKm;

      if (isTutorViewer) {
        await _loadParentRequests(radiusKm);
      } else {
        await _loadTutorOffers(radiusKm);
      }
      status = FeedStatus.loaded;
    } catch (e) {
      status = FeedStatus.error;
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> _loadTutorOffers(double radiusKm) async {
    final collectionRef = _firestore.collection('tutor_offers');

    final stream = _geo.collection(collectionRef: collectionRef).within(
          center: _myLocation!,
          radius: radiusKm,
          field: 'position',
          strictMode: true,
        );

    final snapshots = await stream.first;

    var offers = snapshots
        .map((doc) => TutorOffer.fromDoc(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            ))
        .toList();

    for (final offer in offers) {
      offer.distanceKm = LocationService.instance.distanceInKm(
        GeoPoint(_myLocation!.latitude, _myLocation!.longitude),
        offer.locationGeo,
      );
    }

    offers = _applyCommonFilters(
      offers,
      levelOf: (o) => o.eduLevel ?? '',
      subjectOf: (o) => o.subject ?? '',
      priceOf: (o) => o.pricePrivate ?? 0,
    );

    offers.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    tutorOffers = offers;
  }

  Future<void> _loadParentRequests(double radiusKm) async {
    final collectionRef = _firestore.collection('parent_requests');

    final stream = _geo.collection(collectionRef: collectionRef).within(
          center: _myLocation!,
          radius: radiusKm,
          field: 'position',
          strictMode: true,
        );

    final snapshots = await stream.first;

    var requests = snapshots
        .map((doc) => ParentRequest.fromDoc(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            ))
        .toList();

    for (final req in requests) {
      req.distanceKm = LocationService.instance.distanceInKm(
        GeoPoint(_myLocation!.latitude, _myLocation!.longitude),
        req.locationGeo,
      );
    }

    requests = _applyCommonFilters(
      requests,
      levelOf: (r) => r.eduLevel ?? '',
      subjectOf: (r) => r.subject ?? '',
      priceOf: (r) => r.maxBudget ?? 0,
    );

    requests.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    parentRequests = requests;
  }

  /// Shared filtering logic for edu level / subject / price range,
  /// generic across TutorOffer and ParentRequest via accessor callbacks.
  List<T> _applyCommonFilters<T>(
    List<T> items, {
    required String Function(T) levelOf,
    required String Function(T) subjectOf,
    required int Function(T) priceOf,
  }) {
    final level = filterController.eduLevel;
    final subject = filterController.subject;
    final range = filterController.priceRange;

    return items.where((item) {
      if (level != null && levelOf(item) != level) return false;
      if (subject != null && subjectOf(item) != subject) return false;
      final price = priceOf(item);
      if (price < range.start || price > range.end) return false;
      return true;
    }).toList();
  }

  @override
  void dispose() {
    filterController.removeListener(refresh);
    super.dispose();
  }
}
