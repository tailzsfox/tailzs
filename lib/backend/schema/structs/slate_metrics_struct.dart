// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart' hide Type;

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SlateMetricsStruct extends FFFirebaseStruct {
  SlateMetricsStruct({
    int? totalGames,
    int? sweepsHit,
    double? overallWinPct,
    int? pendingGames,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _totalGames = totalGames,
        _sweepsHit = sweepsHit,
        _overallWinPct = overallWinPct,
        _pendingGames = pendingGames,
        super(firestoreUtilData);

  // "total_games" field.
  int? _totalGames;
  int get totalGames => _totalGames ?? 0;
  set totalGames(int? val) => _totalGames = val;

  void incrementTotalGames(int amount) => totalGames = totalGames + amount;

  bool hasTotalGames() => _totalGames != null;

  // "sweeps_hit" field.
  int? _sweepsHit;
  int get sweepsHit => _sweepsHit ?? 0;
  set sweepsHit(int? val) => _sweepsHit = val;

  void incrementSweepsHit(int amount) => sweepsHit = sweepsHit + amount;

  bool hasSweepsHit() => _sweepsHit != null;

  // "overall_win_pct" field.
  double? _overallWinPct;
  double get overallWinPct => _overallWinPct ?? 0.0;
  set overallWinPct(double? val) => _overallWinPct = val;

  void incrementOverallWinPct(double amount) =>
      overallWinPct = overallWinPct + amount;

  bool hasOverallWinPct() => _overallWinPct != null;

  // "pending_games" field.
  int? _pendingGames;
  int get pendingGames => _pendingGames ?? 0;
  set pendingGames(int? val) => _pendingGames = val;

  void incrementPendingGames(int amount) =>
      pendingGames = pendingGames + amount;

  bool hasPendingGames() => _pendingGames != null;

  static SlateMetricsStruct fromMap(Map<String, dynamic> data) =>
      SlateMetricsStruct(
        totalGames: castToType<int>(data['total_games']),
        sweepsHit: castToType<int>(data['sweeps_hit']),
        overallWinPct: castToType<double>(data['overall_win_pct']),
        pendingGames: castToType<int>(data['pending_games']),
      );

  static SlateMetricsStruct? maybeFromMap(dynamic data) => data is Map
      ? SlateMetricsStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'total_games': _totalGames,
        'sweeps_hit': _sweepsHit,
        'overall_win_pct': _overallWinPct,
        'pending_games': _pendingGames,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'total_games': serializeParam(
          _totalGames,
          ParamType.int,
        ),
        'sweeps_hit': serializeParam(
          _sweepsHit,
          ParamType.int,
        ),
        'overall_win_pct': serializeParam(
          _overallWinPct,
          ParamType.double,
        ),
        'pending_games': serializeParam(
          _pendingGames,
          ParamType.int,
        ),
      }.withoutNulls;

  static SlateMetricsStruct fromSerializableMap(Map<String, dynamic> data) =>
      SlateMetricsStruct(
        totalGames: deserializeParam(
          data['total_games'],
          ParamType.int,
          false,
        ),
        sweepsHit: deserializeParam(
          data['sweeps_hit'],
          ParamType.int,
          false,
        ),
        overallWinPct: deserializeParam(
          data['overall_win_pct'],
          ParamType.double,
          false,
        ),
        pendingGames: deserializeParam(
          data['pending_games'],
          ParamType.int,
          false,
        ),
      );

  @override
  String toString() => 'SlateMetricsStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is SlateMetricsStruct &&
        totalGames == other.totalGames &&
        sweepsHit == other.sweepsHit &&
        overallWinPct == other.overallWinPct &&
        pendingGames == other.pendingGames;
  }

  @override
  int get hashCode => const ListEquality()
      .hash([totalGames, sweepsHit, overallWinPct, pendingGames]);
}

SlateMetricsStruct createSlateMetricsStruct({
  int? totalGames,
  int? sweepsHit,
  double? overallWinPct,
  int? pendingGames,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    SlateMetricsStruct(
      totalGames: totalGames,
      sweepsHit: sweepsHit,
      overallWinPct: overallWinPct,
      pendingGames: pendingGames,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

SlateMetricsStruct? updateSlateMetricsStruct(
  SlateMetricsStruct? slateMetrics, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    slateMetrics
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addSlateMetricsStructData(
  Map<String, dynamic> firestoreData,
  SlateMetricsStruct? slateMetrics,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (slateMetrics == null) {
    return;
  }
  if (slateMetrics.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && slateMetrics.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final slateMetricsData =
      getSlateMetricsFirestoreData(slateMetrics, forFieldValue);
  final nestedData =
      slateMetricsData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = slateMetrics.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getSlateMetricsFirestoreData(
  SlateMetricsStruct? slateMetrics, [
  bool forFieldValue = false,
]) {
  if (slateMetrics == null) {
    return {};
  }
  final firestoreData = mapToFirestore(slateMetrics.toMap());

  // Add any Firestore field values
  mapToFirestore(slateMetrics.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getSlateMetricsListFirestoreData(
  List<SlateMetricsStruct>? slateMetricss,
) =>
    slateMetricss?.map((e) => getSlateMetricsFirestoreData(e, true)).toList() ??
    [];
