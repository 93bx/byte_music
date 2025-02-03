import 'dart:convert';
import 'dart:io';
import 'package:byte_player/models/models.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as ex;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:googleapis/youtube/v3.dart' as yt;
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart' as yt_music;
import 'package:http/http.dart' as http;


class ApiService {
  static ex.YoutubeExplode explode = ex.YoutubeExplode();
  static yt_music.YTMusic ytMusic = yt_music.YTMusic();
  static final String _clientId = dotenv.env['CLIENT_ID']!;
  static final String _clientSecret = dotenv.env['CLIENT_SECRET']!;
  static const String redirectUri = 'http://localhost:9700';
  static final String credentialsFilePath = 'credentials.json';
  static final authorizeUrl = 'https://accounts.google.com/o/oauth2/v2/auth';
  static final tokenUrl = 'https://oauth2.googleapis.com/token';
  static final List<String> scopes = [yt.YouTubeApi.youtubeReadonlyScope, yt.YouTubeApi.youtubeScope, yt.YouTubeApi.youtubeForceSslScope];
  static yt.YouTubeApi? youTubeApi;

  static Future<oauth2.Client?> authenticate() async {
    ytMusic.initialize(hl: 'en');

    // Step 1: Try to restore credentials from file
    final client = await _restoreCredentials();
    if (client != null) {
      print('Credentials restored successfully.');
      youTubeApi = yt.YouTubeApi(client);
      return client;
    }
    // Step 2: Perform the full OAuth2 flow if no valid credentials exist
    print('No valid credentials found. Starting full OAuth2 flow...');
    final authUri = Uri.parse(authorizeUrl);
    final tokenUri = Uri.parse(tokenUrl);
    final grant = oauth2.AuthorizationCodeGrant(_clientId, authUri, tokenUri, secret: _clientSecret);
    final authorizationUrl = grant.getAuthorizationUrl(Uri.parse(redirectUri), scopes: scopes);
    print('Open this URL in your browser:\n$authorizationUrl');
    final server = await HttpServer.bind('127.0.0.1', 9700);
    try {
      final request = await server.first;
      final redirectUriWithCode = request.uri;
      request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.html
      ..write('Authentication Successful! you can close the browser now')
      ..close();
      final client = await grant.handleAuthorizationResponse(redirectUriWithCode.queryParameters);
      // Save credentials to a file for future use
      await _saveCredentials(client.credentials);
      youTubeApi = yt.YouTubeApi(client);
      return client;
    } catch (e, stack) {
      print('Error during authentication: $e\n$stack');
      return null;
    } finally {
      server.close();
    }
  }

  static Future<void> _saveCredentials(oauth2.Credentials credentials) async {
    final file = File(credentialsFilePath);
    await file.writeAsString((credentials.toJson()));
    print('Credentials saved to file.');
  }

  static Future<oauth2.Client?> _restoreCredentials() async {
    final file = File(credentialsFilePath);
    if (await file.exists()) {
      try {
        final credentials = oauth2.Credentials.fromJson(await file.readAsString());
        if (credentials.isExpired && credentials.canRefresh) {
          print('Refreshing expired credentials...');
          final refreshedCredentials = await credentials.refresh(
            identifier: _clientId,
            secret: _clientSecret
          );
          await _saveCredentials(refreshedCredentials);
          return oauth2.Client(refreshedCredentials, identifier: _clientId, secret: _clientSecret);
        }
        if (!credentials.isExpired) {
          return oauth2.Client(credentials, identifier: _clientId, secret: _clientSecret);
        } else {
          print('Credentials are expired and cannot be refreshed.');
        }
      } catch (e) {
        print('Error restoring credentials: $e');
      }
    } else {
      print('No credentials file found.');
    }
    return null;
  }

  static Future<String?> fetchAudioStreamUrl(String videoId) async {
    try {
      var id = await songify(videoId);
      var manifest = await explode.videos.streamsClient.getManifest(id);
      var audioStreamInfo = manifest.audioOnly.withHighestBitrate();
      return audioStreamInfo.url.toString();
    } catch (e) {
      throw ex.YoutubeExplodeException('Error during fetching the audio stream url: $e');
    }
  }

  static Future<String?> fetchVideoStreamUrl(String videoId) async {
    try {
      var manifest = await explode.videos.streamsClient.getManifest(videoId);
      var videoStreamInfo = manifest.videoOnly.withHighestBitrate();
      return videoStreamInfo.url.toString();
    } catch (e) {
      throw ex.YoutubeExplodeException('Error during fetching the audio stream url: $e');
    }
  }

  static Future<List<Playlist>?> fetchPlaylists() async {
    try {
      final response = await youTubeApi!.playlists.list(
        ['contentDetails', 'snippet'],
        mine: true,
        maxResults: 50
      );
      List<Playlist> playlists = response.items!.map((playlist) => Playlist(
        id: playlist.id!,
        title: playlist.snippet!.title!,
        songs: [],
        thumbnail: Thumbnail(url: playlist.snippet!.thumbnails!.medium!.url!)
      )).toList();
      return playlists;
    } catch (e) {
      print("Error fetching Playlists: $e");
      return null;
    }
  }

  static Future<List<Song>?> fetchPlaylistItems(String playlistId) async {
    try {
      var itemsResponse = await explode.playlists.getVideos(playlistId).toList();
      List<Song> songs = itemsResponse.map((item) => Song(
        id: item.id.value,
        title: item.title,
        artistName: item.author,
        artistId: item.channelId.value,
        thumbnail: Thumbnail(url: item.thumbnails.highResUrl)
      )).toList();
      return songs;
    } catch (e) {
      print('Error fetching playlist: $e');
      return null;
    }
  }

  static Future<List<Song>?> fetchLikedMusic() async {
    List<yt.Video> responseList = [];
    String? nextPageToken;
    try {
      while (true) {
        final response = await youTubeApi!.videos.list(
          ['contentDetails', 'snippet', 'topicDetails'],
          myRating: 'like',
          maxResults: 50,
          pageToken: nextPageToken??'',
        );
        responseList.addAll(response.items!);
        nextPageToken = response.nextPageToken;
        if (nextPageToken == '' || nextPageToken == null) break;
      }
    } catch (e) {
      print('Error fetching liked songs: $e');
      return null;
    }
    List<Song> likedSongs = responseList.map((i) => Song(
        id: i.id!,
        title: i.snippet!.title!,
        artistName: i.snippet!.channelTitle!,
        artistId: i.snippet!.channelId!,
        thumbnail: Thumbnail(url: i.snippet!.thumbnails!.high!.url!)
    )).toList();
    return likedSongs;
  }

  static Future<List<Song>?> fetchTrending() async {
    try {
      final response = await youTubeApi!.videos.list(
        ['snippet'],
        maxResults: 50,
        chart: 'mostPopular',
        videoCategoryId: '10',
      );
      List<Song> trending = response.items!.map((i)=>Song(
          id: i.id!,
          title: i.snippet!.title!,
          artistName: i.snippet!.channelTitle!,
          artistId: i.snippet!.channelId!,
          thumbnail: Thumbnail(url: i.snippet!.thumbnails!.high!.url!)
      )).toList();
      return trending;
    } catch (e) {
      print('error fetching trending songs: $e');
      return null;
    }
  }

  static Future<Song?> fetchSong(String videoId) async {
    if (!(ytMusic.hasInitialized)) ytMusic.initialize();
    try {
      var songId = await songify(videoId);
      var response = await ytMusic.getSong(songId);
      var albumResponse = await fetchSongAlbum(response.name, response.artist.artistId!);
      return Song(
        id: response.videoId,
        title: response.name,
        albumId: albumResponse!.id,
        albumName: albumResponse.title,
        artistName: response.artist.name,
        artistId: response.artist.artistId!,
        thumbnail: Thumbnail(url: response.thumbnails.last.url),
      );
    } catch (e) {
      print("Error Fetching Song: $e");
      return null;
    }
  }

  static Future<Album?> fetchSongAlbum(String songName, String artistId) async {
    try {
      var response = await ytMusic.getArtistAlbums(artistId);
      for (var album in response) {
        var albumResponse = await ytMusic.getAlbum(album.albumId);
        for (var song in albumResponse.songs) {
          if (song.name.toLowerCase().contains(songName.toLowerCase())) {
            return Album(
              id: albumResponse.albumId,
              title: albumResponse.name,
              artistId: albumResponse.artist.artistId!,
              artistName: albumResponse.artist.name,
              thumbnail: Thumbnail(url: albumResponse.thumbnails.last.url),
              songs: albumResponse.songs.map((s) => Song(
                id: s.videoId,
                title: s.name,
                artistName: s.artist.name,
                artistId: s.artist.artistId!,
                albumName: s.album!.name,
                albumId: s.album!.albumId
              )).toList()
            );
          }
        }
      }
    } catch (e) {
      print('Error Fetching Album for Song $songName: $e');
      return null;
    }
    return null;
  }

  static Future<Artist?> fetchArtist(String artistId) async {
    try {
      var response = await ytMusic.getArtist(artistId);
      return Artist(
        id: response.artistId,
        name: response.name,
        thumbnail: Thumbnail(url: response.thumbnails.last.url)
      );
    } catch (e) {
      print("Error fetching artist: $e");
      return null;
    }
  }
  
  static Future<List<Song>?> fetchRelatedSongs(String videoId) async {
    try {
      var video = await explode.videos.get(videoId);
      var response = await explode.videos.getRelatedVideos(video);
      return response?.map((s) => Song(
        id: s.id.value,
        title: s.title,
        artistName: s.author,
        artistId: s.channelId.value,
        thumbnail: Thumbnail(url: s.thumbnails.highResUrl),
      )).toList();
    } catch (e) {
      print('error fetching related songs: $e');
      return null;
    }
  }

  static Future<Lyrics?> fetchLyrics(String videoId) async {
    var song = await ytMusic.getSong(videoId);
    var songQuery = song.name.trim().toLowerCase().replaceAll(' ', '+');
    var artistQuery = song.artist.name.trim().toLowerCase().replaceAll(' ', '+');
    print('searching using song and artist');
    var uri = Uri.parse("https://lrclib.net/api/get?artist_name=$artistQuery&track_name=$songQuery");
    var response = await http.get(uri);
    if (response.statusCode == 200){
      var decoded = jsonDecode(response.body);
      return Lyrics.fromJson(decoded);
    } else {
      print(response.body);
    }
    print('searching using song name only');
    print(songQuery);
    uri = Uri.parse("https://lrclib.net/api/search?q=$songQuery");
    response = await http.get(uri);
    if (response.statusCode == 200) {
      var results = jsonDecode(response.body);
      for (var r in results) {
        print(r);
        if (songQuery.toLowerCase().contains(r['trackName'].trim().toLowerCase())
            || artistQuery.toLowerCase().contains(r['artistName'].trim().toLowerCase())
            || songQuery.toLowerCase().contains(r['artistName'].trim().toLowerCase())
        ) {
          return Lyrics.fromJson(r);
        }
      }
    } else {
      print(response.body);
    }
    return null;
  }

  static Future<String> songify(String videoId) async {
    try {
      var response = await ytMusic.getSong(videoId);
      var songSearch = await ytMusic.searchSongs("${response.name} ${response.artist.name}");
      var id = videoId;
      for (var result in songSearch) {
        if (response.name.contains(result.name) && response.artist.name.contains(result.artist.name)) {
          id = result.videoId;
          break;
        }
      }
      return id;
    } catch (e) {
      print("error songifing the video: $e");
      return videoId;
    }
  }
}


