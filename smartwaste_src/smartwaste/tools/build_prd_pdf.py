from __future__ import annotations

from datetime import date
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import (
    Image,
    KeepTogether,
    ListFlowable,
    ListItem,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
DOCS_DIR = ROOT / "docs"
OUTPUT_PDF = DOCS_DIR / "PRD_SmartWaste_Muhammad_Anis_Maksum_Winarso.pdf"

GREEN_DARK = colors.HexColor("#0B3B2E")
GREEN = colors.HexColor("#0E7A50")
GREEN_SOFT = colors.HexColor("#EAF3EA")
LIME = colors.HexColor("#A9D95A")
AMBER = colors.HexColor("#F2A93B")
CORAL = colors.HexColor("#E86D5A")
TEAL = colors.HexColor("#2F8078")
INK = colors.HexColor("#10231D")
MUTED = colors.HexColor("#66756F")
BORDER = colors.HexColor("#DDE8DE")
BG = colors.HexColor("#F6F8F3")
WHITE = colors.white


def stylesheet():
    styles = getSampleStyleSheet()
    styles.add(
        ParagraphStyle(
            name="CoverTitle",
            parent=styles["Title"],
            fontName="Helvetica-Bold",
            fontSize=25,
            leading=31,
            alignment=TA_CENTER,
            textColor=GREEN_DARK,
            spaceAfter=8,
        )
    )
    styles.add(
        ParagraphStyle(
            name="CoverSubtitle",
            parent=styles["Normal"],
            fontName="Helvetica-Bold",
            fontSize=16,
            leading=22,
            alignment=TA_CENTER,
            textColor=GREEN,
            spaceAfter=10,
        )
    )
    styles.add(
        ParagraphStyle(
            name="Body",
            parent=styles["BodyText"],
            fontName="Helvetica",
            fontSize=9.7,
            leading=13.2,
            textColor=INK,
            spaceAfter=7,
        )
    )
    styles.add(
        ParagraphStyle(
            name="SmallMuted",
            parent=styles["Body"],
            fontName="Helvetica",
            fontSize=8.5,
            leading=11,
            alignment=TA_CENTER,
            textColor=MUTED,
            spaceAfter=6,
        )
    )
    styles.add(
        ParagraphStyle(
            name="H1",
            parent=styles["Heading1"],
            fontName="Helvetica-Bold",
            fontSize=15,
            leading=19,
            textColor=GREEN_DARK,
            spaceBefore=10,
            spaceAfter=7,
        )
    )
    styles.add(
        ParagraphStyle(
            name="H2",
            parent=styles["Heading2"],
            fontName="Helvetica-Bold",
            fontSize=12,
            leading=15,
            textColor=GREEN,
            spaceBefore=7,
            spaceAfter=5,
        )
    )
    styles.add(
        ParagraphStyle(
            name="H3",
            parent=styles["Heading3"],
            fontName="Helvetica-Bold",
            fontSize=10.5,
            leading=13,
            textColor=INK,
            spaceBefore=5,
            spaceAfter=4,
        )
    )
    styles.add(
        ParagraphStyle(
            name="TableHeader",
            parent=styles["Body"],
            fontName="Helvetica-Bold",
            fontSize=8.6,
            leading=10.8,
            textColor=GREEN_DARK,
            spaceAfter=0,
        )
    )
    styles.add(
        ParagraphStyle(
            name="TableBody",
            parent=styles["Body"],
            fontName="Helvetica",
            fontSize=8.4,
            leading=10.8,
            textColor=INK,
            spaceAfter=0,
        )
    )
    styles.add(
        ParagraphStyle(
            name="CalloutTitle",
            parent=styles["Body"],
            fontName="Helvetica-Bold",
            fontSize=10,
            leading=12,
            textColor=GREEN_DARK,
            spaceAfter=3,
        )
    )
    styles.add(
        ParagraphStyle(
            name="BulletText",
            parent=styles["Body"],
            leftIndent=12,
            bulletIndent=0,
            spaceAfter=4,
        )
    )
    return styles


STYLES = stylesheet()


def p(text: str, style: str = "Body") -> Paragraph:
    return Paragraph(text, STYLES[style])


def header_footer(canvas, doc) -> None:
    canvas.saveState()
    width, height = A4
    canvas.setStrokeColor(BORDER)
    canvas.setLineWidth(0.5)
    canvas.line(doc.leftMargin, height - 1.28 * cm, width - doc.rightMargin, height - 1.28 * cm)
    canvas.setFillColor(MUTED)
    canvas.setFont("Helvetica", 7.5)
    canvas.drawString(doc.leftMargin, height - 1.05 * cm, "Product Requirement Document - SmartWaste")
    canvas.drawRightString(width - doc.rightMargin, 1.0 * cm, f"Halaman {doc.page}")
    canvas.restoreState()


def bullets(items: list[str]) -> ListFlowable:
    return ListFlowable(
        [
            ListItem(p(item, "Body"), bulletColor=GREEN, leftIndent=12)
            for item in items
        ],
        bulletType="bullet",
        start="circle",
        leftIndent=16,
        bulletFontName="Helvetica",
        bulletFontSize=6,
    )


def numbered(items: list[str]) -> ListFlowable:
    return ListFlowable(
        [ListItem(p(item, "Body"), leftIndent=16) for item in items],
        bulletType="1",
        leftIndent=18,
        bulletFontName="Helvetica-Bold",
        bulletFontSize=8,
    )


def callout(title: str, body: str, fill=GREEN_SOFT) -> Table:
    table = Table(
        [[p(title, "CalloutTitle")], [p(body, "Body")]],
        colWidths=[17.0 * cm],
        hAlign="LEFT",
    )
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), fill),
                ("BOX", (0, 0), (-1, -1), 0.5, fill),
                ("LEFTPADDING", (0, 0), (-1, -1), 12),
                ("RIGHTPADDING", (0, 0), (-1, -1), 12),
                ("TOPPADDING", (0, 0), (-1, -1), 7),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
            ]
        )
    )
    return table


def simple_table(headers: list[str], rows: list[list[str]], widths: list[float]) -> Table:
    data = [[p(header, "TableHeader") for header in headers]]
    data.extend([[p(value, "TableBody") for value in row] for row in rows])
    table = Table(data, colWidths=[width * cm for width in widths], hAlign="LEFT", repeatRows=1)
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), GREEN_SOFT),
                ("TEXTCOLOR", (0, 0), (-1, 0), GREEN_DARK),
                ("GRID", (0, 0), (-1, -1), 0.45, BORDER),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 7),
                ("RIGHTPADDING", (0, 0), (-1, -1), 7),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )
    return table


def cover_block() -> list:
    metadata = simple_table(
        ["Informasi", "Detail"],
        [
            ["Nama Produk", "SmartWaste"],
            ["Jenis Dokumen", "Product Requirement Document (PRD)"],
            ["Versi", "1.0"],
            ["Tanggal", date.today().strftime("%d %B %Y")],
            ["Penyusun", "Muhammad Anis Maksum Winarso"],
            ["Platform", "Flutter Android, Web preview, dan cross-platform ready"],
            ["Output Build", "Android App Bundle (.aab) release"],
        ],
        [4.6, 12.4],
    )
    return [
        Spacer(1, 2.0 * cm),
        p("Product Requirement Document", "CoverTitle"),
        p("Aplikasi SmartWaste", "CoverSubtitle"),
        p("Panduan fitur, fungsi, tujuan, perilaku aplikasi, dan cara pengumpulan", "SmallMuted"),
        Spacer(1, 0.65 * cm),
        callout(
            "Ringkasan dokumen",
            "Dokumen ini menjelaskan kebutuhan produk SmartWaste versi mobile: aplikasi pengelolaan setoran sampah bernilai, reward Eco Pts, kalkulator poin, penjadwalan pickup, panduan sortasi, serta profil pengguna. PRD ini juga memuat cara pengumpulan kebutuhan dan tata cara pengumpulan laporan/proyek.",
        ),
        Spacer(1, 0.55 * cm),
        metadata,
        PageBreak(),
    ]


def category_visual_table() -> Table:
    assets = [
        ("Plastik", ROOT / "assets" / "images.jpg", "50 Eco Pts/kg"),
        ("Logam", ROOT / "assets" / "download(2).jpg", "120 Eco Pts/kg"),
        ("Kertas", ROOT / "assets" / "download(3).jpg", "30 Eco Pts/kg"),
        ("Kaca", ROOT / "assets" / "wew.jpg", "80 Eco Pts/kg"),
    ]
    row = []
    for name, path, points in assets:
        image = Image(str(path), width=3.2 * cm, height=2.25 * cm)
        row.append([image, p(f"<b>{name}</b>", "TableBody"), p(points, "TableBody")])
    table = Table([row], colWidths=[4.25 * cm] * 4, hAlign="LEFT")
    table.setStyle(
        TableStyle(
            [
                ("GRID", (0, 0), (-1, -1), 0.45, BORDER),
                ("BACKGROUND", (0, 0), (-1, -1), colors.white),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                ("LEFTPADDING", (0, 0), (-1, -1), 7),
                ("RIGHTPADDING", (0, 0), (-1, -1), 7),
                ("TOPPADDING", (0, 0), (-1, -1), 8),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
            ]
        )
    )
    return table


def build_story() -> list:
    story = []
    story.extend(cover_block())

    story.append(p("Daftar Isi", "H1"))
    story.append(
        numbered(
            [
                "Ringkasan Eksekutif",
                "Latar Belakang dan Masalah",
                "Tujuan Produk dan Sasaran",
                "Ruang Lingkup Produk",
                "Target Pengguna",
                "Fitur dan Perilaku Aplikasi",
                "Kebutuhan Fungsional",
                "Kebutuhan Non-Fungsional",
                "Alur Pengguna dan Aturan Bisnis",
                "Spesifikasi UI/UX",
                "Pengujian dan Kriteria Penerimaan",
                "Cara Pengumpulan Kebutuhan",
                "Cara Pengumpulan/Penyerahan Tugas",
                "Lampiran Teknis",
            ]
        )
    )
    story.append(PageBreak())

    story.append(p("1. Ringkasan Eksekutif", "H1"))
    story.append(
        p(
            "SmartWaste adalah aplikasi mobile berbasis Flutter untuk membantu pengguna menyetorkan sampah bernilai secara lebih terarah. Aplikasi menggabungkan informasi kategori sampah, estimasi reward Eco Pts, penjadwalan penjemputan kurir, panduan sortasi, serta profil pengguna dalam satu pengalaman yang ringan dan mudah dipahami."
        )
    )
    story.append(
        callout(
            "Visi produk",
            "Membuat aktivitas memilah dan menyetor sampah terasa sederhana, terukur, dan memberi umpan balik yang jelas bagi pengguna.",
        )
    )
    story.append(Spacer(1, 0.25 * cm))
    story.append(category_visual_table())

    story.append(p("2. Latar Belakang dan Masalah", "H1"))
    story.append(
        p(
            "Pengelolaan sampah rumah tangga sering terkendala oleh minimnya informasi kategori, ketidakjelasan nilai tukar, dan proses penjemputan yang belum praktis. Pengguna membutuhkan aplikasi yang tidak hanya tampil menarik, tetapi juga membantu mengambil keputusan: sampah apa yang disetor, berapa estimasi poinnya, dan kapan kurir dapat mengambilnya."
        )
    )
    story.append(
        bullets(
            [
                "Pengguna belum selalu mengetahui jenis sampah yang dapat didaur ulang.",
                "Estimasi poin/reward sering tidak terlihat sebelum setoran dilakukan.",
                "Penjadwalan pickup manual dapat menyebabkan miskomunikasi waktu dan catatan lokasi.",
                "Informasi riwayat dan status pengguna belum tersaji ringkas.",
            ]
        )
    )

    story.append(p("3. Tujuan Produk dan Sasaran", "H1"))
    story.append(
        simple_table(
            ["Tujuan", "Indikator Keberhasilan"],
            [
                ["Memudahkan pemilahan sampah", "Pengguna dapat memilih kategori sampah dan membaca tips sortasi dalam kurang dari 2 tap."],
                ["Menghitung reward secara transparan", "Pengguna dapat melihat estimasi Eco Pts berdasarkan kategori dan berat."],
                ["Mempercepat proses pickup", "Pengguna dapat memilih slot jemput dan menambahkan catatan kurir."],
                ["Meningkatkan motivasi pengguna", "Dashboard menampilkan total Eco Pts, progress reward, dan ringkasan pickup."],
            ],
            [6, 11],
        )
    )

    story.append(p("4. Ruang Lingkup Produk", "H1"))
    story.append(p("Termasuk dalam versi 1.0", "H2"))
    story.append(
        bullets(
            [
                "Login demo dengan validasi input.",
                "Dashboard reward dan metrik ringkas.",
                "Kategori sampah: plastik, logam, kertas, kaca.",
                "Kalkulator Eco Pts berdasarkan berat sampah.",
                "Catat setoran untuk menambah total Eco Pts.",
                "Penjadwalan pickup dengan slot waktu dan catatan.",
                "Panduan sortasi per kategori.",
                "Profil pengguna, reminder pickup, status pickup terakhir, dan logout.",
            ]
        )
    )
    story.append(p("Di luar lingkup versi 1.0", "H2"))
    story.append(
        bullets(
            [
                "Autentikasi backend real-time.",
                "Peta lokasi GPS dan pelacakan kurir langsung.",
                "Pembayaran atau penukaran voucher sungguhan.",
                "Integrasi database cloud dan notifikasi push asli.",
            ]
        )
    )

    story.append(p("5. Target Pengguna", "H1"))
    story.append(
        simple_table(
            ["Persona", "Kebutuhan", "Perilaku yang Didukung"],
            [
                ["Warga rumah tangga", "Menyetor sampah daur ulang dengan cepat.", "Memilih kategori, menghitung poin, menjadwalkan pickup."],
                ["Petugas bank sampah", "Melihat kategori dan catatan setoran.", "Membaca catatan pickup dan memahami jenis sampah yang disiapkan."],
                ["Mahasiswa/pengguna edukasi", "Memahami alur aplikasi smart waste.", "Mempelajari fitur, UI/UX, dan proses build aplikasi."],
            ],
            [4, 6, 7],
        )
    )

    story.append(PageBreak())
    story.append(p("6. Fitur dan Perilaku Aplikasi", "H1"))
    feature_sections = [
        (
            "6.1 Login",
            [
                "Pengguna memasukkan username dan password.",
                "Aplikasi menyediakan tombol Isi Demo untuk mengisi akun contoh admin/12345.",
                "Password dapat ditampilkan atau disembunyikan.",
                "Jika kredensial benar, pengguna masuk ke dashboard; jika salah, aplikasi menampilkan snackbar informasi.",
            ],
        ),
        (
            "6.2 Dashboard Beranda",
            [
                "Menampilkan sapaan, total Eco Pts, progress menuju voucher, jumlah pickup, dan estimasi penghematan CO2.",
                "Menyediakan shortcut Scan, Bank Sampah, Riwayat, dan Jemput.",
                "Menampilkan kartu kategori sampah dengan gambar lokal agar tetap tampil tanpa jaringan internet.",
            ],
        ),
        (
            "6.3 Smart Tools",
            [
                "Pengguna memilih kategori sampah melalui choice chip.",
                "Pengguna mengatur berat sampah memakai slider atau tombol tambah/kurang.",
                "Aplikasi menghitung Eco Pts berdasarkan rumus: berat kg x poin per kg.",
                "Tombol Catat Setoran menambahkan poin ke total pengguna.",
                "Pengguna dapat memilih slot pickup dan menambahkan catatan untuk kurir.",
                "Switch reminder pickup dapat diaktifkan atau dinonaktifkan.",
            ],
        ),
        (
            "6.4 Profil",
            [
                "Menampilkan identitas pengguna, program studi, kampus, total Eco Pts, dan jumlah pickup.",
                "Menampilkan status reminder, jadwal pickup terakhir, dan catatan pickup.",
                "Logout mengembalikan pengguna ke halaman login dan membersihkan stack navigasi.",
            ],
        ),
    ]
    for title, items in feature_sections:
        story.append(p(title, "H2"))
        story.append(bullets(items))

    story.append(p("7. Kebutuhan Fungsional", "H1"))
    story.append(
        simple_table(
            ["ID", "Kebutuhan", "Prioritas", "Kriteria Penerimaan"],
            [
                ["FR-01", "Aplikasi harus menyediakan login demo.", "Must", "Akun admin/12345 dapat masuk ke dashboard."],
                ["FR-02", "Aplikasi harus memvalidasi input login.", "Must", "Input kosong atau salah menampilkan pesan yang jelas."],
                ["FR-03", "Dashboard harus menampilkan total Eco Pts.", "Must", "Nilai poin terlihat di kartu reward utama."],
                ["FR-04", "Pengguna harus dapat memilih kategori sampah.", "Must", "Kategori terpilih terlihat secara visual."],
                ["FR-05", "Kalkulator harus menghitung Eco Pts.", "Must", "Perubahan berat mengubah estimasi poin."],
                ["FR-06", "Pengguna harus dapat mencatat setoran.", "Should", "Total Eco Pts bertambah dan snackbar muncul."],
                ["FR-07", "Pengguna harus dapat menjadwalkan pickup.", "Must", "Slot dan catatan tersimpan di profil."],
                ["FR-08", "Aplikasi harus menyediakan panduan sortasi.", "Should", "Tips tiap kategori dapat dibuka di halaman Tools."],
                ["FR-09", "Aplikasi harus menyediakan logout.", "Must", "Logout membawa pengguna ke halaman login."],
            ],
            [1.5, 5.2, 2.0, 8.3],
        )
    )

    story.append(p("8. Kebutuhan Non-Fungsional", "H1"))
    story.append(
        simple_table(
            ["Aspek", "Kebutuhan"],
            [
                ["Kinerja", "Transisi halaman dan interaksi kalkulator harus terasa responsif pada perangkat Android umum."],
                ["Aksesibilitas", "Kontras teks harus cukup, tombol memiliki ikon yang familiar, dan label input mudah dipahami."],
                ["Keandalan", "Aset kategori memakai gambar lokal agar UI tidak rusak saat offline."],
                ["Maintainability", "Tema warna dan style dipusatkan di AppTheme agar konsisten dan mudah diubah."],
                ["Portabilitas", "Kode Flutter siap dijalankan pada Android dan web preview."],
                ["Keamanan", "Versi demo tidak menyimpan data sensitif; autentikasi produksi perlu backend dan hashing password."],
            ],
            [4, 13],
        )
    )

    story.append(PageBreak())
    story.append(p("9. Alur Pengguna dan Aturan Bisnis", "H1"))
    story.append(p("Alur utama pengguna", "H2"))
    story.append(
        numbered(
            [
                "Pengguna membuka aplikasi dan masuk menggunakan akun demo.",
                "Pengguna melihat dashboard reward dan memilih kategori sampah.",
                "Pengguna membuka tab Tools untuk menghitung poin berdasarkan berat.",
                "Pengguna mencatat setoran sehingga total Eco Pts bertambah.",
                "Pengguna menjadwalkan pickup dan menambahkan catatan untuk kurir.",
                "Pengguna membuka profil untuk melihat ringkasan status dan melakukan logout.",
            ]
        )
    )
    story.append(p("Aturan bisnis utama", "H2"))
    story.append(
        simple_table(
            ["Kategori", "Poin per Kg", "Catatan Sortasi"],
            [
                ["Plastik", "50", "Bilas, keringkan, dan pipihkan."],
                ["Logam", "120", "Pisahkan dari sampah basah dan material tajam."],
                ["Kertas", "30", "Ikat rapi dan jauhkan dari minyak/air."],
                ["Kaca", "80", "Bungkus pecahan dan beri tanda."],
            ],
            [4, 3, 10],
        )
    )

    story.append(p("10. Spesifikasi UI/UX", "H1"))
    story.append(
        bullets(
            [
                "Gaya visual menggunakan eco-minimalism yang bersih, terang, dan modern.",
                "Warna utama hijau tua dan hijau aksen, dilengkapi amber, teal, dan coral agar kategori tidak monoton.",
                "Komponen utama memakai radius 8 px agar tampil rapi dan konsisten.",
                "Navigasi bawah terdiri dari Beranda, Tools, dan Profil untuk memisahkan tugas utama.",
                "Kontrol interaktif memakai pola yang familiar: slider untuk berat, switch untuk reminder, dropdown untuk slot pickup, dan chip untuk kategori.",
                "Konten penting diletakkan di atas: reward, metrik, dan shortcut tindakan cepat.",
            ]
        )
    )
    story.append(
        callout(
            "Prinsip pengalaman",
            "Pengguna tidak perlu membaca instruksi panjang di layar. Setiap fitur memakai label singkat, ikon familiar, dan umpan balik langsung melalui snackbar, dialog, atau perubahan status.",
            colors.HexColor("#FFF6E5"),
        )
    )

    story.append(p("11. Pengujian dan Kriteria Penerimaan", "H1"))
    story.append(
        simple_table(
            ["Area", "Skenario", "Status"],
            [
                ["Static analysis", "Menjalankan flutter analyze.", "Lulus, no issues found."],
                ["Widget test", "Login demo membuka dashboard.", "Lulus."],
                ["Widget test", "Tools dapat mencatat setoran.", "Lulus."],
                ["Build release", "Menjalankan flutter build appbundle.", "Lulus, menghasilkan app-release.aab."],
                ["Preview web", "Server lokal merespons http://127.0.0.1:54545.", "Lulus, HTTP 200."],
            ],
            [3.5, 9, 4.5],
        )
    )
    story.append(p("Kriteria penerimaan versi 1.0", "H2"))
    story.append(
        bullets(
            [
                "Aplikasi dapat dibuka dan pengguna dapat login memakai akun demo.",
                "Dashboard menampilkan reward, kategori, dan shortcut tanpa error gambar.",
                "Kalkulator poin menghasilkan nilai sesuai kategori dan berat.",
                "Catat setoran menambah total Eco Pts.",
                "Jadwal pickup tersimpan dan tampil pada profil.",
                "Build .aab selesai tanpa error Gradle.",
            ]
        )
    )

    story.append(PageBreak())
    story.append(p("12. Cara Pengumpulan Kebutuhan", "H1"))
    story.append(
        p(
            "Cara pengumpulan kebutuhan dipakai untuk memastikan fitur SmartWaste benar-benar sesuai dengan masalah pengguna dan proses operasional bank sampah."
        )
    )
    story.append(
        simple_table(
            ["Metode", "Tujuan", "Output"],
            [
                ["Observasi", "Melihat alur pemilahan, penimbangan, dan pickup sampah.", "Catatan proses, titik masalah, dan peluang fitur."],
                ["Wawancara", "Menggali kebutuhan warga, petugas, dan pengelola bank sampah.", "Daftar kebutuhan pengguna dan prioritas."],
                ["Studi dokumen", "Mempelajari daftar kategori, harga/poin, dan aturan sortasi.", "Aturan bisnis kategori sampah."],
                ["Benchmarking", "Membandingkan aplikasi atau layanan serupa.", "Referensi fitur dan standar UX."],
                ["Uji prototipe", "Memvalidasi apakah pengguna paham alur aplikasi.", "Masukan UI/UX dan daftar perbaikan."],
            ],
            [3.5, 7, 6.5],
        )
    )

    story.append(p("13. Cara Pengumpulan/Penyerahan Tugas", "H1"))
    story.append(
        p(
            "Bagian ini menjelaskan cara mengumpulkan hasil pekerjaan aplikasi SmartWaste agar pemeriksaan tugas lebih mudah dan lengkap."
        )
    )
    story.append(
        numbered(
            [
                "Pastikan folder proyek Flutter sudah dapat dibuka dan menjalankan flutter pub get.",
                "Pastikan hasil analisis bersih dengan perintah flutter analyze.",
                "Pastikan pengujian lulus dengan perintah flutter test.",
                "Buat Android App Bundle dengan perintah flutter build appbundle.",
                "Siapkan file PDF PRD sebagai laporan utama.",
                "Kumpulkan source code proyek dalam bentuk folder atau ZIP.",
                "Kumpulkan file app-release.aab dari folder build/app/outputs/bundle/release.",
                "Gunakan penamaan file yang jelas, misalnya PRD_SmartWaste_Muhammad_Anis_Maksum_Winarso.pdf dan smartwaste_source.zip.",
                "Upload ke LMS, Google Drive, atau media pengumpulan yang diminta dosen/guru.",
                "Jika memakai Google Drive, pastikan permission file dapat diakses oleh pemeriksa.",
            ]
        )
    )
    story.append(p("Checklist pengumpulan", "H2"))
    story.append(
        simple_table(
            ["No", "Item", "Status"],
            [
                ["1", "PDF laporan PRD", "Wajib"],
                ["2", "Source code Flutter", "Wajib"],
                ["3", "File app-release.aab", "Wajib"],
                ["4", "Screenshot aplikasi atau link preview", "Opsional"],
                ["5", "Catatan akun demo: admin / 12345", "Disarankan"],
            ],
            [1.2, 11, 4.8],
        )
    )

    story.append(p("14. Lampiran Teknis", "H1"))
    story.append(
        simple_table(
            ["Item", "Keterangan"],
            [
                ["Framework", "Flutter 3.41.4, Dart 3.11.1"],
                ["Entry point", "lib/main.dart"],
                ["Screen utama", "login_screen.dart, home_screen.dart, profile_screen.dart"],
                ["Tema", "lib/theme/app_theme.dart"],
                ["Aset lokal", "assets/images.jpg, download(2).jpg, download(3).jpg, wew.jpg"],
                ["Build AAB", "build/app/outputs/bundle/release/app-release.aab"],
                ["Akun demo", "Username: admin, Password: 12345"],
            ],
            [4.5, 12.5],
        )
    )
    story.append(p("Rekomendasi pengembangan berikutnya", "H2"))
    story.append(
        bullets(
            [
                "Menambahkan backend untuk akun pengguna, riwayat setoran, dan data pickup real.",
                "Mengintegrasikan notifikasi push untuk pengingat pickup.",
                "Menambahkan peta lokasi bank sampah dan tracking kurir.",
                "Menambahkan fitur penukaran Eco Pts ke voucher atau saldo.",
                "Menambahkan dashboard admin untuk memvalidasi setoran dan mengelola kategori.",
            ]
        )
    )
    return story


def build_pdf() -> Path:
    DOCS_DIR.mkdir(exist_ok=True)
    document = SimpleDocTemplate(
        str(OUTPUT_PDF),
        pagesize=A4,
        rightMargin=2 * cm,
        leftMargin=2 * cm,
        topMargin=1.65 * cm,
        bottomMargin=1.65 * cm,
        title="PRD SmartWaste",
        author="Muhammad Anis Maksum Winarso",
        subject="Product Requirement Document aplikasi SmartWaste",
    )
    story = build_story()
    document.build(story, onFirstPage=header_footer, onLaterPages=header_footer)
    return OUTPUT_PDF


if __name__ == "__main__":
    print(build_pdf())
