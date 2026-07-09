import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/url_validator.dart';
import '../../../data/models/learning_resource_model.dart';
import '../../../domain/repositories/resource_repository.dart';
import '../../bloc/resource/resource_bloc.dart';
import '../../bloc/resource/resource_event.dart';
import '../../bloc/resource/resource_state.dart';

class ManageLearningResourcePage extends StatelessWidget {
  final String classId;
  final String materialId;

  const ManageLearningResourcePage({
    super.key,
    required this.classId,
    required this.materialId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ResourceBloc(
        resourceRepository: context.read<ResourceRepository>(),
      )..add(FetchResourcesByMaterial(materialId)),
      child: _ManageLearningResourceView(
        classId: classId,
        materialId: materialId,
      ),
    );
  }
}

class _ManageLearningResourceView extends StatefulWidget {
  final String classId;
  final String materialId;

  const _ManageLearningResourceView({
    required this.classId,
    required this.materialId,
  });

  @override
  State<_ManageLearningResourceView> createState() =>
      _ManageLearningResourceViewState();
}

class _ManageLearningResourceViewState
    extends State<_ManageLearningResourceView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  String _detectedType = 'link';
  late AnimationController _fabAnimController;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _urlController.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty && UrlValidator.isValidUrl(url)) {
      final type = UrlValidator.detectType(url);
      if (type != _detectedType) {
        setState(() => _detectedType = type);
      }
    }
  }

  void _showAddResourceSheet() {
    _titleController.clear();
    _urlController.clear();
    setState(() => _detectedType = 'link');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Tambah Sumber Belajar',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tempelkan link YouTube, video instruksi, atau referensi edukatif.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // URL Field
                      TextFormField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: 'URL Sumber Belajar',
                          hintText: 'https://youtube.com/watch?v=...',
                          prefixIcon: Icon(
                            _detectedType == 'youtube'
                                ? Icons.play_circle_fill_rounded
                                : Icons.link_rounded,
                            color: _detectedType == 'youtube'
                                ? Colors.red
                                : null,
                          ),
                          suffixIcon: _urlController.text.trim().isNotEmpty
                              ? Icon(
                                  UrlValidator.isValidUrl(_urlController.text.trim())
                                      ? Icons.check_circle_rounded
                                      : Icons.error_rounded,
                                  color: UrlValidator.isValidUrl(
                                          _urlController.text.trim())
                                      ? Colors.green
                                      : Colors.red,
                                )
                              : null,
                        ),
                        keyboardType: TextInputType.url,
                        onChanged: (val) {
                          setSheetState(() {
                            final type = UrlValidator.detectType(val.trim());
                            _detectedType = type;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'URL tidak boleh kosong';
                          }
                          if (!UrlValidator.isValidUrl(value.trim())) {
                            return 'Format URL tidak valid. Harus dimulai dengan http:// atau https://';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Judul Sumber Belajar',
                          hintText: 'Misal: Video Penjelasan Persamaan Linear',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Judul tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Detected type indicator
                      _buildTypeChip(ctx, _detectedType),
                      const SizedBox(height: 12),

                      // YouTube preview
                      if (_detectedType == 'youtube' &&
                          UrlValidator.isValidUrl(_urlController.text.trim()))
                        _buildYoutubeThumbnailPreview(_urlController.text.trim()),
                      const SizedBox(height: 24),

                      // Submit button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final resource = LearningResourceModel(
                              resourceId:
                                  'res_${DateTime.now().millisecondsSinceEpoch}',
                              title: _titleController.text.trim(),
                              type: _detectedType,
                              url: _urlController.text.trim(),
                            );
                            context.read<ResourceBloc>().add(
                                  AddResourceToMaterial(
                                    materialId: widget.materialId,
                                    resource: resource,
                                  ),
                                );
                            Navigator.of(ctx).pop();
                          }
                        },
                        icon: const Icon(Icons.add_rounded, color: Colors.white),
                        label: const Text('Simpan Sumber Belajar'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeChip(BuildContext ctx, String type) {
    final theme = Theme.of(ctx);
    IconData icon;
    String label;
    Color chipColor;

    switch (type) {
      case 'youtube':
        icon = Icons.play_circle_fill_rounded;
        label = 'YouTube Video';
        chipColor = Colors.red;
        break;
      case 'video_file':
        icon = Icons.videocam_rounded;
        label = 'Video File';
        chipColor = Colors.deepPurple;
        break;
      default:
        icon = Icons.link_rounded;
        label = 'Referensi Link';
        chipColor = theme.colorScheme.primary;
    }

    return Row(
      children: [
        const Text(
          'Tipe Terdeteksi: ',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        Chip(
          avatar: Icon(icon, size: 18, color: Colors.white),
          label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          backgroundColor: chipColor,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _buildYoutubeThumbnailPreview(String url) {
    final videoId = UrlValidator.extractYoutubeId(url);
    if (videoId == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.network(
              'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 180,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Warna aksen Teal Emerald untuk halaman sumber belajar
    final accentColor = isDark
        ? HSLColor.fromAHSL(1.0, 165, 0.75, 0.55).toColor()
        : HSLColor.fromAHSL(1.0, 165, 0.80, 0.38).toColor();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sumber Belajar Tambahan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddResourceSheet,
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_link_rounded),
        label: const Text('Tambah Resource'),
      ),
      body: BlocConsumer<ResourceBloc, ResourceState>(
        listener: (context, state) {
          if (state is ResourceActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is ResourceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ResourceLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ResourceLoaded) {
            if (state.resources.isEmpty) {
              return _buildEmptyState(theme, accentColor);
            }
            return _buildResourceList(theme, accentColor, state.resources);
          }

          if (state is ResourceError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 64, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, Color accentColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.library_books_rounded,
                size: 64,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum Ada Sumber Belajar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan link YouTube, video instruksi, atau referensi edukatif untuk memperkaya materi pembelajaran.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddResourceSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Sumber Pertama'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceList(
    ThemeData theme,
    Color accentColor,
    List<LearningResourceModel> resources,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: resources.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader(theme, accentColor, resources.length);
        }
        final resource = resources[index - 1];
        return _buildResourceCard(theme, accentColor, resource);
      },
    );
  }

  Widget _buildHeader(ThemeData theme, Color accentColor, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.auto_stories_rounded, color: accentColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sumber Belajar Terdaftar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '$count resource tersedia',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(
    ThemeData theme,
    Color accentColor,
    LearningResourceModel resource,
  ) {
    IconData typeIcon;
    Color typeColor;
    String typeLabel;

    switch (resource.type) {
      case 'youtube':
        typeIcon = Icons.play_circle_fill_rounded;
        typeColor = Colors.red;
        typeLabel = 'YouTube';
        break;
      case 'video_file':
        typeIcon = Icons.videocam_rounded;
        typeColor = Colors.deepPurple;
        typeLabel = 'Video File';
        break;
      default:
        typeIcon = Icons.link_rounded;
        typeColor = accentColor;
        typeLabel = 'Link Referensi';
    }

    // YouTube thumbnail
    Widget? thumbnail;
    if (resource.type == 'youtube') {
      final videoId = UrlValidator.extractYoutubeId(resource.url);
      if (videoId != null) {
        thumbnail = ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.network(
                'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 140,
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.broken_image_rounded, size: 32)),
                ),
              ),
              Container(
                width: double.infinity,
                height: 140,
                color: Colors.black.withValues(alpha: 0.25),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?thumbnail,
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(typeIcon, size: 20, color: typeColor),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            color: theme.colorScheme.error, size: 22),
                        tooltip: 'Hapus sumber belajar',
                        onPressed: () => _confirmDelete(resource),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resource.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resource.url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(LearningResourceModel resource) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Hapus Sumber Belajar?'),
          content: Text(
            'Apakah Anda yakin ingin menghapus "${resource.title}"? Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                context.read<ResourceBloc>().add(
                      RemoveResource(
                        materialId: widget.materialId,
                        resourceId: resource.resourceId,
                      ),
                    );
                Navigator.of(ctx).pop();
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}
