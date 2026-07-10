import os
import firebase_admin
from firebase_admin import credentials, firestore

db = None

class MockDocumentSnapshot:
    def __init__(self, doc_id, data, exists=False):
        self.id = doc_id
        self.exists = exists
        self._data = data
    def to_dict(self):
        return self._data

class MockDocument:
    def __init__(self, collection_name, doc_id):
        self.collection_name = collection_name
        self.id = doc_id or "mock_doc_id"
    def set(self, data, merge=True):
        print(f"[MOCK FIRESTORE] Set data in '{self.collection_name}/{self.id}': {data} (merge={merge})")
        return None
    def get(self):
        return MockDocumentSnapshot(self.id, {}, exists=False)

class MockCollection:
    def __init__(self, name):
        self.name = name
    def document(self, doc_id=None):
        return MockDocument(self.name, doc_id)
    def add(self, data):
        print(f"[MOCK FIRESTORE] Added data to collection '{self.name}': {data}")
        return None, MockDocument(self.name, "mock_added_id")

class MockFirestoreClient:
    """Mock client used during local testing when Firebase configuration is absent."""
    def collection(self, name):
        return MockCollection(name)

def init_firestore():
    global db
    if db is not None:
        return db
        
    cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "")
    try:
        if cred_path and os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            db = firestore.client()
            print("Firebase Admin initialized via credentials JSON.")
        else:
            # Mencoba menginisialisasi dengan konfigurasi default (misal untuk gcloud CLI / ADC)
            firebase_admin.initialize_app()
            db = firestore.client()
            print("Firebase Admin initialized via default credentials.")
    except Exception as e:
        print(f"Firebase Admin initialization warning: {e}. Menggunakan Mock Firestore Client untuk pengujian lokal.")
        db = MockFirestoreClient()
    return db

# Ekspor objek database terinisialisasi
get_db = init_firestore
