class Kost {
  const Kost({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.price,
    required this.distanceKm,
    required this.imageUrl,
    required this.facilities,
    required this.isVerified,
    required this.isAvailable,
    required this.category,
    required this.ownerName,
    required this.ownerPhone,
    required this.description,
  });

  final String id;
  final String name;
  final String city;
  final String address;
  final int price;
  final double distanceKm;
  final String imageUrl;
  final List<String> facilities;
  final bool isVerified;
  final bool isAvailable;
  final String category;
  final String ownerName;
  final String ownerPhone;
  final String description;

  Kost copyWith({
    String? id,
    String? name,
    String? city,
    String? address,
    int? price,
    double? distanceKm,
    String? imageUrl,
    List<String>? facilities,
    bool? isVerified,
    bool? isAvailable,
    String? category,
    String? ownerName,
    String? ownerPhone,
    String? description,
  }) {
    return Kost(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      address: address ?? this.address,
      price: price ?? this.price,
      distanceKm: distanceKm ?? this.distanceKm,
      imageUrl: imageUrl ?? this.imageUrl,
      facilities: facilities ?? this.facilities,
      isVerified: isVerified ?? this.isVerified,
      isAvailable: isAvailable ?? this.isAvailable,
      category: category ?? this.category,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      description: description ?? this.description,
    );
  }

  Map<String, Object?> toDatabase() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'city': city,
      'address': address,
      'price': price,
      'distance_km': distanceKm,
      'image_url': imageUrl,
      'facilities': facilities,
      'is_verified': isVerified,
      'is_available': isAvailable,
      'category': category,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      'description': description,
    };
  }

  static Kost fromDatabase(Map<String, Object?> data) {
    final Object? facilities = data['facilities'];
    return Kost(
      id: data['id'] as String,
      name: data['name'] as String,
      city: data['city'] as String,
      address: data['address'] as String,
      price: data['price'] as int,
      distanceKm: (data['distance_km'] as num).toDouble(),
      imageUrl: data['image_url'] as String,
      facilities: facilities is List<dynamic>
          ? facilities.map((dynamic item) => item.toString()).toList()
          : const <String>[],
      isVerified: data['is_verified'] as bool,
      isAvailable: data['is_available'] as bool,
      category: data['category'] as String,
      ownerName: data['owner_name'] as String,
      ownerPhone: data['owner_phone'] as String,
      description: data['description'] as String,
    );
  }
}
