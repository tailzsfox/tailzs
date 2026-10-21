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

import '/custom_code/widgets/index.dart';

import 'dart:ui';
import 'package:flutter/services.dart';

class TailzsQuantCardFeed extends StatefulWidget {
  const TailzsQuantCardFeed({
    Key? key,
    this.width,
    this.height,
    this.games,
    this.isSub,
    this.selectedMode,
    this.selectedSport,
    this.selectedTier,
    this.searchQuery,
    this.onUpgradeTapped,
  }) : super(key: key);

  final double? width;
  final double? height;
  final List<dynamic>? games;
  final bool? isSub;
  final String? selectedMode;
  final String? selectedSport;
  final String? selectedTier;
  final String? searchQuery;
  final Future Function()? onUpgradeTapped;

  @override
  State<TailzsQuantCardFeed> createState() => _TailzsQuantCardFeedState();
}

class _TailzsQuantCardFeedState extends State<TailzsQuantCardFeed> {
  final Set<int> expandedDeepDives = {};
  final Set<String> pinnedGameKeys = {};

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

  Future<void> _triggerWaterRippleHaptic() async {
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 70));
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 90));
      await HapticFeedback.selectionClick();
    } catch (_) {
      HapticFeedback.lightImpact();
    }
  }

  String _getFlexibleDeep(
      Map<String, dynamic> rootMap, List<String> candidates, String fallback) {
    for (var cand in candidates) {
      final normalizedTarget =
          cand.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
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
        final childMap = Map<String, dynamic>.from(entry.value as Map);
        final res = _getFlexibleDeep(childMap, candidates, '');
        if (res.isNotEmpty) return res;
      }
    }
    return fallback;
  }

  bool _isValidGameItem(Map<String, dynamic> item) {
    final String rawMatchup =
        _getFlexibleDeep(item, ['game_matchup', 'matchup', 'game', 'event'], '')
            .trim();
    final String awayName =
        _getFlexibleDeep(item, ['away_team', 'away_name'], '').trim();
    final String homeName =
        _getFlexibleDeep(item, ['home_team', 'home_name'], '').trim();

    final String combined = '$rawMatchup $awayName $homeName'.toLowerCase();
    const blacklisted = [
      'category',
      'air & ground',
      'sector profile',
      'qb mobility',
      'containment',
      'trench & havoc',
      'havoc radar',
      'special teams',
      'ecosystem edge',
      'model cover',
      'data status',
      'indicator',
      'directive',
      'workbook',
      'legend',
      'glossary',
      'summary',
      'notes',
      'methodology',
      'parameter',
    ];

    for (var b in blacklisted) {
      if (combined.contains(b)) return false;
    }

    final lowerMatchup = rawMatchup.toLowerCase();
    final bool hasVersus = rawMatchup.contains('@') ||
        lowerMatchup.contains(' vs ') ||
        lowerMatchup.contains(' vs. ') ||
        lowerMatchup.contains(' at ');

    final bool hasRealTeams = awayName.isNotEmpty &&
        homeName.isNotEmpty &&
        awayName.toLowerCase() != 'away' &&
        homeName.toLowerCase() != 'home' &&
        awayName.toLowerCase() != 'tbd' &&
        homeName.toLowerCase() != 'tbd';

    if (!hasVersus && !hasRealTeams) {
      return false;
    }

    if (rawMatchup.contains('@')) {
      final parts = rawMatchup.split('@');
      if (parts.length != 2 ||
          parts[0].trim().isEmpty ||
          parts[1].trim().isEmpty) {
        return false;
      }
    }

    return true;
  }

  // --- COMPILES OFFICIAL RECEIPT TEXT WITH DATE & tailzs.app ---
  String _generateReceiptText(Map<String, dynamic> game, String sport,
      String tier, int legCount, String outcomeStatus) {
    final buffer = StringBuffer();
    buffer.writeln('🦊 TAILZS QUANT VERIFIED RECEIPT');
    buffer.writeln('🏆 ${sport.toUpperCase()} ${tier.toUpperCase()}');
    if (outcomeStatus.isNotEmpty) {
      buffer.writeln('Outcome: $outcomeStatus');
    }
    buffer.writeln('Matchup: ${game['matchup'] ?? ''}');

    final gameDate = (game['game_date'] ?? '').toString().trim();
    if (gameDate.isNotEmpty && gameDate != 'TBA') {
      buffer.writeln('Date: $gameDate');
    }

    final score = (game['score'] ?? '').toString();
    if (score.isNotEmpty) {
      buffer.writeln('Score: $score');
    }
    buffer.writeln();

    for (int i = 1; i <= legCount; i++) {
      final label = game['l${i}_label']?.toString() ?? 'LEG $i';
      final pick = game['l${i}_pick']?.toString() ?? 'TBD';
      final status = game['l${i}_status']?.toString().toUpperCase() ?? '';
      buffer.writeln('• $label: $pick [$status]');
    }

    buffer.writeln();
    buffer.writeln('Quant Edge Tracked Live on Tailzs Terminal 🗞');
    buffer.writeln('tailzs.app');
    return buffer.toString().trim();
  }

  void _showShareReceiptModal(
      BuildContext context, Map<String, dynamic> game, String outcomeStatus) {
    HapticFeedback.mediumImpact();
    final String sport = widget.selectedSport ?? 'NCAAF';
    final String tier = widget.selectedTier ?? 'TIER 1 PARLAY';
    final int legCount = (game['legCount'] as int?) ?? 1;
    final String receiptText =
        _generateReceiptText(game, sport, tier, legCount, outcomeStatus);

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
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('🏆 ', style: TextStyle(fontSize: 13)),
                          Text(
                            '${sport.toUpperCase()} ${tier.toUpperCase()}',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      if (outcomeStatus.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Text('Outcome: ',
                                style: TextStyle(
                                  color: Color(0xFF8A99A6),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                )),
                            Text(
                              outcomeStatus,
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
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Matchup: ${game['matchup'] ?? ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (gameDate.isNotEmpty && gameDate != 'TBA') ...[
                        const SizedBox(height: 2),
                        Text(
                          'Date: $gameDate',
                          style: const TextStyle(
                            color: Color(0xFF8A99A6),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      if ((game['score'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Score: ${game['score']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
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
                        final pick =
                            game['l${legNum}_pick']?.toString() ?? 'TBD';
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
                                  ),
                                ),
                                TextSpan(
                                  text: '$pick ',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: '[$status]',
                                  style: TextStyle(
                                    color: isWin
                                        ? const Color(0xFF00E676)
                                        : const Color(0xFFFF3366),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
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
                    'COPY RECEIPT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
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

  String _getCanonicalMatchupKey(String matchupStr) {
    final clean =
        matchupStr.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s@]'), ' ');
    List<String> parts = clean.contains('@') ? clean.split('@') : [clean];
    List<String> mascots = [];
    for (var part in parts) {
      final words =
          part.trim().split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
      if (words.isNotEmpty) mascots.add(words.last);
    }
    mascots.sort();
    return mascots.join('_');
  }

  bool _gameMatchesQuery(Map<String, dynamic> game, String query) {
    if (query.trim().isEmpty) return true;
    final String q = query.trim().toLowerCase();
    final StringBuffer buffer = StringBuffer();
    void collectStrings(dynamic value) {
      if (value == null) return;
      if (value is String) {
        buffer.write(' $value');
      } else if (value is Map) {
        for (var v in value.values) collectStrings(v);
      } else if (value is Iterable) {
        for (var item in value) collectStrings(item);
      } else if (value is num || value is bool) {
        buffer.write(' $value');
      }
    }

    collectStrings(game);
    return buffer.toString().toLowerCase().contains(q);
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
          fontFamilyFallback: const [
            'Apple Color Emoji',
            'Noto Color Emoji',
            'Segoe UI Emoji'
          ],
        ),
      ),
    );
  }

  Widget _buildDiveBox(String label, String value) {
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
              fontFamilyFallback: [
                'Apple Color Emoji',
                'Noto Color Emoji',
                'Segoe UI Emoji'
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.4,
              fontFamilyFallback: [
                'Apple Color Emoji',
                'Noto Color Emoji',
                'Segoe UI Emoji'
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeepDiveSection(Map<String, dynamic> game) {
    List<Map<String, String>> diveBoxes = [];
    final raw =
        game['_raw'] != null ? Map<String, dynamic>.from(game['_raw']) : game;
    final String awayName = game['away_name']?.toString() ?? 'Away';
    final String homeName = game['home_name']?.toString() ?? 'Home';
    final String sport = widget.selectedSport ?? 'NCAAF';
    final String tier = widget.selectedTier ?? 'TIER 1 PARLAY';

    if (tier.contains('TIER 1')) {
      if (sport == 'MLB') {
        diveBoxes = [
          {
            'title': 'TRIPARTITE MASTER PICK & PARLAY RADAR',
            'value': 'Master Pick: ${_getFlexibleDeep(raw, [
                  'tripartite_master_pick',
                  'leg_3_pick',
                  'moneyline_winner'
                ], 'MAJORITY LEAN: $homeName')}\nGrade: ${_getFlexibleDeep(raw, ['tripartite_parlay_grade', 'grade'], 'GOLDEN PARLAY')}'
          },
          {
            'title': 'LEG 1 (NRFI) EDGE DETAIL',
            'value': _getFlexibleDeep(raw, ['leg_1_edge_detail', 'nrfi_edge'],
                'Verified 30-Day Collision Match')
          },
          {
            'title': 'LEG 2 (F5 ML) EDGE CONTRAST',
            'value': _getFlexibleDeep(raw, ['leg_2_edge_contrast', 'f5_edge'],
                'Pitching Matchup Advantage: $homeName')
          },
          {
            'title': 'FULL GAME ML VALUE & RISK FLAG',
            'value': _getFlexibleDeep(
                raw,
                [
                  'risk_flag_vulnerability_diagnostic_negative_ratio_component',
                  'risk_flag'
                ],
                'Stable Model Output / No Regression Flag')
          },
        ];
      } else {
        diveBoxes = [
          {
            'title': 'TRIPARTITE MASTER PICK & PARLAY RADAR',
            'value': 'Master Pick: ${_getFlexibleDeep(raw, [
                  'tripartite_master_pick',
                  'leg_3_pick'
                ], 'MAJORITY LEAN: $homeName')}\nStatus: ${_getFlexibleDeep(raw, ['sweep_status', 'grade'], 'PENDING')}'
          },
          {
            'title': 'FIRST 7 EDGE DETAIL & MOMENTUM SCRIPT',
            'value': _getFlexibleDeep(raw, ['f7_edge_detail', 'first_7_edge'],
                'Positive Drive Success Trajectory')
          },
          {
            'title': '1H ML EDGE & ADVANTAGE RATIONALE',
            'value': _getFlexibleDeep(raw, ['1h_edge_detail', '1h_edge'],
                'First Half Line of Scrimmage Edge')
          },
          {
            'title': 'FULL GAME ML VALUE & RISK FLAG',
            'value': _getFlexibleDeep(
                raw,
                ['ml_value_detail', 'risk_flag_vulnerability_diagnostic'],
                'Strong Model Cover Conviction')
          },
        ];
      }
    } else if (tier.contains('TIER 2')) {
      if (sport == 'MLB') {
        diveBoxes = [
          {
            'title': 'KINETIC TOPOGRAPHY EDGE & WIN PROBABILITIES',
            'value': 'Win Prob: 📈 ${_getFlexibleDeep(raw, [
                  'kinetic_win_probability_away__home',
                  'kinetic_win_probability'
                ], '50.0% | 50.0%')}\nEdge: ${_getFlexibleDeep(raw, ['edge_confidence'], 'BALANCED')}\nScript: ${_getFlexibleDeep(raw, ['actionable_game_script'], '')}'
          },
          {
            'title': '4-EMOJI CLASH EQUATION & VECTORS',
            'value':
                'Clash: ${_getFlexibleDeep(raw, ['4emoji_clash_equation', 'clash_equation'], '⚡ OFF vs 🛡️ DEF')}\nVectors: ${_getFlexibleDeep(raw, [
                      'trajectory_acceleration_vectors',
                      'trajectory_vectors'
                    ], '$awayName: 🧊 SLUMPING | $homeName: 🔥 SURGING')}'
          },
          {
            'title': 'INSIGNIA SYNERGY MATRIX & CROWN ($awayName vs $homeName)',
            'value': 'Crown: ${_getFlexibleDeep(raw, [
                  'master_prevailing_crown'
                ], 'IMPERIAL OVERMATCH')}\nSynergy: ${_getFlexibleDeep(raw, ['hybrid_clash_result_explicit_inputs'], 'PAPER CUTS')}'
          },
          {
            'title': 'OFFENSE VS DEFENSE SECTOR MATCHUPS',
            'value': '$awayName Metrics: ${_getFlexibleDeep(raw, [
                  'away_metrics_3d_vs_5d'
                ], 'PHANTOM DRIFT')}\n$homeName Metrics: ${_getFlexibleDeep(raw, ['home_metrics_3d_vs_5d'], 'CYCLONE SWARM')}'
          },
        ];
      } else {
        diveBoxes = [
          {
            'title': 'KINETIC TOPOGRAPHY EDGE & WIN PROBABILITIES',
            'value':
                'Win Prob: 📈 ${_getFlexibleDeep(raw, ['kinetic_win_probability_away__home'], '50.0% | 50.0%')}\nEdge: ${_getFlexibleDeep(raw, [
                      'edge_confidence'
                    ], 'BALANCED')}\nScript: ${_getFlexibleDeep(raw, ['actionable_game_script'], '')}'
          },
          {
            'title': 'RECENT VS SEASONAL METRICS & VECTORS',
            'value':
                '$awayName Net: ${_getFlexibleDeep(raw, ['away_metrics_rec_vs_ssn'], '')}\n$homeName Net: ${_getFlexibleDeep(raw, [
                      'home_metrics_rec_vs_ssn'
                    ], '')}\nVectors: ${_getFlexibleDeep(raw, ['trajectory_acceleration_vectors'], '')}'
          },
          {
            'title': '4-EMOJI CLASH EQUATION',
            'value': _getFlexibleDeep(
                raw, ['4emoji_clash_equation'], '⚡ OFF vs 🛡️ DEF')
          },
          {
            'title': 'INSIGNIA OFFENSE VS DEFENSE PROFILES',
            'value':
                '${_getFlexibleDeep(raw, ['offense_team'], awayName)}: ${_getFlexibleDeep(raw, [
                      'offensive_insignia_indexed'
                    ], 'Neutral')}\n${_getFlexibleDeep(raw, ['defense_team'], homeName)}: ${_getFlexibleDeep(raw, ['defensive_insignia_indexed'], 'Neutral')}'
          },
          {
            'title': 'SYNERGY OUTPUT & CROWN ($awayName vs $homeName)',
            'value': 'Crown: ${_getFlexibleDeep(raw, [
                  'master_prevailing_crown'
                ], '🪞 MIRROR EQUILIBRIUM')}\nResult: ${_getFlexibleDeep(raw, ['hybrid_clash_result_explicit_inputs'], '')}'
          },
        ];
      }
    } else {
      if (sport == 'MLB') {
        diveBoxes = [
          {
            'title': 'MICRO PROFILED MATCHUP & PROJECTED ADVANTAGE ($homeName)',
            'value': 'Status: 🎯 ${_getFlexibleDeep(raw, [
                  'projected_advantage_status'
                ], 'HIGH FORCE EDGE')}\nChamber: ${_getFlexibleDeep(raw, ['chamber_topography_status'], 'Balanced Environment')}'
          },
          {
            'title':
                'PITCHER & LINEUP MICRO-ZONE EXECUTION ($awayName vs $homeName)',
            'value': 'Lineup Zone: ${_getFlexibleDeep(raw, [
                  'lineup_micro_zone_index'
                ], 'MAX CONTACT')}\nPitcher Zone: ${_getFlexibleDeep(raw, ['deployed_pitcher_zone_execution_index'], 'SAFE HITS LINEUP')}'
          },
          {
            'title':
                'PLATOON SPLITS & ARSENAL DISRUPTORS ($awayName vs $homeName)',
            'value': 'Platoon: ${_getFlexibleDeep(raw, [
                  'platoon_split_verification_hand_match'
                ], 'NEUTRAL SPLIT')}\nDisruptor: ${_getFlexibleDeep(raw, ['arsenal_disruptor_status'], 'NEUTRAL')}'
          },
          {
            'title': 'STATISTICAL VARIANCE & MOMENTUM PROFILE',
            'value': 'Variance: ${_getFlexibleDeep(raw, [
                  'stat_variance_advantage_offense__defense'
                ], 'OFFENSIVE ADVANTAGE')}\nBullpen: ${_getFlexibleDeep(raw, ['bullpen_status'], 'STABLE BULLPEN')}\nMomentum: ${_getFlexibleDeep(raw, ['buzzsaw__momentum_status'], '')}'
          },
        ];
      } else {
        String awaySpZscore = '';
        String awaySpRating = '';
        String homeSpZscore = '';
        String homeSpRating = '';

        if (raw['home'] is Map) {
          final homeMap = Map<String, dynamic>.from(raw['home'] as Map);
          homeSpZscore =
              _getFlexibleDeep(homeMap, ['sp_rating_rank__zscore'], '');
          homeSpRating = _getFlexibleDeep(homeMap, ['sp_rating_extracted'], '');
        }

        if (raw['away'] is Map) {
          final awayMap = Map<String, dynamic>.from(raw['away'] as Map);
          awaySpZscore =
              _getFlexibleDeep(awayMap, ['sp_rating_rank__zscore'], '');
          awaySpRating = _getFlexibleDeep(awayMap, ['sp_rating_extracted'], '');
        }

        if (awaySpZscore.isEmpty) {
          awaySpZscore =
              _getFlexibleDeep(raw, ['sp_rating_rank__zscore'], 'UNRANKED');
        }
        if (awaySpRating.isEmpty) {
          awaySpRating = _getFlexibleDeep(raw, ['sp_rating_extracted'], '');
        }

        String awaySpDisplay = awaySpRating.isNotEmpty
            ? '$awaySpRating | $awaySpZscore'
            : awaySpZscore;

        String homeSpDisplay = homeSpZscore.isNotEmpty
            ? (homeSpRating.isNotEmpty
                ? '$homeSpRating | $homeSpZscore'
                : homeSpZscore)
            : 'UNRANKED (Z: 0.00 σ)';

        String sideVerdict = _getFlexibleDeep(
            raw,
            [
              'model_spread_cover_verdict_side_edge',
              'model_cover_directive',
              'model_spread_cover_verdict'
            ],
            'LEAN COVER');

        String edgeDirective = _getFlexibleDeep(
            raw,
            [
              'ecosystem_edge__value_trap_directive',
              'ecosystem_edge_directive'
            ],
            '');

        diveBoxes = [
          {
            'title': 'SP+ BASELINE & RATING ($awayName vs $homeName)',
            'value':
                '🏈 $awayName (Away): $awaySpDisplay\n🏈 $homeName (Home): $homeSpDisplay'
          },
          {
            'title': 'MODEL SPREAD COVER VERDICT & DIRECTIVES',
            'value':
                '$sideVerdict${edgeDirective.isNotEmpty ? '\n$edgeDirective' : ''}'
          },
          {
            'title': 'ECOSYSTEM CONTROL ($awayName vs $homeName)',
            'value': 'Air/Ground: ${_getFlexibleDeep(raw, [
                  'air__ground_sector_profiles'
                ], 'Neutral')}\nSpecial Teams: ${_getFlexibleDeep(raw, ['special_teams_xfactor_index'], 'Neutral')}'
          },
          {
            'title': 'QB CONTAINMENT ($awayName vs $homeName)',
            'value': 'Deployed: ${_getFlexibleDeep(raw, [
                  'deployed_defense_qb_containment_profile'
                ], 'Neutral')}\nEcosystem: ${_getFlexibleDeep(raw, ['ecosystem_qb_containment_index'], 'BALANCED')}'
          },
        ];
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: diveBoxes
            .map((box) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: _buildDiveBox(box['title']!, box['value']!)))
            .toList(),
      ),
    );
  }

  Widget _buildLegsGrid(Map<String, dynamic> game, int legCount, bool subActive,
      bool isMixMatch, String activeMode) {
    return Row(
      children: List.generate(legCount, (i) {
        final int legNum = i + 1;
        final String marginStr = (game['l${legNum}_margin'] ?? '').toString();
        final String statusStr =
            game['l${legNum}_status']?.toString().toUpperCase() ?? 'PENDING';

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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFF0B1114),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: legBorderColor)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game['l${legNum}_label']?.toString() ?? 'LEG $legNum',
                    style: TextStyle(
                      color: legTitleColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      fontFamilyFallback: const [
                        'Apple Color Emoji',
                        'Noto Color Emoji',
                        'Segoe UI Emoji'
                      ],
                    )),
                const SizedBox(height: 4),
                Text(game['l${legNum}_pick']?.toString() ?? 'TBD',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamilyFallback: [
                        'Apple Color Emoji',
                        'Noto Color Emoji',
                        'Segoe UI Emoji'
                      ],
                    )),
                const SizedBox(height: 6),
                _buildStatusPill(statusStr),
                if (marginStr.isNotEmpty && marginStr != 'null') ...[
                  const SizedBox(height: 6),
                  Text('Margin: $marginStr',
                      style: const TextStyle(
                        color: Color(0xFF8A99A6),
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        fontFamilyFallback: [
                          'Apple Color Emoji',
                          'Noto Color Emoji',
                          'Segoe UI Emoji'
                        ],
                      )),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game, int index, bool subActive) {
    final mode = widget.selectedMode ?? 'PROSPECTIVE';
    final sport = widget.selectedSport ?? 'NCAAF';
    final String badgeType = game['badgeType']?.toString() ?? 'PENDING';
    final int legCount = (game['legCount'] as int?) ?? 1;
    final bool isDeepDiveOpen = expandedDeepDives.contains(index);
    final String canonicalKey =
        _getCanonicalMatchupKey(game['matchup']?.toString() ?? '');
    final bool isPinned = pinnedGameKeys.contains(canonicalKey);
    final bool isMixMatch = (game['isMixMatch'] as bool?) ?? false;
    final String gameDate = (game['game_date'] ?? '').toString().trim();

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
            : (legCount == 2 ? '🔥 DUAL WIN' : '🔥 SIDE WIN');
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
            : (legCount == 2 ? '❄️ DUAL LOSS' : '❄️ SIDE LOSS');
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
          ? '⚡ HIGH PAYOUT POTENTIAL MIX-MATCH PARLAY'
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
                    letterSpacing: 0.4)),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    isPinned
                        ? pinnedGameKeys.remove(canonicalKey)
                        : pinnedGameKeys.add(canonicalKey);
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Icon(isPinned ? Icons.star : Icons.star_border,
                      color: isPinned
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF8A99A6),
                      size: 16),
                ),
              ),
              Text((subActive || mode == 'AUDIT') ? '🦊 ' : '🔒 ',
                  style: const TextStyle(
                      fontSize: 15,
                      height: 1.0,
                      fontFamilyFallback: [
                        'Apple Color Emoji',
                        'Noto Color Emoji',
                        'Segoe UI Emoji'
                      ])),
              Expanded(
                child: Text(game['matchup']?.toString() ?? 'Matchup TBD',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamilyFallback: [
                        'Apple Color Emoji',
                        'Noto Color Emoji',
                        'Segoe UI Emoji'
                      ],
                    )),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  if (subActive) {
                    await _triggerWaterRippleHaptic();
                    setState(() {
                      isDeepDiveOpen
                          ? expandedDeepDives.remove(index)
                          : expandedDeepDives.add(index);
                    });
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
                              fontWeight: FontWeight.w800)),
                      if (subActive) ...[
                        const SizedBox(width: 4),
                        Icon(
                            isDeepDiveOpen
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: borderColor)),
                  child: Text(badgeTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: badgeText,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        fontFamilyFallback: const [
                          'Apple Color Emoji',
                          'Noto Color Emoji',
                          'Segoe UI Emoji'
                        ],
                      )),
                ),
              ),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (gameDate.isNotEmpty && gameDate != 'TBA') ...[
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                              color: const Color(0xFF0B1114),
                              borderRadius: BorderRadius.circular(5),
                              border:
                                  Border.all(color: const Color(0xFF24343B))),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Color(0xFF8A99A6), size: 9),
                              const SizedBox(width: 4),
                              Flexible(
                                  child: Text(gameDate,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Color(0xFF8A99A6),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                      ),
                      if (mode == 'AUDIT' &&
                          (game['score'] ?? '').toString().isNotEmpty)
                        const SizedBox(width: 4),
                    ],
                    if (mode == 'AUDIT' &&
                        (game['score'] ?? '').toString().isNotEmpty)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                              color: const Color(0xFF0B1114),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                  color: borderColor.withOpacity(0.6))),
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(game['score']?.toString() ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold))),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // --- VERIFIED AUDIT RECEIPT ROW ---
          if (mode == 'AUDIT') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified,
                        color: Color(0xFF00F5D4), size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'VERIFIED $sport AUDIT RECEIPT',
                      style: const TextStyle(
                        color: Color(0xFF00F5D4),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
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
                        Icon(Icons.share, color: Color(0xFFFF5E00), size: 12),
                        SizedBox(width: 4),
                        Text(
                          'SHARE RECEIPT',
                          style: TextStyle(
                            color: Color(0xFFFF5E00),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
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
          if (subActive && isDeepDiveOpen) _buildDeepDiveSection(game),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.games == null || widget.games!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
            (widget.searchQuery ?? '').isNotEmpty
                ? 'NO GAMES MATCHING "${widget.searchQuery}"'
                : 'NO GAMES QUEUED FOR ${widget.selectedSport ?? 'NCAAF'}',
            style: const TextStyle(
                color: Color(0xFF8A99A6),
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      );
    }

    final bool subActive = widget.isSub ?? false;
    final String searchQ = widget.searchQuery ?? '';

    final List<Map<String, dynamic>> gamesList = widget.games!
        .where(
            (g) => g is Map && _isValidGameItem(Map<String, dynamic>.from(g)))
        .map((g) => Map<String, dynamic>.from(g as Map))
        .toList();

    gamesList.sort((a, b) {
      final keyA = _getCanonicalMatchupKey(a['matchup']?.toString() ?? '');
      final keyB = _getCanonicalMatchupKey(b['matchup']?.toString() ?? '');
      final isPinnedA = pinnedGameKeys.contains(keyA);
      final isPinnedB = pinnedGameKeys.contains(keyB);
      if (isPinnedA && !isPinnedB) return -1;
      if (!isPinnedA && isPinnedB) return 1;
      return 0;
    });

    final filtered = searchQ.isEmpty
        ? gamesList
        : gamesList.where((g) => _gameMatchesQuery(g, searchQ)).toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text('NO GAMES MATCHING "$searchQ"',
            style: const TextStyle(
                color: Color(0xFF8A99A6),
                fontSize: 11,
                fontWeight: FontWeight.bold)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildGameCard(filtered[index], index, subActive),
    );
  }
}
