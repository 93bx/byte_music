import 'package:byte_player/screens/home_screen.dart';
import 'package:byte_player/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';

class PlayerProvider with ChangeNotifier {
  late Player _player;
  late VideoController _videoController;
  String? _currentVideoId;
  String _songTitle = '';
  String _artist = '';
  String _thumbnailUrl = 'assets/images/player_placeholder.png';
  List<Song> _upcomingSongs = [];
  bool _isPlaying = false;
  bool _isVideoMode = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  List<LyricLine> _lyrics = [];
  int _currentLyricIndex = 0;
  final ScrollController _lyricsScrollController = ScrollController();

  String get songTitle => _songTitle;
  String get artist => _artist;
  String get thumbnailUrl => _thumbnailUrl;
  bool get isPlaying => _isPlaying;
  bool get isVideoMode => _isVideoMode;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  Player? get player => _player;
  VideoController? get videoController => _videoController;
  List<Song> get upcomingSongs => _upcomingSongs;
  List<LyricLine> get lyrics => _lyrics;
  int get currentLyricIndex => _currentLyricIndex;
  ScrollController get lyricsScrollController => _lyricsScrollController;


  PlayerProvider() {
    _player = Player();
    _videoController = VideoController(_player, configuration: VideoControllerConfiguration(
      height: 400
    ));
    _player.stream.position.listen((position) {
      _currentPosition = position;
      _updateCurrentLyric(position.inSeconds);
      notifyListeners();
    });

    _player.stream.duration.listen((duration) {
      _totalDuration = duration;
      notifyListeners();
    });

    _player.stream.playing.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

  }

  Future<void> playSong({
    required String videoId,
    required String title,
    required String artist,
    required String thumbnailUrl,
    bool isVideo = false
  }) async {
    _player.stop();
    try {
      String? audioStreamUrl = await ApiService.fetchAudioStreamUrl(videoId);
      String? videoStreamUrl = await ApiService.fetchVideoStreamUrl(videoId);

      if (audioStreamUrl != null && !isVideo) {
        _player.open(Media(audioStreamUrl), play: true);
      } else if (videoStreamUrl != null && isVideo && audioStreamUrl != null) {
        _player.open(Media(videoStreamUrl), play: false);
        _player.setAudioTrack(AudioTrack.uri(audioStreamUrl));
        _player.play();
      } else {
        print('Stream url is null');
        return;
      }
      _isPlaying = true;
      _currentVideoId = videoId;
      _songTitle = title;
      _artist = artist;
      _thumbnailUrl = thumbnailUrl;
      _isVideoMode = isVideo;
      _lyrics.clear();
      _currentLyricIndex = 0;
      await fetchLyrics(videoId);
      notifyListeners();
    } catch (e) {
      print('Error playing song: $e');
    }
  }

  void seekTo(Duration position) {
    _player.seek(position);
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      _player.pause();
      _isPlaying = false;
    } else if (!_isPlaying) {
      _player.play();
      _isPlaying = true;
    }
    notifyListeners();
  }

  void setPlaylist(List<Song> playlist) {
    _upcomingSongs = playlist;
    notifyListeners();
  }

  void addToPlaylist(Song song) {
    _upcomingSongs.add(song);
    notifyListeners();
  }

  void removeFromPlaylist(int index) {
    _upcomingSongs.removeAt(index);
    notifyListeners();
  }

  Future<void> fetchLyrics(String videoId) async {
    final lyrics = await ApiService.fetchLyrics(videoId);

    if (lyrics == null || (lyrics.syncedLyrics == null && lyrics.plainLyrics == null)) {
      print("No lyrics found.");
      _lyrics = [];
      _currentLyricIndex = 0;
      notifyListeners();
      return;
    }
    if (lyrics.syncedLyrics == null) {
      print("No synced lyrics found. Using plain lyrics.");
      _lyrics = _parsePlainLyrics(lyrics.plainLyrics!);
      notifyListeners();
      return;
    }
    _lyrics = _parseSyncedLyrics(lyrics.syncedLyrics!);
    _currentLyricIndex = 0;
    notifyListeners();
  }

  List<LyricLine> _parseSyncedLyrics(String syncedLyrics) {
    List<LyricLine> parsedLyrics = [];
    RegExp regex = RegExp(r"\[(\d+):(\d+).(\d+)\] (.+)");

    for (var line in syncedLyrics.split('\n')) {
      var match = regex.firstMatch(line);

      if (match != null) {
        int minutes = int.parse(match.group(1)!);
        int seconds = int.parse(match.group(2)!);
        String text = match.group(4)!;
        int timestamp = (minutes * 60) + seconds;
        parsedLyrics.add(LyricLine(text: text, startTime: timestamp));
      }
    }
    return parsedLyrics;
  }

  List<LyricLine> _parsePlainLyrics(String plainLyrics) {
    List<String> lines = plainLyrics.split('\n');
    List<LyricLine> parsedLyrics = [];

    for (int i = 0; i < lines.length; i++) {
      parsedLyrics.add(LyricLine(text: lines[i], startTime: i * 5)); // Approximate each line as 5s apart
    }
    return parsedLyrics;
  }

  void _updateCurrentLyric(int seconds) {
    for (int i=0; i<_lyrics.length; i++) {
      if (seconds >= lyrics[i].startTime && (i == _lyrics.length - 1 || seconds < _lyrics[i + 1].startTime)) {
        if (_currentLyricIndex != i) {
          _currentLyricIndex = i;
          _scrollToCurrentLyric();
          notifyListeners();
        }
        break;
      }
    }
  }

  void _scrollToCurrentLyric() {
    if (_lyricsScrollController.hasClients) {
      _lyricsScrollController.animateTo(
        (_currentLyricIndex * 30).toDouble(),  // Adjust based on item height
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

class PlayerPanel extends StatefulWidget {
  const PlayerPanel({super.key});

  @override
  State<PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends State<PlayerPanel> with TickerProviderStateMixin{
  late TabController _tabController;
  late TabController _bottomTabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    _bottomTabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        if (player.songTitle.isEmpty) {
          return Container(
            color: Colors.grey[850],
            child: Center(child: Text('No Song is playing', style: TextStyle(color: Colors.white),))
          );
        }
        return Container(
          color: Colors.grey[850],
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              _buildTopRow(player),
              SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Audio Tab
                    Column(
                      children: [
                        _buildThumbnail(player),
                        SizedBox(height: 10),
                        _buildArtistInfo(player),
                        SizedBox(height: 10),
                        _buildActionsRow(),
                        SizedBox(height: 10),
                        _buildProgressBar(player),
                        SizedBox(height: 10),
                        _buildControlsRow(player)
                      ],
                    ),
                    // Video Tab
                    Column(
                      children: [
                        _buildVideoPlayer(player),
                        SizedBox(height: 10),
                        _buildArtistInfo(player),
                        SizedBox(height: 10),
                        _buildProgressBar(player),
                        _buildControlsRow(player)
                      ],
                    ),
                  ]
                )
              ),
              _buildBottomRow(player),
            ],
          ),
        );
      }
    );
  }

  Widget _buildTopRow(PlayerProvider player) => Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      IconButton(onPressed: () {}, icon: Icon(Icons.keyboard_arrow_down)),
      Spacer(),
      Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            color: Colors.black12,
          ),
          child: _buildTabBar(player)
      ),
      Spacer(),
      IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
    ],
  );

  Widget _buildTabBar(PlayerProvider player) => TabBar(
    controller: _tabController,
    onTap: (i) => setState(() {
      _tabController.index = i;
      player.playSong(
        videoId: player._currentVideoId!,
        title: player.songTitle,
        artist: player.artist,
        thumbnailUrl: player.thumbnailUrl,
        isVideo: i == 1,
      );
    }),
    tabs: [
      Text('Audio'),
      Text('Video')
    ],
    dividerColor: Colors.transparent,
    padding: EdgeInsets.all(0),
    indicator: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.all(Radius.circular(10))),
    indicatorSize: TabBarIndicatorSize.tab,
    tabAlignment: TabAlignment.center,
    labelColor: Colors.white,
  );

  Widget _buildThumbnail(PlayerProvider player) => ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(player._thumbnailUrl, height: 300, width: double.maxFinite, fit: BoxFit.fitHeight,),
    );

  Widget _buildArtistInfo(PlayerProvider player) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(player._songTitle, style: TextStyle(fontSize: 25)),
      Text(player._artist, style: TextStyle(fontSize: 20, color: Colors.grey)),
    ],
  );

  Widget _buildActionsRow() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      ElevatedButton(onPressed: (){}, child: Row(spacing: 5, children: [Icon(Icons.thumb_up_outlined), Text('Like')],)),
      ElevatedButton(onPressed: (){}, child: Row(spacing: 5, children: [Icon(Icons.playlist_add), Text('Add')],)),
      ElevatedButton(onPressed: (){}, child: Row(spacing: 5, children: [Icon(Icons.download), Text('Download')],))
    ],
  );

  Widget _buildProgressBar(PlayerProvider player) {
    double progress = (player.totalDuration.inSeconds > 0)
        ? player.currentPosition.inSeconds.toDouble()
        : 0.0;

    double max = (player.totalDuration.inSeconds > 0)
        ? player.totalDuration.inSeconds.toDouble()
        : 1.0; // Prevents `max` from being 0
    return Column(
      spacing: 0,
      children: [
        Slider(
          value: progress,
          max: max,
          onChanged: (value) => player.seekTo(Duration(seconds: value.toInt())),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${player.currentPosition}".substring(2, 7), style: TextStyle(color: Colors.grey, fontSize: 13),),
            Text("${player.totalDuration}".substring(2, 7), style: TextStyle(color: Colors.grey, fontSize: 13))
          ],
        )
      ],
    );
  }

  Widget _buildControlsRow(PlayerProvider player) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      IconButton(onPressed: (){}, icon: Icon(Icons.shuffle)),
      IconButton(onPressed: (){}, icon: Icon(Icons.skip_previous)),
      IconButton(
        icon: Icon(player._isPlaying ? Icons.pause_circle : Icons.play_circle, size: 50,),
        onPressed: () => player.togglePlayPause(),
      ),
      IconButton(onPressed: (){}, icon: Icon(Icons.skip_next)),
      IconButton(onPressed: (){}, icon: Icon(Icons.loop)),
    ],
  );

  Widget _buildVideoPlayer(PlayerProvider player) {
    return Container(
        width: MediaQuery.of(context).size.width,
        height: 300,
        decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(20))),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Video(
          controller: player._videoController,
          controls: null,
          fit: BoxFit.cover,
          height: 300,
        )
    );
  }

  Widget _buildBottomRow(PlayerProvider player) => Container(
    margin: EdgeInsets.only(bottom: 50),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(onPressed: ()=>_showBottomSheet(0), child: Text("Up Next")),
        TextButton(onPressed: ()=>_showBottomSheet(1), child: Text("Lyrics")),
        TextButton(onPressed: ()=>_showBottomSheet(2), child: Text("Related")),
      ],
    ),
  );

  void _showBottomSheet(int index) {
    _bottomTabController.index = index;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(10))),
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.90,
          child: Consumer<PlayerProvider>(
            builder: (context, player, child) {
              return Column(
                children: [
                  _buildBottomSheetTabs(),
                  Expanded(
                    child: TabBarView(
                      controller: _bottomTabController,
                      children: [
                        // playlist
                        _buildUpNextTab(player),
                        // lyrics
                        _buildLyricsTab(player),
                        // related songs
                        _buildRelatedTab(player)
                      ],
                    ),
                  )
                ],
              );
            },
          ),
        )
    );
  }

  Widget _buildBottomSheetTabs() => TabBar(
    controller: _bottomTabController,
    tabs: [Text("Up Next"), Text("Lyrics"), Text("Related"),],
    indicatorSize: TabBarIndicatorSize.tab,
    indicatorColor: Colors.white,
    labelPadding: EdgeInsets.symmetric(vertical: 10),
    onTap: (i) => setState(()=>_bottomTabController.index = i),
  );

  Widget _buildUpNextTab(PlayerProvider player) => ListView.builder(
      itemCount: player.upcomingSongs.length,
      itemBuilder: (context, index) {
        final Song song = player.upcomingSongs[index];
        return ListTile(
          leading: Image.network(song.thumbnail!.url),
          title: Text(song.title),
          subtitle: Text(song.artistName),
          selected: song.title == player.songTitle,
          selectedTileColor: Colors.white24,
          onTap: (){
            player.playSong(
              videoId: song.id,
              title: song.title,
              artist: song.artistName,
              thumbnailUrl: song.thumbnail!.url,
            );
            if (index >= player.upcomingSongs.length - 6) {
              setState(() => player.upcomingSongs.addAll(HomeScreen.quickPicks));
            }
          },
        );
      }
  );

  Widget _buildLyricsTab(PlayerProvider player) => Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: player.lyrics.isNotEmpty
          ? ListView.builder(
        itemCount: player.lyrics.length,
        controller: player.lyricsScrollController,
        itemBuilder: (context, index) {
          bool isActive = index == player.currentLyricIndex;
          return AnimatedContainer(
            padding: EdgeInsets.symmetric(horizontal: 10),
            duration: Duration(milliseconds: 300),
            child: GestureDetector(
              onTap: ()=>player.seekTo(Duration(seconds:player.lyrics[index].startTime + 1)),
              child: Text(
                player.lyrics[index].text,
                style: TextStyle(color: isActive? Colors.white: Colors.white30, fontSize: 25),
              ),
            ),
          );
        },
      )
          :Center(child: Text("No Lyrics Available"),),
    );

  Widget _buildRelatedTab(PlayerProvider player) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10),
  );

  @override
  void dispose() {
    _tabController.dispose();
    _bottomTabController.dispose();
    super.dispose();
  }
}
