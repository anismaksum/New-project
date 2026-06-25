import '../models/booking_request.dart';
import '../models/kost.dart';
import 'kost_seed.dart';

final Kost _cendanaEksklusif = kostSeed.firstWhere(
  (Kost kost) => kost.id == 'cendana-eksklusif',
);

final Kost _kostMelatiResidence = kostSeed.firstWhere(
  (Kost kost) => kost.id == 'kost-melati-residence',
);

final List<BookingRequest> bookingSeed = <BookingRequest>[
  BookingRequest(
    id: 'BK-1002',
    kost: _cendanaEksklusif,
    customerName: 'Nadia Putri',
    customerPhone: '628121110002',
    scheduleLabel: 'Masuk 15 Jun 2026',
    status: 'Diterima',
    notificationStatus: 'Terkirim ke WhatsApp customer',
    notificationReference: 'WA-BK-1002',
    notificationMessage:
        'Update booking Cendana Eksklusif: status kamu sekarang Diterima.',
  ),
  BookingRequest(
    id: 'BK-1001',
    kost: _kostMelatiResidence,
    customerName: 'Raka Pratama',
    customerPhone: '628121110001',
    scheduleLabel: 'Survey 08 Jun 2026',
    status: 'Pending',
    notificationStatus: 'Terkirim ke WhatsApp admin',
    notificationReference: 'WA-BK-1001',
    notificationMessage:
        'Ada booking baru untuk Kost Melati Residence dari Raka Pratama.',
  ),
];
