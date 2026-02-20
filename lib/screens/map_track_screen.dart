import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../components/map_type_dialog.dart';
import '../models/track_data.dart';
import '../components/routs.dart';

class MapTrack extends StatefulWidget {
  static String id = 'map_track_screen';
  const MapTrack({super.key});

  @override
  State<MapTrack> createState() => _MapTrackState();
}

class _MapTrackState extends State<MapTrack> {
  final GlobalKey _globalKey = GlobalKey();
  final List<Color> _trackColors = [
    Colors.blue, Colors.red, Colors.green, Colors.purple,
    Colors.orange, Colors.pink, Colors.teal, Colors.cyan,
  ];
  int _colorIndex = 0;
  bool _isCutMode = false;
  bool _isPhotoPickMode = false;

  BitmapDescriptor? _noteIcon;
  BitmapDescriptor? _pauseIcon;
  BitmapDescriptor? _startIcon;
  BitmapDescriptor? _endIcon;
  BitmapDescriptor? _photoIcon;
  bool _iconsLoaded = false;

  Future<void> _loadAllCustomIcons() async {
    _noteIcon = await _createCustomMarker(Icons.note_alt, Colors.orange);
    _pauseIcon = await _createCustomMarker(Icons.pause, Colors.blue);
    _startIcon = await _createCustomMarker(Icons.play_arrow, Colors.red);
    _endIcon = await _createCustomMarker(Icons.stop, Colors.green);
    _photoIcon = await _createCustomMarker(Icons.camera_alt, Colors.purple);
    if (mounted) setState(() => _iconsLoaded = true);
  }

  Future<BitmapDescriptor> _createCustomMarker(IconData iconData, Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(pictureRecorder);
    const double size = 60.0; 
    const double radius = size / 2;

    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 50/255)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(const ui.Offset(radius, radius + 1), radius - 2, shadowPaint);
    canvas.drawCircle(const ui.Offset(radius, radius), radius - 2, Paint()..color = Colors.white);
    canvas.drawCircle(const ui.Offset(radius, radius), radius - 4, Paint()..color = color);

    TextPainter textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    textPainter.text = TextSpan(text: String.fromCharCode(iconData.codePoint), style: TextStyle(fontSize: size * 0.5, fontFamily: iconData.fontFamily, package: iconData.fontPackage, color: Colors.white));
    textPainter.layout();
    textPainter.paint(canvas, ui.Offset(radius - textPainter.width / 2, radius - textPainter.height / 2));

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  @override
  void initState() {
    super.initState();
    _loadAllCustomIcons();
  }

  Future<void> _shareMapAsImage(BuildContext buttonContext) async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final file = await File('${tempDir.path}/map_share.png').create();
      await file.writeAsBytes(pngBytes);
      await Share.shareXFiles([XFile(file.path)], text: ol('track_image_share_text'));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('${ol('share_failed_snackbar')}: $e')));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      final trackName = arguments['trackName'] as String?;
      final cutMode = arguments['cutMode'] as bool? ?? false;
      if (trackName != null) {
        context.read<TrackData>().setTracksToDisplay([trackName]);
        if (cutMode) setState(() => _isCutMode = true);
      }
    }
  }

  void _showFullImageDialog(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10, right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteEditDialog(String trackName, int lineIndex, String currentNoteText, {int? pauseDuration, String? vignetteBase64}) {
    if (!mounted) return;
    final noteController = TextEditingController(text: currentNoteText);
    Uint8List? vignetteBytes;
    if (vignetteBase64 != null) {
      try { vignetteBytes = base64Decode(vignetteBase64); } catch (_) {}
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: Text(vignetteBytes != null ? ol('photo') : ol('note')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (vignetteBytes != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: SizedBox(
                    width: 250, height: 250,
                    child: GestureDetector(
                      onTap: () => _showFullImageDialog(vignetteBytes!),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(vignetteBytes!, height: 250, width: 250, fit: BoxFit.contain),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.zoom_in, color: Colors.white, size: 24),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              TextField(
                controller: noteController,
                maxLines: null, 
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: ol('note_hint'),
                  border: const UnderlineInputBorder(),
                  contentPadding: const EdgeInsets.fromLTRB(0, 10, 0, 30), 
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () async {
                    if (!dialogContext.mounted) return;
                    await context.read<TrackData>().deleteNoteAndPhotoFromTrack(trackName, lineIndex);
                    if (mounted) setState(() {});
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  },
                  child: Text(ol('delete'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                if (pauseDuration != null && pauseDuration >= 60)
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: Text(affTime(pauseDuration.toString(), true), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14)),
                  ),
                TextButton(
                  child: Text(ol('ok'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    if (!dialogContext.mounted) return;
                    final newNote = noteController.text;
                    if (newNote != currentNoteText) {
                      await context.read<TrackData>().updateNote(trackName, lineIndex, newNote);
                      if (mounted) setState(() {});
                    }
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleTakePhoto(LatLng point) async {
    if (!mounted) return;
    
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(ol('take_photo')),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(ol('from_gallery')),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.dns),
              title: const Text('Réseau local / NAS'),
              onTap: () => Navigator.pop(context, 'files'),
            ),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final trackData = context.read<TrackData>();
    Uint8List? bytes;

    if (action == 'camera' || action == 'gallery') {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: action == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 75,
      );
      if (photo != null) {
        bytes = await photo.readAsBytes();
      }
    } else if (action == 'files') {
      // Utilisation de FileType.custom pour forcer l'accès au NAS/Réseau
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'heic', 'webp'],
      );
      if (result != null && result.files.single.path != null) {
        bytes = await File(result.files.single.path!).readAsBytes();
      }
    }
    
    if (bytes != null && mounted) {
      final base64Vignette = base64Encode(bytes);
      final trackName = trackData.tracksToDisplay.first;
      
      final newIndex = await trackData.addNoteOrPhotoToTrack(trackName, point, vignette: base64Vignette);
      
      if (mounted) {
        setState(() => _isPhotoPickMode = false);
        _showNoteEditDialog(trackName, newIndex, '', vignetteBase64: base64Vignette);
        scaffoldMessenger.showSnackBar(SnackBar(content: Text(ol('photo_added'))));
      }
    }
  }

  Color _getNextColor() {
    final color = _trackColors[_colorIndex];
    _colorIndex = (_colorIndex + 1) % _trackColors.length;
    return color;
  }

  void _showMapTypeDialog(BuildContext context, TrackData trackData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MapTypeDialog(trackData: trackData);
      },
    );
  }

  Future<Map<String, dynamic>> _loadTracksData(TrackData trackData) async {
    _colorIndex = 0;
    final trackNames = trackData.tracksToDisplay;
    Set<Polyline> polylines = {};
    Set<Marker> markers = {};
    List<LatLng> allCoordinates = [];

    for (String trackName in trackNames) {
      final file = File('${trackData.trackPath}/$trackName.txt');
      if (!await file.exists()) continue;
      final lines = await file.readAsLines();
      if (lines.length < 8) continue;

      List<LatLng> trackCoords = [];
      for (int i = 7; i < lines.length; i++) {
        final parts = lines[i].split(' ');
        if (parts.length >= 4) {
          final lat = double.tryParse(parts[0]);
          final lng = double.tryParse(parts[1]);
          if (lat != null && lng != null) {
            final latLng = LatLng(lat, lng);
            trackCoords.add(latLng);

            String? note;
            String? vignette;
            int? pause;

            for (var part in parts.sublist(4)) {
              if (part.startsWith("vignette:")) {
                vignette = part.substring(9);
              } else if (part.startsWith("pause:")) {
                pause = int.tryParse(part.substring(6));
              } else {
                note = (note == null) ? Uri.decodeComponent(part) : "$note ${Uri.decodeComponent(part)}";
              }
            }

            if (note != null || vignette != null) {
              final finalNote = note ?? '';
              final finalVignette = vignette;
              final finalPause = pause;
              markers.add(Marker(
                markerId: MarkerId('note_${i}_$trackName'),
                position: latLng,
                icon: (vignette != null) ? (_photoIcon ?? BitmapDescriptor.defaultMarker) : (_noteIcon ?? BitmapDescriptor.defaultMarker),
                onTap: () => _showNoteEditDialog(trackName, i, finalNote, pauseDuration: finalPause, vignetteBase64: finalVignette),
              ));
            } else if (pause != null && pause >= 60) {
              markers.add(Marker(
                markerId: MarkerId('pause_${i}_$trackName'),
                position: latLng,
                icon: _pauseIcon ?? BitmapDescriptor.defaultMarker,
                infoWindow: InfoWindow(title: ol('stop'), snippet: affTime(pause.toString(), true)),
              ));
            }
          }
        }
      }

      if (trackCoords.isNotEmpty) {
        polylines.add(Polyline(polylineId: PolylineId(trackName), points: trackCoords, color: _getNextColor(), width: 4));
        allCoordinates.addAll(trackCoords);
        markers.add(Marker(markerId: MarkerId('start_$trackName'), position: trackCoords.first, icon: _startIcon ?? BitmapDescriptor.defaultMarker));
        markers.add(Marker(markerId: MarkerId('end_$trackName'), position: trackCoords.last, icon: _endIcon ?? BitmapDescriptor.defaultMarker));
      }
    }

    return {'polylines': polylines, 'markers': markers, 'bounds': _getTrackBounds(allCoordinates)};
  }

  @override
  Widget build(BuildContext context) {
    final trackData = context.read<TrackData>();
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadTracksData(trackData),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !_iconsLoaded) return _buildLoadingScaffold();
        final data = snapshot.data!;
        return _buildMapScaffold(trackData: trackData, polylines: data['polylines'], markers: data['markers'], bounds: data['bounds']);
      },
    );
  }

  Widget _buildMapScaffold({required TrackData trackData, required Set<Polyline> polylines, required Set<Marker> markers, required LatLngBounds bounds}) {
    final bool isSingleTrack = trackData.tracksToDisplay.length == 1;
    final center = LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown, foregroundColor: Colors.white,
        title: Text(isSingleTrack ? trackData.tracksToDisplay.first : ol('group_view_title'), style: const TextStyle(fontSize: 16)),
        actions: [
          if (isSingleTrack) IconButton(icon: Icon(_isPhotoPickMode ? Icons.close : Icons.add_a_photo), onPressed: () {
            setState(() => _isPhotoPickMode = !_isPhotoPickMode);
            if (_isPhotoPickMode) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ol('pick_point_for_photo'))));
            }
          }),
          IconButton(icon: const Icon(Icons.share), onPressed: () => _shareMapAsImage(context)),
          IconButton(icon: const Icon(Icons.layers_sharp), onPressed: () => _showMapTypeDialog(context, trackData)),
        ],
      ),
      body: RepaintBoundary(
        key: _globalKey,
        child: GoogleMap(
          onMapCreated: (c) => Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
          }),
          initialCameraPosition: CameraPosition(target: center, zoom: 12),
          mapType: trackData.mapType, markers: markers, polylines: polylines,
          onTap: (point) {
            if (_isPhotoPickMode) {
              _handleTakePhoto(point);
            } else if (_isCutMode) {
              if (!mounted) return;
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              trackData.cutTrack(trackData.tracksToDisplay.first, point).then((res) { 
                if (scaffoldMessenger.mounted) scaffoldMessenger.showSnackBar(SnackBar(content: Text(res))); 
                if (navigator.mounted) navigator.pop(); 
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoadingScaffold() => Scaffold(appBar: AppBar(backgroundColor: Colors.brown), body: const Center(child: CircularProgressIndicator()));

  LatLngBounds _getTrackBounds(List<LatLng> coords) {
    if (coords.isEmpty) return LatLngBounds(southwest: const LatLng(0,0), northeast: const LatLng(0,0));
    double minLat = coords.map((e) => e.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat = coords.map((e) => e.latitude).reduce((a, b) => a > b ? a : b);
    double minLng = coords.map((e) => e.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng = coords.map((e) => e.longitude).reduce((a, b) => a > b ? a : b);
    return LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
  }
}
