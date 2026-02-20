import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/track_data.dart';
import '../components/routs.dart';

class MapTypeDialog extends StatefulWidget {
  final TrackData trackData;

  const MapTypeDialog({super.key, required this.trackData});

  @override
  State<MapTypeDialog> createState() => _MapTypeDialogState();
}

class _MapTypeDialogState extends State<MapTypeDialog> {
  late MapType _selectedMapType;

  @override
  void initState() {
    super.initState();
    _selectedMapType = widget.trackData.currentMapType;
  }

  void _handleMapTypeChange(MapType value) {
    setState(() {
      _selectedMapType = value;
    });
    widget.trackData.setMapType(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(ol('map_type')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(ol('normal')),
              leading: Radio<MapType>(
                value: MapType.normal,
                groupValue: _selectedMapType,
                onChanged: (val) => _handleMapTypeChange(val!),
              ),
              onTap: () => _handleMapTypeChange(MapType.normal),
            ),
            ListTile(
              title: Text(ol('satellite')),
              leading: Radio<MapType>(
                value: MapType.satellite,
                groupValue: _selectedMapType,
                onChanged: (val) => _handleMapTypeChange(val!),
              ),
              onTap: () => _handleMapTypeChange(MapType.satellite),
            ),
            ListTile(
              title: Text(ol('terrain')),
              leading: Radio<MapType>(
                value: MapType.terrain,
                groupValue: _selectedMapType,
                onChanged: (val) => _handleMapTypeChange(val!),
              ),
              onTap: () => _handleMapTypeChange(MapType.terrain),
            ),
            ListTile(
              title: Text(ol('hybrid')),
              leading: Radio<MapType>(
                value: MapType.hybrid,
                groupValue: _selectedMapType,
                onChanged: (val) => _handleMapTypeChange(val!),
              ),
              onTap: () => _handleMapTypeChange(MapType.hybrid),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(ol('ok')),
        )
      ],
    );
  }
}
