// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongAdapter extends TypeAdapter<Song> {
  @override
  final int typeId = 0;

  @override
  Song read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Song(
      id: fields[0] as String,
      title: fields[1] as String,
      artist: fields[2] as String,
      album: fields[3] as String,
      duration: fields[4] as String,
      durationInSeconds: fields[5] as int,
      audioUrl: fields[6] as String,
      coverUrl: fields[7] as String,
      artistId: fields[8] as String?,
      albumId: fields[9] as String?,
      genres: (fields[10] as List).cast<String>(),
      releaseDate: fields[11] as DateTime,
      playCount: fields[12] as int,
      likeCount: fields[13] as int,
      isExplicit: fields[14] as bool,
      lyricsUrl: fields[15] as String?,
      copyright: fields[16] as String?,
      tags: (fields[17] as List).cast<String>(),
      bitrate: fields[18] as int,
      format: fields[19] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Song obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.album)
      ..writeByte(4)
      ..write(obj.duration)
      ..writeByte(5)
      ..write(obj.durationInSeconds)
      ..writeByte(6)
      ..write(obj.audioUrl)
      ..writeByte(7)
      ..write(obj.coverUrl)
      ..writeByte(8)
      ..write(obj.artistId)
      ..writeByte(9)
      ..write(obj.albumId)
      ..writeByte(10)
      ..write(obj.genres)
      ..writeByte(11)
      ..write(obj.releaseDate)
      ..writeByte(12)
      ..write(obj.playCount)
      ..writeByte(13)
      ..write(obj.likeCount)
      ..writeByte(14)
      ..write(obj.isExplicit)
      ..writeByte(15)
      ..write(obj.lyricsUrl)
      ..writeByte(16)
      ..write(obj.copyright)
      ..writeByte(17)
      ..write(obj.tags)
      ..writeByte(18)
      ..write(obj.bitrate)
      ..writeByte(19)
      ..write(obj.format);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
