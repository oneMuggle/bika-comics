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
  Comic copyWithCompanion(ComicsCompanion data) {
    return Comic(
      id: data.id.present ? data.id.value : this.id,
      comicId: data.comicId.present ? data.comicId.value : this.comicId,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      description:
          data.description.present ? data.description.value : this.description,
      episodeCount: data.episodeCount.present
          ? data.episodeCount.value
          : this.episodeCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      isFollowed:
          data.isFollowed.present ? data.isFollowed.value : this.isFollowed,
    );
  }

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
  Episode copyWithCompanion(EpisodesCompanion data) {
    return Episode(
      id: data.id.present ? data.id.value : this.id,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      comicId: data.comicId.present ? data.comicId.value : this.comicId,
      title: data.title.present ? data.title.value : this.title,
      order: data.order.present ? data.order.value : this.order,
      publishedAt:
          data.publishedAt.present ? data.publishedAt.value : this.publishedAt,
    );
  }

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
  HistoryData copyWithCompanion(HistoryCompanion data) {
    return HistoryData(
      id: data.id.present ? data.id.value : this.id,
      comicId: data.comicId.present ? data.comicId.value : this.comicId,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      lastPage: data.lastPage.present ? data.lastPage.value : this.lastPage,
      lastReadAt:
          data.lastReadAt.present ? data.lastReadAt.value : this.lastReadAt,
    );
  }

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
        episodeId,
        status,
        progress,
        localPath,
        createdAt,
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
    if (data.containsKey('episode_id')) {
      context.handle(_episodeIdMeta,
          episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta));
    } else if (isInserting) {
      context.missing(_episodeIdMeta);
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
          .read(DriftSqlType.int, data['${effectivePrefix}comic_id'])!,
      episodeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}episode_id'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}progress'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
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
  final int comicId;
  final int episodeId;
  final String status;
  final int progress;
  final String? localPath;
  final DateTime createdAt;
  final DateTime? completedAt;
  const Download(
      {required this.id,
      required this.comicId,
      required this.episodeId,
      required this.status,
      required this.progress,
      this.localPath,
      required this.createdAt,
      this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['comic_id'] = Variable<int>(comicId);
    map['episode_id'] = Variable<int>(episodeId);
    map['status'] = Variable<String>(status);
    map['progress'] = Variable<int>(progress);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      id: Value(id),
      comicId: Value(comicId),
      episodeId: Value(episodeId),
      status: Value(status),
      progress: Value(progress),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      createdAt: Value(createdAt),
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
      comicId: serializer.fromJson<int>(json['comicId']),
      episodeId: serializer.fromJson<int>(json['episodeId']),
      status: serializer.fromJson<String>(json['status']),
      progress: serializer.fromJson<int>(json['progress']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'comicId': serializer.toJson<int>(comicId),
      'episodeId': serializer.toJson<int>(episodeId),
      'status': serializer.toJson<String>(status),
      'progress': serializer.toJson<int>(progress),
      'localPath': serializer.toJson<String?>(localPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  Download copyWith(
          {int? id,
          int? comicId,
          int? episodeId,
          String? status,
          int? progress,
          Value<String?> localPath = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> completedAt = const Value.absent()}) =>
      Download(
        id: id ?? this.id,
        comicId: comicId ?? this.comicId,
        episodeId: episodeId ?? this.episodeId,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        localPath: localPath.present ? localPath.value : this.localPath,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
      );
  Download copyWithCompanion(DownloadsCompanion data) {
    return Download(
      id: data.id.present ? data.id.value : this.id,
      comicId: data.comicId.present ? data.comicId.value : this.comicId,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Download(')
          ..write('id: $id, ')
          ..write('comicId: $comicId, ')
          ..write('episodeId: $episodeId, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('localPath: $localPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, comicId, episodeId, status, progress,
      localPath, createdAt, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Download &&
          other.id == this.id &&
          other.comicId == this.comicId &&
          other.episodeId == this.episodeId &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.localPath == this.localPath &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt);
}

class DownloadsCompanion extends UpdateCompanion<Download> {
  final Value<int> id;
  final Value<int> comicId;
  final Value<int> episodeId;
  final Value<String> status;
  final Value<int> progress;
  final Value<String?> localPath;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  const DownloadsCompanion({
    this.id = const Value.absent(),
    this.comicId = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.localPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  DownloadsCompanion.insert({
    this.id = const Value.absent(),
    required int comicId,
    required int episodeId,
    required String status,
    this.progress = const Value.absent(),
    this.localPath = const Value.absent(),
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
  })  : comicId = Value(comicId),
        episodeId = Value(episodeId),
        status = Value(status),
        createdAt = Value(createdAt);
  static Insertable<Download> custom({
    Expression<int>? id,
    Expression<int>? comicId,
    Expression<int>? episodeId,
    Expression<String>? status,
    Expression<int>? progress,
    Expression<String>? localPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (comicId != null) 'comic_id': comicId,
      if (episodeId != null) 'episode_id': episodeId,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (localPath != null) 'local_path': localPath,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  DownloadsCompanion copyWith(
      {Value<int>? id,
      Value<int>? comicId,
      Value<int>? episodeId,
      Value<String>? status,
      Value<int>? progress,
      Value<String?>? localPath,
      Value<DateTime>? createdAt,
      Value<DateTime?>? completedAt}) {
    return DownloadsCompanion(
      id: id ?? this.id,
      comicId: comicId ?? this.comicId,
      episodeId: episodeId ?? this.episodeId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      localPath: localPath ?? this.localPath,
      createdAt: createdAt ?? this.createdAt,
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
      map['comic_id'] = Variable<int>(comicId.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<int>(episodeId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
          ..write('episodeId: $episodeId, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('localPath: $localPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
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
  SearchHistoryData copyWithCompanion(SearchHistoryCompanion data) {
    return SearchHistoryData(
      id: data.id.present ? data.id.value : this.id,
      keyword: data.keyword.present ? data.keyword.value : this.keyword,
      searchedAt:
          data.searchedAt.present ? data.searchedAt.value : this.searchedAt,
    );
  }

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
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ComicsTable comics = $ComicsTable(this);
  late final $EpisodesTable episodes = $EpisodesTable(this);
  late final $HistoryTable history = $HistoryTable(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  late final $SearchHistoryTable searchHistory = $SearchHistoryTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [comics, episodes, history, downloads, searchHistory];
}

typedef $$ComicsTableCreateCompanionBuilder = ComicsCompanion Function({
  Value<int> id,
  required String comicId,
  required String title,
  Value<String?> author,
  required String coverUrl,
  Value<String?> description,
  Value<int> episodeCount,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<bool> isFavorite,
  Value<bool> isFollowed,
});
typedef $$ComicsTableUpdateCompanionBuilder = ComicsCompanion Function({
  Value<int> id,
  Value<String> comicId,
  Value<String> title,
  Value<String?> author,
  Value<String> coverUrl,
  Value<String?> description,
  Value<int> episodeCount,
  Value<DateTime?> createdAt,
  Value<DateTime?> updatedAt,
  Value<bool> isFavorite,
  Value<bool> isFollowed,
});

final class $$ComicsTableReferences
    extends BaseReferences<_$AppDatabase, $ComicsTable, Comic> {
  $$ComicsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EpisodesTable, List<Episode>> _episodesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.episodes,
          aliasName: $_aliasNameGenerator(db.comics.id, db.episodes.comicId));

  $$EpisodesTableProcessedTableManager get episodesRefs {
    final manager = $$EpisodesTableTableManager($_db, $_db.episodes)
        .filter((f) => f.comicId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_episodesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$HistoryTable, List<HistoryData>>
      _historyRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.history,
          aliasName: $_aliasNameGenerator(db.comics.id, db.history.comicId));

  $$HistoryTableProcessedTableManager get historyRefs {
    final manager = $$HistoryTableTableManager($_db, $_db.history)
        .filter((f) => f.comicId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_historyRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$DownloadsTable, List<Download>>
      _downloadsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.downloads,
          aliasName: $_aliasNameGenerator(db.comics.id, db.downloads.comicId));

  $$DownloadsTableProcessedTableManager get downloadsRefs {
    final manager = $$DownloadsTableTableManager($_db, $_db.downloads)
        .filter((f) => f.comicId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_downloadsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ComicsTableFilterComposer
    extends Composer<_$AppDatabase, $ComicsTable> {
  $$ComicsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get comicId => $composableBuilder(
      column: $table.comicId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get author => $composableBuilder(
      column: $table.author, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get episodeCount => $composableBuilder(
      column: $table.episodeCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFollowed => $composableBuilder(
      column: $table.isFollowed, builder: (column) => ColumnFilters(column));

  Expression<bool> episodesRefs(
      Expression<bool> Function($$EpisodesTableFilterComposer f) f) {
    final $$EpisodesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.episodes,
        getReferencedColumn: (t) => t.comicId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EpisodesTableFilterComposer(
              $db: $db,
              $table: $db.episodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> historyRefs(
      Expression<bool> Function($$HistoryTableFilterComposer f) f) {
    final $$HistoryTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.history,
        getReferencedColumn: (t) => t.comicId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HistoryTableFilterComposer(
              $db: $db,
              $table: $db.history,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> downloadsRefs(
      Expression<bool> Function($$DownloadsTableFilterComposer f) f) {
    final $$DownloadsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.downloads,
        getReferencedColumn: (t) => t.comicId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DownloadsTableFilterComposer(
              $db: $db,
              $table: $db.downloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ComicsTableOrderingComposer
    extends Composer<_$AppDatabase, $ComicsTable> {
  $$ComicsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get comicId => $composableBuilder(
      column: $table.comicId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get author => $composableBuilder(
      column: $table.author, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverUrl => $composableBuilder(
      column: $table.coverUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get episodeCount => $composableBuilder(
      column: $table.episodeCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFollowed => $composableBuilder(
      column: $table.isFollowed, builder: (column) => ColumnOrderings(column));
}

class $$ComicsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ComicsTable> {
  $$ComicsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get comicId =>
      $composableBuilder(column: $table.comicId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<int> get episodeCount => $composableBuilder(
      column: $table.episodeCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<bool> get isFollowed => $composableBuilder(
      column: $table.isFollowed, builder: (column) => column);

  Expression<T> episodesRefs<T extends Object>(
      Expression<T> Function($$EpisodesTableAnnotationComposer a) f) {
    final $$EpisodesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.episodes,
        getReferencedColumn: (t) => t.comicId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EpisodesTableAnnotationComposer(
              $db: $db,
              $table: $db.episodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> historyRefs<T extends Object>(
      Expression<T> Function($$HistoryTableAnnotationComposer a) f) {
    final $$HistoryTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.history,
        getReferencedColumn: (t) => t.comicId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HistoryTableAnnotationComposer(
              $db: $db,
              $table: $db.history,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> downloadsRefs<T extends Object>(
      Expression<T> Function($$DownloadsTableAnnotationComposer a) f) {
    final $$DownloadsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.downloads,
        getReferencedColumn: (t) => t.comicId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DownloadsTableAnnotationComposer(
              $db: $db,
              $table: $db.downloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ComicsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ComicsTable,
    Comic,
    $$ComicsTableFilterComposer,
    $$ComicsTableOrderingComposer,
    $$ComicsTableAnnotationComposer,
    $$ComicsTableCreateCompanionBuilder,
    $$ComicsTableUpdateCompanionBuilder,
    (Comic, $$ComicsTableReferences),
    Comic,
    PrefetchHooks Function(
        {bool episodesRefs, bool historyRefs, bool downloadsRefs})> {
  $$ComicsTableTableManager(_$AppDatabase db, $ComicsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ComicsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ComicsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ComicsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> comicId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> author = const Value.absent(),
            Value<String> coverUrl = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<int> episodeCount = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<bool> isFollowed = const Value.absent(),
          }) =>
              ComicsCompanion(
            id: id,
            comicId: comicId,
            title: title,
            author: author,
            coverUrl: coverUrl,
            description: description,
            episodeCount: episodeCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isFavorite: isFavorite,
            isFollowed: isFollowed,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String comicId,
            required String title,
            Value<String?> author = const Value.absent(),
            required String coverUrl,
            Value<String?> description = const Value.absent(),
            Value<int> episodeCount = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<bool> isFollowed = const Value.absent(),
          }) =>
              ComicsCompanion.insert(
            id: id,
            comicId: comicId,
            title: title,
            author: author,
            coverUrl: coverUrl,
            description: description,
            episodeCount: episodeCount,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isFavorite: isFavorite,
            isFollowed: isFollowed,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ComicsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {episodesRefs = false,
              historyRefs = false,
              downloadsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (episodesRefs) db.episodes,
                if (historyRefs) db.history,
                if (downloadsRefs) db.downloads
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (episodesRefs)
                    await $_getPrefetchedData<Comic, $ComicsTable, Episode>(
                        currentTable: table,
                        referencedTable:
                            $$ComicsTableReferences._episodesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ComicsTableReferences(db, table, p0).episodesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.comicId == item.id),
                        typedResults: items),
                  if (historyRefs)
                    await $_getPrefetchedData<Comic, $ComicsTable, HistoryData>(
                        currentTable: table,
                        referencedTable:
                            $$ComicsTableReferences._historyRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ComicsTableReferences(db, table, p0).historyRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.comicId == item.id),
                        typedResults: items),
                  if (downloadsRefs)
                    await $_getPrefetchedData<Comic, $ComicsTable, Download>(
                        currentTable: table,
                        referencedTable:
                            $$ComicsTableReferences._downloadsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ComicsTableReferences(db, table, p0)
                                .downloadsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.comicId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ComicsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ComicsTable,
    Comic,
    $$ComicsTableFilterComposer,
    $$ComicsTableOrderingComposer,
    $$ComicsTableAnnotationComposer,
    $$ComicsTableCreateCompanionBuilder,
    $$ComicsTableUpdateCompanionBuilder,
    (Comic, $$ComicsTableReferences),
    Comic,
    PrefetchHooks Function(
        {bool episodesRefs, bool historyRefs, bool downloadsRefs})>;
typedef $$EpisodesTableCreateCompanionBuilder = EpisodesCompanion Function({
  Value<int> id,
  required String episodeId,
  required int comicId,
  required String title,
  required int order,
  Value<DateTime?> publishedAt,
});
typedef $$EpisodesTableUpdateCompanionBuilder = EpisodesCompanion Function({
  Value<int> id,
  Value<String> episodeId,
  Value<int> comicId,
  Value<String> title,
  Value<int> order,
  Value<DateTime?> publishedAt,
});

final class $$EpisodesTableReferences
    extends BaseReferences<_$AppDatabase, $EpisodesTable, Episode> {
  $$EpisodesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ComicsTable _comicIdTable(_$AppDatabase db) => db.comics
      .createAlias($_aliasNameGenerator(db.episodes.comicId, db.comics.id));

  $$ComicsTableProcessedTableManager get comicId {
    final $_column = $_itemColumn<int>('comic_id')!;

    final manager = $$ComicsTableTableManager($_db, $_db.comics)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_comicIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$HistoryTable, List<HistoryData>>
      _historyRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.history,
              aliasName:
                  $_aliasNameGenerator(db.episodes.id, db.history.episodeId));

  $$HistoryTableProcessedTableManager get historyRefs {
    final manager = $$HistoryTableTableManager($_db, $_db.history)
        .filter((f) => f.episodeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_historyRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$DownloadsTable, List<Download>>
      _downloadsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.downloads,
              aliasName:
                  $_aliasNameGenerator(db.episodes.id, db.downloads.episodeId));

  $$DownloadsTableProcessedTableManager get downloadsRefs {
    final manager = $$DownloadsTableTableManager($_db, $_db.downloads)
        .filter((f) => f.episodeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_downloadsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$EpisodesTableFilterComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get episodeId => $composableBuilder(
      column: $table.episodeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get order => $composableBuilder(
      column: $table.order, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get publishedAt => $composableBuilder(
      column: $table.publishedAt, builder: (column) => ColumnFilters(column));

  $$ComicsTableFilterComposer get comicId {
    final $$ComicsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.comicId,
        referencedTable: $db.comics,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ComicsTableFilterComposer(
              $db: $db,
              $table: $db.comics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> historyRefs(
      Expression<bool> Function($$HistoryTableFilterComposer f) f) {
    final $$HistoryTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.history,
        getReferencedColumn: (t) => t.episodeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HistoryTableFilterComposer(
              $db: $db,
              $table: $db.history,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> downloadsRefs(
      Expression<bool> Function($$DownloadsTableFilterComposer f) f) {
    final $$DownloadsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.downloads,
        getReferencedColumn: (t) => t.episodeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DownloadsTableFilterComposer(
              $db: $db,
              $table: $db.downloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EpisodesTableOrderingComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get episodeId => $composableBuilder(
      column: $table.episodeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get order => $composableBuilder(
      column: $table.order, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get publishedAt => $composableBuilder(
      column: $table.publishedAt, builder: (column) => ColumnOrderings(column));

  $$ComicsTableOrderingComposer get comicId {
    final $$ComicsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.comicId,
        referencedTable: $db.comics,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ComicsTableOrderingComposer(
              $db: $db,
              $table: $db.comics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$EpisodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get episodeId =>
      $composableBuilder(column: $table.episodeId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get order =>
      $composableBuilder(column: $table.order, builder: (column) => column);

  GeneratedColumn<DateTime> get publishedAt => $composableBuilder(
      column: $table.publishedAt, builder: (column) => column);

  $$ComicsTableAnnotationComposer get comicId {
    final $$ComicsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.comicId,
        referencedTable: $db.comics,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ComicsTableAnnotationComposer(
              $db: $db,
              $table: $db.comics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> historyRefs<T extends Object>(
      Expression<T> Function($$HistoryTableAnnotationComposer a) f) {
    final $$HistoryTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.history,
        getReferencedColumn: (t) => t.episodeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HistoryTableAnnotationComposer(
              $db: $db,
              $table: $db.history,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> downloadsRefs<T extends Object>(
      Expression<T> Function($$DownloadsTableAnnotationComposer a) f) {
    final $$DownloadsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.downloads,
        getReferencedColumn: (t) => t.episodeId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DownloadsTableAnnotationComposer(
              $db: $db,
              $table: $db.downloads,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$EpisodesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EpisodesTable,
    Episode,
    $$EpisodesTableFilterComposer,
    $$EpisodesTableOrderingComposer,
    $$EpisodesTableAnnotationComposer,
    $$EpisodesTableCreateCompanionBuilder,
    $$EpisodesTableUpdateCompanionBuilder,
    (Episode, $$EpisodesTableReferences),
    Episode,
    PrefetchHooks Function(
        {bool comicId, bool historyRefs, bool downloadsRefs})> {
  $$EpisodesTableTableManager(_$AppDatabase db, $EpisodesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> episodeId = const Value.absent(),
            Value<int> comicId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int> order = const Value.absent(),
            Value<DateTime?> publishedAt = const Value.absent(),
          }) =>
              EpisodesCompanion(
            id: id,
            episodeId: episodeId,
            comicId: comicId,
            title: title,
            order: order,
            publishedAt: publishedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String episodeId,
            required int comicId,
            required String title,
            required int order,
            Value<DateTime?> publishedAt = const Value.absent(),
          }) =>
              EpisodesCompanion.insert(
            id: id,
            episodeId: episodeId,
            comicId: comicId,
            title: title,
            order: order,
            publishedAt: publishedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$EpisodesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {comicId = false, historyRefs = false, downloadsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (historyRefs) db.history,
                if (downloadsRefs) db.downloads
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (comicId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.comicId,
                    referencedTable:
                        $$EpisodesTableReferences._comicIdTable(db),
                    referencedColumn:
                        $$EpisodesTableReferences._comicIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (historyRefs)
                    await $_getPrefetchedData<Episode, $EpisodesTable,
                            HistoryData>(
                        currentTable: table,
                        referencedTable:
                            $$EpisodesTableReferences._historyRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EpisodesTableReferences(db, table, p0)
                                .historyRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.episodeId == item.id),
                        typedResults: items),
                  if (downloadsRefs)
                    await $_getPrefetchedData<Episode, $EpisodesTable,
                            Download>(
                        currentTable: table,
                        referencedTable:
                            $$EpisodesTableReferences._downloadsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$EpisodesTableReferences(db, table, p0)
                                .downloadsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.episodeId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$EpisodesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EpisodesTable,
    Episode,
    $$EpisodesTableFilterComposer,
    $$EpisodesTableOrderingComposer,
    $$EpisodesTableAnnotationComposer,
    $$EpisodesTableCreateCompanionBuilder,
    $$EpisodesTableUpdateCompanionBuilder,
    (Episode, $$EpisodesTableReferences),
    Episode,
    PrefetchHooks Function(
        {bool comicId, bool historyRefs, bool downloadsRefs})>;
typedef $$HistoryTableCreateCompanionBuilder = HistoryCompanion Function({
  Value<int> id,
  required int comicId,
  required int episodeId,
  Value<int> lastPage,
  required DateTime lastReadAt,
});
typedef $$HistoryTableUpdateCompanionBuilder = HistoryCompanion Function({
  Value<int> id,
  Value<int> comicId,
  Value<int> episodeId,
  Value<int> lastPage,
  Value<DateTime> lastReadAt,
});

final class $$HistoryTableReferences
    extends BaseReferences<_$AppDatabase, $HistoryTable, HistoryData> {
  $$HistoryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ComicsTable _comicIdTable(_$AppDatabase db) => db.comics
      .createAlias($_aliasNameGenerator(db.history.comicId, db.comics.id));

  $$ComicsTableProcessedTableManager get comicId {
    final $_column = $_itemColumn<int>('comic_id')!;

    final manager = $$ComicsTableTableManager($_db, $_db.comics)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_comicIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EpisodesTable _episodeIdTable(_$AppDatabase db) => db.episodes
      .createAlias($_aliasNameGenerator(db.history.episodeId, db.episodes.id));

  $$EpisodesTableProcessedTableManager get episodeId {
    final $_column = $_itemColumn<int>('episode_id')!;

    final manager = $$EpisodesTableTableManager($_db, $_db.episodes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_episodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$HistoryTableFilterComposer
    extends Composer<_$AppDatabase, $HistoryTable> {
  $$HistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastPage => $composableBuilder(
      column: $table.lastPage, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastReadAt => $composableBuilder(
      column: $table.lastReadAt, builder: (column) => ColumnFilters(column));

  $$ComicsTableFilterComposer get comicId {
    final $$ComicsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.comicId,
        referencedTable: $db.comics,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ComicsTableFilterComposer(
              $db: $db,
              $table: $db.comics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EpisodesTableFilterComposer get episodeId {
    final $$EpisodesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.episodeId,
        referencedTable: $db.episodes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EpisodesTableFilterComposer(
              $db: $db,
              $table: $db.episodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $HistoryTable> {
  $$HistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastPage => $composableBuilder(
      column: $table.lastPage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastReadAt => $composableBuilder(
      column: $table.lastReadAt, builder: (column) => ColumnOrderings(column));

  $$ComicsTableOrderingComposer get comicId {
    final $$ComicsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.comicId,
        referencedTable: $db.comics,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ComicsTableOrderingComposer(
              $db: $db,
              $table: $db.comics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EpisodesTableOrderingComposer get episodeId {
    final $$EpisodesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.episodeId,
        referencedTable: $db.episodes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EpisodesTableOrderingComposer(
              $db: $db,
              $table: $db.episodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $HistoryTable> {
  $$HistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lastPage =>
      $composableBuilder(column: $table.lastPage, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReadAt => $composableBuilder(
      column: $table.lastReadAt, builder: (column) => column);

  $$ComicsTableAnnotationComposer get comicId {
    final $$ComicsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.comicId,
        referencedTable: $db.comics,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ComicsTableAnnotationComposer(
              $db: $db,
              $table: $db.comics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EpisodesTableAnnotationComposer get episodeId {
    final $$EpisodesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.episodeId,
        referencedTable: $db.episodes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EpisodesTableAnnotationComposer(
              $db: $db,
              $table: $db.episodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HistoryTable,
    HistoryData,
    $$HistoryTableFilterComposer,
    $$HistoryTableOrderingComposer,
    $$HistoryTableAnnotationComposer,
    $$HistoryTableCreateCompanionBuilder,
    $$HistoryTableUpdateCompanionBuilder,
    (HistoryData, $$HistoryTableReferences),
    HistoryData,
    PrefetchHooks Function({bool comicId, bool episodeId})> {
  $$HistoryTableTableManager(_$AppDatabase db, $HistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> comicId = const Value.absent(),
            Value<int> episodeId = const Value.absent(),
            Value<int> lastPage = const Value.absent(),
            Value<DateTime> lastReadAt = const Value.absent(),
          }) =>
              HistoryCompanion(
            id: id,
            comicId: comicId,
            episodeId: episodeId,
            lastPage: lastPage,
            lastReadAt: lastReadAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int comicId,
            required int episodeId,
            Value<int> lastPage = const Value.absent(),
            required DateTime lastReadAt,
          }) =>
              HistoryCompanion.insert(
            id: id,
            comicId: comicId,
            episodeId: episodeId,
            lastPage: lastPage,
            lastReadAt: lastReadAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$HistoryTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({comicId = false, episodeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (comicId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.comicId,
                    referencedTable: $$HistoryTableReferences._comicIdTable(db),
                    referencedColumn:
                        $$HistoryTableReferences._comicIdTable(db).id,
                  ) as T;
                }
                if (episodeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.episodeId,
                    referencedTable:
                        $$HistoryTableReferences._episodeIdTable(db),
                    referencedColumn:
                        $$HistoryTableReferences._episodeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$HistoryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HistoryTable,
    HistoryData,
    $$HistoryTableFilterComposer,
    $$HistoryTableOrderingComposer,
    $$HistoryTableAnnotationComposer,
    $$HistoryTableCreateCompanionBuilder,
    $$HistoryTableUpdateCompanionBuilder,
    (HistoryData, $$HistoryTableReferences),
    HistoryData,
    PrefetchHooks Function({bool comicId, bool episodeId})>;
typedef $$DownloadsTableCreateCompanionBuilder = DownloadsCompanion Function({
  Value<int> id,
  required int comicId,
  required int episodeId,
  required String status,
  Value<int> progress,
  Value<String?> localPath,
  required DateTime createdAt,
  Value<DateTime?> completedAt,
});
typedef $$DownloadsTableUpdateCompanionBuilder = DownloadsCompanion Function({
  Value<int> id,
  Value<int> comicId,
  Value<int> episodeId,
  Value<String> status,
  Value<int> progress,
  Value<String?> localPath,
  Value<DateTime> createdAt,
  Value<DateTime?> completedAt,
});

final class $$DownloadsTableReferences
    extends BaseReferences<_$AppDatabase, $DownloadsTable, Download> {
  $$DownloadsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ComicsTable _comicIdTable(_$AppDatabase db) => db.comics
      .createAlias($_aliasNameGenerator(db.downloads.comicId, db.comics.id));

  $$ComicsTableProcessedTableManager get comicId {
    final $_column = $_itemColumn<int>('comic_id')!;

    final manager = $$ComicsTableTableManager($_db, $_db.comics)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_comicIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $EpisodesTable _episodeIdTable(_$AppDatabase db) =>
      db.episodes.createAlias(
          $_aliasNameGenerator(db.downloads.episodeId, db.episodes.id));

  $$EpisodesTableProcessedTableManager get episodeId {
    final $_column = $_itemColumn<int>('episode_id')!;

    final manager = $$EpisodesTableTableManager($_db, $_db.episodes)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_episodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DownloadsTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  $$ComicsTableFilterComposer get comicId {
    final $$ComicsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.comicId,
        referencedTable: $db.comics,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ComicsTableFilterComposer(
              $db: $db,
              $table: $db.comics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EpisodesTableFilterComposer get episodeId {
    final $$EpisodesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.episodeId,
        referencedTable: $db.episodes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EpisodesTableFilterComposer(
              $db: $db,
              $table: $db.episodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DownloadsTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  $$ComicsTableOrderingComposer get comicId {
    final $$ComicsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.comicId,
        referencedTable: $db.comics,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ComicsTableOrderingComposer(
              $db: $db,
              $table: $db.comics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EpisodesTableOrderingComposer get episodeId {
    final $$EpisodesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.episodeId,
        referencedTable: $db.episodes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EpisodesTableOrderingComposer(
              $db: $db,
              $table: $db.episodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DownloadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  $$ComicsTableAnnotationComposer get comicId {
    final $$ComicsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.comicId,
        referencedTable: $db.comics,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ComicsTableAnnotationComposer(
              $db: $db,
              $table: $db.comics,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$EpisodesTableAnnotationComposer get episodeId {
    final $$EpisodesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.episodeId,
        referencedTable: $db.episodes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$EpisodesTableAnnotationComposer(
              $db: $db,
              $table: $db.episodes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DownloadsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DownloadsTable,
    Download,
    $$DownloadsTableFilterComposer,
    $$DownloadsTableOrderingComposer,
    $$DownloadsTableAnnotationComposer,
    $$DownloadsTableCreateCompanionBuilder,
    $$DownloadsTableUpdateCompanionBuilder,
    (Download, $$DownloadsTableReferences),
    Download,
    PrefetchHooks Function({bool comicId, bool episodeId})> {
  $$DownloadsTableTableManager(_$AppDatabase db, $DownloadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> comicId = const Value.absent(),
            Value<int> episodeId = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> progress = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
          }) =>
              DownloadsCompanion(
            id: id,
            comicId: comicId,
            episodeId: episodeId,
            status: status,
            progress: progress,
            localPath: localPath,
            createdAt: createdAt,
            completedAt: completedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int comicId,
            required int episodeId,
            required String status,
            Value<int> progress = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> completedAt = const Value.absent(),
          }) =>
              DownloadsCompanion.insert(
            id: id,
            comicId: comicId,
            episodeId: episodeId,
            status: status,
            progress: progress,
            localPath: localPath,
            createdAt: createdAt,
            completedAt: completedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DownloadsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({comicId = false, episodeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (comicId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.comicId,
                    referencedTable:
                        $$DownloadsTableReferences._comicIdTable(db),
                    referencedColumn:
                        $$DownloadsTableReferences._comicIdTable(db).id,
                  ) as T;
                }
                if (episodeId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.episodeId,
                    referencedTable:
                        $$DownloadsTableReferences._episodeIdTable(db),
                    referencedColumn:
                        $$DownloadsTableReferences._episodeIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DownloadsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DownloadsTable,
    Download,
    $$DownloadsTableFilterComposer,
    $$DownloadsTableOrderingComposer,
    $$DownloadsTableAnnotationComposer,
    $$DownloadsTableCreateCompanionBuilder,
    $$DownloadsTableUpdateCompanionBuilder,
    (Download, $$DownloadsTableReferences),
    Download,
    PrefetchHooks Function({bool comicId, bool episodeId})>;
typedef $$SearchHistoryTableCreateCompanionBuilder = SearchHistoryCompanion
    Function({
  Value<int> id,
  required String keyword,
  required DateTime searchedAt,
});
typedef $$SearchHistoryTableUpdateCompanionBuilder = SearchHistoryCompanion
    Function({
  Value<int> id,
  Value<String> keyword,
  Value<DateTime> searchedAt,
});

class $$SearchHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keyword => $composableBuilder(
      column: $table.keyword, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get searchedAt => $composableBuilder(
      column: $table.searchedAt, builder: (column) => ColumnFilters(column));
}

class $$SearchHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keyword => $composableBuilder(
      column: $table.keyword, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get searchedAt => $composableBuilder(
      column: $table.searchedAt, builder: (column) => ColumnOrderings(column));
}

class $$SearchHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get keyword =>
      $composableBuilder(column: $table.keyword, builder: (column) => column);

  GeneratedColumn<DateTime> get searchedAt => $composableBuilder(
      column: $table.searchedAt, builder: (column) => column);
}

class $$SearchHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SearchHistoryTable,
    SearchHistoryData,
    $$SearchHistoryTableFilterComposer,
    $$SearchHistoryTableOrderingComposer,
    $$SearchHistoryTableAnnotationComposer,
    $$SearchHistoryTableCreateCompanionBuilder,
    $$SearchHistoryTableUpdateCompanionBuilder,
    (
      SearchHistoryData,
      BaseReferences<_$AppDatabase, $SearchHistoryTable, SearchHistoryData>
    ),
    SearchHistoryData,
    PrefetchHooks Function()> {
  $$SearchHistoryTableTableManager(_$AppDatabase db, $SearchHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SearchHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> keyword = const Value.absent(),
            Value<DateTime> searchedAt = const Value.absent(),
          }) =>
              SearchHistoryCompanion(
            id: id,
            keyword: keyword,
            searchedAt: searchedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String keyword,
            required DateTime searchedAt,
          }) =>
              SearchHistoryCompanion.insert(
            id: id,
            keyword: keyword,
            searchedAt: searchedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SearchHistoryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SearchHistoryTable,
    SearchHistoryData,
    $$SearchHistoryTableFilterComposer,
    $$SearchHistoryTableOrderingComposer,
    $$SearchHistoryTableAnnotationComposer,
    $$SearchHistoryTableCreateCompanionBuilder,
    $$SearchHistoryTableUpdateCompanionBuilder,
    (
      SearchHistoryData,
      BaseReferences<_$AppDatabase, $SearchHistoryTable, SearchHistoryData>
    ),
    SearchHistoryData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ComicsTableTableManager get comics =>
      $$ComicsTableTableManager(_db, _db.comics);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db, _db.episodes);
  $$HistoryTableTableManager get history =>
      $$HistoryTableTableManager(_db, _db.history);
  $$DownloadsTableTableManager get downloads =>
      $$DownloadsTableTableManager(_db, _db.downloads);
  $$SearchHistoryTableTableManager get searchHistory =>
      $$SearchHistoryTableTableManager(_db, _db.searchHistory);
}
