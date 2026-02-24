// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ArtistAdapter extends TypeAdapter<Artist> {
  @override
  final int typeId = 1;

  @override
  Artist read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Artist(
      id: fields[0] as String,
      name: fields[1] as String,
      bio: fields[2] as String?,
      imageUrl: fields[3] as String?,
      monthlyListeners: fields[4] as int,
      genres: (fields[5] as List).cast<String>(),
      topSongs: (fields[6] as List).cast<String>(),
      albums: (fields[7] as List).cast<String>(),
      followersCount: fields[8] as int,
      isVerified: fields[9] as bool,
      website: fields[10] as String?,
      facebookUrl: fields[11] as String?,
      twitterUrl: fields[12] as String?,
      instagramUrl: fields[13] as String?,
      createdAt: fields[14] as DateTime?,
      updatedAt: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Artist obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.bio)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.monthlyListeners)
      ..writeByte(5)
      ..write(obj.genres)
      ..writeByte(6)
      ..write(obj.topSongs)
      ..writeByte(7)
      ..write(obj.albums)
      ..writeByte(8)
      ..write(obj.followersCount)
      ..writeByte(9)
      ..write(obj.isVerified)
      ..writeByte(10)
      ..write(obj.website)
      ..writeByte(11)
      ..write(obj.facebookUrl)
      ..writeByte(12)
      ..write(obj.twitterUrl)
      ..writeByte(13)
      ..write(obj.instagramUrl)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtistAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
