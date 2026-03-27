import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../components/routs.dart';
import '../components/track_view.dart';
import '../models/premium_state.dart';
import '../models/sort_state.dart';
import '../models/track.dart';
import '../models/track_data.dart';
import 'map_track_screen.dart';

class TracksScreen extends StatefulWidget {
  static const String id = 'tracks_screen';
  final bool isSelectionMode;

  const TracksScreen({super.key, this.isSelectionMode = false});

  @override
  createState() => _TracksScreenState();
}

class _TracksScreenState extends State<TracksScreen> {
  bool _showArchives = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TrackData>().listTracks();
        context.read<TrackData>().listArchivedTracks();
      }
    });
  }

  Future<bool> _checkPremiumArchives() async {
    if (!mounted) return false;
    final premiumState = context.read<PremiumState>();
    
    // FORCER le rechargement de l'état depuis les préférences pour être sûr
    await premiumState.initializationDone;
    
    // On vérifie à nouveau après l'initialisation
    if (premiumState.isPremium || premiumState.isPremiumArchives) {
      return true;
    }

    if (!context.mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Consumer<PremiumState>(
        builder: (context, state, child) {
          if (state.isPremium || state.isPremiumArchives) {
            return AlertDialog(
              title: Text(ol('access_activated')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(ol('archive_allowed')),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(ol('continue')),
                ),
              ],
            );
          }

          return AlertDialog(
            title: Text(ol('premium_title')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                Text(ol('premium_desc')),
                const SizedBox(height: 8),
                Text(
                  ol('archive_benefit'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(ol('cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () => state.buyPremiumArchives(),
                child: Text("${ol('premium_buy_label')} ${state.formattedPriceArchives}", style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final trackData = context.watch<TrackData>();
    final selectedTracks = trackData.tracks.where((t) => t.isDone).toList();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      extendBody: true, 
      extendBodyBehindAppBar: false, 
      appBar: AppBar(
        backgroundColor: Colors.brown,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, 
          statusBarIconBrightness: Brightness.light, 
          systemNavigationBarColor: Colors.transparent, 
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
            widget.isSelectionMode
                ? ol('select_track_to_simulate')
                : (_showArchives ? ol('archives') : ol('traces_list_banner')),
            style: const TextStyle(color: Colors.white)),
        actions: widget.isSelectionMode
            ? []
            : _showArchives
                ? [
                    IconButton(
                      icon: const Icon(Icons.list, color: Colors.white),
                      tooltip: ol('tracks_title'),
                      onPressed: () {
                        setState(() {
                          _showArchives = false;
                          trackData.listTracks();
                        });
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (String result) async {
                        if (!mounted) return;
                        final messenger = ScaffoldMessenger.of(context);
                        final trackDataProvider = context.read<TrackData>();

                        switch (result) {
                          case 'export':
                            final String? fileName = await _displayTextInputDialog(title: ol('export_archives'), initialValue: 'archives');
                            if (!context.mounted || fileName == null || fileName.isEmpty) return;
                            try {
                              final path = await trackDataProvider.exportArchivesToTempFile(fileName: fileName);
                              if (!context.mounted) return;
                              final file = File(path);
                              final sizeInBytes = await file.length();
                              final sizeInMb = sizeInBytes / (1024 * 1024);
                              if (sizeInMb > 20) {
                                  if (!context.mounted) return;
                                  final bool? proceed = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: Text(ol('warning')),
                                    content: Text(ol('export_size_warning').replaceAll('%s', sizeInMb.toStringAsFixed(1))),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(ol('cancel'))),
                                      TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(ol('confirm'))),
                                    ],
                                  ),
                                );
                                if (!context.mounted || proceed != true) return;
                              }
                              await Share.shareXFiles([XFile(path)], text: ol('archives_backup_text'));
                            } catch (e) {
                              if (!context.mounted) return;
                              messenger.showSnackBar(SnackBar(content: Text("${ol('error_exporting_archives')}: $e")));
                            }
                            break;
                          case 'import':
                            final importResult = await trackDataProvider.importArchives();
                            if (!context.mounted) return;
                            messenger.showSnackBar(SnackBar(content: Text(importResult)));
                            break;
                          case 'import_shared':
                            final importResult = await trackDataProvider.importSharedTracks();
                            if (!context.mounted) return;
                            messenger.showSnackBar(SnackBar(content: Text(importResult)));
                            break;
                          case 'unarchive':
                            final listSelected = trackDataProvider.archivedTracks.where((t) => t.isDone).toList();
                            if (listSelected.isEmpty) return;
                            await trackDataProvider.unarchiveTracks(listSelected);
                            if (!context.mounted) return;
                            messenger.showSnackBar(SnackBar(content: Text(ol('tracks_unarchived_snackbar'))));
                            setState(() {
                              _showArchives = false;
                            });
                            break;
                          case 'delete':
                            final listSelected = trackDataProvider.archivedTracks.where((t) => t.isDone).toList();
                            if (listSelected.isEmpty) return;
                            final bool? shouldDelete = await _dialogDelete(listSelected);
                            if (!context.mounted || shouldDelete != true) return;
                            await trackDataProvider.deleteArchivedTracks(listSelected.map((t) => t.name).toList());
                            if (!context.mounted) return;
                            messenger.showSnackBar(SnackBar(content: Text(ol('archives_deleted_snackbar'))));
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'import_shared',
                          child: Row(
                            children: [
                              const Icon(Icons.group_add, color: Colors.brown),
                              const SizedBox(width: 8),
                              Text(ol('import_shared_tracks')),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'export',
                          child: Row(
                            children: [
                              const Icon(Icons.archive_outlined, color: Colors.brown),
                              const SizedBox(width: 8),
                              Text(ol('export_archives')),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'import',
                          child: Row(
                            children: [
                              const Icon(Icons.unarchive_outlined, color: Colors.brown),
                              const SizedBox(width: 8),
                              Text(ol('import_archives')),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'unarchive',
                          child: Row(
                            children: [
                              const Icon(Icons.unarchive, color: Colors.brown),
                              const SizedBox(width: 8),
                              Text(ol('unarchive')),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, color: Colors.brown),
                              const SizedBox(width: 8),
                              Text(ol('delete')),
                            ],
                          ),
                        ),
                      ],
                    )
                  ]
                : [
                    if (selectedTracks.isNotEmpty) ...[
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye, color: Colors.white),
                        tooltip: ol('view_button'),
                        onPressed: () {
                          if (!mounted) return;
                          final trackDataProvider = context.read<TrackData>();
                          final selectedTrackNames = trackDataProvider.getSelectedTracksNames;
                          if (selectedTrackNames.isNotEmpty) {
                            trackDataProvider.setTracksToDisplay(selectedTrackNames);
                            Navigator.of(context).pushNamed(MapTrack.id);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        tooltip: ol('delete_button'),
                        onPressed: () async {
                          if (selectedTracks.isEmpty) return;
                          final messenger = ScaffoldMessenger.of(context);
                          final trackDataRef = context.read<TrackData>();
                          final bool? shouldDelete = await _dialogDelete(selectedTracks);
                          if (!context.mounted || shouldDelete != true) return;
                          await trackDataRef.deleteTracks(selectedTracks.map((t) => t.name).toList());
                          if (!context.mounted) return;
                          messenger.showSnackBar(SnackBar(content: Text(ol('tracks_deleted_snackbar'))));
                        },
                      ),
                    ],
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.share, color: Colors.white),
                      tooltip: ol('share_button'),
                      onSelected: (String result) async {
                        if (result == 'send') {
                          _shareTracks();
                        } else if (result == 'receive') {
                          if (!mounted) return;
                          final trackDataRef = context.read<TrackData>();
                          final messenger = ScaffoldMessenger.of(context);
                          final res = await trackDataRef.importSharedTracks();
                          if (!context.mounted) return;
                          messenger.showSnackBar(SnackBar(content: Text(res)));
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'send',
                          child: Row(
                            children: [
                              const Icon(Icons.upload, color: Colors.brown),
                              const SizedBox(width: 8),
                              Text(ol('send_field')),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'receive',
                          child: Row(
                            children: [
                              const Icon(Icons.download, color: Colors.brown),
                              const SizedBox(width: 8),
                              Text(ol('receive_field')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.inventory_2, color: Colors.white),
                      tooltip: ol('archives_button'),
                      onPressed: () {
                        setState(() {
                          _showArchives = true;
                          trackData.listArchivedTracks();
                        });
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      tooltip: ol('more_button'),
                      onSelected: (String result) async {
                        if (!mounted) return;
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        final trackDataRef = context.read<TrackData>();

                        switch (result) {
                          case 'merge':
                            if (selectedTracks.length < 2) {
                              messenger.showSnackBar(SnackBar(content: Text(ol('merge_min_selection'))));
                              return;
                            }
                            final String? newName = await _displayTextInputDialog(title: ol('merge_button'));
                            if (!context.mounted || newName == null || newName.isEmpty) return;

                            final bool? deleteSource = await _confirmDeleteSourceDialog();
                            if (!context.mounted || deleteSource == null) return;

                            try {
                              await trackDataRef.mergeTracks(selectedTracks, newName, deleteSource: deleteSource);
                              if (!context.mounted) return;
                              messenger.showSnackBar(SnackBar(content: Text('${ol('merge_success_snackbar')} "$newName".')));
                            } catch (e) {
                              if (!context.mounted) return;
                              messenger.showSnackBar(SnackBar(content: Text('${ol('merge_failed_snackbar')}: $e')));
                            }
                            break;
                          case 'rename':
                            if (selectedTracks.length != 1) return;
                            final track = selectedTracks.first;
                            final int index = trackDataRef.tracks.indexOf(track);
                            final String? newName = await _displayTextInputDialog(initialValue: track.name);
                            if (!context.mounted || newName == null || newName.isEmpty) return;

                            await trackDataRef.changeName(newName, index);
                            if (!context.mounted) return;
                            messenger.showSnackBar(SnackBar(content: Text('${ol('track_renamed_snackbar')} "$newName".')));
                            break;
                          case 'archive':
                            final hasArchiveAccess = await _checkPremiumArchives();
                            if (!context.mounted || !hasArchiveAccess || selectedTracks.isEmpty) return;

                            await trackDataRef.archiveTracks(selectedTracks);
                            if (!context.mounted) return;
                            messenger.showSnackBar(SnackBar(content: Text(ol('tracks_archived_snackbar'))));
                            break;
                          case 'sort':
                            _showSortOptions();
                            break;
                          case 'cut':
                            if (selectedTracks.length != 1) return;
                            final trackName = selectedTracks.first.name;
                            if (!context.mounted) return;
                            navigator.pushNamed(MapTrack.id, arguments: {'trackName': trackName, 'cutMode': true});
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        if (selectedTracks.length > 1)
                          PopupMenuItem<String>(
                            value: 'merge',
                            child: Row(
                              children: [
                                const Icon(Icons.merge_type, color: Colors.brown),
                                const SizedBox(width: 8),
                                Text(ol('merge_button')),
                              ],
                            ),
                          ),
                        if (selectedTracks.length == 1) ...[
                          PopupMenuItem<String>(
                            value: 'rename',
                            child: Row(
                              children: [
                                const Icon(Icons.drive_file_rename_outline, color: Colors.brown),
                                const SizedBox(width: 8),
                                Text(ol('rename_button')),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'cut',
                            child: Row(
                              children: [
                                const Icon(Icons.content_cut, color: Colors.brown),
                                const SizedBox(width: 8),
                                Text(ol('cut_button')),
                              ],
                            ),
                          ),
                        ],
                        if (selectedTracks.isNotEmpty)
                          PopupMenuItem<String>(
                            value: 'archive',
                            child: Row(
                              children: [
                                const Icon(Icons.inventory_2, color: Colors.brown),
                                const SizedBox(width: 8),
                                Text(ol('archive_button')),
                              ],
                            ),
                          ),
                        PopupMenuItem<String>(
                          value: 'sort',
                          child: Row(
                            children: [
                              const Icon(Icons.sort, color: Colors.brown),
                              const SizedBox(width: 8),
                              Text(ol('sort_button')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
      ),
      body: TrackView(
        isSelectionMode: widget.isSelectionMode,
        isArchiveView: _showArchives,
      ),
    );
  }

  Future<void> _shareTracks() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final trackDataProvider = context.read<TrackData>();
    final selectedTracks = trackDataProvider.tracks.where((t) => t.isDone).toList();
    if (selectedTracks.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(ol('no_track_selected'))));
      return;
    }

    String initialName = ol('shared_tracks_filename');
    if (selectedTracks.length == 1) {
      initialName = selectedTracks.first.name;
    }

    final String? fileName = await _displayTextInputDialog(title: ol('share_tracks'), initialValue: initialName);
    if (!context.mounted || fileName == null || fileName.isEmpty) return;

    try {
      final result = await trackDataProvider.exportTracksToTempFile(selectedTracks, fileName);
      if (!context.mounted) return;
      
      final file = File(result);
      final sizeInMb = await file.length() / (1024 * 1024);
      if (sizeInMb > 20) {
        if (!context.mounted) return;
        final bool? proceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(ol('warning')),
            content: Text(ol('export_size_warning').replaceAll('%s', sizeInMb.toStringAsFixed(1))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(ol('cancel'))),
              TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(ol('confirm'))),
            ],
          ),
        );
        if (!context.mounted || proceed != true) return;
      }

      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(result)],
        text: ol('share_tracks_text'),
        subject: ol('share_tracks'),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(ol('error_sharing_tracks'))));
    }
  }

  void _showSortOptions() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Consumer<TrackData>(
          builder: (context, trackData, child) {
            return Wrap(
              children: <Widget>[
                for (var criterion in SortCriterion.values)
                  ListTile(
                    leading: Icon(trackData.sortState.criterion == criterion
                        ? (trackData.sortState.direction == SortDirection.ascending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward)
                        : null),
                    title: Text(ol('sort_${criterion.name}')),
                    onTap: () {
                      trackData.setSort(criterion);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _displayTextInputDialog({String title = '', String initialValue = ''}) async {
    if (!context.mounted) return null;
    final textController = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title.isEmpty ? ol('rename_prompt_title') : title),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(hintText: ol('rename_prompt_hint')),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(ol('cancel')),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text(ol('ok')),
              onPressed: () => Navigator.pop(context, textController.text),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _dialogDelete(List<Track> tracks) async {
    if (!context.mounted) return null;
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              '${ol('delete_prompt_title')} (${tracks.length} ${ol('selected_tracks')})'),
          content: Text(ol('delete_prompt_body')),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(ol('cancel'))),
            TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(ol('delete'))),
          ],
        );
      },
    );
  }

  Future<bool?> _confirmDeleteSourceDialog() async {
    if (!context.mounted) return null;
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(ol('merge_delete_sources')),
          actions: <Widget>[
            TextButton(
              child: Text(ol('no')),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(ol('yes')),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }
}
