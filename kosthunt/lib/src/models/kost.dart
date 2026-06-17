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
}
