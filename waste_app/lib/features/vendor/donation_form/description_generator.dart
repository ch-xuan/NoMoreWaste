import '../../../data/models/donation.dart';

/// Smart template-based description generator for food donations.
/// Generates appealing, contextual descriptions based on form fields
/// without requiring any external API.
class DescriptionGenerator {
  /// Generate a description based on the donation form fields.
  ///
  /// [title] — the food title (required)
  /// [category] — food category string (e.g. "Cooked Food")
  /// [quantity] — quantity string (e.g. "5")
  /// [unit] — unit string (e.g. "Servings")
  /// [containsAllergens] — whether the food contains allergens
  /// [hasPhotos] — whether photos were attached
  String generate({
    required String title,
    String? category,
    String? quantity,
    String? unit,
    bool containsAllergens = false,
    bool hasPhotos = false,
  }) {
    final buffer = StringBuffer();

    // Opening line based on category
    final opener = _getOpener(title, category);
    buffer.write(opener);

    // Quantity details
    if (quantity != null && quantity.isNotEmpty) {
      final unitLabel = _formatUnit(unit, quantity);
      buffer.write(' \u2014 $quantity $unitLabel available.');
    } else {
      buffer.write('.');
    }

    // Category-specific detail
    final detail = _getCategoryDetail(category);
    if (detail.isNotEmpty) {
      buffer.write(' $detail');
    }

    // Allergen warning
    if (containsAllergens) {
      buffer.write(' \u26a0\ufe0f Contains allergens \u2014 please inquire for details.');
    }

    // Pickup note
    buffer.write(' Ready for pickup within the specified window.');

    return buffer.toString();
  }

  /// Generate multiple description variants for the user to choose from.
  List<String> generateVariants({
    required String title,
    String? category,
    String? quantity,
    String? unit,
    bool containsAllergens = false,
  }) {
    final variants = <String>[];
    final unitLabel = _formatUnit(unit, quantity ?? '');
    final qtyText = (quantity != null && quantity.isNotEmpty) 
        ? '$quantity $unitLabel' 
        : null;

    // Variant 1: Concise & Professional
    final v1 = StringBuffer();
    v1.write(_getOpener(title, category));
    if (qtyText != null) v1.write(' \u2014 $qtyText available.');
    else v1.write('.');
    v1.write(' ${_getCategoryDetail(category)}');
    if (containsAllergens) v1.write(' Contains allergens.');
    v1.write(' Ready for pickup.');
    variants.add(v1.toString());

    // Variant 2: Warm & Inviting
    final v2 = StringBuffer();
    v2.write(_getWarmOpener(title, category));
    if (qtyText != null) v2.write(' We have $qtyText to share.');
    v2.write(' ${_getWarmDetail(category)}');
    if (containsAllergens) v2.write(' Please note: contains allergens.');
    v2.write(' Come grab it before it\'s gone!');
    variants.add(v2.toString());

    // Variant 3: Brief & Direct
    final v3 = StringBuffer();
    if (qtyText != null) {
      v3.write('$qtyText of $title.');
    } else {
      v3.write('$title up for donation.');
    }
    v3.write(' ${_getBriefDetail(category)}');
    if (containsAllergens) v3.write(' Allergens present.');
    v3.write(' Pickup available now.');
    variants.add(v3.toString());

    return variants;
  }

  // Openers

  String _getOpener(String title, String? category) {
    switch (category) {
      case 'Cooked Food':
        return 'Freshly prepared $title';
      case 'Baked Goods':
        return 'Freshly baked $title';
      case 'Fresh Produce':
        return 'Farm-fresh $title';
      case 'Drinks':
        return 'Refreshing $title';
      case 'Packaged Food':
        return 'Quality packaged $title';
      default:
        return 'Fresh $title';
    }
  }

  String _getWarmOpener(String title, String? category) {
    switch (category) {
      case 'Cooked Food':
        return 'We\'ve got some delicious $title ready to share!';
      case 'Baked Goods':
        return 'Warm, freshly baked $title \u2014 too good to go to waste!';
      case 'Fresh Produce':
        return 'Beautiful, fresh $title straight from our kitchen!';
      case 'Drinks':
        return 'Chilled and ready \u2014 $title for anyone who needs a refreshment!';
      case 'Packaged Food':
        return 'Quality $title that deserves a good home!';
      default:
        return 'We have some wonderful $title to share!';
    }
  }

  // Category Details

  String _getCategoryDetail(String? category) {
    switch (category) {
      case 'Cooked Food':
        return 'Prepared with care and best consumed fresh.';
      case 'Baked Goods':
        return 'Baked fresh and best enjoyed soon.';
      case 'Fresh Produce':
        return 'Harvested fresh and in great condition.';
      case 'Drinks':
        return 'Properly stored and ready to serve.';
      case 'Packaged Food':
        return 'Sealed and in original packaging.';
      default:
        return 'In good condition and ready for collection.';
    }
  }

  String _getWarmDetail(String? category) {
    switch (category) {
      case 'Cooked Food':
        return 'Made with love and ready to warm someone\'s day.';
      case 'Baked Goods':
        return 'Perfect for brightening someone\'s morning.';
      case 'Fresh Produce':
        return 'Great quality \u2014 perfect for a healthy meal.';
      case 'Drinks':
        return 'Perfect for a quick refreshment.';
      case 'Packaged Food':
        return 'Well-sealed and ready to go.';
      default:
        return 'Hope this can help someone in need!';
    }
  }

  String _getBriefDetail(String? category) {
    switch (category) {
      case 'Cooked Food':
        return 'Home-cooked, fresh quality.';
      case 'Baked Goods':
        return 'Freshly baked today.';
      case 'Fresh Produce':
        return 'Fresh and nutritious.';
      case 'Drinks':
        return 'Chilled and ready.';
      case 'Packaged Food':
        return 'Sealed, unexpired.';
      default:
        return 'Good condition.';
    }
  }

  // Helpers

  String _formatUnit(String? unit, String? quantity) {
    final qty = double.tryParse(quantity ?? '') ?? 0;
    final isPlural = qty != 1;

    switch (unit) {
      case 'Kilograms (kg)':
        return 'kg';
      case 'Units':
        return isPlural ? 'units' : 'unit';
      case 'Servings':
        return isPlural ? 'servings' : 'serving';
      default:
        return isPlural ? 'items' : 'item';
    }
  }
}
