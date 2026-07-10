import os
import random
import uuid
from datetime import datetime, timedelta
import firebase_admin
from firebase_admin import credentials, firestore

def init_firestore():
    """Initializes Firestore client using credentials certificate or default path."""
    # Cari serviceAccountKey.json di direktori aktif
    cred_file = "serviceAccountKey.json"
    env_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "")

    if os.path.exists(cred_file):
        cred = credentials.Certificate(cred_file)
        firebase_admin.initialize_app(cred)
        print("Firebase Admin diinisialisasi via local serviceAccountKey.json")
    elif env_path and os.path.exists(env_path):
        cred = credentials.Certificate(env_path)
        firebase_admin.initialize_app(cred)
        print(f"Firebase Admin diinisialisasi via path env: {env_path}")
    else:
        try:
            firebase_admin.initialize_app()
            print("Firebase Admin diinisialisasi via Default Credentials.")
        except Exception as e:
            print("\n" + "="*80)
            print("Gagal Menginisialisasi Firebase Admin!")
            print("Silakan unduh file Kunci Akun Layanan (service account key JSON) dari Firebase Console:")
            print("  Project Settings -> Service Accounts -> Generate New Private Key")
            print("Letakkan file tersebut dengan nama 'serviceAccountKey.json' di folder backend/ lalu jalankan kembali skrip ini.")
            print("="*80 + "\n")
            raise e

    return firestore.client()

def seed_data():
    db = init_firestore()
    print("Memulai proses seeding data dummy ke Firestore...")

    # =========================================================================
    # 1. AKUN PENGGUNA (GURU, SISWA, ORANG TUA)
    # =========================================================================
    print("\n[1/5] Seeding Users...")
    
    # 1 Guru
    guru_uid = "guru_budi_santoso"
    guru_data = {
        "uid": guru_uid,
        "name": "Budi Santoso, S.Pd.",
        "email": "guru@school.com",
        "role": "guru",
        "createdAt": datetime.utcnow().isoformat()
    }
    db.collection("users").document(guru_uid).set(guru_data)

    # 15 Siswa
    siswa_names = [
        "Adi Wijaya", "Budi Raharjo", "Citra Lestari", "Dedi Kurniawan", "Eka Saputra",
        "Fani Amanda", "Gita Permata", "Hadi Susanto", "Indah Sari", "Joko Wibowo",
        "Kartika Putri", "Lestari Dewi", "Mega Utami", "Naufal Hakim", "Oki Pratama"
    ]
    
    siswa_uids = []
    siswa_list = []
    
    for i, name in enumerate(siswa_names):
        std_uid = f"student_{i+1:02d}"
        parent_code = f"FKS-{name.split()[0].upper()}-{random.randint(100, 999)}"
        
        student_data = {
            "uid": std_uid,
            "name": name,
            "email": f"{name.lower().replace(' ', '')}@student.com",
            "role": "siswa",
            "level": random.randint(1, 5),
            "xp": random.randint(200, 2000),
            "parentAccessCode": parent_code,
            "createdAt": datetime.utcnow().isoformat()
        }
        db.collection("users").document(std_uid).set(student_data)
        siswa_uids.append(std_uid)
        siswa_list.append(student_data)
        
    print(f"-> 1 Guru dan 15 Siswa berhasil ditambahkan.")

    # 3 Orang Tua (menghubungkan ke 3 siswa pertama: Adi, Budi, Citra)
    parent_uids = []
    for i in range(3):
        parent_uid = f"parent_{i+1:02d}"
        linked_student = siswa_list[i]
        
        parent_data = {
            "uid": parent_uid,
            "name": f"Orang Tua {linked_student['name'].split()[0]}",
            "email": f"parent.{linked_student['name'].lower().split()[0]}@gmail.com",
            "role": "orangtua",
            "linkedStudentUid": linked_student["uid"],
            "createdAt": datetime.utcnow().isoformat()
        }
        db.collection("users").document(parent_uid).set(parent_data)
        parent_uids.append(parent_uid)
    print(f"-> 3 Orang Tua berhasil ditambahkan (terhubung ke Adi, Budi, dan Citra).")

    # =========================================================================
    # 2. KELAS & MATERI
    # =========================================================================
    print("\n[2/5] Seeding Classes & Learning Materials...")

    class_id = "class_math_7a"
    class_data = {
        "classId": class_id,
        "className": "Matematika VII A",
        "classCode": "MATH7A23",
        "guruUid": guru_uid,
        "studentUids": siswa_uids,
        "createdAt": datetime.utcnow().isoformat()
    }
    db.collection("classes").document(class_id).set(class_data)
    print(f"-> Kelas '{class_data['className']}' ({class_data['classCode']}) berhasil dibuat.")

    # 3 Modul Materi
    materials = [
        {
            "id": "mat_aljabar",
            "title": "Aljabar Dasar",
            "description": "Pengenalan variabel, suku sejenis, penyederhanaan aljabar sederhana.",
            "fileUrl": "https://firebasestorage.googleapis.com/v0/b/sifokus-dummy/o/aljabar_dasar.pdf",
            "summary": "Aljabar adalah cabang matematika yang menggunakan huruf atau simbol untuk mewakili angka tidak diketahui. Suku sejenis adalah suku-suku yang memiliki variabel dan pangkat variabel yang sama. Kita hanya bisa menjumlahkan atau mengurangkan suku-suku yang sejenis."
        },
        {
            "id": "mat_persamaan_linear",
            "title": "Persamaan Linear",
            "description": "Memecahkan persamaan linear satu variabel dan aplikasinya.",
            "fileUrl": "https://firebasestorage.googleapis.com/v0/b/sifokus-dummy/o/persamaan_linear.pdf",
            "summary": "Persamaan linear satu variabel adalah kalimat terbuka yang dihubungkan oleh tanda sama dengan (=) dan hanya mempunyai satu variabel berpangkat satu. Langkah penyelesaian meliputi memisahkan variabel di satu sisi dan konstanta di sisi lain."
        },
        {
            "id": "mat_geometri",
            "title": "Geometri Sederhana",
            "description": "Konsep keliling, luas persegi, persegi panjang, dan segitiga.",
            "fileUrl": "https://firebasestorage.googleapis.com/v0/b/sifokus-dummy/o/geometri_sederhana.pdf",
            "summary": "Geometri membahas tentang bangun datar. Persegi panjang memiliki Luas = p x l dan Keliling = 2 x (p + l). Segitiga memiliki Luas = 1/2 x alas x tinggi. Pemahaman keliling diperoleh dengan menjumlahkan seluruh panjang sisi terluar bangun datar."
        }
    ]

    for m in materials:
        material_data = {
            "materialId": m["id"],
            "classId": class_id,
            "title": m["title"],
            "description": m["description"],
            "fileUrl": m["fileUrl"],
            "summary": m["summary"],
            "createdAt": datetime.utcnow().isoformat()
        }
        db.collection("materials").document(m["id"]).set(material_data)
    print(f"-> 3 Modul Materi berhasil diunggah.")

    # =========================================================================
    # 3. KUIS & SOAL (QUICK CHECK & KUIS UTAMA)
    # =========================================================================
    print("\n[3/5] Seeding Assessments (Quick Checks & Main Quizzes)...")

    # Seed Soal Quick Check (3 Soal per materi)
    for m in materials:
        assessment_id = f"qc_{m['id']}"
        qc_data = {
            "assessmentId": assessment_id,
            "materialId": m["id"],
            "title": f"Quick Check: {m['title']}",
            "type": "quick_check",
            "passingScore": 60,
            "questions": [
                {
                    "questionText": f"Sederhanakan bentuk aljabar berikut: 3a + 2b - a + 4b. Manakah hasil yang benar?",
                    "options": ["2a + 6b", "4a + 6b", "2a + 2b", "4a + 2b"],
                    "correctAnswerIndex": 0
                },
                {
                    "questionText": "Jika x + 5 = 12, berapakah nilai x?",
                    "options": ["5", "6", "7", "8"],
                    "correctAnswerIndex": 2
                },
                {
                    "questionText": "Sebuah persegi panjang memiliki panjang 10 cm dan lebar 5 cm. Luas bangun tersebut adalah...",
                    "options": ["30 cm2", "50 cm2", "15 cm2", "25 cm2"],
                    "correctAnswerIndex": 1
                }
            ],
            "createdAt": datetime.utcnow().isoformat()
        }
        db.collection("assessments").document(assessment_id).set(qc_data)

    # Seed Soal Kuis Utama (10 Soal per materi)
    for m in materials:
        assessment_id = f"quiz_{m['id']}"
        quiz_data = {
            "assessmentId": assessment_id,
            "materialId": m["id"],
            "title": f"Kuis Utama: {m['title']}",
            "type": "quiz_utama",
            "passingScore": 70,
            "questions": [
                {
                    "questionText": "Nilai variabel x dari persamaan 3x - 4 = 11 adalah...",
                    "options": ["3", "4", "5", "6"],
                    "correctAnswerIndex": 2
                },
                {
                    "questionText": "Hasil dari (2x + 3)(x - 1) adalah...",
                    "options": ["2x2 + x - 3", "2x2 - x - 3", "2x2 + 5x - 3", "2x2 + 2x - 3"],
                    "correctAnswerIndex": 0
                },
                {
                    "questionText": "Sebuah segitiga siku-siku memiliki alas 6 cm dan tinggi 8 cm. Berapakah panjang hipotenusa (sisi miring) segitiga tersebut?",
                    "options": ["9 cm", "10 cm", "11 cm", "12 cm"],
                    "correctAnswerIndex": 1
                },
                {
                    "questionText": "Sederhanakan bentuk 5(2x - 3y) - 2(3x + 4y)!",
                    "options": ["4x - 23y", "4x - 7y", "16x - 23y", "16x - 7y"],
                    "correctAnswerIndex": 0
                },
                {
                    "questionText": "Jika keliling sebuah persegi adalah 32 cm, berapakah luas persegi tersebut?",
                    "options": ["16 cm2", "32 cm2", "64 cm2", "81 cm2"],
                    "correctAnswerIndex": 2
                },
                {
                    "questionText": "Suku-suku sejenis dari bentuk aljabar 4x2 - 3x + 2y - x2 + 5 adalah...",
                    "options": ["4x2 dan -x2", "4x2 dan -3x", "-3x dan 2y", "2y dan 5"],
                    "correctAnswerIndex": 0
                },
                {
                    "questionText": "Himpunan penyelesaian dari 2(x - 3) < 4 adalah...",
                    "options": ["x < 5", "x < 7", "x > 5", "x > 7"],
                    "correctAnswerIndex": 0
                },
                {
                    "questionText": "Sebuah trapesium memiliki panjang sisi sejajar 8 cm dan 12 cm, serta tinggi 5 cm. Luas trapesium tersebut adalah...",
                    "options": ["40 cm2", "50 cm2", "100 cm2", "200 cm2"],
                    "correctAnswerIndex": 1
                },
                {
                    "questionText": "Koefisien dari variabel y pada bentuk aljabar 3x - 5y + 8 adalah...",
                    "options": ["3", "-5", "5", "8"],
                    "correctAnswerIndex": 1
                },
                {
                    "questionText": "Berapakah luas lingkaran dengan jari-jari 7 cm? (Gunakan pi = 22/7)",
                    "options": ["44 cm2", "154 cm2", "308 cm2", "616 cm2"],
                    "correctAnswerIndex": 1
                }
            ],
            "createdAt": datetime.utcnow().isoformat()
        }
        db.collection("assessments").document(assessment_id).set(quiz_data)
        
    print(f"-> 3 Asesmen Quick Check dan 3 Kuis Utama berhasil dibuat.")

    # =========================================================================
    # 4. LOG AKTIVITAS MEMBACA & NILAI KUIS (SIMULASI 2 MINGGU)
    # =========================================================================
    print("\n[4/5] Seeding Reading Activities & Quiz Scores (Simulating 2 Weeks)...")

    # Kelompok siswa berdasarkan perilaku belajar
    siswa_fokus_tinggi = siswa_uids[0:5]    # student_01 s.d student_05
    siswa_fokus_sedang = siswa_uids[5:12]   # student_06 s.d student_12
    siswa_fokus_rendah = siswa_uids[12:15]  # student_13 s.d student_15

    now = datetime.utcnow()

    # Generator log aktivitas
    for m in materials:
        material_id = m["id"]
        
        # 1. Siswa Fokus Tinggi
        for std in siswa_fokus_tinggi:
            focus_score = random.uniform(85.0, 96.0)
            duration = random.randint(400, 600)
            idle = random.randint(10, 30)
            tab_switches = random.randint(0, 1)
            
            activity = {
                "activityId": str(uuid.uuid4()),
                "studentId": std,
                "materialId": material_id,
                "focusScore": focus_score,
                "readDurationSec": duration,
                "idleTimeSec": idle,
                "tabSwitches": tab_switches,
                "scrollVelocity": "Normal",
                "isCompleted": True,
                "timestamp": (now - timedelta(days=random.randint(1, 14))).isoformat()
            }
            db.collection("activities").document(activity["activityId"]).set(activity)

            # Nilai kuis utama (Tinggi)
            score = random.randint(9, 10) # 90-100%
            submission = {
                "submissionId": str(uuid.uuid4()),
                "studentId": std,
                "assessmentId": f"quiz_{material_id}",
                "score": score,
                "totalQuestions": 10,
                "passed": True,
                "answers": [random.randint(0, 3) for _ in range(10)], # dummy jawaban
                "timestamp": (now - timedelta(days=random.randint(1, 14))).isoformat()
            }
            db.collection("submissions").document(submission["submissionId"]).set(submission)

        # 2. Siswa Fokus Sedang
        for std in siswa_fokus_sedang:
            focus_score = random.uniform(65.0, 80.0)
            duration = random.randint(250, 350)
            idle = random.randint(40, 80)
            tab_switches = random.randint(2, 4)
            
            activity = {
                "activityId": str(uuid.uuid4()),
                "studentId": std,
                "materialId": material_id,
                "focusScore": focus_score,
                "readDurationSec": duration,
                "idleTimeSec": idle,
                "tabSwitches": tab_switches,
                "scrollVelocity": "Normal",
                "isCompleted": True,
                "timestamp": (now - timedelta(days=random.randint(1, 14))).isoformat()
            }
            db.collection("activities").document(activity["activityId"]).set(activity)

            # Nilai kuis utama (Sedang)
            score = random.randint(7, 8) # 70-80%
            submission = {
                "submissionId": str(uuid.uuid4()),
                "studentId": std,
                "assessmentId": f"quiz_{material_id}",
                "score": score,
                "totalQuestions": 10,
                "passed": True,
                "answers": [random.randint(0, 3) for _ in range(10)],
                "timestamp": (now - timedelta(days=random.randint(1, 14))).isoformat()
            }
            db.collection("submissions").document(submission["submissionId"]).set(submission)

        # 3. Siswa Fokus Rendah
        for std in siswa_fokus_rendah:
            focus_score = random.uniform(30.0, 52.0)
            duration = random.randint(100, 180)
            idle = random.randint(120, 200)
            tab_switches = random.randint(6, 12)
            
            activity = {
                "activityId": str(uuid.uuid4()),
                "studentId": std,
                "materialId": material_id,
                "focusScore": focus_score,
                "readDurationSec": duration,
                "idleTimeSec": idle,
                "tabSwitches": tab_switches,
                "scrollVelocity": "Abnormal",
                "isCompleted": random.choice([True, False]),
                "timestamp": (now - timedelta(days=random.randint(1, 14))).isoformat()
            }
            db.collection("activities").document(activity["activityId"]).set(activity)

            # Nilai kuis utama (Rendah)
            score = random.randint(4, 6) # 40-60%
            submission = {
                "submissionId": str(uuid.uuid4()),
                "studentId": std,
                "assessmentId": f"quiz_{material_id}",
                "score": score,
                "totalQuestions": 10,
                "passed": False,
                "answers": [random.randint(0, 3) for _ in range(10)],
                "timestamp": (now - timedelta(days=random.randint(1, 14))).isoformat()
            }
            db.collection("submissions").document(submission["submissionId"]).set(submission)

    print("-> Log aktivitas membaca & riwayat kuis berhasil disuntikkan secara bervariasi.")

    # =========================================================================
    # 5. DIAGNOSIS KOMPETENSI & REKOMENDASI PERSONAL (GURU, SISWA, ORANG TUA)
    # =========================================================================
    print("\n[5/5] Seeding Diagnosis & Recommendations (F-22 to F-25)...")

    # Lakukan seeding rekomendasi / diagnosis khusus untuk 3 siswa yang terhubung dengan orang tua
    # Adi (student_01) -> Fokus Tinggi
    # Budi (student_02) -> Fokus Tinggi (namun buat variasi sedang untuk demo)
    # Citra (student_03) -> Fokus Tinggi
    
    diagnosis_cases = [
        {
            "student_id": "student_01",
            "name": "Adi Wijaya",
            "material_id": "mat_aljabar",
            "strengths": ["Variabel dasar", "Konsep suku sejenis", "Penyederhanaan suku satu variabel"],
            "weaknesses": ["Penyederhanaan ekspresi kurung", "Operasi perkalian aljabar 2 suku"],
            "recommendations": [
                "Latih perkalian dua kurung bentuk (ax + b)(cx + d) di rumah.",
                "Tonton modul video interaktif visual tentang perkalian distribusi aljabar."
            ],
            "focus_analysis": "Adi memiliki fokus luar biasa (94.2%) dengan membaca modul secara tenang (tidak ada perpindahan tab). Namun, ia agak terburu-buru saat kuis pada soal nomor 2 perkalian distribusi.",
            "teacher_rec": [
                "Adi sudah menguasai teori klasikal dengan baik. Berikan dia soal pengayaan/tantangan tingkat tinggi (HOTS) terkait penyederhanaan aljabar rumit.",
                "Apresiasi ketekunannya secara klasikal di depan kelas."
            ],
            "student_rec": [
                "Hebat Adi! Belajar aljabar kamu sangat terencana. Mari selangkah lagi menguasai operasi perkalian aljabar dua suku dengan menonton video ringkasan di menu rekomendasi.",
                "Tantang dirimu untuk mencoba 5 soal kuis harian aljabar tingkat lanjut!"
            ],
            "parent_rec": [
                "Adi belajar secara sangat mandiri dan tertib di rumah (skor fokus 94%). Teruskan mendukung belajarnya di sore hari.",
                "Coba tanyakan secara santai apakah ia butuh kertas coret-coretan ekstra saat belajar aljabar."
            ],
            "teacher_narrative": "Siswa Adi Wijaya menunjukkan penguasaan teori aljabar dasar yang luar biasa. Ia siap menerima latihan soal bermutu tinggi.",
            "student_narrative": "Halo Adi! Stabilitas belajarmu keren banget hari ini. Pertahankan terus fokus membacamu ya, kamu luar biasa!",
            "parent_narrative": "Bunda, Adi belajar dengan sangat teratur dan fokus tinggi di rumah sore ini. Berikan dia segelas air hangat dan apresiasi usahanya."
        },
        {
            "student_id": "student_13", # Joko Wibowo / Lestari / student_13 -> Fokus Rendah
            "name": "Mega Utami",
            "material_id": "mat_persamaan_linear",
            "strengths": ["Konsep tanda sama dengan (=)", "Konstanta & Koefisien"],
            "weaknesses": ["Pemindahan ruas variabel", "Pecahan linear satu variabel"],
            "recommendations": [
                "Gunakan visualisasi neraca timbangan untuk memahami konsep memindahkan ruas variabel.",
                "Dampingi membaca modul secara bertahap (5 menit membaca, 2 menit diskusi)."
            ],
            "focus_analysis": "Siswa menunjukkan skor fokus sangat rendah (41.5%) karena melakukan perpindahan tab sebanyak 8 kali selama membaca materi, dan menutup modul dalam waktu kurang dari 3 menit.",
            "teacher_rec": [
                "Lakukan pendekatan remedial individual atau tutor sebaya khusus memindahkan ruas variabel untuk Mega.",
                "Mega membutuhkan modul materi dengan teks lebih singkat atau dalam bentuk poin-poin mind map visual."
            ],
            "student_rec": [
                "Hai Mega! Jangan patah semangat ya. Konsep dasar persamaanmu sudah bagus. Coba belajar dengan menonaktifkan notifikasi HP atau tab lain agar kamu tidak terdistraksi.",
                "Yuk tonton video singkat neraca aljabar di menu video pembelajaran!"
            ],
            "parent_rec": [
                "Mega sering berpindah halaman game/sosmed saat membaca modul di rumah (8 kali tab switches). Dampingi Mega dan arahkan untuk menjauhkan gadget lain selama 15 menit belajar.",
                "Berikan pujian pada setiap langkah pengerjaan persamaan matematika yang berhasil ia selesaikan dengan benar."
            ],
            "teacher_narrative": "Mega Utami membutuhkan intervensi personal khusus untuk meningkatkan retensi membacanya. Disarankan menggunakan media ajar yang lebih padat.",
            "student_narrative": "Hai Mega! Kakak AI di sini mendampingimu. Belajar sedikit demi sedikit asal rutin ya. Yuk, kita kurangi distraksi tab browser!",
            "parent_narrative": "Ayah/Bunda, Mega membutuhkan pendampingan lebih dekat saat belajar online di rumah untuk membantu menyaring distraksi internet. Cobalah menemani Mega membaca selama 10 menit."
        }
    ]

    for c in diagnosis_cases:
        doc_id = f"diag_{c['student_id']}_{c['material_id']}"
        diagnosis_data = {
            "studentId": c["student_id"],
            "classId": class_id,
            "materialId": c["material_id"],
            "strengths": c["strengths"],
            "weaknesses": c["weaknesses"],
            "recommendations": c["recommendations"],
            "focusAnalysis": c["focus_analysis"],
            
            # Rekomendasi Target F-23
            "teacherRecommendations": c["teacher_rec"],
            "studentRecommendations": c["student_rec"],
            "parentRecommendations": c["parent_rec"],
            
            # Naratif Laporan F-25
            "teacherNarrative": c["teacher_narrative"],
            "studentNarrative": c["student_narrative"],
            "parentNarrative": c["parent_narrative"],
            "timestamp": datetime.utcnow().isoformat()
        }
        db.collection("student_competencies").document(doc_id).set(diagnosis_data)

        # Tambahkan juga data bakat siswa ke talent_recommendations
        talent_id = f"talent_{c['student_id']}"
        talent_data = {
            "studentId": c["student_id"],
            "recommendedField": "Lomba Karya Tulis Sains" if c["student_id"] == "student_01" else "Kompetisi Bahasa",
            "confidenceScore": 0.95 if c["student_id"] == "student_01" else 0.72,
            "reasoning": (
                f"Siswa {c['name']} memiliki ketekunan membaca teks naratif teoritis yang tinggi "
                f"diikuti dengan pencapaian skor kuis yang terencana baik. Hal ini mengindikasikan ketertarikan "
                f"pada bidang sains eksploratif ilmiah."
            )
        }
        db.collection("talent_recommendations").document(talent_id).set(talent_data)

    print("-> Data diagnosis kompetensi dan rekomendasi personal berhasil ditanam.")
    print("\n" + "="*80)
    print("PROSES SEEDING DATA DUMMY SELESAI DENGAN SUKSES!")
    print("Database Firestore Anda sekarang berisi dataset yang sangat kaya dan realistis.")
    print("Leaderboard, grafik fl_chart, dan seluruh kartu analitik akan terisi dengan indah!")
    print("="*80 + "\n")

if __name__ == "__main__":
    seed_data()
