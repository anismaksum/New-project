-- Optional seed data for the current KostHunt prototype listings.

insert into public.owners (id, display_name, phone, verified)
values
  ('00000000-0000-0000-0000-000000000101', 'Ibu Ratna', '628122220001', true),
  ('00000000-0000-0000-0000-000000000102', 'Bapak Ardi', '628122220002', true),
  ('00000000-0000-0000-0000-000000000103', 'Ibu Sari', '628122220003', false),
  ('00000000-0000-0000-0000-000000000104', 'Mas Dimas', '628122220004', true)
on conflict (id) do update set
  display_name = excluded.display_name,
  phone = excluded.phone,
  verified = excluded.verified;

insert into public.kosts (
  id,
  owner_id,
  name,
  city,
  address,
  price,
  distance_km,
  image_url,
  facilities,
  is_verified,
  is_available,
  category,
  owner_name,
  owner_phone,
  description
)
values
  (
    'kost-melati-residence',
    '00000000-0000-0000-0000-000000000101',
    'Kost Melati Residence',
    'Yogyakarta',
    'Jl. Kaliurang KM 5, dekat UGM',
    1850000,
    0.8,
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80',
    array['WiFi', 'AC', 'Parkir', 'Laundry'],
    true,
    true,
    'Dekat Kampus',
    'Ibu Ratna',
    '628122220001',
    'Hunian tenang dengan kamar terang, akses cepat ke kampus, area komunal bersih, dan pengelola responsif untuk kebutuhan harian.'
  ),
  (
    'cendana-eksklusif',
    '00000000-0000-0000-0000-000000000102',
    'Cendana Eksklusif',
    'Bandung',
    'Jl. Dipatiukur No. 21',
    2450000,
    1.2,
    'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
    array['WiFi', 'AC', 'Kamar Mandi Dalam', 'Premium'],
    true,
    true,
    'Premium',
    'Bapak Ardi',
    '628122220002',
    'Kost eksklusif dengan keamanan baik, kamar berperabot, dan lokasi strategis untuk mahasiswa maupun pekerja muda.'
  ),
  (
    'kost-putri-anggrek',
    '00000000-0000-0000-0000-000000000103',
    'Kost Putri Anggrek',
    'Depok',
    'Jl. Margonda Raya, dekat UI',
    1650000,
    0.6,
    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80',
    array['WiFi', 'Dapur Bersama', 'Laundry', 'Dekat Kampus'],
    false,
    true,
    'Putri',
    'Ibu Sari',
    '628122220003',
    'Pilihan kost putri yang rapi dan hangat, cocok untuk mahasiswa baru yang ingin tinggal dekat kampus dan transportasi umum.'
  ),
  (
    'ruang-huni-merdeka',
    '00000000-0000-0000-0000-000000000104',
    'Ruang Huni Merdeka',
    'Malang',
    'Jl. Soekarno Hatta, area kampus',
    1350000,
    2.1,
    'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80',
    array['WiFi', 'Parkir', 'Ruang Tamu', 'Kontrakan'],
    true,
    false,
    'Kontrakan',
    'Mas Dimas',
    '628122220004',
    'Unit hunian fleksibel untuk pekerja muda atau pasangan, dengan area parkir, ruang bersama, dan lingkungan yang mudah dijangkau.'
  )
on conflict (id) do update set
  owner_id = excluded.owner_id,
  name = excluded.name,
  city = excluded.city,
  address = excluded.address,
  price = excluded.price,
  distance_km = excluded.distance_km,
  image_url = excluded.image_url,
  facilities = excluded.facilities,
  is_verified = excluded.is_verified,
  is_available = excluded.is_available,
  category = excluded.category,
  owner_name = excluded.owner_name,
  owner_phone = excluded.owner_phone,
  description = excluded.description;
