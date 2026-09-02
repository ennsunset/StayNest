// shared/mock/mock_hostels.dart
//
// Seed data for Sprint 2. Every screen that shows a hostel draws from here.
// Replace with real API calls in Sprint 2 backend integration.
//
// All prices are integer pesewas (D1).

class MockHostel {
  const MockHostel({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.fromPricePesewas,
    this.rating,
    this.reviewCount,
    this.verified = false,
    this.amenities = const [],
    this.slotsLeft,
  });

  final String id;
  final String name;
  final String location;
  final String? imageUrl;
  final int fromPricePesewas;
  final double? rating;
  final int? reviewCount;
  final bool verified;
  final List<String> amenities;
  final int? slotsLeft;
}

abstract final class MockData {
  static const featured = [
    MockHostel(
      id: '1',
      name: 'Royal Palms Hostel',
      location: 'Near North Campus',
      imageUrl: null,
      fromPricePesewas: 320000,
      rating: 4.8,
      reviewCount: 124,
      verified: true,
      amenities: ['WiFi', 'Power', 'Security'],
      slotsLeft: 12,
    ),
    MockHostel(
      id: '2',
      name: 'Elite Residency',
      location: 'Near South Campus',
      imageUrl: null,
      fromPricePesewas: 550000,
      rating: 4.6,
      reviewCount: 89,
      verified: true,
      amenities: ['WiFi', 'AC', 'Power'],
      slotsLeft: 2,
    ),
    MockHostel(
      id: '3',
      name: 'Campus View Lodge',
      location: 'Near Main Gate',
      imageUrl: null,
      fromPricePesewas: 280000,
      rating: 4.3,
      reviewCount: 56,
      verified: false,
      amenities: ['WiFi', 'Laundry'],
      slotsLeft: 8,
    ),
    MockHostel(
      id: '4',
      name: 'Prestige Hall',
      location: 'Near Engineering Block',
      imageUrl: null,
      fromPricePesewas: 450000,
      rating: 4.9,
      reviewCount: 201,
      verified: true,
      amenities: ['WiFi', 'Power', 'AC', 'Security'],
      slotsLeft: 5,
    ),
  ];

  static const amenityGrid = [
    AmenityItem(label: 'Fast WiFi', icon: 'wifi'),
    AmenityItem(label: 'Backup Power', icon: 'power'),
    AmenityItem(label: 'Security', icon: 'security'),
    AmenityItem(label: 'Laundry', icon: 'laundry'),
    AmenityItem(label: 'Air Conditioning', icon: 'ac'),
    AmenityItem(label: 'Water Supply', icon: 'water'),
  ];
}

class AmenityItem {
  const AmenityItem({required this.label, required this.icon});
  final String label;
  final String icon;
}
