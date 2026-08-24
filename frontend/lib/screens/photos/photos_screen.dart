import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/photo.dart';
import '../../providers/auth_provider.dart';
import '../../services/photo_service.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final PhotoService _photoService = PhotoService();
  final TextEditingController _captionController = TextEditingController();
  late Future<void> _loadFuture;
  List<Photo> _photos = const [];
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;
    _photos = await _photoService.fetchPhotos(token, widget.projectId);
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to read selected image.')),
      );
      return;
    }
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;

    setState(() => _uploading = true);
    try {
      await _photoService.uploadPhoto(
        token: token,
        projectId: widget.projectId,
        bytes: file.bytes!,
        fileName: file.name,
        caption: _captionController.text.trim(),
      );
      _captionController.clear();
      setState(() {
        _loadFuture = _loadData();
      });
      await _loadFuture;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo uploaded successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _photos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 280,
                      child: TextField(
                        controller: _captionController,
                        decoration: const InputDecoration(
                          labelText: 'Photo caption (optional)',
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _uploading ? null : _pickAndUpload,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Photo'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_photos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No progress photos uploaded yet.')),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _photos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final photo = _photos[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: photo.url.isNotEmpty
                              ? Image.network(
                                  photo.url,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image_outlined, size: 48),
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.image_outlined, size: 48),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                photo.caption.isNotEmpty ? photo.caption : 'Untitled photo',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                photo.uploadedAt != null ? DateFormat.yMMMd().add_jm().format(photo.uploadedAt!) : 'No upload date',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
