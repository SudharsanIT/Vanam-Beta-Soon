import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_colors.dart';
import '../services/tflite_service.dart';

class WildLensScreen extends StatefulWidget {
  const WildLensScreen({super.key});

  @override
  State<WildLensScreen> createState() => _WildLensScreenState();
}

class _WildLensScreenState extends State<WildLensScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isProcessing = false;
  Map<String, dynamic>? _currentDetection;

  // 🔥 உன்னோட Cloudinary விவரங்கள் செட் பண்ணியாச்சு 🔥
  final String cloudName = "sbyrupt";
  final String uploadPreset = "vanam_preset";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCameraAndAI();
  }

  Future<void> _initializeCameraAndAI() async {
    await TFLiteService.instance.loadModel();

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _currentDetection = null;
    });

    try {
      // 1. Photo எடுப்பது
      final XFile photo = await _cameraController!.takePicture();

      // 2. Offline AI-க்கு அனுப்புவது
      final aiResult = await TFLiteService.instance.processCapturedImage(photo.path);

      setState(() {
        _currentDetection = aiResult;
      });

      // 3. Cloudinary-க்கு Upload செய்வது
      await _uploadToCloudinary(photo.path);

    } catch (e) {
      debugPrint("Capture Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _uploadToCloudinary(String filePath) async {
    final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
    final request = http.MultipartRequest("POST", uri);

    request.fields['upload_preset'] = uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    try {
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = jsonDecode(responseString);

      if (response.statusCode == 200) {
        final imageUrl = jsonMap['secure_url'];
        debugPrint("✅ Uploaded to Cloudinary: $imageUrl");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo Saved Online!'), backgroundColor: AppColors.primaryGreen),
          );
        }
      } else {
        debugPrint("❌ Upload Failed: ${jsonMap['error']['message']}");
      }
    } catch (e) {
      debugPrint("Cloudinary API Error: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    TFLiteService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    final isDanger = _currentDetection?['is_danger'] ?? false;
    final alertColor = isDanger ? AppColors.dangerRed : AppColors.primaryGreen;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),

          // Scanner Border Layout
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _currentDetection != null ? alertColor : Colors.white54,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          if (_currentDetection != null)
            Positioned(
              top: 80,
              left: 24,
              right: 24,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                  border: Border.all(color: alertColor, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(isDanger ? Icons.warning_rounded : Icons.check_circle_rounded, color: alertColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentDetection!['label'].toUpperCase(),
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 20, color: alertColor),
                          ),
                        ),
                        Text(
                          '${(_currentDetection!['confidence'] * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentDetection!['advice'],
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // 🔥 Capture & Upload Button 🔥
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _captureAndProcess,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: _isProcessing ? Colors.grey : AppColors.primaryGreen,
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 36),
                ),
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          )
        ],
      ),
    );
  }
}