import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/components/game_card_widget.dart';
import '/components/kpi_item_widget.dart';
import '/flutter_flow/flutter_flow_choice_chips.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import 'prototype_widget.dart' show PrototypeWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:text_search/text_search.dart';

class PrototypeModel extends FlutterFlowModel<PrototypeWidget> {
  ///  Local state fields for this page.

  String? selectedSport = 'NCAAF';

  String? selectedMode = 'EOW_AUDIT';

  String selectedTier = 'tier1_audit';

  String? activeDossierUrl;

  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  List<DossiersRecord> simpleSearchResults = [];
  // State field(s) for ChoiceChips widget.
  FormFieldController<List<String>>? choiceChipsValueController1;
  String? get choiceChipsValue1 =>
      choiceChipsValueController1?.value?.firstOrNull;
  set choiceChipsValue1(String? val) =>
      choiceChipsValueController1?.value = val != null ? [val] : [];
  // State field(s) for ChoiceChips widget.
  FormFieldController<List<String>>? choiceChipsValueController2;
  String? get choiceChipsValue2 =>
      choiceChipsValueController2?.value?.firstOrNull;
  set choiceChipsValue2(String? val) =>
      choiceChipsValueController2?.value = val != null ? [val] : [];
  // Model for KpiItem.
  late KpiItemModel kpiItemModel1;
  // Model for KpiItem.
  late KpiItemModel kpiItemModel2;
  // Model for KpiItem.
  late KpiItemModel kpiItemModel3;
  // Model for KpiItem.
  late KpiItemModel kpiItemModel4;

  @override
  void initState(BuildContext context) {
    kpiItemModel1 = createModel(context, () => KpiItemModel());
    kpiItemModel2 = createModel(context, () => KpiItemModel());
    kpiItemModel3 = createModel(context, () => KpiItemModel());
    kpiItemModel4 = createModel(context, () => KpiItemModel());
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();

    kpiItemModel1.dispose();
    kpiItemModel2.dispose();
    kpiItemModel3.dispose();
    kpiItemModel4.dispose();
  }
}
