class Product {
  final String barcode;
  final String? name;
  final String? brand;
  final String? imageUrl;

  // New optional fields
  final String? quantity;                 // e.g., "330 ml"
  final String? ingredientsText;          // plain text, localized if available
  final String? nutritionGrade;           // Nutri-Score letter: a..e

  // Nutriments (per 100g/100ml if provided)
  final double? energyKcal100g;
  final double? fat100g;
  final double? saturatedFat100g;
  final double? carbs100g;
  final double? sugars100g;
  final double? fiber100g;
  final double? proteins100g;
  final double? salt100g;
  final double? sodium100g;

  // Tags (already humanized)
  final List<String>? allergens;          // e.g., ["milk", "gluten"]
  final List<String>? additives;          // e.g., ["e322", "e330"]
  final List<String>? labels;             // e.g., ["organic"]

  const Product({
    required this.barcode,
    this.name,
    this.brand,
    this.imageUrl,
    this.quantity,
    this.ingredientsText,
    this.nutritionGrade,
    this.energyKcal100g,
    this.fat100g,
    this.saturatedFat100g,
    this.carbs100g,
    this.sugars100g,
    this.fiber100g,
    this.proteins100g,
    this.salt100g,
    this.sodium100g,
    this.allergens,
    this.additives,
    this.labels,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        barcode: json['barcode']?.toString() ?? '',
        name: json['name'] as String?,
        brand: json['brand'] as String?,
        imageUrl: json['imageUrl'] as String?,
        quantity: json['quantity'] as String?,
        ingredientsText: json['ingredientsText'] as String?,
        nutritionGrade: json['nutritionGrade'] as String?,
        energyKcal100g: (json['energyKcal100g'] as num?)?.toDouble(),
        fat100g: (json['fat100g'] as num?)?.toDouble(),
        saturatedFat100g: (json['saturatedFat100g'] as num?)?.toDouble(),
        carbs100g: (json['carbs100g'] as num?)?.toDouble(),
        sugars100g: (json['sugars100g'] as num?)?.toDouble(),
        fiber100g: (json['fiber100g'] as num?)?.toDouble(),
        proteins100g: (json['proteins100g'] as num?)?.toDouble(),
        salt100g: (json['salt100g'] as num?)?.toDouble(),
        sodium100g: (json['sodium100g'] as num?)?.toDouble(),
        allergens: (json['allergens'] as List?)?.cast<String>(),
        additives: (json['additives'] as List?)?.cast<String>(),
        labels: (json['labels'] as List?)?.cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'imageUrl': imageUrl,
        'quantity': quantity,
        'ingredientsText': ingredientsText,
        'nutritionGrade': nutritionGrade,
        'energyKcal100g': energyKcal100g,
        'fat100g': fat100g,
        'saturatedFat100g': saturatedFat100g,
        'carbs100g': carbs100g,
        'sugars100g': sugars100g,
        'fiber100g': fiber100g,
        'proteins100g': proteins100g,
        'salt100g': salt100g,
        'sodium100g': sodium100g,
        'allergens': allergens,
        'additives': additives,
        'labels': labels,
      };
}
