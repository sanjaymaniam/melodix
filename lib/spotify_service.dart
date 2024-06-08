import 'dart:convert';
import 'package:http/http.dart' as http;

class SpotifyService {
  SpotifyService(this.token);
  final String baseUrl = 'https://api.spotify.com/v1';
  final String token;

  Future<List<Playlist>> getPlaylists() async {
    final response = await http.get(
      Uri.parse('$baseUrl/me/playlists'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

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
}

class Playlist {
  Playlist({required this.id, required this.name, required this.imageUrl});

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: (json['images'] as List).isNotEmpty
          // ignore: avoid_dynamic_calls
          ? (json['images'][0]['url'] as String)
          : '',
    );
  }
  final String id;
  final String name;
  final String imageUrl;
}
