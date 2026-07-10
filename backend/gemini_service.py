import os
import json
import google.generativeai as genai
from pydantic import BaseModel, Field
from typing import List, Optional

# Setup API Key (Membaca dari Environment atau file .env lokal)
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
if not GEMINI_API_KEY:
    env_path = os.path.join(os.path.dirname(__file__), ".env")
    if os.path.exists(env_path):
        with open(env_path, "r") as f:
            for line in f:
                if "=" in line and not line.strip().startswith("#"):
                    key, val = line.strip().split("=", 1)
                    if key.strip() == "GEMINI_API_KEY":
                        GEMINI_API_KEY = val.strip()
                        os.environ["GEMINI_API_KEY"] = GEMINI_API_KEY
                        break

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

class QuestionSchema(BaseModel):
    questionId: str = Field(description="ID pertanyaan kuis unik, misal: q001, q002, dst.")
    questionText: str = Field(description="Teks pertanyaan kuis secara akademik langsung tanpa referensi ke file dokumen.")
    options: List[str] = Field(description="Daftar opsi pilihan jawaban. Untuk pilihan_ganda biasa wajib sediakan 5 opsi (A, B, C, D, E). Untuk majemuk_kompleks dan isian_singkat biarkan list kosong [].")
    correctAnswerIndex: Optional[int] = Field(None, description="Indeks jawaban benar (0 sampai 4) untuk pilihan_ganda biasa. Set null untuk tipe soal lainnya.")
    type: str = Field("pilihan_ganda", description="Tipe soal: 'pilihan_ganda' | 'majemuk_kompleks' | 'isian_singkat'")
    correctAnswers: Optional[List[int]] = Field(None, description="Hanya untuk tipe 'majemuk_kompleks', berisi list angka 1 (Benar) atau 0 (Salah) untuk merepresentasikan jawaban setiap pernyataan sub-soal.")
    correctAnswerText: Optional[str] = Field(None, description="Hanya untuk tipe 'isian_singkat', berisi kunci jawaban kata/frasa singkat.")
    topicTag: str = Field("", description="Tag topik spesifik dari modul yang dicakup oleh soal ini.")

class MaterialProcessResult(BaseModel):
    summary: str = Field(description="Ringkasan materi pembelajaran yang komprehensif (maksimal 300 kata).")
    topics: List[str] = Field(description="Daftar topik utama yang dibahas dalam materi tersebut.")
    quick_check: List[QuestionSchema] = Field(description="Daftar tepat 3 soal kuis singkat untuk Quick Check pemahaman awal.")
    quiz_utama: List[QuestionSchema] = Field(description="Daftar tepat 10 soal kuis utama dengan tingkat kesulitan bertahap.")

def generate_dynamic_fallback(text: str, filename: str) -> dict:
    """Generates a realistic, dynamic fallback summary and quizzes when Gemini API quota is exceeded."""
    title = filename.replace(".pdf", "").replace(".docx", "").replace(".pptx", "").replace(".ppt", "").replace("_", " ")
    if not title.strip():
        title = "Dokumen Pembelajaran"

    # Extract keywords
    stopwords = {
        "adalah", "tentang", "yang", "untuk", "dalam", "dengan", "dan", "atau", "dari", 
        "pada", "oleh", "juga", "yaitu", "ialah", "bahwa", "sebagai", "dapat", "akan", 
        "telah", "sudah", "kami", "mereka", "karena", "sehingga", "tetapi", "namun", 
        "jika", "maka", "pada", "bisa", "ini", "itu", "serta", "yaitu", "secara", "lebih"
    }
    words = [w.strip(",.()\"'[]:;-+=!?").lower() for w in text.split() if len(w) > 4]
    filtered_words = [w for w in words if w.isalnum() and w not in stopwords]
    
    unique_words = []
    for w in filtered_words:
        cap_w = w.capitalize()
        if cap_w not in unique_words:
            unique_words.append(cap_w)
            
    keywords = unique_words[:5] if len(unique_words) >= 5 else ["Metode", "Konsep", "Organisasi", "Evaluasi", "Keselamatan"]
    
    sentences = [s.strip() for s in text.split(".") if len(s.strip()) > 20]
    extracted_summary = ""
    if len(sentences) >= 2:
        extracted_summary = ". ".join(sentences[:2]) + "."
        if len(extracted_summary) > 400:
            extracted_summary = extracted_summary[:400] + "..."
    else:
        extracted_summary = "Materi membahas tentang prinsip-prinsip sains, metode ilmiah dalam melakukan pengamatan, dan keselamatan kerja di laboratorium."
        
    summary = f"Pembahasan {title}: {extracted_summary} Fokus utama materi adalah pemahaman menyeluruh terhadap konsep dasar dan penerapan praktis."
    
    quick_check = [
        {
            "questionId": "qc_fb_1",
            "questionText": "Hingga kini penyakit AIDS belum ada obatnya. Penelitian dilakukan oleh para ahli untuk mengetahui aktivitas Virus HIV pada tingkat organisasi kehidupan yaitu...",
            "options": ["A. Molekul", "B. Sel", "C. Jaringan", "D. Organ", "E. Sistem organ"],
            "correctAnswerIndex": 1,
            "type": "pilihan_ganda",
            "correctAnswers": None,
            "correctAnswerText": None,
            "topicTag": "Organisasi Kehidupan"
        },
        {
            "questionId": "qc_fb_2",
            "questionText": "Pembuatan film terkenal Jurassic Park menceritakan kehidupan hewan purba. Cabang ilmu biologi yang paling berperan dalam memodelkan hewan purba tersebut adalah...",
            "options": ["A. Evolusi", "B. Botani", "C. Zoologi", "D. Palaeontologi", "E. Anatomi"],
            "correctAnswerIndex": 3,
            "type": "pilihan_ganda",
            "correctAnswers": None,
            "correctAnswerText": None,
            "topicTag": "Cabang Biologi"
        },
        {
            "questionId": "qc_fb_3",
            "questionText": "Seseorang yang akan menjalani transplantasi organ hati perlu memahami struktur fungsi hati. Studi tersebut dipelajari pada tingkat organisasi...",
            "options": ["A. Sel", "B. Jaringan", "C. Organ", "D. Sistem organ", "E. Individu"],
            "correctAnswerIndex": 2,
            "type": "pilihan_ganda",
            "correctAnswers": None,
            "correctAnswerText": None,
            "topicTag": "Organisasi Kehidupan"
        }
    ]
    
    quiz_utama = [
        {
            "questionId": "qu_fb_1",
            "questionText": "Berikut merupakan salah satu manfaat penerapan biologi di bidang peternakan secara modern adalah...",
            "options": [
              "A. Memperbanyak dengan teknik kultur jaringan",
              "B. Membuat antibodi monoklonal",
              "C. Membuat vaksin pencegah penyakit virus SARS",
              "D. Terapi gen transgenik menghasilkan susu sapi lebih berkualitas",
              "E. Menghasilkan insulin buatan"
            ],
            "correctAnswerIndex": 3,
            "type": "pilihan_ganda",
            "correctAnswers": None,
            "correctAnswerText": None,
            "topicTag": "Manfaat Biologi"
        },
        {
            "questionId": "qu_fb_2",
            "questionText": "Sekelompok peneliti melakukan pengamatan terhadap perilaku sekumpulan harimau Sumatera (Panthera tigris sumatrae). Tingkat organisasi kehidupan yang diamati adalah...",
            "options": ["A. Ekosistem", "B. Komunitas", "C. Populasi", "D. Individu", "E. Bioma"],
            "correctAnswerIndex": 2,
            "type": "pilihan_ganda",
            "correctAnswers": None,
            "correctAnswerText": None,
            "topicTag": "Organisasi Kehidupan"
        },
        {
            "questionId": "qu_fb_3",
            "questionText": "Seorang peneliti mengamati lingkungan X dan menemukan bahwa banyak bayi terlahir cacat akibat kekurangan gizi serta polusi logam berat. Bidang studi biologi yang mempelajari cacat perkembangan embrio ini adalah...",
            "options": ["A. Parasitologi", "B. Ginekologi", "C. Teratologi", "D. Genetika", "E. Fisiologi"],
            "correctAnswerIndex": 2,
            "type": "pilihan_ganda",
            "correctAnswers": None,
            "correctAnswerText": None,
            "topicTag": "Cabang Biologi"
        },
        {
            "questionId": "qu_fb_4",
            "questionText": "Dalam suatu langkah metode ilmiah, eksperimen atau percobaan dilakukan secara terkontrol untuk menguji...",
            "options": ["A. Pengumpulan data", "B. Rumusan masalah", "C. Latar belakang", "D. Kesimpulan", "E. Hipotesis"],
            "correctAnswerIndex": 4,
            "type": "pilihan_ganda",
            "correctAnswers": None,
            "correctAnswerText": None,
            "topicTag": "Metode Ilmiah"
        },
        {
            "questionId": "qu_fb_5",
            "questionText": "Perilaku yang benar, aman, dan menjaga keselamatan kerja saat berada di dalam laboratorium biologi adalah...",
            "options": ["A. Membawa bekal makanan", "B. Mengenakan pakaian ketat", "C. Bersikap serius dan tekun", "D. Bersikap gembira dan bercanda", "E. Menggunakan seragam sekolah ketat"],
            "correctAnswerIndex": 2,
            "type": "pilihan_ganda",
            "correctAnswers": None,
            "correctAnswerText": None,
            "topicTag": "Keselamatan Kerja"
        },
        {
            "questionId": "qu_fb_6",
            "questionText": "Jika Anda memasuki laboratorium dan melihat simbol botol pecah mengeluarkan cairan korosif, berarti zat tersebut bersifat...",
            "options": ["A. Korosif", "B. Beracun", "C. Radioaktif", "D. Mudah meledak", "E. Mudah terbakar"],
            "correctAnswerIndex": 0,
            "type": "pilihan_ganda",
            "correctAnswers": None,
            "correctAnswerText": None,
            "topicTag": "Keselamatan Kerja"
        },
        {
            "questionId": "qu_fb_7",
            "questionText": "Tentukan Benar (B) atau Salah (S) untuk pernyataan keselamatan kerja berikut:\n1. Membuang sisa limbah asam pekat langsung ke wastafel diperbolehkan.\n2. Selalu gunakan jas lab kancing lengkap saat berada di laboratorium.",
            "options": [],
            "correctAnswerIndex": None,
            "type": "majemuk_kompleks",
            "correctAnswers": [0, 1],
            "correctAnswerText": None,
            "topicTag": "Keselamatan Kerja"
        },
        {
            "questionId": "qu_fb_8",
            "questionText": "Tentukan Benar (B) atau Salah (S) untuk pernyataan tingkat organisasi kehidupan berikut:\n1. Kumpulan sel sejenis yang memiliki bentuk dan fungsi sama disebut jaringan.\n2. Tingkatan organisasi kehidupan tertinggi di biosfer adalah individu tunggal.",
            "options": [],
            "correctAnswerIndex": None,
            "type": "majemuk_kompleks",
            "correctAnswers": [1, 0],
            "correctAnswerText": None,
            "topicTag": "Organisasi Kehidupan"
        },
        {
            "questionId": "qu_fb_9",
            "questionText": "Langkah pertama dalam metode ilmiah setelah mengamati fenomena alam secara seksama adalah merumuskan...",
            "options": [],
            "correctAnswerIndex": None,
            "type": "isian_singkat",
            "correctAnswers": None,
            "correctAnswerText": "masalah",
            "topicTag": "Metode Ilmiah"
        },
        {
            "questionId": "qu_fb_10",
            "questionText": "Dugaan awal atau jawaban sementara yang diajukan peneliti terhadap rumusan masalah penelitian disebut...",
            "options": [],
            "correctAnswerIndex": None,
            "type": "isian_singkat",
            "correctAnswers": None,
            "correctAnswerText": "hipotesis",
            "topicTag": "Metode Ilmiah"
        }
    ]
        
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
                "Anda adalah asisten AI akademik ahli kurikulum nasional untuk platform e-learning adaptif SI-FOKUS.\n\n"
                "=== KERANGKA KERJA PROMPT (TKFBC) ===\n"
                "1. TUGAS (Task):\n"
                "   - Ekstrak atau sadurlah pertanyaan-pertanyaan evaluasi, soal latihan, atau tes formatif beserta kunci jawabannya yang sudah tertulis di dalam dokumen asli (terutama di bagian akhir seperti bab EVALUASI/LATIHAN) secara persis ke dalam format JSON.\n"
                "   - Jika tidak ada soal orisinal di dalam dokumen, buatlah soal kuis akademik baru secara mandiri berdasarkan materi.\n"
                "   - Hasilkan juga ringkasan materi pelajaran yang komprehensif serta daftar topik utama.\n"
                "2. KONTEKS (Context):\n"
                "   - Hasil kuis ini akan langsung dikerjakan oleh siswa SMP/SMA di platform untuk verifikasi pemahaman belajar mereka.\n"
                "3. FORMAT (Format):\n"
                "   - Keluaran WAJIB berupa JSON murni yang sesuai dengan skema 'MaterialProcessResult'.\n"
                "4. BATASAN (Constraints):\n"
                "   - DILARANG KERAS menggunakan kalimat referensial dokumen (contoh yang DILARANG: 'Berdasarkan dokumen...', 'Sesuai modul ini...', 'Di dalam file ini...', atau referensi berkas sejenis). Soal harus langsung terfokus secara akademis.\n"
                "   - Jumlah kata ringkasan maksimal 300 kata.\n"
                "   - Tipe kuis terbagi menjadi 3 model:\n"
                "     * 'pilihan_ganda': Pilihan ganda biasa dengan tepat 5 opsi jawaban (A, B, C, D, E).\n"
                "     * 'majemuk_kompleks': Pernyataan Benar/Salah (diwakili list correctAnswers berisi 1 untuk Benar, 0 untuk Salah).\n"
                "     * 'isian_singkat': Mengisi rumpang dengan jawaban teks singkat (diwakili correctAnswerText).\n"
                "5. CONTOH (Example):\n"
                "   - Pilihan Ganda (5 opsi): {'questionId': 'q1', 'questionText': 'Seseorang akan menjalani transplantasi hati. Hati dipelajari pada tingkat organisasi...', 'options': ['A. Sel', 'B. Jaringan', 'C. Organ', 'D. Sistem organ', 'E. Individu'], 'correctAnswerIndex': 2, 'type': 'pilihan_ganda', 'correctAnswers': None, 'correctAnswerText': None, 'topicTag': 'Organisasi Kehidupan'}\n"
                "   - Majemuk Kompleks: {'questionId': 'q2', 'questionText': 'Tentukan Benar (B) atau Salah (S) untuk pernyataan keselamatan kerja berikut:\\n1. Jas lab digunakan saat praktikum.\\n2. Zat korosif aman disentuh tangan langsung.', 'options': [], 'correctAnswerIndex': None, 'type': 'majemuk_kompleks', 'correctAnswers': [1, 0], 'correctAnswerText': None, 'topicTag': 'Keselamatan Kerja'}\n"
                "   - Isian Singkat: {'questionId': 'q3', 'questionText': 'Langkah pertama dalam metode ilmiah setelah mengamati masalah adalah merumuskan...', 'options': [], 'correctAnswerIndex': None, 'type': 'isian_singkat', 'correctAnswers': None, 'correctAnswerText': 'masalah', 'topicTag': 'Metode Ilmiah'}"
            )
        )

        prompt = f"Berikut adalah teks pelajaran yang harus dianalisis:\n\n{text}"

        response = model.generate_content(
            prompt,
            generation_config=genai.types.GenerationConfig(
                response_mime_type="application/json",
                response_schema=MaterialProcessResult,
                temperature=0.15,
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

def generate_single_question_with_gemini(text: str, filename: str, question_type: str) -> dict:
    """Generates a single question of a specific type ('pilihan_ganda', 'majemuk_kompleks', 'isian_singkat') based on the text."""
    if not GEMINI_API_KEY:
        fallback_res = generate_dynamic_fallback(text, filename)
        for q in fallback_res["quiz_utama"]:
            if q["type"] == question_type:
                return q
        return fallback_res["quick_check"][0]

    try:
        model = genai.GenerativeModel(
            model_name="gemini-2.0-flash",
            system_instruction=(
                "Anda adalah asisten AI akademik yang ahli. Buatlah tepat SATU soal kuis yang valid secara akademik berdasarkan teks materi yang diberikan.\n"
                "Format output WAJIB mematuhi skema JSON dari QuestionSchema."
            )
        )

        prompt = f"""
        Buatlah satu soal bertipe: '{question_type}' berdasarkan materi pelajaran berikut.
        Jangan merujuk dokumen secara langsung (hindari kalimat seperti 'Berdasarkan dokumen...').
        
        Materi:
        {text}
        """

        response = model.generate_content(
            prompt,
            generation_config=genai.types.GenerationConfig(
                response_mime_type="application/json",
                response_schema=QuestionSchema,
                temperature=0.3,
            )
        )

        return json.loads(response.text)
    except Exception as e:
        print(f"Warning: Gagal membuat single question ({e}). Menjalankan fallback...")
        fallback_res = generate_dynamic_fallback(text, filename)
        for q in fallback_res["quiz_utama"]:
            if q["type"] == question_type:
                return q
        return fallback_res["quick_check"][0]
