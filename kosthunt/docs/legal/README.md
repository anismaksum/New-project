# KostHunt Legal And Policy Drafts

Dokumen ini adalah draft operasional untuk kebutuhan Play Store dan production.
Sebelum rilis publik, minta review legal/bisnis agar istilah, biaya, refund,
dan kewajiban platform sesuai model usaha KostHunt.

## Privacy Policy

KostHunt mengumpulkan data akun seperti nama, email, nomor telepon, role akun,
data profil owner, data listing, foto kost, favorit, booking, payment status,
chat customer-owner, support message, notification, review, report, device token
FCM, dan audit operasional. Data dipakai untuk menjalankan marketplace kost,
memproses booking dan pembayaran, mengirim notifikasi, menangani support,
mencegah fraud, menyelesaikan dispute, dan memenuhi kewajiban hukum.

Secret seperti Duitku API key, Supabase service role key, dan Firebase service
account tidak disimpan di aplikasi Flutter. Data sensitif payment diproses lewat
backend atau Supabase Edge Functions. User dapat meminta penghapusan akun dari
halaman profil. Beberapa data transaksi, audit, dan dispute dapat disimpan lebih
lama sesuai kebutuhan hukum dan rekonsiliasi.

## Terms And Conditions

KostHunt adalah platform perantara marketplace kost antara customer dan owner.
Customer wajib memberi data benar, menjaga etika chat, dan membayar sesuai total
sewa yang ditampilkan. Owner wajib memastikan listing, harga, ketersediaan unit,
foto, fasilitas, dan aturan kost benar. KostHunt dapat membatasi akun, menurunkan
listing, memproses refund, atau menahan payout bila ada indikasi fraud, sengketa,
atau pelanggaran kebijakan.

## Refund Policy

Refund dapat diajukan dari halaman booking/payment bila transaksi sudah paid dan
ada alasan valid seperti pembatalan, listing tidak sesuai, owner tidak dapat
menyediakan unit, atau sengketa lain. Status refund minimum: requested,
approved, processed, rejected, cancelled. Admin meninjau bukti dari booking,
payment, chat, support, report, dan audit log. Biaya gateway/platform mengikuti
kebijakan bisnis yang berlaku saat transaksi.

## Owner Agreement

Owner dapat publish listing langsung setelah data wajib valid. Owner bertanggung
jawab atas legalitas kost, keakuratan harga, foto, aturan, fasilitas, dan
ketersediaan unit. Owner setuju bahwa dana sewa penuh masuk ke platform lebih
dulu dan menjadi pending balance sampai syarat release terpenuhi. KostHunt dapat
suspend listing atau akun owner bila ada laporan, indikasi penipuan, data palsu,
atau pelanggaran moderation policy.

## Payment And Payout Policy

Pembayaran customer diproses melalui Duitku. Status pembayaran hanya valid dari
callback/webhook Duitku yang lolos verifikasi signature, amount, dan merchant
order ID. Redirect payment tidak dianggap bukti sukses. Setelah payment paid,
owner_amount masuk ke pending balance. Setelah masa aman atau booking completed,
saldo dapat dipindah ke available balance. Owner dapat meminta payout manual.
Admin menandai payout paid setelah transfer selesai.

## Account Deletion Policy

User dapat meminta penghapusan akun dari halaman profil. KostHunt akan meninjau
booking aktif, payment, refund, payout, dispute, dan kewajiban hukum sebelum
menghapus atau menganonimkan data. Data chat/support/report/audit yang terkait
transaksi dapat tetap disimpan secara terbatas untuk keamanan, dispute, dan
rekonsiliasi.

## Moderation Policy

Listing, chat, review, dan report dimoderasi untuk mencegah penipuan, spam,
konten palsu, pelecehan, dan penyalahgunaan platform. Admin dapat memberi status
suspended pada listing, membatasi user, menyelesaikan report, dan mencatat aksi
ke audit log. Chat customer-owner dan support internal dapat ditinjau untuk
kebutuhan dispute, report, dan keamanan sesuai privacy policy.
