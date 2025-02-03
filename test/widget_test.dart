// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:byte_player/services/api_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  var ytMusic = ApiService.ytMusic;
  await ytMusic.initialize(hl: 'en', gl: 'US');
  print(ytMusic.hasInitialized);
  // var explode = ApiService.explode;
  var id = "46p-IxAVJ74";
  var song = await ytMusic.getSong(id);
  var songSearch = await ytMusic.searchSongs("${song.name} ${song.artist.name}");
  for (var r in songSearch) {
    if (song.name.contains(r.name) && song.artist.name.contains(r.artist.name)) {
      print("found");
      id = r.videoId;
      break;
    }
  }
  var explode = ApiService.explode;
  var link =  await explode.videos.streamsClient.getManifest(id);
  print(link.videoOnly.withHighestBitrate().url);
}