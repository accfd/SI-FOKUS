import os
from fastapi import FastAPI, HTTPException, status, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import httpx
from pydantic import BaseModel, Field

from typing import List
from parser import extract_text
from gemini_service import analyze_material_with_gemini, diagnose_competency_with_gemini, generate_recommendations_with_gemini, predict_talent_with_gemini, generate_narrative_report, generate_single_question_with_gemini
from firestore_service import get_db

app = FastAPI(
    title="SI-FOKUS AI Backend",
    description="Backend API untuk memproses dokumen pembelajaran & ekstraksi soal kuis otomatis menggunakan Gemini API",
    version="1.0.0"
)

# Konfigurasi CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Izinkan semua asal untuk testing lokal, sesuaikan di production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ProcessMaterialRequest(BaseModel):
    file_url: str = Field(description="URL berkas dokumen (.pdf, .docx, .pptx) yang akan diproses")

class FocusDataSchema(BaseModel):
    focusScore: float = Field(description="Skor fokus belajar rata-rata (0-100)")
    readDurationSec: int = Field(description="Total durasi membaca materi dalam detik")
    idleTimeSec: int = Field(description="Durasi diam/tidak beraktivitas dalam detik")
    tabSwitches: int = Field(description="Jumlah perpindahan tab yang dilakukan siswa")
    scrollVelocity: str = Field(description="Kecepatan scroll modul ('Normal' atau 'Abnormal')")

class QuizAnswerSchema(BaseModel):
    questionId: str = Field(description="ID pertanyaan kuis")
    questionText: str = Field(description="Teks pertanyaan kuis")
    selectedAnswerIndex: int = Field(description="Indeks pilihan jawaban yang dipilih siswa")
    correctAnswerIndex: int = Field(description="Indeks pilihan jawaban benar")
    isCorrect: bool = Field(description="Apakah jawaban siswa benar")

class DiagnoseCompetencyRequest(BaseModel):
    student_id: str = Field(description="UID siswa yang bersangkutan")
    class_id: str = Field(description="ID kelas siswa")
    material_id: str = Field(description="ID materi yang diujikan")
    quiz_history: List[QuizAnswerSchema] = Field(description="Riwayat pengerjaan kuis utama siswa")
    focus_data: FocusDataSchema = Field(description="Data pola fokus membaca modul siswa")

@app.get("/")
def read_root():
    return {"status": "running", "service": "SI-FOKUS AI Backend"}

@app.post("/api/process-material-file", status_code=status.HTTP_200_OK)
async def process_material_file(file: UploadFile = File(...)):
    """
    Endpoint untuk mengunggah file secara langsung, mengekstrak teks,
    dan meminta Gemini API menghasilkan ringkasan serta soal kuis (Quick Check & Kuis Utama).
    """
    file_bytes = await file.read()
    file_name = file.filename

    # Validasi ekstensi dasar
    if not any(file_name.lower().endswith(ext) for ext in [".pdf", ".docx", ".pptx", ".ppt"]):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Format file tidak didukung. File harus berupa .pdf, .docx, atau .pptx"
        )

    # 1. Ekstraksi teks dari berkas
    try:
        extracted_text = extract_text(file_bytes, file_name)
    except ValueError as val_err:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(val_err)
        )
    except Exception as parse_err:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengekstrak teks dari berkas: {parse_err}"
        )

    # 2. Minta Gemini menganalisis materi
    try:
        analysis = analyze_material_with_gemini(extracted_text, file_name)
        return analysis
    except Exception as gemini_err:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal menganalisis dokumen via Gemini: {gemini_err}"
        )

@app.post("/api/process-material", status_code=status.HTTP_200_OK)
async def process_material(request: ProcessMaterialRequest):
    """
    Endpoint untuk memproses dokumen pembelajaran.
    1. Mengunduh file dari URL yang dikirimkan.
    2. Mengekstrak teks berdasarkan jenis dokumen (PDF, DOCX, PPTX).
    3. Menganalisis teks menggunakan model Gemini 2.5 Flash.
    4. Mengembalikan ringkasan, topik, soal Quick Check (3 soal), dan Kuis Utama (10 soal) dalam bentuk JSON terstruktur.
    """
    file_url = request.file_url
    file_name = file_url.split("/")[-1]

    # Validasi ekstensi dasar
    if not any(file_name.lower().endswith(ext) for ext in [".pdf", ".docx", ".pptx", ".ppt"]):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Format file tidak didukung. File harus berupa .pdf, .docx, atau .pptx"
        )

    # 1. Unduh dokumen
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(file_url)
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Gagal mengunduh file dari URL. Status code: {response.status_code}"
                )
            file_bytes = response.content
    except httpx.RequestError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Terjadi kesalahan saat menghubungi server pengunduh file: {e}"
        )

    # 2. Ekstraksi teks dari berkas
    try:
        extracted_text = extract_text(file_bytes, file_name)
    except ValueError as val_err:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(val_err)
        )
    except Exception as parse_err:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengekstrak konten teks dari dokumen: {parse_err}"
        )

    if not extracted_text.strip():
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Teks hasil ekstraksi kosong. Pastikan file berisi konten teks yang valid."
        )

    # 3. Kirim ke Gemini API untuk analisis AI
    try:
        ai_analysis_result = analyze_material_with_gemini(extracted_text, file_name)
        return ai_analysis_result
    except Exception as gemini_err:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal melakukan pemrosesan AI via Gemini: {gemini_err}"
        )

@app.post("/api/diagnose-competency", status_code=status.HTTP_200_OK)
async def diagnose_competency(request: DiagnoseCompetencyRequest):
    """
    Endpoint untuk mendiagnosis kompetensi belajar siswa menggunakan Gemini 2.5 Pro.
    1. Menerima data jawaban kuis dan pola perilaku membaca.
    2. Menganalisis kelebihan, kelemahan, serta pola fokus menggunakan Gemini API.
    3. Menyimpan hasil analisis ke Firestore dalam koleksi 'student_competencies'.
    """
    # Ubah data input ke bentuk dictionary
    quiz_history_dict = [q.model_dump() for q in request.quiz_history]
    focus_data_dict = request.focus_data.model_dump()

    try:
        # Panggil Gemini Service
        diagnosis = diagnose_competency_with_gemini(quiz_history_dict, focus_data_dict)
    except Exception as gemini_err:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal melakukan diagnosis kompetensi via Gemini: {gemini_err}"
        )

    # F-25: Generate narrative reports for each target role before saving to DB
    try:
        teacher_narrative = generate_narrative_report(diagnosis, "guru")
        student_narrative = generate_narrative_report(diagnosis, "siswa")
        parent_narrative = generate_narrative_report(diagnosis, "orang_tua")
    except Exception as narr_err:
        print(f"Warning: Gagal membuat narasi AI: {narr_err}")
        # Fallbacks
        from gemini_service import get_dummy_narrative
        teacher_narrative = get_dummy_narrative("guru")
        student_narrative = get_dummy_narrative("siswa")
        parent_narrative = get_dummy_narrative("orang_tua")

    # Simpan ke Firestore
    try:
        db = get_db()
        diagnosis_data = {
            "studentId": request.student_id,
            "classId": request.class_id,
            "materialId": request.material_id,
            "strengths": diagnosis.get("strengths", []),
            "weaknesses": diagnosis.get("weaknesses", []),
            "recommendations": diagnosis.get("recommendations", []),
            "focusAnalysis": diagnosis.get("focus_analysis", ""),
            # Nalar AI (F-25)
            "teacherNarrative": teacher_narrative,
            "studentNarrative": student_narrative,
            "parentNarrative": parent_narrative
        }
        
        # Simpan dokumen baru ke Firestore
        _, doc_ref = db.collection("student_competencies").add(diagnosis_data)
        
        # Tambahkan ID dokumen yang tersimpan ke response
        response_data = {
            "diagnosis_id": doc_ref.id if doc_ref else "mock_added_id",
            "teacher_narrative": teacher_narrative,
            "student_narrative": student_narrative,
            "parent_narrative": parent_narrative,
            **diagnosis
        }
        return response_data
    except Exception as db_err:
        # Jika Firestore gagal, kita tetap kembalikan hasil Gemini namun log warning
        print(f"Warning: Gagal menyimpan hasil diagnosis ke Firestore: {db_err}")
        return {
            "diagnosis_id": "failed_to_save",
            "teacher_narrative": teacher_narrative,
            "student_narrative": student_narrative,
            "parent_narrative": parent_narrative,
            **diagnosis
        }

class GenerateRecommendationsRequest(BaseModel):
    student_id: str = Field(description="UID siswa")
    class_id: str = Field(description="ID kelas siswa")
    material_id: str = Field(description="ID materi")
    diagnosis_id: str = Field(default="", description="ID dokumen student_competencies. Jika kosong, akan dicari dokumen terbaru.")

@app.post("/api/generate-recommendations", status_code=status.HTTP_200_OK)
async def generate_recommendations(request: GenerateRecommendationsRequest):
    """
    Endpoint untuk membuat rekomendasi belajar ter-personalisasi untuk 3 target (Guru, Siswa, Orang Tua).
    1. Mengambil data diagnosis kompetensi dari Firestore.
    2. Menghasilkan rekomendasi belajar tertarget menggunakan Gemini 2.5 Flash.
    3. Menyimpan hasil rekomendasi kembali ke dokumen Firestore terkait.
    """
    db = get_db()
    diagnosis_data = None
    doc_ref = None

    # 1. Cari data diagnosis kompetensi di Firestore
    try:
        if request.diagnosis_id:
            doc_ref = db.collection("student_competencies").document(request.diagnosis_id)
            doc_snap = doc_ref.get()
            if doc_snap.exists:
                diagnosis_data = doc_snap.to_dict()
        
        if not diagnosis_data:
            # Cari dokumen terbaru berdasarkan studentId & materialId
            docs = (
                db.collection("student_competencies")
                .where("studentId", "==", request.student_id)
                .where("materialId", "==", request.material_id)
                .get()
            )
            # Karena mock client get() mengembalikan list kosong, ini aman
            if docs:
                # Ambil dokumen pertama jika ada
                doc_ref = docs[0].reference if hasattr(docs[0], 'reference') else docs[0]
                diagnosis_data = docs[0].to_dict()
    except Exception as e:
        print(f"Gagal mengambil data diagnosis dari Firestore: {e}")

    # Fallback ke dummy diagnosis jika tidak ada di DB (misal saat testing lokal)
    if not diagnosis_data:
        from gemini_service import get_dummy_diagnosis
        diagnosis_data = get_dummy_diagnosis()
        print("Menggunakan fallback dummy diagnosis untuk generating recommendations.")

    # 2. Panggil Gemini Service untuk merumuskan rekomendasi
    try:
        recommendations = generate_recommendations_with_gemini(diagnosis_data)
    except Exception as gemini_err:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal merumuskan rekomendasi via Gemini: {gemini_err}"
        )

    # 3. Simpan rekomendasi kembali ke dokumen Firestore
    try:
        if doc_ref:
            update_payload = {
                "teacherRecommendations": recommendations.get("teacher_recommendation", []),
                "studentRecommendations": recommendations.get("student_recommendation", []),
                "parentRecommendations": recommendations.get("parent_recommendation", [])
            }
            doc_ref.set(update_payload, merge=True)
            print(f"Rekomendasi berhasil disimpan ke dokumen: {doc_ref.id}")
    except Exception as db_err:
        print(f"Warning: Gagal mengupdate rekomendasi ke Firestore: {db_err}")

    return {
        "status": "success",
        "diagnosis_id": doc_ref.id if doc_ref else "mock_doc_id",
        **recommendations
    }

class PredictTalentRequest(BaseModel):
    student_id: str = Field(description="UID siswa")
    quiz_averages: dict = Field(description="Peta subjek ke rata-rata nilai kuis (misal: {'Biologi': 88, 'Matematika': 62})")
    average_focus_score: float = Field(description="Rata-rata focus score siswa di seluruh materi (0-100)")
    weekly_consistency_days: float = Field(description="Rata-rata hari aktif belajar per minggu")
    quiz_speed_sec: float = Field(description="Rata-rata waktu pengerjaan per soal kuis dalam detik")

@app.post("/api/predict-talent", status_code=status.HTTP_200_OK)
async def predict_talent(request: PredictTalentRequest):
    """
    Endpoint untuk mendeteksi potensi bakat akademik siswa menggunakan Gemini 2.5 Flash.
    1. Menerima data akumulasi performa akademik, fokus, konsistensi, & kecepatan pengerjaan kuis.
    2. Memprediksi kategori bakat (Olimpiade Matematika, Lomba Informatika, Karya Tulis Sains, Lomba Bahasa).
    3. Menyimpan hasil analisis ke Firestore dalam koleksi 'talent_recommendations'.
    """
    try:
        # Panggil Gemini Service
        prediction = predict_talent_with_gemini(
            quiz_averages=request.quiz_averages,
            average_focus_score=request.average_focus_score,
            weekly_consistency_days=request.weekly_consistency_days,
            quiz_speed_sec=request.quiz_speed_sec
        )
    except Exception as gemini_err:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal memprediksi bakat siswa via Gemini: {gemini_err}"
        )

    # Simpan ke Firestore
    try:
        db = get_db()
        talent_data = {
            "studentId": request.student_id,
            "recommendedField": prediction.get("recommendedField", "Lomba Karya Tulis Sains"),
            "confidenceScore": prediction.get("confidenceScore", 0.0),
            "reasoning": prediction.get("reasoning", "")
        }
        
        # Simpan dokumen baru ke Firestore
        _, doc_ref = db.collection("talent_recommendations").add(talent_data)
        
        # Tambahkan ID dokumen yang tersimpan ke response
        response_data = {
            "recommendation_id": doc_ref.id if doc_ref else "mock_added_id",
            **prediction
        }
        return response_data
    except Exception as db_err:
        print(f"Warning: Gagal menyimpan rekomendasi bakat ke Firestore: {db_err}")
        return {
            "recommendation_id": "failed_to_save",
            **prediction
        }

class GenerateSingleQuestionRequest(BaseModel):
    file_url: str = Field(description="URL berkas dokumen (.pdf, .docx, .pptx) yang akan diproses")
    question_type: str = Field(description="Tipe soal: 'pilihan_ganda' | 'majemuk_kompleks' | 'isian_singkat'")

@app.post("/api/generate-single-question", status_code=status.HTTP_200_OK)
async def generate_single_question(request: GenerateSingleQuestionRequest):
    """
    Endpoint untuk menghasilkan satu soal tertentu berdasarkan tipe soal menggunakan Gemini.
    """
    file_url = request.file_url
    question_type = request.question_type
    file_name = file_url.split("/")[-1]

    # 1. Coba baca secara lokal terlebih dahulu
    local_path = os.path.join("..", "web", file_url)
    if os.path.exists(local_path):
        try:
            with open(local_path, "rb") as f:
                file_bytes = f.read()
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Gagal membaca file lokal: {e}"
            )
    else:
        # Coba unduh via HTTP
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.get(file_url)
                if response.status_code != 200:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Gagal mengunduh berkas dari URL: {file_url}"
                    )
                file_bytes = response.content
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Gagal menghubungi server untuk mengunduh berkas: {e}"
            )

    # 2. Ekstraksi teks
    try:
        extracted_text = extract_text(file_bytes, file_name)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal mengekstrak teks dari berkas: {e}"
        )

    # 3. Generate question
    try:
        question_data = generate_single_question_with_gemini(extracted_text, file_name, question_type)
        return question_data
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Gagal menghasilkan soal via Gemini: {e}"
        )

if __name__ == "__main__":
    import uvicorn
    # Jalankan uvicorn secara lokal di port 8000
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
