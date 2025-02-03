import 'dart:math';

import 'package:byte_player/models/models.dart';
import 'package:byte_player/services/api_service.dart';
import 'package:byte_player/widgets/carousel.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  static List<Playlist> playlists = [];
  static List<Song> trending = [];
  static List<Song> quickPicks = [];
  static bool playlistLoading = false;
  static bool trendingLoading = false;
  static bool quickPicksLoading = true;
  final Function(Song, List<Song>) onSongSelected;
  const HomeScreen({super.key, required this.onSongSelected});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  void getPlaylists() async {
    setState(() {
      HomeScreen.playlistLoading = true;
    });
    var playlists = await ApiService.fetchPlaylists();
    HomeScreen.playlists = playlists!;
    setState(() {
      HomeScreen.playlistLoading = false;
    });
    for (var i = 0; i < playlists.length; i++) {
      List<Song>? songs = await ApiService.fetchPlaylistItems(playlists[i].id);
      HomeScreen.playlists[i].songs.addAll(songs!);
    }
   populateQP();
  }

  void getTrending() async {
    setState(() => HomeScreen.trendingLoading = true);
    List<Song>? trendingSongs = await ApiService.fetchTrending();
    if (trendingSongs != null) {
      HomeScreen.trending.addAll(trendingSongs);
    }
    setState(() => HomeScreen.trendingLoading = false);
  }

  void populateQP() async {
    while (true) {
      int playlistRand = Random().nextInt(HomeScreen.playlists.length);
      int songRand = Random().nextInt(HomeScreen.playlists[playlistRand].length);
      Song song = HomeScreen.playlists[playlistRand].songs[songRand];
      if (HomeScreen.quickPicks.contains(song)) continue;
      HomeScreen.quickPicks.add(HomeScreen.playlists[playlistRand].songs[songRand]);
      if (HomeScreen.quickPicks.length >= 27) {
        break;
      }
    }
    setState(() => HomeScreen.quickPicksLoading = false);
  }

  @override
  void initState() {
    getPlaylists();
    getTrending();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Color(0xFF171717),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(10),
              children: [
                // Search bar
                SearchBar(
                  hintText: "Search songs",
                ),

                // Quick Pick Section
                Text("Quick Picks", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                HomeScreen.quickPicksLoading ?
                Center(child: CircularProgressIndicator()) :
                Carousel(
                  height: 270,
                  viewport: 1,
                  showIndicator: true,
                  items: List.generate(3, (i) {
                    return GridView.count(
                      crossAxisCount: 3,
                      childAspectRatio: 1.4,
                      physics: NeverScrollableScrollPhysics(),
                      children: List.generate(9, (x) {
                        Song song = HomeScreen.quickPicks[(i * 9 + x)];
                        return Container(
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          margin: EdgeInsets.all(5),
                          decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(10))),
                          child: InkWell(
                            onTap: () {
                              final upcoming = HomeScreen.quickPicks;
                              upcoming.remove(song);
                              upcoming.insert(0, song);
                              widget.onSongSelected(song, upcoming);
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  song.thumbnail!.url,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.transparent, Colors.black]
                                    )
                                  ),
                                  width: double.maxFinite,
                                  height: 40,
                                  alignment: Alignment.bottomCenter,
                                  child: Text(
                                    song.title.trim(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight:FontWeight.w500, fontSize: 12),
                                    maxLines: 2,
                                  )
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ),

                // Trending Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text("Trending", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ),
                HomeScreen.trendingLoading ?
                Center(child: CircularProgressIndicator()) :
                Carousel(
                  height: 170,
                  viewport: 0.85,
                  items: List.generate(4, (i) {
                    return Column(
                      spacing: 10,
                      children: List.generate(3, (y) {
                        int index = i * 3 + y;
                        Song song = HomeScreen.trending[index];
                        return InkWell(
                          onTap: () {
                            final upcoming = HomeScreen.trending;
                            upcoming.remove(song);
                            upcoming.insert(0, song);
                            widget.onSongSelected(song, upcoming);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            spacing: 10,
                            children: [
                              Container(
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                child: Image.network(song.thumbnail!.url, fit: BoxFit.cover, width: 88, height: 50,)
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(titlize(song.title, song.artistName)),
                                  Text(song.artistName, style: TextStyle(color: Colors.grey, fontSize: 13),)
                                ],
                              )
                            ],
                          ),
                        );
                      }),
                    );
                  }),
                ),


                // Playlists
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text("Playlists", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20))
                ),
                HomeScreen.playlistLoading ?
                Center(child: CircularProgressIndicator()) :
                Carousel(
                  height: 155,
                  viewport: 0.4,
                  items: List.generate(HomeScreen.playlists.length + 1, (i) {
                    if (i==0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                              margin: EdgeInsets.only(right: 20),
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              child: Image.asset('assets/images/liked_playlist.png', fit: BoxFit.cover, height: 120,)
                          ),
                          Text('Liked Music')
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
                          margin: EdgeInsets.only(right: 20),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: Image.network(HomeScreen.playlists[i-1].thumbnail!.url, fit: BoxFit.cover, height: 120,)
                        ),
                        Text(HomeScreen.playlists[i-1].title)
                      ],
                    );
                  }),
                ),
                SizedBox(height: 60,)
              ],
            ),
          ),
        ],
      ),
    );
  }

  String titlize(String title, String artistName) {
    List<String> result = title.toLowerCase().replaceAll('-', '').replaceAll("official", "")
        .replaceAll(")", "").replaceAll("(", "").replaceAll("video", "")
        .replaceAll("&", "").replaceAll("  ", " ").replaceAll(artistName.toLowerCase(), "")
        .replaceAll("music", "").replaceAll('[', '').replaceAll(']', '')
        .trim().split('');
    if (result.length >= 33) {
      result = result.sublist(0, 32);
      if (result.last == ' ') {
        result.removeAt(result.length-1);
      }
    }
    for (var i=0; i<result.length; i++) {
      if (i==0) {
        result[i] = result[i].toUpperCase();
      }
      if (result[i] == " ") {
        result[i+1] = result[i+1].toUpperCase();
      }
    }
    return result.join();
  }
}
