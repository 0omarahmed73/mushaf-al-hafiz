// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $WirdsTable extends Wirds with TableInfo<$WirdsTable, Wird> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WirdsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WirdType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WirdType>($WirdsTable.$convertertype);
  static const VerificationMeta _currentPageMeta = const VerificationMeta(
    'currentPage',
  );
  @override
  late final GeneratedColumn<int> currentPage = GeneratedColumn<int>(
    'current_page',
    aliasedName,
    false,
    check: () => ComparableExpr(currentPage).isBetweenValues(1, 604),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _dailyPagesMeta = const VerificationMeta(
    'dailyPages',
  );
  @override
  late final GeneratedColumn<int> dailyPages = GeneratedColumn<int>(
    'daily_pages',
    aliasedName,
    true,
    check: () =>
        dailyPages.isNull() |
        ComparableExpr(dailyPages).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
    'target_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _khatmaCountMeta = const VerificationMeta(
    'khatmaCount',
  );
  @override
  late final GeneratedColumn<int> khatmaCount = GeneratedColumn<int>(
    'khatma_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notifyEnabledMeta = const VerificationMeta(
    'notifyEnabled',
  );
  @override
  late final GeneratedColumn<bool> notifyEnabled = GeneratedColumn<bool>(
    'notify_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notify_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notifyMinutesMeta = const VerificationMeta(
    'notifyMinutes',
  );
  @override
  late final GeneratedColumn<int> notifyMinutes = GeneratedColumn<int>(
    'notify_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    currentPage,
    dailyPages,
    targetDate,
    khatmaCount,
    notifyEnabled,
    notifyMinutes,
    color,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wirds';
  @override
  VerificationContext validateIntegrity(
    Insertable<Wird> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('current_page')) {
      context.handle(
        _currentPageMeta,
        currentPage.isAcceptableOrUnknown(
          data['current_page']!,
          _currentPageMeta,
        ),
      );
    }
    if (data.containsKey('daily_pages')) {
      context.handle(
        _dailyPagesMeta,
        dailyPages.isAcceptableOrUnknown(data['daily_pages']!, _dailyPagesMeta),
      );
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    }
    if (data.containsKey('khatma_count')) {
      context.handle(
        _khatmaCountMeta,
        khatmaCount.isAcceptableOrUnknown(
          data['khatma_count']!,
          _khatmaCountMeta,
        ),
      );
    }
    if (data.containsKey('notify_enabled')) {
      context.handle(
        _notifyEnabledMeta,
        notifyEnabled.isAcceptableOrUnknown(
          data['notify_enabled']!,
          _notifyEnabledMeta,
        ),
      );
    }
    if (data.containsKey('notify_minutes')) {
      context.handle(
        _notifyMinutesMeta,
        notifyMinutes.isAcceptableOrUnknown(
          data['notify_minutes']!,
          _notifyMinutesMeta,
        ),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Wird map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Wird(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $WirdsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      currentPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_page'],
      )!,
      dailyPages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_pages'],
      ),
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}target_date'],
      ),
      khatmaCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}khatma_count'],
      )!,
      notifyEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notify_enabled'],
      )!,
      notifyMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notify_minutes'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WirdsTable createAlias(String alias) {
    return $WirdsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WirdType, String, String> $convertertype =
      const EnumNameConverter<WirdType>(WirdType.values);
}

class Wird extends DataClass implements Insertable<Wird> {
  final int id;
  final String name;
  final WirdType type;

  /// 1..604, default 1.
  final int currentPage;

  /// >= 1 when set; wins over [targetDate].
  final int? dailyPages;

  /// Date only (stored at local midnight).
  final DateTime? targetDate;
  final int khatmaCount;
  final bool notifyEnabled;

  /// Minutes after local midnight.
  final int? notifyMinutes;
  final int color;
  final int sortOrder;
  final DateTime createdAt;
  const Wird({
    required this.id,
    required this.name,
    required this.type,
    required this.currentPage,
    this.dailyPages,
    this.targetDate,
    required this.khatmaCount,
    required this.notifyEnabled,
    this.notifyMinutes,
    required this.color,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>($WirdsTable.$convertertype.toSql(type));
    }
    map['current_page'] = Variable<int>(currentPage);
    if (!nullToAbsent || dailyPages != null) {
      map['daily_pages'] = Variable<int>(dailyPages);
    }
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<DateTime>(targetDate);
    }
    map['khatma_count'] = Variable<int>(khatmaCount);
    map['notify_enabled'] = Variable<bool>(notifyEnabled);
    if (!nullToAbsent || notifyMinutes != null) {
      map['notify_minutes'] = Variable<int>(notifyMinutes);
    }
    map['color'] = Variable<int>(color);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WirdsCompanion toCompanion(bool nullToAbsent) {
    return WirdsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      currentPage: Value(currentPage),
      dailyPages: dailyPages == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyPages),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      khatmaCount: Value(khatmaCount),
      notifyEnabled: Value(notifyEnabled),
      notifyMinutes: notifyMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(notifyMinutes),
      color: Value(color),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Wird.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Wird(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: $WirdsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      currentPage: serializer.fromJson<int>(json['currentPage']),
      dailyPages: serializer.fromJson<int?>(json['dailyPages']),
      targetDate: serializer.fromJson<DateTime?>(json['targetDate']),
      khatmaCount: serializer.fromJson<int>(json['khatmaCount']),
      notifyEnabled: serializer.fromJson<bool>(json['notifyEnabled']),
      notifyMinutes: serializer.fromJson<int?>(json['notifyMinutes']),
      color: serializer.fromJson<int>(json['color']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $WirdsTable.$convertertype.toJson(type),
      ),
      'currentPage': serializer.toJson<int>(currentPage),
      'dailyPages': serializer.toJson<int?>(dailyPages),
      'targetDate': serializer.toJson<DateTime?>(targetDate),
      'khatmaCount': serializer.toJson<int>(khatmaCount),
      'notifyEnabled': serializer.toJson<bool>(notifyEnabled),
      'notifyMinutes': serializer.toJson<int?>(notifyMinutes),
      'color': serializer.toJson<int>(color),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Wird copyWith({
    int? id,
    String? name,
    WirdType? type,
    int? currentPage,
    Value<int?> dailyPages = const Value.absent(),
    Value<DateTime?> targetDate = const Value.absent(),
    int? khatmaCount,
    bool? notifyEnabled,
    Value<int?> notifyMinutes = const Value.absent(),
    int? color,
    int? sortOrder,
    DateTime? createdAt,
  }) => Wird(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    currentPage: currentPage ?? this.currentPage,
    dailyPages: dailyPages.present ? dailyPages.value : this.dailyPages,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    khatmaCount: khatmaCount ?? this.khatmaCount,
    notifyEnabled: notifyEnabled ?? this.notifyEnabled,
    notifyMinutes: notifyMinutes.present
        ? notifyMinutes.value
        : this.notifyMinutes,
    color: color ?? this.color,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  Wird copyWithCompanion(WirdsCompanion data) {
    return Wird(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      currentPage: data.currentPage.present
          ? data.currentPage.value
          : this.currentPage,
      dailyPages: data.dailyPages.present
          ? data.dailyPages.value
          : this.dailyPages,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      khatmaCount: data.khatmaCount.present
          ? data.khatmaCount.value
          : this.khatmaCount,
      notifyEnabled: data.notifyEnabled.present
          ? data.notifyEnabled.value
          : this.notifyEnabled,
      notifyMinutes: data.notifyMinutes.present
          ? data.notifyMinutes.value
          : this.notifyMinutes,
      color: data.color.present ? data.color.value : this.color,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Wird(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currentPage: $currentPage, ')
          ..write('dailyPages: $dailyPages, ')
          ..write('targetDate: $targetDate, ')
          ..write('khatmaCount: $khatmaCount, ')
          ..write('notifyEnabled: $notifyEnabled, ')
          ..write('notifyMinutes: $notifyMinutes, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    currentPage,
    dailyPages,
    targetDate,
    khatmaCount,
    notifyEnabled,
    notifyMinutes,
    color,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Wird &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.currentPage == this.currentPage &&
          other.dailyPages == this.dailyPages &&
          other.targetDate == this.targetDate &&
          other.khatmaCount == this.khatmaCount &&
          other.notifyEnabled == this.notifyEnabled &&
          other.notifyMinutes == this.notifyMinutes &&
          other.color == this.color &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class WirdsCompanion extends UpdateCompanion<Wird> {
  final Value<int> id;
  final Value<String> name;
  final Value<WirdType> type;
  final Value<int> currentPage;
  final Value<int?> dailyPages;
  final Value<DateTime?> targetDate;
  final Value<int> khatmaCount;
  final Value<bool> notifyEnabled;
  final Value<int?> notifyMinutes;
  final Value<int> color;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const WirdsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.currentPage = const Value.absent(),
    this.dailyPages = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.khatmaCount = const Value.absent(),
    this.notifyEnabled = const Value.absent(),
    this.notifyMinutes = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WirdsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required WirdType type,
    this.currentPage = const Value.absent(),
    this.dailyPages = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.khatmaCount = const Value.absent(),
    this.notifyEnabled = const Value.absent(),
    this.notifyMinutes = const Value.absent(),
    required int color,
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       type = Value(type),
       color = Value(color);
  static Insertable<Wird> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? currentPage,
    Expression<int>? dailyPages,
    Expression<DateTime>? targetDate,
    Expression<int>? khatmaCount,
    Expression<bool>? notifyEnabled,
    Expression<int>? notifyMinutes,
    Expression<int>? color,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (currentPage != null) 'current_page': currentPage,
      if (dailyPages != null) 'daily_pages': dailyPages,
      if (targetDate != null) 'target_date': targetDate,
      if (khatmaCount != null) 'khatma_count': khatmaCount,
      if (notifyEnabled != null) 'notify_enabled': notifyEnabled,
      if (notifyMinutes != null) 'notify_minutes': notifyMinutes,
      if (color != null) 'color': color,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WirdsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<WirdType>? type,
    Value<int>? currentPage,
    Value<int?>? dailyPages,
    Value<DateTime?>? targetDate,
    Value<int>? khatmaCount,
    Value<bool>? notifyEnabled,
    Value<int?>? notifyMinutes,
    Value<int>? color,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return WirdsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      currentPage: currentPage ?? this.currentPage,
      dailyPages: dailyPages ?? this.dailyPages,
      targetDate: targetDate ?? this.targetDate,
      khatmaCount: khatmaCount ?? this.khatmaCount,
      notifyEnabled: notifyEnabled ?? this.notifyEnabled,
      notifyMinutes: notifyMinutes ?? this.notifyMinutes,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $WirdsTable.$convertertype.toSql(type.value),
      );
    }
    if (currentPage.present) {
      map['current_page'] = Variable<int>(currentPage.value);
    }
    if (dailyPages.present) {
      map['daily_pages'] = Variable<int>(dailyPages.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (khatmaCount.present) {
      map['khatma_count'] = Variable<int>(khatmaCount.value);
    }
    if (notifyEnabled.present) {
      map['notify_enabled'] = Variable<bool>(notifyEnabled.value);
    }
    if (notifyMinutes.present) {
      map['notify_minutes'] = Variable<int>(notifyMinutes.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WirdsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('currentPage: $currentPage, ')
          ..write('dailyPages: $dailyPages, ')
          ..write('targetDate: $targetDate, ')
          ..write('khatmaCount: $khatmaCount, ')
          ..write('notifyEnabled: $notifyEnabled, ')
          ..write('notifyMinutes: $notifyMinutes, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WirdDaysTable extends WirdDays with TableInfo<$WirdDaysTable, WirdDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WirdDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wirdIdMeta = const VerificationMeta('wirdId');
  @override
  late final GeneratedColumn<int> wirdId = GeneratedColumn<int>(
    'wird_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wirds (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startPageMeta = const VerificationMeta(
    'startPage',
  );
  @override
  late final GeneratedColumn<int> startPage = GeneratedColumn<int>(
    'start_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endPageMeta = const VerificationMeta(
    'endPage',
  );
  @override
  late final GeneratedColumn<int> endPage = GeneratedColumn<int>(
    'end_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doneMeta = const VerificationMeta('done');
  @override
  late final GeneratedColumn<bool> done = GeneratedColumn<bool>(
    'done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [wirdId, day, startPage, endPage, done];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wird_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<WirdDay> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('wird_id')) {
      context.handle(
        _wirdIdMeta,
        wirdId.isAcceptableOrUnknown(data['wird_id']!, _wirdIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wirdIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('start_page')) {
      context.handle(
        _startPageMeta,
        startPage.isAcceptableOrUnknown(data['start_page']!, _startPageMeta),
      );
    } else if (isInserting) {
      context.missing(_startPageMeta);
    }
    if (data.containsKey('end_page')) {
      context.handle(
        _endPageMeta,
        endPage.isAcceptableOrUnknown(data['end_page']!, _endPageMeta),
      );
    } else if (isInserting) {
      context.missing(_endPageMeta);
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wirdId, day};
  @override
  WirdDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WirdDay(
      wirdId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wird_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      startPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_page'],
      )!,
      endPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_page'],
      )!,
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}done'],
      )!,
    );
  }

  @override
  $WirdDaysTable createAlias(String alias) {
    return $WirdDaysTable(attachedDatabase, alias);
  }
}

class WirdDay extends DataClass implements Insertable<WirdDay> {
  final int wirdId;
  final String day;
  final int startPage;
  final int endPage;
  final bool done;
  const WirdDay({
    required this.wirdId,
    required this.day,
    required this.startPage,
    required this.endPage,
    required this.done,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['wird_id'] = Variable<int>(wirdId);
    map['day'] = Variable<String>(day);
    map['start_page'] = Variable<int>(startPage);
    map['end_page'] = Variable<int>(endPage);
    map['done'] = Variable<bool>(done);
    return map;
  }

  WirdDaysCompanion toCompanion(bool nullToAbsent) {
    return WirdDaysCompanion(
      wirdId: Value(wirdId),
      day: Value(day),
      startPage: Value(startPage),
      endPage: Value(endPage),
      done: Value(done),
    );
  }

  factory WirdDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WirdDay(
      wirdId: serializer.fromJson<int>(json['wirdId']),
      day: serializer.fromJson<String>(json['day']),
      startPage: serializer.fromJson<int>(json['startPage']),
      endPage: serializer.fromJson<int>(json['endPage']),
      done: serializer.fromJson<bool>(json['done']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wirdId': serializer.toJson<int>(wirdId),
      'day': serializer.toJson<String>(day),
      'startPage': serializer.toJson<int>(startPage),
      'endPage': serializer.toJson<int>(endPage),
      'done': serializer.toJson<bool>(done),
    };
  }

  WirdDay copyWith({
    int? wirdId,
    String? day,
    int? startPage,
    int? endPage,
    bool? done,
  }) => WirdDay(
    wirdId: wirdId ?? this.wirdId,
    day: day ?? this.day,
    startPage: startPage ?? this.startPage,
    endPage: endPage ?? this.endPage,
    done: done ?? this.done,
  );
  WirdDay copyWithCompanion(WirdDaysCompanion data) {
    return WirdDay(
      wirdId: data.wirdId.present ? data.wirdId.value : this.wirdId,
      day: data.day.present ? data.day.value : this.day,
      startPage: data.startPage.present ? data.startPage.value : this.startPage,
      endPage: data.endPage.present ? data.endPage.value : this.endPage,
      done: data.done.present ? data.done.value : this.done,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WirdDay(')
          ..write('wirdId: $wirdId, ')
          ..write('day: $day, ')
          ..write('startPage: $startPage, ')
          ..write('endPage: $endPage, ')
          ..write('done: $done')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(wirdId, day, startPage, endPage, done);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WirdDay &&
          other.wirdId == this.wirdId &&
          other.day == this.day &&
          other.startPage == this.startPage &&
          other.endPage == this.endPage &&
          other.done == this.done);
}

class WirdDaysCompanion extends UpdateCompanion<WirdDay> {
  final Value<int> wirdId;
  final Value<String> day;
  final Value<int> startPage;
  final Value<int> endPage;
  final Value<bool> done;
  final Value<int> rowid;
  const WirdDaysCompanion({
    this.wirdId = const Value.absent(),
    this.day = const Value.absent(),
    this.startPage = const Value.absent(),
    this.endPage = const Value.absent(),
    this.done = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WirdDaysCompanion.insert({
    required int wirdId,
    required String day,
    required int startPage,
    required int endPage,
    this.done = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : wirdId = Value(wirdId),
       day = Value(day),
       startPage = Value(startPage),
       endPage = Value(endPage);
  static Insertable<WirdDay> custom({
    Expression<int>? wirdId,
    Expression<String>? day,
    Expression<int>? startPage,
    Expression<int>? endPage,
    Expression<bool>? done,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wirdId != null) 'wird_id': wirdId,
      if (day != null) 'day': day,
      if (startPage != null) 'start_page': startPage,
      if (endPage != null) 'end_page': endPage,
      if (done != null) 'done': done,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WirdDaysCompanion copyWith({
    Value<int>? wirdId,
    Value<String>? day,
    Value<int>? startPage,
    Value<int>? endPage,
    Value<bool>? done,
    Value<int>? rowid,
  }) {
    return WirdDaysCompanion(
      wirdId: wirdId ?? this.wirdId,
      day: day ?? this.day,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      done: done ?? this.done,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wirdId.present) {
      map['wird_id'] = Variable<int>(wirdId.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (startPage.present) {
      map['start_page'] = Variable<int>(startPage.value);
    }
    if (endPage.present) {
      map['end_page'] = Variable<int>(endPage.value);
    }
    if (done.present) {
      map['done'] = Variable<bool>(done.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WirdDaysCompanion(')
          ..write('wirdId: $wirdId, ')
          ..write('day: $day, ')
          ..write('startPage: $startPage, ')
          ..write('endPage: $endPage, ')
          ..write('done: $done, ')
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
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _wirdIdMeta = const VerificationMeta('wirdId');
  @override
  late final GeneratedColumn<int> wirdId = GeneratedColumn<int>(
    'wird_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES wirds (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    check: () => ComparableExpr(page).isBetweenValues(1, 604),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _surahMeta = const VerificationMeta('surah');
  @override
  late final GeneratedColumn<int> surah = GeneratedColumn<int>(
    'surah',
    aliasedName,
    true,
    check: () => surah.isNull() | ComparableExpr(surah).isBetweenValues(1, 114),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ayahMeta = const VerificationMeta('ayah');
  @override
  late final GeneratedColumn<int> ayah = GeneratedColumn<int>(
    'ayah',
    aliasedName,
    true,
    check: () =>
        ayah.isNull().equalsExp(surah.isNull()) &
        (ayah.isNull() | ComparableExpr(ayah).isBetweenValues(1, 286)),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wirdId,
    page,
    note,
    createdAt,
    surah,
    ayah,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('wird_id')) {
      context.handle(
        _wirdIdMeta,
        wirdId.isAcceptableOrUnknown(data['wird_id']!, _wirdIdMeta),
      );
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('surah')) {
      context.handle(
        _surahMeta,
        surah.isAcceptableOrUnknown(data['surah']!, _surahMeta),
      );
    }
    if (data.containsKey('ayah')) {
      context.handle(
        _ayahMeta,
        ayah.isAcceptableOrUnknown(data['ayah']!, _ayahMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wirdId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wird_id'],
      ),
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      surah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah'],
      ),
      ayah: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ayah'],
      ),
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final int id;
  final int? wirdId;
  final int page;
  final String? note;
  final DateTime createdAt;

  /// The ayah's surah, 1..114; null on a page bookmark (schema 2, data-model.md).
  final int? surah;

  /// The ayah's number, both or neither with [surah]. The cross-column rule lives here, on the column added second,
  /// because SQLite refuses a CHECK that names a column that does not exist yet (research D1). 286 is the longest
  /// surah; that the ayah exists in its surah is checked where rows are made and on import.
  final int? ayah;
  const Bookmark({
    required this.id,
    this.wirdId,
    required this.page,
    this.note,
    required this.createdAt,
    this.surah,
    this.ayah,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || wirdId != null) {
      map['wird_id'] = Variable<int>(wirdId);
    }
    map['page'] = Variable<int>(page);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || surah != null) {
      map['surah'] = Variable<int>(surah);
    }
    if (!nullToAbsent || ayah != null) {
      map['ayah'] = Variable<int>(ayah);
    }
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      wirdId: wirdId == null && nullToAbsent
          ? const Value.absent()
          : Value(wirdId),
      page: Value(page),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      surah: surah == null && nullToAbsent
          ? const Value.absent()
          : Value(surah),
      ayah: ayah == null && nullToAbsent ? const Value.absent() : Value(ayah),
    );
  }

  factory Bookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<int>(json['id']),
      wirdId: serializer.fromJson<int?>(json['wirdId']),
      page: serializer.fromJson<int>(json['page']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      surah: serializer.fromJson<int?>(json['surah']),
      ayah: serializer.fromJson<int?>(json['ayah']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wirdId': serializer.toJson<int?>(wirdId),
      'page': serializer.toJson<int>(page),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'surah': serializer.toJson<int?>(surah),
      'ayah': serializer.toJson<int?>(ayah),
    };
  }

  Bookmark copyWith({
    int? id,
    Value<int?> wirdId = const Value.absent(),
    int? page,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    Value<int?> surah = const Value.absent(),
    Value<int?> ayah = const Value.absent(),
  }) => Bookmark(
    id: id ?? this.id,
    wirdId: wirdId.present ? wirdId.value : this.wirdId,
    page: page ?? this.page,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    surah: surah.present ? surah.value : this.surah,
    ayah: ayah.present ? ayah.value : this.ayah,
  );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      wirdId: data.wirdId.present ? data.wirdId.value : this.wirdId,
      page: data.page.present ? data.page.value : this.page,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      surah: data.surah.present ? data.surah.value : this.surah,
      ayah: data.ayah.present ? data.ayah.value : this.ayah,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('wirdId: $wirdId, ')
          ..write('page: $page, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, wirdId, page, note, createdAt, surah, ayah);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.wirdId == this.wirdId &&
          other.page == this.page &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.surah == this.surah &&
          other.ayah == this.ayah);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<int> id;
  final Value<int?> wirdId;
  final Value<int> page;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int?> surah;
  final Value<int?> ayah;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.wirdId = const Value.absent(),
    this.page = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
  });
  BookmarksCompanion.insert({
    this.id = const Value.absent(),
    this.wirdId = const Value.absent(),
    required int page,
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.surah = const Value.absent(),
    this.ayah = const Value.absent(),
  }) : page = Value(page);
  static Insertable<Bookmark> custom({
    Expression<int>? id,
    Expression<int>? wirdId,
    Expression<int>? page,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? surah,
    Expression<int>? ayah,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wirdId != null) 'wird_id': wirdId,
      if (page != null) 'page': page,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (surah != null) 'surah': surah,
      if (ayah != null) 'ayah': ayah,
    });
  }

  BookmarksCompanion copyWith({
    Value<int>? id,
    Value<int?>? wirdId,
    Value<int>? page,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<int?>? surah,
    Value<int?>? ayah,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      wirdId: wirdId ?? this.wirdId,
      page: page ?? this.page,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wirdId.present) {
      map['wird_id'] = Variable<int>(wirdId.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (surah.present) {
      map['surah'] = Variable<int>(surah.value);
    }
    if (ayah.present) {
      map['ayah'] = Variable<int>(ayah.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('wirdId: $wirdId, ')
          ..write('page: $page, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('surah: $surah, ')
          ..write('ayah: $ayah')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WirdsTable wirds = $WirdsTable(this);
  late final $WirdDaysTable wirdDays = $WirdDaysTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    wirds,
    wirdDays,
    bookmarks,
    settings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'wirds',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('wird_days', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'wirds',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('bookmarks', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$WirdsTableCreateCompanionBuilder = WirdsCompanion Function({
  Value<int> id,
  required String name,
  required WirdType type,
  Value<int> currentPage,
  Value<int?> dailyPages,
  Value<DateTime?> targetDate,
  Value<int> khatmaCount,
  Value<bool> notifyEnabled,
  Value<int?> notifyMinutes,
  required int color,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});
typedef $$WirdsTableUpdateCompanionBuilder = WirdsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<WirdType> type,
  Value<int> currentPage,
  Value<int?> dailyPages,
  Value<DateTime?> targetDate,
  Value<int> khatmaCount,
  Value<bool> notifyEnabled,
  Value<int?> notifyMinutes,
  Value<int> color,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});

final class $$WirdsTableReferences
    extends BaseReferences<_$AppDatabase, $WirdsTable, Wird> {
  $$WirdsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WirdDaysTable, List<WirdDay>> _wirdDaysRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.wirdDays,
    aliasName: 'wirds__id__wird_days__wird_id',
  );

  $$WirdDaysTableProcessedTableManager get wirdDaysRefs {
    final manager = $$WirdDaysTableTableManager(
      $_db,
      $_db.wirdDays,
    ).filter((f) => f.wirdId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wirdDaysRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BookmarksTable, List<Bookmark>>
  _bookmarksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.bookmarks,
    aliasName: 'wirds__id__bookmarks__wird_id',
  );

  $$BookmarksTableProcessedTableManager get bookmarksRefs {
    final manager = $$BookmarksTableTableManager(
      $_db,
      $_db.bookmarks,
    ).filter((f) => f.wirdId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookmarksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WirdsTableFilterComposer extends Composer<_$AppDatabase, $WirdsTable> {
  $$WirdsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WirdType, WirdType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyPages => $composableBuilder(
    column: $table.dailyPages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get khatmaCount => $composableBuilder(
    column: $table.khatmaCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifyEnabled => $composableBuilder(
    column: $table.notifyEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notifyMinutes => $composableBuilder(
    column: $table.notifyMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> wirdDaysRefs(
    Expression<bool> Function($$WirdDaysTableFilterComposer f) f,
  ) {
    final $$WirdDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wirdDays,
      getReferencedColumn: (t) => t.wirdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WirdDaysTableFilterComposer(
            $db: $db,
            $table: $db.wirdDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookmarksRefs(
    Expression<bool> Function($$BookmarksTableFilterComposer f) f,
  ) {
    final $$BookmarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.wirdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableFilterComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WirdsTableOrderingComposer
    extends Composer<_$AppDatabase, $WirdsTable> {
  $$WirdsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyPages => $composableBuilder(
    column: $table.dailyPages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get khatmaCount => $composableBuilder(
    column: $table.khatmaCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifyEnabled => $composableBuilder(
    column: $table.notifyEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notifyMinutes => $composableBuilder(
    column: $table.notifyMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WirdsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WirdsTable> {
  $$WirdsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WirdType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get currentPage => $composableBuilder(
    column: $table.currentPage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyPages => $composableBuilder(
    column: $table.dailyPages,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get khatmaCount => $composableBuilder(
    column: $table.khatmaCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notifyEnabled => $composableBuilder(
    column: $table.notifyEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get notifyMinutes => $composableBuilder(
    column: $table.notifyMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> wirdDaysRefs<T extends Object>(
    Expression<T> Function($$WirdDaysTableAnnotationComposer a) f,
  ) {
    final $$WirdDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wirdDays,
      getReferencedColumn: (t) => t.wirdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WirdDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.wirdDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bookmarksRefs<T extends Object>(
    Expression<T> Function($$BookmarksTableAnnotationComposer a) f,
  ) {
    final $$BookmarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.wirdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableAnnotationComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WirdsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WirdsTable,
          Wird,
          $$WirdsTableFilterComposer,
          $$WirdsTableOrderingComposer,
          $$WirdsTableAnnotationComposer,
          $$WirdsTableCreateCompanionBuilder,
          $$WirdsTableUpdateCompanionBuilder,
          (Wird, $$WirdsTableReferences),
          Wird,
          PrefetchHooks Function({bool wirdDaysRefs, bool bookmarksRefs})
        > {
  $$WirdsTableTableManager(_$AppDatabase db, $WirdsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WirdsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WirdsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WirdsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<WirdType> type = const Value.absent(),
                Value<int> currentPage = const Value.absent(),
                Value<int?> dailyPages = const Value.absent(),
                Value<DateTime?> targetDate = const Value.absent(),
                Value<int> khatmaCount = const Value.absent(),
                Value<bool> notifyEnabled = const Value.absent(),
                Value<int?> notifyMinutes = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WirdsCompanion(
                id: id,
                name: name,
                type: type,
                currentPage: currentPage,
                dailyPages: dailyPages,
                targetDate: targetDate,
                khatmaCount: khatmaCount,
                notifyEnabled: notifyEnabled,
                notifyMinutes: notifyMinutes,
                color: color,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required WirdType type,
                Value<int> currentPage = const Value.absent(),
                Value<int?> dailyPages = const Value.absent(),
                Value<DateTime?> targetDate = const Value.absent(),
                Value<int> khatmaCount = const Value.absent(),
                Value<bool> notifyEnabled = const Value.absent(),
                Value<int?> notifyMinutes = const Value.absent(),
                required int color,
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WirdsCompanion.insert(
                id: id,
                name: name,
                type: type,
                currentPage: currentPage,
                dailyPages: dailyPages,
                targetDate: targetDate,
                khatmaCount: khatmaCount,
                notifyEnabled: notifyEnabled,
                notifyMinutes: notifyMinutes,
                color: color,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WirdsTable, Wird>(table),
                  $$WirdsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({wirdDaysRefs = false, bookmarksRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (wirdDaysRefs) db.wirdDays,
                    if (bookmarksRefs) db.bookmarks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (wirdDaysRefs)
                        await $_getPrefetchedDataByColumns<
                          Wird,
                          $WirdsTable,
                          WirdDay,
                          $WirdDaysTable
                        >(
                          currentTable: table,
                          referencedTable: $$WirdsTableReferences
                              ._wirdDaysRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WirdsTableReferences(
                                db,
                                table,
                                p0,
                              ).wirdDaysRefs,
                          currentColumn: 'id',
                          referencedColumn: 'wird_id',
                          typedResults: items,
                        ),
                      if (bookmarksRefs)
                        await $_getPrefetchedDataByColumns<
                          Wird,
                          $WirdsTable,
                          Bookmark,
                          $BookmarksTable
                        >(
                          currentTable: table,
                          referencedTable: $$WirdsTableReferences
                              ._bookmarksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WirdsTableReferences(
                                db,
                                table,
                                p0,
                              ).bookmarksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'wird_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WirdsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WirdsTable,
      Wird,
      $$WirdsTableFilterComposer,
      $$WirdsTableOrderingComposer,
      $$WirdsTableAnnotationComposer,
      $$WirdsTableCreateCompanionBuilder,
      $$WirdsTableUpdateCompanionBuilder,
      (Wird, $$WirdsTableReferences),
      Wird,
      PrefetchHooks Function({bool wirdDaysRefs, bool bookmarksRefs})
    >;
typedef $$WirdDaysTableCreateCompanionBuilder = WirdDaysCompanion Function({
  required int wirdId,
  required String day,
  required int startPage,
  required int endPage,
  Value<bool> done,
  Value<int> rowid,
});
typedef $$WirdDaysTableUpdateCompanionBuilder = WirdDaysCompanion Function({
  Value<int> wirdId,
  Value<String> day,
  Value<int> startPage,
  Value<int> endPage,
  Value<bool> done,
  Value<int> rowid,
});

final class $$WirdDaysTableReferences
    extends BaseReferences<_$AppDatabase, $WirdDaysTable, WirdDay> {
  $$WirdDaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WirdsTable _wirdIdTable(_$AppDatabase db) =>
      db.wirds.createAlias('wird_days__wird_id__wirds__id');

  $$WirdsTableProcessedTableManager get wirdId {
    final $_column = $_itemColumn<int>('wird_id')!;

    final manager = $$WirdsTableTableManager(
      $_db,
      $_db.wirds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wirdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WirdDaysTableFilterComposer
    extends Composer<_$AppDatabase, $WirdDaysTable> {
  $$WirdDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startPage => $composableBuilder(
    column: $table.startPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endPage => $composableBuilder(
    column: $table.endPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnFilters(column),
  );

  $$WirdsTableFilterComposer get wirdId {
    final $$WirdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wirdId,
      referencedTable: $db.wirds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WirdsTableFilterComposer(
            $db: $db,
            $table: $db.wirds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WirdDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $WirdDaysTable> {
  $$WirdDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startPage => $composableBuilder(
    column: $table.startPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endPage => $composableBuilder(
    column: $table.endPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => ColumnOrderings(column),
  );

  $$WirdsTableOrderingComposer get wirdId {
    final $$WirdsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wirdId,
      referencedTable: $db.wirds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WirdsTableOrderingComposer(
            $db: $db,
            $table: $db.wirds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WirdDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $WirdDaysTable> {
  $$WirdDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get startPage =>
      $composableBuilder(column: $table.startPage, builder: (column) => column);

  GeneratedColumn<int> get endPage =>
      $composableBuilder(column: $table.endPage, builder: (column) => column);

  GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  $$WirdsTableAnnotationComposer get wirdId {
    final $$WirdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wirdId,
      referencedTable: $db.wirds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WirdsTableAnnotationComposer(
            $db: $db,
            $table: $db.wirds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WirdDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WirdDaysTable,
          WirdDay,
          $$WirdDaysTableFilterComposer,
          $$WirdDaysTableOrderingComposer,
          $$WirdDaysTableAnnotationComposer,
          $$WirdDaysTableCreateCompanionBuilder,
          $$WirdDaysTableUpdateCompanionBuilder,
          (WirdDay, $$WirdDaysTableReferences),
          WirdDay,
          PrefetchHooks Function({bool wirdId})
        > {
  $$WirdDaysTableTableManager(_$AppDatabase db, $WirdDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WirdDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WirdDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WirdDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> wirdId = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<int> startPage = const Value.absent(),
                Value<int> endPage = const Value.absent(),
                Value<bool> done = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WirdDaysCompanion(
                wirdId: wirdId,
                day: day,
                startPage: startPage,
                endPage: endPage,
                done: done,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int wirdId,
                required String day,
                required int startPage,
                required int endPage,
                Value<bool> done = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WirdDaysCompanion.insert(
                wirdId: wirdId,
                day: day,
                startPage: startPage,
                endPage: endPage,
                done: done,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WirdDaysTable, WirdDay>(table),
                  $$WirdDaysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wirdId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (wirdId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.wirdId,
                        referencedTable: $$WirdDaysTableReferences._wirdIdTable(
                          db,
                        ),
                        referencedColumn: $$WirdDaysTableReferences
                            ._wirdIdTable(db)
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
        ),
      );
}

typedef $$WirdDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WirdDaysTable,
      WirdDay,
      $$WirdDaysTableFilterComposer,
      $$WirdDaysTableOrderingComposer,
      $$WirdDaysTableAnnotationComposer,
      $$WirdDaysTableCreateCompanionBuilder,
      $$WirdDaysTableUpdateCompanionBuilder,
      (WirdDay, $$WirdDaysTableReferences),
      WirdDay,
      PrefetchHooks Function({bool wirdId})
    >;
typedef $$BookmarksTableCreateCompanionBuilder = BookmarksCompanion Function({
  Value<int> id,
  Value<int?> wirdId,
  required int page,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<int?> surah,
  Value<int?> ayah,
});
typedef $$BookmarksTableUpdateCompanionBuilder = BookmarksCompanion Function({
  Value<int> id,
  Value<int?> wirdId,
  Value<int> page,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<int?> surah,
  Value<int?> ayah,
});

final class $$BookmarksTableReferences
    extends BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark> {
  $$BookmarksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WirdsTable _wirdIdTable(_$AppDatabase db) =>
      db.wirds.createAlias('bookmarks__wird_id__wirds__id');

  $$WirdsTableProcessedTableManager? get wirdId {
    final $_column = $_itemColumn<int>('wird_id');
    if ($_column == null) return null;
    final manager = $$WirdsTableTableManager(
      $_db,
      $_db.wirds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wirdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnFilters(column),
  );

  $$WirdsTableFilterComposer get wirdId {
    final $$WirdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wirdId,
      referencedTable: $db.wirds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WirdsTableFilterComposer(
            $db: $db,
            $table: $db.wirds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get surah => $composableBuilder(
    column: $table.surah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ayah => $composableBuilder(
    column: $table.ayah,
    builder: (column) => ColumnOrderings(column),
  );

  $$WirdsTableOrderingComposer get wirdId {
    final $$WirdsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wirdId,
      referencedTable: $db.wirds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WirdsTableOrderingComposer(
            $db: $db,
            $table: $db.wirds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get surah =>
      $composableBuilder(column: $table.surah, builder: (column) => column);

  GeneratedColumn<int> get ayah =>
      $composableBuilder(column: $table.ayah, builder: (column) => column);

  $$WirdsTableAnnotationComposer get wirdId {
    final $$WirdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wirdId,
      referencedTable: $db.wirds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WirdsTableAnnotationComposer(
            $db: $db,
            $table: $db.wirds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarksTable,
          Bookmark,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (Bookmark, $$BookmarksTableReferences),
          Bookmark,
          PrefetchHooks Function({bool wirdId})
        > {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> wirdId = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> surah = const Value.absent(),
                Value<int?> ayah = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                wirdId: wirdId,
                page: page,
                note: note,
                createdAt: createdAt,
                surah: surah,
                ayah: ayah,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> wirdId = const Value.absent(),
                required int page,
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int?> surah = const Value.absent(),
                Value<int?> ayah = const Value.absent(),
              }) => BookmarksCompanion.insert(
                id: id,
                wirdId: wirdId,
                page: page,
                note: note,
                createdAt: createdAt,
                surah: surah,
                ayah: ayah,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookmarksTable, Bookmark>(table),
                  $$BookmarksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wirdId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (wirdId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.wirdId,
                        referencedTable: $$BookmarksTableReferences
                            ._wirdIdTable(db),
                        referencedColumn: $$BookmarksTableReferences
                            ._wirdIdTable(db)
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
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarksTable,
      Bookmark,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (Bookmark, $$BookmarksTableReferences),
      Bookmark,
      PrefetchHooks Function({bool wirdId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WirdsTableTableManager get wirds =>
      $$WirdsTableTableManager(_db, _db.wirds);
  $$WirdDaysTableTableManager get wirdDays =>
      $$WirdDaysTableTableManager(_db, _db.wirdDays);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
