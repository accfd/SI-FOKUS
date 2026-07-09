/// Utility class untuk validasi URL dan deteksi tipe sumber belajar.
class UrlValidator {
  UrlValidator._();

  /// Regex standar validasi URL (http/https).
  static final RegExp _urlRegex = RegExp(
    r'^https?:\/\/'                     // Wajib dimulai dengan http:// atau https://
    r'([\w\-]+\.)+[\w\-]+'              // Domain (termasuk subdomain)
    r'(:\d{1,5})?'                      // Port opsional
    r'(\/[^\s]*)?$',                    // Path opsional
    caseSensitive: false,
  );

  /// Regex khusus pola URL YouTube.
  static final RegExp _youtubeRegex = RegExp(
    r'^https?:\/\/(www\.)?(youtube\.com\/(watch\?v=|embed\/|shorts\/)|youtu\.be\/)',
    caseSensitive: false,
  );

  /// Memvalidasi apakah [url] merupakan URL yang valid.
  static bool isValidUrl(String url) {
    if (url.trim().isEmpty) return false;
    return _urlRegex.hasMatch(url.trim());
  }

  /// Mendeteksi tipe resource secara otomatis dari pola URL.
  /// - YouTube → 'youtube'
  /// - Lainnya → 'link'
  /// Catatan: Tipe 'video_file' harus dipilih manual oleh user
  /// karena tidak bisa dideteksi dari URL saja.
  static String detectType(String url) {
    if (_youtubeRegex.hasMatch(url.trim())) return 'youtube';
    return 'link';
  }

  /// Mengekstrak YouTube Video ID dari URL.
  /// Mengembalikan null jika URL bukan YouTube.
  static String? extractYoutubeId(String url) {
    final trimmed = url.trim();

    // Format: youtube.com/watch?v=VIDEO_ID
    final watchMatch = RegExp(r'youtube\.com\/watch\?v=([a-zA-Z0-9_-]{11})').firstMatch(trimmed);
    if (watchMatch != null) return watchMatch.group(1);

    // Format: youtu.be/VIDEO_ID
    final shortMatch = RegExp(r'youtu\.be\/([a-zA-Z0-9_-]{11})').firstMatch(trimmed);
    if (shortMatch != null) return shortMatch.group(1);

    // Format: youtube.com/embed/VIDEO_ID
    final embedMatch = RegExp(r'youtube\.com\/embed\/([a-zA-Z0-9_-]{11})').firstMatch(trimmed);
    if (embedMatch != null) return embedMatch.group(1);

    // Format: youtube.com/shorts/VIDEO_ID
    final shortsMatch = RegExp(r'youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})').firstMatch(trimmed);
    if (shortsMatch != null) return shortsMatch.group(1);

    return null;
  }
}
