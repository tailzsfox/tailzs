// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class GameItemStruct extends FFFirebaseStruct {
  GameItemStruct({
    String? matchup,
    String? resultLabel,
    String? first7,
    String? firstHalfMl,
    String? fullMl,
    Tier1AuditStruct? tier1Audit,
    String? leg1Status,
    String? leg2Status,
    String? leg3Status,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _matchup = matchup,
        _resultLabel = resultLabel,
        _first7 = first7,
        _firstHalfMl = firstHalfMl,
        _fullMl = fullMl,
        _tier1Audit = tier1Audit,
        _leg1Status = leg1Status,
        _leg2Status = leg2Status,
        _leg3Status = leg3Status,
        super(firestoreUtilData);

  // "matchup" field.
  String? _matchup;
  String get matchup => _matchup ?? '';
  set matchup(String? val) => _matchup = val;

  bool hasMatchup() => _matchup != null;

  // "result_label" field.
  String? _resultLabel;
  String get resultLabel => _resultLabel ?? '';
  set resultLabel(String? val) => _resultLabel = val;

  bool hasResultLabel() => _resultLabel != null;

  // "first7" field.
  String? _first7;
  String get first7 => _first7 ?? '';
  set first7(String? val) => _first7 = val;

  bool hasFirst7() => _first7 != null;

  // "first_half_ml" field.
  String? _firstHalfMl;
  String get firstHalfMl => _firstHalfMl ?? '';
  set firstHalfMl(String? val) => _firstHalfMl = val;

  bool hasFirstHalfMl() => _firstHalfMl != null;

  // "full_ml" field.
  String? _fullMl;
  String get fullMl => _fullMl ?? '';
  set fullMl(String? val) => _fullMl = val;

  bool hasFullMl() => _fullMl != null;

  // "tier1_audit" field.
  Tier1AuditStruct? _tier1Audit;
  Tier1AuditStruct get tier1Audit => _tier1Audit ?? Tier1AuditStruct();
  set tier1Audit(Tier1AuditStruct? val) => _tier1Audit = val;

  void updateTier1Audit(Function(Tier1AuditStruct) updateFn) {
    updateFn(_tier1Audit ??= Tier1AuditStruct());
  }

  bool hasTier1Audit() => _tier1Audit != null;

  // "leg1_status" field.
  String? _leg1Status;
  String get leg1Status => _leg1Status ?? '';
  set leg1Status(String? val) => _leg1Status = val;

  bool hasLeg1Status() => _leg1Status != null;

  // "leg2_status" field.
  String? _leg2Status;
  String get leg2Status => _leg2Status ?? '';
  set leg2Status(String? val) => _leg2Status = val;

  bool hasLeg2Status() => _leg2Status != null;

  // "leg3_status" field.
  String? _leg3Status;
  String get leg3Status => _leg3Status ?? '';
  set leg3Status(String? val) => _leg3Status = val;

  bool hasLeg3Status() => _leg3Status != null;

  static GameItemStruct fromMap(Map<String, dynamic> data) => GameItemStruct(
        matchup: data['matchup'] as String?,
        resultLabel: data['result_label'] as String?,
        first7: data['first7'] as String?,
        firstHalfMl: data['first_half_ml'] as String?,
        fullMl: data['full_ml'] as String?,
        tier1Audit: data['tier1_audit'] is Tier1AuditStruct
            ? data['tier1_audit']
            : Tier1AuditStruct.maybeFromMap(data['tier1_audit']),
        leg1Status: data['leg1_status'] as String?,
        leg2Status: data['leg2_status'] as String?,
        leg3Status: data['leg3_status'] as String?,
      );

  static GameItemStruct? maybeFromMap(dynamic data) =>
      data is Map ? GameItemStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'matchup': _matchup,
        'result_label': _resultLabel,
        'first7': _first7,
        'first_half_ml': _firstHalfMl,
        'full_ml': _fullMl,
        'tier1_audit': _tier1Audit?.toMap(),
        'leg1_status': _leg1Status,
        'leg2_status': _leg2Status,
        'leg3_status': _leg3Status,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'matchup': serializeParam(
          _matchup,
          ParamType.String,
        ),
        'result_label': serializeParam(
          _resultLabel,
          ParamType.String,
        ),
        'first7': serializeParam(
          _first7,
          ParamType.String,
        ),
        'first_half_ml': serializeParam(
          _firstHalfMl,
          ParamType.String,
        ),
        'full_ml': serializeParam(
          _fullMl,
          ParamType.String,
        ),
        'tier1_audit': serializeParam(
          _tier1Audit,
          ParamType.DataStruct,
        ),
        'leg1_status': serializeParam(
          _leg1Status,
          ParamType.String,
        ),
        'leg2_status': serializeParam(
          _leg2Status,
          ParamType.String,
        ),
        'leg3_status': serializeParam(
          _leg3Status,
          ParamType.String,
        ),
      }.withoutNulls;

  static GameItemStruct fromSerializableMap(Map<String, dynamic> data) =>
      GameItemStruct(
        matchup: deserializeParam(
          data['matchup'],
          ParamType.String,
          false,
        ),
        resultLabel: deserializeParam(
          data['result_label'],
          ParamType.String,
          false,
        ),
        first7: deserializeParam(
          data['first7'],
          ParamType.String,
          false,
        ),
        firstHalfMl: deserializeParam(
          data['first_half_ml'],
          ParamType.String,
          false,
        ),
        fullMl: deserializeParam(
          data['full_ml'],
          ParamType.String,
          false,
        ),
        tier1Audit: deserializeStructParam(
          data['tier1_audit'],
          ParamType.DataStruct,
          false,
          structBuilder: Tier1AuditStruct.fromSerializableMap,
        ),
        leg1Status: deserializeParam(
          data['leg1_status'],
          ParamType.String,
          false,
        ),
        leg2Status: deserializeParam(
          data['leg2_status'],
          ParamType.String,
          false,
        ),
        leg3Status: deserializeParam(
          data['leg3_status'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'GameItemStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is GameItemStruct &&
        matchup == other.matchup &&
        resultLabel == other.resultLabel &&
        first7 == other.first7 &&
        firstHalfMl == other.firstHalfMl &&
        fullMl == other.fullMl &&
        tier1Audit == other.tier1Audit &&
        leg1Status == other.leg1Status &&
        leg2Status == other.leg2Status &&
        leg3Status == other.leg3Status;
  }

  @override
  int get hashCode => const ListEquality().hash([
        matchup,
        resultLabel,
        first7,
        firstHalfMl,
        fullMl,
        tier1Audit,
        leg1Status,
        leg2Status,
        leg3Status
      ]);
}

GameItemStruct createGameItemStruct({
  String? matchup,
  String? resultLabel,
  String? first7,
  String? firstHalfMl,
  String? fullMl,
  Tier1AuditStruct? tier1Audit,
  String? leg1Status,
  String? leg2Status,
  String? leg3Status,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    GameItemStruct(
      matchup: matchup,
      resultLabel: resultLabel,
      first7: first7,
      firstHalfMl: firstHalfMl,
      fullMl: fullMl,
      tier1Audit: tier1Audit ?? (clearUnsetFields ? Tier1AuditStruct() : null),
      leg1Status: leg1Status,
      leg2Status: leg2Status,
      leg3Status: leg3Status,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

GameItemStruct? updateGameItemStruct(
  GameItemStruct? gameItem, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    gameItem
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addGameItemStructData(
  Map<String, dynamic> firestoreData,
  GameItemStruct? gameItem,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (gameItem == null) {
    return;
  }
  if (gameItem.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && gameItem.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final gameItemData = getGameItemFirestoreData(gameItem, forFieldValue);
  final nestedData = gameItemData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = gameItem.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getGameItemFirestoreData(
  GameItemStruct? gameItem, [
  bool forFieldValue = false,
]) {
  if (gameItem == null) {
    return {};
  }
  final firestoreData = mapToFirestore(gameItem.toMap());

  // Handle nested data for "tier1_audit" field.
  addTier1AuditStructData(
    firestoreData,
    gameItem.hasTier1Audit() ? gameItem.tier1Audit : null,
    'tier1_audit',
    forFieldValue,
  );

  // Add any Firestore field values
  mapToFirestore(gameItem.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getGameItemListFirestoreData(
  List<GameItemStruct>? gameItems,
) =>
    gameItems?.map((e) => getGameItemFirestoreData(e, true)).toList() ?? [];
