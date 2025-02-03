class Thumbnail {
  final String url;

  Thumbnail({required this.url});

  factory Thumbnail.fromJson(Map<String, dynamic> json) => Thumbnail(url: json['url'] ?? '');

  Map<String, dynamic> toJson() => {'url': url};
}

class Song {
  final String id;
  final String title;
  final String artistName;
  final String artistId;
  final String? albumName;
  final String? albumId;
  final Thumbnail? thumbnail;
  final Lyrics? lyrics;

  Song({
    required this.id,
    required this.title,
    required this.artistName,
    required this.artistId,
    this.albumName,
    this.albumId,
    this.thumbnail,
    this.lyrics
  });

  factory Song.fromJson(Map<String, dynamic> json) => Song(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      artistName: json['artistName'] ?? '',
      artistId: json['artistId'] ?? '',
      albumName: json['albumName'] ?? '',
      albumId: json['albumId'] ?? '',
      thumbnail: json['thumbnail'],
      lyrics: json['lyrics'] ?? ''
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artistName': artistName,
    'artistId': artistId,
    'albumName': albumName,
    'albumId': albumId,
    'thumbnail': thumbnail?.toJson(),
    'lyrics': lyrics
  };
  
  @override
  String toString() {
    return title.padRight(1, artistName);
  }
}


class Album {
  final String id;
  final String title;
  final String artistName;
  final String artistId;
  final List<Song>? songs;
  final Thumbnail? thumbnail;

  Album({required this.id, required this.title, required this.artistId, required this.artistName, this.thumbnail, this.songs});

  factory Album.fromJson(Map<String, dynamic> json) => Album(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    artistName: json['artistName'] ?? '',
    artistId: json['artistId'] ?? '',
    thumbnail: json['thumbnail'],
    songs: List.from(json['songs'])
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artistName': artistName,
    'artistId': artistId,
    'thumbnail': thumbnail?.toJson(),
    'songs': songs
  };
}

class Playlist {
  final String id;
  final String title;
  final List<Song> songs;
  final Thumbnail? thumbnail;

  Playlist({required this.id, required this.title, required this.songs, this.thumbnail});

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    songs: List.from(json['songs']),
    thumbnail: json['thumbnail']
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'songs': songs,
    'thumbnail': thumbnail?.toJson()
  };

  get length => songs.length;
}

class Artist {
  final String id;
  final String name;
  final Thumbnail? thumbnail;

  Artist({required this.id, required this.name, this.thumbnail});

  factory Artist.fromJson(Map<String, dynamic> json) => Artist(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    thumbnail: json['thumbnail']
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'thumbnail': thumbnail
  };
}

class Lyrics {
  final int id;
  final String name;
  final String trackName;
  final String artistName;
  final String albumName;
  final Duration duration;
  final bool instrumental;
  final String? plainLyrics;
  final String? syncedLyrics;

  Lyrics({
    required this.id,
    required this.name,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    required this.duration,
    required this.instrumental,
    this.plainLyrics,
    this.syncedLyrics
  });

  factory Lyrics.fromJson(Map<String, dynamic> json) => Lyrics(
    id: json['id'],
    name: json['name'],
    trackName: json['trackName'],
    artistName: json['artistName'],
    albumName: json['albumName'],
    duration: Duration(seconds: json['duration'].toInt()),
    instrumental: json['instrumental'] as bool,
    plainLyrics: json['plainLyrics'],
    syncedLyrics: json['syncedLyrics']
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'trackName': trackName,
    'artistName': artistName,
    'albumName': albumName,
    'duration': duration.inSeconds,
    'instrumental': instrumental,
    'plainLyrics': plainLyrics,
    'syncedLyrics': syncedLyrics
  };
}

class LyricLine {
  final String text;
  final int startTime;

  LyricLine({required this.text, required this.startTime});
}