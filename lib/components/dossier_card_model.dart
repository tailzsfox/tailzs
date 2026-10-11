import '/components/leg_box2_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'dossier_card_widget.dart' show DossierCardWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DossierCardModel extends FlutterFlowModel<DossierCardWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for LegBox.
  late LegBox2Model legBoxModel1;
  // Model for LegBox.
  late LegBox2Model legBoxModel2;
  // Model for LegBox.
  late LegBox2Model legBoxModel3;

  @override
  void initState(BuildContext context) {
    legBoxModel1 = createModel(context, () => LegBox2Model());
    legBoxModel2 = createModel(context, () => LegBox2Model());
    legBoxModel3 = createModel(context, () => LegBox2Model());
  }

  @override
  void dispose() {
    legBoxModel1.dispose();
    legBoxModel2.dispose();
    legBoxModel3.dispose();
  }
}
