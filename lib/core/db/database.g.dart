// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ComicsTable extends Comics with TableInfo<$ComicsTable, Comic> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ComicsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _comicIdMeta =
      const VerificationMeta('comicId');
  @override
  late final GeneratedColumn<String> comicId = GeneratedColumn<String>(
      'comic_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
      'author', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _episodeCountMeta =
      const VerificationMeta('episodeCount');
  @override
  late final GeneratedColumn<int> episodeCount = GeneratedColumn<int>(
      'episode_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isFollowedMeta =
      const VerificationMeta('isFollowed');
  @override
  late final GeneratedColumn<bool> isFollowed = GeneratedColumn<bool>(
      'is_followed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_followed" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        comicId,
        title,
        author,
        coverUrl,
        description,
        episodeCount,
        createdAt,
        updatedAt,
        isFavorite,
        isFollowed
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'comics';
  @override
  VerificationContext validateIntegrity(Insertable<Comic> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('comic_id')) {
      context.handle(_comicIdMeta,
          comicId.isAcceptableOrUnknown(data['comic_id']!, _comicIdMeta));
    } else if (isInserting) {
      context.missing(_comicIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(_authorMeta,
          author.isAcceptableOrUnknown(data['author']!, _authorMeta));
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    } else if (isInserting) {
      context.missing(_coverUrlMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('episode_count')) {
      context.handle(
          _episodeCountMeta,
          episodeCount.isAcceptableOrUnknown(
              data['episode_count']!, _episodeCountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('is_followed')) {
      context.handle(
          _isFollowedMeta,
          isFollowed.isAcceptableOrUnknown(
              data['is_followed']!, _isFollowedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Comic map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Comic(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      comicId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}comic_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      author: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author']),
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      episodeCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}episode_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      isFollowed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_followed'])!,
    );
  }

  @override
  $ComicsTable createAlias(String alias) {
    return $ComicsTable(attachedDatabase, alias);
  }
}

class Comic extends DataClass implements Insertable<Comic> {
  final int id;
  final String comicId;
  final String title;
  final String? author;
  final String coverUrl;
  final String? description;
  final int episodeCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isFavorite;
  final bool isFollowed;
  const Comic(
      {required this.id,
      required this.comicId,
      required this.title,
      this.author,
      required this.coverUrl,
      this.description,
      required this.episodeCount,
      this.createdAt,
      this.updatedAt,
      required this.isFavorite,
      required this.isFollowed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['comic_id'] = Variable<String>(comicId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    map['cover_url'] = Variable<String>(coverUrl);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['episode_count'] = Variable<int>(episodeCount);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_followed'] = Variable<bool>(isFollowed);
    return map;
  }

  ComicsCompanion toCompanion(bool nullToAbsent) {
    return ComicsCompanion(
      id: Value(id),
      comicId: Value(comicId),
      title: Value(title),
      author:
          author == null && nullToAbsent ? const Value.absent() : Value(author),
      coverUrl: Value(coverUrl),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      episodeCount: Value(episodeCount),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isFavorite: Value(isFavorite),
      isFollowed: Value(isFollowed),
    );
  }

  factory Comic.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Comic(
      id: serializer.fromJson<int>(json['id']),
      comicId: serializer.fromJson<String>(json['comicId']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      coverUrl: serializer.fromJson<String>(json['coverUrl']),
      description: serializer.fromJson<String?>(json['description']),
      episodeCount: serializer.fromJson<int>(json['episodeCount']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isFollowed: serializer.fromJson<bool>(json['isFollowed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'comicId': serializer.toJson<String>(comicId),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'coverUrl': serializer.toJson<String>(coverUrl),
      'description': serializer.toJson<String?>(description),
      'episodeCount': serializer.toJson<int>(episodeCount),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isFollowed': serializer.toJson<bool>(isFollowed),
    };
  }

  Comic copyWith(
          {int? id,
          String? comicId,
          String? title,
          Value<String?> author = const Value.absent(),
          String? coverUrl,
          Value<String?> description = const Value.absent(),
          int? episodeCount,
          Value<DateTime?> createdAt = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent(),
          bool? isFavorite,
          bool? isFollowed}) =>
      Comic(
        id: id ?? this.id,
        comicId: comicId ?? this.comicId,
        title: title ?? this.title,
        author: author.present ? author.value : this.author,
        coverUrl: coverUrl ?? this.coverUrl,
        description: description.present ? description.value : this.description,
        episodeCount: episodeCount ?? this.episodeCount,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        isFavorite: isFavorite ?? this.isFavorite,
        isFollowed: isFollowed ?? this.isFollowed,
      );
  @override
  String toString() {
    return (StringBuffer('Comic(')
          ..write('id: $id, ')
          ..write('comicId: $comicId, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('description: $description, ')
          ..write('episodeCount: $episodeCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isFollowed: $isFollowed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, comicId, title, author, coverUrl,
      description, episodeCount, createdAt, updatedAt, isFavorite, isFollowed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Comic &&
          other.id == this.id &&
          other.comicId == this.comicId &&
          other.title == this.title &&
          other.author == this.author &&
          other.coverUrl == this.coverUrl &&
          other.description == this.description &&
          other.episodeCount == this.episodeCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isFavorite == this.isFavorite &&
          other.isFollowed == this.isFollowed);
}

class ComicsCompanion extends UpdateCompanion<Comic> {
  final Value<int> id;
  final Value<String> comicId;
  final Value<String> title;
  final Value<String?> author;
  final Value<String> coverUrl;
  final Value<String?> description;
  final Value<int> episodeCount;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<bool> isFavorite;
  final Value<bool> isFollowed;
  const ComicsCompanion({
    this.id = const Value.absent(),
    this.comicId = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.description = const Value.absent(),
    this.episodeCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isFollowed = const Value.absent(),
  });
  ComicsCompanion.insert({
    this.id = const Value.absent(),
    required String comicId,
    required String title,
    this.author = const Value.absent(),
    required String coverUrl,
    this.description = const Value.absent(),
    this.episodeCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isFollowed = const Value.absent(),
  })  : comicId = Value(comicId),
        title = Value(title),
        coverUrl = Value(coverUrl);
  static Insertable<Comic> custom({
    Expression<int>? id,
    Expression<String>? comicId,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? coverUrl,
    Expression<String>? description,
    Expression<int>? episodeCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isFavorite,
    Expression<bool>? isFollowed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (comicId != null) 'comic_id': comicId,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (description != null) 'description': description,
      if (episodeCount != null) 'episode_count': episodeCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isFollowed != null) 'is_followed': isFollowed,
    });
  }

  ComicsCompanion copyWith(
      {Value<int>? id,
      Value<String>? comicId,
      Value<String>? title,
      Value<String?>? author,
      Value<String>? coverUrl,
      Value<String?>? description,
      Value<int>? episodeCount,
      Value<DateTime?>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<bool>? isFavorite,
      Value<bool>? isFollowed}) {
    return ComicsCompanion(
      id: id ?? this.id,
      comicId: comicId ?? this.comicId,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      description: description ?? this.description,
      episodeCount: episodeCount ?? this.episodeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (comicId.present) {
      map['comic_id'] = Variable<String>(comicId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (episodeCount.present) {
      map['episode_count'] = Variable<int>(episodeCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isFollowed.present) {
      map['is_followed'] = Variable<bool>(isFollowed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ComicsCompanion(')
          ..write('id: $id, ')
          ..write('comicId: $comicId, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('description: $description, ')
          ..write('episodeCount: $episodeCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isFollowed: $isFollowed')
          ..write(')'))
        .toString();
  }
}

class $EpisodesTable extends Episodes with TableInfo<$EpisodesTable, Episode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _episodeIdMeta =
      const VerificationMeta('episodeId');
  @override
  late final GeneratedColumn<String> episodeId = GeneratedColumn<String>(
      'episode_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _comicIdMeta =
      const VerificationMeta('comicId');
  @override
  late final GeneratedColumn<int> comicId = GeneratedColumn<int>(
      'comic_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES comics (id)'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _publishedAtMeta =
      const VerificationMeta('publishedAt');
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
      'published_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, episodeId, comicId, title, order, publishedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(Insertable<Episode> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('episode_id')) {
      context.handle(_episodeIdMeta,
          episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta));
    } else if (isInserting) {
      context.missing(_episodeIdMeta);
    }
    if (data.containsKey('comic_id')) {
      context.handle(_comicIdMeta,
          comicId.isAcceptableOrUnknown(data['comic_id']!, _comicIdMeta));
    } else if (isInserting) {
      context.missing(_comicIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
          _orderMeta, order.isAcceptableOrUnknown(data['order']!, _orderMeta));
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('published_at')) {
      context.handle(
          _publishedAtMeta,
          publishedAt.isAcceptableOrUnknown(
              data['published_at']!, _publishedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Episode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Episode(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      episodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}episode_id'])!,
      comicId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}comic_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order'])!,
      publishedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}published_at']),
    );
  }

  @override
  $EpisodesTable createAlias(String alias) {
    return $EpisodesTable(attachedDatabase, alias);
  }
}

class Episode extends DataClass implements Insertable<Episode> {
  final int id;
  final String episodeId;
  final int comicId;
  final String title;
  final int order;
  final DateTime? publishedAt;
  const Episode(
      {required this.id,
      required this.episodeId,
      required this.comicId,
      required this.title,
      required this.order,
      this.publishedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['episode_id'] = Variable<String>(episodeId);
    map['comic_id'] = Variable<int>(comicId);
    map['title'] = Variable<String>(title);
    map['order'] = Variable<int>(order);
    if (!nullToAbsent || publishedAt != null) {
      map['published_at'] = Variable<DateTime>(publishedAt);
    }
    return map;
  }

  EpisodesCompanion toCompanion(bool nullToAbsent) {
    return EpisodesCompanion(
      id: Value(id),
      episodeId: Value(episodeId),
      comicId: Value(comicId),
      title: Value(title),
      order: Value(order),
      publishedAt: publishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedAt),
    );
  }

  factory Episode.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Episode(
      id: serializer.fromJson<int>(json['id']),
      episodeId: serializer.fromJson<String>(json['episodeId']),
      comicId: serializer.fromJson<int>(json['comicId']),
      title: serializer.fromJson<String>(json['title']),
      order: serializer.fromJson<int>(json['order']),
      publishedAt: serializer.fromJson<DateTime?>(json['publishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'episodeId': serializer.toJson<String>(episodeId),
      'comicId': serializer.toJson<int>(comicId),
      'title': serializer.toJson<String>(title),
      'order': serializer.toJson<int>(order),
      'publishedAt': serializer.toJson<DateTime?>(publishedAt),
    };
  }

  Episode copyWith(
          {int? id,
          String? episodeId,
          int? comicId,
          String? title,
          int? order,
          Value<DateTime?> publishedAt = const Value.absent()}) =>
      Episode(
        id: id ?? this.id,
        episodeId: episodeId ?? this.episodeId,
        comicId: comicId ?? this.comicId,
        title: title ?? this.title,
        order: order ?? this.order,
        publishedAt: publishedAt.present ? publishedAt.value : this.publishedAt,
      );
  @override
  String toString() {
    return (StringBuffer('Episode(')
          ..write('id: $id, ')
          ..write('episodeId: $episodeId, ')
          ..write('comicId: $comicId, ')
          ..write('title: $title, ')
          ..write('order: $order, ')
          ..write('publishedAt: $publishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, episodeId, comicId, title, order, publishedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Episode &&
          other.id == this.id &&
          other.episodeId == this.episodeId &&
          other.comicId == this.comicId &&
          other.title == this.title &&
          other.order == this.order &&
          other.publishedAt == this.publishedAt);
}

class EpisodesCompanion extends UpdateCompanion<Episode> {
  final Value<int> id;
  final Value<String> episodeId;
  final Value<int> comicId;
  final Value<String> title;
  final Value<int> order;
  final Value<DateTime?> publishedAt;
  const EpisodesCompanion({
    this.id = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.comicId = const Value.absent(),
    this.title = const Value.absent(),
    this.order = const Value.absent(),
    this.publishedAt = const Value.absent(),
  });
  EpisodesCompanion.insert({
    this.id = const Value.absent(),
    required String episodeId,
    required int comicId,
    required String title,
    required int order,
    this.publishedAt = const Value.absent(),
  })  : episodeId = Value(episodeId),
        comicId = Value(comicId),
        title = Value(title),
        order = Value(order);
  static Insertable<Episode> custom({
    Expression<int>? id,
    Expression<String>? episodeId,
    Expression<int>? comicId,
    Expression<String>? title,
    Expression<int>? order,
    Expression<DateTime>? publishedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (episodeId != null) 'episode_id': episodeId,
      if (comicId != null) 'comic_id': comicId,
      if (title != null) 'title': title,
      if (order != null) 'order': order,
      if (publishedAt != null) 'published_at': publishedAt,
    });
  }

  EpisodesCompanion copyWith(
      {Value<int>? id,
      Value<String>? episodeId,
      Value<int>? comicId,
      Value<String>? title,
      Value<int>? order,
      Value<DateTime?>? publishedAt}) {
    return EpisodesCompanion(
      id: id ?? this.id,
      episodeId: episodeId ?? this.episodeId,
      comicId: comicId ?? this.comicId,
      title: title ?? this.title,
      order: order ?? this.order,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<String>(episodeId.value);
    }
    if (comicId.present) {
      map['comic_id'] = Variable<int>(comicId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesCompanion(')
          ..write('id: $id, ')
          ..write('episodeId: $episodeId, ')
          ..write('comicId: $comicId, ')
          ..write('title: $title, ')
          ..write('order: $order, ')
          ..write('publishedAt: $publishedAt')
          ..write(')'))
        .toString();
  }
}

class $HistoryTable extends History with TableInfo<$HistoryTable, HistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _comicIdMeta =
      const VerificationMeta('comicId');
  @override
  late final GeneratedColumn<int> comicId = GeneratedColumn<int>(
      'comic_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES comics (id)'));
  static const VerificationMeta _episodeIdMeta =
      const VerificationMeta('episodeId');
  @override
  late final GeneratedColumn<int> episodeId = GeneratedColumn<int>(
      'episode_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES episodes (id)'));
  static const VerificationMeta _lastPageMeta =
      const VerificationMeta('lastPage');
  @override
  late final GeneratedColumn<int> lastPage = GeneratedColumn<int>(
      'last_page', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastReadAtMeta =
      const VerificationMeta('lastReadAt');
  @override
  late final GeneratedColumn<DateTime> lastReadAt = GeneratedColumn<DateTime>(
      'last_read_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, comicId, episodeId, lastPage, lastReadAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history';
  @override
  VerificationContext validateIntegrity(Insertable<HistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('comic_id')) {
      context.handle(_comicIdMeta,
          comicId.isAcceptableOrUnknown(data['comic_id']!, _comicIdMeta));
    } else if (isInserting) {
      context.missing(_comicIdMeta);
    }
    if (data.containsKey('episode_id')) {
      context.handle(_episodeIdMeta,
          episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta));
    } else if (isInserting) {
      context.missing(_episodeIdMeta);
    }
    if (data.containsKey('last_page')) {
      context.handle(_lastPageMeta,
          lastPage.isAcceptableOrUnknown(data['last_page']!, _lastPageMeta));
    }
    if (data.containsKey('last_read_at')) {
      context.handle(
          _lastReadAtMeta,
          lastReadAt.isAcceptableOrUnknown(
              data['last_read_at']!, _lastReadAtMeta));
    } else if (isInserting) {
      context.missing(_lastReadAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      comicId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}comic_id'])!,
      episodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}episode_id'])!,
      lastPage: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_page'])!,
      lastReadAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_read_at'])!,
    );
  }

  @override
  $HistoryTable createAlias(String alias) {
    return $HistoryTable(attachedDatabase, alias);
  }
}

class HistoryData extends DataClass implements Insertable<HistoryData> {
  final int id;
  final int comicId;
  final int episodeId;
  final int lastPage;
  final DateTime lastReadAt;
  const HistoryData(
      {required this.id,
      required this.comicId,
      required this.episodeId,
      required this.lastPage,
      required this.lastReadAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['comic_id'] = Variable<int>(comicId);
    map['episode_id'] = Variable<int>(episodeId);
    map['last_page'] = Variable<int>(lastPage);
    map['last_read_at'] = Variable<DateTime>(lastReadAt);
    return map;
  }

  HistoryCompanion toCompanion(bool nullToAbsent) {
    return HistoryCompanion(
      id: Value(id),
      comicId: Value(comicId),
      episodeId: Value(episodeId),
      lastPage: Value(lastPage),
      lastReadAt: Value(lastReadAt),
    );
  }

  factory HistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryData(
      id: serializer.fromJson<int>(json['id']),
      comicId: serializer.fromJson<int>(json['comicId']),
      episodeId: serializer.fromJson<int>(json['episodeId']),
      lastPage: serializer.fromJson<int>(json['lastPage']),
      lastReadAt: serializer.fromJson<DateTime>(json['lastReadAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'comicId': serializer.toJson<int>(comicId),
      'episodeId': serializer.toJson<int>(episodeId),
      'lastPage': serializer.toJson<int>(lastPage),
      'lastReadAt': serializer.toJson<DateTime>(lastReadAt),
    };
  }

  HistoryData copyWith(
          {int? id,
          int? comicId,
          int? episodeId,
          int? lastPage,
          DateTime? lastReadAt}) =>
      HistoryData(
        id: id ?? this.id,
        comicId: comicId ?? this.comicId,
        episodeId: episodeId ?? this.episodeId,
        lastPage: lastPage ?? this.lastPage,
        lastReadAt: lastReadAt ?? this.lastReadAt,
      );
  @override
  String toString() {
    return (StringBuffer('HistoryData(')
          ..write('id: $id, ')
          ..write('comicId: $comicId, ')
          ..write('episodeId: $episodeId, ')
          ..write('lastPage: $lastPage, ')
          ..write('lastReadAt: $lastReadAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, comicId, episodeId, lastPage, lastReadAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryData &&
          other.id == this.id &&
          other.comicId == this.comicId &&
          other.episodeId == this.episodeId &&
          other.lastPage == this.lastPage &&
          other.lastReadAt == this.lastReadAt);
}

class HistoryCompanion extends UpdateCompanion<HistoryData> {
  final Value<int> id;
  final Value<int> comicId;
  final Value<int> episodeId;
  final Value<int> lastPage;
  final Value<DateTime> lastReadAt;
  const HistoryCompanion({
    this.id = const Value.absent(),
    this.comicId = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.lastPage = const Value.absent(),
    this.lastReadAt = const Value.absent(),
  });
  HistoryCompanion.insert({
    this.id = const Value.absent(),
    required int comicId,
    required int episodeId,
    this.lastPage = const Value.absent(),
    required DateTime lastReadAt,
  })  : comicId = Value(comicId),
        episodeId = Value(episodeId),
        lastReadAt = Value(lastReadAt);
  static Insertable<HistoryData> custom({
    Expression<int>? id,
    Expression<int>? comicId,
    Expression<int>? episodeId,
    Expression<int>? lastPage,
    Expression<DateTime>? lastReadAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (comicId != null) 'comic_id': comicId,
      if (episodeId != null) 'episode_id': episodeId,
      if (lastPage != null) 'last_page': lastPage,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
    });
  }

  HistoryCompanion copyWith(
      {Value<int>? id,
      Value<int>? comicId,
      Value<int>? episodeId,
      Value<int>? lastPage,
      Value<DateTime>? lastReadAt}) {
    return HistoryCompanion(
      id: id ?? this.id,
      comicId: comicId ?? this.comicId,
      episodeId: episodeId ?? this.episodeId,
      lastPage: lastPage ?? this.lastPage,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (comicId.present) {
      map['comic_id'] = Variable<int>(comicId.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<int>(episodeId.value);
    }
    if (lastPage.present) {
      map['last_page'] = Variable<int>(lastPage.value);
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<DateTime>(lastReadAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryCompanion(')
          ..write('id: $id, ')
          ..write('comicId: $comicId, ')
          ..write('episodeId: $episodeId, ')
          ..write('lastPage: $lastPage, ')
          ..write('lastReadAt: $lastReadAt')
          ..write(')'))
        .toString();
  }
}

class $DownloadsTable extends Downloads
    with TableInfo<$DownloadsTable, Download> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _comicIdMeta =
      const VerificationMeta('comicId');
  @override
  late final GeneratedColumn<String> comicId = GeneratedColumn<String>(
      'comic_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _coverUrlMeta =
      const VerificationMeta('coverUrl');
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
      'cover_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
      'author', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _downloadedEpisodeIdsMeta =
      const VerificationMeta('downloadedEpisodeIds');
  @override
  late final GeneratedColumn<String> downloadedEpisodeIds =
      GeneratedColumn<String>('downloaded_episode_ids', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pendingEpisodeIdsMeta =
      const VerificationMeta('pendingEpisodeIds');
  @override
  late final GeneratedColumn<String> pendingEpisodeIds =
      GeneratedColumn<String>('pending_episode_ids', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalEpisodesMeta =
      const VerificationMeta('totalEpisodes');
  @override
  late final GeneratedColumn<int> totalEpisodes = GeneratedColumn<int>(
      'total_episodes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _completedEpisodesMeta =
      const VerificationMeta('completedEpisodes');
  @override
  late final GeneratedColumn<int> completedEpisodes = GeneratedColumn<int>(
      'completed_episodes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentEpisodeIndexMeta =
      const VerificationMeta('currentEpisodeIndex');
  @override
  late final GeneratedColumn<int> currentEpisodeIndex = GeneratedColumn<int>(
      'current_episode_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentEpisodeIdMeta =
      const VerificationMeta('currentEpisodeId');
  @override
  late final GeneratedColumn<String> currentEpisodeId = GeneratedColumn<String>(
      'current_episode_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        comicId,
        title,
        coverUrl,
        author,
        tags,
        downloadedEpisodeIds,
        pendingEpisodeIds,
        status,
        totalEpisodes,
        completedEpisodes,
        currentEpisodeIndex,
        currentEpisodeId,
        localPath,
        createdAt,
        updatedAt,
        completedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(Insertable<Download> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('comic_id')) {
      context.handle(_comicIdMeta,
          comicId.isAcceptableOrUnknown(data['comic_id']!, _comicIdMeta));
    } else if (isInserting) {
      context.missing(_comicIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cover_url')) {
      context.handle(_coverUrlMeta,
          coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta));
    } else if (isInserting) {
      context.missing(_coverUrlMeta);
    }
    if (data.containsKey('author')) {
      context.handle(_authorMeta,
          author.isAcceptableOrUnknown(data['author']!, _authorMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('downloaded_episode_ids')) {
      context.handle(
          _downloadedEpisodeIdsMeta,
          downloadedEpisodeIds.isAcceptableOrUnknown(
              data['downloaded_episode_ids']!, _downloadedEpisodeIdsMeta));
    } else if (isInserting) {
      context.missing(_downloadedEpisodeIdsMeta);
    }
    if (data.containsKey('pending_episode_ids')) {
      context.handle(
          _pendingEpisodeIdsMeta,
          pendingEpisodeIds.isAcceptableOrUnknown(
              data['pending_episode_ids']!, _pendingEpisodeIdsMeta));
    } else if (isInserting) {
      context.missing(_pendingEpisodeIdsMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('total_episodes')) {
      context.handle(
          _totalEpisodesMeta,
          totalEpisodes.isAcceptableOrUnknown(
              data['total_episodes']!, _totalEpisodesMeta));
    }
    if (data.containsKey('completed_episodes')) {
      context.handle(
          _completedEpisodesMeta,
          completedEpisodes.isAcceptableOrUnknown(
              data['completed_episodes']!, _completedEpisodesMeta));
    }
    if (data.containsKey('current_episode_index')) {
      context.handle(
          _currentEpisodeIndexMeta,
          currentEpisodeIndex.isAcceptableOrUnknown(
              data['current_episode_index']!, _currentEpisodeIndexMeta));
    }
    if (data.containsKey('current_episode_id')) {
      context.handle(
          _currentEpisodeIdMeta,
          currentEpisodeId.isAcceptableOrUnknown(
              data['current_episode_id']!, _currentEpisodeIdMeta));
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Download map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Download(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      comicId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}comic_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      coverUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_url'])!,
      author: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author']),
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags']),
      downloadedEpisodeIds: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}downloaded_episode_ids'])!,
      pendingEpisodeIds: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}pending_episode_ids'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      totalEpisodes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_episodes'])!,
      completedEpisodes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}completed_episodes'])!,
      currentEpisodeIndex: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}current_episode_index'])!,
      currentEpisodeId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}current_episode_id']),
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
    );
  }

  @override
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }
}

class Download extends DataClass implements Insertable<Download> {
  final int id;
  final String comicId;
  final String title;
  final String coverUrl;
  final String? author;
  final String? tags;
  final String downloadedEpisodeIds;
  final String pendingEpisodeIds;
  final String status;
  final int totalEpisodes;
  final int completedEpisodes;
  final int currentEpisodeIndex;
  final String? currentEpisodeId;
  final String? localPath;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  const Download(
      {required this.id,
      required this.comicId,
      required this.title,
      required this.coverUrl,
      this.author,
      this.tags,
      required this.downloadedEpisodeIds,
      required this.pendingEpisodeIds,
      required this.status,
      required this.totalEpisodes,
      required this.completedEpisodes,
      required this.currentEpisodeIndex,
      this.currentEpisodeId,
      this.localPath,
      required this.createdAt,
      this.updatedAt,
      this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['comic_id'] = Variable<String>(comicId);
    map['title'] = Variable<String>(title);
    map['cover_url'] = Variable<String>(coverUrl);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['downloaded_episode_ids'] = Variable<String>(downloadedEpisodeIds);
    map['pending_episode_ids'] = Variable<String>(pendingEpisodeIds);
    map['status'] = Variable<String>(status);
    map['total_episodes'] = Variable<int>(totalEpisodes);
    map['completed_episodes'] = Variable<int>(completedEpisodes);
    map['current_episode_index'] = Variable<int>(currentEpisodeIndex);
    if (!nullToAbsent || currentEpisodeId != null) {
      map['current_episode_id'] = Variable<String>(currentEpisodeId);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      id: Value(id),
      comicId: Value(comicId),
      title: Value(title),
      coverUrl: Value(coverUrl),
      author:
          author == null && nullToAbsent ? const Value.absent() : Value(author),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      downloadedEpisodeIds: Value(downloadedEpisodeIds),
      pendingEpisodeIds: Value(pendingEpisodeIds),
      status: Value(status),
      totalEpisodes: Value(totalEpisodes),
      completedEpisodes: Value(completedEpisodes),
      currentEpisodeIndex: Value(currentEpisodeIndex),
      currentEpisodeId: currentEpisodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentEpisodeId),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory Download.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Download(
      id: serializer.fromJson<int>(json['id']),
      comicId: serializer.fromJson<String>(json['comicId']),
      title: serializer.fromJson<String>(json['title']),
      coverUrl: serializer.fromJson<String>(json['coverUrl']),
      author: serializer.fromJson<String?>(json['author']),
      tags: serializer.fromJson<String?>(json['tags']),
      downloadedEpisodeIds:
          serializer.fromJson<String>(json['downloadedEpisodeIds']),
      pendingEpisodeIds: serializer.fromJson<String>(json['pendingEpisodeIds']),
      status: serializer.fromJson<String>(json['status']),
      totalEpisodes: serializer.fromJson<int>(json['totalEpisodes']),
      completedEpisodes: serializer.fromJson<int>(json['completedEpisodes']),
      currentEpisodeIndex:
          serializer.fromJson<int>(json['currentEpisodeIndex']),
      currentEpisodeId: serializer.fromJson<String?>(json['currentEpisodeId']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'comicId': serializer.toJson<String>(comicId),
      'title': serializer.toJson<String>(title),
      'coverUrl': serializer.toJson<String>(coverUrl),
      'author': serializer.toJson<String?>(author),
      'tags': serializer.toJson<String?>(tags),
      'downloadedEpisodeIds': serializer.toJson<String>(downloadedEpisodeIds),
      'pendingEpisodeIds': serializer.toJson<String>(pendingEpisodeIds),
      'status': serializer.toJson<String>(status),
      'totalEpisodes': serializer.toJson<int>(totalEpisodes),
      'completedEpisodes': serializer.toJson<int>(completedEpisodes),
      'currentEpisodeIndex': serializer.toJson<int>(currentEpisodeIndex),
      'currentEpisodeId': serializer.toJson<String?>(currentEpisodeId),
      'localPath': serializer.toJson<String?>(localPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  Download copyWith(
          {int? id,
          String? comicId,
          String? title,
          String? coverUrl,
          Value<String?> author = const Value.absent(),
          Value<String?> tags = const Value.absent(),
          String? downloadedEpisodeIds,
          String? pendingEpisodeIds,
          String? status,
          int? totalEpisodes,
          int? completedEpisodes,
          int? currentEpisodeIndex,
          Value<String?> currentEpisodeId = const Value.absent(),
          Value<String?> localPath = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent(),
          Value<DateTime?> completedAt = const Value.absent()}) =>
      Download(
        id: id ?? this.id,
        comicId: comicId ?? this.comicId,
        title: title ?? this.title,
        coverUrl: coverUrl ?? this.coverUrl,
        author: author.present ? author.value : this.author,
        tags: tags.present ? tags.value : this.tags,
        downloadedEpisodeIds: downloadedEpisodeIds ?? this.downloadedEpisodeIds,
        pendingEpisodeIds: pendingEpisodeIds ?? this.pendingEpisodeIds,
        status: status ?? this.status,
        totalEpisodes: totalEpisodes ?? this.totalEpisodes,
        completedEpisodes: completedEpisodes ?? this.completedEpisodes,
        currentEpisodeIndex: currentEpisodeIndex ?? this.currentEpisodeIndex,
        currentEpisodeId: currentEpisodeId.present
            ? currentEpisodeId.value
            : this.currentEpisodeId,
        localPath: localPath.present ? localPath.value : this.localPath,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
      );
  @override
  String toString() {
    return (StringBuffer('Download(')
          ..write('id: $id, ')
          ..write('comicId: $comicId, ')
          ..write('title: $title, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('author: $author, ')
          ..write('tags: $tags, ')
          ..write('downloadedEpisodeIds: $downloadedEpisodeIds, ')
          ..write('pendingEpisodeIds: $pendingEpisodeIds, ')
          ..write('status: $status, ')
          ..write('totalEpisodes: $totalEpisodes, ')
          ..write('completedEpisodes: $completedEpisodes, ')
          ..write('currentEpisodeIndex: $currentEpisodeIndex, ')
          ..write('currentEpisodeId: $currentEpisodeId, ')
          ..write('localPath: $localPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      comicId,
      title,
      coverUrl,
      author,
      tags,
      downloadedEpisodeIds,
      pendingEpisodeIds,
      status,
      totalEpisodes,
      completedEpisodes,
      currentEpisodeIndex,
      currentEpisodeId,
      localPath,
      createdAt,
      updatedAt,
      completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Download &&
          other.id == this.id &&
          other.comicId == this.comicId &&
          other.title == this.title &&
          other.coverUrl == this.coverUrl &&
          other.author == this.author &&
          other.tags == this.tags &&
          other.downloadedEpisodeIds == this.downloadedEpisodeIds &&
          other.pendingEpisodeIds == this.pendingEpisodeIds &&
          other.status == this.status &&
          other.totalEpisodes == this.totalEpisodes &&
          other.completedEpisodes == this.completedEpisodes &&
          other.currentEpisodeIndex == this.currentEpisodeIndex &&
          other.currentEpisodeId == this.currentEpisodeId &&
          other.localPath == this.localPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt);
}

class DownloadsCompanion extends UpdateCompanion<Download> {
  final Value<int> id;
  final Value<String> comicId;
  final Value<String> title;
  final Value<String> coverUrl;
  final Value<String?> author;
  final Value<String?> tags;
  final Value<String> downloadedEpisodeIds;
  final Value<String> pendingEpisodeIds;
  final Value<String> status;
  final Value<int> totalEpisodes;
  final Value<int> completedEpisodes;
  final Value<int> currentEpisodeIndex;
  final Value<String?> currentEpisodeId;
  final Value<String?> localPath;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> completedAt;
  const DownloadsCompanion({
    this.id = const Value.absent(),
    this.comicId = const Value.absent(),
    this.title = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.author = const Value.absent(),
    this.tags = const Value.absent(),
    this.downloadedEpisodeIds = const Value.absent(),
    this.pendingEpisodeIds = const Value.absent(),
    this.status = const Value.absent(),
    this.totalEpisodes = const Value.absent(),
    this.completedEpisodes = const Value.absent(),
    this.currentEpisodeIndex = const Value.absent(),
    this.currentEpisodeId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  DownloadsCompanion.insert({
    this.id = const Value.absent(),
    required String comicId,
    required String title,
    required String coverUrl,
    this.author = const Value.absent(),
    this.tags = const Value.absent(),
    required String downloadedEpisodeIds,
    required String pendingEpisodeIds,
    required String status,
    this.totalEpisodes = const Value.absent(),
    this.completedEpisodes = const Value.absent(),
    this.currentEpisodeIndex = const Value.absent(),
    this.currentEpisodeId = const Value.absent(),
    this.localPath = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  })  : comicId = Value(comicId),
        title = Value(title),
        coverUrl = Value(coverUrl),
        downloadedEpisodeIds = Value(downloadedEpisodeIds),
        pendingEpisodeIds = Value(pendingEpisodeIds),
        status = Value(status),
        createdAt = Value(createdAt);
  static Insertable<Download> custom({
    Expression<int>? id,
    Expression<String>? comicId,
    Expression<String>? title,
    Expression<String>? coverUrl,
    Expression<String>? author,
    Expression<String>? tags,
    Expression<String>? downloadedEpisodeIds,
    Expression<String>? pendingEpisodeIds,
    Expression<String>? status,
    Expression<int>? totalEpisodes,
    Expression<int>? completedEpisodes,
    Expression<int>? currentEpisodeIndex,
    Expression<String>? currentEpisodeId,
    Expression<String>? localPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (comicId != null) 'comic_id': comicId,
      if (title != null) 'title': title,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (author != null) 'author': author,
      if (tags != null) 'tags': tags,
      if (downloadedEpisodeIds != null)
        'downloaded_episode_ids': downloadedEpisodeIds,
      if (pendingEpisodeIds != null) 'pending_episode_ids': pendingEpisodeIds,
      if (status != null) 'status': status,
      if (totalEpisodes != null) 'total_episodes': totalEpisodes,
      if (completedEpisodes != null) 'completed_episodes': completedEpisodes,
      if (currentEpisodeIndex != null)
        'current_episode_index': currentEpisodeIndex,
      if (currentEpisodeId != null) 'current_episode_id': currentEpisodeId,
      if (localPath != null) 'local_path': localPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  DownloadsCompanion copyWith(
      {Value<int>? id,
      Value<String>? comicId,
      Value<String>? title,
      Value<String>? coverUrl,
      Value<String?>? author,
      Value<String?>? tags,
      Value<String>? downloadedEpisodeIds,
      Value<String>? pendingEpisodeIds,
      Value<String>? status,
      Value<int>? totalEpisodes,
      Value<int>? completedEpisodes,
      Value<int>? currentEpisodeIndex,
      Value<String?>? currentEpisodeId,
      Value<String?>? localPath,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<DateTime?>? completedAt}) {
    return DownloadsCompanion(
      id: id ?? this.id,
      comicId: comicId ?? this.comicId,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      author: author ?? this.author,
      tags: tags ?? this.tags,
      downloadedEpisodeIds: downloadedEpisodeIds ?? this.downloadedEpisodeIds,
      pendingEpisodeIds: pendingEpisodeIds ?? this.pendingEpisodeIds,
      status: status ?? this.status,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      completedEpisodes: completedEpisodes ?? this.completedEpisodes,
      currentEpisodeIndex: currentEpisodeIndex ?? this.currentEpisodeIndex,
      currentEpisodeId: currentEpisodeId ?? this.currentEpisodeId,
      localPath: localPath ?? this.localPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (comicId.present) {
      map['comic_id'] = Variable<String>(comicId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (downloadedEpisodeIds.present) {
      map['downloaded_episode_ids'] =
          Variable<String>(downloadedEpisodeIds.value);
    }
    if (pendingEpisodeIds.present) {
      map['pending_episode_ids'] = Variable<String>(pendingEpisodeIds.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalEpisodes.present) {
      map['total_episodes'] = Variable<int>(totalEpisodes.value);
    }
    if (completedEpisodes.present) {
      map['completed_episodes'] = Variable<int>(completedEpisodes.value);
    }
    if (currentEpisodeIndex.present) {
      map['current_episode_index'] = Variable<int>(currentEpisodeIndex.value);
    }
    if (currentEpisodeId.present) {
      map['current_episode_id'] = Variable<String>(currentEpisodeId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('id: $id, ')
          ..write('comicId: $comicId, ')
          ..write('title: $title, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('author: $author, ')
          ..write('tags: $tags, ')
          ..write('downloadedEpisodeIds: $downloadedEpisodeIds, ')
          ..write('pendingEpisodeIds: $pendingEpisodeIds, ')
          ..write('status: $status, ')
          ..write('totalEpisodes: $totalEpisodes, ')
          ..write('completedEpisodes: $completedEpisodes, ')
          ..write('currentEpisodeIndex: $currentEpisodeIndex, ')
          ..write('currentEpisodeId: $currentEpisodeId, ')
          ..write('localPath: $localPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $DownloadProgressTable extends DownloadProgress
    with TableInfo<$DownloadProgressTable, DownloadProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _downloadIdMeta =
      const VerificationMeta('downloadId');
  @override
  late final GeneratedColumn<int> downloadId = GeneratedColumn<int>(
      'download_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES downloads (id)'));
  static const VerificationMeta _episodeIdMeta =
      const VerificationMeta('episodeId');
  @override
  late final GeneratedColumn<String> episodeId = GeneratedColumn<String>(
      'episode_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _episodeTitleMeta =
      const VerificationMeta('episodeTitle');
  @override
  late final GeneratedColumn<String> episodeTitle = GeneratedColumn<String>(
      'episode_title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalPagesMeta =
      const VerificationMeta('totalPages');
  @override
  late final GeneratedColumn<int> totalPages = GeneratedColumn<int>(
      'total_pages', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _downloadedPagesMeta =
      const VerificationMeta('downloadedPages');
  @override
  late final GeneratedColumn<int> downloadedPages = GeneratedColumn<int>(
      'downloaded_pages', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _progressMeta =
      const VerificationMeta('progress');
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
      'progress', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        downloadId,
        episodeId,
        episodeTitle,
        totalPages,
        downloadedPages,
        status,
        progress,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_progress';
  @override
  VerificationContext validateIntegrity(
      Insertable<DownloadProgressData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('download_id')) {
      context.handle(
          _downloadIdMeta,
          downloadId.isAcceptableOrUnknown(
              data['download_id']!, _downloadIdMeta));
    } else if (isInserting) {
      context.missing(_downloadIdMeta);
    }
    if (data.containsKey('episode_id')) {
      context.handle(_episodeIdMeta,
          episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta));
    } else if (isInserting) {
      context.missing(_episodeIdMeta);
    }
    if (data.containsKey('episode_title')) {
      context.handle(
          _episodeTitleMeta,
          episodeTitle.isAcceptableOrUnknown(
              data['episode_title']!, _episodeTitleMeta));
    } else if (isInserting) {
      context.missing(_episodeTitleMeta);
    }
    if (data.containsKey('total_pages')) {
      context.handle(
          _totalPagesMeta,
          totalPages.isAcceptableOrUnknown(
              data['total_pages']!, _totalPagesMeta));
    }
    if (data.containsKey('downloaded_pages')) {
      context.handle(
          _downloadedPagesMeta,
          downloadedPages.isAcceptableOrUnknown(
              data['downloaded_pages']!, _downloadedPagesMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(_progressMeta,
          progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadProgressData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      downloadId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}download_id'])!,
      episodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}episode_id'])!,
      episodeTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}episode_title'])!,
      totalPages: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_pages'])!,
      downloadedPages: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}downloaded_pages'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}progress'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $DownloadProgressTable createAlias(String alias) {
    return $DownloadProgressTable(attachedDatabase, alias);
  }
}

class DownloadProgressData extends DataClass
    implements Insertable<DownloadProgressData> {
  final int id;
  final int downloadId;
  final String episodeId;
  final String episodeTitle;
  final int totalPages;
  final int downloadedPages;
  final String status;
  final int progress;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const DownloadProgressData(
      {required this.id,
      required this.downloadId,
      required this.episodeId,
      required this.episodeTitle,
      required this.totalPages,
      required this.downloadedPages,
      required this.status,
      required this.progress,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['download_id'] = Variable<int>(downloadId);
    map['episode_id'] = Variable<String>(episodeId);
    map['episode_title'] = Variable<String>(episodeTitle);
    map['total_pages'] = Variable<int>(totalPages);
    map['downloaded_pages'] = Variable<int>(downloadedPages);
    map['status'] = Variable<String>(status);
    map['progress'] = Variable<int>(progress);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  DownloadProgressCompanion toCompanion(bool nullToAbsent) {
    return DownloadProgressCompanion(
      id: Value(id),
      downloadId: Value(downloadId),
      episodeId: Value(episodeId),
      episodeTitle: Value(episodeTitle),
      totalPages: Value(totalPages),
      downloadedPages: Value(downloadedPages),
      status: Value(status),
      progress: Value(progress),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory DownloadProgressData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadProgressData(
      id: serializer.fromJson<int>(json['id']),
      downloadId: serializer.fromJson<int>(json['downloadId']),
      episodeId: serializer.fromJson<String>(json['episodeId']),
      episodeTitle: serializer.fromJson<String>(json['episodeTitle']),
      totalPages: serializer.fromJson<int>(json['totalPages']),
      downloadedPages: serializer.fromJson<int>(json['downloadedPages']),
      status: serializer.fromJson<String>(json['status']),
      progress: serializer.fromJson<int>(json['progress']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'downloadId': serializer.toJson<int>(downloadId),
      'episodeId': serializer.toJson<String>(episodeId),
      'episodeTitle': serializer.toJson<String>(episodeTitle),
      'totalPages': serializer.toJson<int>(totalPages),
      'downloadedPages': serializer.toJson<int>(downloadedPages),
      'status': serializer.toJson<String>(status),
      'progress': serializer.toJson<int>(progress),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  DownloadProgressData copyWith(
          {int? id,
          int? downloadId,
          String? episodeId,
          String? episodeTitle,
          int? totalPages,
          int? downloadedPages,
          String? status,
          int? progress,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      DownloadProgressData(
        id: id ?? this.id,
        downloadId: downloadId ?? this.downloadId,
        episodeId: episodeId ?? this.episodeId,
        episodeTitle: episodeTitle ?? this.episodeTitle,
        totalPages: totalPages ?? this.totalPages,
        downloadedPages: downloadedPages ?? this.downloadedPages,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  @override
  String toString() {
    return (StringBuffer('DownloadProgressData(')
          ..write('id: $id, ')
          ..write('downloadId: $downloadId, ')
          ..write('episodeId: $episodeId, ')
          ..write('episodeTitle: $episodeTitle, ')
          ..write('totalPages: $totalPages, ')
          ..write('downloadedPages: $downloadedPages, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, downloadId, episodeId, episodeTitle,
      totalPages, downloadedPages, status, progress, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadProgressData &&
          other.id == this.id &&
          other.downloadId == this.downloadId &&
          other.episodeId == this.episodeId &&
          other.episodeTitle == this.episodeTitle &&
          other.totalPages == this.totalPages &&
          other.downloadedPages == this.downloadedPages &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DownloadProgressCompanion extends UpdateCompanion<DownloadProgressData> {
  final Value<int> id;
  final Value<int> downloadId;
  final Value<String> episodeId;
  final Value<String> episodeTitle;
  final Value<int> totalPages;
  final Value<int> downloadedPages;
  final Value<String> status;
  final Value<int> progress;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  const DownloadProgressCompanion({
    this.id = const Value.absent(),
    this.downloadId = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.episodeTitle = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.downloadedPages = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DownloadProgressCompanion.insert({
    this.id = const Value.absent(),
    required int downloadId,
    required String episodeId,
    required String episodeTitle,
    this.totalPages = const Value.absent(),
    this.downloadedPages = const Value.absent(),
    required String status,
    this.progress = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
  })  : downloadId = Value(downloadId),
        episodeId = Value(episodeId),
        episodeTitle = Value(episodeTitle),
        status = Value(status),
        createdAt = Value(createdAt);
  static Insertable<DownloadProgressData> custom({
    Expression<int>? id,
    Expression<int>? downloadId,
    Expression<String>? episodeId,
    Expression<String>? episodeTitle,
    Expression<int>? totalPages,
    Expression<int>? downloadedPages,
    Expression<String>? status,
    Expression<int>? progress,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (downloadId != null) 'download_id': downloadId,
      if (episodeId != null) 'episode_id': episodeId,
      if (episodeTitle != null) 'episode_title': episodeTitle,
      if (totalPages != null) 'total_pages': totalPages,
      if (downloadedPages != null) 'downloaded_pages': downloadedPages,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DownloadProgressCompanion copyWith(
      {Value<int>? id,
      Value<int>? downloadId,
      Value<String>? episodeId,
      Value<String>? episodeTitle,
      Value<int>? totalPages,
      Value<int>? downloadedPages,
      Value<String>? status,
      Value<int>? progress,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt}) {
    return DownloadProgressCompanion(
      id: id ?? this.id,
      downloadId: downloadId ?? this.downloadId,
      episodeId: episodeId ?? this.episodeId,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      totalPages: totalPages ?? this.totalPages,
      downloadedPages: downloadedPages ?? this.downloadedPages,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (downloadId.present) {
      map['download_id'] = Variable<int>(downloadId.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<String>(episodeId.value);
    }
    if (episodeTitle.present) {
      map['episode_title'] = Variable<String>(episodeTitle.value);
    }
    if (totalPages.present) {
      map['total_pages'] = Variable<int>(totalPages.value);
    }
    if (downloadedPages.present) {
      map['downloaded_pages'] = Variable<int>(downloadedPages.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadProgressCompanion(')
          ..write('id: $id, ')
          ..write('downloadId: $downloadId, ')
          ..write('episodeId: $episodeId, ')
          ..write('episodeTitle: $episodeTitle, ')
          ..write('totalPages: $totalPages, ')
          ..write('downloadedPages: $downloadedPages, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SearchHistoryTable extends SearchHistory
    with TableInfo<$SearchHistoryTable, SearchHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _keywordMeta =
      const VerificationMeta('keyword');
  @override
  late final GeneratedColumn<String> keyword = GeneratedColumn<String>(
      'keyword', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _searchedAtMeta =
      const VerificationMeta('searchedAt');
  @override
  late final GeneratedColumn<DateTime> searchedAt = GeneratedColumn<DateTime>(
      'searched_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, keyword, searchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_history';
  @override
  VerificationContext validateIntegrity(Insertable<SearchHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('keyword')) {
      context.handle(_keywordMeta,
          keyword.isAcceptableOrUnknown(data['keyword']!, _keywordMeta));
    } else if (isInserting) {
      context.missing(_keywordMeta);
    }
    if (data.containsKey('searched_at')) {
      context.handle(
          _searchedAtMeta,
          searchedAt.isAcceptableOrUnknown(
              data['searched_at']!, _searchedAtMeta));
    } else if (isInserting) {
      context.missing(_searchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SearchHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchHistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      keyword: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}keyword'])!,
      searchedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}searched_at'])!,
    );
  }

  @override
  $SearchHistoryTable createAlias(String alias) {
    return $SearchHistoryTable(attachedDatabase, alias);
  }
}

class SearchHistoryData extends DataClass
    implements Insertable<SearchHistoryData> {
  final int id;
  final String keyword;
  final DateTime searchedAt;
  const SearchHistoryData(
      {required this.id, required this.keyword, required this.searchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['keyword'] = Variable<String>(keyword);
    map['searched_at'] = Variable<DateTime>(searchedAt);
    return map;
  }

  SearchHistoryCompanion toCompanion(bool nullToAbsent) {
    return SearchHistoryCompanion(
      id: Value(id),
      keyword: Value(keyword),
      searchedAt: Value(searchedAt),
    );
  }

  factory SearchHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchHistoryData(
      id: serializer.fromJson<int>(json['id']),
      keyword: serializer.fromJson<String>(json['keyword']),
      searchedAt: serializer.fromJson<DateTime>(json['searchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'keyword': serializer.toJson<String>(keyword),
      'searchedAt': serializer.toJson<DateTime>(searchedAt),
    };
  }

  SearchHistoryData copyWith(
          {int? id, String? keyword, DateTime? searchedAt}) =>
      SearchHistoryData(
        id: id ?? this.id,
        keyword: keyword ?? this.keyword,
        searchedAt: searchedAt ?? this.searchedAt,
      );
  @override
  String toString() {
    return (StringBuffer('SearchHistoryData(')
          ..write('id: $id, ')
          ..write('keyword: $keyword, ')
          ..write('searchedAt: $searchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, keyword, searchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHistoryData &&
          other.id == this.id &&
          other.keyword == this.keyword &&
          other.searchedAt == this.searchedAt);
}

class SearchHistoryCompanion extends UpdateCompanion<SearchHistoryData> {
  final Value<int> id;
  final Value<String> keyword;
  final Value<DateTime> searchedAt;
  const SearchHistoryCompanion({
    this.id = const Value.absent(),
    this.keyword = const Value.absent(),
    this.searchedAt = const Value.absent(),
  });
  SearchHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String keyword,
    required DateTime searchedAt,
  })  : keyword = Value(keyword),
        searchedAt = Value(searchedAt);
  static Insertable<SearchHistoryData> custom({
    Expression<int>? id,
    Expression<String>? keyword,
    Expression<DateTime>? searchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (keyword != null) 'keyword': keyword,
      if (searchedAt != null) 'searched_at': searchedAt,
    });
  }

  SearchHistoryCompanion copyWith(
      {Value<int>? id, Value<String>? keyword, Value<DateTime>? searchedAt}) {
    return SearchHistoryCompanion(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      searchedAt: searchedAt ?? this.searchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (keyword.present) {
      map['keyword'] = Variable<String>(keyword.value);
    }
    if (searchedAt.present) {
      map['searched_at'] = Variable<DateTime>(searchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryCompanion(')
          ..write('id: $id, ')
          ..write('keyword: $keyword, ')
          ..write('searchedAt: $searchedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $ComicsTable comics = $ComicsTable(this);
  late final $EpisodesTable episodes = $EpisodesTable(this);
  late final $HistoryTable history = $HistoryTable(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  late final $DownloadProgressTable downloadProgress =
      $DownloadProgressTable(this);
  late final $SearchHistoryTable searchHistory = $SearchHistoryTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [comics, episodes, history, downloads, downloadProgress, searchHistory];
}
