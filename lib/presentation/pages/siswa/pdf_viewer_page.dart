import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../data/models/material_model.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/quick_check/quick_check_bloc.dart';
import 'quick_check_page.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startFocusTimer();
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
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _saveActivityAndExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.material.title,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: Colors.indigo.shade900,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            TextButton.icon(
              onPressed: _isTargetMet ? _saveActivityAndExit : null,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                'Selesai',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: _isTargetMet ? Colors.greenAccent : Colors.grey.shade400,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Banner indikator tracker (Non-invasif tapi transparan ke pengguna)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.indigo.shade50,
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
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 5, // 5 Halaman PDF Dummy
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        height: 600,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halaman ${index + 1}',
                                style: GoogleFonts.outfit(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                widget.material.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo.shade900,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: Text(
                                  'Ini adalah simulasi halaman PDF untuk materi ${widget.material.title}.\n\n'
                                  'Karena limitasi rendering PDF (CORS) di lingkungan Web lokal, '
                                  'kami menggunakan tampilan tiruan (mock) ini agar Anda dapat menguji '
                                  'sistem Pelacak Fokus (Focus Tracker) dengan lancar.\n\n'
                                  'Silakan gulir ke bawah atau berdiam diri untuk melihat peringatan AI '
                                  'berfungsi sebagaimana mestinya.',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    height: 1.6,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text, {bool isWarning = false}) {
    final color = isWarning ? Colors.orange.shade800 : Colors.indigo.shade700;
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
}
