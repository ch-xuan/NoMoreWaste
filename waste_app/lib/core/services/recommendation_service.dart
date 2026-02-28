import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/donation.dart';
import '../../data/models/donation_request.dart';

/// A scored donation with its recommendation score and breakdown
class ScoredDonation {
  final Donation donation;
  final double score; // 0.0 - 1.0
  final Map<String, double> breakdown;

  const ScoredDonation({
    required this.donation,
    required this.score,
    this.breakdown = const {},
  });

  int get matchPercent => (score * 100).round().clamp(0, 99);
}

/// AI-powered recommendation service that ranks food donations for NGOs.
///
/// Scoring factors:
/// - Distance (35%): proximity between NGO and donation pickup
/// - Food Preference (25%): based on NGO's request history
/// - Freshness/Urgency (25%): donations closer to expiry get higher score
/// - Quantity (15%): larger quantities are preferred
class RecommendationService {
  static const _weightDistance = 0.35;
  static const _weightPreference = 0.25;
  static const _weightFreshness = 0.25;
  static const _weightQuantity = 0.15;

  /// Rank donations by recommendation score for an NGO.
  ///
  /// [donations] — list of available donations
  /// [ngoAddress] — the NGO's address string (for text-based proximity)
  /// [ngoLocation] — optional GeoPoint for precise distance
  /// [requestHistory] — NGO's past donation requests (to learn preferences)
  List<ScoredDonation> rankDonations({
    required List<Donation> donations,
    String? ngoAddress,
    GeoPoint? ngoLocation,
    List<DonationRequest>? requestHistory,
  }) {
    if (donations.isEmpty) return [];

    // Build preference map from history
    final prefMap = _buildPreferenceMap(requestHistory ?? []);
    
    // Calculate max quantity for normalization
    final maxQty = donations.fold<double>(0, (prev, d) {
      final qty = double.tryParse(d.quantity) ?? 0;
      return qty > prev ? qty : prev;
    });

    final scored = donations.map((donation) {
      final distScore = _distanceScore(
        donationAddress: donation.pickupAddress,
        donationLocation: donation.location,
        ngoAddress: ngoAddress,
        ngoLocation: ngoLocation,
      );

      final prefScore = _preferenceScore(donation.foodType, prefMap);
      final freshScore = _freshnessScore(donation.expiryTime);
      final qtyScore = _quantityScore(donation.quantity, maxQty);

      // If no location data available, redistribute distance weight
      double finalScore;
      if (ngoAddress == null && ngoLocation == null) {
        // No location data — skip distance, redistribute weight
        final redistWeight = _weightDistance / 3;
        finalScore = 
          (prefScore * (_weightPreference + redistWeight)) +
          (freshScore * (_weightFreshness + redistWeight)) +
          (qtyScore * (_weightQuantity + redistWeight));
      } else {
        finalScore = 
          (distScore * _weightDistance) +
          (prefScore * _weightPreference) +
          (freshScore * _weightFreshness) +
          (qtyScore * _weightQuantity);
      }

      return ScoredDonation(
        donation: donation,
        score: finalScore.clamp(0.0, 1.0),
        breakdown: {
          'distance': distScore,
          'preference': prefScore,
          'freshness': freshScore,
          'quantity': qtyScore,
        },
      );
    }).toList();

    // Sort descending by score
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }

  /// Build a frequency map of food types from past requests
  Map<FoodType, double> _buildPreferenceMap(List<DonationRequest> history) {
    if (history.isEmpty) return {};

    final counts = <FoodType, int>{};
    // We don't have FoodType on DonationRequest, so we'll use donationTitle
    // as a proxy to infer food type preferences
    for (final req in history) {
      final title = req.donationTitle.toLowerCase();
      // Simple keyword-based inference
      FoodType? inferred;
      if (title.contains('bread') || title.contains('cake') || title.contains('pastry') || title.contains('baked')) {
        inferred = FoodType.bakedGoods;
      } else if (title.contains('fruit') || title.contains('vegetable') || title.contains('salad') || title.contains('fresh')) {
        inferred = FoodType.freshProduce;
      } else if (title.contains('rice') || title.contains('noodle') || title.contains('curry') || title.contains('meal') || title.contains('cooked')) {
        inferred = FoodType.cookedFood;
      } else if (title.contains('drink') || title.contains('juice') || title.contains('water') || title.contains('tea') || title.contains('coffee')) {
        inferred = FoodType.drinks;
      } else if (title.contains('canned') || title.contains('packed') || title.contains('packaged') || title.contains('instant')) {
        inferred = FoodType.packagedFood;
      }
      
      if (inferred != null) {
        counts[inferred] = (counts[inferred] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) return {};

    final maxCount = counts.values.reduce(max);
    return counts.map((type, count) => MapEntry(type, count / maxCount));
  }

  /// Score based on proximity. Uses GeoPoint if available, otherwise text matching.
  double _distanceScore({
    required String donationAddress,
    GeoPoint? donationLocation,
    String? ngoAddress,
    GeoPoint? ngoLocation,
  }) {
    // If both have GeoPoints, use Haversine distance
    if (donationLocation != null && ngoLocation != null) {
      final distKm = _haversineDistance(
        donationLocation.latitude, donationLocation.longitude,
        ngoLocation.latitude, ngoLocation.longitude,
      );
      // Score: 1.0 for 0km, decays to ~0.1 at 50km
      return exp(-distKm / 15.0);
    }

    // Text-based fallback: check if addresses share common area keywords
    if (ngoAddress != null && ngoAddress.isNotEmpty) {
      return _textAddressSimilarity(donationAddress, ngoAddress);
    }

    return 0.5; // Neutral if no location data
  }

  /// Haversine formula for distance between two lat/lng points in km
  double _haversineDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0; // Earth radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  /// Simple text similarity for addresses (shared words/area names)
  double _textAddressSimilarity(String addr1, String addr2) {
    final words1 = addr1.toLowerCase().split(RegExp(r'[\s,]+'))
        .where((w) => w.length > 2).toSet();
    final words2 = addr2.toLowerCase().split(RegExp(r'[\s,]+'))
        .where((w) => w.length > 2).toSet();

    if (words1.isEmpty || words2.isEmpty) return 0.5;

    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;
    
    // Jaccard similarity
    return (intersection / union).clamp(0.0, 1.0);
  }

  /// Score based on food type preference. Higher = more preferred.
  double _preferenceScore(FoodType type, Map<FoodType, double> prefMap) {
    if (prefMap.isEmpty) return 0.5; // Neutral for new NGOs
    return prefMap[type] ?? 0.2; // Low score for never-requested types
  }

  /// Score based on freshness/urgency. Donations expiring soon get higher scores
  /// (they need to be claimed urgently).
  double _freshnessScore(DateTime expiryTime) {
    final now = DateTime.now();
    final hoursUntilExpiry = expiryTime.difference(now).inMinutes / 60.0;

    if (hoursUntilExpiry <= 0) return 0.0; // Already expired
    if (hoursUntilExpiry <= 2) return 1.0; // Very urgent (< 2 hours)
    if (hoursUntilExpiry <= 6) return 0.85; // Urgent (< 6 hours)
    if (hoursUntilExpiry <= 12) return 0.7; // Same day
    if (hoursUntilExpiry <= 24) return 0.5; // Tomorrow
    if (hoursUntilExpiry <= 48) return 0.3; // Day after
    return 0.15; // Far out
  }

  /// Score based on quantity. Larger quantities are preferred.
  double _quantityScore(String quantityStr, double maxQty) {
    final qty = double.tryParse(quantityStr) ?? 0;
    if (maxQty <= 0) return 0.5;
    return (qty / maxQty).clamp(0.0, 1.0);
  }
}
