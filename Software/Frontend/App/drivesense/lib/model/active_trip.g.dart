// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_trip.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetActiveTripCollection on Isar {
  IsarCollection<ActiveTrip> get activeTrips => this.collection();
}

const ActiveTripSchema = CollectionSchema(
  name: r'ActiveTrip',
  id: 975461283745502161,
  properties: {
    r'accountId': PropertySchema(
      id: 0,
      name: r'accountId',
      type: IsarType.long,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'distanceMeters': PropertySchema(
      id: 2,
      name: r'distanceMeters',
      type: IsarType.double,
    ),
    r'lastAcceptedPointJson': PropertySchema(
      id: 3,
      name: r'lastAcceptedPointJson',
      type: IsarType.string,
    ),
    r'profileId': PropertySchema(
      id: 4,
      name: r'profileId',
      type: IsarType.long,
    ),
    r'protocolId': PropertySchema(
      id: 5,
      name: r'protocolId',
      type: IsarType.long,
    ),
    r'startMileage': PropertySchema(
      id: 6,
      name: r'startMileage',
      type: IsarType.long,
    ),
    r'startTime': PropertySchema(
      id: 7,
      name: r'startTime',
      type: IsarType.dateTime,
    ),
    r'trackingPointsJson': PropertySchema(
      id: 8,
      name: r'trackingPointsJson',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 9,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'vehicleId': PropertySchema(
      id: 10,
      name: r'vehicleId',
      type: IsarType.long,
    ),
  },
  estimateSize: _activeTripEstimateSize,
  serialize: _activeTripSerialize,
  deserialize: _activeTripDeserialize,
  deserializeProp: _activeTripDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _activeTripGetId,
  getLinks: _activeTripGetLinks,
  attach: _activeTripAttach,
  version: '3.1.0+1',
);

int _activeTripEstimateSize(
  ActiveTrip object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.lastAcceptedPointJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.trackingPointsJson.length * 3;
  return bytesCount;
}

void _activeTripSerialize(
  ActiveTrip object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accountId);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeDouble(offsets[2], object.distanceMeters);
  writer.writeString(offsets[3], object.lastAcceptedPointJson);
  writer.writeLong(offsets[4], object.profileId);
  writer.writeLong(offsets[5], object.protocolId);
  writer.writeLong(offsets[6], object.startMileage);
  writer.writeDateTime(offsets[7], object.startTime);
  writer.writeString(offsets[8], object.trackingPointsJson);
  writer.writeDateTime(offsets[9], object.updatedAt);
  writer.writeLong(offsets[10], object.vehicleId);
}

ActiveTrip _activeTripDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ActiveTrip();
  object.accountId = reader.readLong(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.distanceMeters = reader.readDouble(offsets[2]);
  object.id = id;
  object.lastAcceptedPointJson = reader.readStringOrNull(offsets[3]);
  object.profileId = reader.readLong(offsets[4]);
  object.protocolId = reader.readLong(offsets[5]);
  object.startMileage = reader.readLong(offsets[6]);
  object.startTime = reader.readDateTime(offsets[7]);
  object.trackingPointsJson = reader.readString(offsets[8]);
  object.updatedAt = reader.readDateTime(offsets[9]);
  object.vehicleId = reader.readLong(offsets[10]);
  return object;
}

P _activeTripDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readDateTime(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _activeTripGetId(ActiveTrip object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _activeTripGetLinks(ActiveTrip object) {
  return [];
}

void _activeTripAttach(IsarCollection<dynamic> col, Id id, ActiveTrip object) {
  object.id = id;
}

extension ActiveTripQueryWhereSort
    on QueryBuilder<ActiveTrip, ActiveTrip, QWhere> {
  QueryBuilder<ActiveTrip, ActiveTrip, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ActiveTripQueryWhere
    on QueryBuilder<ActiveTrip, ActiveTrip, QWhereClause> {
  QueryBuilder<ActiveTrip, ActiveTrip, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension ActiveTripQueryFilter
    on QueryBuilder<ActiveTrip, ActiveTrip, QFilterCondition> {
  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> accountIdEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'accountId', value: value),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  accountIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'accountId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> accountIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'accountId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> accountIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'accountId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> createdAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  distanceMetersEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'distanceMeters',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  distanceMetersGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'distanceMeters',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  distanceMetersLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'distanceMeters',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  distanceMetersBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'distanceMeters',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  lastAcceptedPointJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastAcceptedPointJson'),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  lastAcceptedPointJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastAcceptedPointJson'),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  lastAcceptedPointJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastAcceptedPointJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  lastAcceptedPointJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastAcceptedPointJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  lastAcceptedPointJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastAcceptedPointJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  lastAcceptedPointJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastAcceptedPointJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  lastAcceptedPointJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastAcceptedPointJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  lastAcceptedPointJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastAcceptedPointJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  lastAcceptedPointJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastAcceptedPointJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  lastAcceptedPointJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastAcceptedPointJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  lastAcceptedPointJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastAcceptedPointJson', value: ''),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  lastAcceptedPointJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'lastAcceptedPointJson',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> profileIdEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'profileId', value: value),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  profileIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'profileId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> profileIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'profileId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> profileIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'profileId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> protocolIdEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'protocolId', value: value),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  protocolIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'protocolId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  protocolIdLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'protocolId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> protocolIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'protocolId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  startMileageEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'startMileage', value: value),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  startMileageGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'startMileage',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  startMileageLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'startMileage',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  startMileageBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'startMileage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> startTimeEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'startTime', value: value),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  startTimeGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'startTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> startTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'startTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> startTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'startTime',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  trackingPointsJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'trackingPointsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  trackingPointsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'trackingPointsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  trackingPointsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'trackingPointsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  trackingPointsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'trackingPointsJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  trackingPointsJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'trackingPointsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  trackingPointsJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'trackingPointsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  trackingPointsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'trackingPointsJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  trackingPointsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'trackingPointsJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  trackingPointsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'trackingPointsJson', value: ''),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  trackingPointsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'trackingPointsJson', value: ''),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> updatedAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> vehicleIdEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'vehicleId', value: value),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition>
  vehicleIdGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'vehicleId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> vehicleIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'vehicleId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterFilterCondition> vehicleIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'vehicleId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension ActiveTripQueryObject
    on QueryBuilder<ActiveTrip, ActiveTrip, QFilterCondition> {}

extension ActiveTripQueryLinks
    on QueryBuilder<ActiveTrip, ActiveTrip, QFilterCondition> {}

extension ActiveTripQuerySortBy
    on QueryBuilder<ActiveTrip, ActiveTrip, QSortBy> {
  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> sortByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> sortByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> sortByDistanceMeters() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceMeters', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy>
  sortByDistanceMetersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceMeters', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy>
  sortByLastAcceptedPointJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAcceptedPointJson', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy>
  sortByLastAcceptedPointJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAcceptedPointJson', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> sortByProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> sortByProfileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> sortByProtocolId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protocolId', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> sortByProtocolIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protocolId', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> sortByStartMileage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMileage', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> sortByStartMileageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMileage', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> sortByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> sortByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy>
  sortByTrackingPointsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackingPointsJson', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy>
  sortByTrackingPointsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackingPointsJson', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> sortByVehicleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vehicleId', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> sortByVehicleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vehicleId', Sort.desc);
    });
  }
}

extension ActiveTripQuerySortThenBy
    on QueryBuilder<ActiveTrip, ActiveTrip, QSortThenBy> {
  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenByAccountIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accountId', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenByDistanceMeters() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceMeters', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy>
  thenByDistanceMetersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceMeters', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy>
  thenByLastAcceptedPointJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAcceptedPointJson', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy>
  thenByLastAcceptedPointJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAcceptedPointJson', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenByProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenByProfileIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'profileId', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenByProtocolId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protocolId', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenByProtocolIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'protocolId', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenByStartMileage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMileage', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenByStartMileageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startMileage', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenByStartTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startTime', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy>
  thenByTrackingPointsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackingPointsJson', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy>
  thenByTrackingPointsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trackingPointsJson', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenByVehicleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vehicleId', Sort.asc);
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QAfterSortBy> thenByVehicleIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'vehicleId', Sort.desc);
    });
  }
}

extension ActiveTripQueryWhereDistinct
    on QueryBuilder<ActiveTrip, ActiveTrip, QDistinct> {
  QueryBuilder<ActiveTrip, ActiveTrip, QDistinct> distinctByAccountId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accountId');
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QDistinct> distinctByDistanceMeters() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'distanceMeters');
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QDistinct>
  distinctByLastAcceptedPointJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'lastAcceptedPointJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QDistinct> distinctByProfileId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'profileId');
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QDistinct> distinctByProtocolId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'protocolId');
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QDistinct> distinctByStartMileage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startMileage');
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QDistinct> distinctByStartTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startTime');
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QDistinct> distinctByTrackingPointsJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'trackingPointsJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<ActiveTrip, ActiveTrip, QDistinct> distinctByVehicleId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'vehicleId');
    });
  }
}

extension ActiveTripQueryProperty
    on QueryBuilder<ActiveTrip, ActiveTrip, QQueryProperty> {
  QueryBuilder<ActiveTrip, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ActiveTrip, int, QQueryOperations> accountIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accountId');
    });
  }

  QueryBuilder<ActiveTrip, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ActiveTrip, double, QQueryOperations> distanceMetersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'distanceMeters');
    });
  }

  QueryBuilder<ActiveTrip, String?, QQueryOperations>
  lastAcceptedPointJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastAcceptedPointJson');
    });
  }

  QueryBuilder<ActiveTrip, int, QQueryOperations> profileIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'profileId');
    });
  }

  QueryBuilder<ActiveTrip, int, QQueryOperations> protocolIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'protocolId');
    });
  }

  QueryBuilder<ActiveTrip, int, QQueryOperations> startMileageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startMileage');
    });
  }

  QueryBuilder<ActiveTrip, DateTime, QQueryOperations> startTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startTime');
    });
  }

  QueryBuilder<ActiveTrip, String, QQueryOperations>
  trackingPointsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trackingPointsJson');
    });
  }

  QueryBuilder<ActiveTrip, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<ActiveTrip, int, QQueryOperations> vehicleIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'vehicleId');
    });
  }
}
