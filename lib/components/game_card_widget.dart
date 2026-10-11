import '/components/leg_box_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'game_card_model.dart';
export 'game_card_model.dart';

class GameCardWidget extends StatefulWidget {
  const GameCardWidget({
    super.key,
    bool? isSub,
    String? matchup,
    String? time,
    String? statusType,
    String? l1,
    String? l2,
    String? l3,
    this.finalScore,
    required this.gameItem,
    this.legs,
  })  : this.isSub = isSub ?? true,
        this.matchup = matchup ?? 'Western Kentucky @ New Mexico St',
        this.time = time ?? 'FINAL',
        this.statusType = statusType ?? 'SWEEP',
        this.l1 = l1 ?? 'FIRST 7',
        this.l2 = l2 ?? '1H ML',
        this.l3 = l3 ?? 'FULL ML';

  final bool isSub;
  final String matchup;
  final String time;
  final String statusType;
  final String l1;
  final String l2;
  final String l3;
  final String? finalScore;
  final dynamic gameItem;
  final List<dynamic>? legs;

  @override
  State<GameCardWidget> createState() => _GameCardWidgetState();
}

class _GameCardWidgetState extends State<GameCardWidget> {
  late GameCardModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GameCardModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF182226),
        borderRadius: BorderRadius.circular(24.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: EdgeInsets.all(24.0),
            child: Container(
              child: Builder(
                builder: (context) {
                  final legItem = widget!.legs?.toList() ?? [];

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(legItem.length, (legItemIndex) {
                      final legItemItem = legItem[legItemIndex];
                      return Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 18.0,
                                height: 18.0,
                                child: Stack(
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  children: [
                                    if (valueOrDefault<bool>(
                                      valueOrDefault<bool>(
                                        widget!.isSub,
                                        true,
                                      )
                                          ? false
                                          : true,
                                      false,
                                    ))
                                      Icon(
                                        Icons.lock_rounded,
                                        color: valueOrDefault<Color>(
                                          valueOrDefault<bool>(
                                            widget!.isSub,
                                            true,
                                          )
                                              ? Color(0xFFFF5E00)
                                              : FlutterFlowTheme.of(context)
                                                  .secondaryText,
                                          Color(0xFFFF5E00),
                                        ),
                                        size: 18.0,
                                      ),
                                    Align(
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Text(
                                        widget!.isSub == false ? '🔒' : '🦊',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.inter(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                valueOrDefault<String>(
                                  widget!.matchup,
                                  'Western Kentucky @ New Mexico St',
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .override(
                                      font: GoogleFonts.interTight(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontStyle,
                                      ),
                                      color: Color(0xFFF5E5C9),
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                              ),
                            ].divide(SizedBox(width: 8.0)),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF24343B),
                              borderRadius: BorderRadius.circular(8.0),
                              shape: BoxShape.rectangle,
                            ),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  8.0, 4.0, 8.0, 4.0),
                              child: Container(
                                child: Text(
                                  valueOrDefault<String>(
                                    widget!.time,
                                    'FINAL',
                                  ),
                                  style: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .override(
                                        font: GoogleFonts.inter(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelSmall
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF8A99A6),
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .fontStyle,
                                        lineHeight: 1.4,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).divide(SizedBox(height: 16.0)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
