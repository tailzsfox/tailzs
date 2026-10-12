import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'terminal_page_model.dart';
export 'terminal_page_model.dart';

class TerminalPageWidget extends StatefulWidget {
  const TerminalPageWidget({super.key});

  static String routeName = 'TerminalPage';
  static String routePath = '/terminalPage';

  @override
  State<TerminalPageWidget> createState() => _TerminalPageWidgetState();
}

class _TerminalPageWidgetState extends State<TerminalPageWidget> {
  late TerminalPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TerminalPageModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: custom_widgets.TailzsLoginScreen(
              width: double.infinity,
              height: double.infinity,
              targetPageName: 'Tailzs',
            ),
          ),
        ),
      ),
    );
  }
}
