import 'package:flutter/material.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}


class _ExploreScreenState extends State<ExploreScreen> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 300,
            margin: EdgeInsets.only(bottom: 10),
            // child: YouTubeAudioPlayer(videoId: '0qAJgwkN76Y'),
          ),

        ],
      ),
    );
  }


}
