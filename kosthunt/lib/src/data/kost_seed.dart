import '../models/kost.dart';

const List<Kost> kostSeed = <Kost>[
  Kost(
    id: 'kost-melati-residence',
    name: 'Kost Melati Residence',
    city: 'Yogyakarta',
    address: 'Jl. Kaliurang KM 5, dekat UGM',
    price: 1850000,
    distanceKm: 0.8,
    imageUrl:
        'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80',
    facilities: <String>['WiFi', 'AC', 'Parkir', 'Laundry'],
    isVerified: true,
    isAvailable: true,
    category: 'Dekat Kampus',
    ownerName: 'Ibu Ratna',
    ownerPhone: '628122220001',
    description:
        'Hunian tenang dengan kamar terang, akses cepat ke kampus, area komunal bersih, dan pengelola responsif untuk kebutuhan harian.',
  ),
  Kost(
    id: 'cendana-eksklusif',
    name: 'Cendana Eksklusif',
    city: 'Bandung',
    address: 'Jl. Dipatiukur No. 21',
    price: 2450000,
    distanceKm: 1.2,
    imageUrl:
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
    facilities: <String>['WiFi', 'AC', 'Kamar Mandi Dalam', 'Premium'],
    isVerified: true,
    isAvailable: true,
    category: 'Premium',
    ownerName: 'Bapak Ardi',
    ownerPhone: '628122220002',
    description:
        'Kost eksklusif dengan keamanan baik, kamar berperabot, dan lokasi strategis untuk mahasiswa maupun pekerja muda.',
  ),
  Kost(
    id: 'kost-putri-anggrek',
    name: 'Kost Putri Anggrek',
    city: 'Depok',
    address: 'Jl. Margonda Raya, dekat UI',
    price: 1650000,
    distanceKm: 0.6,
    imageUrl:
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80',
    facilities: <String>['WiFi', 'Dapur Bersama', 'Laundry', 'Dekat Kampus'],
    isVerified: false,
    isAvailable: true,
    category: 'Putri',
    ownerName: 'Ibu Sari',
    ownerPhone: '628122220003',
    description:
        'Pilihan kost putri yang rapi dan hangat, cocok untuk mahasiswa baru yang ingin tinggal dekat kampus dan transportasi umum.',
  ),
  Kost(
    id: 'ruang-huni-merdeka',
    name: 'Ruang Huni Merdeka',
    city: 'Malang',
    address: 'Jl. Soekarno Hatta, area kampus',
    price: 1350000,
    distanceKm: 2.1,
    imageUrl:
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80',
    facilities: <String>['WiFi', 'Parkir', 'Ruang Tamu', 'Kontrakan'],
    isVerified: true,
    isAvailable: false,
    category: 'Kontrakan',
    ownerName: 'Mas Dimas',
    ownerPhone: '628122220004',
    description:
        'Unit hunian fleksibel untuk pekerja muda atau pasangan, dengan area parkir, ruang bersama, dan lingkungan yang mudah dijangkau.',
  ),
];
