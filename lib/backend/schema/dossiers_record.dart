import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DossiersRecord extends FirestoreRecord {
  DossiersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "category" field.
  String? _category;
  String get category => _category ?? '';
  bool hasCategory() => _category != null;

  // "is_active" field.
  bool? _isActive;
  bool get isActive => _isActive ?? false;
  bool hasIsActive() => _isActive != null;

  // "pdf_filename" field.
  String? _pdfFilename;
  String get pdfFilename => _pdfFilename ?? '';
  bool hasPdfFilename() => _pdfFilename != null;

  // "pdf_url" field.
  String? _pdfUrl;
  String get pdfUrl => _pdfUrl ?? '';
  bool hasPdfUrl() => _pdfUrl != null;

  // "sport" field.
  String? _sport;
  String get sport => _sport ?? '';
  bool hasSport() => _sport != null;

  // "updated_at" field.
  DateTime? _updatedAt;
  DateTime? get updatedAt => _updatedAt;
  bool hasUpdatedAt() => _updatedAt != null;

  // "slate_metrics" field.
  SlateMetricsStruct? _slateMetrics;
  SlateMetricsStruct get slateMetrics => _slateMetrics ?? SlateMetricsStruct();
  bool hasSlateMetrics() => _slateMetrics != null;

  // "games" field.
  List<GameItemStruct>? _games;
  List<GameItemStruct> get games => _games ?? const [];
  bool hasGames() => _games != null;

  // "tier" field.
  String? _tier;
  String get tier => _tier ?? '';
  bool hasTier() => _tier != null;

  void _initializeFields() {
    _category = snapshotData['category'] as String?;
    _isActive = snapshotData['is_active'] as bool?;
    _pdfFilename = snapshotData['pdf_filename'] as String?;
    _pdfUrl = snapshotData['pdf_url'] as String?;
    _sport = snapshotData['sport'] as String?;
    _updatedAt = snapshotData['updated_at'] as DateTime?;
    _slateMetrics = snapshotData['slate_metrics'] is SlateMetricsStruct
        ? snapshotData['slate_metrics']
        : SlateMetricsStruct.maybeFromMap(snapshotData['slate_metrics']);
    _games = getStructList(
      snapshotData['games'],
      GameItemStruct.fromMap,
    );
    _tier = snapshotData['tier'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('dossiers');

  static Stream<DossiersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => DossiersRecord.fromSnapshot(s));

  static Future<DossiersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => DossiersRecord.fromSnapshot(s));

  static DossiersRecord fromSnapshot(DocumentSnapshot snapshot) =>
      DossiersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static DossiersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      DossiersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'DossiersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is DossiersRecord && reference.path == other.reference.path;
}

Map<String, dynamic> createDossiersRecordData({
  String? category,
  bool? isActive,
  String? pdfFilename,
  String? pdfUrl,
  String? sport,
  DateTime? updatedAt,
  SlateMetricsStruct? slateMetrics,
  String? tier,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'category': category,
      'is_active': isActive,
      'pdf_filename': pdfFilename,
      'pdf_url': pdfUrl,
      'sport': sport,
      'updated_at': updatedAt,
      'slate_metrics': SlateMetricsStruct().toMap(),
      'tier': tier,
    }.withoutNulls,
  );

  // Handle nested data for "slate_metrics" field.
  addSlateMetricsStructData(firestoreData, slateMetrics, 'slate_metrics');

  return firestoreData;
}

class DossiersRecordDocumentEquality implements Equality<DossiersRecord> {
  const DossiersRecordDocumentEquality();

  @override
  bool equals(DossiersRecord? e1, DossiersRecord? e2) {
    const listEquality = ListEquality();
    return e1?.category == e2?.category &&
        e1?.isActive == e2?.isActive &&
        e1?.pdfFilename == e2?.pdfFilename &&
        e1?.pdfUrl == e2?.pdfUrl &&
        e1?.sport == e2?.sport &&
        e1?.updatedAt == e2?.updatedAt &&
        e1?.slateMetrics == e2?.slateMetrics &&
        listEquality.equals(e1?.games, e2?.games) &&
        e1?.tier == e2?.tier;
  }

  @override
  int hash(DossiersRecord? e) => const ListEquality().hash([
        e?.category,
        e?.isActive,
        e?.pdfFilename,
        e?.pdfUrl,
        e?.sport,
        e?.updatedAt,
        e?.slateMetrics,
        const ListEquality().hash(e?.games),
        e?.tier
      ]);

  @override
  bool isValidKey(Object? o) => o is DossiersRecord;
}
