import 'package:flutter/material.dart';
import '../components/routs.dart';

class DocumentationScreen extends StatefulWidget {
  static const String id = 'documentation_screen';
  const DocumentationScreen({super.key});

  @override
  State<DocumentationScreen> createState() => _DocumentationScreenState();
}

class _DocumentationScreenState extends State<DocumentationScreen> {
  @override
  Widget build(BuildContext context) {
    const double iconSize = 18.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(ol('documentation')),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: RichText(
          text: TextSpan(
            style:
                Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16),
            children: [
              TextSpan(text: ol('doc_intro_1')),
              const WidgetSpan(
                child:
                    Icon(Icons.play_arrow, color: Colors.green, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_stop_1')),
              const WidgetSpan(
                child: Icon(Icons.stop, color: Colors.red, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_intro_2')),
              const WidgetSpan(
                child: Icon(Icons.list_alt, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_intro_3')),

              //---------------------------
              // Bottom bar explanation
              //---------------------------
              const TextSpan(text: "\n\n"),
              TextSpan(
                text: ol('doc_bottom_bar_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_bottom_bar_body')
              ),
            const WidgetSpan(
                child: Icon(Icons.explore_outlined, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_bottom_bar_compass')
              ),
                   const WidgetSpan(
                child: Icon(Icons.bar_chart, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_bottom_bar_stats')
              ),

              //---------------------------
              // The Tracks Title
              //---------------------------
              const TextSpan(text: "\n\n"),
              TextSpan(
                text: ol('doc_tracks_title'), 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_tracks_button')),
              const WidgetSpan(
                child: Icon(Icons.list_alt, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_tracks_button_2')),

              //----------------------------
              // Section for a single track
              //---------------------------
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_single_intro')),
              const WidgetSpan(
                child: Icon(Icons.remove_red_eye, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_single_view')),
             const WidgetSpan(
                child: Icon(Icons.delete, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_single_delete')),
              const WidgetSpan(
                child: Icon(Icons.more_vert, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_single_plus')),
              const WidgetSpan(
                child: Icon(Icons.merge_type, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_single_plus_merge')),
              const WidgetSpan(
                child: Icon(Icons.drive_file_rename_outline, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_single_plus_rename')),
              const WidgetSpan(
                child: Icon(Icons.inventory_2, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_single_plus_archive')),
              const WidgetSpan(
                child: Icon(Icons.sort, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_single_plus_sort')),
              const WidgetSpan(
                child: Icon(Icons.content_cut, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_single_plus_cut')),
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc-single_to_cut')),

              //------------------------------
              // Section for multiple tracks
              //--------------------------------
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_multi_intro')),
              const WidgetSpan(
                child: Icon(Icons.remove_red_eye, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_multi_delete')),
              const WidgetSpan(
                child: Icon(Icons.delete, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_multi_merge')),
              const WidgetSpan(
                child: Icon(Icons.more_vert, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_multi_plus')),
              const WidgetSpan(
                child: Icon(Icons.merge_type, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_multi_plus_merge')),
              const WidgetSpan(
                child: Icon(Icons.inventory_2, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_multi_plus_archive')),
              const WidgetSpan(
                child: Icon(Icons.sort, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_multi_plus_sort')),

              //---------------------------
              // Notes
              //---------------------------
              const TextSpan(text: "\n\n"),
              TextSpan(text: ol('doc_notes_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)
              ),
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_notes_intro')),
              const WidgetSpan(
                child: Icon(Icons.note_add, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_photos_intro')),
              const WidgetSpan(
                child: Icon(Icons.add_a_photo, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_notes_display')),
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_notes_update')),
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_photos_tile')),
              //---------------------------
              // --- Archives Section ---
              //---------------------------
              const TextSpan(text: "\n\n"),
              TextSpan(
                text: ol('doc_archives_title'),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_archives_intro')),
              const WidgetSpan(
                child: Icon(Icons.inventory_2, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              const TextSpan(text: "  "), // Small space
              TextSpan(text: ol('doc_archives_usage')),


              // --- Destinations Section ---
              const TextSpan(text: "\n\n"),
              TextSpan(
                text: ol('doc_dest_title'),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_dest_create')),
              const WidgetSpan(
                child: Icon(Icons.create, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_dest_create_body')),
              TextSpan(text: ol('doc_dest_name_pos')),
                const WidgetSpan(
                child: Icon(Icons.my_location, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_dest_manage')),
              const WidgetSpan(
                child: Icon(Icons.home_work_outlined, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_dest_change')),
              const WidgetSpan(
                child: Icon(Icons.directions_car, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_dest_gmaps')),
              const WidgetSpan(
                child: Icon(Icons.map_outlined, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_dest_export')),
              const WidgetSpan(
                child: Icon(Icons.upload, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_dest_import')),
              const WidgetSpan(
                child: Icon(Icons.download, size: iconSize),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(text: ol('doc_dest_outro')),

              //---------------------------
              // --- VAC & aérodromes ---
              //---------------------------
              const TextSpan(text: "\n\n"),
              TextSpan(
                text: ol('doc_vac_title'),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_vac_body_1')),
              TextSpan(text: ol('doc_vac_body_2')),
               const WidgetSpan(
                child: Icon(Icons.description,
                  size: iconSize,
                  color: Colors.orange,),
                alignment: PlaceholderAlignment.middle,

              ),

              TextSpan(text: ol('doc_vac_body_3')),
              TextSpan(text: ol('doc_vac_body_4')),
              TextSpan(text: ol('doc_vac_body_5')),
              TextSpan(text: ol('doc_vac_body_6')),
              const WidgetSpan(
                child: Icon(Icons.description,
                  size: iconSize,
                  color: Colors.green,),
                alignment: PlaceholderAlignment.middle,

              ),
              TextSpan(text: ol('doc_vac_body_7')),

              //---------------------------
              // --- Réglages Section (V16) ---
              //---------------------------
              const TextSpan(text: "\n\n"),
              TextSpan(
                text: ol('doc_settings_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_settings_intro')),
              const TextSpan(text: "\n• "),
              TextSpan(text: ol('doc_settings_units')),
              const TextSpan(text: "\n• "),
              TextSpan(text: ol('doc_settings_destline')),

              //---------------------------
              // --- Pack Premium Section ---
              //---------------------------
              const TextSpan(text: "\n\n"),
              TextSpan(
                text: ol('doc_premium_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_premium_intro')),
              const TextSpan(text: "\n• "),
              TextSpan(text: ol('doc_premium_oaci')),
              const TextSpan(text: "\n• "),
              TextSpan(text: ol('doc_premium_planning')),

              //---------------------------
              // --- Consumption Section ---
              //---------------------------
              const TextSpan(text: "\n\n"),
              TextSpan(
                text: ol('doc_final_title'),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_final_body_1')),
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_final_body_2')),
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_final_body_3')),
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_final_body_4')),
              const TextSpan(text: "\n"),
              TextSpan(text: ol('doc_close_app')),
              const TextSpan(text: "\n\n\n"),

            ],
          ),
        ),
      ),
    );
  }
}
