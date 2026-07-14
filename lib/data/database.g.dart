// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $MeetingsTable extends Meetings with TableInfo<$MeetingsTable, Meeting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeetingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _audioPathMeta =
      const VerificationMeta('audioPath');
  @override
  late final GeneratedColumn<String> audioPath = GeneratedColumn<String>(
      'audio_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<MeetingStatus, String> status =
      GeneratedColumn<String>('status', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<MeetingStatus>($MeetingsTable.$converterstatus);
  static const VerificationMeta _failureReasonMeta =
      const VerificationMeta('failureReason');
  @override
  late final GeneratedColumn<String> failureReason = GeneratedColumn<String>(
      'failure_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _calendarEventIdMeta =
      const VerificationMeta('calendarEventId');
  @override
  late final GeneratedColumn<String> calendarEventId = GeneratedColumn<String>(
      'calendar_event_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _languageMeta =
      const VerificationMeta('language');
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
      'language', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('en'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        durationMs,
        audioPath,
        createdAt,
        updatedAt,
        status,
        failureReason,
        calendarEventId,
        language
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meetings';
  @override
  VerificationContext validateIntegrity(Insertable<Meeting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('audio_path')) {
      context.handle(_audioPathMeta,
          audioPath.isAcceptableOrUnknown(data['audio_path']!, _audioPathMeta));
    } else if (isInserting) {
      context.missing(_audioPathMeta);
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
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('failure_reason')) {
      context.handle(
          _failureReasonMeta,
          failureReason.isAcceptableOrUnknown(
              data['failure_reason']!, _failureReasonMeta));
    }
    if (data.containsKey('calendar_event_id')) {
      context.handle(
          _calendarEventIdMeta,
          calendarEventId.isAcceptableOrUnknown(
              data['calendar_event_id']!, _calendarEventIdMeta));
    }
    if (data.containsKey('language')) {
      context.handle(_languageMeta,
          language.isAcceptableOrUnknown(data['language']!, _languageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Meeting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Meeting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      audioPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audio_path'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      status: $MeetingsTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!),
      failureReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}failure_reason']),
      calendarEventId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}calendar_event_id']),
      language: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}language'])!,
    );
  }

  @override
  $MeetingsTable createAlias(String alias) {
    return $MeetingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MeetingStatus, String, String> $converterstatus =
      const EnumNameConverter<MeetingStatus>(MeetingStatus.values);
}

class Meeting extends DataClass implements Insertable<Meeting> {
  final String id;
  final String title;
  final int durationMs;
  final String audioPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MeetingStatus status;
  final String? failureReason;
  final String? calendarEventId;
  final String language;
  const Meeting(
      {required this.id,
      required this.title,
      required this.durationMs,
      required this.audioPath,
      required this.createdAt,
      required this.updatedAt,
      required this.status,
      this.failureReason,
      this.calendarEventId,
      required this.language});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['duration_ms'] = Variable<int>(durationMs);
    map['audio_path'] = Variable<String>(audioPath);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['status'] =
          Variable<String>($MeetingsTable.$converterstatus.toSql(status));
    }
    if (!nullToAbsent || failureReason != null) {
      map['failure_reason'] = Variable<String>(failureReason);
    }
    if (!nullToAbsent || calendarEventId != null) {
      map['calendar_event_id'] = Variable<String>(calendarEventId);
    }
    map['language'] = Variable<String>(language);
    return map;
  }

  MeetingsCompanion toCompanion(bool nullToAbsent) {
    return MeetingsCompanion(
      id: Value(id),
      title: Value(title),
      durationMs: Value(durationMs),
      audioPath: Value(audioPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      status: Value(status),
      failureReason: failureReason == null && nullToAbsent
          ? const Value.absent()
          : Value(failureReason),
      calendarEventId: calendarEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(calendarEventId),
      language: Value(language),
    );
  }

  factory Meeting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Meeting(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      audioPath: serializer.fromJson<String>(json['audioPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      status: $MeetingsTable.$converterstatus
          .fromJson(serializer.fromJson<String>(json['status'])),
      failureReason: serializer.fromJson<String?>(json['failureReason']),
      calendarEventId: serializer.fromJson<String?>(json['calendarEventId']),
      language: serializer.fromJson<String>(json['language']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'durationMs': serializer.toJson<int>(durationMs),
      'audioPath': serializer.toJson<String>(audioPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'status': serializer
          .toJson<String>($MeetingsTable.$converterstatus.toJson(status)),
      'failureReason': serializer.toJson<String?>(failureReason),
      'calendarEventId': serializer.toJson<String?>(calendarEventId),
      'language': serializer.toJson<String>(language),
    };
  }

  Meeting copyWith(
          {String? id,
          String? title,
          int? durationMs,
          String? audioPath,
          DateTime? createdAt,
          DateTime? updatedAt,
          MeetingStatus? status,
          Value<String?> failureReason = const Value.absent(),
          Value<String?> calendarEventId = const Value.absent(),
          String? language}) =>
      Meeting(
        id: id ?? this.id,
        title: title ?? this.title,
        durationMs: durationMs ?? this.durationMs,
        audioPath: audioPath ?? this.audioPath,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        status: status ?? this.status,
        failureReason:
            failureReason.present ? failureReason.value : this.failureReason,
        calendarEventId: calendarEventId.present
            ? calendarEventId.value
            : this.calendarEventId,
        language: language ?? this.language,
      );
  Meeting copyWithCompanion(MeetingsCompanion data) {
    return Meeting(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      audioPath: data.audioPath.present ? data.audioPath.value : this.audioPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      status: data.status.present ? data.status.value : this.status,
      failureReason: data.failureReason.present
          ? data.failureReason.value
          : this.failureReason,
      calendarEventId: data.calendarEventId.present
          ? data.calendarEventId.value
          : this.calendarEventId,
      language: data.language.present ? data.language.value : this.language,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Meeting(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('durationMs: $durationMs, ')
          ..write('audioPath: $audioPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('status: $status, ')
          ..write('failureReason: $failureReason, ')
          ..write('calendarEventId: $calendarEventId, ')
          ..write('language: $language')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, durationMs, audioPath, createdAt,
      updatedAt, status, failureReason, calendarEventId, language);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Meeting &&
          other.id == this.id &&
          other.title == this.title &&
          other.durationMs == this.durationMs &&
          other.audioPath == this.audioPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.status == this.status &&
          other.failureReason == this.failureReason &&
          other.calendarEventId == this.calendarEventId &&
          other.language == this.language);
}

class MeetingsCompanion extends UpdateCompanion<Meeting> {
  final Value<String> id;
  final Value<String> title;
  final Value<int> durationMs;
  final Value<String> audioPath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<MeetingStatus> status;
  final Value<String?> failureReason;
  final Value<String?> calendarEventId;
  final Value<String> language;
  final Value<int> rowid;
  const MeetingsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.audioPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.failureReason = const Value.absent(),
    this.calendarEventId = const Value.absent(),
    this.language = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeetingsCompanion.insert({
    required String id,
    required String title,
    this.durationMs = const Value.absent(),
    required String audioPath,
    required DateTime createdAt,
    required DateTime updatedAt,
    required MeetingStatus status,
    this.failureReason = const Value.absent(),
    this.calendarEventId = const Value.absent(),
    this.language = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        audioPath = Value(audioPath),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        status = Value(status);
  static Insertable<Meeting> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? durationMs,
    Expression<String>? audioPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? status,
    Expression<String>? failureReason,
    Expression<String>? calendarEventId,
    Expression<String>? language,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (durationMs != null) 'duration_ms': durationMs,
      if (audioPath != null) 'audio_path': audioPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (status != null) 'status': status,
      if (failureReason != null) 'failure_reason': failureReason,
      if (calendarEventId != null) 'calendar_event_id': calendarEventId,
      if (language != null) 'language': language,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeetingsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<int>? durationMs,
      Value<String>? audioPath,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<MeetingStatus>? status,
      Value<String?>? failureReason,
      Value<String?>? calendarEventId,
      Value<String>? language,
      Value<int>? rowid}) {
    return MeetingsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      durationMs: durationMs ?? this.durationMs,
      audioPath: audioPath ?? this.audioPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      failureReason: failureReason ?? this.failureReason,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      language: language ?? this.language,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (audioPath.present) {
      map['audio_path'] = Variable<String>(audioPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (status.present) {
      map['status'] =
          Variable<String>($MeetingsTable.$converterstatus.toSql(status.value));
    }
    if (failureReason.present) {
      map['failure_reason'] = Variable<String>(failureReason.value);
    }
    if (calendarEventId.present) {
      map['calendar_event_id'] = Variable<String>(calendarEventId.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeetingsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('durationMs: $durationMs, ')
          ..write('audioPath: $audioPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('status: $status, ')
          ..write('failureReason: $failureReason, ')
          ..write('calendarEventId: $calendarEventId, ')
          ..write('language: $language, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TranscriptsTable extends Transcripts
    with TableInfo<$TranscriptsTable, Transcript> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranscriptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _meetingIdMeta =
      const VerificationMeta('meetingId');
  @override
  late final GeneratedColumn<String> meetingId = GeneratedColumn<String>(
      'meeting_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES meetings (id) ON DELETE CASCADE'));
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modelIdMeta =
      const VerificationMeta('modelId');
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
      'model_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _processingMsMeta =
      const VerificationMeta('processingMs');
  @override
  late final GeneratedColumn<int> processingMs = GeneratedColumn<int>(
      'processing_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [meetingId, body, modelId, processingMs, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transcripts';
  @override
  VerificationContext validateIntegrity(Insertable<Transcript> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('meeting_id')) {
      context.handle(_meetingIdMeta,
          meetingId.isAcceptableOrUnknown(data['meeting_id']!, _meetingIdMeta));
    } else if (isInserting) {
      context.missing(_meetingIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('model_id')) {
      context.handle(_modelIdMeta,
          modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta));
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('processing_ms')) {
      context.handle(
          _processingMsMeta,
          processingMs.isAcceptableOrUnknown(
              data['processing_ms']!, _processingMsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {meetingId};
  @override
  Transcript map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transcript(
      meetingId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meeting_id'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      modelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model_id'])!,
      processingMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}processing_ms'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TranscriptsTable createAlias(String alias) {
    return $TranscriptsTable(attachedDatabase, alias);
  }
}

class Transcript extends DataClass implements Insertable<Transcript> {
  final String meetingId;
  final String body;
  final String modelId;
  final int processingMs;
  final DateTime createdAt;
  const Transcript(
      {required this.meetingId,
      required this.body,
      required this.modelId,
      required this.processingMs,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['meeting_id'] = Variable<String>(meetingId);
    map['body'] = Variable<String>(body);
    map['model_id'] = Variable<String>(modelId);
    map['processing_ms'] = Variable<int>(processingMs);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TranscriptsCompanion toCompanion(bool nullToAbsent) {
    return TranscriptsCompanion(
      meetingId: Value(meetingId),
      body: Value(body),
      modelId: Value(modelId),
      processingMs: Value(processingMs),
      createdAt: Value(createdAt),
    );
  }

  factory Transcript.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transcript(
      meetingId: serializer.fromJson<String>(json['meetingId']),
      body: serializer.fromJson<String>(json['body']),
      modelId: serializer.fromJson<String>(json['modelId']),
      processingMs: serializer.fromJson<int>(json['processingMs']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'meetingId': serializer.toJson<String>(meetingId),
      'body': serializer.toJson<String>(body),
      'modelId': serializer.toJson<String>(modelId),
      'processingMs': serializer.toJson<int>(processingMs),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Transcript copyWith(
          {String? meetingId,
          String? body,
          String? modelId,
          int? processingMs,
          DateTime? createdAt}) =>
      Transcript(
        meetingId: meetingId ?? this.meetingId,
        body: body ?? this.body,
        modelId: modelId ?? this.modelId,
        processingMs: processingMs ?? this.processingMs,
        createdAt: createdAt ?? this.createdAt,
      );
  Transcript copyWithCompanion(TranscriptsCompanion data) {
    return Transcript(
      meetingId: data.meetingId.present ? data.meetingId.value : this.meetingId,
      body: data.body.present ? data.body.value : this.body,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      processingMs: data.processingMs.present
          ? data.processingMs.value
          : this.processingMs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transcript(')
          ..write('meetingId: $meetingId, ')
          ..write('body: $body, ')
          ..write('modelId: $modelId, ')
          ..write('processingMs: $processingMs, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(meetingId, body, modelId, processingMs, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transcript &&
          other.meetingId == this.meetingId &&
          other.body == this.body &&
          other.modelId == this.modelId &&
          other.processingMs == this.processingMs &&
          other.createdAt == this.createdAt);
}

class TranscriptsCompanion extends UpdateCompanion<Transcript> {
  final Value<String> meetingId;
  final Value<String> body;
  final Value<String> modelId;
  final Value<int> processingMs;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TranscriptsCompanion({
    this.meetingId = const Value.absent(),
    this.body = const Value.absent(),
    this.modelId = const Value.absent(),
    this.processingMs = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TranscriptsCompanion.insert({
    required String meetingId,
    required String body,
    required String modelId,
    this.processingMs = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : meetingId = Value(meetingId),
        body = Value(body),
        modelId = Value(modelId),
        createdAt = Value(createdAt);
  static Insertable<Transcript> custom({
    Expression<String>? meetingId,
    Expression<String>? body,
    Expression<String>? modelId,
    Expression<int>? processingMs,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (meetingId != null) 'meeting_id': meetingId,
      if (body != null) 'body': body,
      if (modelId != null) 'model_id': modelId,
      if (processingMs != null) 'processing_ms': processingMs,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TranscriptsCompanion copyWith(
      {Value<String>? meetingId,
      Value<String>? body,
      Value<String>? modelId,
      Value<int>? processingMs,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return TranscriptsCompanion(
      meetingId: meetingId ?? this.meetingId,
      body: body ?? this.body,
      modelId: modelId ?? this.modelId,
      processingMs: processingMs ?? this.processingMs,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (meetingId.present) {
      map['meeting_id'] = Variable<String>(meetingId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (processingMs.present) {
      map['processing_ms'] = Variable<int>(processingMs.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptsCompanion(')
          ..write('meetingId: $meetingId, ')
          ..write('body: $body, ')
          ..write('modelId: $modelId, ')
          ..write('processingMs: $processingMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TranscriptSegmentsTable extends TranscriptSegments
    with TableInfo<$TranscriptSegmentsTable, TranscriptSegment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranscriptSegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _meetingIdMeta =
      const VerificationMeta('meetingId');
  @override
  late final GeneratedColumn<String> meetingId = GeneratedColumn<String>(
      'meeting_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES meetings (id) ON DELETE CASCADE'));
  static const VerificationMeta _startMsMeta =
      const VerificationMeta('startMs');
  @override
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
      'start_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endMsMeta = const VerificationMeta('endMs');
  @override
  late final GeneratedColumn<int> endMs = GeneratedColumn<int>(
      'end_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isFinalMeta =
      const VerificationMeta('isFinal');
  @override
  late final GeneratedColumn<bool> isFinal = GeneratedColumn<bool>(
      'is_final', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_final" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _speakerLabelMeta =
      const VerificationMeta('speakerLabel');
  @override
  late final GeneratedColumn<String> speakerLabel = GeneratedColumn<String>(
      'speaker_label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, meetingId, startMs, endMs, body, isFinal, speakerLabel];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transcript_segments';
  @override
  VerificationContext validateIntegrity(Insertable<TranscriptSegment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('meeting_id')) {
      context.handle(_meetingIdMeta,
          meetingId.isAcceptableOrUnknown(data['meeting_id']!, _meetingIdMeta));
    } else if (isInserting) {
      context.missing(_meetingIdMeta);
    }
    if (data.containsKey('start_ms')) {
      context.handle(_startMsMeta,
          startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta));
    } else if (isInserting) {
      context.missing(_startMsMeta);
    }
    if (data.containsKey('end_ms')) {
      context.handle(
          _endMsMeta, endMs.isAcceptableOrUnknown(data['end_ms']!, _endMsMeta));
    } else if (isInserting) {
      context.missing(_endMsMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('is_final')) {
      context.handle(_isFinalMeta,
          isFinal.isAcceptableOrUnknown(data['is_final']!, _isFinalMeta));
    }
    if (data.containsKey('speaker_label')) {
      context.handle(
          _speakerLabelMeta,
          speakerLabel.isAcceptableOrUnknown(
              data['speaker_label']!, _speakerLabelMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TranscriptSegment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TranscriptSegment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      meetingId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meeting_id'])!,
      startMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_ms'])!,
      endMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_ms'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      isFinal: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_final'])!,
      speakerLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}speaker_label']),
    );
  }

  @override
  $TranscriptSegmentsTable createAlias(String alias) {
    return $TranscriptSegmentsTable(attachedDatabase, alias);
  }
}

class TranscriptSegment extends DataClass
    implements Insertable<TranscriptSegment> {
  final String id;
  final String meetingId;
  final int startMs;
  final int endMs;
  final String body;
  final bool isFinal;
  final String? speakerLabel;
  const TranscriptSegment(
      {required this.id,
      required this.meetingId,
      required this.startMs,
      required this.endMs,
      required this.body,
      required this.isFinal,
      this.speakerLabel});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['meeting_id'] = Variable<String>(meetingId);
    map['start_ms'] = Variable<int>(startMs);
    map['end_ms'] = Variable<int>(endMs);
    map['body'] = Variable<String>(body);
    map['is_final'] = Variable<bool>(isFinal);
    if (!nullToAbsent || speakerLabel != null) {
      map['speaker_label'] = Variable<String>(speakerLabel);
    }
    return map;
  }

  TranscriptSegmentsCompanion toCompanion(bool nullToAbsent) {
    return TranscriptSegmentsCompanion(
      id: Value(id),
      meetingId: Value(meetingId),
      startMs: Value(startMs),
      endMs: Value(endMs),
      body: Value(body),
      isFinal: Value(isFinal),
      speakerLabel: speakerLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(speakerLabel),
    );
  }

  factory TranscriptSegment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TranscriptSegment(
      id: serializer.fromJson<String>(json['id']),
      meetingId: serializer.fromJson<String>(json['meetingId']),
      startMs: serializer.fromJson<int>(json['startMs']),
      endMs: serializer.fromJson<int>(json['endMs']),
      body: serializer.fromJson<String>(json['body']),
      isFinal: serializer.fromJson<bool>(json['isFinal']),
      speakerLabel: serializer.fromJson<String?>(json['speakerLabel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'meetingId': serializer.toJson<String>(meetingId),
      'startMs': serializer.toJson<int>(startMs),
      'endMs': serializer.toJson<int>(endMs),
      'body': serializer.toJson<String>(body),
      'isFinal': serializer.toJson<bool>(isFinal),
      'speakerLabel': serializer.toJson<String?>(speakerLabel),
    };
  }

  TranscriptSegment copyWith(
          {String? id,
          String? meetingId,
          int? startMs,
          int? endMs,
          String? body,
          bool? isFinal,
          Value<String?> speakerLabel = const Value.absent()}) =>
      TranscriptSegment(
        id: id ?? this.id,
        meetingId: meetingId ?? this.meetingId,
        startMs: startMs ?? this.startMs,
        endMs: endMs ?? this.endMs,
        body: body ?? this.body,
        isFinal: isFinal ?? this.isFinal,
        speakerLabel:
            speakerLabel.present ? speakerLabel.value : this.speakerLabel,
      );
  TranscriptSegment copyWithCompanion(TranscriptSegmentsCompanion data) {
    return TranscriptSegment(
      id: data.id.present ? data.id.value : this.id,
      meetingId: data.meetingId.present ? data.meetingId.value : this.meetingId,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      endMs: data.endMs.present ? data.endMs.value : this.endMs,
      body: data.body.present ? data.body.value : this.body,
      isFinal: data.isFinal.present ? data.isFinal.value : this.isFinal,
      speakerLabel: data.speakerLabel.present
          ? data.speakerLabel.value
          : this.speakerLabel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptSegment(')
          ..write('id: $id, ')
          ..write('meetingId: $meetingId, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('body: $body, ')
          ..write('isFinal: $isFinal, ')
          ..write('speakerLabel: $speakerLabel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, meetingId, startMs, endMs, body, isFinal, speakerLabel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TranscriptSegment &&
          other.id == this.id &&
          other.meetingId == this.meetingId &&
          other.startMs == this.startMs &&
          other.endMs == this.endMs &&
          other.body == this.body &&
          other.isFinal == this.isFinal &&
          other.speakerLabel == this.speakerLabel);
}

class TranscriptSegmentsCompanion extends UpdateCompanion<TranscriptSegment> {
  final Value<String> id;
  final Value<String> meetingId;
  final Value<int> startMs;
  final Value<int> endMs;
  final Value<String> body;
  final Value<bool> isFinal;
  final Value<String?> speakerLabel;
  final Value<int> rowid;
  const TranscriptSegmentsCompanion({
    this.id = const Value.absent(),
    this.meetingId = const Value.absent(),
    this.startMs = const Value.absent(),
    this.endMs = const Value.absent(),
    this.body = const Value.absent(),
    this.isFinal = const Value.absent(),
    this.speakerLabel = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TranscriptSegmentsCompanion.insert({
    required String id,
    required String meetingId,
    required int startMs,
    required int endMs,
    required String body,
    this.isFinal = const Value.absent(),
    this.speakerLabel = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        meetingId = Value(meetingId),
        startMs = Value(startMs),
        endMs = Value(endMs),
        body = Value(body);
  static Insertable<TranscriptSegment> custom({
    Expression<String>? id,
    Expression<String>? meetingId,
    Expression<int>? startMs,
    Expression<int>? endMs,
    Expression<String>? body,
    Expression<bool>? isFinal,
    Expression<String>? speakerLabel,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (meetingId != null) 'meeting_id': meetingId,
      if (startMs != null) 'start_ms': startMs,
      if (endMs != null) 'end_ms': endMs,
      if (body != null) 'body': body,
      if (isFinal != null) 'is_final': isFinal,
      if (speakerLabel != null) 'speaker_label': speakerLabel,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TranscriptSegmentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? meetingId,
      Value<int>? startMs,
      Value<int>? endMs,
      Value<String>? body,
      Value<bool>? isFinal,
      Value<String?>? speakerLabel,
      Value<int>? rowid}) {
    return TranscriptSegmentsCompanion(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      body: body ?? this.body,
      isFinal: isFinal ?? this.isFinal,
      speakerLabel: speakerLabel ?? this.speakerLabel,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (meetingId.present) {
      map['meeting_id'] = Variable<String>(meetingId.value);
    }
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (endMs.present) {
      map['end_ms'] = Variable<int>(endMs.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (isFinal.present) {
      map['is_final'] = Variable<bool>(isFinal.value);
    }
    if (speakerLabel.present) {
      map['speaker_label'] = Variable<String>(speakerLabel.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranscriptSegmentsCompanion(')
          ..write('id: $id, ')
          ..write('meetingId: $meetingId, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('body: $body, ')
          ..write('isFinal: $isFinal, ')
          ..write('speakerLabel: $speakerLabel, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SummariesTable extends Summaries
    with TableInfo<$SummariesTable, Summary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _meetingIdMeta =
      const VerificationMeta('meetingId');
  @override
  late final GeneratedColumn<String> meetingId = GeneratedColumn<String>(
      'meeting_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES meetings (id) ON DELETE CASCADE'));
  static const VerificationMeta _personaKeyMeta =
      const VerificationMeta('personaKey');
  @override
  late final GeneratedColumn<String> personaKey = GeneratedColumn<String>(
      'persona_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<SummaryBackendKind, String>
      backend = GeneratedColumn<String>('backend', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<SummaryBackendKind>($SummariesTable.$converterbackend);
  static const VerificationMeta _modelIdMeta =
      const VerificationMeta('modelId');
  @override
  late final GeneratedColumn<String> modelId = GeneratedColumn<String>(
      'model_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _processingMsMeta =
      const VerificationMeta('processingMs');
  @override
  late final GeneratedColumn<int> processingMs = GeneratedColumn<int>(
      'processing_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        meetingId,
        personaKey,
        body,
        backend,
        modelId,
        processingMs,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'summaries';
  @override
  VerificationContext validateIntegrity(Insertable<Summary> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('meeting_id')) {
      context.handle(_meetingIdMeta,
          meetingId.isAcceptableOrUnknown(data['meeting_id']!, _meetingIdMeta));
    } else if (isInserting) {
      context.missing(_meetingIdMeta);
    }
    if (data.containsKey('persona_key')) {
      context.handle(
          _personaKeyMeta,
          personaKey.isAcceptableOrUnknown(
              data['persona_key']!, _personaKeyMeta));
    } else if (isInserting) {
      context.missing(_personaKeyMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('model_id')) {
      context.handle(_modelIdMeta,
          modelId.isAcceptableOrUnknown(data['model_id']!, _modelIdMeta));
    } else if (isInserting) {
      context.missing(_modelIdMeta);
    }
    if (data.containsKey('processing_ms')) {
      context.handle(
          _processingMsMeta,
          processingMs.isAcceptableOrUnknown(
              data['processing_ms']!, _processingMsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Summary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Summary(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      meetingId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meeting_id'])!,
      personaKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}persona_key'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      backend: $SummariesTable.$converterbackend.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}backend'])!),
      modelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model_id'])!,
      processingMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}processing_ms'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SummariesTable createAlias(String alias) {
    return $SummariesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SummaryBackendKind, String, String>
      $converterbackend =
      const EnumNameConverter<SummaryBackendKind>(SummaryBackendKind.values);
}

class Summary extends DataClass implements Insertable<Summary> {
  final String id;
  final String meetingId;
  final String personaKey;
  final String body;
  final SummaryBackendKind backend;
  final String modelId;
  final int processingMs;
  final DateTime createdAt;
  const Summary(
      {required this.id,
      required this.meetingId,
      required this.personaKey,
      required this.body,
      required this.backend,
      required this.modelId,
      required this.processingMs,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['meeting_id'] = Variable<String>(meetingId);
    map['persona_key'] = Variable<String>(personaKey);
    map['body'] = Variable<String>(body);
    {
      map['backend'] =
          Variable<String>($SummariesTable.$converterbackend.toSql(backend));
    }
    map['model_id'] = Variable<String>(modelId);
    map['processing_ms'] = Variable<int>(processingMs);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SummariesCompanion toCompanion(bool nullToAbsent) {
    return SummariesCompanion(
      id: Value(id),
      meetingId: Value(meetingId),
      personaKey: Value(personaKey),
      body: Value(body),
      backend: Value(backend),
      modelId: Value(modelId),
      processingMs: Value(processingMs),
      createdAt: Value(createdAt),
    );
  }

  factory Summary.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Summary(
      id: serializer.fromJson<String>(json['id']),
      meetingId: serializer.fromJson<String>(json['meetingId']),
      personaKey: serializer.fromJson<String>(json['personaKey']),
      body: serializer.fromJson<String>(json['body']),
      backend: $SummariesTable.$converterbackend
          .fromJson(serializer.fromJson<String>(json['backend'])),
      modelId: serializer.fromJson<String>(json['modelId']),
      processingMs: serializer.fromJson<int>(json['processingMs']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'meetingId': serializer.toJson<String>(meetingId),
      'personaKey': serializer.toJson<String>(personaKey),
      'body': serializer.toJson<String>(body),
      'backend': serializer
          .toJson<String>($SummariesTable.$converterbackend.toJson(backend)),
      'modelId': serializer.toJson<String>(modelId),
      'processingMs': serializer.toJson<int>(processingMs),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Summary copyWith(
          {String? id,
          String? meetingId,
          String? personaKey,
          String? body,
          SummaryBackendKind? backend,
          String? modelId,
          int? processingMs,
          DateTime? createdAt}) =>
      Summary(
        id: id ?? this.id,
        meetingId: meetingId ?? this.meetingId,
        personaKey: personaKey ?? this.personaKey,
        body: body ?? this.body,
        backend: backend ?? this.backend,
        modelId: modelId ?? this.modelId,
        processingMs: processingMs ?? this.processingMs,
        createdAt: createdAt ?? this.createdAt,
      );
  Summary copyWithCompanion(SummariesCompanion data) {
    return Summary(
      id: data.id.present ? data.id.value : this.id,
      meetingId: data.meetingId.present ? data.meetingId.value : this.meetingId,
      personaKey:
          data.personaKey.present ? data.personaKey.value : this.personaKey,
      body: data.body.present ? data.body.value : this.body,
      backend: data.backend.present ? data.backend.value : this.backend,
      modelId: data.modelId.present ? data.modelId.value : this.modelId,
      processingMs: data.processingMs.present
          ? data.processingMs.value
          : this.processingMs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Summary(')
          ..write('id: $id, ')
          ..write('meetingId: $meetingId, ')
          ..write('personaKey: $personaKey, ')
          ..write('body: $body, ')
          ..write('backend: $backend, ')
          ..write('modelId: $modelId, ')
          ..write('processingMs: $processingMs, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, meetingId, personaKey, body, backend,
      modelId, processingMs, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Summary &&
          other.id == this.id &&
          other.meetingId == this.meetingId &&
          other.personaKey == this.personaKey &&
          other.body == this.body &&
          other.backend == this.backend &&
          other.modelId == this.modelId &&
          other.processingMs == this.processingMs &&
          other.createdAt == this.createdAt);
}

class SummariesCompanion extends UpdateCompanion<Summary> {
  final Value<String> id;
  final Value<String> meetingId;
  final Value<String> personaKey;
  final Value<String> body;
  final Value<SummaryBackendKind> backend;
  final Value<String> modelId;
  final Value<int> processingMs;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SummariesCompanion({
    this.id = const Value.absent(),
    this.meetingId = const Value.absent(),
    this.personaKey = const Value.absent(),
    this.body = const Value.absent(),
    this.backend = const Value.absent(),
    this.modelId = const Value.absent(),
    this.processingMs = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SummariesCompanion.insert({
    required String id,
    required String meetingId,
    required String personaKey,
    required String body,
    required SummaryBackendKind backend,
    required String modelId,
    this.processingMs = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        meetingId = Value(meetingId),
        personaKey = Value(personaKey),
        body = Value(body),
        backend = Value(backend),
        modelId = Value(modelId),
        createdAt = Value(createdAt);
  static Insertable<Summary> custom({
    Expression<String>? id,
    Expression<String>? meetingId,
    Expression<String>? personaKey,
    Expression<String>? body,
    Expression<String>? backend,
    Expression<String>? modelId,
    Expression<int>? processingMs,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (meetingId != null) 'meeting_id': meetingId,
      if (personaKey != null) 'persona_key': personaKey,
      if (body != null) 'body': body,
      if (backend != null) 'backend': backend,
      if (modelId != null) 'model_id': modelId,
      if (processingMs != null) 'processing_ms': processingMs,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SummariesCompanion copyWith(
      {Value<String>? id,
      Value<String>? meetingId,
      Value<String>? personaKey,
      Value<String>? body,
      Value<SummaryBackendKind>? backend,
      Value<String>? modelId,
      Value<int>? processingMs,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return SummariesCompanion(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      personaKey: personaKey ?? this.personaKey,
      body: body ?? this.body,
      backend: backend ?? this.backend,
      modelId: modelId ?? this.modelId,
      processingMs: processingMs ?? this.processingMs,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (meetingId.present) {
      map['meeting_id'] = Variable<String>(meetingId.value);
    }
    if (personaKey.present) {
      map['persona_key'] = Variable<String>(personaKey.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (backend.present) {
      map['backend'] = Variable<String>(
          $SummariesTable.$converterbackend.toSql(backend.value));
    }
    if (modelId.present) {
      map['model_id'] = Variable<String>(modelId.value);
    }
    if (processingMs.present) {
      map['processing_ms'] = Variable<int>(processingMs.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SummariesCompanion(')
          ..write('id: $id, ')
          ..write('meetingId: $meetingId, ')
          ..write('personaKey: $personaKey, ')
          ..write('body: $body, ')
          ..write('backend: $backend, ')
          ..write('modelId: $modelId, ')
          ..write('processingMs: $processingMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _meetingIdMeta =
      const VerificationMeta('meetingId');
  @override
  late final GeneratedColumn<String> meetingId = GeneratedColumn<String>(
      'meeting_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES meetings (id) ON DELETE CASCADE'));
  static const VerificationMeta _atMsMeta = const VerificationMeta('atMs');
  @override
  late final GeneratedColumn<int> atMs = GeneratedColumn<int>(
      'at_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, meetingId, atMs, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(Insertable<Bookmark> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('meeting_id')) {
      context.handle(_meetingIdMeta,
          meetingId.isAcceptableOrUnknown(data['meeting_id']!, _meetingIdMeta));
    } else if (isInserting) {
      context.missing(_meetingIdMeta);
    }
    if (data.containsKey('at_ms')) {
      context.handle(
          _atMsMeta, atMs.isAcceptableOrUnknown(data['at_ms']!, _atMsMeta));
    } else if (isInserting) {
      context.missing(_atMsMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      meetingId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meeting_id'])!,
      atMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}at_ms'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final String id;
  final String meetingId;
  final int atMs;
  final String? note;
  final DateTime createdAt;
  const Bookmark(
      {required this.id,
      required this.meetingId,
      required this.atMs,
      this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['meeting_id'] = Variable<String>(meetingId);
    map['at_ms'] = Variable<int>(atMs);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      meetingId: Value(meetingId),
      atMs: Value(atMs),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory Bookmark.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<String>(json['id']),
      meetingId: serializer.fromJson<String>(json['meetingId']),
      atMs: serializer.fromJson<int>(json['atMs']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'meetingId': serializer.toJson<String>(meetingId),
      'atMs': serializer.toJson<int>(atMs),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Bookmark copyWith(
          {String? id,
          String? meetingId,
          int? atMs,
          Value<String?> note = const Value.absent(),
          DateTime? createdAt}) =>
      Bookmark(
        id: id ?? this.id,
        meetingId: meetingId ?? this.meetingId,
        atMs: atMs ?? this.atMs,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      meetingId: data.meetingId.present ? data.meetingId.value : this.meetingId,
      atMs: data.atMs.present ? data.atMs.value : this.atMs,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('meetingId: $meetingId, ')
          ..write('atMs: $atMs, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, meetingId, atMs, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.meetingId == this.meetingId &&
          other.atMs == this.atMs &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<String> id;
  final Value<String> meetingId;
  final Value<int> atMs;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.meetingId = const Value.absent(),
    this.atMs = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksCompanion.insert({
    required String id,
    required String meetingId,
    required int atMs,
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        meetingId = Value(meetingId),
        atMs = Value(atMs),
        createdAt = Value(createdAt);
  static Insertable<Bookmark> custom({
    Expression<String>? id,
    Expression<String>? meetingId,
    Expression<int>? atMs,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (meetingId != null) 'meeting_id': meetingId,
      if (atMs != null) 'at_ms': atMs,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksCompanion copyWith(
      {Value<String>? id,
      Value<String>? meetingId,
      Value<int>? atMs,
      Value<String?>? note,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return BookmarksCompanion(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      atMs: atMs ?? this.atMs,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (meetingId.present) {
      map['meeting_id'] = Variable<String>(meetingId.value);
    }
    if (atMs.present) {
      map['at_ms'] = Variable<int>(atMs.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('meetingId: $meetingId, ')
          ..write('atMs: $atMs, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsageDaysTable extends UsageDays
    with TableInfo<$UsageDaysTable, UsageDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsageDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
      'day', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _meetingsStartedMeta =
      const VerificationMeta('meetingsStarted');
  @override
  late final GeneratedColumn<int> meetingsStarted = GeneratedColumn<int>(
      'meetings_started', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _recordedMsMeta =
      const VerificationMeta('recordedMs');
  @override
  late final GeneratedColumn<int> recordedMs = GeneratedColumn<int>(
      'recorded_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [day, meetingsStarted, recordedMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usage_days';
  @override
  VerificationContext validateIntegrity(Insertable<UsageDay> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
          _dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('meetings_started')) {
      context.handle(
          _meetingsStartedMeta,
          meetingsStarted.isAcceptableOrUnknown(
              data['meetings_started']!, _meetingsStartedMeta));
    }
    if (data.containsKey('recorded_ms')) {
      context.handle(
          _recordedMsMeta,
          recordedMs.isAcceptableOrUnknown(
              data['recorded_ms']!, _recordedMsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  UsageDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsageDay(
      day: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}day'])!,
      meetingsStarted: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}meetings_started'])!,
      recordedMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}recorded_ms'])!,
    );
  }

  @override
  $UsageDaysTable createAlias(String alias) {
    return $UsageDaysTable(attachedDatabase, alias);
  }
}

class UsageDay extends DataClass implements Insertable<UsageDay> {
  final String day;
  final int meetingsStarted;
  final int recordedMs;
  const UsageDay(
      {required this.day,
      required this.meetingsStarted,
      required this.recordedMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    map['meetings_started'] = Variable<int>(meetingsStarted);
    map['recorded_ms'] = Variable<int>(recordedMs);
    return map;
  }

  UsageDaysCompanion toCompanion(bool nullToAbsent) {
    return UsageDaysCompanion(
      day: Value(day),
      meetingsStarted: Value(meetingsStarted),
      recordedMs: Value(recordedMs),
    );
  }

  factory UsageDay.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsageDay(
      day: serializer.fromJson<String>(json['day']),
      meetingsStarted: serializer.fromJson<int>(json['meetingsStarted']),
      recordedMs: serializer.fromJson<int>(json['recordedMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'meetingsStarted': serializer.toJson<int>(meetingsStarted),
      'recordedMs': serializer.toJson<int>(recordedMs),
    };
  }

  UsageDay copyWith({String? day, int? meetingsStarted, int? recordedMs}) =>
      UsageDay(
        day: day ?? this.day,
        meetingsStarted: meetingsStarted ?? this.meetingsStarted,
        recordedMs: recordedMs ?? this.recordedMs,
      );
  UsageDay copyWithCompanion(UsageDaysCompanion data) {
    return UsageDay(
      day: data.day.present ? data.day.value : this.day,
      meetingsStarted: data.meetingsStarted.present
          ? data.meetingsStarted.value
          : this.meetingsStarted,
      recordedMs:
          data.recordedMs.present ? data.recordedMs.value : this.recordedMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsageDay(')
          ..write('day: $day, ')
          ..write('meetingsStarted: $meetingsStarted, ')
          ..write('recordedMs: $recordedMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, meetingsStarted, recordedMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsageDay &&
          other.day == this.day &&
          other.meetingsStarted == this.meetingsStarted &&
          other.recordedMs == this.recordedMs);
}

class UsageDaysCompanion extends UpdateCompanion<UsageDay> {
  final Value<String> day;
  final Value<int> meetingsStarted;
  final Value<int> recordedMs;
  final Value<int> rowid;
  const UsageDaysCompanion({
    this.day = const Value.absent(),
    this.meetingsStarted = const Value.absent(),
    this.recordedMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsageDaysCompanion.insert({
    required String day,
    this.meetingsStarted = const Value.absent(),
    this.recordedMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : day = Value(day);
  static Insertable<UsageDay> custom({
    Expression<String>? day,
    Expression<int>? meetingsStarted,
    Expression<int>? recordedMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (meetingsStarted != null) 'meetings_started': meetingsStarted,
      if (recordedMs != null) 'recorded_ms': recordedMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsageDaysCompanion copyWith(
      {Value<String>? day,
      Value<int>? meetingsStarted,
      Value<int>? recordedMs,
      Value<int>? rowid}) {
    return UsageDaysCompanion(
      day: day ?? this.day,
      meetingsStarted: meetingsStarted ?? this.meetingsStarted,
      recordedMs: recordedMs ?? this.recordedMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (meetingsStarted.present) {
      map['meetings_started'] = Variable<int>(meetingsStarted.value);
    }
    if (recordedMs.present) {
      map['recorded_ms'] = Variable<int>(recordedMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsageDaysCompanion(')
          ..write('day: $day, ')
          ..write('meetingsStarted: $meetingsStarted, ')
          ..write('recordedMs: $recordedMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsageMonthsTable extends UsageMonths
    with TableInfo<$UsageMonthsTable, UsageMonth> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsageMonthsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<String> month = GeneratedColumn<String>(
      'month', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cloudSummariesUsedMeta =
      const VerificationMeta('cloudSummariesUsed');
  @override
  late final GeneratedColumn<int> cloudSummariesUsed = GeneratedColumn<int>(
      'cloud_summaries_used', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _recordedMsMeta =
      const VerificationMeta('recordedMs');
  @override
  late final GeneratedColumn<int> recordedMs = GeneratedColumn<int>(
      'recorded_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [month, cloudSummariesUsed, recordedMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usage_months';
  @override
  VerificationContext validateIntegrity(Insertable<UsageMonth> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('month')) {
      context.handle(
          _monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('cloud_summaries_used')) {
      context.handle(
          _cloudSummariesUsedMeta,
          cloudSummariesUsed.isAcceptableOrUnknown(
              data['cloud_summaries_used']!, _cloudSummariesUsedMeta));
    }
    if (data.containsKey('recorded_ms')) {
      context.handle(
          _recordedMsMeta,
          recordedMs.isAcceptableOrUnknown(
              data['recorded_ms']!, _recordedMsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {month};
  @override
  UsageMonth map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsageMonth(
      month: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}month'])!,
      cloudSummariesUsed: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}cloud_summaries_used'])!,
      recordedMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}recorded_ms'])!,
    );
  }

  @override
  $UsageMonthsTable createAlias(String alias) {
    return $UsageMonthsTable(attachedDatabase, alias);
  }
}

class UsageMonth extends DataClass implements Insertable<UsageMonth> {
  final String month;
  final int cloudSummariesUsed;
  final int recordedMs;
  const UsageMonth(
      {required this.month,
      required this.cloudSummariesUsed,
      required this.recordedMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['month'] = Variable<String>(month);
    map['cloud_summaries_used'] = Variable<int>(cloudSummariesUsed);
    map['recorded_ms'] = Variable<int>(recordedMs);
    return map;
  }

  UsageMonthsCompanion toCompanion(bool nullToAbsent) {
    return UsageMonthsCompanion(
      month: Value(month),
      cloudSummariesUsed: Value(cloudSummariesUsed),
      recordedMs: Value(recordedMs),
    );
  }

  factory UsageMonth.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsageMonth(
      month: serializer.fromJson<String>(json['month']),
      cloudSummariesUsed: serializer.fromJson<int>(json['cloudSummariesUsed']),
      recordedMs: serializer.fromJson<int>(json['recordedMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'month': serializer.toJson<String>(month),
      'cloudSummariesUsed': serializer.toJson<int>(cloudSummariesUsed),
      'recordedMs': serializer.toJson<int>(recordedMs),
    };
  }

  UsageMonth copyWith(
          {String? month, int? cloudSummariesUsed, int? recordedMs}) =>
      UsageMonth(
        month: month ?? this.month,
        cloudSummariesUsed: cloudSummariesUsed ?? this.cloudSummariesUsed,
        recordedMs: recordedMs ?? this.recordedMs,
      );
  UsageMonth copyWithCompanion(UsageMonthsCompanion data) {
    return UsageMonth(
      month: data.month.present ? data.month.value : this.month,
      cloudSummariesUsed: data.cloudSummariesUsed.present
          ? data.cloudSummariesUsed.value
          : this.cloudSummariesUsed,
      recordedMs:
          data.recordedMs.present ? data.recordedMs.value : this.recordedMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsageMonth(')
          ..write('month: $month, ')
          ..write('cloudSummariesUsed: $cloudSummariesUsed, ')
          ..write('recordedMs: $recordedMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(month, cloudSummariesUsed, recordedMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsageMonth &&
          other.month == this.month &&
          other.cloudSummariesUsed == this.cloudSummariesUsed &&
          other.recordedMs == this.recordedMs);
}

class UsageMonthsCompanion extends UpdateCompanion<UsageMonth> {
  final Value<String> month;
  final Value<int> cloudSummariesUsed;
  final Value<int> recordedMs;
  final Value<int> rowid;
  const UsageMonthsCompanion({
    this.month = const Value.absent(),
    this.cloudSummariesUsed = const Value.absent(),
    this.recordedMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsageMonthsCompanion.insert({
    required String month,
    this.cloudSummariesUsed = const Value.absent(),
    this.recordedMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : month = Value(month);
  static Insertable<UsageMonth> custom({
    Expression<String>? month,
    Expression<int>? cloudSummariesUsed,
    Expression<int>? recordedMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (month != null) 'month': month,
      if (cloudSummariesUsed != null)
        'cloud_summaries_used': cloudSummariesUsed,
      if (recordedMs != null) 'recorded_ms': recordedMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsageMonthsCompanion copyWith(
      {Value<String>? month,
      Value<int>? cloudSummariesUsed,
      Value<int>? recordedMs,
      Value<int>? rowid}) {
    return UsageMonthsCompanion(
      month: month ?? this.month,
      cloudSummariesUsed: cloudSummariesUsed ?? this.cloudSummariesUsed,
      recordedMs: recordedMs ?? this.recordedMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (month.present) {
      map['month'] = Variable<String>(month.value);
    }
    if (cloudSummariesUsed.present) {
      map['cloud_summaries_used'] = Variable<int>(cloudSummariesUsed.value);
    }
    if (recordedMs.present) {
      map['recorded_ms'] = Variable<int>(recordedMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsageMonthsCompanion(')
          ..write('month: $month, ')
          ..write('cloudSummariesUsed: $cloudSummariesUsed, ')
          ..write('recordedMs: $recordedMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TopUpCreditsTable extends TopUpCredits
    with TableInfo<$TopUpCreditsTable, TopUpCredit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TopUpCreditsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remainingMeta =
      const VerificationMeta('remaining');
  @override
  late final GeneratedColumn<int> remaining = GeneratedColumn<int>(
      'remaining', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _purchasedAtMeta =
      const VerificationMeta('purchasedAt');
  @override
  late final GeneratedColumn<DateTime> purchasedAt = GeneratedColumn<DateTime>(
      'purchased_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, remaining, purchasedAt, productId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'top_up_credits';
  @override
  VerificationContext validateIntegrity(Insertable<TopUpCredit> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('remaining')) {
      context.handle(_remainingMeta,
          remaining.isAcceptableOrUnknown(data['remaining']!, _remainingMeta));
    } else if (isInserting) {
      context.missing(_remainingMeta);
    }
    if (data.containsKey('purchased_at')) {
      context.handle(
          _purchasedAtMeta,
          purchasedAt.isAcceptableOrUnknown(
              data['purchased_at']!, _purchasedAtMeta));
    } else if (isInserting) {
      context.missing(_purchasedAtMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TopUpCredit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TopUpCredit(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      remaining: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}remaining'])!,
      purchasedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}purchased_at'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
    );
  }

  @override
  $TopUpCreditsTable createAlias(String alias) {
    return $TopUpCreditsTable(attachedDatabase, alias);
  }
}

class TopUpCredit extends DataClass implements Insertable<TopUpCredit> {
  final String id;
  final int remaining;
  final DateTime purchasedAt;
  final String productId;
  const TopUpCredit(
      {required this.id,
      required this.remaining,
      required this.purchasedAt,
      required this.productId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['remaining'] = Variable<int>(remaining);
    map['purchased_at'] = Variable<DateTime>(purchasedAt);
    map['product_id'] = Variable<String>(productId);
    return map;
  }

  TopUpCreditsCompanion toCompanion(bool nullToAbsent) {
    return TopUpCreditsCompanion(
      id: Value(id),
      remaining: Value(remaining),
      purchasedAt: Value(purchasedAt),
      productId: Value(productId),
    );
  }

  factory TopUpCredit.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TopUpCredit(
      id: serializer.fromJson<String>(json['id']),
      remaining: serializer.fromJson<int>(json['remaining']),
      purchasedAt: serializer.fromJson<DateTime>(json['purchasedAt']),
      productId: serializer.fromJson<String>(json['productId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'remaining': serializer.toJson<int>(remaining),
      'purchasedAt': serializer.toJson<DateTime>(purchasedAt),
      'productId': serializer.toJson<String>(productId),
    };
  }

  TopUpCredit copyWith(
          {String? id,
          int? remaining,
          DateTime? purchasedAt,
          String? productId}) =>
      TopUpCredit(
        id: id ?? this.id,
        remaining: remaining ?? this.remaining,
        purchasedAt: purchasedAt ?? this.purchasedAt,
        productId: productId ?? this.productId,
      );
  TopUpCredit copyWithCompanion(TopUpCreditsCompanion data) {
    return TopUpCredit(
      id: data.id.present ? data.id.value : this.id,
      remaining: data.remaining.present ? data.remaining.value : this.remaining,
      purchasedAt:
          data.purchasedAt.present ? data.purchasedAt.value : this.purchasedAt,
      productId: data.productId.present ? data.productId.value : this.productId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TopUpCredit(')
          ..write('id: $id, ')
          ..write('remaining: $remaining, ')
          ..write('purchasedAt: $purchasedAt, ')
          ..write('productId: $productId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, remaining, purchasedAt, productId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TopUpCredit &&
          other.id == this.id &&
          other.remaining == this.remaining &&
          other.purchasedAt == this.purchasedAt &&
          other.productId == this.productId);
}

class TopUpCreditsCompanion extends UpdateCompanion<TopUpCredit> {
  final Value<String> id;
  final Value<int> remaining;
  final Value<DateTime> purchasedAt;
  final Value<String> productId;
  final Value<int> rowid;
  const TopUpCreditsCompanion({
    this.id = const Value.absent(),
    this.remaining = const Value.absent(),
    this.purchasedAt = const Value.absent(),
    this.productId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TopUpCreditsCompanion.insert({
    required String id,
    required int remaining,
    required DateTime purchasedAt,
    required String productId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        remaining = Value(remaining),
        purchasedAt = Value(purchasedAt),
        productId = Value(productId);
  static Insertable<TopUpCredit> custom({
    Expression<String>? id,
    Expression<int>? remaining,
    Expression<DateTime>? purchasedAt,
    Expression<String>? productId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remaining != null) 'remaining': remaining,
      if (purchasedAt != null) 'purchased_at': purchasedAt,
      if (productId != null) 'product_id': productId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TopUpCreditsCompanion copyWith(
      {Value<String>? id,
      Value<int>? remaining,
      Value<DateTime>? purchasedAt,
      Value<String>? productId,
      Value<int>? rowid}) {
    return TopUpCreditsCompanion(
      id: id ?? this.id,
      remaining: remaining ?? this.remaining,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      productId: productId ?? this.productId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (remaining.present) {
      map['remaining'] = Variable<int>(remaining.value);
    }
    if (purchasedAt.present) {
      map['purchased_at'] = Variable<DateTime>(purchasedAt.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TopUpCreditsCompanion(')
          ..write('id: $id, ')
          ..write('remaining: $remaining, ')
          ..write('purchasedAt: $purchasedAt, ')
          ..write('productId: $productId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VoiceprintsTable extends Voiceprints
    with TableInfo<$VoiceprintsTable, Voiceprint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoiceprintsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _embeddingMeta =
      const VerificationMeta('embedding');
  @override
  late final GeneratedColumn<Uint8List> embedding = GeneratedColumn<Uint8List>(
      'embedding', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _avatarPathMeta =
      const VerificationMeta('avatarPath');
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
      'avatar_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, embedding, avatarPath, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voiceprints';
  @override
  VerificationContext validateIntegrity(Insertable<Voiceprint> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('embedding')) {
      context.handle(_embeddingMeta,
          embedding.isAcceptableOrUnknown(data['embedding']!, _embeddingMeta));
    } else if (isInserting) {
      context.missing(_embeddingMeta);
    }
    if (data.containsKey('avatar_path')) {
      context.handle(
          _avatarPathMeta,
          avatarPath.isAcceptableOrUnknown(
              data['avatar_path']!, _avatarPathMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Voiceprint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Voiceprint(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      embedding: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}embedding'])!,
      avatarPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}avatar_path']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $VoiceprintsTable createAlias(String alias) {
    return $VoiceprintsTable(attachedDatabase, alias);
  }
}

class Voiceprint extends DataClass implements Insertable<Voiceprint> {
  final String id;
  final String name;
  final Uint8List embedding;
  final String? avatarPath;
  final DateTime createdAt;
  const Voiceprint(
      {required this.id,
      required this.name,
      required this.embedding,
      this.avatarPath,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['embedding'] = Variable<Uint8List>(embedding);
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  VoiceprintsCompanion toCompanion(bool nullToAbsent) {
    return VoiceprintsCompanion(
      id: Value(id),
      name: Value(name),
      embedding: Value(embedding),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      createdAt: Value(createdAt),
    );
  }

  factory Voiceprint.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Voiceprint(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      embedding: serializer.fromJson<Uint8List>(json['embedding']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'embedding': serializer.toJson<Uint8List>(embedding),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Voiceprint copyWith(
          {String? id,
          String? name,
          Uint8List? embedding,
          Value<String?> avatarPath = const Value.absent(),
          DateTime? createdAt}) =>
      Voiceprint(
        id: id ?? this.id,
        name: name ?? this.name,
        embedding: embedding ?? this.embedding,
        avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
        createdAt: createdAt ?? this.createdAt,
      );
  Voiceprint copyWithCompanion(VoiceprintsCompanion data) {
    return Voiceprint(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      embedding: data.embedding.present ? data.embedding.value : this.embedding,
      avatarPath:
          data.avatarPath.present ? data.avatarPath.value : this.avatarPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Voiceprint(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('embedding: $embedding, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, $driftBlobEquality.hash(embedding), avatarPath, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Voiceprint &&
          other.id == this.id &&
          other.name == this.name &&
          $driftBlobEquality.equals(other.embedding, this.embedding) &&
          other.avatarPath == this.avatarPath &&
          other.createdAt == this.createdAt);
}

class VoiceprintsCompanion extends UpdateCompanion<Voiceprint> {
  final Value<String> id;
  final Value<String> name;
  final Value<Uint8List> embedding;
  final Value<String?> avatarPath;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const VoiceprintsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.embedding = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VoiceprintsCompanion.insert({
    required String id,
    required String name,
    required Uint8List embedding,
    this.avatarPath = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        embedding = Value(embedding),
        createdAt = Value(createdAt);
  static Insertable<Voiceprint> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<Uint8List>? embedding,
    Expression<String>? avatarPath,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (embedding != null) 'embedding': embedding,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VoiceprintsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<Uint8List>? embedding,
      Value<String?>? avatarPath,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return VoiceprintsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      embedding: embedding ?? this.embedding,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (embedding.present) {
      map['embedding'] = Variable<Uint8List>(embedding.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoiceprintsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('embedding: $embedding, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SegmentEmbeddingsTable extends SegmentEmbeddings
    with TableInfo<$SegmentEmbeddingsTable, SegmentEmbedding> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SegmentEmbeddingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _segmentIdMeta =
      const VerificationMeta('segmentId');
  @override
  late final GeneratedColumn<String> segmentId = GeneratedColumn<String>(
      'segment_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES transcript_segments (id) ON DELETE CASCADE'));
  static const VerificationMeta _meetingIdMeta =
      const VerificationMeta('meetingId');
  @override
  late final GeneratedColumn<String> meetingId = GeneratedColumn<String>(
      'meeting_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES meetings (id) ON DELETE CASCADE'));
  static const VerificationMeta _vecMeta = const VerificationMeta('vec');
  @override
  late final GeneratedColumn<Uint8List> vec = GeneratedColumn<Uint8List>(
      'vec', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _dimMeta = const VerificationMeta('dim');
  @override
  late final GeneratedColumn<int> dim = GeneratedColumn<int>(
      'dim', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(384));
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('all-MiniLM-L6-v2'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [segmentId, meetingId, vec, dim, model, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'segment_embeddings';
  @override
  VerificationContext validateIntegrity(Insertable<SegmentEmbedding> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('segment_id')) {
      context.handle(_segmentIdMeta,
          segmentId.isAcceptableOrUnknown(data['segment_id']!, _segmentIdMeta));
    } else if (isInserting) {
      context.missing(_segmentIdMeta);
    }
    if (data.containsKey('meeting_id')) {
      context.handle(_meetingIdMeta,
          meetingId.isAcceptableOrUnknown(data['meeting_id']!, _meetingIdMeta));
    } else if (isInserting) {
      context.missing(_meetingIdMeta);
    }
    if (data.containsKey('vec')) {
      context.handle(
          _vecMeta, vec.isAcceptableOrUnknown(data['vec']!, _vecMeta));
    } else if (isInserting) {
      context.missing(_vecMeta);
    }
    if (data.containsKey('dim')) {
      context.handle(
          _dimMeta, dim.isAcceptableOrUnknown(data['dim']!, _dimMeta));
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {segmentId};
  @override
  SegmentEmbedding map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SegmentEmbedding(
      segmentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}segment_id'])!,
      meetingId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meeting_id'])!,
      vec: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}vec'])!,
      dim: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}dim'])!,
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SegmentEmbeddingsTable createAlias(String alias) {
    return $SegmentEmbeddingsTable(attachedDatabase, alias);
  }
}

class SegmentEmbedding extends DataClass
    implements Insertable<SegmentEmbedding> {
  final String segmentId;
  final String meetingId;
  final Uint8List vec;

  /// Vector width, and the model that produced it.
  ///
  /// Without these, swapping the embedding model silently mixes two different
  /// vector spaces in one index: cosine similarity between them is meaningless,
  /// and search quietly returns nonsense with no error anywhere. The retriever
  /// filters on both.
  final int dim;
  final String model;
  final DateTime createdAt;
  const SegmentEmbedding(
      {required this.segmentId,
      required this.meetingId,
      required this.vec,
      required this.dim,
      required this.model,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['segment_id'] = Variable<String>(segmentId);
    map['meeting_id'] = Variable<String>(meetingId);
    map['vec'] = Variable<Uint8List>(vec);
    map['dim'] = Variable<int>(dim);
    map['model'] = Variable<String>(model);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SegmentEmbeddingsCompanion toCompanion(bool nullToAbsent) {
    return SegmentEmbeddingsCompanion(
      segmentId: Value(segmentId),
      meetingId: Value(meetingId),
      vec: Value(vec),
      dim: Value(dim),
      model: Value(model),
      createdAt: Value(createdAt),
    );
  }

  factory SegmentEmbedding.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SegmentEmbedding(
      segmentId: serializer.fromJson<String>(json['segmentId']),
      meetingId: serializer.fromJson<String>(json['meetingId']),
      vec: serializer.fromJson<Uint8List>(json['vec']),
      dim: serializer.fromJson<int>(json['dim']),
      model: serializer.fromJson<String>(json['model']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'segmentId': serializer.toJson<String>(segmentId),
      'meetingId': serializer.toJson<String>(meetingId),
      'vec': serializer.toJson<Uint8List>(vec),
      'dim': serializer.toJson<int>(dim),
      'model': serializer.toJson<String>(model),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SegmentEmbedding copyWith(
          {String? segmentId,
          String? meetingId,
          Uint8List? vec,
          int? dim,
          String? model,
          DateTime? createdAt}) =>
      SegmentEmbedding(
        segmentId: segmentId ?? this.segmentId,
        meetingId: meetingId ?? this.meetingId,
        vec: vec ?? this.vec,
        dim: dim ?? this.dim,
        model: model ?? this.model,
        createdAt: createdAt ?? this.createdAt,
      );
  SegmentEmbedding copyWithCompanion(SegmentEmbeddingsCompanion data) {
    return SegmentEmbedding(
      segmentId: data.segmentId.present ? data.segmentId.value : this.segmentId,
      meetingId: data.meetingId.present ? data.meetingId.value : this.meetingId,
      vec: data.vec.present ? data.vec.value : this.vec,
      dim: data.dim.present ? data.dim.value : this.dim,
      model: data.model.present ? data.model.value : this.model,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SegmentEmbedding(')
          ..write('segmentId: $segmentId, ')
          ..write('meetingId: $meetingId, ')
          ..write('vec: $vec, ')
          ..write('dim: $dim, ')
          ..write('model: $model, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(segmentId, meetingId,
      $driftBlobEquality.hash(vec), dim, model, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SegmentEmbedding &&
          other.segmentId == this.segmentId &&
          other.meetingId == this.meetingId &&
          $driftBlobEquality.equals(other.vec, this.vec) &&
          other.dim == this.dim &&
          other.model == this.model &&
          other.createdAt == this.createdAt);
}

class SegmentEmbeddingsCompanion extends UpdateCompanion<SegmentEmbedding> {
  final Value<String> segmentId;
  final Value<String> meetingId;
  final Value<Uint8List> vec;
  final Value<int> dim;
  final Value<String> model;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SegmentEmbeddingsCompanion({
    this.segmentId = const Value.absent(),
    this.meetingId = const Value.absent(),
    this.vec = const Value.absent(),
    this.dim = const Value.absent(),
    this.model = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SegmentEmbeddingsCompanion.insert({
    required String segmentId,
    required String meetingId,
    required Uint8List vec,
    this.dim = const Value.absent(),
    this.model = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : segmentId = Value(segmentId),
        meetingId = Value(meetingId),
        vec = Value(vec),
        createdAt = Value(createdAt);
  static Insertable<SegmentEmbedding> custom({
    Expression<String>? segmentId,
    Expression<String>? meetingId,
    Expression<Uint8List>? vec,
    Expression<int>? dim,
    Expression<String>? model,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (segmentId != null) 'segment_id': segmentId,
      if (meetingId != null) 'meeting_id': meetingId,
      if (vec != null) 'vec': vec,
      if (dim != null) 'dim': dim,
      if (model != null) 'model': model,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SegmentEmbeddingsCompanion copyWith(
      {Value<String>? segmentId,
      Value<String>? meetingId,
      Value<Uint8List>? vec,
      Value<int>? dim,
      Value<String>? model,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return SegmentEmbeddingsCompanion(
      segmentId: segmentId ?? this.segmentId,
      meetingId: meetingId ?? this.meetingId,
      vec: vec ?? this.vec,
      dim: dim ?? this.dim,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (segmentId.present) {
      map['segment_id'] = Variable<String>(segmentId.value);
    }
    if (meetingId.present) {
      map['meeting_id'] = Variable<String>(meetingId.value);
    }
    if (vec.present) {
      map['vec'] = Variable<Uint8List>(vec.value);
    }
    if (dim.present) {
      map['dim'] = Variable<int>(dim.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SegmentEmbeddingsCompanion(')
          ..write('segmentId: $segmentId, ')
          ..write('meetingId: $meetingId, ')
          ..write('vec: $vec, ')
          ..write('dim: $dim, ')
          ..write('model: $model, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActionItemsTable extends ActionItems
    with TableInfo<$ActionItemsTable, ActionItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActionItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _meetingIdMeta =
      const VerificationMeta('meetingId');
  @override
  late final GeneratedColumn<String> meetingId = GeneratedColumn<String>(
      'meeting_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES meetings (id) ON DELETE CASCADE'));
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _assigneeMeta =
      const VerificationMeta('assignee');
  @override
  late final GeneratedColumn<String> assignee = GeneratedColumn<String>(
      'assignee', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<ActionItemStatus, String> status =
      GeneratedColumn<String>('status', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('open'))
          .withConverter<ActionItemStatus>($ActionItemsTable.$converterstatus);
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
  List<GeneratedColumn> get $columns =>
      [id, meetingId, body, assignee, dueDate, status, createdAt, completedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'action_items';
  @override
  VerificationContext validateIntegrity(Insertable<ActionItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('meeting_id')) {
      context.handle(_meetingIdMeta,
          meetingId.isAcceptableOrUnknown(data['meeting_id']!, _meetingIdMeta));
    } else if (isInserting) {
      context.missing(_meetingIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('assignee')) {
      context.handle(_assigneeMeta,
          assignee.isAcceptableOrUnknown(data['assignee']!, _assigneeMeta));
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
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
  ActionItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActionItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      meetingId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meeting_id'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      assignee: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}assignee']),
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      status: $ActionItemsTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
    );
  }

  @override
  $ActionItemsTable createAlias(String alias) {
    return $ActionItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ActionItemStatus, String, String> $converterstatus =
      const EnumNameConverter<ActionItemStatus>(ActionItemStatus.values);
}

class ActionItem extends DataClass implements Insertable<ActionItem> {
  final String id;
  final String meetingId;
  final String body;
  final String? assignee;
  final DateTime? dueDate;
  final ActionItemStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  const ActionItem(
      {required this.id,
      required this.meetingId,
      required this.body,
      this.assignee,
      this.dueDate,
      required this.status,
      required this.createdAt,
      this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['meeting_id'] = Variable<String>(meetingId);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || assignee != null) {
      map['assignee'] = Variable<String>(assignee);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    {
      map['status'] =
          Variable<String>($ActionItemsTable.$converterstatus.toSql(status));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  ActionItemsCompanion toCompanion(bool nullToAbsent) {
    return ActionItemsCompanion(
      id: Value(id),
      meetingId: Value(meetingId),
      body: Value(body),
      assignee: assignee == null && nullToAbsent
          ? const Value.absent()
          : Value(assignee),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      status: Value(status),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory ActionItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActionItem(
      id: serializer.fromJson<String>(json['id']),
      meetingId: serializer.fromJson<String>(json['meetingId']),
      body: serializer.fromJson<String>(json['body']),
      assignee: serializer.fromJson<String?>(json['assignee']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      status: $ActionItemsTable.$converterstatus
          .fromJson(serializer.fromJson<String>(json['status'])),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'meetingId': serializer.toJson<String>(meetingId),
      'body': serializer.toJson<String>(body),
      'assignee': serializer.toJson<String?>(assignee),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'status': serializer
          .toJson<String>($ActionItemsTable.$converterstatus.toJson(status)),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  ActionItem copyWith(
          {String? id,
          String? meetingId,
          String? body,
          Value<String?> assignee = const Value.absent(),
          Value<DateTime?> dueDate = const Value.absent(),
          ActionItemStatus? status,
          DateTime? createdAt,
          Value<DateTime?> completedAt = const Value.absent()}) =>
      ActionItem(
        id: id ?? this.id,
        meetingId: meetingId ?? this.meetingId,
        body: body ?? this.body,
        assignee: assignee.present ? assignee.value : this.assignee,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
      );
  ActionItem copyWithCompanion(ActionItemsCompanion data) {
    return ActionItem(
      id: data.id.present ? data.id.value : this.id,
      meetingId: data.meetingId.present ? data.meetingId.value : this.meetingId,
      body: data.body.present ? data.body.value : this.body,
      assignee: data.assignee.present ? data.assignee.value : this.assignee,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActionItem(')
          ..write('id: $id, ')
          ..write('meetingId: $meetingId, ')
          ..write('body: $body, ')
          ..write('assignee: $assignee, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, meetingId, body, assignee, dueDate, status, createdAt, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActionItem &&
          other.id == this.id &&
          other.meetingId == this.meetingId &&
          other.body == this.body &&
          other.assignee == this.assignee &&
          other.dueDate == this.dueDate &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt);
}

class ActionItemsCompanion extends UpdateCompanion<ActionItem> {
  final Value<String> id;
  final Value<String> meetingId;
  final Value<String> body;
  final Value<String?> assignee;
  final Value<DateTime?> dueDate;
  final Value<ActionItemStatus> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const ActionItemsCompanion({
    this.id = const Value.absent(),
    this.meetingId = const Value.absent(),
    this.body = const Value.absent(),
    this.assignee = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActionItemsCompanion.insert({
    required String id,
    required String meetingId,
    required String body,
    this.assignee = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        meetingId = Value(meetingId),
        body = Value(body),
        createdAt = Value(createdAt);
  static Insertable<ActionItem> custom({
    Expression<String>? id,
    Expression<String>? meetingId,
    Expression<String>? body,
    Expression<String>? assignee,
    Expression<DateTime>? dueDate,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (meetingId != null) 'meeting_id': meetingId,
      if (body != null) 'body': body,
      if (assignee != null) 'assignee': assignee,
      if (dueDate != null) 'due_date': dueDate,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActionItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? meetingId,
      Value<String>? body,
      Value<String?>? assignee,
      Value<DateTime?>? dueDate,
      Value<ActionItemStatus>? status,
      Value<DateTime>? createdAt,
      Value<DateTime?>? completedAt,
      Value<int>? rowid}) {
    return ActionItemsCompanion(
      id: id ?? this.id,
      meetingId: meetingId ?? this.meetingId,
      body: body ?? this.body,
      assignee: assignee ?? this.assignee,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (meetingId.present) {
      map['meeting_id'] = Variable<String>(meetingId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (assignee.present) {
      map['assignee'] = Variable<String>(assignee.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
          $ActionItemsTable.$converterstatus.toSql(status.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActionItemsCompanion(')
          ..write('id: $id, ')
          ..write('meetingId: $meetingId, ')
          ..write('body: $body, ')
          ..write('assignee: $assignee, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoldersTable extends Folders with TableInfo<$FoldersTable, Folder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorIndexMeta =
      const VerificationMeta('colorIndex');
  @override
  late final GeneratedColumn<int> colorIndex = GeneratedColumn<int>(
      'color_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, parentId, colorIndex, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folders';
  @override
  VerificationContext validateIntegrity(Insertable<Folder> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('color_index')) {
      context.handle(
          _colorIndexMeta,
          colorIndex.isAcceptableOrUnknown(
              data['color_index']!, _colorIndexMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Folder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Folder(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      colorIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color_index'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $FoldersTable createAlias(String alias) {
    return $FoldersTable(attachedDatabase, alias);
  }
}

class Folder extends DataClass implements Insertable<Folder> {
  final String id;
  final String name;
  final String? parentId;
  final int colorIndex;
  final DateTime createdAt;
  const Folder(
      {required this.id,
      required this.name,
      this.parentId,
      required this.colorIndex,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['color_index'] = Variable<int>(colorIndex);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FoldersCompanion toCompanion(bool nullToAbsent) {
    return FoldersCompanion(
      id: Value(id),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      colorIndex: Value(colorIndex),
      createdAt: Value(createdAt),
    );
  }

  factory Folder.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Folder(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      colorIndex: serializer.fromJson<int>(json['colorIndex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'colorIndex': serializer.toJson<int>(colorIndex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Folder copyWith(
          {String? id,
          String? name,
          Value<String?> parentId = const Value.absent(),
          int? colorIndex,
          DateTime? createdAt}) =>
      Folder(
        id: id ?? this.id,
        name: name ?? this.name,
        parentId: parentId.present ? parentId.value : this.parentId,
        colorIndex: colorIndex ?? this.colorIndex,
        createdAt: createdAt ?? this.createdAt,
      );
  Folder copyWithCompanion(FoldersCompanion data) {
    return Folder(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      colorIndex:
          data.colorIndex.present ? data.colorIndex.value : this.colorIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Folder(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, parentId, colorIndex, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Folder &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.colorIndex == this.colorIndex &&
          other.createdAt == this.createdAt);
}

class FoldersCompanion extends UpdateCompanion<Folder> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<int> colorIndex;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoldersCompanion.insert({
    required String id,
    required String name,
    this.parentId = const Value.absent(),
    this.colorIndex = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<Folder> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<int>? colorIndex,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (colorIndex != null) 'color_index': colorIndex,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoldersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? parentId,
      Value<int>? colorIndex,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return FoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (colorIndex.present) {
      map['color_index'] = Variable<int>(colorIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MeetingFoldersTable extends MeetingFolders
    with TableInfo<$MeetingFoldersTable, MeetingFolder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeetingFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _meetingIdMeta =
      const VerificationMeta('meetingId');
  @override
  late final GeneratedColumn<String> meetingId = GeneratedColumn<String>(
      'meeting_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES meetings (id) ON DELETE CASCADE'));
  static const VerificationMeta _folderIdMeta =
      const VerificationMeta('folderId');
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
      'folder_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES folders (id) ON DELETE CASCADE'));
  @override
  List<GeneratedColumn> get $columns => [meetingId, folderId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meeting_folders';
  @override
  VerificationContext validateIntegrity(Insertable<MeetingFolder> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('meeting_id')) {
      context.handle(_meetingIdMeta,
          meetingId.isAcceptableOrUnknown(data['meeting_id']!, _meetingIdMeta));
    } else if (isInserting) {
      context.missing(_meetingIdMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(_folderIdMeta,
          folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta));
    } else if (isInserting) {
      context.missing(_folderIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {meetingId, folderId};
  @override
  MeetingFolder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeetingFolder(
      meetingId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meeting_id'])!,
      folderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_id'])!,
    );
  }

  @override
  $MeetingFoldersTable createAlias(String alias) {
    return $MeetingFoldersTable(attachedDatabase, alias);
  }
}

class MeetingFolder extends DataClass implements Insertable<MeetingFolder> {
  final String meetingId;
  final String folderId;
  const MeetingFolder({required this.meetingId, required this.folderId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['meeting_id'] = Variable<String>(meetingId);
    map['folder_id'] = Variable<String>(folderId);
    return map;
  }

  MeetingFoldersCompanion toCompanion(bool nullToAbsent) {
    return MeetingFoldersCompanion(
      meetingId: Value(meetingId),
      folderId: Value(folderId),
    );
  }

  factory MeetingFolder.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeetingFolder(
      meetingId: serializer.fromJson<String>(json['meetingId']),
      folderId: serializer.fromJson<String>(json['folderId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'meetingId': serializer.toJson<String>(meetingId),
      'folderId': serializer.toJson<String>(folderId),
    };
  }

  MeetingFolder copyWith({String? meetingId, String? folderId}) =>
      MeetingFolder(
        meetingId: meetingId ?? this.meetingId,
        folderId: folderId ?? this.folderId,
      );
  MeetingFolder copyWithCompanion(MeetingFoldersCompanion data) {
    return MeetingFolder(
      meetingId: data.meetingId.present ? data.meetingId.value : this.meetingId,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeetingFolder(')
          ..write('meetingId: $meetingId, ')
          ..write('folderId: $folderId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(meetingId, folderId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeetingFolder &&
          other.meetingId == this.meetingId &&
          other.folderId == this.folderId);
}

class MeetingFoldersCompanion extends UpdateCompanion<MeetingFolder> {
  final Value<String> meetingId;
  final Value<String> folderId;
  final Value<int> rowid;
  const MeetingFoldersCompanion({
    this.meetingId = const Value.absent(),
    this.folderId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeetingFoldersCompanion.insert({
    required String meetingId,
    required String folderId,
    this.rowid = const Value.absent(),
  })  : meetingId = Value(meetingId),
        folderId = Value(folderId);
  static Insertable<MeetingFolder> custom({
    Expression<String>? meetingId,
    Expression<String>? folderId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (meetingId != null) 'meeting_id': meetingId,
      if (folderId != null) 'folder_id': folderId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeetingFoldersCompanion copyWith(
      {Value<String>? meetingId, Value<String>? folderId, Value<int>? rowid}) {
    return MeetingFoldersCompanion(
      meetingId: meetingId ?? this.meetingId,
      folderId: folderId ?? this.folderId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (meetingId.present) {
      map['meeting_id'] = Variable<String>(meetingId.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeetingFoldersCompanion(')
          ..write('meetingId: $meetingId, ')
          ..write('folderId: $folderId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MeetingTagsTable extends MeetingTags
    with TableInfo<$MeetingTagsTable, MeetingTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeetingTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _meetingIdMeta =
      const VerificationMeta('meetingId');
  @override
  late final GeneratedColumn<String> meetingId = GeneratedColumn<String>(
      'meeting_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES meetings (id) ON DELETE CASCADE'));
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
      'tag', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [meetingId, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meeting_tags';
  @override
  VerificationContext validateIntegrity(Insertable<MeetingTag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('meeting_id')) {
      context.handle(_meetingIdMeta,
          meetingId.isAcceptableOrUnknown(data['meeting_id']!, _meetingIdMeta));
    } else if (isInserting) {
      context.missing(_meetingIdMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
          _tagMeta, tag.isAcceptableOrUnknown(data['tag']!, _tagMeta));
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {meetingId, tag};
  @override
  MeetingTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeetingTag(
      meetingId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meeting_id'])!,
      tag: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag'])!,
    );
  }

  @override
  $MeetingTagsTable createAlias(String alias) {
    return $MeetingTagsTable(attachedDatabase, alias);
  }
}

class MeetingTag extends DataClass implements Insertable<MeetingTag> {
  final String meetingId;
  final String tag;
  const MeetingTag({required this.meetingId, required this.tag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['meeting_id'] = Variable<String>(meetingId);
    map['tag'] = Variable<String>(tag);
    return map;
  }

  MeetingTagsCompanion toCompanion(bool nullToAbsent) {
    return MeetingTagsCompanion(
      meetingId: Value(meetingId),
      tag: Value(tag),
    );
  }

  factory MeetingTag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeetingTag(
      meetingId: serializer.fromJson<String>(json['meetingId']),
      tag: serializer.fromJson<String>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'meetingId': serializer.toJson<String>(meetingId),
      'tag': serializer.toJson<String>(tag),
    };
  }

  MeetingTag copyWith({String? meetingId, String? tag}) => MeetingTag(
        meetingId: meetingId ?? this.meetingId,
        tag: tag ?? this.tag,
      );
  MeetingTag copyWithCompanion(MeetingTagsCompanion data) {
    return MeetingTag(
      meetingId: data.meetingId.present ? data.meetingId.value : this.meetingId,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeetingTag(')
          ..write('meetingId: $meetingId, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(meetingId, tag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeetingTag &&
          other.meetingId == this.meetingId &&
          other.tag == this.tag);
}

class MeetingTagsCompanion extends UpdateCompanion<MeetingTag> {
  final Value<String> meetingId;
  final Value<String> tag;
  final Value<int> rowid;
  const MeetingTagsCompanion({
    this.meetingId = const Value.absent(),
    this.tag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeetingTagsCompanion.insert({
    required String meetingId,
    required String tag,
    this.rowid = const Value.absent(),
  })  : meetingId = Value(meetingId),
        tag = Value(tag);
  static Insertable<MeetingTag> custom({
    Expression<String>? meetingId,
    Expression<String>? tag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (meetingId != null) 'meeting_id': meetingId,
      if (tag != null) 'tag': tag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeetingTagsCompanion copyWith(
      {Value<String>? meetingId, Value<String>? tag, Value<int>? rowid}) {
    return MeetingTagsCompanion(
      meetingId: meetingId ?? this.meetingId,
      tag: tag ?? this.tag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (meetingId.present) {
      map['meeting_id'] = Variable<String>(meetingId.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeetingTagsCompanion(')
          ..write('meetingId: $meetingId, ')
          ..write('tag: $tag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TranslationCacheTable extends TranslationCache
    with TableInfo<$TranslationCacheTable, TranslationCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranslationCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceHashMeta =
      const VerificationMeta('sourceHash');
  @override
  late final GeneratedColumn<String> sourceHash = GeneratedColumn<String>(
      'source_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceLangMeta =
      const VerificationMeta('sourceLang');
  @override
  late final GeneratedColumn<String> sourceLang = GeneratedColumn<String>(
      'source_lang', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetLangMeta =
      const VerificationMeta('targetLang');
  @override
  late final GeneratedColumn<String> targetLang = GeneratedColumn<String>(
      'target_lang', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceTextMeta =
      const VerificationMeta('sourceText');
  @override
  late final GeneratedColumn<String> sourceText = GeneratedColumn<String>(
      'source_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _translationMeta =
      const VerificationMeta('translation');
  @override
  late final GeneratedColumn<String> translation = GeneratedColumn<String>(
      'translation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [sourceHash, sourceLang, targetLang, sourceText, translation, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'translation_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<TranslationCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_hash')) {
      context.handle(
          _sourceHashMeta,
          sourceHash.isAcceptableOrUnknown(
              data['source_hash']!, _sourceHashMeta));
    } else if (isInserting) {
      context.missing(_sourceHashMeta);
    }
    if (data.containsKey('source_lang')) {
      context.handle(
          _sourceLangMeta,
          sourceLang.isAcceptableOrUnknown(
              data['source_lang']!, _sourceLangMeta));
    } else if (isInserting) {
      context.missing(_sourceLangMeta);
    }
    if (data.containsKey('target_lang')) {
      context.handle(
          _targetLangMeta,
          targetLang.isAcceptableOrUnknown(
              data['target_lang']!, _targetLangMeta));
    } else if (isInserting) {
      context.missing(_targetLangMeta);
    }
    if (data.containsKey('source_text')) {
      context.handle(
          _sourceTextMeta,
          sourceText.isAcceptableOrUnknown(
              data['source_text']!, _sourceTextMeta));
    } else if (isInserting) {
      context.missing(_sourceTextMeta);
    }
    if (data.containsKey('translation')) {
      context.handle(
          _translationMeta,
          translation.isAcceptableOrUnknown(
              data['translation']!, _translationMeta));
    } else if (isInserting) {
      context.missing(_translationMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceHash, sourceLang, targetLang};
  @override
  TranslationCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TranslationCacheData(
      sourceHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_hash'])!,
      sourceLang: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_lang'])!,
      targetLang: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_lang'])!,
      sourceText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_text'])!,
      translation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}translation'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TranslationCacheTable createAlias(String alias) {
    return $TranslationCacheTable(attachedDatabase, alias);
  }
}

class TranslationCacheData extends DataClass
    implements Insertable<TranslationCacheData> {
  final String sourceHash;
  final String sourceLang;
  final String targetLang;
  final String sourceText;
  final String translation;
  final DateTime createdAt;
  const TranslationCacheData(
      {required this.sourceHash,
      required this.sourceLang,
      required this.targetLang,
      required this.sourceText,
      required this.translation,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_hash'] = Variable<String>(sourceHash);
    map['source_lang'] = Variable<String>(sourceLang);
    map['target_lang'] = Variable<String>(targetLang);
    map['source_text'] = Variable<String>(sourceText);
    map['translation'] = Variable<String>(translation);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TranslationCacheCompanion toCompanion(bool nullToAbsent) {
    return TranslationCacheCompanion(
      sourceHash: Value(sourceHash),
      sourceLang: Value(sourceLang),
      targetLang: Value(targetLang),
      sourceText: Value(sourceText),
      translation: Value(translation),
      createdAt: Value(createdAt),
    );
  }

  factory TranslationCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TranslationCacheData(
      sourceHash: serializer.fromJson<String>(json['sourceHash']),
      sourceLang: serializer.fromJson<String>(json['sourceLang']),
      targetLang: serializer.fromJson<String>(json['targetLang']),
      sourceText: serializer.fromJson<String>(json['sourceText']),
      translation: serializer.fromJson<String>(json['translation']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceHash': serializer.toJson<String>(sourceHash),
      'sourceLang': serializer.toJson<String>(sourceLang),
      'targetLang': serializer.toJson<String>(targetLang),
      'sourceText': serializer.toJson<String>(sourceText),
      'translation': serializer.toJson<String>(translation),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TranslationCacheData copyWith(
          {String? sourceHash,
          String? sourceLang,
          String? targetLang,
          String? sourceText,
          String? translation,
          DateTime? createdAt}) =>
      TranslationCacheData(
        sourceHash: sourceHash ?? this.sourceHash,
        sourceLang: sourceLang ?? this.sourceLang,
        targetLang: targetLang ?? this.targetLang,
        sourceText: sourceText ?? this.sourceText,
        translation: translation ?? this.translation,
        createdAt: createdAt ?? this.createdAt,
      );
  TranslationCacheData copyWithCompanion(TranslationCacheCompanion data) {
    return TranslationCacheData(
      sourceHash:
          data.sourceHash.present ? data.sourceHash.value : this.sourceHash,
      sourceLang:
          data.sourceLang.present ? data.sourceLang.value : this.sourceLang,
      targetLang:
          data.targetLang.present ? data.targetLang.value : this.targetLang,
      sourceText:
          data.sourceText.present ? data.sourceText.value : this.sourceText,
      translation:
          data.translation.present ? data.translation.value : this.translation,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TranslationCacheData(')
          ..write('sourceHash: $sourceHash, ')
          ..write('sourceLang: $sourceLang, ')
          ..write('targetLang: $targetLang, ')
          ..write('sourceText: $sourceText, ')
          ..write('translation: $translation, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      sourceHash, sourceLang, targetLang, sourceText, translation, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TranslationCacheData &&
          other.sourceHash == this.sourceHash &&
          other.sourceLang == this.sourceLang &&
          other.targetLang == this.targetLang &&
          other.sourceText == this.sourceText &&
          other.translation == this.translation &&
          other.createdAt == this.createdAt);
}

class TranslationCacheCompanion extends UpdateCompanion<TranslationCacheData> {
  final Value<String> sourceHash;
  final Value<String> sourceLang;
  final Value<String> targetLang;
  final Value<String> sourceText;
  final Value<String> translation;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TranslationCacheCompanion({
    this.sourceHash = const Value.absent(),
    this.sourceLang = const Value.absent(),
    this.targetLang = const Value.absent(),
    this.sourceText = const Value.absent(),
    this.translation = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TranslationCacheCompanion.insert({
    required String sourceHash,
    required String sourceLang,
    required String targetLang,
    required String sourceText,
    required String translation,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : sourceHash = Value(sourceHash),
        sourceLang = Value(sourceLang),
        targetLang = Value(targetLang),
        sourceText = Value(sourceText),
        translation = Value(translation),
        createdAt = Value(createdAt);
  static Insertable<TranslationCacheData> custom({
    Expression<String>? sourceHash,
    Expression<String>? sourceLang,
    Expression<String>? targetLang,
    Expression<String>? sourceText,
    Expression<String>? translation,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceHash != null) 'source_hash': sourceHash,
      if (sourceLang != null) 'source_lang': sourceLang,
      if (targetLang != null) 'target_lang': targetLang,
      if (sourceText != null) 'source_text': sourceText,
      if (translation != null) 'translation': translation,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TranslationCacheCompanion copyWith(
      {Value<String>? sourceHash,
      Value<String>? sourceLang,
      Value<String>? targetLang,
      Value<String>? sourceText,
      Value<String>? translation,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return TranslationCacheCompanion(
      sourceHash: sourceHash ?? this.sourceHash,
      sourceLang: sourceLang ?? this.sourceLang,
      targetLang: targetLang ?? this.targetLang,
      sourceText: sourceText ?? this.sourceText,
      translation: translation ?? this.translation,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceHash.present) {
      map['source_hash'] = Variable<String>(sourceHash.value);
    }
    if (sourceLang.present) {
      map['source_lang'] = Variable<String>(sourceLang.value);
    }
    if (targetLang.present) {
      map['target_lang'] = Variable<String>(targetLang.value);
    }
    if (sourceText.present) {
      map['source_text'] = Variable<String>(sourceText.value);
    }
    if (translation.present) {
      map['translation'] = Variable<String>(translation.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranslationCacheCompanion(')
          ..write('sourceHash: $sourceHash, ')
          ..write('sourceLang: $sourceLang, ')
          ..write('targetLang: $targetLang, ')
          ..write('sourceText: $sourceText, ')
          ..write('translation: $translation, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GlossaryTermsTable extends GlossaryTerms
    with TableInfo<$GlossaryTermsTable, GlossaryTerm> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GlossaryTermsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _termMeta = const VerificationMeta('term');
  @override
  late final GeneratedColumn<String> term = GeneratedColumn<String>(
      'term', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [term, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'glossary_terms';
  @override
  VerificationContext validateIntegrity(Insertable<GlossaryTerm> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('term')) {
      context.handle(
          _termMeta, term.isAcceptableOrUnknown(data['term']!, _termMeta));
    } else if (isInserting) {
      context.missing(_termMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {term};
  @override
  GlossaryTerm map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GlossaryTerm(
      term: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}term'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $GlossaryTermsTable createAlias(String alias) {
    return $GlossaryTermsTable(attachedDatabase, alias);
  }
}

class GlossaryTerm extends DataClass implements Insertable<GlossaryTerm> {
  final String term;
  final String? note;
  final DateTime createdAt;
  const GlossaryTerm({required this.term, this.note, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['term'] = Variable<String>(term);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GlossaryTermsCompanion toCompanion(bool nullToAbsent) {
    return GlossaryTermsCompanion(
      term: Value(term),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory GlossaryTerm.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GlossaryTerm(
      term: serializer.fromJson<String>(json['term']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'term': serializer.toJson<String>(term),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GlossaryTerm copyWith(
          {String? term,
          Value<String?> note = const Value.absent(),
          DateTime? createdAt}) =>
      GlossaryTerm(
        term: term ?? this.term,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  GlossaryTerm copyWithCompanion(GlossaryTermsCompanion data) {
    return GlossaryTerm(
      term: data.term.present ? data.term.value : this.term,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GlossaryTerm(')
          ..write('term: $term, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(term, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GlossaryTerm &&
          other.term == this.term &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class GlossaryTermsCompanion extends UpdateCompanion<GlossaryTerm> {
  final Value<String> term;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const GlossaryTermsCompanion({
    this.term = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GlossaryTermsCompanion.insert({
    required String term,
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : term = Value(term),
        createdAt = Value(createdAt);
  static Insertable<GlossaryTerm> custom({
    Expression<String>? term,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (term != null) 'term': term,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GlossaryTermsCompanion copyWith(
      {Value<String>? term,
      Value<String?>? note,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return GlossaryTermsCompanion(
      term: term ?? this.term,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (term.present) {
      map['term'] = Variable<String>(term.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GlossaryTermsCompanion(')
          ..write('term: $term, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PurchasesTable extends Purchases
    with TableInfo<$PurchasesTable, Purchase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  @override
  late final GeneratedColumn<String> tier = GeneratedColumn<String>(
      'tier', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _purchasedAtMeta =
      const VerificationMeta('purchasedAt');
  @override
  late final GeneratedColumn<DateTime> purchasedAt = GeneratedColumn<DateTime>(
      'purchased_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('store'));
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, productId, tier, purchasedAt, source, recordedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchases';
  @override
  VerificationContext validateIntegrity(Insertable<Purchase> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('tier')) {
      context.handle(
          _tierMeta, tier.isAcceptableOrUnknown(data['tier']!, _tierMeta));
    }
    if (data.containsKey('purchased_at')) {
      context.handle(
          _purchasedAtMeta,
          purchasedAt.isAcceptableOrUnknown(
              data['purchased_at']!, _purchasedAtMeta));
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Purchase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Purchase(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      tier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tier']),
      purchasedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}purchased_at']),
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
    );
  }

  @override
  $PurchasesTable createAlias(String alias) {
    return $PurchasesTable(attachedDatabase, alias);
  }
}

class Purchase extends DataClass implements Insertable<Purchase> {
  /// Store-issued purchase/transaction id (falls back to the product id for
  /// stores that omit it).
  final String id;
  final String productId;

  /// The [Tier] this purchase grants, by enum name. Null for top-up packs,
  /// which grant credits rather than a tier.
  final String? tier;

  /// Store transaction date. Nullable on purpose: the two stores disagree on
  /// the format (Android sends ms-since-epoch, iOS sends a date string), and
  /// recording "unknown" is better than fabricating DateTime.now() — the
  /// lifetime-grandfathering invariant is enforced against this value, so a
  /// wrong date silently corrupts it.
  final DateTime? purchasedAt;

  /// 'store' | 'debug_override'. A debug tier switch must never be mistaken
  /// for a real purchase.
  final String source;
  final DateTime recordedAt;
  const Purchase(
      {required this.id,
      required this.productId,
      this.tier,
      this.purchasedAt,
      required this.source,
      required this.recordedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    if (!nullToAbsent || tier != null) {
      map['tier'] = Variable<String>(tier);
    }
    if (!nullToAbsent || purchasedAt != null) {
      map['purchased_at'] = Variable<DateTime>(purchasedAt);
    }
    map['source'] = Variable<String>(source);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  PurchasesCompanion toCompanion(bool nullToAbsent) {
    return PurchasesCompanion(
      id: Value(id),
      productId: Value(productId),
      tier: tier == null && nullToAbsent ? const Value.absent() : Value(tier),
      purchasedAt: purchasedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasedAt),
      source: Value(source),
      recordedAt: Value(recordedAt),
    );
  }

  factory Purchase.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Purchase(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      tier: serializer.fromJson<String?>(json['tier']),
      purchasedAt: serializer.fromJson<DateTime?>(json['purchasedAt']),
      source: serializer.fromJson<String>(json['source']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'tier': serializer.toJson<String?>(tier),
      'purchasedAt': serializer.toJson<DateTime?>(purchasedAt),
      'source': serializer.toJson<String>(source),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  Purchase copyWith(
          {String? id,
          String? productId,
          Value<String?> tier = const Value.absent(),
          Value<DateTime?> purchasedAt = const Value.absent(),
          String? source,
          DateTime? recordedAt}) =>
      Purchase(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        tier: tier.present ? tier.value : this.tier,
        purchasedAt: purchasedAt.present ? purchasedAt.value : this.purchasedAt,
        source: source ?? this.source,
        recordedAt: recordedAt ?? this.recordedAt,
      );
  Purchase copyWithCompanion(PurchasesCompanion data) {
    return Purchase(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      tier: data.tier.present ? data.tier.value : this.tier,
      purchasedAt:
          data.purchasedAt.present ? data.purchasedAt.value : this.purchasedAt,
      source: data.source.present ? data.source.value : this.source,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Purchase(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('tier: $tier, ')
          ..write('purchasedAt: $purchasedAt, ')
          ..write('source: $source, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productId, tier, purchasedAt, source, recordedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Purchase &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.tier == this.tier &&
          other.purchasedAt == this.purchasedAt &&
          other.source == this.source &&
          other.recordedAt == this.recordedAt);
}

class PurchasesCompanion extends UpdateCompanion<Purchase> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String?> tier;
  final Value<DateTime?> purchasedAt;
  final Value<String> source;
  final Value<DateTime> recordedAt;
  final Value<int> rowid;
  const PurchasesCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.tier = const Value.absent(),
    this.purchasedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchasesCompanion.insert({
    required String id,
    required String productId,
    this.tier = const Value.absent(),
    this.purchasedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        productId = Value(productId);
  static Insertable<Purchase> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? tier,
    Expression<DateTime>? purchasedAt,
    Expression<String>? source,
    Expression<DateTime>? recordedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (tier != null) 'tier': tier,
      if (purchasedAt != null) 'purchased_at': purchasedAt,
      if (source != null) 'source': source,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchasesCompanion copyWith(
      {Value<String>? id,
      Value<String>? productId,
      Value<String?>? tier,
      Value<DateTime?>? purchasedAt,
      Value<String>? source,
      Value<DateTime>? recordedAt,
      Value<int>? rowid}) {
    return PurchasesCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      tier: tier ?? this.tier,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      source: source ?? this.source,
      recordedAt: recordedAt ?? this.recordedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (tier.present) {
      map['tier'] = Variable<String>(tier.value);
    }
    if (purchasedAt.present) {
      map['purchased_at'] = Variable<DateTime>(purchasedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchasesCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('tier: $tier, ')
          ..write('purchasedAt: $purchasedAt, ')
          ..write('source: $source, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplatesTable extends Templates
    with TableInfo<$TemplatesTable, Template> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 60),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
      'emoji', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('✨'));
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
      'prompt', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _builtinKeyMeta =
      const VerificationMeta('builtinKey');
  @override
  late final GeneratedColumn<String> builtinKey = GeneratedColumn<String>(
      'builtin_key', aliasedName, true,
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
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, emoji, prompt, builtinKey, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'templates';
  @override
  VerificationContext validateIntegrity(Insertable<Template> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
          _emojiMeta, emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta));
    }
    if (data.containsKey('prompt')) {
      context.handle(_promptMeta,
          prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta));
    } else if (isInserting) {
      context.missing(_promptMeta);
    }
    if (data.containsKey('builtin_key')) {
      context.handle(
          _builtinKeyMeta,
          builtinKey.isAcceptableOrUnknown(
              data['builtin_key']!, _builtinKeyMeta));
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
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Template map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Template(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      emoji: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}emoji'])!,
      prompt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prompt'])!,
      builtinKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}builtin_key']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TemplatesTable createAlias(String alias) {
    return $TemplatesTable(attachedDatabase, alias);
  }
}

class Template extends DataClass implements Insertable<Template> {
  /// `custom:<uuid>`. The `custom:` prefix is load-bearing — [resolvePersona]
  /// keys off it to tell a user template from one of the 7 built-ins.
  final String id;
  final String name;
  final String emoji;
  final String prompt;

  /// Set when this template was created by duplicating a built-in, so the
  /// editor can show what it was forked from.
  final String? builtinKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Template(
      {required this.id,
      required this.name,
      required this.emoji,
      required this.prompt,
      this.builtinKey,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['emoji'] = Variable<String>(emoji);
    map['prompt'] = Variable<String>(prompt);
    if (!nullToAbsent || builtinKey != null) {
      map['builtin_key'] = Variable<String>(builtinKey);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TemplatesCompanion toCompanion(bool nullToAbsent) {
    return TemplatesCompanion(
      id: Value(id),
      name: Value(name),
      emoji: Value(emoji),
      prompt: Value(prompt),
      builtinKey: builtinKey == null && nullToAbsent
          ? const Value.absent()
          : Value(builtinKey),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Template.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Template(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      emoji: serializer.fromJson<String>(json['emoji']),
      prompt: serializer.fromJson<String>(json['prompt']),
      builtinKey: serializer.fromJson<String?>(json['builtinKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'emoji': serializer.toJson<String>(emoji),
      'prompt': serializer.toJson<String>(prompt),
      'builtinKey': serializer.toJson<String?>(builtinKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Template copyWith(
          {String? id,
          String? name,
          String? emoji,
          String? prompt,
          Value<String?> builtinKey = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Template(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        prompt: prompt ?? this.prompt,
        builtinKey: builtinKey.present ? builtinKey.value : this.builtinKey,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Template copyWithCompanion(TemplatesCompanion data) {
    return Template(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      builtinKey:
          data.builtinKey.present ? data.builtinKey.value : this.builtinKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Template(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('prompt: $prompt, ')
          ..write('builtinKey: $builtinKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, emoji, prompt, builtinKey, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Template &&
          other.id == this.id &&
          other.name == this.name &&
          other.emoji == this.emoji &&
          other.prompt == this.prompt &&
          other.builtinKey == this.builtinKey &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TemplatesCompanion extends UpdateCompanion<Template> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> emoji;
  final Value<String> prompt;
  final Value<String?> builtinKey;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.emoji = const Value.absent(),
    this.prompt = const Value.absent(),
    this.builtinKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplatesCompanion.insert({
    required String id,
    required String name,
    this.emoji = const Value.absent(),
    required String prompt,
    this.builtinKey = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        prompt = Value(prompt),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Template> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? emoji,
    Expression<String>? prompt,
    Expression<String>? builtinKey,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      if (prompt != null) 'prompt': prompt,
      if (builtinKey != null) 'builtin_key': builtinKey,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplatesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? emoji,
      Value<String>? prompt,
      Value<String?>? builtinKey,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return TemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      prompt: prompt ?? this.prompt,
      builtinKey: builtinKey ?? this.builtinKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (builtinKey.present) {
      map['builtin_key'] = Variable<String>(builtinKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('prompt: $prompt, ')
          ..write('builtinKey: $builtinKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxTable extends SyncOutbox
    with TableInfo<$SyncOutboxTable, SyncOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entityTableMeta =
      const VerificationMeta('entityTable');
  @override
  late final GeneratedColumn<String> entityTable = GeneratedColumn<String>(
      'entity_table', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
      'op', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
      'hlc', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, entityTable, entityId, op, hlc, createdAt, attempts];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(Insertable<SyncOutboxData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_table')) {
      context.handle(
          _entityTableMeta,
          entityTable.isAcceptableOrUnknown(
              data['entity_table']!, _entityTableMeta));
    } else if (isInserting) {
      context.missing(_entityTableMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
          _hlcMeta, hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta));
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entityTable: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_table'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      op: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}op'])!,
      hlc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hlc'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
    );
  }

  @override
  $SyncOutboxTable createAlias(String alias) {
    return $SyncOutboxTable(attachedDatabase, alias);
  }
}

class SyncOutboxData extends DataClass implements Insertable<SyncOutboxData> {
  final int id;

  /// The table + primary key of the row that changed.
  final String entityTable;
  final String entityId;

  /// 'upsert' | 'delete'. Deletes are tombstones (a soft-delete on the row plus
  /// this marker), never a destructive DELETE that a peer could never learn of.
  final String op;

  /// The HLC stamped on the change — the server orders and conflict-resolves by
  /// this, not by arrival time.
  final String hlc;
  final DateTime createdAt;

  /// Bumped each failed attempt, for backoff and to surface a stuck change.
  final int attempts;
  const SyncOutboxData(
      {required this.id,
      required this.entityTable,
      required this.entityId,
      required this.op,
      required this.hlc,
      required this.createdAt,
      required this.attempts});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_table'] = Variable<String>(entityTable);
    map['entity_id'] = Variable<String>(entityId);
    map['op'] = Variable<String>(op);
    map['hlc'] = Variable<String>(hlc);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    return map;
  }

  SyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxCompanion(
      id: Value(id),
      entityTable: Value(entityTable),
      entityId: Value(entityId),
      op: Value(op),
      hlc: Value(hlc),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
    );
  }

  factory SyncOutboxData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxData(
      id: serializer.fromJson<int>(json['id']),
      entityTable: serializer.fromJson<String>(json['entityTable']),
      entityId: serializer.fromJson<String>(json['entityId']),
      op: serializer.fromJson<String>(json['op']),
      hlc: serializer.fromJson<String>(json['hlc']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityTable': serializer.toJson<String>(entityTable),
      'entityId': serializer.toJson<String>(entityId),
      'op': serializer.toJson<String>(op),
      'hlc': serializer.toJson<String>(hlc),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
    };
  }

  SyncOutboxData copyWith(
          {int? id,
          String? entityTable,
          String? entityId,
          String? op,
          String? hlc,
          DateTime? createdAt,
          int? attempts}) =>
      SyncOutboxData(
        id: id ?? this.id,
        entityTable: entityTable ?? this.entityTable,
        entityId: entityId ?? this.entityId,
        op: op ?? this.op,
        hlc: hlc ?? this.hlc,
        createdAt: createdAt ?? this.createdAt,
        attempts: attempts ?? this.attempts,
      );
  SyncOutboxData copyWithCompanion(SyncOutboxCompanion data) {
    return SyncOutboxData(
      id: data.id.present ? data.id.value : this.id,
      entityTable:
          data.entityTable.present ? data.entityTable.value : this.entityTable,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      op: data.op.present ? data.op.value : this.op,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxData(')
          ..write('id: $id, ')
          ..write('entityTable: $entityTable, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('hlc: $hlc, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, entityTable, entityId, op, hlc, createdAt, attempts);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxData &&
          other.id == this.id &&
          other.entityTable == this.entityTable &&
          other.entityId == this.entityId &&
          other.op == this.op &&
          other.hlc == this.hlc &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts);
}

class SyncOutboxCompanion extends UpdateCompanion<SyncOutboxData> {
  final Value<int> id;
  final Value<String> entityTable;
  final Value<String> entityId;
  final Value<String> op;
  final Value<String> hlc;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  const SyncOutboxCompanion({
    this.id = const Value.absent(),
    this.entityTable = const Value.absent(),
    this.entityId = const Value.absent(),
    this.op = const Value.absent(),
    this.hlc = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
  });
  SyncOutboxCompanion.insert({
    this.id = const Value.absent(),
    required String entityTable,
    required String entityId,
    required String op,
    required String hlc,
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
  })  : entityTable = Value(entityTable),
        entityId = Value(entityId),
        op = Value(op),
        hlc = Value(hlc);
  static Insertable<SyncOutboxData> custom({
    Expression<int>? id,
    Expression<String>? entityTable,
    Expression<String>? entityId,
    Expression<String>? op,
    Expression<String>? hlc,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityTable != null) 'entity_table': entityTable,
      if (entityId != null) 'entity_id': entityId,
      if (op != null) 'op': op,
      if (hlc != null) 'hlc': hlc,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
    });
  }

  SyncOutboxCompanion copyWith(
      {Value<int>? id,
      Value<String>? entityTable,
      Value<String>? entityId,
      Value<String>? op,
      Value<String>? hlc,
      Value<DateTime>? createdAt,
      Value<int>? attempts}) {
    return SyncOutboxCompanion(
      id: id ?? this.id,
      entityTable: entityTable ?? this.entityTable,
      entityId: entityId ?? this.entityId,
      op: op ?? this.op,
      hlc: hlc ?? this.hlc,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityTable.present) {
      map['entity_table'] = Variable<String>(entityTable.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxCompanion(')
          ..write('id: $id, ')
          ..write('entityTable: $entityTable, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('hlc: $hlc, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $MeetingsTable meetings = $MeetingsTable(this);
  late final $TranscriptsTable transcripts = $TranscriptsTable(this);
  late final $TranscriptSegmentsTable transcriptSegments =
      $TranscriptSegmentsTable(this);
  late final $SummariesTable summaries = $SummariesTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $UsageDaysTable usageDays = $UsageDaysTable(this);
  late final $UsageMonthsTable usageMonths = $UsageMonthsTable(this);
  late final $TopUpCreditsTable topUpCredits = $TopUpCreditsTable(this);
  late final $VoiceprintsTable voiceprints = $VoiceprintsTable(this);
  late final $SegmentEmbeddingsTable segmentEmbeddings =
      $SegmentEmbeddingsTable(this);
  late final $ActionItemsTable actionItems = $ActionItemsTable(this);
  late final $FoldersTable folders = $FoldersTable(this);
  late final $MeetingFoldersTable meetingFolders = $MeetingFoldersTable(this);
  late final $MeetingTagsTable meetingTags = $MeetingTagsTable(this);
  late final $TranslationCacheTable translationCache =
      $TranslationCacheTable(this);
  late final $GlossaryTermsTable glossaryTerms = $GlossaryTermsTable(this);
  late final $PurchasesTable purchases = $PurchasesTable(this);
  late final $TemplatesTable templates = $TemplatesTable(this);
  late final $SyncOutboxTable syncOutbox = $SyncOutboxTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        meetings,
        transcripts,
        transcriptSegments,
        summaries,
        bookmarks,
        usageDays,
        usageMonths,
        topUpCredits,
        voiceprints,
        segmentEmbeddings,
        actionItems,
        folders,
        meetingFolders,
        meetingTags,
        translationCache,
        glossaryTerms,
        purchases,
        templates,
        syncOutbox
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('meetings',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transcripts', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('meetings',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('transcript_segments', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('meetings',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('summaries', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('meetings',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('bookmarks', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('transcript_segments',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('segment_embeddings', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('meetings',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('segment_embeddings', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('meetings',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('action_items', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('meetings',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('meeting_folders', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('folders',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('meeting_folders', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('meetings',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('meeting_tags', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$MeetingsTableCreateCompanionBuilder = MeetingsCompanion Function({
  required String id,
  required String title,
  Value<int> durationMs,
  required String audioPath,
  required DateTime createdAt,
  required DateTime updatedAt,
  required MeetingStatus status,
  Value<String?> failureReason,
  Value<String?> calendarEventId,
  Value<String> language,
  Value<int> rowid,
});
typedef $$MeetingsTableUpdateCompanionBuilder = MeetingsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<int> durationMs,
  Value<String> audioPath,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<MeetingStatus> status,
  Value<String?> failureReason,
  Value<String?> calendarEventId,
  Value<String> language,
  Value<int> rowid,
});

final class $$MeetingsTableReferences
    extends BaseReferences<_$AppDb, $MeetingsTable, Meeting> {
  $$MeetingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TranscriptsTable, List<Transcript>>
      _transcriptsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
          db.transcripts,
          aliasName:
              $_aliasNameGenerator(db.meetings.id, db.transcripts.meetingId));

  $$TranscriptsTableProcessedTableManager get transcriptsRefs {
    final manager = $$TranscriptsTableTableManager($_db, $_db.transcripts)
        .filter((f) => f.meetingId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transcriptsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TranscriptSegmentsTable, List<TranscriptSegment>>
      _transcriptSegmentsRefsTable(_$AppDb db) =>
          MultiTypedResultKey.fromTable(db.transcriptSegments,
              aliasName: $_aliasNameGenerator(
                  db.meetings.id, db.transcriptSegments.meetingId));

  $$TranscriptSegmentsTableProcessedTableManager get transcriptSegmentsRefs {
    final manager = $$TranscriptSegmentsTableTableManager(
            $_db, $_db.transcriptSegments)
        .filter((f) => f.meetingId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_transcriptSegmentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SummariesTable, List<Summary>>
      _summariesRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
          db.summaries,
          aliasName:
              $_aliasNameGenerator(db.meetings.id, db.summaries.meetingId));

  $$SummariesTableProcessedTableManager get summariesRefs {
    final manager = $$SummariesTableTableManager($_db, $_db.summaries)
        .filter((f) => f.meetingId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_summariesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BookmarksTable, List<Bookmark>>
      _bookmarksRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
          db.bookmarks,
          aliasName:
              $_aliasNameGenerator(db.meetings.id, db.bookmarks.meetingId));

  $$BookmarksTableProcessedTableManager get bookmarksRefs {
    final manager = $$BookmarksTableTableManager($_db, $_db.bookmarks)
        .filter((f) => f.meetingId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookmarksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SegmentEmbeddingsTable, List<SegmentEmbedding>>
      _segmentEmbeddingsRefsTable(_$AppDb db) =>
          MultiTypedResultKey.fromTable(db.segmentEmbeddings,
              aliasName: $_aliasNameGenerator(
                  db.meetings.id, db.segmentEmbeddings.meetingId));

  $$SegmentEmbeddingsTableProcessedTableManager get segmentEmbeddingsRefs {
    final manager = $$SegmentEmbeddingsTableTableManager(
            $_db, $_db.segmentEmbeddings)
        .filter((f) => f.meetingId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_segmentEmbeddingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ActionItemsTable, List<ActionItem>>
      _actionItemsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
          db.actionItems,
          aliasName:
              $_aliasNameGenerator(db.meetings.id, db.actionItems.meetingId));

  $$ActionItemsTableProcessedTableManager get actionItemsRefs {
    final manager = $$ActionItemsTableTableManager($_db, $_db.actionItems)
        .filter((f) => f.meetingId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_actionItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$MeetingFoldersTable, List<MeetingFolder>>
      _meetingFoldersRefsTable(_$AppDb db) =>
          MultiTypedResultKey.fromTable(db.meetingFolders,
              aliasName: $_aliasNameGenerator(
                  db.meetings.id, db.meetingFolders.meetingId));

  $$MeetingFoldersTableProcessedTableManager get meetingFoldersRefs {
    final manager = $$MeetingFoldersTableTableManager($_db, $_db.meetingFolders)
        .filter((f) => f.meetingId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_meetingFoldersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$MeetingTagsTable, List<MeetingTag>>
      _meetingTagsRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
          db.meetingTags,
          aliasName:
              $_aliasNameGenerator(db.meetings.id, db.meetingTags.meetingId));

  $$MeetingTagsTableProcessedTableManager get meetingTagsRefs {
    final manager = $$MeetingTagsTableTableManager($_db, $_db.meetingTags)
        .filter((f) => f.meetingId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_meetingTagsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$MeetingsTableFilterComposer extends Composer<_$AppDb, $MeetingsTable> {
  $$MeetingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioPath => $composableBuilder(
      column: $table.audioPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<MeetingStatus, MeetingStatus, String>
      get status => $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get failureReason => $composableBuilder(
      column: $table.failureReason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get calendarEventId => $composableBuilder(
      column: $table.calendarEventId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnFilters(column));

  Expression<bool> transcriptsRefs(
      Expression<bool> Function($$TranscriptsTableFilterComposer f) f) {
    final $$TranscriptsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transcripts,
        getReferencedColumn: (t) => t.meetingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TranscriptsTableFilterComposer(
              $db: $db,
              $table: $db.transcripts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> transcriptSegmentsRefs(
      Expression<bool> Function($$TranscriptSegmentsTableFilterComposer f) f) {
    final $$TranscriptSegmentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transcriptSegments,
        getReferencedColumn: (t) => t.meetingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TranscriptSegmentsTableFilterComposer(
              $db: $db,
              $table: $db.transcriptSegments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> summariesRefs(
      Expression<bool> Function($$SummariesTableFilterComposer f) f) {
    final $$SummariesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.summaries,
        getReferencedColumn: (t) => t.meetingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SummariesTableFilterComposer(
              $db: $db,
              $table: $db.summaries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> bookmarksRefs(
      Expression<bool> Function($$BookmarksTableFilterComposer f) f) {
    final $$BookmarksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bookmarks,
        getReferencedColumn: (t) => t.meetingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookmarksTableFilterComposer(
              $db: $db,
              $table: $db.bookmarks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> segmentEmbeddingsRefs(
      Expression<bool> Function($$SegmentEmbeddingsTableFilterComposer f) f) {
    final $$SegmentEmbeddingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.segmentEmbeddings,
        getReferencedColumn: (t) => t.meetingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SegmentEmbeddingsTableFilterComposer(
              $db: $db,
              $table: $db.segmentEmbeddings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> actionItemsRefs(
      Expression<bool> Function($$ActionItemsTableFilterComposer f) f) {
    final $$ActionItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.actionItems,
        getReferencedColumn: (t) => t.meetingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActionItemsTableFilterComposer(
              $db: $db,
              $table: $db.actionItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> meetingFoldersRefs(
      Expression<bool> Function($$MeetingFoldersTableFilterComposer f) f) {
    final $$MeetingFoldersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.meetingFolders,
        getReferencedColumn: (t) => t.meetingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingFoldersTableFilterComposer(
              $db: $db,
              $table: $db.meetingFolders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> meetingTagsRefs(
      Expression<bool> Function($$MeetingTagsTableFilterComposer f) f) {
    final $$MeetingTagsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.meetingTags,
        getReferencedColumn: (t) => t.meetingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingTagsTableFilterComposer(
              $db: $db,
              $table: $db.meetingTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MeetingsTableOrderingComposer
    extends Composer<_$AppDb, $MeetingsTable> {
  $$MeetingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioPath => $composableBuilder(
      column: $table.audioPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get failureReason => $composableBuilder(
      column: $table.failureReason,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get calendarEventId => $composableBuilder(
      column: $table.calendarEventId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get language => $composableBuilder(
      column: $table.language, builder: (column) => ColumnOrderings(column));
}

class $$MeetingsTableAnnotationComposer
    extends Composer<_$AppDb, $MeetingsTable> {
  $$MeetingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<String> get audioPath =>
      $composableBuilder(column: $table.audioPath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MeetingStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get failureReason => $composableBuilder(
      column: $table.failureReason, builder: (column) => column);

  GeneratedColumn<String> get calendarEventId => $composableBuilder(
      column: $table.calendarEventId, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  Expression<T> transcriptsRefs<T extends Object>(
      Expression<T> Function($$TranscriptsTableAnnotationComposer a) f) {
    final $$TranscriptsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transcripts,
        getReferencedColumn: (t) => t.meetingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TranscriptsTableAnnotationComposer(
              $db: $db,
              $table: $db.transcripts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> transcriptSegmentsRefs<T extends Object>(
      Expression<T> Function($$TranscriptSegmentsTableAnnotationComposer a) f) {
    final $$TranscriptSegmentsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.transcriptSegments,
            getReferencedColumn: (t) => t.meetingId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$TranscriptSegmentsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.transcriptSegments,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> summariesRefs<T extends Object>(
      Expression<T> Function($$SummariesTableAnnotationComposer a) f) {
    final $$SummariesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.summaries,
        getReferencedColumn: (t) => t.meetingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SummariesTableAnnotationComposer(
              $db: $db,
              $table: $db.summaries,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> bookmarksRefs<T extends Object>(
      Expression<T> Function($$BookmarksTableAnnotationComposer a) f) {
    final $$BookmarksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bookmarks,
        getReferencedColumn: (t) => t.meetingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookmarksTableAnnotationComposer(
              $db: $db,
              $table: $db.bookmarks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> segmentEmbeddingsRefs<T extends Object>(
      Expression<T> Function($$SegmentEmbeddingsTableAnnotationComposer a) f) {
    final $$SegmentEmbeddingsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.segmentEmbeddings,
            getReferencedColumn: (t) => t.meetingId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SegmentEmbeddingsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.segmentEmbeddings,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> actionItemsRefs<T extends Object>(
      Expression<T> Function($$ActionItemsTableAnnotationComposer a) f) {
    final $$ActionItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.actionItems,
        getReferencedColumn: (t) => t.meetingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActionItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.actionItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> meetingFoldersRefs<T extends Object>(
      Expression<T> Function($$MeetingFoldersTableAnnotationComposer a) f) {
    final $$MeetingFoldersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.meetingFolders,
        getReferencedColumn: (t) => t.meetingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingFoldersTableAnnotationComposer(
              $db: $db,
              $table: $db.meetingFolders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> meetingTagsRefs<T extends Object>(
      Expression<T> Function($$MeetingTagsTableAnnotationComposer a) f) {
    final $$MeetingTagsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.meetingTags,
        getReferencedColumn: (t) => t.meetingId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingTagsTableAnnotationComposer(
              $db: $db,
              $table: $db.meetingTags,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MeetingsTableTableManager extends RootTableManager<
    _$AppDb,
    $MeetingsTable,
    Meeting,
    $$MeetingsTableFilterComposer,
    $$MeetingsTableOrderingComposer,
    $$MeetingsTableAnnotationComposer,
    $$MeetingsTableCreateCompanionBuilder,
    $$MeetingsTableUpdateCompanionBuilder,
    (Meeting, $$MeetingsTableReferences),
    Meeting,
    PrefetchHooks Function(
        {bool transcriptsRefs,
        bool transcriptSegmentsRefs,
        bool summariesRefs,
        bool bookmarksRefs,
        bool segmentEmbeddingsRefs,
        bool actionItemsRefs,
        bool meetingFoldersRefs,
        bool meetingTagsRefs})> {
  $$MeetingsTableTableManager(_$AppDb db, $MeetingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeetingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeetingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeetingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<String> audioPath = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<MeetingStatus> status = const Value.absent(),
            Value<String?> failureReason = const Value.absent(),
            Value<String?> calendarEventId = const Value.absent(),
            Value<String> language = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MeetingsCompanion(
            id: id,
            title: title,
            durationMs: durationMs,
            audioPath: audioPath,
            createdAt: createdAt,
            updatedAt: updatedAt,
            status: status,
            failureReason: failureReason,
            calendarEventId: calendarEventId,
            language: language,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<int> durationMs = const Value.absent(),
            required String audioPath,
            required DateTime createdAt,
            required DateTime updatedAt,
            required MeetingStatus status,
            Value<String?> failureReason = const Value.absent(),
            Value<String?> calendarEventId = const Value.absent(),
            Value<String> language = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MeetingsCompanion.insert(
            id: id,
            title: title,
            durationMs: durationMs,
            audioPath: audioPath,
            createdAt: createdAt,
            updatedAt: updatedAt,
            status: status,
            failureReason: failureReason,
            calendarEventId: calendarEventId,
            language: language,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$MeetingsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {transcriptsRefs = false,
              transcriptSegmentsRefs = false,
              summariesRefs = false,
              bookmarksRefs = false,
              segmentEmbeddingsRefs = false,
              actionItemsRefs = false,
              meetingFoldersRefs = false,
              meetingTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (transcriptsRefs) db.transcripts,
                if (transcriptSegmentsRefs) db.transcriptSegments,
                if (summariesRefs) db.summaries,
                if (bookmarksRefs) db.bookmarks,
                if (segmentEmbeddingsRefs) db.segmentEmbeddings,
                if (actionItemsRefs) db.actionItems,
                if (meetingFoldersRefs) db.meetingFolders,
                if (meetingTagsRefs) db.meetingTags
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transcriptsRefs)
                    await $_getPrefetchedData<Meeting, $MeetingsTable,
                            Transcript>(
                        currentTable: table,
                        referencedTable:
                            $$MeetingsTableReferences._transcriptsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MeetingsTableReferences(db, table, p0)
                                .transcriptsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.meetingId == item.id),
                        typedResults: items),
                  if (transcriptSegmentsRefs)
                    await $_getPrefetchedData<Meeting, $MeetingsTable,
                            TranscriptSegment>(
                        currentTable: table,
                        referencedTable: $$MeetingsTableReferences
                            ._transcriptSegmentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MeetingsTableReferences(db, table, p0)
                                .transcriptSegmentsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.meetingId == item.id),
                        typedResults: items),
                  if (summariesRefs)
                    await $_getPrefetchedData<Meeting, $MeetingsTable, Summary>(
                        currentTable: table,
                        referencedTable:
                            $$MeetingsTableReferences._summariesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MeetingsTableReferences(db, table, p0)
                                .summariesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.meetingId == item.id),
                        typedResults: items),
                  if (bookmarksRefs)
                    await $_getPrefetchedData<Meeting, $MeetingsTable,
                            Bookmark>(
                        currentTable: table,
                        referencedTable:
                            $$MeetingsTableReferences._bookmarksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MeetingsTableReferences(db, table, p0)
                                .bookmarksRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.meetingId == item.id),
                        typedResults: items),
                  if (segmentEmbeddingsRefs)
                    await $_getPrefetchedData<Meeting, $MeetingsTable,
                            SegmentEmbedding>(
                        currentTable: table,
                        referencedTable: $$MeetingsTableReferences
                            ._segmentEmbeddingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MeetingsTableReferences(db, table, p0)
                                .segmentEmbeddingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.meetingId == item.id),
                        typedResults: items),
                  if (actionItemsRefs)
                    await $_getPrefetchedData<Meeting, $MeetingsTable,
                            ActionItem>(
                        currentTable: table,
                        referencedTable:
                            $$MeetingsTableReferences._actionItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MeetingsTableReferences(db, table, p0)
                                .actionItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.meetingId == item.id),
                        typedResults: items),
                  if (meetingFoldersRefs)
                    await $_getPrefetchedData<Meeting, $MeetingsTable,
                            MeetingFolder>(
                        currentTable: table,
                        referencedTable: $$MeetingsTableReferences
                            ._meetingFoldersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MeetingsTableReferences(db, table, p0)
                                .meetingFoldersRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.meetingId == item.id),
                        typedResults: items),
                  if (meetingTagsRefs)
                    await $_getPrefetchedData<Meeting, $MeetingsTable,
                            MeetingTag>(
                        currentTable: table,
                        referencedTable:
                            $$MeetingsTableReferences._meetingTagsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MeetingsTableReferences(db, table, p0)
                                .meetingTagsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.meetingId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$MeetingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $MeetingsTable,
    Meeting,
    $$MeetingsTableFilterComposer,
    $$MeetingsTableOrderingComposer,
    $$MeetingsTableAnnotationComposer,
    $$MeetingsTableCreateCompanionBuilder,
    $$MeetingsTableUpdateCompanionBuilder,
    (Meeting, $$MeetingsTableReferences),
    Meeting,
    PrefetchHooks Function(
        {bool transcriptsRefs,
        bool transcriptSegmentsRefs,
        bool summariesRefs,
        bool bookmarksRefs,
        bool segmentEmbeddingsRefs,
        bool actionItemsRefs,
        bool meetingFoldersRefs,
        bool meetingTagsRefs})>;
typedef $$TranscriptsTableCreateCompanionBuilder = TranscriptsCompanion
    Function({
  required String meetingId,
  required String body,
  required String modelId,
  Value<int> processingMs,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$TranscriptsTableUpdateCompanionBuilder = TranscriptsCompanion
    Function({
  Value<String> meetingId,
  Value<String> body,
  Value<String> modelId,
  Value<int> processingMs,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$TranscriptsTableReferences
    extends BaseReferences<_$AppDb, $TranscriptsTable, Transcript> {
  $$TranscriptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MeetingsTable _meetingIdTable(_$AppDb db) => db.meetings.createAlias(
      $_aliasNameGenerator(db.transcripts.meetingId, db.meetings.id));

  $$MeetingsTableProcessedTableManager get meetingId {
    final $_column = $_itemColumn<String>('meeting_id')!;

    final manager = $$MeetingsTableTableManager($_db, $_db.meetings)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_meetingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TranscriptsTableFilterComposer
    extends Composer<_$AppDb, $TranscriptsTable> {
  $$TranscriptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelId => $composableBuilder(
      column: $table.modelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get processingMs => $composableBuilder(
      column: $table.processingMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$MeetingsTableFilterComposer get meetingId {
    final $$MeetingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableFilterComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TranscriptsTableOrderingComposer
    extends Composer<_$AppDb, $TranscriptsTable> {
  $$TranscriptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelId => $composableBuilder(
      column: $table.modelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get processingMs => $composableBuilder(
      column: $table.processingMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$MeetingsTableOrderingComposer get meetingId {
    final $$MeetingsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableOrderingComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TranscriptsTableAnnotationComposer
    extends Composer<_$AppDb, $TranscriptsTable> {
  $$TranscriptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<int> get processingMs => $composableBuilder(
      column: $table.processingMs, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$MeetingsTableAnnotationComposer get meetingId {
    final $$MeetingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableAnnotationComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TranscriptsTableTableManager extends RootTableManager<
    _$AppDb,
    $TranscriptsTable,
    Transcript,
    $$TranscriptsTableFilterComposer,
    $$TranscriptsTableOrderingComposer,
    $$TranscriptsTableAnnotationComposer,
    $$TranscriptsTableCreateCompanionBuilder,
    $$TranscriptsTableUpdateCompanionBuilder,
    (Transcript, $$TranscriptsTableReferences),
    Transcript,
    PrefetchHooks Function({bool meetingId})> {
  $$TranscriptsTableTableManager(_$AppDb db, $TranscriptsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranscriptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranscriptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TranscriptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> meetingId = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String> modelId = const Value.absent(),
            Value<int> processingMs = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TranscriptsCompanion(
            meetingId: meetingId,
            body: body,
            modelId: modelId,
            processingMs: processingMs,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String meetingId,
            required String body,
            required String modelId,
            Value<int> processingMs = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TranscriptsCompanion.insert(
            meetingId: meetingId,
            body: body,
            modelId: modelId,
            processingMs: processingMs,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TranscriptsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({meetingId = false}) {
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
                if (meetingId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.meetingId,
                    referencedTable:
                        $$TranscriptsTableReferences._meetingIdTable(db),
                    referencedColumn:
                        $$TranscriptsTableReferences._meetingIdTable(db).id,
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

typedef $$TranscriptsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $TranscriptsTable,
    Transcript,
    $$TranscriptsTableFilterComposer,
    $$TranscriptsTableOrderingComposer,
    $$TranscriptsTableAnnotationComposer,
    $$TranscriptsTableCreateCompanionBuilder,
    $$TranscriptsTableUpdateCompanionBuilder,
    (Transcript, $$TranscriptsTableReferences),
    Transcript,
    PrefetchHooks Function({bool meetingId})>;
typedef $$TranscriptSegmentsTableCreateCompanionBuilder
    = TranscriptSegmentsCompanion Function({
  required String id,
  required String meetingId,
  required int startMs,
  required int endMs,
  required String body,
  Value<bool> isFinal,
  Value<String?> speakerLabel,
  Value<int> rowid,
});
typedef $$TranscriptSegmentsTableUpdateCompanionBuilder
    = TranscriptSegmentsCompanion Function({
  Value<String> id,
  Value<String> meetingId,
  Value<int> startMs,
  Value<int> endMs,
  Value<String> body,
  Value<bool> isFinal,
  Value<String?> speakerLabel,
  Value<int> rowid,
});

final class $$TranscriptSegmentsTableReferences extends BaseReferences<_$AppDb,
    $TranscriptSegmentsTable, TranscriptSegment> {
  $$TranscriptSegmentsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $MeetingsTable _meetingIdTable(_$AppDb db) => db.meetings.createAlias(
      $_aliasNameGenerator(db.transcriptSegments.meetingId, db.meetings.id));

  $$MeetingsTableProcessedTableManager get meetingId {
    final $_column = $_itemColumn<String>('meeting_id')!;

    final manager = $$MeetingsTableTableManager($_db, $_db.meetings)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_meetingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SegmentEmbeddingsTable, List<SegmentEmbedding>>
      _segmentEmbeddingsRefsTable(_$AppDb db) =>
          MultiTypedResultKey.fromTable(db.segmentEmbeddings,
              aliasName: $_aliasNameGenerator(
                  db.transcriptSegments.id, db.segmentEmbeddings.segmentId));

  $$SegmentEmbeddingsTableProcessedTableManager get segmentEmbeddingsRefs {
    final manager = $$SegmentEmbeddingsTableTableManager(
            $_db, $_db.segmentEmbeddings)
        .filter((f) => f.segmentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_segmentEmbeddingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TranscriptSegmentsTableFilterComposer
    extends Composer<_$AppDb, $TranscriptSegmentsTable> {
  $$TranscriptSegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startMs => $composableBuilder(
      column: $table.startMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endMs => $composableBuilder(
      column: $table.endMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFinal => $composableBuilder(
      column: $table.isFinal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get speakerLabel => $composableBuilder(
      column: $table.speakerLabel, builder: (column) => ColumnFilters(column));

  $$MeetingsTableFilterComposer get meetingId {
    final $$MeetingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableFilterComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> segmentEmbeddingsRefs(
      Expression<bool> Function($$SegmentEmbeddingsTableFilterComposer f) f) {
    final $$SegmentEmbeddingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.segmentEmbeddings,
        getReferencedColumn: (t) => t.segmentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SegmentEmbeddingsTableFilterComposer(
              $db: $db,
              $table: $db.segmentEmbeddings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TranscriptSegmentsTableOrderingComposer
    extends Composer<_$AppDb, $TranscriptSegmentsTable> {
  $$TranscriptSegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startMs => $composableBuilder(
      column: $table.startMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endMs => $composableBuilder(
      column: $table.endMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFinal => $composableBuilder(
      column: $table.isFinal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get speakerLabel => $composableBuilder(
      column: $table.speakerLabel,
      builder: (column) => ColumnOrderings(column));

  $$MeetingsTableOrderingComposer get meetingId {
    final $$MeetingsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableOrderingComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TranscriptSegmentsTableAnnotationComposer
    extends Composer<_$AppDb, $TranscriptSegmentsTable> {
  $$TranscriptSegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get endMs =>
      $composableBuilder(column: $table.endMs, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<bool> get isFinal =>
      $composableBuilder(column: $table.isFinal, builder: (column) => column);

  GeneratedColumn<String> get speakerLabel => $composableBuilder(
      column: $table.speakerLabel, builder: (column) => column);

  $$MeetingsTableAnnotationComposer get meetingId {
    final $$MeetingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableAnnotationComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> segmentEmbeddingsRefs<T extends Object>(
      Expression<T> Function($$SegmentEmbeddingsTableAnnotationComposer a) f) {
    final $$SegmentEmbeddingsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.segmentEmbeddings,
            getReferencedColumn: (t) => t.segmentId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SegmentEmbeddingsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.segmentEmbeddings,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$TranscriptSegmentsTableTableManager extends RootTableManager<
    _$AppDb,
    $TranscriptSegmentsTable,
    TranscriptSegment,
    $$TranscriptSegmentsTableFilterComposer,
    $$TranscriptSegmentsTableOrderingComposer,
    $$TranscriptSegmentsTableAnnotationComposer,
    $$TranscriptSegmentsTableCreateCompanionBuilder,
    $$TranscriptSegmentsTableUpdateCompanionBuilder,
    (TranscriptSegment, $$TranscriptSegmentsTableReferences),
    TranscriptSegment,
    PrefetchHooks Function({bool meetingId, bool segmentEmbeddingsRefs})> {
  $$TranscriptSegmentsTableTableManager(
      _$AppDb db, $TranscriptSegmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranscriptSegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranscriptSegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TranscriptSegmentsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> meetingId = const Value.absent(),
            Value<int> startMs = const Value.absent(),
            Value<int> endMs = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<bool> isFinal = const Value.absent(),
            Value<String?> speakerLabel = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TranscriptSegmentsCompanion(
            id: id,
            meetingId: meetingId,
            startMs: startMs,
            endMs: endMs,
            body: body,
            isFinal: isFinal,
            speakerLabel: speakerLabel,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String meetingId,
            required int startMs,
            required int endMs,
            required String body,
            Value<bool> isFinal = const Value.absent(),
            Value<String?> speakerLabel = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TranscriptSegmentsCompanion.insert(
            id: id,
            meetingId: meetingId,
            startMs: startMs,
            endMs: endMs,
            body: body,
            isFinal: isFinal,
            speakerLabel: speakerLabel,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TranscriptSegmentsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {meetingId = false, segmentEmbeddingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (segmentEmbeddingsRefs) db.segmentEmbeddings
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
                if (meetingId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.meetingId,
                    referencedTable:
                        $$TranscriptSegmentsTableReferences._meetingIdTable(db),
                    referencedColumn: $$TranscriptSegmentsTableReferences
                        ._meetingIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (segmentEmbeddingsRefs)
                    await $_getPrefetchedData<TranscriptSegment,
                            $TranscriptSegmentsTable, SegmentEmbedding>(
                        currentTable: table,
                        referencedTable: $$TranscriptSegmentsTableReferences
                            ._segmentEmbeddingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TranscriptSegmentsTableReferences(db, table, p0)
                                .segmentEmbeddingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.segmentId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TranscriptSegmentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $TranscriptSegmentsTable,
    TranscriptSegment,
    $$TranscriptSegmentsTableFilterComposer,
    $$TranscriptSegmentsTableOrderingComposer,
    $$TranscriptSegmentsTableAnnotationComposer,
    $$TranscriptSegmentsTableCreateCompanionBuilder,
    $$TranscriptSegmentsTableUpdateCompanionBuilder,
    (TranscriptSegment, $$TranscriptSegmentsTableReferences),
    TranscriptSegment,
    PrefetchHooks Function({bool meetingId, bool segmentEmbeddingsRefs})>;
typedef $$SummariesTableCreateCompanionBuilder = SummariesCompanion Function({
  required String id,
  required String meetingId,
  required String personaKey,
  required String body,
  required SummaryBackendKind backend,
  required String modelId,
  Value<int> processingMs,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$SummariesTableUpdateCompanionBuilder = SummariesCompanion Function({
  Value<String> id,
  Value<String> meetingId,
  Value<String> personaKey,
  Value<String> body,
  Value<SummaryBackendKind> backend,
  Value<String> modelId,
  Value<int> processingMs,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$SummariesTableReferences
    extends BaseReferences<_$AppDb, $SummariesTable, Summary> {
  $$SummariesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MeetingsTable _meetingIdTable(_$AppDb db) => db.meetings.createAlias(
      $_aliasNameGenerator(db.summaries.meetingId, db.meetings.id));

  $$MeetingsTableProcessedTableManager get meetingId {
    final $_column = $_itemColumn<String>('meeting_id')!;

    final manager = $$MeetingsTableTableManager($_db, $_db.meetings)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_meetingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SummariesTableFilterComposer
    extends Composer<_$AppDb, $SummariesTable> {
  $$SummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get personaKey => $composableBuilder(
      column: $table.personaKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<SummaryBackendKind, SummaryBackendKind, String>
      get backend => $composableBuilder(
          column: $table.backend,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get modelId => $composableBuilder(
      column: $table.modelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get processingMs => $composableBuilder(
      column: $table.processingMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$MeetingsTableFilterComposer get meetingId {
    final $$MeetingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableFilterComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SummariesTableOrderingComposer
    extends Composer<_$AppDb, $SummariesTable> {
  $$SummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get personaKey => $composableBuilder(
      column: $table.personaKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backend => $composableBuilder(
      column: $table.backend, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelId => $composableBuilder(
      column: $table.modelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get processingMs => $composableBuilder(
      column: $table.processingMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$MeetingsTableOrderingComposer get meetingId {
    final $$MeetingsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableOrderingComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SummariesTableAnnotationComposer
    extends Composer<_$AppDb, $SummariesTable> {
  $$SummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get personaKey => $composableBuilder(
      column: $table.personaKey, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SummaryBackendKind, String> get backend =>
      $composableBuilder(column: $table.backend, builder: (column) => column);

  GeneratedColumn<String> get modelId =>
      $composableBuilder(column: $table.modelId, builder: (column) => column);

  GeneratedColumn<int> get processingMs => $composableBuilder(
      column: $table.processingMs, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$MeetingsTableAnnotationComposer get meetingId {
    final $$MeetingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableAnnotationComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SummariesTableTableManager extends RootTableManager<
    _$AppDb,
    $SummariesTable,
    Summary,
    $$SummariesTableFilterComposer,
    $$SummariesTableOrderingComposer,
    $$SummariesTableAnnotationComposer,
    $$SummariesTableCreateCompanionBuilder,
    $$SummariesTableUpdateCompanionBuilder,
    (Summary, $$SummariesTableReferences),
    Summary,
    PrefetchHooks Function({bool meetingId})> {
  $$SummariesTableTableManager(_$AppDb db, $SummariesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SummariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> meetingId = const Value.absent(),
            Value<String> personaKey = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<SummaryBackendKind> backend = const Value.absent(),
            Value<String> modelId = const Value.absent(),
            Value<int> processingMs = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SummariesCompanion(
            id: id,
            meetingId: meetingId,
            personaKey: personaKey,
            body: body,
            backend: backend,
            modelId: modelId,
            processingMs: processingMs,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String meetingId,
            required String personaKey,
            required String body,
            required SummaryBackendKind backend,
            required String modelId,
            Value<int> processingMs = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SummariesCompanion.insert(
            id: id,
            meetingId: meetingId,
            personaKey: personaKey,
            body: body,
            backend: backend,
            modelId: modelId,
            processingMs: processingMs,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SummariesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({meetingId = false}) {
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
                if (meetingId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.meetingId,
                    referencedTable:
                        $$SummariesTableReferences._meetingIdTable(db),
                    referencedColumn:
                        $$SummariesTableReferences._meetingIdTable(db).id,
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

typedef $$SummariesTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $SummariesTable,
    Summary,
    $$SummariesTableFilterComposer,
    $$SummariesTableOrderingComposer,
    $$SummariesTableAnnotationComposer,
    $$SummariesTableCreateCompanionBuilder,
    $$SummariesTableUpdateCompanionBuilder,
    (Summary, $$SummariesTableReferences),
    Summary,
    PrefetchHooks Function({bool meetingId})>;
typedef $$BookmarksTableCreateCompanionBuilder = BookmarksCompanion Function({
  required String id,
  required String meetingId,
  required int atMs,
  Value<String?> note,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$BookmarksTableUpdateCompanionBuilder = BookmarksCompanion Function({
  Value<String> id,
  Value<String> meetingId,
  Value<int> atMs,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$BookmarksTableReferences
    extends BaseReferences<_$AppDb, $BookmarksTable, Bookmark> {
  $$BookmarksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MeetingsTable _meetingIdTable(_$AppDb db) => db.meetings.createAlias(
      $_aliasNameGenerator(db.bookmarks.meetingId, db.meetings.id));

  $$MeetingsTableProcessedTableManager get meetingId {
    final $_column = $_itemColumn<String>('meeting_id')!;

    final manager = $$MeetingsTableTableManager($_db, $_db.meetings)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_meetingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDb, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get atMs => $composableBuilder(
      column: $table.atMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$MeetingsTableFilterComposer get meetingId {
    final $$MeetingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableFilterComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDb, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get atMs => $composableBuilder(
      column: $table.atMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$MeetingsTableOrderingComposer get meetingId {
    final $$MeetingsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableOrderingComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDb, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get atMs =>
      $composableBuilder(column: $table.atMs, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$MeetingsTableAnnotationComposer get meetingId {
    final $$MeetingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableAnnotationComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookmarksTableTableManager extends RootTableManager<
    _$AppDb,
    $BookmarksTable,
    Bookmark,
    $$BookmarksTableFilterComposer,
    $$BookmarksTableOrderingComposer,
    $$BookmarksTableAnnotationComposer,
    $$BookmarksTableCreateCompanionBuilder,
    $$BookmarksTableUpdateCompanionBuilder,
    (Bookmark, $$BookmarksTableReferences),
    Bookmark,
    PrefetchHooks Function({bool meetingId})> {
  $$BookmarksTableTableManager(_$AppDb db, $BookmarksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> meetingId = const Value.absent(),
            Value<int> atMs = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BookmarksCompanion(
            id: id,
            meetingId: meetingId,
            atMs: atMs,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String meetingId,
            required int atMs,
            Value<String?> note = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BookmarksCompanion.insert(
            id: id,
            meetingId: meetingId,
            atMs: atMs,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BookmarksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({meetingId = false}) {
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
                if (meetingId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.meetingId,
                    referencedTable:
                        $$BookmarksTableReferences._meetingIdTable(db),
                    referencedColumn:
                        $$BookmarksTableReferences._meetingIdTable(db).id,
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

typedef $$BookmarksTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $BookmarksTable,
    Bookmark,
    $$BookmarksTableFilterComposer,
    $$BookmarksTableOrderingComposer,
    $$BookmarksTableAnnotationComposer,
    $$BookmarksTableCreateCompanionBuilder,
    $$BookmarksTableUpdateCompanionBuilder,
    (Bookmark, $$BookmarksTableReferences),
    Bookmark,
    PrefetchHooks Function({bool meetingId})>;
typedef $$UsageDaysTableCreateCompanionBuilder = UsageDaysCompanion Function({
  required String day,
  Value<int> meetingsStarted,
  Value<int> recordedMs,
  Value<int> rowid,
});
typedef $$UsageDaysTableUpdateCompanionBuilder = UsageDaysCompanion Function({
  Value<String> day,
  Value<int> meetingsStarted,
  Value<int> recordedMs,
  Value<int> rowid,
});

class $$UsageDaysTableFilterComposer
    extends Composer<_$AppDb, $UsageDaysTable> {
  $$UsageDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get meetingsStarted => $composableBuilder(
      column: $table.meetingsStarted,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get recordedMs => $composableBuilder(
      column: $table.recordedMs, builder: (column) => ColumnFilters(column));
}

class $$UsageDaysTableOrderingComposer
    extends Composer<_$AppDb, $UsageDaysTable> {
  $$UsageDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get meetingsStarted => $composableBuilder(
      column: $table.meetingsStarted,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get recordedMs => $composableBuilder(
      column: $table.recordedMs, builder: (column) => ColumnOrderings(column));
}

class $$UsageDaysTableAnnotationComposer
    extends Composer<_$AppDb, $UsageDaysTable> {
  $$UsageDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get meetingsStarted => $composableBuilder(
      column: $table.meetingsStarted, builder: (column) => column);

  GeneratedColumn<int> get recordedMs => $composableBuilder(
      column: $table.recordedMs, builder: (column) => column);
}

class $$UsageDaysTableTableManager extends RootTableManager<
    _$AppDb,
    $UsageDaysTable,
    UsageDay,
    $$UsageDaysTableFilterComposer,
    $$UsageDaysTableOrderingComposer,
    $$UsageDaysTableAnnotationComposer,
    $$UsageDaysTableCreateCompanionBuilder,
    $$UsageDaysTableUpdateCompanionBuilder,
    (UsageDay, BaseReferences<_$AppDb, $UsageDaysTable, UsageDay>),
    UsageDay,
    PrefetchHooks Function()> {
  $$UsageDaysTableTableManager(_$AppDb db, $UsageDaysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsageDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsageDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsageDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> day = const Value.absent(),
            Value<int> meetingsStarted = const Value.absent(),
            Value<int> recordedMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsageDaysCompanion(
            day: day,
            meetingsStarted: meetingsStarted,
            recordedMs: recordedMs,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String day,
            Value<int> meetingsStarted = const Value.absent(),
            Value<int> recordedMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsageDaysCompanion.insert(
            day: day,
            meetingsStarted: meetingsStarted,
            recordedMs: recordedMs,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsageDaysTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $UsageDaysTable,
    UsageDay,
    $$UsageDaysTableFilterComposer,
    $$UsageDaysTableOrderingComposer,
    $$UsageDaysTableAnnotationComposer,
    $$UsageDaysTableCreateCompanionBuilder,
    $$UsageDaysTableUpdateCompanionBuilder,
    (UsageDay, BaseReferences<_$AppDb, $UsageDaysTable, UsageDay>),
    UsageDay,
    PrefetchHooks Function()>;
typedef $$UsageMonthsTableCreateCompanionBuilder = UsageMonthsCompanion
    Function({
  required String month,
  Value<int> cloudSummariesUsed,
  Value<int> recordedMs,
  Value<int> rowid,
});
typedef $$UsageMonthsTableUpdateCompanionBuilder = UsageMonthsCompanion
    Function({
  Value<String> month,
  Value<int> cloudSummariesUsed,
  Value<int> recordedMs,
  Value<int> rowid,
});

class $$UsageMonthsTableFilterComposer
    extends Composer<_$AppDb, $UsageMonthsTable> {
  $$UsageMonthsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cloudSummariesUsed => $composableBuilder(
      column: $table.cloudSummariesUsed,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get recordedMs => $composableBuilder(
      column: $table.recordedMs, builder: (column) => ColumnFilters(column));
}

class $$UsageMonthsTableOrderingComposer
    extends Composer<_$AppDb, $UsageMonthsTable> {
  $$UsageMonthsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get month => $composableBuilder(
      column: $table.month, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cloudSummariesUsed => $composableBuilder(
      column: $table.cloudSummariesUsed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get recordedMs => $composableBuilder(
      column: $table.recordedMs, builder: (column) => ColumnOrderings(column));
}

class $$UsageMonthsTableAnnotationComposer
    extends Composer<_$AppDb, $UsageMonthsTable> {
  $$UsageMonthsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get cloudSummariesUsed => $composableBuilder(
      column: $table.cloudSummariesUsed, builder: (column) => column);

  GeneratedColumn<int> get recordedMs => $composableBuilder(
      column: $table.recordedMs, builder: (column) => column);
}

class $$UsageMonthsTableTableManager extends RootTableManager<
    _$AppDb,
    $UsageMonthsTable,
    UsageMonth,
    $$UsageMonthsTableFilterComposer,
    $$UsageMonthsTableOrderingComposer,
    $$UsageMonthsTableAnnotationComposer,
    $$UsageMonthsTableCreateCompanionBuilder,
    $$UsageMonthsTableUpdateCompanionBuilder,
    (UsageMonth, BaseReferences<_$AppDb, $UsageMonthsTable, UsageMonth>),
    UsageMonth,
    PrefetchHooks Function()> {
  $$UsageMonthsTableTableManager(_$AppDb db, $UsageMonthsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsageMonthsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsageMonthsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsageMonthsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> month = const Value.absent(),
            Value<int> cloudSummariesUsed = const Value.absent(),
            Value<int> recordedMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsageMonthsCompanion(
            month: month,
            cloudSummariesUsed: cloudSummariesUsed,
            recordedMs: recordedMs,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String month,
            Value<int> cloudSummariesUsed = const Value.absent(),
            Value<int> recordedMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UsageMonthsCompanion.insert(
            month: month,
            cloudSummariesUsed: cloudSummariesUsed,
            recordedMs: recordedMs,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsageMonthsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $UsageMonthsTable,
    UsageMonth,
    $$UsageMonthsTableFilterComposer,
    $$UsageMonthsTableOrderingComposer,
    $$UsageMonthsTableAnnotationComposer,
    $$UsageMonthsTableCreateCompanionBuilder,
    $$UsageMonthsTableUpdateCompanionBuilder,
    (UsageMonth, BaseReferences<_$AppDb, $UsageMonthsTable, UsageMonth>),
    UsageMonth,
    PrefetchHooks Function()>;
typedef $$TopUpCreditsTableCreateCompanionBuilder = TopUpCreditsCompanion
    Function({
  required String id,
  required int remaining,
  required DateTime purchasedAt,
  required String productId,
  Value<int> rowid,
});
typedef $$TopUpCreditsTableUpdateCompanionBuilder = TopUpCreditsCompanion
    Function({
  Value<String> id,
  Value<int> remaining,
  Value<DateTime> purchasedAt,
  Value<String> productId,
  Value<int> rowid,
});

class $$TopUpCreditsTableFilterComposer
    extends Composer<_$AppDb, $TopUpCreditsTable> {
  $$TopUpCreditsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remaining => $composableBuilder(
      column: $table.remaining, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get purchasedAt => $composableBuilder(
      column: $table.purchasedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));
}

class $$TopUpCreditsTableOrderingComposer
    extends Composer<_$AppDb, $TopUpCreditsTable> {
  $$TopUpCreditsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remaining => $composableBuilder(
      column: $table.remaining, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get purchasedAt => $composableBuilder(
      column: $table.purchasedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));
}

class $$TopUpCreditsTableAnnotationComposer
    extends Composer<_$AppDb, $TopUpCreditsTable> {
  $$TopUpCreditsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get remaining =>
      $composableBuilder(column: $table.remaining, builder: (column) => column);

  GeneratedColumn<DateTime> get purchasedAt => $composableBuilder(
      column: $table.purchasedAt, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);
}

class $$TopUpCreditsTableTableManager extends RootTableManager<
    _$AppDb,
    $TopUpCreditsTable,
    TopUpCredit,
    $$TopUpCreditsTableFilterComposer,
    $$TopUpCreditsTableOrderingComposer,
    $$TopUpCreditsTableAnnotationComposer,
    $$TopUpCreditsTableCreateCompanionBuilder,
    $$TopUpCreditsTableUpdateCompanionBuilder,
    (TopUpCredit, BaseReferences<_$AppDb, $TopUpCreditsTable, TopUpCredit>),
    TopUpCredit,
    PrefetchHooks Function()> {
  $$TopUpCreditsTableTableManager(_$AppDb db, $TopUpCreditsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TopUpCreditsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TopUpCreditsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TopUpCreditsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> remaining = const Value.absent(),
            Value<DateTime> purchasedAt = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TopUpCreditsCompanion(
            id: id,
            remaining: remaining,
            purchasedAt: purchasedAt,
            productId: productId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int remaining,
            required DateTime purchasedAt,
            required String productId,
            Value<int> rowid = const Value.absent(),
          }) =>
              TopUpCreditsCompanion.insert(
            id: id,
            remaining: remaining,
            purchasedAt: purchasedAt,
            productId: productId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TopUpCreditsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $TopUpCreditsTable,
    TopUpCredit,
    $$TopUpCreditsTableFilterComposer,
    $$TopUpCreditsTableOrderingComposer,
    $$TopUpCreditsTableAnnotationComposer,
    $$TopUpCreditsTableCreateCompanionBuilder,
    $$TopUpCreditsTableUpdateCompanionBuilder,
    (TopUpCredit, BaseReferences<_$AppDb, $TopUpCreditsTable, TopUpCredit>),
    TopUpCredit,
    PrefetchHooks Function()>;
typedef $$VoiceprintsTableCreateCompanionBuilder = VoiceprintsCompanion
    Function({
  required String id,
  required String name,
  required Uint8List embedding,
  Value<String?> avatarPath,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$VoiceprintsTableUpdateCompanionBuilder = VoiceprintsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<Uint8List> embedding,
  Value<String?> avatarPath,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$VoiceprintsTableFilterComposer
    extends Composer<_$AppDb, $VoiceprintsTable> {
  $$VoiceprintsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<Uint8List> get embedding => $composableBuilder(
      column: $table.embedding, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$VoiceprintsTableOrderingComposer
    extends Composer<_$AppDb, $VoiceprintsTable> {
  $$VoiceprintsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get embedding => $composableBuilder(
      column: $table.embedding, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$VoiceprintsTableAnnotationComposer
    extends Composer<_$AppDb, $VoiceprintsTable> {
  $$VoiceprintsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<Uint8List> get embedding =>
      $composableBuilder(column: $table.embedding, builder: (column) => column);

  GeneratedColumn<String> get avatarPath => $composableBuilder(
      column: $table.avatarPath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$VoiceprintsTableTableManager extends RootTableManager<
    _$AppDb,
    $VoiceprintsTable,
    Voiceprint,
    $$VoiceprintsTableFilterComposer,
    $$VoiceprintsTableOrderingComposer,
    $$VoiceprintsTableAnnotationComposer,
    $$VoiceprintsTableCreateCompanionBuilder,
    $$VoiceprintsTableUpdateCompanionBuilder,
    (Voiceprint, BaseReferences<_$AppDb, $VoiceprintsTable, Voiceprint>),
    Voiceprint,
    PrefetchHooks Function()> {
  $$VoiceprintsTableTableManager(_$AppDb db, $VoiceprintsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoiceprintsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoiceprintsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoiceprintsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<Uint8List> embedding = const Value.absent(),
            Value<String?> avatarPath = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VoiceprintsCompanion(
            id: id,
            name: name,
            embedding: embedding,
            avatarPath: avatarPath,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required Uint8List embedding,
            Value<String?> avatarPath = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              VoiceprintsCompanion.insert(
            id: id,
            name: name,
            embedding: embedding,
            avatarPath: avatarPath,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VoiceprintsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $VoiceprintsTable,
    Voiceprint,
    $$VoiceprintsTableFilterComposer,
    $$VoiceprintsTableOrderingComposer,
    $$VoiceprintsTableAnnotationComposer,
    $$VoiceprintsTableCreateCompanionBuilder,
    $$VoiceprintsTableUpdateCompanionBuilder,
    (Voiceprint, BaseReferences<_$AppDb, $VoiceprintsTable, Voiceprint>),
    Voiceprint,
    PrefetchHooks Function()>;
typedef $$SegmentEmbeddingsTableCreateCompanionBuilder
    = SegmentEmbeddingsCompanion Function({
  required String segmentId,
  required String meetingId,
  required Uint8List vec,
  Value<int> dim,
  Value<String> model,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$SegmentEmbeddingsTableUpdateCompanionBuilder
    = SegmentEmbeddingsCompanion Function({
  Value<String> segmentId,
  Value<String> meetingId,
  Value<Uint8List> vec,
  Value<int> dim,
  Value<String> model,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$SegmentEmbeddingsTableReferences
    extends BaseReferences<_$AppDb, $SegmentEmbeddingsTable, SegmentEmbedding> {
  $$SegmentEmbeddingsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $TranscriptSegmentsTable _segmentIdTable(_$AppDb db) =>
      db.transcriptSegments.createAlias($_aliasNameGenerator(
          db.segmentEmbeddings.segmentId, db.transcriptSegments.id));

  $$TranscriptSegmentsTableProcessedTableManager get segmentId {
    final $_column = $_itemColumn<String>('segment_id')!;

    final manager =
        $$TranscriptSegmentsTableTableManager($_db, $_db.transcriptSegments)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_segmentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $MeetingsTable _meetingIdTable(_$AppDb db) => db.meetings.createAlias(
      $_aliasNameGenerator(db.segmentEmbeddings.meetingId, db.meetings.id));

  $$MeetingsTableProcessedTableManager get meetingId {
    final $_column = $_itemColumn<String>('meeting_id')!;

    final manager = $$MeetingsTableTableManager($_db, $_db.meetings)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_meetingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SegmentEmbeddingsTableFilterComposer
    extends Composer<_$AppDb, $SegmentEmbeddingsTable> {
  $$SegmentEmbeddingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<Uint8List> get vec => $composableBuilder(
      column: $table.vec, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dim => $composableBuilder(
      column: $table.dim, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$TranscriptSegmentsTableFilterComposer get segmentId {
    final $$TranscriptSegmentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.segmentId,
        referencedTable: $db.transcriptSegments,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TranscriptSegmentsTableFilterComposer(
              $db: $db,
              $table: $db.transcriptSegments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$MeetingsTableFilterComposer get meetingId {
    final $$MeetingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableFilterComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SegmentEmbeddingsTableOrderingComposer
    extends Composer<_$AppDb, $SegmentEmbeddingsTable> {
  $$SegmentEmbeddingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get vec => $composableBuilder(
      column: $table.vec, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dim => $composableBuilder(
      column: $table.dim, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$TranscriptSegmentsTableOrderingComposer get segmentId {
    final $$TranscriptSegmentsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.segmentId,
        referencedTable: $db.transcriptSegments,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TranscriptSegmentsTableOrderingComposer(
              $db: $db,
              $table: $db.transcriptSegments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$MeetingsTableOrderingComposer get meetingId {
    final $$MeetingsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableOrderingComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SegmentEmbeddingsTableAnnotationComposer
    extends Composer<_$AppDb, $SegmentEmbeddingsTable> {
  $$SegmentEmbeddingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<Uint8List> get vec =>
      $composableBuilder(column: $table.vec, builder: (column) => column);

  GeneratedColumn<int> get dim =>
      $composableBuilder(column: $table.dim, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TranscriptSegmentsTableAnnotationComposer get segmentId {
    final $$TranscriptSegmentsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.segmentId,
            referencedTable: $db.transcriptSegments,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$TranscriptSegmentsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.transcriptSegments,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  $$MeetingsTableAnnotationComposer get meetingId {
    final $$MeetingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableAnnotationComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SegmentEmbeddingsTableTableManager extends RootTableManager<
    _$AppDb,
    $SegmentEmbeddingsTable,
    SegmentEmbedding,
    $$SegmentEmbeddingsTableFilterComposer,
    $$SegmentEmbeddingsTableOrderingComposer,
    $$SegmentEmbeddingsTableAnnotationComposer,
    $$SegmentEmbeddingsTableCreateCompanionBuilder,
    $$SegmentEmbeddingsTableUpdateCompanionBuilder,
    (SegmentEmbedding, $$SegmentEmbeddingsTableReferences),
    SegmentEmbedding,
    PrefetchHooks Function({bool segmentId, bool meetingId})> {
  $$SegmentEmbeddingsTableTableManager(
      _$AppDb db, $SegmentEmbeddingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SegmentEmbeddingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SegmentEmbeddingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SegmentEmbeddingsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> segmentId = const Value.absent(),
            Value<String> meetingId = const Value.absent(),
            Value<Uint8List> vec = const Value.absent(),
            Value<int> dim = const Value.absent(),
            Value<String> model = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SegmentEmbeddingsCompanion(
            segmentId: segmentId,
            meetingId: meetingId,
            vec: vec,
            dim: dim,
            model: model,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String segmentId,
            required String meetingId,
            required Uint8List vec,
            Value<int> dim = const Value.absent(),
            Value<String> model = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SegmentEmbeddingsCompanion.insert(
            segmentId: segmentId,
            meetingId: meetingId,
            vec: vec,
            dim: dim,
            model: model,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SegmentEmbeddingsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({segmentId = false, meetingId = false}) {
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
                if (segmentId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.segmentId,
                    referencedTable:
                        $$SegmentEmbeddingsTableReferences._segmentIdTable(db),
                    referencedColumn: $$SegmentEmbeddingsTableReferences
                        ._segmentIdTable(db)
                        .id,
                  ) as T;
                }
                if (meetingId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.meetingId,
                    referencedTable:
                        $$SegmentEmbeddingsTableReferences._meetingIdTable(db),
                    referencedColumn: $$SegmentEmbeddingsTableReferences
                        ._meetingIdTable(db)
                        .id,
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

typedef $$SegmentEmbeddingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $SegmentEmbeddingsTable,
    SegmentEmbedding,
    $$SegmentEmbeddingsTableFilterComposer,
    $$SegmentEmbeddingsTableOrderingComposer,
    $$SegmentEmbeddingsTableAnnotationComposer,
    $$SegmentEmbeddingsTableCreateCompanionBuilder,
    $$SegmentEmbeddingsTableUpdateCompanionBuilder,
    (SegmentEmbedding, $$SegmentEmbeddingsTableReferences),
    SegmentEmbedding,
    PrefetchHooks Function({bool segmentId, bool meetingId})>;
typedef $$ActionItemsTableCreateCompanionBuilder = ActionItemsCompanion
    Function({
  required String id,
  required String meetingId,
  required String body,
  Value<String?> assignee,
  Value<DateTime?> dueDate,
  Value<ActionItemStatus> status,
  required DateTime createdAt,
  Value<DateTime?> completedAt,
  Value<int> rowid,
});
typedef $$ActionItemsTableUpdateCompanionBuilder = ActionItemsCompanion
    Function({
  Value<String> id,
  Value<String> meetingId,
  Value<String> body,
  Value<String?> assignee,
  Value<DateTime?> dueDate,
  Value<ActionItemStatus> status,
  Value<DateTime> createdAt,
  Value<DateTime?> completedAt,
  Value<int> rowid,
});

final class $$ActionItemsTableReferences
    extends BaseReferences<_$AppDb, $ActionItemsTable, ActionItem> {
  $$ActionItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MeetingsTable _meetingIdTable(_$AppDb db) => db.meetings.createAlias(
      $_aliasNameGenerator(db.actionItems.meetingId, db.meetings.id));

  $$MeetingsTableProcessedTableManager get meetingId {
    final $_column = $_itemColumn<String>('meeting_id')!;

    final manager = $$MeetingsTableTableManager($_db, $_db.meetings)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_meetingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ActionItemsTableFilterComposer
    extends Composer<_$AppDb, $ActionItemsTable> {
  $$ActionItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get assignee => $composableBuilder(
      column: $table.assignee, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ActionItemStatus, ActionItemStatus, String>
      get status => $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  $$MeetingsTableFilterComposer get meetingId {
    final $$MeetingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableFilterComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ActionItemsTableOrderingComposer
    extends Composer<_$AppDb, $ActionItemsTable> {
  $$ActionItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get assignee => $composableBuilder(
      column: $table.assignee, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  $$MeetingsTableOrderingComposer get meetingId {
    final $$MeetingsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableOrderingComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ActionItemsTableAnnotationComposer
    extends Composer<_$AppDb, $ActionItemsTable> {
  $$ActionItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get assignee =>
      $composableBuilder(column: $table.assignee, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ActionItemStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  $$MeetingsTableAnnotationComposer get meetingId {
    final $$MeetingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableAnnotationComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ActionItemsTableTableManager extends RootTableManager<
    _$AppDb,
    $ActionItemsTable,
    ActionItem,
    $$ActionItemsTableFilterComposer,
    $$ActionItemsTableOrderingComposer,
    $$ActionItemsTableAnnotationComposer,
    $$ActionItemsTableCreateCompanionBuilder,
    $$ActionItemsTableUpdateCompanionBuilder,
    (ActionItem, $$ActionItemsTableReferences),
    ActionItem,
    PrefetchHooks Function({bool meetingId})> {
  $$ActionItemsTableTableManager(_$AppDb db, $ActionItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActionItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActionItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActionItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> meetingId = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String?> assignee = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<ActionItemStatus> status = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ActionItemsCompanion(
            id: id,
            meetingId: meetingId,
            body: body,
            assignee: assignee,
            dueDate: dueDate,
            status: status,
            createdAt: createdAt,
            completedAt: completedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String meetingId,
            required String body,
            Value<String?> assignee = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<ActionItemStatus> status = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ActionItemsCompanion.insert(
            id: id,
            meetingId: meetingId,
            body: body,
            assignee: assignee,
            dueDate: dueDate,
            status: status,
            createdAt: createdAt,
            completedAt: completedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ActionItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({meetingId = false}) {
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
                if (meetingId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.meetingId,
                    referencedTable:
                        $$ActionItemsTableReferences._meetingIdTable(db),
                    referencedColumn:
                        $$ActionItemsTableReferences._meetingIdTable(db).id,
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

typedef $$ActionItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $ActionItemsTable,
    ActionItem,
    $$ActionItemsTableFilterComposer,
    $$ActionItemsTableOrderingComposer,
    $$ActionItemsTableAnnotationComposer,
    $$ActionItemsTableCreateCompanionBuilder,
    $$ActionItemsTableUpdateCompanionBuilder,
    (ActionItem, $$ActionItemsTableReferences),
    ActionItem,
    PrefetchHooks Function({bool meetingId})>;
typedef $$FoldersTableCreateCompanionBuilder = FoldersCompanion Function({
  required String id,
  required String name,
  Value<String?> parentId,
  Value<int> colorIndex,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$FoldersTableUpdateCompanionBuilder = FoldersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> parentId,
  Value<int> colorIndex,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$FoldersTableReferences
    extends BaseReferences<_$AppDb, $FoldersTable, Folder> {
  $$FoldersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MeetingFoldersTable, List<MeetingFolder>>
      _meetingFoldersRefsTable(_$AppDb db) => MultiTypedResultKey.fromTable(
          db.meetingFolders,
          aliasName:
              $_aliasNameGenerator(db.folders.id, db.meetingFolders.folderId));

  $$MeetingFoldersTableProcessedTableManager get meetingFoldersRefs {
    final manager = $$MeetingFoldersTableTableManager($_db, $_db.meetingFolders)
        .filter((f) => f.folderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_meetingFoldersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$FoldersTableFilterComposer extends Composer<_$AppDb, $FoldersTable> {
  $$FoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colorIndex => $composableBuilder(
      column: $table.colorIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> meetingFoldersRefs(
      Expression<bool> Function($$MeetingFoldersTableFilterComposer f) f) {
    final $$MeetingFoldersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.meetingFolders,
        getReferencedColumn: (t) => t.folderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingFoldersTableFilterComposer(
              $db: $db,
              $table: $db.meetingFolders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FoldersTableOrderingComposer extends Composer<_$AppDb, $FoldersTable> {
  $$FoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colorIndex => $composableBuilder(
      column: $table.colorIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$FoldersTableAnnotationComposer
    extends Composer<_$AppDb, $FoldersTable> {
  $$FoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get colorIndex => $composableBuilder(
      column: $table.colorIndex, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> meetingFoldersRefs<T extends Object>(
      Expression<T> Function($$MeetingFoldersTableAnnotationComposer a) f) {
    final $$MeetingFoldersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.meetingFolders,
        getReferencedColumn: (t) => t.folderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingFoldersTableAnnotationComposer(
              $db: $db,
              $table: $db.meetingFolders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FoldersTableTableManager extends RootTableManager<
    _$AppDb,
    $FoldersTable,
    Folder,
    $$FoldersTableFilterComposer,
    $$FoldersTableOrderingComposer,
    $$FoldersTableAnnotationComposer,
    $$FoldersTableCreateCompanionBuilder,
    $$FoldersTableUpdateCompanionBuilder,
    (Folder, $$FoldersTableReferences),
    Folder,
    PrefetchHooks Function({bool meetingFoldersRefs})> {
  $$FoldersTableTableManager(_$AppDb db, $FoldersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<int> colorIndex = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FoldersCompanion(
            id: id,
            name: name,
            parentId: parentId,
            colorIndex: colorIndex,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> parentId = const Value.absent(),
            Value<int> colorIndex = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              FoldersCompanion.insert(
            id: id,
            name: name,
            parentId: parentId,
            colorIndex: colorIndex,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$FoldersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({meetingFoldersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (meetingFoldersRefs) db.meetingFolders
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (meetingFoldersRefs)
                    await $_getPrefetchedData<Folder, $FoldersTable,
                            MeetingFolder>(
                        currentTable: table,
                        referencedTable: $$FoldersTableReferences
                            ._meetingFoldersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FoldersTableReferences(db, table, p0)
                                .meetingFoldersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.folderId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$FoldersTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $FoldersTable,
    Folder,
    $$FoldersTableFilterComposer,
    $$FoldersTableOrderingComposer,
    $$FoldersTableAnnotationComposer,
    $$FoldersTableCreateCompanionBuilder,
    $$FoldersTableUpdateCompanionBuilder,
    (Folder, $$FoldersTableReferences),
    Folder,
    PrefetchHooks Function({bool meetingFoldersRefs})>;
typedef $$MeetingFoldersTableCreateCompanionBuilder = MeetingFoldersCompanion
    Function({
  required String meetingId,
  required String folderId,
  Value<int> rowid,
});
typedef $$MeetingFoldersTableUpdateCompanionBuilder = MeetingFoldersCompanion
    Function({
  Value<String> meetingId,
  Value<String> folderId,
  Value<int> rowid,
});

final class $$MeetingFoldersTableReferences
    extends BaseReferences<_$AppDb, $MeetingFoldersTable, MeetingFolder> {
  $$MeetingFoldersTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $MeetingsTable _meetingIdTable(_$AppDb db) => db.meetings.createAlias(
      $_aliasNameGenerator(db.meetingFolders.meetingId, db.meetings.id));

  $$MeetingsTableProcessedTableManager get meetingId {
    final $_column = $_itemColumn<String>('meeting_id')!;

    final manager = $$MeetingsTableTableManager($_db, $_db.meetings)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_meetingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $FoldersTable _folderIdTable(_$AppDb db) => db.folders.createAlias(
      $_aliasNameGenerator(db.meetingFolders.folderId, db.folders.id));

  $$FoldersTableProcessedTableManager get folderId {
    final $_column = $_itemColumn<String>('folder_id')!;

    final manager = $$FoldersTableTableManager($_db, $_db.folders)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MeetingFoldersTableFilterComposer
    extends Composer<_$AppDb, $MeetingFoldersTable> {
  $$MeetingFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$MeetingsTableFilterComposer get meetingId {
    final $$MeetingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableFilterComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$FoldersTableFilterComposer get folderId {
    final $$FoldersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.folderId,
        referencedTable: $db.folders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FoldersTableFilterComposer(
              $db: $db,
              $table: $db.folders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MeetingFoldersTableOrderingComposer
    extends Composer<_$AppDb, $MeetingFoldersTable> {
  $$MeetingFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$MeetingsTableOrderingComposer get meetingId {
    final $$MeetingsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableOrderingComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$FoldersTableOrderingComposer get folderId {
    final $$FoldersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.folderId,
        referencedTable: $db.folders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FoldersTableOrderingComposer(
              $db: $db,
              $table: $db.folders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MeetingFoldersTableAnnotationComposer
    extends Composer<_$AppDb, $MeetingFoldersTable> {
  $$MeetingFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$MeetingsTableAnnotationComposer get meetingId {
    final $$MeetingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableAnnotationComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$FoldersTableAnnotationComposer get folderId {
    final $$FoldersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.folderId,
        referencedTable: $db.folders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FoldersTableAnnotationComposer(
              $db: $db,
              $table: $db.folders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MeetingFoldersTableTableManager extends RootTableManager<
    _$AppDb,
    $MeetingFoldersTable,
    MeetingFolder,
    $$MeetingFoldersTableFilterComposer,
    $$MeetingFoldersTableOrderingComposer,
    $$MeetingFoldersTableAnnotationComposer,
    $$MeetingFoldersTableCreateCompanionBuilder,
    $$MeetingFoldersTableUpdateCompanionBuilder,
    (MeetingFolder, $$MeetingFoldersTableReferences),
    MeetingFolder,
    PrefetchHooks Function({bool meetingId, bool folderId})> {
  $$MeetingFoldersTableTableManager(_$AppDb db, $MeetingFoldersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeetingFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeetingFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeetingFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> meetingId = const Value.absent(),
            Value<String> folderId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MeetingFoldersCompanion(
            meetingId: meetingId,
            folderId: folderId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String meetingId,
            required String folderId,
            Value<int> rowid = const Value.absent(),
          }) =>
              MeetingFoldersCompanion.insert(
            meetingId: meetingId,
            folderId: folderId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MeetingFoldersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({meetingId = false, folderId = false}) {
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
                if (meetingId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.meetingId,
                    referencedTable:
                        $$MeetingFoldersTableReferences._meetingIdTable(db),
                    referencedColumn:
                        $$MeetingFoldersTableReferences._meetingIdTable(db).id,
                  ) as T;
                }
                if (folderId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.folderId,
                    referencedTable:
                        $$MeetingFoldersTableReferences._folderIdTable(db),
                    referencedColumn:
                        $$MeetingFoldersTableReferences._folderIdTable(db).id,
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

typedef $$MeetingFoldersTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $MeetingFoldersTable,
    MeetingFolder,
    $$MeetingFoldersTableFilterComposer,
    $$MeetingFoldersTableOrderingComposer,
    $$MeetingFoldersTableAnnotationComposer,
    $$MeetingFoldersTableCreateCompanionBuilder,
    $$MeetingFoldersTableUpdateCompanionBuilder,
    (MeetingFolder, $$MeetingFoldersTableReferences),
    MeetingFolder,
    PrefetchHooks Function({bool meetingId, bool folderId})>;
typedef $$MeetingTagsTableCreateCompanionBuilder = MeetingTagsCompanion
    Function({
  required String meetingId,
  required String tag,
  Value<int> rowid,
});
typedef $$MeetingTagsTableUpdateCompanionBuilder = MeetingTagsCompanion
    Function({
  Value<String> meetingId,
  Value<String> tag,
  Value<int> rowid,
});

final class $$MeetingTagsTableReferences
    extends BaseReferences<_$AppDb, $MeetingTagsTable, MeetingTag> {
  $$MeetingTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MeetingsTable _meetingIdTable(_$AppDb db) => db.meetings.createAlias(
      $_aliasNameGenerator(db.meetingTags.meetingId, db.meetings.id));

  $$MeetingsTableProcessedTableManager get meetingId {
    final $_column = $_itemColumn<String>('meeting_id')!;

    final manager = $$MeetingsTableTableManager($_db, $_db.meetings)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_meetingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MeetingTagsTableFilterComposer
    extends Composer<_$AppDb, $MeetingTagsTable> {
  $$MeetingTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnFilters(column));

  $$MeetingsTableFilterComposer get meetingId {
    final $$MeetingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableFilterComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MeetingTagsTableOrderingComposer
    extends Composer<_$AppDb, $MeetingTagsTable> {
  $$MeetingTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tag => $composableBuilder(
      column: $table.tag, builder: (column) => ColumnOrderings(column));

  $$MeetingsTableOrderingComposer get meetingId {
    final $$MeetingsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableOrderingComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MeetingTagsTableAnnotationComposer
    extends Composer<_$AppDb, $MeetingTagsTable> {
  $$MeetingTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  $$MeetingsTableAnnotationComposer get meetingId {
    final $$MeetingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.meetingId,
        referencedTable: $db.meetings,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingsTableAnnotationComposer(
              $db: $db,
              $table: $db.meetings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$MeetingTagsTableTableManager extends RootTableManager<
    _$AppDb,
    $MeetingTagsTable,
    MeetingTag,
    $$MeetingTagsTableFilterComposer,
    $$MeetingTagsTableOrderingComposer,
    $$MeetingTagsTableAnnotationComposer,
    $$MeetingTagsTableCreateCompanionBuilder,
    $$MeetingTagsTableUpdateCompanionBuilder,
    (MeetingTag, $$MeetingTagsTableReferences),
    MeetingTag,
    PrefetchHooks Function({bool meetingId})> {
  $$MeetingTagsTableTableManager(_$AppDb db, $MeetingTagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeetingTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeetingTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeetingTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> meetingId = const Value.absent(),
            Value<String> tag = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MeetingTagsCompanion(
            meetingId: meetingId,
            tag: tag,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String meetingId,
            required String tag,
            Value<int> rowid = const Value.absent(),
          }) =>
              MeetingTagsCompanion.insert(
            meetingId: meetingId,
            tag: tag,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MeetingTagsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({meetingId = false}) {
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
                if (meetingId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.meetingId,
                    referencedTable:
                        $$MeetingTagsTableReferences._meetingIdTable(db),
                    referencedColumn:
                        $$MeetingTagsTableReferences._meetingIdTable(db).id,
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

typedef $$MeetingTagsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $MeetingTagsTable,
    MeetingTag,
    $$MeetingTagsTableFilterComposer,
    $$MeetingTagsTableOrderingComposer,
    $$MeetingTagsTableAnnotationComposer,
    $$MeetingTagsTableCreateCompanionBuilder,
    $$MeetingTagsTableUpdateCompanionBuilder,
    (MeetingTag, $$MeetingTagsTableReferences),
    MeetingTag,
    PrefetchHooks Function({bool meetingId})>;
typedef $$TranslationCacheTableCreateCompanionBuilder
    = TranslationCacheCompanion Function({
  required String sourceHash,
  required String sourceLang,
  required String targetLang,
  required String sourceText,
  required String translation,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$TranslationCacheTableUpdateCompanionBuilder
    = TranslationCacheCompanion Function({
  Value<String> sourceHash,
  Value<String> sourceLang,
  Value<String> targetLang,
  Value<String> sourceText,
  Value<String> translation,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$TranslationCacheTableFilterComposer
    extends Composer<_$AppDb, $TranslationCacheTable> {
  $$TranslationCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sourceHash => $composableBuilder(
      column: $table.sourceHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceLang => $composableBuilder(
      column: $table.sourceLang, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetLang => $composableBuilder(
      column: $table.targetLang, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceText => $composableBuilder(
      column: $table.sourceText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get translation => $composableBuilder(
      column: $table.translation, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$TranslationCacheTableOrderingComposer
    extends Composer<_$AppDb, $TranslationCacheTable> {
  $$TranslationCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sourceHash => $composableBuilder(
      column: $table.sourceHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceLang => $composableBuilder(
      column: $table.sourceLang, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetLang => $composableBuilder(
      column: $table.targetLang, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceText => $composableBuilder(
      column: $table.sourceText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get translation => $composableBuilder(
      column: $table.translation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TranslationCacheTableAnnotationComposer
    extends Composer<_$AppDb, $TranslationCacheTable> {
  $$TranslationCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sourceHash => $composableBuilder(
      column: $table.sourceHash, builder: (column) => column);

  GeneratedColumn<String> get sourceLang => $composableBuilder(
      column: $table.sourceLang, builder: (column) => column);

  GeneratedColumn<String> get targetLang => $composableBuilder(
      column: $table.targetLang, builder: (column) => column);

  GeneratedColumn<String> get sourceText => $composableBuilder(
      column: $table.sourceText, builder: (column) => column);

  GeneratedColumn<String> get translation => $composableBuilder(
      column: $table.translation, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TranslationCacheTableTableManager extends RootTableManager<
    _$AppDb,
    $TranslationCacheTable,
    TranslationCacheData,
    $$TranslationCacheTableFilterComposer,
    $$TranslationCacheTableOrderingComposer,
    $$TranslationCacheTableAnnotationComposer,
    $$TranslationCacheTableCreateCompanionBuilder,
    $$TranslationCacheTableUpdateCompanionBuilder,
    (
      TranslationCacheData,
      BaseReferences<_$AppDb, $TranslationCacheTable, TranslationCacheData>
    ),
    TranslationCacheData,
    PrefetchHooks Function()> {
  $$TranslationCacheTableTableManager(_$AppDb db, $TranslationCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranslationCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranslationCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TranslationCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> sourceHash = const Value.absent(),
            Value<String> sourceLang = const Value.absent(),
            Value<String> targetLang = const Value.absent(),
            Value<String> sourceText = const Value.absent(),
            Value<String> translation = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TranslationCacheCompanion(
            sourceHash: sourceHash,
            sourceLang: sourceLang,
            targetLang: targetLang,
            sourceText: sourceText,
            translation: translation,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String sourceHash,
            required String sourceLang,
            required String targetLang,
            required String sourceText,
            required String translation,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TranslationCacheCompanion.insert(
            sourceHash: sourceHash,
            sourceLang: sourceLang,
            targetLang: targetLang,
            sourceText: sourceText,
            translation: translation,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TranslationCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $TranslationCacheTable,
    TranslationCacheData,
    $$TranslationCacheTableFilterComposer,
    $$TranslationCacheTableOrderingComposer,
    $$TranslationCacheTableAnnotationComposer,
    $$TranslationCacheTableCreateCompanionBuilder,
    $$TranslationCacheTableUpdateCompanionBuilder,
    (
      TranslationCacheData,
      BaseReferences<_$AppDb, $TranslationCacheTable, TranslationCacheData>
    ),
    TranslationCacheData,
    PrefetchHooks Function()>;
typedef $$GlossaryTermsTableCreateCompanionBuilder = GlossaryTermsCompanion
    Function({
  required String term,
  Value<String?> note,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$GlossaryTermsTableUpdateCompanionBuilder = GlossaryTermsCompanion
    Function({
  Value<String> term,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$GlossaryTermsTableFilterComposer
    extends Composer<_$AppDb, $GlossaryTermsTable> {
  $$GlossaryTermsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get term => $composableBuilder(
      column: $table.term, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$GlossaryTermsTableOrderingComposer
    extends Composer<_$AppDb, $GlossaryTermsTable> {
  $$GlossaryTermsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get term => $composableBuilder(
      column: $table.term, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$GlossaryTermsTableAnnotationComposer
    extends Composer<_$AppDb, $GlossaryTermsTable> {
  $$GlossaryTermsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get term =>
      $composableBuilder(column: $table.term, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GlossaryTermsTableTableManager extends RootTableManager<
    _$AppDb,
    $GlossaryTermsTable,
    GlossaryTerm,
    $$GlossaryTermsTableFilterComposer,
    $$GlossaryTermsTableOrderingComposer,
    $$GlossaryTermsTableAnnotationComposer,
    $$GlossaryTermsTableCreateCompanionBuilder,
    $$GlossaryTermsTableUpdateCompanionBuilder,
    (GlossaryTerm, BaseReferences<_$AppDb, $GlossaryTermsTable, GlossaryTerm>),
    GlossaryTerm,
    PrefetchHooks Function()> {
  $$GlossaryTermsTableTableManager(_$AppDb db, $GlossaryTermsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GlossaryTermsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GlossaryTermsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GlossaryTermsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> term = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GlossaryTermsCompanion(
            term: term,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String term,
            Value<String?> note = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              GlossaryTermsCompanion.insert(
            term: term,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GlossaryTermsTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $GlossaryTermsTable,
    GlossaryTerm,
    $$GlossaryTermsTableFilterComposer,
    $$GlossaryTermsTableOrderingComposer,
    $$GlossaryTermsTableAnnotationComposer,
    $$GlossaryTermsTableCreateCompanionBuilder,
    $$GlossaryTermsTableUpdateCompanionBuilder,
    (GlossaryTerm, BaseReferences<_$AppDb, $GlossaryTermsTable, GlossaryTerm>),
    GlossaryTerm,
    PrefetchHooks Function()>;
typedef $$PurchasesTableCreateCompanionBuilder = PurchasesCompanion Function({
  required String id,
  required String productId,
  Value<String?> tier,
  Value<DateTime?> purchasedAt,
  Value<String> source,
  Value<DateTime> recordedAt,
  Value<int> rowid,
});
typedef $$PurchasesTableUpdateCompanionBuilder = PurchasesCompanion Function({
  Value<String> id,
  Value<String> productId,
  Value<String?> tier,
  Value<DateTime?> purchasedAt,
  Value<String> source,
  Value<DateTime> recordedAt,
  Value<int> rowid,
});

class $$PurchasesTableFilterComposer
    extends Composer<_$AppDb, $PurchasesTable> {
  $$PurchasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tier => $composableBuilder(
      column: $table.tier, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get purchasedAt => $composableBuilder(
      column: $table.purchasedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));
}

class $$PurchasesTableOrderingComposer
    extends Composer<_$AppDb, $PurchasesTable> {
  $$PurchasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tier => $composableBuilder(
      column: $table.tier, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get purchasedAt => $composableBuilder(
      column: $table.purchasedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));
}

class $$PurchasesTableAnnotationComposer
    extends Composer<_$AppDb, $PurchasesTable> {
  $$PurchasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get tier =>
      $composableBuilder(column: $table.tier, builder: (column) => column);

  GeneratedColumn<DateTime> get purchasedAt => $composableBuilder(
      column: $table.purchasedAt, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);
}

class $$PurchasesTableTableManager extends RootTableManager<
    _$AppDb,
    $PurchasesTable,
    Purchase,
    $$PurchasesTableFilterComposer,
    $$PurchasesTableOrderingComposer,
    $$PurchasesTableAnnotationComposer,
    $$PurchasesTableCreateCompanionBuilder,
    $$PurchasesTableUpdateCompanionBuilder,
    (Purchase, BaseReferences<_$AppDb, $PurchasesTable, Purchase>),
    Purchase,
    PrefetchHooks Function()> {
  $$PurchasesTableTableManager(_$AppDb db, $PurchasesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PurchasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<String?> tier = const Value.absent(),
            Value<DateTime?> purchasedAt = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PurchasesCompanion(
            id: id,
            productId: productId,
            tier: tier,
            purchasedAt: purchasedAt,
            source: source,
            recordedAt: recordedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String productId,
            Value<String?> tier = const Value.absent(),
            Value<DateTime?> purchasedAt = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PurchasesCompanion.insert(
            id: id,
            productId: productId,
            tier: tier,
            purchasedAt: purchasedAt,
            source: source,
            recordedAt: recordedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PurchasesTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $PurchasesTable,
    Purchase,
    $$PurchasesTableFilterComposer,
    $$PurchasesTableOrderingComposer,
    $$PurchasesTableAnnotationComposer,
    $$PurchasesTableCreateCompanionBuilder,
    $$PurchasesTableUpdateCompanionBuilder,
    (Purchase, BaseReferences<_$AppDb, $PurchasesTable, Purchase>),
    Purchase,
    PrefetchHooks Function()>;
typedef $$TemplatesTableCreateCompanionBuilder = TemplatesCompanion Function({
  required String id,
  required String name,
  Value<String> emoji,
  required String prompt,
  Value<String?> builtinKey,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$TemplatesTableUpdateCompanionBuilder = TemplatesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> emoji,
  Value<String> prompt,
  Value<String?> builtinKey,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$TemplatesTableFilterComposer
    extends Composer<_$AppDb, $TemplatesTable> {
  $$TemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get emoji => $composableBuilder(
      column: $table.emoji, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get prompt => $composableBuilder(
      column: $table.prompt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get builtinKey => $composableBuilder(
      column: $table.builtinKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TemplatesTableOrderingComposer
    extends Composer<_$AppDb, $TemplatesTable> {
  $$TemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get emoji => $composableBuilder(
      column: $table.emoji, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prompt => $composableBuilder(
      column: $table.prompt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get builtinKey => $composableBuilder(
      column: $table.builtinKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TemplatesTableAnnotationComposer
    extends Composer<_$AppDb, $TemplatesTable> {
  $$TemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<String> get builtinKey => $composableBuilder(
      column: $table.builtinKey, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TemplatesTableTableManager extends RootTableManager<
    _$AppDb,
    $TemplatesTable,
    Template,
    $$TemplatesTableFilterComposer,
    $$TemplatesTableOrderingComposer,
    $$TemplatesTableAnnotationComposer,
    $$TemplatesTableCreateCompanionBuilder,
    $$TemplatesTableUpdateCompanionBuilder,
    (Template, BaseReferences<_$AppDb, $TemplatesTable, Template>),
    Template,
    PrefetchHooks Function()> {
  $$TemplatesTableTableManager(_$AppDb db, $TemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> emoji = const Value.absent(),
            Value<String> prompt = const Value.absent(),
            Value<String?> builtinKey = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TemplatesCompanion(
            id: id,
            name: name,
            emoji: emoji,
            prompt: prompt,
            builtinKey: builtinKey,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> emoji = const Value.absent(),
            required String prompt,
            Value<String?> builtinKey = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TemplatesCompanion.insert(
            id: id,
            name: name,
            emoji: emoji,
            prompt: prompt,
            builtinKey: builtinKey,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TemplatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $TemplatesTable,
    Template,
    $$TemplatesTableFilterComposer,
    $$TemplatesTableOrderingComposer,
    $$TemplatesTableAnnotationComposer,
    $$TemplatesTableCreateCompanionBuilder,
    $$TemplatesTableUpdateCompanionBuilder,
    (Template, BaseReferences<_$AppDb, $TemplatesTable, Template>),
    Template,
    PrefetchHooks Function()>;
typedef $$SyncOutboxTableCreateCompanionBuilder = SyncOutboxCompanion Function({
  Value<int> id,
  required String entityTable,
  required String entityId,
  required String op,
  required String hlc,
  Value<DateTime> createdAt,
  Value<int> attempts,
});
typedef $$SyncOutboxTableUpdateCompanionBuilder = SyncOutboxCompanion Function({
  Value<int> id,
  Value<String> entityTable,
  Value<String> entityId,
  Value<String> op,
  Value<String> hlc,
  Value<DateTime> createdAt,
  Value<int> attempts,
});

class $$SyncOutboxTableFilterComposer
    extends Composer<_$AppDb, $SyncOutboxTable> {
  $$SyncOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityTable => $composableBuilder(
      column: $table.entityTable, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get op => $composableBuilder(
      column: $table.op, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hlc => $composableBuilder(
      column: $table.hlc, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));
}

class $$SyncOutboxTableOrderingComposer
    extends Composer<_$AppDb, $SyncOutboxTable> {
  $$SyncOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityTable => $composableBuilder(
      column: $table.entityTable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get op => $composableBuilder(
      column: $table.op, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hlc => $composableBuilder(
      column: $table.hlc, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));
}

class $$SyncOutboxTableAnnotationComposer
    extends Composer<_$AppDb, $SyncOutboxTable> {
  $$SyncOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityTable => $composableBuilder(
      column: $table.entityTable, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);
}

class $$SyncOutboxTableTableManager extends RootTableManager<
    _$AppDb,
    $SyncOutboxTable,
    SyncOutboxData,
    $$SyncOutboxTableFilterComposer,
    $$SyncOutboxTableOrderingComposer,
    $$SyncOutboxTableAnnotationComposer,
    $$SyncOutboxTableCreateCompanionBuilder,
    $$SyncOutboxTableUpdateCompanionBuilder,
    (SyncOutboxData, BaseReferences<_$AppDb, $SyncOutboxTable, SyncOutboxData>),
    SyncOutboxData,
    PrefetchHooks Function()> {
  $$SyncOutboxTableTableManager(_$AppDb db, $SyncOutboxTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> entityTable = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> op = const Value.absent(),
            Value<String> hlc = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> attempts = const Value.absent(),
          }) =>
              SyncOutboxCompanion(
            id: id,
            entityTable: entityTable,
            entityId: entityId,
            op: op,
            hlc: hlc,
            createdAt: createdAt,
            attempts: attempts,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String entityTable,
            required String entityId,
            required String op,
            required String hlc,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> attempts = const Value.absent(),
          }) =>
              SyncOutboxCompanion.insert(
            id: id,
            entityTable: entityTable,
            entityId: entityId,
            op: op,
            hlc: hlc,
            createdAt: createdAt,
            attempts: attempts,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncOutboxTableProcessedTableManager = ProcessedTableManager<
    _$AppDb,
    $SyncOutboxTable,
    SyncOutboxData,
    $$SyncOutboxTableFilterComposer,
    $$SyncOutboxTableOrderingComposer,
    $$SyncOutboxTableAnnotationComposer,
    $$SyncOutboxTableCreateCompanionBuilder,
    $$SyncOutboxTableUpdateCompanionBuilder,
    (SyncOutboxData, BaseReferences<_$AppDb, $SyncOutboxTable, SyncOutboxData>),
    SyncOutboxData,
    PrefetchHooks Function()>;

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$MeetingsTableTableManager get meetings =>
      $$MeetingsTableTableManager(_db, _db.meetings);
  $$TranscriptsTableTableManager get transcripts =>
      $$TranscriptsTableTableManager(_db, _db.transcripts);
  $$TranscriptSegmentsTableTableManager get transcriptSegments =>
      $$TranscriptSegmentsTableTableManager(_db, _db.transcriptSegments);
  $$SummariesTableTableManager get summaries =>
      $$SummariesTableTableManager(_db, _db.summaries);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$UsageDaysTableTableManager get usageDays =>
      $$UsageDaysTableTableManager(_db, _db.usageDays);
  $$UsageMonthsTableTableManager get usageMonths =>
      $$UsageMonthsTableTableManager(_db, _db.usageMonths);
  $$TopUpCreditsTableTableManager get topUpCredits =>
      $$TopUpCreditsTableTableManager(_db, _db.topUpCredits);
  $$VoiceprintsTableTableManager get voiceprints =>
      $$VoiceprintsTableTableManager(_db, _db.voiceprints);
  $$SegmentEmbeddingsTableTableManager get segmentEmbeddings =>
      $$SegmentEmbeddingsTableTableManager(_db, _db.segmentEmbeddings);
  $$ActionItemsTableTableManager get actionItems =>
      $$ActionItemsTableTableManager(_db, _db.actionItems);
  $$FoldersTableTableManager get folders =>
      $$FoldersTableTableManager(_db, _db.folders);
  $$MeetingFoldersTableTableManager get meetingFolders =>
      $$MeetingFoldersTableTableManager(_db, _db.meetingFolders);
  $$MeetingTagsTableTableManager get meetingTags =>
      $$MeetingTagsTableTableManager(_db, _db.meetingTags);
  $$TranslationCacheTableTableManager get translationCache =>
      $$TranslationCacheTableTableManager(_db, _db.translationCache);
  $$GlossaryTermsTableTableManager get glossaryTerms =>
      $$GlossaryTermsTableTableManager(_db, _db.glossaryTerms);
  $$PurchasesTableTableManager get purchases =>
      $$PurchasesTableTableManager(_db, _db.purchases);
  $$TemplatesTableTableManager get templates =>
      $$TemplatesTableTableManager(_db, _db.templates);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db, _db.syncOutbox);
}
