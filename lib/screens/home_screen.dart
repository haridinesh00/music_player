// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:music_player/providers/audio_provider.dart';
import 'package:provider/provider.dart';

import '../providers/library_provider.dart';
import '../providers/playlist_provider.dart';
import '../widgets/mini_player.dart';
import 'songs_screen.dart';
import 'albums_screen.dart';
import 'artists_screen.dart';
import 'playlists_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _tabs = [
    NavigationDestination(
      icon: Icon(Icons.music_note_outlined),
      selectedIcon: Icon(Icons.music_note),
      label: 'Songs',
    ),
    NavigationDestination(
      icon: Icon(Icons.album_outlined),
      selectedIcon: Icon(Icons.album),
      label: 'Albums',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Artists',
    ),
    NavigationDestination(
      icon: Icon(Icons.queue_music_outlined),
      selectedIcon: Icon(Icons.queue_music),
      label: 'Playlists',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().init();
      context.read<PlaylistProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HM Player',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _showSearch(context),
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                SongsScreen(),
                AlbumsScreen(),
                ArtistsScreen(),
                PlaylistsScreen(),
              ],
            ),
          ),
          // Mini Player
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) =>
            setState(() => _selectedIndex = idx),
        destinations: _tabs,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _MusicSearchDelegate(),
    );
  }
}

// ─── Search Delegate ─────────────────────────────────────────
// class _MusicSearchDelegate extends SearchDelegate<String> {
//   @override
//   String get searchFieldLabel => 'Search songs, artists, albums…';

//   @override
//   List<Widget> buildActions(BuildContext context) => [
//         if (query.isNotEmpty)
//           IconButton(
//             icon: const Icon(Icons.clear),
//             onPressed: () => query = '',
//           ),
//       ];

//   @override
//   Widget buildLeading(BuildContext context) =>
//       BackButton(onPressed: () => close(context, ''));

//   @override
//   Widget buildResults(BuildContext context) => _buildBody(context);

//   @override
//   Widget buildSuggestions(BuildContext context) => _buildBody(context);

//   Widget _buildBody(BuildContext context) {
//     final lib = context.read<LibraryProvider>();
//     lib.setSearch(query);

//     if (query.trim().isEmpty) {
//       return const Center(
//           child: Text('Type to search songs, artists, albums…'));
//     }

//     final results = lib.songs;
//     if (results.isEmpty) {
//       return const Center(child: Text('No results found'));
//     }

//     return ListView.builder(
//       itemCount: results.length,
//       itemBuilder: (ctx, i) {
//         final song = results[i];
//         return ListTile(
//           leading: const Icon(Icons.music_note_outlined),
//           title: Text(song.title),
//           subtitle: Text('${song.artist} • ${song.album}'),
//           onTap: () {
//             close(context, song.title);
//             context.read<LibraryProvider>().setSearch('');
//           },
//         );
//       },
//     );
//   }
// }

// ─── Search Delegate ─────────────────────────────────────────
class _MusicSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Search songs, artists, albums…';

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) =>
      BackButton(onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) => _buildBody(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildBody(context);

  Widget _buildBody(BuildContext context) {
    // 1. Read the library without updating its state!
    final lib = context.read<LibraryProvider>();

    if (query.trim().isEmpty) {
      return const Center(
          child: Text('Type to search songs, artists, albums…'));
    }

    // 2. Perform a safe, local filter instead of mutating the Provider
    final lowercaseQuery = query.toLowerCase();
    final results = lib.songs.where((song) {
      return song.title.toLowerCase().contains(lowercaseQuery) ||
             song.artist.toLowerCase().contains(lowercaseQuery) ||
             song.album.toLowerCase().contains(lowercaseQuery);
    }).toList();

    if (results.isEmpty) {
      return const Center(child: Text('No results found'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (ctx, i) {
        final song = results[i];
        return ListTile(
          leading: const Icon(Icons.music_note_outlined),
          title: Text(song.title),
          subtitle: Text('${song.artist} • ${song.album}'),
          onTap: () {
            // 3. Close the search screen FIRST
            close(context, song.title);
            
            // 4. Wait for the screen to finish closing, THEN play the song
            WidgetsBinding.instance.addPostFrameCallback((_) {
              
              // Reset the search string in the provider quietly
              context.read<LibraryProvider>().setSearch('');
              
              // 👇 ACTUALLY PLAY THE SONG 👇
              // Note: Adjust 'playAll' or 'play' based on what you named 
              // the method inside your AudioProvider!
              // 👇 Use playSong instead of playAll 👇
              context.read<AudioProvider>().playSong(song, results);
            });
          },
        );
      },
    );
  }
}