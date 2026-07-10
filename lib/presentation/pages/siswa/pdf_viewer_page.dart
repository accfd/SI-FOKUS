import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../data/models/material_model.dart';
import '../../../../data/repositories/material_repository_impl.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/quick_check/quick_check_bloc.dart';
import 'quick_check_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../presentation/widgets/shared_ui_kit.dart';

class PdfViewerPage extends StatefulWidget {
  final MaterialModel material;

  const PdfViewerPage({Key? key, required this.material}) : super(key: key);

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> with WidgetsBindingObserver {
  // Focus Tracking Variables
  int _readDurationSec = 0;
  int _idleTimeSec = 0;
  int _tabSwitches = 0;
  
  int _timeSinceLastAction = 0;
  bool _isIdle = false;
  bool _isIdleWarningShown = false;
  bool _isBackground = false;
  
  bool _hasAbnormalScroll = false;
  bool _hasPdfError = false;
  
  Timer? _focusTimer;
  
  final List<DateTime> _pageChangeTimestamps = [];
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  bool get _isTargetMet => _readDurationSec >= 60; // Set to 60 seconds (1 min) for demo purposes, instead of 10 min

  bool _isGuru = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _isGuru = authState.user.role == 'guru';
    }
    WidgetsBinding.instance.addObserver(this);
    if (!_isGuru) {
      _startFocusTimer();
    }
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startFocusTimer() {
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isBackground) return; // Jangan hitung saat aplikasi di background
      
      setState(() {
        _timeSinceLastAction++;
        
        // Cek jika idle >= 30 detik
        if (_timeSinceLastAction >= 30) {
          _isIdle = true;
          _idleTimeSec++;
          if (!_isIdleWarningShown) {
            _showWarning('Tetap fokus! Aktivitas membaca Anda sedang diamati untuk pembukaan Kuis.');
            _isIdleWarningShown = true;
          }
        } else {
          _isIdle = false;
          _isIdleWarningShown = false;
          _readDurationSec++;
        }
      });
    });
  }

  void _resetActionTimer() {
    if (_isIdle) {
      setState(() {
        _isIdle = false;
        _isIdleWarningShown = false;
      });
    }
    _timeSinceLastAction = 0;
  }

  void _showWarning(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (!_isBackground) {
        _isBackground = true;
        setState(() {
          _tabSwitches++;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isBackground) {
        _isBackground = false;
        _resetActionTimer();
        _showWarning('Tetap fokus! Aktivitas membaca Anda sedang diamati untuk pembukaan Kuis.');
      }
    }
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    _resetActionTimer();
    
    final now = DateTime.now();
    _pageChangeTimestamps.add(now);
    
    // Hapus timestamp yang usianya lebih dari 2 detik
    _pageChangeTimestamps.removeWhere((timestamp) => now.difference(timestamp).inSeconds > 2);
    
    // Jika terdeteksi scroll 10 halaman dalam 2 detik
    if (_pageChangeTimestamps.length >= 10 && !_hasAbnormalScroll) {
      setState(() {
        _hasAbnormalScroll = true;
      });
      _showWarning('Terdeteksi pergerakan scroll tidak wajar! Harap baca materi dengan saksama.');
    }
  }

  Future<void> _saveActivityAndExit() async {
    _focusTimer?.cancel();
    
    // Rumus Evaluasi Fokus: 100 - (idleTimeSec * 0.4) - (tabSwitches * 12) - (abnormal scroll ? 20 : 0)
    double focusScore = 100 - (_idleTimeSec * 0.4) - (_tabSwitches * 12) - (_hasAbnormalScroll ? 20 : 0);
    focusScore = max(0, focusScore); // Batasi nilai minimal 0

    // Dapatkan data siswa
    final authState = context.read<AuthBloc>().state;
    String studentId = '';
    if (authState is Authenticated) {
      studentId = authState.user.uid;
    }

    try {
      if (studentId.isNotEmpty) {
        // Kirim payload data ke Firestore tanpa await agar tidak memblokir navigasi
        FirebaseFirestore.instance.collection('activities').add({
          'studentId': studentId,
          'materialId': widget.material.materialId,
          'readDurationSec': _readDurationSec,
          'scrollVelocity': _hasAbnormalScroll ? 'Abnormal' : 'Normal',
          'idleTimeSec': _idleTimeSec,
          'tabSwitches': _tabSwitches,
          'focusScore': focusScore,
          'isCompleted': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Gagal menyimpan data aktivitas: $e");
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => QuickCheckBloc(),
            child: QuickCheckPage(material: widget.material),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isGuru,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_isGuru) {
          Navigator.of(context).pop();
        } else {
          await _saveActivityAndExit();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: SharedAppBar(
          title: widget.material.title,
          actions: [
            if (!_isGuru)
              TextButton.icon(
                onPressed: _isTargetMet ? _saveActivityAndExit : null,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  'Selesai',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: _isTargetMet ? AppColors.accentLight : Colors.grey.shade400,
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Banner indikator tracker (Hanya untuk siswa)
            if (!_isGuru)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(Icons.timer_outlined, 'Membaca: ${_readDurationSec}s'),
                    _buildStatItem(Icons.pause_circle_outline, 'Idle: ${_idleTimeSec}s', isWarning: _idleTimeSec > 30),
                    _buildStatItem(Icons.switch_access_shortcut, 'Pindah Tab: $_tabSwitches', isWarning: _tabSwitches > 0),
                  ],
                ),
              ),
            Expanded(
              child: Listener(
                onPointerDown: (_) => _resetActionTimer(),
                onPointerMove: (_) => _resetActionTimer(),
                onPointerUp: (_) => _resetActionTimer(),
                child: Container(
                  color: Colors.grey.shade300,
                  child: _buildPdfContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text, {bool isWarning = false}) {
    final color = isWarning ? AppColors.accentLight : AppColors.primaryLight;
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPdfContent() {
    final cachedBytes = MaterialRepositoryImpl.getCachedBytes(widget.material.materialId);
    if (cachedBytes != null) {
      return SfPdfViewer.memory(
        Uint8List.fromList(cachedBytes),
        key: _pdfViewerKey,
        onDocumentLoadFailed: (details) {
          setState(() {
            _hasPdfError = true;
          });
        },
      );
    }

    final url = widget.material.fileUrl;
    return SfPdfViewer.network(
      url,
      key: _pdfViewerKey,
      onDocumentLoadFailed: (details) {
        setState(() {
          _hasPdfError = true;
        });
      },
    );
  }
}
