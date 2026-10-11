import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'leg_box_model.dart';
export 'leg_box_model.dart';

class LegBoxWidget extends StatefulWidget {
  const LegBoxWidget({
    super.key,
    bool? isLocked,
    String? label,
    String? status,
  })  : this.isLocked = isLocked ?? false,
        this.label = label ?? '',
        this.status = status ?? 'WIN';

  final bool isLocked;
  final String label;
  final String status;

  @override
  State<LegBoxWidget> createState() => _LegBoxWidgetState();
}

class _LegBoxWidgetState extends State<LegBoxWidget> {
  late LegBoxModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LegBoxModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF12181C),
        borderRadius: BorderRadius.circular(16.0),
        shape: BoxShape.rectangle,
        border: Border.all(
          color: Color(0xFF2E3D45),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget!.label,
                maxLines: 1,
                style: FlutterFlowTheme.of(context).labelSmall.override(
                      font: GoogleFonts.inter(
                        fontWeight:
                            FlutterFlowTheme.of(context).labelSmall.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelSmall.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).secondaryText,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).labelSmall.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelSmall.fontStyle,
                      lineHeight: 1.4,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                constraints: BoxConstraints(
                  minWidth: 75.0,
                ),
                decoration: BoxDecoration(
                  color: valueOrDefault<Color>(
                    () {
                      if (valueOrDefault<String>(
                            widget!.status,
                            'WIN',
                          ) ==
                          'WIN') {
                        return Color(0xFF00E676);
                      } else if (valueOrDefault<String>(
                            widget!.status,
                            'WIN',
                          ) ==
                          'LOSS') {
                        return Color(0xFFFF3366);
                      } else {
                        return Color(0xFF24343B);
                      }
                    }(),
                    Color(0xFF00E676),
                  ),
                  borderRadius: BorderRadius.circular(9999.0),
                  shape: BoxShape.rectangle,
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(16.0, 4.0, 16.0, 4.0),
                  child: Container(
                    child: AutoSizeText(
                      valueOrDefault<String>(
                        widget!.status,
                        'WIN',
                      ),
                      minFontSize: 9.0,
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontStyle,
                            ),
                            color: valueOrDefault<Color>(
                              valueOrDefault<String>(
                                        widget!.status,
                                        'WIN',
                                      ) ==
                                      'PENDING'
                                  ? Color(0xFF8A99A6)
                                  : Color(0xFF12181C),
                              Color(0xFF12181C),
                            ),
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                            lineHeight: 1.4,
                          ),
                    ),
                  ),
                ),
              ),
            ].divide(SizedBox(height: 8.0)),
          ),
        ),
      ),
    );
  }
}
