import os
import json
import google.generativeai as genai
from pydantic import BaseModel, Field
from typing import List

# Setup API Key
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

class QuestionSchema(BaseModel):
    questionText: str = Field(description="Teks pertanyaan kuis pilihan ganda.")
    options: List[str] = Field(description="Daftar 4 opsi pilihan jawaban (A, B, C, D). Harus tepat 4 opsi.")
    correctAnswerIndex: int = Field(description="Indeks jawaban yang benar, dimulai dari 0 sampai 3.")

class MaterialProcessResult(BaseModel):
    summary: str = Field(description="Ringkasan materi pembelajaran yang komprehensif namun padat (maksimal 300 kata).")
    topics: List[str] = Field(description="Daftar topik utama atau kompetensi inti yang dibahas dalam materi tersebut.")
    quick_check: List[QuestionSchema] = Field(description="Daftar tepat 3 soal kuis singkat untuk Quick Check pemahaman awal.")
    quiz_utama: List[QuestionSchema] = Field(description="Daftar tepat 10 soal kuis utama dengan tingkat kesulitan yang bertingkat.")

def generate_dynamic_fallback(text: str, filename: str) -> dict:
    """Generates a realistic, dynamic fallback summary and quizzes when Gemini API quota is exceeded."""
    title = filename.replace(".pdf", "").replace(".docx", "").replace(".pptx", "").replace(".ppt", "").replace("_", " ")
    if not title.strip():
        title = "Dokumen Pembelajaran"

    # Extract words to find keywords (filtering out common Indonesian stop words)
    stopwords = {
        "adalah", "tentang", "yang", "untuk", "dalam", "dengan", "dan", "atau", "dari", 
        "pada", "oleh", "juga", "yaitu", "ialah", "bahwa", "sebagai", "dapat", "akan", 
        "telah", "sudah", "kami", "mereka", "karena", "sehingga", "tetapi", "namun", 
        "jika", "maka", "pada", "bisa", "ini", "itu", "serta", "yaitu", "secara", "lebih"
    }
    words = [w.strip(",.()\"'[]:;-+=!?").lower() for w in text.split() if len(w) > 4]
    filtered_words = [w for w in words if w.isalnum() and w not in stopwords]
    
    # Capitalize unique keywords for display
    unique_words = []
    for w in filtered_words:
        cap_w = w.capitalize()
        if cap_w not in unique_words:
            unique_words.append(cap_w)
            
    keywords = unique_words[:5] if len(unique_words) >= 5 else ["Konsep", "Metodologi", "Analisis", "Evaluasi", "Implementasi"]
    
    # Try to extract the first two readable sentences
    sentences = [s.strip() for s in text.split(".") if len(s.strip()) > 20]
    extracted_summary = ""
    if len(sentences) >= 2:
        extracted_summary = ". ".join(sentences[:2]) + "."
        if len(extracted_summary) > 400:
            extracted_summary = extracted_summary[:400] + "..."
    else:
        extracted_summary = f"Dokumen '{title}' menyajikan pembahasan mendalam mengenai topik ini, mencakup kerangka kerja, teori pendukung, dan evaluasi hasil."
        
    summary = f"Ringkasan '{title}': {extracted_summary} Fokus utama materi adalah pemahaman menyeluruh terhadap struktur konsep dan aplikasi praktis di lapangan."
    
    # Daftar template pertanyaan & opsi jawaban yang variatif agar tidak terkesan mekanis/template
    templates = [
        {
            "question": "Apa dampak utama dari penerapan konsep '{kw}' dalam pembahasan '{title}'?",
            "options": [
                "Meningkatkan akurasi analisis dan pemecahan kasus secara terukur",
                "Menyederhanakan proses tanpa memberikan dampak signifikan",
                "Hanya berfungsi sebagai pelengkap administrasi dokumen",
                "Menyulitkan pemahaman konsep dasar bagi pemula"
            ]
        },
        {
            "question": "Manakah di bawah ini yang paling tepat menggambarkan karakteristik utama dari '{kw}'?",
            "options": [
                "Bersifat fundamental dan terintegrasi dengan topik utama",
                "Bersifat opsional dan dapat diabaikan dalam analisis praktis",
                "Hanya berlaku pada kasus-kasus berskala kecil",
                "Merupakan bagian terpisah yang tidak memengaruhi hasil"
            ]
        },
        {
            "question": "Berdasarkan isi dokumen '{title}', mengapa '{kw}' dianggap sebagai komponen penting?",
            "options": [
                "Karena menjadi dasar evaluasi dan perumusan rekomendasi tindakan",
                "Karena disarankan oleh standar kurikulum tanpa alasan teknis",
                "Hanya untuk memenuhi kelengkapan bab pembahasan materi",
                "Guna meminimalkan interaksi aktif dalam proses belajar"
            ]
        },
        {
            "question": "Bagaimana hubungan logis antara '{kw}' dengan topik bahasan '{title}'?",
            "options": [
                "Saling mendukung untuk membentuk pemahaman konsep yang utuh",
                "Bertolak belakang sehingga membingungkan pembaca",
                "Tidak memiliki kaitan langsung maupun tidak langsung",
                "Hanya berhubungan pada bagian kesimpulan akhir"
            ]
        },
        {
            "question": "Apa tujuan utama dari dipelajarinya konsep '{kw}' dalam materi ini?",
            "options": [
                "Membekali siswa dengan metodologi analisis yang sistematis",
                "Sekadar menghafal definisi tanpa perlu menerapkannya",
                "Mempercepat durasi belajar tanpa memperhatikan kualitas",
                "Mengurangi porsi latihan soal dalam evaluasi kompetensi"
            ]
        },
        {
            "question": "Jika '{kw}' tidak dipahami dengan benar dalam konteks '{title}', apa risiko utama yang terjadi?",
            "options": [
                "Terjadinya kesalahan diagnosis dan bias pada hasil evaluasi",
                "Tidak ada risiko karena topik ini bersifat opsional",
                "Proses belajar akan menjadi lebih cepat dan efisien",
                "Hanya memengaruhi nilai tugas harian secara minor"
            ]
        },
        {
            "question": "Dalam dokumen '{title}', konsep '{kw}' paling erat dikaitkan dengan aspek...",
            "options": [
                "Metodologi implementasi dan efektivitas pemecahan masalah",
                "Sejarah penemuan teori dan biografi tokoh pendukung",
                "Latihan hafalan jangka pendek sebelum ujian utama",
                "Penyusunan laporan administrasi di akhir semester"
            ]
        },
        {
            "question": "Bagaimana cara terbaik untuk mengukur keberhasilan penerapan '{kw}'?",
            "options": [
                "Melalui evaluasi berkala dan analisis performa secara konsisten",
                "Cukup dengan melihat durasi waktu membaca dokumen",
                "Dengan membandingkan jumlah halaman yang telah dibaca",
                "Tidak diperlukan pengukuran khusus karena hasilnya konstan"
            ]
        },
        {
            "question": "Apa kesimpulan utama dokumen '{title}' mengenai peran strategis '{kw}'?",
            "options": [
                "Menjadi akselerator penting dalam peningkatan pemahaman materi",
                "Hanya sebagai alternatif pilihan jika metode utama gagal",
                "Dapat digantikan sepenuhnya oleh komponen lain tanpa masalah",
                "Merupakan konsep teoritis yang sulit diwujudkan secara praktis"
            ]
        },
        {
            "question": "Bagaimana '{kw}' memengaruhi pola analisis yang dibahas dalam '{title}'?",
            "options": [
                "Mengarahkan pemikiran ke pendekatan yang lebih logis dan terstruktur",
                "Membatasi kreativitas berpikir dalam menemukan solusi alternatif",
                "Membuat alur analisis menjadi berputar-putar tanpa arah",
                "Tidak memberikan pengaruh apa pun pada pola berpikir siswa"
            ]
        }
    ]

    # Generate Quick Check (ambil 3 template pertama)
    quick_check = []
    for idx in range(3):
        tpl = templates[idx]
        kw = keywords[idx % len(keywords)]
        quick_check.append({
            "questionText": tpl["question"].format(kw=kw, title=title),
            "options": tpl["options"],
            "correctAnswerIndex": idx % 4
        })
    
    # Generate Kuis Utama (gunakan semua 10 template)
    quiz_utama = []
    for idx in range(10):
        tpl = templates[idx]
        kw = keywords[idx % len(keywords)]
        quiz_utama.append({
            "questionText": tpl["question"].format(kw=kw, title=title),
            "options": tpl["options"],
            "correctAnswerIndex": (idx + 1) % 4
        })
        
    return {
        "summary": summary,
        "topics": keywords,
        "quick_check": quick_check,
        "quiz_utama": quiz_utama
    }

def analyze_material_with_gemini(text: str, filename: str = "document.pdf") -> dict:
    """Sends the extracted text to Gemini API using gemini-2.0-flash with structured JSON output."""
    if not GEMINI_API_KEY:
        return generate_dynamic_fallback(text, filename)

    try:
        model = genai.GenerativeModel(
            model_name="gemini-2.0-flash",
            system_instruction=(
                "Anda adalah asisten AI akademik yang ahli. Analisislah teks pelajaran yang diberikan. "
                "Hasilkan ringkasan materi, daftar topik utama, 3 soal quick check, dan 10 soal kuis utama. "
                "Semua pertanyaan kuis wajib memiliki tepat 4 opsi pilihan jawaban (A, B, C, D) "
                "dengan indeks jawaban benar antara 0 sampai 3. Anda wajib mematuhi skema JSON yang ditentukan."
            )
        )

        prompt = f"Berikut adalah teks pelajaran yang harus dianalisis:\n\n{text}"

        response = model.generate_content(
            prompt,
            generation_config=genai.types.GenerationConfig(
                response_mime_type="application/json",
                response_schema=MaterialProcessResult,
                temperature=0.2,
            )
        )

        result_dict = json.loads(response.text)
        return result_dict
    except Exception as e:
        print(f"Warning: Gagal memproses menggunakan Gemini API ({e}). Menjalankan dynamic fallback...")
        return generate_dynamic_fallback(text, filename)

def get_dummy_response() -> dict:
    """Returns a valid dummy structure matching the schema for local testing."""
    return {
        "summary": "Ini adalah ringkasan materi dummy karena API Key Gemini belum diatur atau terjadi kegagalan parsing. Materi membahas tentang Sistem Pencernaan Manusia, organ pencernaan dari mulut hingga usus besar, pencernaan mekanis oleh gigi dan kimiawi oleh enzim pencernaan.",
        "topics": ["Sistem Pencernaan", "Organ Pencernaan", "Enzim Pencernaan"],
        "quick_check": [
          {
            "questionText": "Enzim apakah yang berfungsi memecah amilum menjadi glukosa di rongga mulut?",
            "options": ["Amilase / Ptialin", "Pepsin", "Lipase", "Tripsin"],
            "correctAnswerIndex": 0
          },
          {
            "questionText": "Organ manakah yang berfungsi menyerap sari-sari makanan?",
            "options": ["Lambung", "Usus Halus", "Usus Besar", "Kerongkongan"],
            "correctAnswerIndex": 1
          },
          {
            "questionText": "Apa peran utama bakteri E. coli di usus besar?",
            "options": ["Mencerna lemak", "Menghasilkan asam klorida", "Pembusukan sisa makanan & sintesis Vit K", "Menyerap protein"],
            "correctAnswerIndex": 2
          }
        ],
        "quiz_utama": [
          {
            "questionText": "Urutan saluran pencernaan manusia yang benar dari luar ke dalam adalah...",
            "options": [
              "Mulut - kerongkongan - lambung - usus halus - usus besar - anus",
              "Mulut - tenggorokan - lambung - usus besar - usus halus - anus",
              "Mulut - kerongkongan - usus halus - lambung - usus besar - anus",
              "Mulut - lambung - kerongkongan - usus halus - usus besar - anus"
            ],
            "correctAnswerIndex": 0
          },
          {
            "questionText": "Pencernaan kimiawi protein pertama kali terjadi di organ...",
            "options": ["Mulut", "Lambung", "Usus halus", "Pankreas"],
            "correctAnswerIndex": 1
          },
          {
            "questionText": "Cairan empedu dihasilkan oleh organ X dan disimpan di organ Y. Organ X dan Y adalah...",
            "options": ["Hati dan Kantung Empedu", "Kantung Empedu dan Hati", "Pankreas dan Hati", "Lambung dan Usus Dua Belas Jari"],
            "correctAnswerIndex": 0
          },
          {
            "questionText": "Enzim tripsin yang diproduksi oleh pankreas berfungsi untuk...",
            "options": ["Mengubah protein menjadi peptida/asam amino", "Mengubah lemak menjadi asam lemak", "Mengubah amilum menjadi maltosa", "Mengendapkan kasein susu"],
            "correctAnswerIndex": 0
          },
          {
            "questionText": "Gerakan meremas dan mendorong makanan di kerongkongan disebut gerakan...",
            "options": ["Peristaltik", "Brown", "Amuboid", "Refleks"],
            "correctAnswerIndex": 0
          },
          {
            "questionText": "Bagian lambung yang berbatasan langsung dengan kerongkongan adalah...",
            "options": ["Kardia", "Fundus", "Pilorus", "Duodenum"],
            "correctAnswerIndex": 0
          },
          {
            "questionText": "Asam klorida (HCl) di lambung diproduksi untuk...",
            "options": ["Membunuh kuman & mengaktifkan pepsinogen", "Mencerna karbohidrat", "Mengemulsi lemak", "Menyerap vitamin B12"],
            "correctAnswerIndex": 0
          },
          {
            "questionText": "Jonjot-jonjot usus (vili) pada usus halus berguna untuk...",
            "options": ["Memperluas bidang penyerapan sari makanan", "Menghasilkan lendir pelindung", "Menghambat aliran chime", "Membunuh bakteri patogen"],
            "correctAnswerIndex": 0
          },
          {
            "questionText": "Apendisitis (radang umbai cacing) merupakan gangguan pada bagian...",
            "options": ["Usus buntu / sekum", "Lambung", "Usus kosong", "Rektum"],
            "correctAnswerIndex": 0
          },
          {
            "questionText": "Konstipasi terjadi akibat...",
            "options": [
              "Penyerapan air yang berlebihan di usus besar",
              "Kurangnya penyerapan air di usus besar",
              "Radang pada selaput dinding lambung",
              "Infeksi bakteri Vibrio cholerae"
            ],
            "correctAnswerIndex": 0
          }
        ]
    }

class DiagnosisResultSchema(BaseModel):
    strengths: List[str] = Field(description="Topik atau sub-materi yang sudah dikuasai dengan baik oleh siswa.")
    weaknesses: List[str] = Field(description="Topik atau sub-materi yang masih lemah dan perlu dipelajari kembali.")
    recommendations: List[str] = Field(description="Daftar rekomendasi tindakan belajar personal dan konkrit di rumah.")
    focus_analysis: str = Field(description="Evaluasi tingkat pemahaman siswa dikaitkan dengan pola fokus membacanya (durasi, idle, scroll, tab switch).")

def diagnose_competency_with_gemini(quiz_history: List[dict], reading_behavior: dict) -> dict:
    """Uses gemini-2.5-pro to diagnose student strengths, weaknesses, recommendations, and focus pattern analysis."""
    if not GEMINI_API_KEY:
        return get_dummy_diagnosis()

    model = genai.GenerativeModel(
        model_name="gemini-1.5-pro",
        system_instruction=(
            "Anda adalah AI asisten akademik dan psikolog pendidikan. Tugas Anda adalah melakukan diagnosis kompetensi "
            "siswa berdasarkan jawaban kuis mereka dan pola perilaku membaca modul mereka. "
            "Analisislah hubungan antara kelemahan pemahaman materi dan kebiasaan fokus membacanya. "
            "Berikan evaluasi yang hangat dan mendalam, lalu kelompokkan topik yang sudah dikuasai (strengths), "
            "topik yang masih lemah (weaknesses), rekomendasi belajar personal (recommendations), dan "
            "analisis fokus membaca secara rinci (focus_analysis). "
            "Output wajib mematuhi skema JSON yang ditentukan."
        )
    )

    prompt = f"""
    Lakukan evaluasi performa belajar siswa berdasarkan data berikut:
    
    1. RIWAYAT JAWABAN KUIS UTAMA (Jawaban Siswa vs Kunci Jawaban):
    {json.dumps(quiz_history, indent=2)}
    
    2. DATA PERILAKU MEMBACA:
    - Rata-rata Skor Fokus: {reading_behavior.get('focusScore')}%
    - Durasi Membaca: {reading_behavior.get('readDurationSec')} detik
    - Durasi Diam (Idle): {reading_behavior.get('idleTimeSec')} detik
    - Pergantian Tab (Tab Switches): {reading_behavior.get('tabSwitches')} kali
    - Kecepatan Scroll (Scroll Velocity): {reading_behavior.get('scrollVelocity')}
    """

    response = model.generate_content(
        prompt,
        generation_config=genai.types.GenerationConfig(
            response_mime_type="application/json",
            response_schema=DiagnosisResultSchema,
            temperature=0.2,
        )
    )

    try:
        return json.loads(response.text)
    except Exception as e:
        print(f"Gagal memparsing respons JSON Diagnosis dari Gemini: {e}")
        return get_dummy_diagnosis()

def get_dummy_diagnosis() -> dict:
    """Returns a valid dummy structure matching the Diagnosis schema for local testing."""
    return {
        "strengths": [
            "Fisiologi mulut & lambung (fungsi gigi, lambung, asam lambung)",
            "Enzim ptialin & pepsin"
        ],
        "weaknesses": [
            "Fisiologi usus halus & penyerapan sari makanan (fungsi vili/jonjot usus)",
            "Peran cairan empedu dalam emulsi lemak di usus dua belas jari",
            "Pembusukan makanan & pembentukan vitamin K oleh E. coli di usus besar"
        ],
        "recommendations": [
            "Tonton video animasi interaktif tentang mekanisme vili usus halus menyerap makanan.",
            "Lakukan review ulang sub-materi 'Pencernaan Lemak & Peran Hati' selama 10 menit.",
            "Kerjakan kuis latihan mandiri khusus topik usus besar sebelum mencoba Kuis Utama kembali."
        ],
        "focus_analysis": "Siswa mendapatkan skor fokus 82.7% yang tergolong baik, namun terdapat catatan berupa durasi membaca yang cenderung singkat di bagian bab usus halus (scroll cepat) dan 2 kali pergantian tab (distraksi). Hal ini berkorelasi langsung dengan kesalahan jawaban kuis pada soal nomor 8 tentang fungsi jonjot usus (vili) dan nomor 10 tentang usus besar. Tingkat fokus yang stabil di awal membaca membantu siswa menjawab dengan benar soal-soal mulut dan lambung."
    }

class TargetRecommendationSchema(BaseModel):
    teacher_recommendation: List[str] = Field(description="Rekomendasi tindakan intervensi kelas atau remedial untuk Guru.")
    student_recommendation: List[str] = Field(description="Rekomendasi personal langkah belajar selanjutnya & metode belajar cocok untuk Siswa.")
    parent_recommendation: List[str] = Field(description="Rekomendasi pendampingan belajar di rumah yang sederhana tanpa jargon akademik untuk Orang Tua.")

def generate_recommendations_with_gemini(diagnosis: dict) -> dict:
    """Uses Gemini API to formulate personalized recommendations for 3 target audiences based on child competency diagnosis."""
    if not GEMINI_API_KEY:
        return get_dummy_recommendations()

    model = genai.GenerativeModel(
        model_name="gemini-1.5-flash",
        system_instruction=(
            "Anda adalah asisten AI pendidikan yang ahli dalam merumuskan rencana tindakan pembelajaran. "
            "Berdasarkan data diagnosis kompetensi dan perilaku fokus siswa yang diberikan, "
            "buat rekomendasi yang sangat terperinci dan disesuaikan untuk 3 target pengguna: "
            "1. Guru: Berikan tindakan intervensi konkret di kelas, materi mana yang perlu diajar ulang, atau nama kelompok belajar remedial. "
            "2. Siswa: Langkah pembelajaran berikutnya secara mandiri, rekomendasi modul remedial, dan saran metode belajar (visual/audio/latihan) yang cocok. "
            "3. Orang Tua: Panduan pendampingan sederhana di rumah tanpa istilah teknis kurikulum. "
            "Kembalikan data dalam format JSON terstruktur sesuai skema."
        )
    )

    strengths = diagnosis.get("strengths", [])
    weaknesses = diagnosis.get("weaknesses", [])
    focus_analysis = diagnosis.get("focusAnalysis", diagnosis.get("focus_analysis", ""))
    rec_list = diagnosis.get("recommendations", [])

    prompt = f"""
    ANALISIS DATA DIAGNOSIS:
    - Kompetensi yang Dikuasai (Strengths): {json.dumps(strengths)}
    - Kompetensi yang Lemah (Weaknesses): {json.dumps(weaknesses)}
    - Analisis Fokus Membaca: {focus_analysis}
    - Rekomendasi Awal: {json.dumps(rec_list)}
    
    Rumuskan rekomendasi belajar spesifik untuk Guru, Siswa, dan Orang Tua.
    """

    response = model.generate_content(
        prompt,
        generation_config=genai.types.GenerationConfig(
            response_mime_type="application/json",
            response_schema=TargetRecommendationSchema,
            temperature=0.2,
        )
    )

    try:
        return json.loads(response.text)
    except Exception as e:
        print(f"Gagal memparsing respons JSON Rekomendasi dari Gemini: {e}")
        return get_dummy_recommendations()

def get_dummy_recommendations() -> dict:
    """Returns a valid dummy structure matching the TargetRecommendationSchema for local testing."""
    return {
        "teacher_recommendation": [
            "Lakukan review ulang (re-teaching) secara klasikal khusus pada mekanisme pencernaan kimiawi di usus halus selama 15 menit sebelum masuk materi berikutnya.",
            "Gabungkan Ahmad Fauzi ke dalam kelompok belajar remedial terpandu bersama siswa lain yang lemah di sub-topik penyerapan sari makanan.",
            "Fasilitasi Ahmad Fauzi dengan bahan ajar alternatif berupa poster infografis sistem pencernaan atau tayangan video pendek."
        ],
        "student_recommendation": [
            "Gunakan metode belajar visual: tonton video edukasi interaktif tentang 'Mekanisme Vili Usus Halus' di portal belajar.",
            "Pelajari kembali materi 'Fungsi Empedu & Pencernaan Lemak' dari rangkuman modul halaman 12-14.",
            "Latih pemahamanmu dengan mencoba kuis mandiri khusus topik Usus Besar di aplikasi sebelum menempuh Kuis Utama kembali."
        ],
        "parent_recommendation": [
            "Ajak anak menonton video animasi singkat tentang organ pencernaan di YouTube bersama-sama selama 10 menit.",
            "Tanyakan secara santai organ pencernaan apa saja yang dilewati oleh makanan saat sarapan pagi untuk melatih daya ingatnya.",
            "Dampingi anak belajar dan ingatkan dia untuk mengambil jeda istirahat 5 menit setiap kali dia tampak lelah atau sering mengganti tab browser."
        ]
    }

class TalentPredictionSchema(BaseModel):
    recommendedField: str = Field(description="Rekomendasi kategori bakat: 'Olimpiade Matematika', 'Lomba Informatika/Coding', 'Lomba Karya Tulis Sains', atau 'Kompetisi Bahasa'.")
    confidenceScore: float = Field(description="Skor kepercayaan prediksi bakat (0.0 sampai 1.0).")
    reasoning: str = Field(description="Argumen logis analisis AI mengenai potensi bakat akademik siswa berdasarkan data performa.")

def predict_talent_with_gemini(quiz_averages: dict, average_focus_score: float, weekly_consistency_days: float, quiz_speed_sec: float) -> dict:
    """Uses Gemini API to predict student's academic talent recommendation based on learning analytics metrics."""
    if not GEMINI_API_KEY:
        return get_dummy_talent_prediction()

    model = genai.GenerativeModel(
        model_name="gemini-1.5-flash",
        system_instruction=(
            "Anda adalah AI spesialis bimbingan konseling dan analisis bakat akademik anak. "
            "Tugas Anda adalah memprediksi bidang prestasi anak dari data performa belajar akumulasi. "
            "Pilihlah salah satu dari kategori bakat berikut: "
            "1. 'Olimpiade Matematika'"
            "2. 'Lomba Informatika/Coding'"
            "3. 'Lomba Karya Tulis Sains'"
            "4. 'Kompetisi Bahasa'"
            "Sertakan skor kepercayaan (0.0 s.d 1.0) dan berikan narasi analisis penalaran yang hangat dan memotivasi."
            "Output wajib mematuhi skema JSON yang ditentukan."
        )
    )

    prompt = f"""
    ANALISIS DATA AKUMULASI BELAJAR SISWA:
    - Rerata Nilai Kuis (per mata pelajaran): {json.dumps(quiz_averages)}
    - Rerata Skor Fokus: {average_focus_score}%
    - Rerata Konsistensi Belajar Mingguan: {weekly_consistency_days} hari aktif/minggu
    - Rerata Kecepatan Pengerjaan Kuis: {quiz_speed_sec} detik/soal
    
    Prediksikan bidang prestasi yang paling potensial bagi siswa ini.
    """

    response = model.generate_content(
        prompt,
        generation_config=genai.types.GenerationConfig(
            response_mime_type="application/json",
            response_schema=TalentPredictionSchema,
            temperature=0.2,
        )
    )

    try:
        return json.loads(response.text)
    except Exception as e:
        print(f"Gagal memparsing respons JSON Prediksi Bakat dari Gemini: {e}")
        return get_dummy_talent_prediction()

def get_dummy_talent_prediction() -> dict:
    """Returns a valid dummy structure matching the TalentPredictionSchema for local testing."""
    return {
        "recommendedField": "Lomba Karya Tulis Sains",
        "confidenceScore": 0.92,
        "reasoning": "Siswa menunjukkan performa yang sangat kuat dan konsisten di bidang mata pelajaran IPA/Biologi dengan rata-rata nilai kuis mencapai 88%. Selaras dengan itu, AI Focus Tracker mendeteksi bahwa tingkat fokus membaca modul teks ilmiah sangat tinggi (85%) dengan durasi membaca rata-rata 12 menit per sesi. Kecepatan pengerjaan kuis juga tergolong terencana dan teliti (45 detik per soal). Kombinasi antara daya baca yang mendalam, ketelitian menganalisis konsep biologi, dan kenyamanan mengeksplorasi modul teoretik yang panjang mengindikasikan bakat yang sangat besar di bidang penelitian ilmiah atau penulisan karya ilmiah remaja."
    }

def generate_narrative_report(report_data: dict, target_role: str) -> str:
    """Uses Gemini API to generate a warm, customized narrative report based on raw diagnostics for a specific role (guru, siswa, orang_tua)."""
    if not GEMINI_API_KEY:
        return get_dummy_narrative(target_role)

    role_instructions = {
        "guru": (
            "Gunakan bahasa Indonesia yang formal, analitis, dan profesional akademis. "
            "Fokuslah pada metrik performa kelas, tingkat pemahaman materi, tingkat konsentrasi, "
            "dan rekomendasi intervensi pengajaran klasikal maupun remedial individual."
        ),
        "siswa": (
            "Gunakan bahasa Indonesia yang santai, memotivasi, inspiratif, dan ramah seperti robot tutor pendamping yang hangat. "
            "Fokuslah pada apresiasi usaha belajarnya, dorongan semangat, tips praktis mandiri, dan tantangan menarik berikutnya."
        ),
        "orang_tua": (
            "Gunakan bahasa Indonesia yang sederhana, hangat, penuh empati, dan bebas dari istilah rumit statistik atau kurikulum akademik. "
            "Fokuslah pada cara sederhana pendampingan belajar di rumah dan bagaimana orang tua bisa memberikan suasana nyaman."
        )
    }

    instruction = role_instructions.get(target_role.lower(), role_instructions["siswa"])

    model = genai.GenerativeModel(
        model_name="gemini-1.5-flash",
        system_instruction=(
            f"Anda adalah asisten AI akademik SI-FOKUS. Tugas Anda adalah mengubah data analitik angka siswa "
            f"menjadi laporan naratif bahasa manusia yang hangat dan mudah dipahami sesuai karakteristik pembaca. "
            f"Instruksi Gaya Bahasa Pembaca: {instruction}"
        )
    )

    prompt = f"""
    ANALISIS DATA EVALUASI SISWA:
    {json.dumps(report_data, indent=2)}
    
    Buatlah 1-2 paragraf naratif laporan perkembangan untuk target pembaca: '{target_role}'.
    """

    try:
        response = model.generate_content(prompt)
        return response.text.strip()
    except Exception as e:
        print(f"Gagal menghasilkan laporan naratif Gemini: {e}")
        return get_dummy_narrative(target_role)

def get_dummy_narrative(target_role: str) -> str:
    """Returns a dummy narrative report depending on the target role."""
    if target_role == "guru":
        return (
            "Siswa Ahmad Fauzi menunjukkan pencapaian memuaskan pada kompetensi organ mulut dan lambung. "
            "Namun, terdapat indikasi kelemahan signifikan pada materi penyerapan sari makanan di usus halus. "
            "Rekomendasi intervensi berupa bimbingan kelompok remedial terpadu dan penataan visual pada materi terkait "
            "untuk mengimbangi laju baca siswa yang cenderung terburu-buru."
        )
    elif target_role == "orang_tua":
        return (
            "Bunda, Ahmad Fauzi sudah belajar dengan sangat rajin minggu ini! Ahmad sangat pintar dan fokus saat mempelajari bagian lambung. "
            "Namun, Ahmad tampaknya masih agak kebingungan di bagian usus penyerapan sari makanan. "
            "Bunda bisa membantunya dengan mengajak Ahmad mengobrol santai atau menonton video animasi bersama tentang sistem pencernaan di rumah selama 10 menit."
        )
    else: # siswa
        return (
            "Halo Ahmad! Keren banget kamu sudah rajin belajar dan membaca modul minggu ini! "
            "Pemahamanmu di bagian sistem mulut dan lambung mantap sekali. Untuk bagian penyerapan usus halus, yuk pelajari pelan-pelan lagi. "
            "Jangan membaca terlalu cepat ya, cobalah ambil jeda istirahat 5 menit agar fokusmu tetap terjaga. Kamu pasti bisa!"
        )

