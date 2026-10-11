import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'tailzs_model.dart';
export 'tailzs_model.dart';

/// Build a high-performance, dark-themed sports quant terminal Page connected
/// to a Firestore database.
///
/// ### 1. THEME & COLORS
/// - Page Background: Solid #080C0E
/// - Elevated Cards/Containers Background: #182226
/// - Inner Leg Boxes/Search Background: #0B1114
/// - Primary Accent (Flame Orange): #FF5E00
/// - Secondary Accent (Neon Teal): #00F5D4
/// - Split Decision Accent (Cream): #F5E5C9
/// - Cold Loss Accent (Ice Blue): #00E5FF
/// - Muted Borders/Text: #24343B / #8A99A6
///
/// ### 2. PAGE STATE VARIABLES (Local State)
/// - selectedSport (String, default: "NCAAF")
/// - selectedMode (String, default: "PROSPECTIVE")
/// - selectedTier (String, default: "TIER 1 PARLAY")
///
/// ### 3. TOP COMMAND HEADER
/// Create a Column inside a Container (#182226 bg, #24343B border, 18px
/// border radius).
/// - Row 1 (Brand & Search): Image asset (appleicon.png), RichText ("TAIL" in
/// #FF5E00, "ZS" in #00F5D4), and a TextField for search (bg #0B1114).
/// - Row 2 (Mode Toggle): Two Expanded Containers acting as custom buttons
/// for "PROSPECTIVE" and "AUDIT". Highlight the active one with #FF5E00 based
/// on selectedMode.
///   * Logic: If AUDIT is selected and selectedSport == 'MLB', query
/// 'EOD_AUDIT'. If AUDIT is selected and selectedSport == 'NCAAF', query
/// 'EOW_AUDIT'.
/// - Row 3 (Sports Chips): Horizontally scrolling Row of Containers for
/// 'MLB', 'NCAAF', 'NFL', 'NBA', 'NHL', 'NCAAM', 'UFC'. Highlight the active
/// one with #00F5D4 based on selectedSport.
/// - Row 4 (Tier Chips): Row of 3 Expanded Containers for 'TIER 1 PARLAY',
/// 'TIER 2 ML', 'TIER 3 SIDE'. Highlight the active one with #F5E5C9 based on
/// selectedTier.
///
/// ### 4. KPI BANNER & DOSSIER BUTTON
/// - KPI Row: A Container (#182226 bg, #F5E5C9 border) with 4 evenly spaced
/// Columns. Each column has a large white text value and a small #00F5D4
/// label: "114 EVAL", "23 SWEEPS", "100% WIN %", "112 PENDING".
/// - Dossier Button: A full-width ElevatedButton (bg color #D4AF37). Use
/// Conditional logic for the text: If Authenticated User 'isSub' == true,
/// text is "📄 DOSSIER VAULT 🗞". If 'isSub' == false, text is "🔒 UNLOCK
/// DOSSIER ($9.99/MO)".
///
/// ### 5. DYNAMIC GAME CARDS (ListView & Component)
/// Add a ListView bound to a Backend Query of the 'dossiers' collection.
/// Generate the items inside the ListView as a reusable Component with a
/// Component State boolean named 'showDeepDive' (default: false).
/// Card Container styling: #182226 bg, 16px radius.
/// - Conditional Border Color: If 'sweep_status' contains 'WIN', border is
/// #FF5E00. If 'SPLIT', border is #F5E5C9. If 'LOSS', border is #00E5FF.
///
/// Inside the Card Component:
/// - Row 1 (Header): Add a Conditional Builder. If 'isSub' == true, show Text
/// "🦊 ". If 'isSub' == false, show Text "🔒 ". Follow with 'game_matchup'.
/// - Far Right of Row 1 (Deep Dive Button): Add a Conditional Builder. If
/// 'isSub' == true, show a button "DEEP DIVE ➔" that toggles the Component
/// State 'showDeepDive'. If 'isSub' == false, show a button "🔒 DEEP DIVE"
/// that triggers a bottom sheet paywall.
/// - Row 2 (Badges): Left badge shows Sweep Status text. Right badge shows
/// 'final_score'.
///
/// ### 6. DYNAMIC LEGS GRID & PAYWALL
/// Inside the Card Component, add a Stack.
/// Inside the Stack, add a Row with 3 Expanded Columns (Leg Boxes).
/// - Leg Box Container: #0B1114 bg, #24343B border, 10px radius.
/// - Leg Box Contents: Text (Label, #00F5D4), Text (Pick, White), Container
/// Pill (Status).
/// - Conditional Visibility for the Columns:
///   - Column 1: Always visible. Label Text Logic: If selectedSport == 'MLB',
/// text is 'YRFI'. If 'NCAAF', text is 'FIRST 7'.
///   - Column 2: Visible only if selectedTier == "TIER 1 PARLAY" OR "TIER 2
/// ML". Label Text Logic: If 'MLB', text is 'F5'. If 'NCAAF', text is '1H'.
///   - Column 3: Visible only if selectedTier == "TIER 1 PARLAY". Label text
/// is 'ML'.
/// - Status Pill Color Logic: If status == 'WIN', bg is #00E676. If 'LOSS',
/// bg is #FF3366.
///
/// Paywall Overlay (Top layer of the Stack):
/// - Add a ClipRect with a BackdropFilter (blur sigma 5.0) covering the Leg
/// Boxes.
/// - Add an ElevatedButton reading "🔒 UNLOCK ALL ACCESS ($9.99/MO)".
/// - Set Conditional Visibility on this blur/button layer to: Authenticated
/// User 'isSub' == false.
///
/// ### 7. MATCHUP QUANT DEEP DIVE (Expandable Section)
/// Below the Leg Box Stack inside the Card Component, add a Column for the
/// Deep Dive data.
/// - Set Conditional Visibility on this entire Column to show only when
/// Component State 'showDeepDive' == true AND 'isSub' == true.
/// - Add 4 text box Containers (#0B1114 bg, #24343B border, 8px padding, 8px
/// radius) arranged vertically.
/// - Map the Text inside these containers to the Firestore fields:
/// '4emoji_clash_equation', 'master_prevailing_crown',
/// 'actionable_game_script', and 'edge_confidence'.
/// - Use #00F5D4 for field labels and White for the dynamic field values.
class TailzsWidget extends StatefulWidget {
  const TailzsWidget({super.key});

  static String routeName = 'Tailzs';
  static String routePath = '/tailzs';

  @override
  State<TailzsWidget> createState() => _TailzsWidgetState();
}

class _TailzsWidgetState extends State<TailzsWidget> {
  late TailzsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TailzsModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DossiersRecord>>(
      stream: queryDossiersRecord(),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: Color(0xFF080C0E),
            body: Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
              ),
            ),
          );
        }
        List<DossiersRecord> tailzsDossiersRecordList = snapshot.data!;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: Color(0xFF080C0E),
            body: Container(
              width: double.infinity,
              height: double.infinity,
              child: custom_widgets.TailzsQuantTerminal(
                width: double.infinity,
                height: double.infinity,
                isSub: true,
                dossierDocs: tailzsDossiersRecordList,
              ),
            ),
          ),
        );
      },
    );
  }
}
