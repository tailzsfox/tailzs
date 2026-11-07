// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:ui';
import 'package:flutter/services.dart';

class TailzsNFL extends StatefulWidget {
  const TailzsNFL({
    Key? key,
    this.width,
    this.height,
    this.game,
    this.isSub,
    this.selectedMode,
    this.selectedTier,
    this.onUpgradeTapped,
  }) : super(key: key);

  final double? width;
  final double? height;
  final dynamic game;
  final bool? isSub;
  final String? selectedMode;
  final String? selectedTier;
  final Future Function()? onUpgradeTapped;

  @override
  State<TailzsNFL> createState() => _TailzsNFLState();
}

class _TailzsNFLState extends State<TailzsNFL> {
  bool _isDeepDiveOpen = false;
  bool _isPinned = false;

  /// Collapses spaced-out numbers, signs, and percentage kerning glitches
  String _tighten(dynamic raw) {
    if (raw == null) return '';
    String str = raw.toString();

    str = str.replaceAll(RegExp(r'[ \t]+'), ' ');

    for (int i = 0; i < 4; i++) {
      str = str.replaceAllMapped(
        RegExp(r'(?<=[0-9\+\-\.\%\$])\s+(?=[0-9\+\-\.\%\$])'),
        (m) => '',
      );
    }

    str = str.replaceAllMapped(
      RegExp(r'([\(\[])\s+([\+\-0-9])'),
      (m) => '${m.group(1)}${m.group(2)}',
    );
    str = str.replaceAllMapped(
      RegExp(r'([0-9\+\-\.\%])\s+([\)\],])'),
      (m) => '${m.group(1)}${m.group(2)}',
    );

    return str.trim();
  }

  Future<void> _triggerElectricHapticBuzz() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 60));
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.heavyImpact();
    } catch (_) {
      HapticFeedback.vibrate();
    }
  }

  Future<void> _triggerMechanicalLatchHaptic() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 60));
      await HapticFeedback.selectionClick();
    } catch (_) {
      HapticFeedback.lightImpact();
    }
  }

  String _getFlexibleDeep(
      Map rootMap, List<String> candidates, String fallback) {
    for (var cand in candidates) {
      final normalizedTarget =
          cand.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      if (normalizedTarget == 'mlprojectorwinner' ||
          normalizedTarget == 'tier2pick') {
        if (rootMap.containsKey('tier2_insignia') &&
            rootMap['tier2_insignia'] is List) {
          final List insigniaList = rootMap['tier2_insignia'] as List;
          if (insigniaList.isNotEmpty && insigniaList[0] is Map) {
            final Map firstItem = insigniaList[0] as Map;
            if (firstItem.containsKey('ml_projector_winner')) {
              String rawValue = firstItem['ml_projector_winner'].toString();
              if (rawValue.contains(':')) {
                rawValue = rawValue.split(':').last.trim();
              }
              if (rawValue.isNotEmpty) return rawValue;
            }
          }
        }
      }

      for (var entry in rootMap.entries) {
        final normalizedKey = entry.key
            .toString()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (normalizedKey == normalizedTarget ||
            (normalizedKey.contains(normalizedTarget) &&
                normalizedTarget.length >= 5)) {
          final val = entry.value?.toString().trim();
          if (val != null && val.isNotEmpty && val != 'null' && val != 'TBD') {
            return val;
          }
        }
      }
    }
    for (var entry in rootMap.entries) {
      if (entry.value is Map) {
        final childMap = Map.from(entry.value as Map);
        final res = _getFlexibleDeep(childMap, candidates, '');
        if (res.isNotEmpty) return res;
      }
    }
    return fallback;
  }

  String _generateReceiptText(
      Map game, String tier, int legCount, String outcomeStatus) {
    final buffer = StringBuffer();
    buffer.writeln('🦊 TAILZS QUANT VERIFIED RECEIPT');
    buffer.writeln('🏆 NFL ${tier.toUpperCase()}');

    final gameDate = (game['game_date'] ?? '').toString().trim();
    if (gameDate.isNotEmpty && gameDate != 'TBA') {
      buffer.writeln('📅 Game Date: $gameDate');
    }

    buffer.writeln('Matchup: ${_tighten(game['matchup'] ?? '')}');

    final score = _tighten(game['score'] ?? '');
    if (score.isNotEmpty) {
      buffer.writeln('Score: $score');
    }

    if (outcomeStatus.isNotEmpty) {
      buffer.writeln('📊 Outcome: ${_tighten(outcomeStatus)}');
    }
    buffer.writeln();

    for (int i = 1; i <= legCount; i++) {
      final label = game['l${i}_label']?.toString() ?? 'LEG $i';
      String pick = game['l${i}_pick']?.toString() ?? 'TBD';

      pick = pick
          .replaceAll(
              RegExp(r'OPTION\s*\d+\s*PICK:', caseSensitive: false), 'PICK:')
          .trim();

      final status = game['l${i}_status']?.toString().toUpperCase() ?? '';
      buffer.writeln('• $label: ${_tighten(pick)} [${_tighten(status)}]');
    }

    buffer.writeln();
    buffer.writeln('Quant Edge Tracked Live on Tailzs Terminal 🗞');
    buffer.writeln('tailzs.app');
    return buffer.toString().trim();
  }

  void _showShareReceiptModal(
      BuildContext context, Map game, String outcomeStatus) {
    HapticFeedback.mediumImpact();
    final String tier = widget.selectedTier ?? 'TIER 1 PARLAY';
    final int legCount = (game['legCount'] as int?) ?? 1;
    final String receiptText =
        _generateReceiptText(game, tier, legCount, outcomeStatus);

    final String gameDate = (game['game_date'] ?? '').toString().trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF182226),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Text('📥 ', style: TextStyle(fontSize: 16)),
                        Text(
                          'SHARE VERIFIED RECEIPT',
                          style: TextStyle(
                            color: Color(0xFF00F5D4),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Color(0xFF8A99A6), size: 18),
                      onPressed: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1114),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: const Color(0xFFFF5E00), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5E00).withOpacity(0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text('🦊 ', style: TextStyle(fontSize: 14)),
                          Text(
                            'TAILZS QUANT VERIFIED RECEIPT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('🏆 ', style: TextStyle(fontSize: 13)),
                          Text(
                            'NFL ${tier.toUpperCase()}',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      if (gameDate.isNotEmpty && gameDate != 'TBA') ...[
                        const SizedBox(height: 6),
                        Text(
                          '📅 Game Date: $gameDate',
                          style: const TextStyle(
                            color: Color(0xFF8A99A6),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Matchup: ${_tighten(game['matchup'] ?? '')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      if ((game['score'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Score: ${_tighten(game['score'])}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                      if (outcomeStatus.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Text('📊 Outcome: ',
                                style: TextStyle(
                                  color: Color(0xFF8A99A6),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                  decoration: TextDecoration.none,
                                )),
                            Text(
                              _tighten(outcomeStatus),
                              style: TextStyle(
                                color: outcomeStatus.contains('WIN') ||
                                        outcomeStatus.contains('SWEEP HIT')
                                    ? const Color(0xFFFF7700)
                                    : (outcomeStatus.contains('SPLIT')
                                        ? const Color(0xFFF8EDD8)
                                        : const Color(0xFF00E5FF)),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: Color(0xFF24343B), height: 1),
                      ),
                      ...List.generate(legCount, (i) {
                        final legNum = i + 1;
                        final label = game['l${legNum}_label']?.toString() ??
                            'LEG $legNum';
                        String pick =
                            game['l${legNum}_pick']?.toString() ?? 'TBD';
                        pick = pick
                            .replaceAll(
                                RegExp(r'OPTION\s*\d+\s*PICK:',
                                    caseSensitive: false),
                                'PICK:')
                            .trim();

                        final status = game['l${legNum}_status']
                                ?.toString()
                                .toUpperCase() ??
                            '';
                        final bool isWin = status.contains('WIN');

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '• $label: ',
                                  style: const TextStyle(
                                    color: Color(0xFF8A99A6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                TextSpan(
                                  text: '${_tighten(pick)} ',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                TextSpan(
                                  text: '[${_tighten(status)}]',
                                  style: TextStyle(
                                    color: isWin
                                        ? const Color(0xFF00E676)
                                        : const Color(0xFFFF3366),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: Color(0xFF24343B), height: 1),
                      ),
                      const Text(
                        'Quant Edge Tracked Live on Tailzs Terminal 🗞',
                        style: TextStyle(
                          color: Color(0xFF8A99A6),
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.2,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'tailzs.app',
                        style: TextStyle(
                          color: Color(0xFF00F5D4),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: receiptText));
                    await HapticFeedback.heavyImpact();
                    if (context.mounted) {
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('✓ Verified receipt copied to clipboard!'),
                          backgroundColor: Color(0xFF00F5D4),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.content_copy,
                      color: Colors.white, size: 16),
                  label: const Text(
                    'TAP TO COPY FOR POSTING RESULTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5E00),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg = const Color(0xFF24343B);
    Color text = const Color(0xFF8A99A6);
    final clean = status.toUpperCase().trim();

    if (clean.contains('WIN') ||
        clean.contains('HIT') ||
        clean.contains('🟢')) {
      bg = const Color(0xFF00E676);
      text = const Color(0xFF0B1114);
    } else if (clean.contains('LOSS') ||
        clean.contains('MISS') ||
        clean.contains('🔴')) {
      bg = const Color(0xFFFF3366);
      text = Colors.white;
    } else if (clean.contains('SKIP') ||
        clean.contains('DEAD') ||
        clean.contains('PUSH') ||
        clean.contains('⏸️')) {
      bg = const Color(0xFFF5E5C9);
      text = const Color(0xFF0B1114);
    }

    String displayLabel = clean;
    if (clean.contains('PENDING') || clean.contains('⏳')) {
      displayLabel = '⏳ PENDING';
    } else if (clean.contains('WIN') || clean.contains('🟢')) {
      displayLabel = 'WIN';
    } else if (clean.contains('LOSS') || clean.contains('🔴')) {
      displayLabel = 'LOSS';
    } else if (clean.contains('PUSH') || clean.contains('⏸️')) {
      displayLabel = '⏸️ PUSH';
    } else if (clean.contains('SKIP') || clean.contains('DEAD')) {
      displayLabel = '⏸️ SKIP';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        displayLabel,
        style: TextStyle(
          color: text,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildDiveBox(String label, String value) {
    final cleanVal = _tighten(value);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: const Color(0xFF0B1114),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF24343B))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF00F5D4),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cleanVal,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.4,
              letterSpacing: 0.2,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  // NFL Dynamic Deep Dive Diagnostic Engine
  Widget _buildDeepDiveSection(Map game) {
    final diveBoxes = [];
    final raw = (game['_raw'] != null && game['_raw'] is Map)
        ? Map.from(game['_raw'] as Map)
        : game;
    final String awayName = game['away_name']?.toString() ?? 'Away';
    final String homeName = game['home_name']?.toString() ?? 'Home';
    final String tier = widget.selectedTier ?? 'TIER 1 PARLAY';

    void addBox(String title, String value) {
      diveBoxes.add({'title': title, 'value': value});
    }

    if (tier.contains('TIER 1')) {
      final String masterPick = _getFlexibleDeep(
          raw,
          ['tripartite_master_pick', 'leg_3_pick', 'ml_pick'],
          'MAJORITY LEAN: $homeName');
      final String grade = _getFlexibleDeep(
          raw, ['tripartite_parlay_grade', 'grade'], 'GOLDEN PARLAY');
      addBox('TRIPARTITE MASTER PICK & PARLAY RADAR',
          'Master Pick: $masterPick\nGrade: $grade');

      final String f7Detail = _getFlexibleDeep(
          raw,
          ['f7_edge_detail', 'first_7_edge'],
          'Opening Script Z-Score Execution: $awayName');
      addBox('FIRST 7 EDGE DETAIL & OPENING SCRIPT', f7Detail);

      final String h1Detail = _getFlexibleDeep(
          raw,
          ['1h_edge_detail', '1h_edge'],
          'Red Zone Containment Edge: $homeName');
      addBox('1H ML EDGE & ADVANTAGE RATIONALE', h1Detail);

      final String mlDetail = _getFlexibleDeep(raw,
          ['ml_value_detail', 'risk_flag'], 'Net Advantage Disparity Positive');
      addBox('FULL GAME ML VALUE & RISK FLAG', mlDetail);
    } else if (tier.contains('TIER 2')) {
      final String topoWinner = _getFlexibleDeep(
          raw, ['topography_winner', 'topography_ml_pick'], homeName);
      final String edge =
          _getFlexibleDeep(raw, ['topography_edge'], 'LEAN (+1.8 Z)');
      addBox('CHAMBER TOPOGRAPHY ML & NET DISPARITY',
          'Topography ML: $topoWinner\nEdge: $edge');

      final String crown = _getFlexibleDeep(
          raw,
          ['master_prevailing_crown', 'prevailing_crown'],
          '👑 IMPERIAL OVERMATCH');
      final String clash = _getFlexibleDeep(
          raw, ['hybrid_clash_result_explicit_inputs'], 'TRENCH COLLISION');
      addBox('INSIGNIA SECTOR PROFILES & PREVAILING CROWN',
          'Crown: $crown\nClash: $clash');

      final String winProb = _getFlexibleDeep(
          raw,
          ['kinetic_win_probability_away__home', 'kinetic_win_probability'],
          '50.0% | 50.0%');
      final String script = _getFlexibleDeep(
          raw, ['actionable_game_script'], 'Balanced Rushing & Play-Action');
      addBox('KINETIC WIN PROBABILITY & GAME SCRIPT',
          'Win Prob: 📈 $winProb\nScript: $script');

      final String vectors = _getFlexibleDeep(
          raw,
          ['trajectory_acceleration_vectors', 'trajectory_vectors'],
          '$awayName: 🧊 SLUMPING | $homeName: 🔥 SURGING');
      addBox('TRAJECTORY ACCELERATION VECTORS', vectors);
    } else {
      // TIER 3 - DRAFTKINGS SPREAD COVER
      final String spreadPick = _getFlexibleDeep(
          raw,
          [
            'model_spread_cover_verdict_side_edge',
            'model_spread_cover_verdict'
          ],
          'LEAN COVER: $homeName');
      final String dkLine = _getFlexibleDeep(
          raw, ['draftkings_market_line', 'point_spread_line'], 'N/A');
      addBox('DRAFTKINGS SPREAD & MODEL DIRECTIVE',
          'Model Spread Pick: $spreadPick\nDraftKings Line: $dkLine');

      final String trench = _getFlexibleDeep(
          raw,
          ['trench_disruption__protection_status', 'trench_profile'],
          'IMPENETRABLE O-LINE PROTECTION');
      final String netAdv =
          _getFlexibleDeep(raw, ['net_trench_advantage_val'], '+0.88 Ssn Net');
      addBox('TRENCH, O-LINE & NET ADVANTAGE PROFILES',
          'Trench Profile: $trench\nNet Disparity: $netAdv');

      final String awayQb = _getFlexibleDeep(
          raw, ['away_qb_contain'], 'Standard Pocket Mobility');
      final String homeQb = _getFlexibleDeep(
          raw, ['home_qb_contain'], 'Dual-Threat Mobility Advantage');
      addBox('STARTING QB PROFILE & CONTAINMENT SCRIPT',
          '$awayName QB: $awayQb\n$homeName QB: $homeQb');

      final String directive = _getFlexibleDeep(
          raw,
          ['ecosystem_edge__value_trap_directive', 'ecosystem_edge_directive'],
          'STABLE ECOSYSTEM: Line aligned with power rating');
      addBox(
          'SECTORS & VALUE TRAP DIRECTIVE', 'Ecosystem Directive: $directive');
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: diveBoxes
            .map((box) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: _buildDiveBox((box['title'] ?? '').toString(),
                    (box['value'] ?? '').toString())))
            .toList(),
      ),
    );
  }

  Widget _buildLegsGrid(Map game, int legCount, bool subActive, bool isMixMatch,
      String activeMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(legCount, (i) {
        final int legNum = i + 1;
        final String rawMargin = (game['l${legNum}_margin'] ?? '').toString();
        final String cleanMargin = _tighten(rawMargin);

        final String statusStr =
            game['l${legNum}_status']?.toString().toUpperCase() ?? 'PENDING';

        // NFL specific leg labels: FIRST 7, 1H ML, FULL ML, or SPREAD COVER for Tier 3
        final String rawLabel = game['l${legNum}_label']?.toString() ??
            (widget.selectedTier == 'TIER 3 SIDE'
                ? 'SPREAD COVER'
                : (widget.selectedTier == 'TIER 2 ML'
                    ? (legNum == 1 ? 'TOPOGRAPHY ML' : 'INSIGNIA SYNERGY')
                    : (legNum == 1
                        ? 'FIRST 7'
                        : (legNum == 2 ? '1H ML' : 'FULL ML'))));
        final String cleanLabel = _tighten(rawLabel);

        final String rawPick = game['l${legNum}_pick']?.toString() ?? 'TBD';
        final String cleanPick = _tighten(rawPick);

        Color legBorderColor = const Color(0xFF24343B);
        Color legTitleColor = const Color(0xFF00F5D4);

        if (activeMode == 'AUDIT') {
          if (statusStr.contains('WIN')) {
            legBorderColor = const Color(0xFF00E676).withOpacity(0.8);
            legTitleColor = const Color(0xFF00E676);
          } else if (statusStr.contains('LOSS')) {
            legBorderColor = const Color(0xFFFF3366).withOpacity(0.8);
            legTitleColor = const Color(0xFFFF3366);
          } else if (statusStr.contains('PUSH') || statusStr.contains('SKIP')) {
            legBorderColor = const Color(0xFFF5E5C9).withOpacity(0.8);
            legTitleColor = const Color(0xFFF5E5C9);
          }
        } else {
          if (isMixMatch) {
            legBorderColor = const Color(0xFF00FF66).withOpacity(0.8);
            legTitleColor = const Color(0xFF00FF66);
          }
        }

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < legCount - 1 ? 6 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
                color: const Color(0xFF0B1114),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: legBorderColor)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cleanLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: legTitleColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      decoration: TextDecoration.none,
                    )),
                const SizedBox(height: 4),
                Text(cleanPick,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                      letterSpacing: 0.2,
                      decoration: TextDecoration.none,
                    )),
                const SizedBox(height: 6),
                _buildStatusPill(statusStr),
                if (cleanMargin.isNotEmpty && cleanMargin != 'null') ...[
                  const SizedBox(height: 6),
                  Text('Margin: $cleanMargin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8A99A6),
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                        decoration: TextDecoration.none,
                      )),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.game == null || widget.game is! Map) {
      return Container(
        width: widget.width,
        padding: const EdgeInsets.all(16),
        child: const Text('NFL Matchup data unavailable.',
            style: TextStyle(color: Color(0xFF8A99A6), fontSize: 11)),
      );
    }

    final Map game = Map.from(widget.game as Map);
    final mode = widget.selectedMode ?? 'PROSPECTIVE';
    final int legCount = (game['legCount'] as int?) ??
        (widget.selectedTier == 'TIER 2 ML'
            ? 2
            : (widget.selectedTier == 'TIER 3 SIDE' ? 1 : 3));
    final bool subActive = widget.isSub ?? false;
    final bool isMixMatch = (game['isMixMatch'] as bool?) ?? false;
    final String gameDate = (game['game_date'] ?? '').toString().trim();

    final String cleanMatchup = _tighten(
        (game['matchup']?.toString() ?? 'Matchup TBD')
            .replaceAll(RegExp(r'\s+'), ' '));

    int winCount = 0;
    int lossCount = 0;

    for (int i = 1; i <= legCount; i++) {
      final String legStatus =
          game['l${i}_status']?.toString().toUpperCase() ?? '';
      if (legStatus.contains('WIN') || legStatus.contains('HIT')) {
        winCount++;
      } else if (legStatus.contains('LOSS') || legStatus.contains('MISS')) {
        lossCount++;
      }
    }

    String badgeType = game['badgeType']?.toString() ?? 'PENDING';

    if (mode == 'AUDIT') {
      if (winCount > 0 && lossCount > 0) {
        badgeType = 'SPLIT_DECISION';
      } else if (lossCount == legCount && legCount > 0) {
        badgeType = 'SWEEP_LOSS';
      } else if (winCount == legCount && legCount > 0) {
        badgeType = 'SWEEP_HIT';
      }
    }

    Color borderColor = const Color(0xFF24343B);
    Color badgeBg = const Color(0xFF24343B);
    Color badgeText = const Color(0xFF8A99A6);
    String badgeTitle = '🎯 PROSPECTIVE SIGNAL';

    if (mode == 'AUDIT') {
      if (badgeType == 'PENDING') {
        badgeTitle = '⏳ PENDING';
      } else if (badgeType == 'SWEEP_HIT') {
        borderColor = const Color(0xFFFF5E00);
        badgeBg = const Color(0xFFFF5E00).withOpacity(0.2);
        badgeText = const Color(0xFFFF7700);
        badgeTitle = legCount == 3
            ? '🔥 3-LEG SWEEP HIT'
            : (legCount == 2 ? '🔥 DUAL WIN' : '🔥 COVER WIN');
      } else if (badgeType == 'SPLIT_DECISION') {
        borderColor = const Color(0xFFF5E5C9);
        badgeBg = const Color(0xFFF5E5C9).withOpacity(0.2);
        badgeText = const Color(0xFFF8EDD8);
        badgeTitle = '🦊 SPLIT DECISION';
      } else if (badgeType == 'SWEEP_LOSS') {
        borderColor = const Color(0xFF00E5FF);
        badgeBg = const Color(0xFF00E5FF).withOpacity(0.2);
        badgeText = const Color(0xFF00E5FF);
        badgeTitle = legCount == 3
            ? '❄️ 0-3 SWEEP LOSS'
            : (legCount == 2 ? '❄️ DUAL LOSS' : '❄️ COVER LOSS');
      }
    } else {
      borderColor =
          isMixMatch ? const Color(0xFF00FF66) : const Color(0xFF00F5D4);
      badgeBg = isMixMatch
          ? const Color(0xFF00FF66).withOpacity(0.18)
          : const Color(0xFF00F5D4).withOpacity(0.15);
      badgeText =
          isMixMatch ? const Color(0xFF00FF66) : const Color(0xFF00F5D4);
      badgeTitle = isMixMatch
          ? '⚡ HIGH ODDS POTENTIAL MIX-MATCH PARLAY'
          : '🎯 PROSPECTIVE SIGNAL';
    }

    Widget gridRow =
        _buildLegsGrid(game, legCount, subActive, isMixMatch, mode);

    if (mode == 'PROSPECTIVE' && !subActive) {
      gridRow = Stack(
        alignment: Alignment.center,
        children: [
          ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: gridRow),
          ElevatedButton.icon(
            onPressed: () async {
              await _triggerElectricHapticBuzz();
              widget.onUpgradeTapped?.call();
            },
            icon: const Icon(Icons.lock, color: Colors.white, size: 13),
            label: const Text('UNLOCK ALL ACCESS • ALL PICKS (\$9.99/MO)',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    decoration: TextDecoration.none)),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5E00),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
          ),
        ],
      );
    }

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF182226),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: borderColor,
            width: isMixMatch && mode == 'PROSPECTIVE' ? 2.5 : 2),
        boxShadow: [
          BoxShadow(
              color: borderColor.withOpacity(
                  (isMixMatch && mode == 'PROSPECTIVE') ? 0.35 : 0.25),
              blurRadius: (isMixMatch && mode == 'PROSPECTIVE') ? 18 : 14,
              spreadRadius: 1)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isPinned = !_isPinned);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Icon(_isPinned ? Icons.star : Icons.star_border,
                      color: _isPinned
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF8A99A6),
                      size: 16),
                ),
              ),
              Text((subActive || mode == 'AUDIT') ? '🦊 ' : '🔒 ',
                  style: const TextStyle(
                      fontSize: 15,
                      height: 1.0,
                      decoration: TextDecoration.none)),
              Expanded(
                child: Text(cleanMatchup,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: 0.2,
                      decoration: TextDecoration.none,
                    )),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  if (subActive) {
                    await _triggerMechanicalLatchHaptic();
                    setState(() => _isDeepDiveOpen = !_isDeepDiveOpen);
                  } else {
                    await _triggerElectricHapticBuzz();
                    widget.onUpgradeTapped?.call();
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: subActive
                        ? const Color(0xFF0B1114)
                        : const Color(0xFF24343B),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: subActive
                            ? const Color(0xFF00F5D4)
                            : const Color(0xFFFF5E00)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!subActive) ...[
                        const Icon(Icons.lock,
                            size: 10, color: Color(0xFFFF5E00)),
                        const SizedBox(width: 4)
                      ],
                      Text('DEEP DIVE',
                          style: TextStyle(
                              color: subActive
                                  ? const Color(0xFF00F5D4)
                                  : Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              decoration: TextDecoration.none)),
                      if (subActive) ...[
                        const SizedBox(width: 4),
                        Icon(
                            _isDeepDiveOpen
                                ? Icons.keyboard_arrow_down
                                : Icons.arrow_forward_rounded,
                            color: const Color(0xFF00F5D4),
                            size: 11)
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Status Badge on left + Date & Score on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: borderColor)),
                  child: Text(badgeTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: badgeText,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        decoration: TextDecoration.none,
                      )),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (gameDate.isNotEmpty && gameDate != 'TBA') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                          color: const Color(0xFF0B1114),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: const Color(0xFF24343B))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Color(0xFF8A99A6), size: 9),
                          const SizedBox(width: 4),
                          Text(gameDate,
                              maxLines: 1,
                              style: const TextStyle(
                                  color: Color(0xFF8A99A6),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                  decoration: TextDecoration.none)),
                        ],
                      ),
                    ),
                    if (mode == 'AUDIT' &&
                        (game['score'] ?? '').toString().isNotEmpty)
                      const SizedBox(width: 5),
                  ],
                  if (mode == 'AUDIT' &&
                      (game['score'] ?? '').toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                          color: const Color(0xFF0B1114),
                          borderRadius: BorderRadius.circular(5),
                          border:
                              Border.all(color: borderColor.withOpacity(0.6))),
                      child: Text(_tighten(game['score']?.toString() ?? ''),
                          maxLines: 1,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                              decoration: TextDecoration.none)),
                    ),
                ],
              ),
            ],
          ),

          if (mode == 'AUDIT') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified,
                          color: Color(0xFF00F5D4), size: 13),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'VERIFIED NFL AUDIT RECEIPT',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF00F5D4),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () =>
                      _showShareReceiptModal(context, game, badgeTitle),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: const Color(0xFFFF5E00), width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.share, color: Color(0xFFFF5E00), size: 11),
                        SizedBox(width: 4),
                        Text(
                          'SHARE RECEIPT',
                          style: TextStyle(
                            color: Color(0xFFFF5E00),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),
          gridRow,
          if (subActive && _isDeepDiveOpen) _buildDeepDiveSection(game),
        ],
      ),
    );
  }
}
