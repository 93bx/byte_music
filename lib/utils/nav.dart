import 'package:byte_player/models/models.dart';
import 'package:byte_player/screens/explore_screen.dart';
import 'package:byte_player/screens/home_screen.dart';
import 'package:byte_player/screens/library_screen.dart';
import 'package:byte_player/screens/player_panel.dart';
import 'package:byte_player/widgets/titlebar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class Nav extends StatefulWidget {
  const Nav({super.key});

  @override
  State<Nav> createState() => _NavState();
}

class _NavState extends State<Nav> {
  int _currentIndex = 0;
  final PanelController _panelController = PanelController();


  void onTabTabbed(int index) => setState(() => _currentIndex = index);

  void _onSongSelected(Song song, List<Song> upcoming) {
    Provider.of<PlayerProvider>(context, listen: false).playSong(
      videoId: song.id,
      title: song.title,
      artist: song.artistName,
      thumbnailUrl: song.thumbnail!.url,
    );
    Provider.of<PlayerProvider>(context, listen: false).setPlaylist(upcoming);
    _panelController.open();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Titlebar()
      ),
      bottomNavigationBar: SizedBox(
        height: 35,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: onTabTabbed,
          showUnselectedLabels: false,
          showSelectedLabels: false,
          unselectedFontSize: 0,
          selectedFontSize: 0,
          iconSize: 25,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore),
                label: 'explore'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music_outlined),
              activeIcon: Icon(Icons.library_music),
              label: 'library',
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(onSongSelected: _onSongSelected),
            ExploreScreen(),
            LibraryScreen()
          ],
        ),
          SlidingUpPanel(
            controller: _panelController,
            minHeight: 70, // Height when collapsed (mini player)
            maxHeight: MediaQuery.of(context).size.height, // Adjust as needed
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            panel: PlayerPanel(),
            collapsed: buildCollapsedPanel(),
          )
        ],
      ),
    );
  }

  Widget buildCollapsedPanel() {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        return GestureDetector(
          onTap: () {
            _panelController.open();
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 0, vertical: 5),
            color: Colors.grey[850],
            child: Row(
              spacing: 10,
              children: [
                // Song Thumbnail
                player.songTitle.isEmpty ?
                Image.asset('assets/images/player_placeholder.png', color: Colors.white38,) :
                Image.network(player.thumbnailUrl, fit: BoxFit.cover),
                // Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(player.songTitle.isEmpty? "Nothing Is Playing" : player.songTitle, style: TextStyle(color: Colors.white)),
                      Text(player.songTitle.isEmpty? "" : player.artist, style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                // Play/Pause Button
                IconButton(
                  icon: Icon(Icons.keyboard_arrow_up, color: Colors.white),
                  onPressed: () {
                    _panelController.open();
                  },
                ),
              ],
            ),
          ),
        );
      }
    );
  }

}
