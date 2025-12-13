import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/pengaduan.dart';

class DetailPengaduanScreen extends StatefulWidget {
  final Pengaduan pengaduan;
  const DetailPengaduanScreen({super.key, required this.pengaduan});

  @override
  State<DetailPengaduanScreen> createState() => _DetailPengaduanScreenState();
}

class _DetailPengaduanScreenState extends State<DetailPengaduanScreen> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.pengaduan.videoUrl != null) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.pengaduan.videoUrl!),
      )
        ..initialize().then((_) {
          setState(() {});
        })
        ..addListener(() {
          if (mounted) setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pengaduan;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengaduan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              p.nama,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('Telp: ${p.noTelp}'),
            if (p.lokasi != null) Text('Lokasi: ${p.lokasi}'),
            const Divider(height: 24),
            Text(
              p.isiPengaduan,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (p.gambarUrl != null)
              Image.network(
                p.gambarUrl!,
                height: 200,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 12),

            // === VIDEO PLAYER DENGAN KONTROL ===
            if (_videoController != null && _videoController!.value.isInitialized)
              Column(
                children: [
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                  const SizedBox(height: 8),
                  VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    colors: const VideoProgressColors(
                      playedColor: Colors.blueAccent,
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.black12,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          _videoController!.value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                          size: 40,
                          color: Colors.blueAccent,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_videoController!.value.isPlaying) {
                              _videoController!.pause();
                            } else {
                              _videoController!.play();
                            }
                          });
                        },
                      ),
                      Text(
                        "${_formatDuration(_videoController!.value.position)} / ${_formatDuration(_videoController!.value.duration)}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop, color: Colors.redAccent),
                        onPressed: () {
                          _videoController!.pause();
                          _videoController!.seekTo(Duration.zero);
                        },
                      ),
                    ],
                  ),
                ],
              ),

            const SizedBox(height: 16),
            Text(
              'Tanggal: ${p.createdAt}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
