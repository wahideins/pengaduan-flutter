import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraXScreen extends StatefulWidget {
  final bool enableVideo;
  const CameraXScreen({super.key, this.enableVideo = false});

  @override
  State<CameraXScreen> createState() => _CameraXScreenState();
}

class _CameraXScreenState extends State<CameraXScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isRearCamera = true;
  bool _isRecording = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    final camera = cameras.firstWhere(
      (c) => _isRearCamera
          ? c.lensDirection == CameraLensDirection.back
          : c.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: widget.enableVideo,
    );

    await _controller!.initialize();
    await _controller!.setFlashMode(_flashMode);

    if (!mounted) return;
    setState(() => _isInitialized = true);
  }

  Future<void> _switchCamera() async {
    _isRearCamera = !_isRearCamera;
    await _controller?.dispose();
    _controller = null;
    setState(() => _isInitialized = false);
    await _initCamera();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;

    _flashMode =
        _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;

    await _controller!.setFlashMode(_flashMode);
    setState(() {});
  }

  /// ================== FOTO ==================
  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) return;

    final XFile file = await _controller!.takePicture();

    Navigator.pop(context, {
      'type': 'image',
      'file': File(file.path),
    });
  }

  /// ================== VIDEO ==================
  Future<void> _startRecording() async {
    if (!_controller!.value.isInitialized) return;

    await _controller!.startVideoRecording();
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    final XFile file = await _controller!.stopVideoRecording();
    setState(() => _isRecording = false);

    Navigator.pop(context, {
      'type': 'video',
      'file': File(file.path),
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitialized
          ? Stack(
              children: [
                CameraPreview(_controller!),

                /// 🔙 BACK
                Positioned(
                  top: 40,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                /// ⚡ FLASH
                Positioned(
                  top: 40,
                  right: 16,
                  child: IconButton(
                    icon: Icon(
                      _flashMode == FlashMode.off
                          ? Icons.flash_off
                          : Icons.flash_on,
                      color: Colors.white,
                    ),
                    onPressed: _toggleFlash,
                  ),
                ),

                /// 🎥 MODE INFO
                Positioned(
                  top: 90,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      widget.enableVideo
                          ? (_isRecording ? 'RECORDING...' : 'VIDEO')
                          : 'PHOTO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                /// 🎛 CONTROL BAWAH
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      /// 🔄 SWITCH CAMERA
                      IconButton(
                        icon: const Icon(
                          Icons.cameraswitch,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: _switchCamera,
                      ),

                      /// 📸 / 🎥 CAPTURE
                      GestureDetector(
                        onTap: widget.enableVideo
                            ? (_isRecording
                                ? _stopRecording
                                : _startRecording)
                            : _takePicture,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.enableVideo && _isRecording
                                ? Colors.red
                                : Colors.transparent,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }
}
