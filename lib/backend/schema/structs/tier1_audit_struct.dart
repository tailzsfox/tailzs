// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class Tier1AuditStruct extends FFFirebaseStruct {
  Tier1AuditStruct({
    String? fgScore,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _fgScore = fgScore,
        super(firestoreUtilData);

  // "fg_score" field.
  String? _fgScore;
  String get fgScore => _fgScore ?? '';
  set fgScore(String? val) => _fgScore = val;

  bool hasFgScore() => _fgScore != null;

  static Tier1AuditStruct fromMap(Map<String, dynamic> data) =>
      Tier1AuditStruct(
        fgScore: data['fg_score'] as String?,
      );

  static Tier1AuditStruct? maybeFromMap(dynamic data) => data is Map
      ? Tier1AuditStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'fg_score': _fgScore,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'fg_score': serializeParam(
          _fgScore,
          ParamType.String,
        ),
      }.withoutNulls;

  static Tier1AuditStruct fromSerializableMap(Map<String, dynamic> data) =>
      Tier1AuditStruct(
        fgScore: deserializeParam(
          data['fg_score'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'Tier1AuditStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is Tier1AuditStruct && fgScore == other.fgScore;
  }

  @override
  int get hashCode => const ListEquality().hash([fgScore]);
}

Tier1AuditStruct createTier1AuditStruct({
  String? fgScore,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    Tier1AuditStruct(
      fgScore: fgScore,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

Tier1AuditStruct? updateTier1AuditStruct(
  Tier1AuditStruct? tier1Audit, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    tier1Audit
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addTier1AuditStructData(
  Map<String, dynamic> firestoreData,
  Tier1AuditStruct? tier1Audit,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (tier1Audit == null) {
    return;
  }
  if (tier1Audit.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && tier1Audit.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final tier1AuditData = getTier1AuditFirestoreData(tier1Audit, forFieldValue);
  final nestedData = tier1AuditData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = tier1Audit.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getTier1AuditFirestoreData(
  Tier1AuditStruct? tier1Audit, [
  bool forFieldValue = false,
]) {
  if (tier1Audit == null) {
    return {};
  }
  final firestoreData = mapToFirestore(tier1Audit.toMap());

  // Add any Firestore field values
  mapToFirestore(tier1Audit.firestoreUtilData.fieldValues)
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getTier1AuditListFirestoreData(
  List<Tier1AuditStruct>? tier1Audits,
) =>
    tier1Audits?.map((e) => getTier1AuditFirestoreData(e, true)).toList() ?? [];
