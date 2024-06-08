import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:oauth2/oauth2.dart' as oauth2;

class PlaylistScreen extends StatelessWidget {
  final oauth2.Client client;

  const PlaylistScreen({super.key, required this.client});

  Future<List<Playlist>> _fetchPlaylists() async {
    final response =
        await client.get(Uri.parse('https://api.spotify.com/v1/me/playlists'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final playlists = data['items'] as List;
      return playlists
          .map(
              (playlist) => Playlist.fromJson(playlist as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load playlists');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Playlists'),
      ),
      body: FutureBuilder(
        future: _fetchPlaylists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final playlists = snapshot.data as List<Playlist>;
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 2,
              ),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return Card(
                  child: Column(
                    children: [
                      playlist.imageUrl.isNotEmpty
                          ? Image.network(playlist.imageUrl, fit: BoxFit.cover)
                          : Container(height: 100, color: Colors.grey),
                      Text(playlist.name,
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class Playlist {
  final String id;
  final String name;
  final String imageUrl;

  Playlist({required this.id, required this.name, required this.imageUrl});

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: (json['images'] as List).isNotEmpty
          ? (json['images'][0]['url'] as String)
          : '',
    );
  }
}
