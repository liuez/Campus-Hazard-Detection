import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const SafeCampusApp());
}

class SafeCampusApp extends StatelessWidget {
  const SafeCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeCampus AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006B5F)),
        scaffoldBackgroundColor: const Color(0xFFF4F7F5),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFDDE5E1)),
          ),
        ),
      ),
      home: const DetectionHomePage(),
    );
  }
}

class DetectionHomePage extends StatefulWidget {
  const DetectionHomePage({super.key});

  @override
  State<DetectionHomePage> createState() => _DetectionHomePageState();
}

class _DetectionHomePageState extends State<DetectionHomePage> {
  static const List<String> _zones = <String>[
    'Main walkway',
    'Parking area',
    'Building entrance',
    'Sports area',
    'Construction zone',
  ];

  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  ui.Size? _imageSize;
  DetectionResponse? _result;
  String _zone = _zones.first;
  bool _isLoading = false;
  bool _isSavingEvidence = false;
  String? _error;
  String? _evidenceMessage;

  String get _apiUrl => kIsWeb ? 'http://127.0.0.1:8000/detect' : 'http://10.0.2.2:8000/detect';
  String get _evidenceUrl => kIsWeb ? 'http://127.0.0.1:8000/evidence' : 'http://10.0.2.2:8000/evidence';

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source, imageQuality: 92);
    if (picked == null) return;

    final Uint8List bytes = await picked.readAsBytes();
    final ui.Size size = await _readImageSize(bytes);

    setState(() {
      _imageBytes = bytes;
      _imageSize = size;
      _result = null;
      _error = null;
      _evidenceMessage = null;
    });
  }

  Future<ui.Size> _readImageSize(Uint8List bytes) async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image image = frame.image;
    return ui.Size(image.width.toDouble(), image.height.toDouble());
  }

  Future<void> _detectHazard() async {
    final Uint8List? bytes = _imageBytes;
    if (bytes == null) {
      setState(() => _error = 'Choose a campus image first.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _evidenceMessage = null;
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.fields['zone'] = _zone;
      request.fields['confidence_threshold'] = '0.25';
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'campus_hazard.jpg'));

      final streamed = await request.send().timeout(const Duration(seconds: 90));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 200) {
        throw Exception('Backend returned ${streamed.statusCode}: $body');
      }

      setState(() {
        _result = DetectionResponse.fromJson(jsonDecode(body) as Map<String, dynamic>);
      });
    } catch (error) {
      setState(() => _error = 'Detection failed. Make sure backend is running on port 8000.\n$error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEvidence() async {
    final Uint8List? bytes = _imageBytes;
    final DetectionResponse? result = _result;
    if (bytes == null || result == null || !result.detected) {
      setState(() => _error = 'Run a successful detection before saving evidence.');
      return;
    }

    setState(() {
      _isSavingEvidence = true;
      _error = null;
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_evidenceUrl));
      request.fields['zone'] = _zone;
      request.fields['result_json'] = jsonEncode(result.toJson());
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'evidence.jpg'));

      final streamed = await request.send().timeout(const Duration(seconds: 45));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 200) {
        throw Exception('Backend returned ${streamed.statusCode}: $body');
      }

      final saved = jsonDecode(body) as Map<String, dynamic>;
      final evidenceId = saved['evidence_id'] as String? ?? 'evidence record';
      setState(() => _evidenceMessage = 'Saved $evidenceId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Evidence saved: $evidenceId')));
      }
    } catch (error) {
      setState(() => _error = 'Evidence save failed.\n$error');
    } finally {
      if (mounted) setState(() => _isSavingEvidence = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Detection? finalDetection = _result?.finalDetection;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: const Row(
          children: <Widget>[
            Icon(Icons.health_and_safety_outlined),
            SizedBox(width: 10),
            Text('SafeCampus AI'),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _StatusPill(
                icon: Icons.cloud_done_outlined,
                text: kIsWeb ? 'Web API' : 'Android API',
                color: const Color(0xFF006B5F),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool wide = constraints.maxWidth >= 960;
            final Widget controls = Column(
              children: <Widget>[
                _ControlPanel(
                  zone: _zone,
                  zones: _zones,
                  isLoading: _isLoading,
                  hasImage: _imageBytes != null,
                  onZoneChanged: (value) => setState(() => _zone = value),
                  onChooseImage: () => _pickImage(ImageSource.gallery),
                  onCamera: kIsWeb ? null : () => _pickImage(ImageSource.camera),
                  onDetect: _detectHazard,
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _ErrorPanel(message: _error!),
                ],
                const SizedBox(height: 12),
                _ResultPanel(result: _result, isLoading: _isLoading),
                if (_result?.detected == true && _imageBytes != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _EvidencePanel(
                    isSaving: _isSavingEvidence,
                    message: _evidenceMessage,
                    onSave: _saveEvidence,
                  ),
                ],
                const SizedBox(height: 12),
                _VotesPanel(detections: _result?.detections ?? const <Detection>[]),
              ],
            );

            final Widget imagePanel = _ImagePanel(
              imageBytes: _imageBytes,
              imageSize: _imageSize,
              detection: finalDetection,
              isLoading: _isLoading,
            );

            return ListView(
              padding: EdgeInsets.symmetric(horizontal: wide ? 28 : 14, vertical: 16),
              children: <Widget>[
                _HeaderSummary(result: _result, zone: _zone),
                const SizedBox(height: 14),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(flex: 7, child: imagePanel),
                      const SizedBox(width: 14),
                      Expanded(flex: 5, child: controls),
                    ],
                  )
                else ...<Widget>[
                  controls,
                  const SizedBox(height: 12),
                  imagePanel,
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderSummary extends StatelessWidget {
  const _HeaderSummary({required this.result, required this.zone});

  final DetectionResponse? result;
  final String zone;

  @override
  Widget build(BuildContext context) {
    final Detection? detection = result?.finalDetection;
    final String status = detection == null ? 'Ready' : _formatLabel(detection.severity);
    final Color statusColor = detection == null ? const Color(0xFF48625B) : _severityColor(detection.severity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: <Widget>[
            SizedBox(
              width: 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Campus hazard scan', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(zone, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF5B6864))),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _StatusPill(icon: Icons.place_outlined, text: zone, color: const Color(0xFF44615A)),
                _StatusPill(icon: Icons.bolt_outlined, text: status, color: statusColor),
                _StatusPill(
                  icon: Icons.storage_outlined,
                  text: '${result?.detections.length ?? 0} candidates',
                  color: const Color(0xFF5A5669),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.zone,
    required this.zones,
    required this.isLoading,
    required this.hasImage,
    required this.onZoneChanged,
    required this.onChooseImage,
    required this.onCamera,
    required this.onDetect,
  });

  final String zone;
  final List<String> zones;
  final bool isLoading;
  final bool hasImage;
  final ValueChanged<String> onZoneChanged;
  final VoidCallback onChooseImage;
  final VoidCallback? onCamera;
  final VoidCallback onDetect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Scan setup', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: zone,
              decoration: const InputDecoration(
                labelText: 'Campus zone',
                prefixIcon: Icon(Icons.map_outlined),
                border: OutlineInputBorder(),
              ),
              items: zones.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: isLoading ? null : (value) => onZoneChanged(value ?? zone),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : onChooseImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choose Image'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.outlined(
                  tooltip: kIsWeb ? 'Camera is available on Android run' : 'Camera',
                  onPressed: isLoading ? null : onCamera,
                  icon: const Icon(Icons.photo_camera_outlined),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: isLoading || !hasImage ? null : onDetect,
                icon: isLoading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.security_outlined),
                label: Text(isLoading ? 'Detecting...' : 'Detect Hazard'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidencePanel extends StatelessWidget {
  const _EvidencePanel({required this.isSaving, required this.message, required this.onSave});

  final bool isSaving;
  final String? message;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.folder_copy_outlined),
                const SizedBox(width: 8),
                Text('Evidence capture', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isSaving ? null : onSave,
                icon: isSaving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_alt_outlined),
                label: Text(isSaving ? 'Saving...' : 'Save Evidence'),
              ),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(message!, style: const TextStyle(color: Color(0xFF25745E), fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImagePanel extends StatelessWidget {
  const _ImagePanel({required this.imageBytes, required this.imageSize, required this.detection, required this.isLoading});

  final Uint8List? imageBytes;
  final ui.Size? imageSize;
  final Detection? detection;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: DecoratedBox(
            decoration: BoxDecoration(color: const Color(0xFF101817), borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (imageBytes == null)
                    const _EmptyImageState()
                  else
                    ColoredBox(color: Colors.black, child: Image.memory(imageBytes!, fit: BoxFit.contain)),
                  if (imageSize != null && detection?.bbox != null)
                    CustomPaint(painter: DetectionBoxPainter(imageSize: imageSize!, detection: detection!)),
                  if (isLoading)
                    const ColoredBox(color: Color(0x66000000), child: Center(child: CircularProgressIndicator())),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyImageState extends StatelessWidget {
  const _EmptyImageState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.add_photo_alternate_outlined, size: 52, color: Colors.white.withValues(alpha: 0.72)),
          const SizedBox(height: 10),
          Text(
            'No image selected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white.withValues(alpha: 0.82)),
          ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.result, required this.isLoading});

  final DetectionResponse? result;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final Detection? item = result?.finalDetection;
    final bool detected = result?.detected ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.fact_check_outlined),
                const SizedBox(width: 8),
                Text('Detection result', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 14),
            if (isLoading)
              const LinearProgressIndicator()
            else if (result == null)
              const Text('Run detection to see the final hazard result.')
            else if (!detected || item == null)
              const _NoHazardState()
            else ...<Widget>[
              _HazardHero(detection: item),
              const SizedBox(height: 14),
              _InfoRow(label: 'Hazard', value: _formatLabel(item.label)),
              _InfoRow(label: 'Category', value: _formatLabel(item.category)),
              _InfoRow(label: 'Confidence', value: '${(item.confidence * 100).toStringAsFixed(1)}%'),
              _InfoRow(label: 'Model', value: item.model),
              _InfoRow(label: 'Zone', value: result!.zone),
              const Divider(height: 24),
              Text('Recommended action', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(result!.recommendation),
            ],
          ],
        ),
      ),
    );
  }
}

class _HazardHero extends StatelessWidget {
  const _HazardHero({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context) {
    final Color color = _severityColor(detection.severity);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(backgroundColor: color, foregroundColor: Colors.white, child: const Icon(Icons.warning_amber_outlined)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(_formatLabel(detection.label), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('${_formatLabel(detection.severity)} severity'),
                ],
              ),
            ),
            Text(
              '${(detection.confidence * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoHazardState extends StatelessWidget {
  const _NoHazardState();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Icon(Icons.check_circle_outline, color: Color(0xFF25745E)),
        const SizedBox(width: 10),
        Expanded(child: Text('No hazard detected above the confidence threshold.', style: Theme.of(context).textTheme.bodyLarge)),
      ],
    );
  }
}

class _VotesPanel extends StatelessWidget {
  const _VotesPanel({required this.detections});

  final List<Detection> detections;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.analytics_outlined),
                const SizedBox(width: 8),
                Text('Model candidates', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            if (detections.isEmpty)
              const Text('No candidate detections yet.')
            else
              ...detections.take(8).map((item) => _CandidateRow(detection: item)),
          ],
        ),
      ),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context) {
    final Color color = _severityColor(detection.severity);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Container(width: 10, height: 38, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(_formatLabel(detection.label), style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${detection.model} | ${_formatLabel(detection.category)} | ${_formatLabel(detection.severity)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text('${(detection.confidence * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 104, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.error_outline, color: Color(0xFFB3261E)),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Color(0xFF8C1D18)))),
          ],
        ),
      ),
    );
  }
}

class DetectionBoxPainter extends CustomPainter {
  DetectionBoxPainter({required this.imageSize, required this.detection});

  final ui.Size imageSize;
  final Detection detection;

  @override
  void paint(Canvas canvas, Size size) {
    final List<double>? bbox = detection.bbox;
    if (bbox == null || bbox.length < 4 || imageSize.width <= 0 || imageSize.height <= 0) return;

    final double scale = math.min(size.width / imageSize.width, size.height / imageSize.height);
    final double displayWidth = imageSize.width * scale;
    final double displayHeight = imageSize.height * scale;
    final double offsetX = (size.width - displayWidth) / 2;
    final double offsetY = (size.height - displayHeight) / 2;

    final Rect rect = Rect.fromLTRB(
      offsetX + bbox[0] * scale,
      offsetY + bbox[1] * scale,
      offsetX + bbox[2] * scale,
      offsetY + bbox[3] * scale,
    );

    final Color color = _severityColor(detection.severity);
    canvas.drawRect(rect, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 3.5);

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: '${_formatLabel(detection.label)} ${(detection.confidence * 100).toStringAsFixed(0)}%',
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 16);

    final Rect labelRect = Rect.fromLTWH(
      rect.left.clamp(0, size.width - textPainter.width - 12),
      math.max(0, rect.top - textPainter.height - 8),
      textPainter.width + 12,
      textPainter.height + 8,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(labelRect, const Radius.circular(4)), Paint()..color = color);
    textPainter.paint(canvas, Offset(labelRect.left + 6, labelRect.top + 4));
  }

  @override
  bool shouldRepaint(covariant DetectionBoxPainter oldDelegate) {
    return oldDelegate.detection != detection || oldDelegate.imageSize != imageSize;
  }
}

class DetectionResponse {
  DetectionResponse({required this.detected, required this.zone, required this.recommendation, required this.detections, required this.finalDetection});

  final bool detected;
  final String zone;
  final String recommendation;
  final List<Detection> detections;
  final Detection? finalDetection;

  factory DetectionResponse.fromJson(Map<String, dynamic> json) {
    final Object? finalJson = json['final'];
    final List<dynamic> rawDetections = json['detections'] as List<dynamic>? ?? const <dynamic>[];
    return DetectionResponse(
      detected: json['detected'] == true,
      zone: json['zone'] as String? ?? 'Unknown',
      recommendation: finalJson is Map<String, dynamic>
          ? finalJson['recommendation'] as String? ?? json['recommendation'] as String? ?? 'No recommendation returned.'
          : json['recommendation'] as String? ?? 'No recommendation returned.',
      detections: rawDetections.whereType<Map<String, dynamic>>().map(Detection.fromJson).toList(),
      finalDetection: finalJson is Map<String, dynamic> ? Detection.fromJson(finalJson) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detected': detected,
      'zone': zone,
      'recommendation': recommendation,
      'final': finalDetection?.toJson(),
      'detections': detections.map((item) => item.toJson()).toList(),
    };
  }
}

class Detection {
  Detection({required this.model, required this.label, required this.confidence, required this.category, required this.severity, required this.bbox});

  final String model;
  final String label;
  final double confidence;
  final String category;
  final String severity;
  final List<double>? bbox;

  static String _modelLabel(Map<String, dynamic> json) {
    final String modelId = json['model_id'] as String? ?? '';
    final String modelName = json['model_name'] as String? ?? '';
    if (modelId.isNotEmpty && modelName.isNotEmpty) return '$modelId - $modelName';
    if (modelId.isNotEmpty) return modelId;
    if (modelName.isNotEmpty) return modelName;
    return json['model'] as String? ?? 'unknown model';
  }

  factory Detection.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? rawBbox = json['bbox'] as List<dynamic>?;
    return Detection(
      model: _modelLabel(json),
      label: json['label'] as String? ?? 'unknown hazard',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? 'General hazard',
      severity: json['severity'] as String? ?? 'medium',
      bbox: rawBbox?.map((value) => (value as num).toDouble()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'label': label,
      'confidence': confidence,
      'category': category,
      'severity': severity,
      'bbox': bbox,
    };
  }
}

Color _severityColor(String severity) {
  switch (severity.toLowerCase()) {
    case 'high':
      return const Color(0xFFD92D20);
    case 'medium':
      return const Color(0xFFB45F06);
    case 'low':
      return const Color(0xFF25745E);
    default:
      return const Color(0xFF596A80);
  }
}

String _formatLabel(String value) {
  if (value.trim().isEmpty) return value;
  return value.split('_').where((part) => part.isNotEmpty).map((part) => part[0].toUpperCase() + part.substring(1)).join(' ');
}
