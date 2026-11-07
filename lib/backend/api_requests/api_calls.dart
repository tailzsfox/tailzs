import 'dart:convert';
import 'dart:typed_data';
import '../schema/structs/index.dart';

import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

class TriggerNCAAFPipelineCall {
  static Future<ApiCallResponse> call({
    int? week = 10,
    String? tier = 'merge',
    String? mode = 'prospective',
  }) async {
    final ffApiRequestBody = '''
{
  "week": ${week},
  "tier": ${tier == null ? 'null' : '"${escapeStringForJson(tier)}"'},
  "mode": ${mode == null ? 'null' : '"${escapeStringForJson(mode)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Trigger NCAAF Pipeline',
      apiUrl:
          'https://tailzs-ncaaf-dispatcher-56267457175.us-central1.run.app/run-ncaaf',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class TriggerMLBPipelineCall {
  static Future<ApiCallResponse> call({
    String? mode = 'eod',
    String? tier = 'merge',
    String? date = '2026-10-28',
  }) async {
    final ffApiRequestBody = '''
{
  "mode": ${mode == null ? 'null' : '"${escapeStringForJson(mode)}"'},
  "tier": ${tier == null ? 'null' : '"${escapeStringForJson(tier)}"'},
  "date": ${date == null ? 'null' : '"${escapeStringForJson(date)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Trigger MLB Pipeline',
      apiUrl:
          'https://tailzs-sports-pipeline-56267457175.us-central1.run.app/run-mlb',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class NHLPipelineCall {
  static Future<ApiCallResponse> call({
    String? mode = 'eod',
    String? date = '2026-11-04',
  }) async {
    final ffApiRequestBody = '''
{
  "mode": ${mode == null ? 'null' : '"${escapeStringForJson(mode)}"'},
  "date": ${date == null ? 'null' : '"${escapeStringForJson(date)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'NHL Pipeline',
      apiUrl: 'https://tailzs-nhl-engine-56267457175.us-central1.run.app/run',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': 'tailzs-quant-secret',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class NFLPipelineCall {
  static Future<ApiCallResponse> call({
    String? mode = 'eow',
    int? week = 9,
    String? tier = 'master',
  }) async {
    final ffApiRequestBody = '''
{
  "mode": ${mode == null ? 'null' : '"${escapeStringForJson(mode)}"'},
  "week": ${week},
  "tier": ${tier == null ? 'null' : '"${escapeStringForJson(tier)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'NFL Pipeline',
      apiUrl:
          'https://tailzs-nfl-dispatcher-56267457175.us-central1.run.app/run',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': 'tailzs-quant-secret',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class NBAPipelineCall {
  static Future<ApiCallResponse> call({
    String? mode = 'eod',
    String? date = '2026-11-05',
    String? tier = 'master',
  }) async {
    final ffApiRequestBody = '''
{
  "mode": ${mode == null ? 'null' : '"${escapeStringForJson(mode)}"'},
  "date": ${date == null ? 'null' : '"${escapeStringForJson(date)}"'},
  "tier": ${tier == null ? 'null' : '"${escapeStringForJson(tier)}"'}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'NBA Pipeline',
      apiUrl:
          'https://tailzs-nba-dispatcher-56267457175.us-central1.run.app/run',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': 'tailzs-quant-secret',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  if (item is DocumentReference) {
    return item.path;
  }
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  final encoded = jsonEncode(input);
  return encoded.substring(1, encoded.length - 1);
}
