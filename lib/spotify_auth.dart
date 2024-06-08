import 'package:flutter/material.dart';
import 'package:melodix/playlist_screen.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

final authorizationEndpoint =
    Uri.parse('https://accounts.spotify.com/authorize');
final tokenEndpoint = Uri.parse('https://accounts.spotify.com/api/token');
final redirectUrl = Uri.parse('http://localhost:8080');
final clientId = 'f795b603c81b482bb4c2ac19642fa31b';
final clientSecret =
    'b0328d1846914e7ca5f322e8d0772764'; // Replace with actual client secret

final credentialsFile = File('credentials.json');

class SpotifyAuth extends StatefulWidget {
  const SpotifyAuth({super.key});

  @override
  _SpotifyAuthState createState() => _SpotifyAuthState();
}

class _SpotifyAuthState extends State<SpotifyAuth> {
  oauth2.Client? client;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    if (await credentialsFile.exists()) {
      final credentials =
          oauth2.Credentials.fromJson(await credentialsFile.readAsString());
      setState(() {
        client = oauth2.Client(credentials,
            identifier: clientId, secret: clientSecret);
      });
    }
  }

  Future<void> _authenticate() async {
    final grant = oauth2.AuthorizationCodeGrant(
      clientId,
      authorizationEndpoint,
      tokenEndpoint,
      secret: clientSecret,
    );

    final authorizationUrl = grant.getAuthorizationUrl(redirectUrl, scopes: [
      'user-read-private',
      'user-read-email',
      'playlist-read-private',
      'playlist-modify-public',
      'playlist-modify-private',
    ]);

    if (await canLaunch(authorizationUrl.toString())) {
      await launch(authorizationUrl.toString());
    }

    final responseUrl = await _listenForCode();

    final client =
        await grant.handleAuthorizationResponse(responseUrl.queryParameters);

    await credentialsFile.writeAsString(client.credentials.toJson());

    setState(() {
      this.client = client;
    });
  }

  Future<Uri> _listenForCode() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
    final request = await server.first;
    final response = request.response;
    response.statusCode = 200;
    response.headers.set('Content-Type', ContentType.html.mimeType);
    response.write('<html><h1>Authentication successful!</h1>'
        'You can close this window.</html>');
    await response.close();
    await server.close();
    return request.uri;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotify Auth'),
      ),
      body: Center(
        child: client == null
            ? ElevatedButton(
                onPressed: _authenticate,
                child: const Text('Connect to Spotify'),
              )
            : ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PlaylistScreen(client: client!)),
                  );
                },
                child: const Text('View Playlists'),
              ),
      ),
    );
  }
}
