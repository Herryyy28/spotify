// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaylistAdapter extends TypeAdapter<Playlist> {
  @override
  final int typeId = 2;

  @override
  Playlist read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Playlist(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      coverUrl: fields[3] as String?,
      userId: fields[4] as String,
      userName: fields[5] as String,
      songs: (fields[6] as List).cast<Song>(),
      songCount: fields[7] as int,
      totalDuration: fields[8] as int,
      followersCount: fields[9] as int,
      isPublic: fields[10] as bool,
      isCollaborative: fields[11] as bool,
      collaborators: (fields[12] as List).cast<String>(),
      createdAt: fields[13] as DateTime,
      updatedAt: fields[14] as DateTime,
      color: fields[15] as String?,
      tags: (fields[16] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Playlist obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.coverUrl)
      ..writeByte(4)
      ..write(obj.userId)
      ..writeByte(5)
      ..write(obj.userName)
      ..writeByte(6)
      ..write(obj.songs)
      ..writeByte(7)
      ..write(obj.songCount)
      ..writeByte(8)
      ..write(obj.totalDuration)
      ..writeByte(9)
      ..write(obj.followersCount)
      ..writeByte(10)
      ..write(obj.isPublic)
      ..writeByte(11)
      ..write(obj.isCollaborative)
      ..writeByte(12)
      ..write(obj.collaborators)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.color)
      ..writeByte(16)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
