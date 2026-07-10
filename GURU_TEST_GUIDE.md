# Panduan Uji Coba Fitur Guru (F-01 s/d F-09) — SI-FOKUS

Panduan ini dirancang khusus untuk memandu simulasi dan verifikasi fungsionalitas **Modul Guru** pada aplikasi SI-FOKUS secara mandiri.

---

## 🛠️ Persiapan Awal (Sangat Penting)

1. **Jalankan Aplikasi**:
   Pastikan aplikasi berjalan lancar di browser Chrome:
   ```bash
   flutter run -d chrome
   ```
2. **Suntikkan Data Uji Coba (Seeding)**:
   - Pada halaman **Splash Page** (paling awal saat aplikasi dibuka), Anda akan melihat dua tombol di bagian bawah:
     * 📥 **Seed Data**: Ketuk tombol ini untuk secara otomatis menyuntikkan seluruh database dummy (Akun Guru Budi Santoso, 15 siswa, 2 kelas, 4 materi lengkap beserta data analitik, visualisasi, dan intervensi AI).
     * 🗑️ **Clear Data**: Ketuk tombol ini jika Anda ingin mengosongkan/membersihkan ulang seluruh data demo dari database.
   - Ketuk **Seed Data** sebelum melanjutkan!

---

## 📋 Lembar Uji Coba (Checklist)

### TAHAP 1 - LOGIN & NAVIGASI DASAR
- [ ] **Buka Aplikasi** → Pastikan berada di Splash/Login Page.
- [ ] **Login Akun Guru**:
  * Email: `guru@test.com`
  * Password: `guru123456`
- [ ] **Verifikasi Dashboard**: Sistem harus mendeteksi peran Anda dan mengarahkan ke `GuruDashboardPage`.
- [ ] **Informasi Profil**: Pastikan nama pengajar **"Budi Santoso"** tampil di header/profil dashboard dengan tepat.

### TAHAP 2 - CEK FITUR F-01 (MANAJEMEN KELAS)
- [ ] **Daftar Kelas**: Di dasbor guru, pastikan tampil dua kelas hasil seeding:
  * Matematika VII-A
  * IPA VII-B
- [ ] **Detail Kelas**: Klik pada kelas **"Matematika VII-A"** dan masuk ke `ClassDetailGuruPage`.
- [ ] **Daftar Siswa**: Periksa tab anggota kelas, pastikan 10 nama siswa (dari Adi Pratama s/d Joko Susanto) terdaftar di sana.
- [ ] **Tambah Kelas Baru**:
  * Kembali ke dasbor utama.
  * Tekan tombol **(+)** untuk membuat kelas baru.
  * Isi nama kelas: `Bahasa Indonesia VII-C`, mata pelajaran: `Bahasa Indonesia`.
  * Simpan.
- [ ] **Kode Kelas Otomatis**: Pastikan kelas baru yang Anda buat otomatis memiliki kode kelas 8 karakter unik alfanumerik.
- [ ] **Hapus Kelas**: Coba hapus kelas `Bahasa Indonesia VII-C` yang baru Anda buat untuk memastikan fungsi hapus berjalan lancar.

### TAHAP 3 - CEK FITUR F-02 (SMART LEARNING MATERIAL)
- [ ] **Daftar Modul**: Masuk ke kelas **"Matematika VII-A"** → tab materi.
- [ ] **Dua Materi Aktif**: Pastikan materi **"Aljabar Dasar"** dan **"Persamaan Linear Satu Variabel"** tercantum.
- [ ] **AI Summary**: Ketuk materi **"Aljabar Dasar"** → periksa apakah teks ringkasan (summary) hasil analisis AI muncul dengan rapi.
- [ ] **Status Publikasi**:
  * Pastikan status materi **"Aljabar Dasar"** adalah **Dipublikasikan** (aktif untuk siswa).
  * Masuk ke kelas **"IPA VII-B"** → periksa materi **"Ekosistem dan Rantai Makanan"** harus berstatus **Belum Dipublikasikan** (ikon gembok/keterangan draf).

### TAHAP 4 - CEK FITUR F-03 (AI ASSESSMENT GENERATOR)
- [ ] **Pratinjau Soal**: Di dalam halaman detail materi **"Aljabar Dasar"**, periksa tombol asesmen AI:
  * Klik **Quick Check** → Pastikan ada 3 soal pilihan ganda lengkap dengan opsi A/B/C/D yang dihasilkan AI.
  * Klik **Kuis Utama** → Pastikan ada 10 soal pilihan ganda bergradasi kesulitan.
- [ ] **Edit Soal**: Uji fitur pengeditan dengan mengubah teks soal pertama Quick Check, lalu klik simpan dan pastikan teks berubah.
- [ ] **Ubah Kunci Jawaban**: Coba ubah kunci jawaban salah satu soal Kuis Utama, klik simpan, dan periksa apakah statusnya berhasil diperbarui.

### TAHAP 5 - CEK FITUR F-04 (QUIZ MANAGEMENT)
- [ ] **Konfigurasi Kuis**: Di halaman detail materi, ketuk tombol pengaturan (ikon gerigi) pada Kuis Utama **"Aljabar Dasar"**.
- [ ] **Jadwal Kuis**: Pastikan kolom **Tanggal Mulai** dan **Tanggal Selesai** sudah terisi otomatis (default dari seeder).
- [ ] **Ubah Durasi**: Ganti durasi pengerjaan kuis dari 30 menit menjadi 45 menit, klik simpan, dan pastikan nilainya terupdate.
- [ ] **Toggle Publikasi Kuis**: Coba matikan/aktifkan status publikasi kuis utama dan periksa reaktivitas perubahannya.

### TAHAP 6 - CEK FITUR F-05 (DASHBOARD KOMPETENSI)
- [ ] **Buka Kompetensi**: Dari rincian kelas **"Matematika VII-A"**, klik tombol **Dashboard Kompetensi**.
- [ ] **Rata-rata Nilai**: Periksa visualisasi circular progress bar bergradasi yang menampilkan rata-rata nilai kelas.
- [ ] **Topik Tersulit (Horizontal Bar Chart)**: Pastikan grafik horizontal menampilkan topik **"Soal Cerita Aljabar"** sebagai materi dengan tingkat kesalahan tertinggi (60% error).
- [ ] **Radar Chart (Spider Web)**: Periksa keindahan grafik Radar Chart yang menampilkan pemetaan 5 area penguasaan kompetensi siswa secara premium.

### TAHAP 7 - CEK FITUR F-06 (AI LEARNING INTERVENTION)
- [ ] **Peringatan Dini**: Di halaman detail materi **"Aljabar Dasar"**, klik tombol **Rekomendasi Intervensi Belajar AI**.
- [ ] **Warning Box HSL**: Pastikan kotak peringatan berwarna amber/kuning dinamis muncul di bagian atas bertuliskan *"60% siswa masih kesulitan memahami Soal Cerita Aljabar"*.
- [ ] **Poin Rekomendasi AI**: Pastikan 3 daftar solusi pengajaran remedial dari AI tampil.
- [ ] **Siswa Remedial**: Pastikan nama-nama siswa dengan tingkat pemahaman rendah (seperti Hadi Nugroho, Indah, Joko) muncul lengkap dengan draf pesan chat personal untuk dikirim cepat ke orang tua/siswa.

### TAHAP 8 - CEK FITUR F-07 (LEARNING ANALYTICS)
- [ ] **Analitik Kelas**: Dari kelas **"Matematika VII-A"**, klik tombol **Learning Analytics**.
- [ ] **Line Chart**: Periksa visualisasi tren kenaikan/penurunan nilai kelas dari kuis ke kuis.
- [ ] **Durasi vs Nilai**: Periksa grafik durasi membaca siswa per modul dan hubungannya dengan nilai akhir kuis mereka.
- [ ] **Pencarian Siswa**: Ketikkan nama siswa secara spesifik (misal: "Adi Pratama") untuk memfilter riwayat belajar individu secara interaktif.

### TAHAP 9 - CEK FITUR F-08 (TALENT RECOMMENDATION)
- [ ] **Buka Menu Bakat**: Pada AppBar dasbor utama Guru Budi, klik tombol pintas berbentuk **Trophy (Piala Emas)**.
- [ ] **Rekomendasi AI**: Pastikan 3 siswa berprestasi tampil:
  * **Adi Pratama**: Olimpiade Matematika (Confidence: 92%).
  * **Citra Dewi**: Lomba Sains (Confidence: 85%).
  * **Fajar Hidayat**: Lomba Informatika (Confidence: 78%).
- [ ] **Gauge Visual**: Periksa keindahan komponen visual semi-circular gauge berwarna Golden Amber.
- [ ] **Justifikasi AI**: Pastikan alasan detail (*reasoning*) tercetak rapi di bawah nama masing-masing siswa.

### TAHAP 10 - CEK FITUR F-09 (LEARNING RESOURCE)
- [ ] **Materi Aljabar**: Masuk ke detail **"Aljabar Dasar"** → periksa di bagian bawah terdapat 1 tautan YouTube edukatif.
- [ ] **Materi Persamaan Linear**: Buka detail materi ini → periksa terdapat 2 tautan (1 video YouTube dan 1 artikel blog).
- [ ] **Tambah Tautan Baru**: Klik tombol **Tambah Resource**, masukkan judul dan tempelkan link (sistem akan memvalidasi dengan regex).
- [ ] **Hapus Tautan**: Coba hapus tautan yang baru saja dibuat untuk memastikan kelancaran manajemen resource tambahan.

---

## 🎨 TAHAP 11 - ESTETIKA & PENGALAMAN PENGGUNA (UX)
- [ ] **Warna & Konsistensi**: Pastikan kombinasi warna Deep Indigo, Teal, dan aksen Golden Amber terdistribusi secara seimbang.
- [ ] **Efek Glassmorphism**: Elemen card memiliki gradasi tipis, border tipis semi-transparan, dan bayangan lembut (*soft shadows*).
- [ ] **Responsive Grid**: Coba ubah ukuran layar ke mode landscape atau perkecil jendela browser; pastikan tidak ada teks bertumpuk atau tombol yang terpotong.
