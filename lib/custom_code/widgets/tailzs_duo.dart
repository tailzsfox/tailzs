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
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

class TailzsDuo extends StatefulWidget {
  const TailzsDuo({
    Key? key,
    this.width,
    this.height,
    this.masterGamesList,
    this.isSub,
    this.onUpgradeTapped,
  }) : super(key: key);

  final double? width;
  final double? height;
  final dynamic masterGamesList;
  final bool? isSub;
  final dynamic onUpgradeTapped;

  @override
  State<TailzsDuo> createState() => _TailzsDuoState();
}

class _TailzsDuoState extends State<TailzsDuo> {
  // --- LEFT PANE STATE (Primary Mobile State) ---
  String _leftMode = 'PROSPECTIVE';
  String _leftSport = 'NFL';
  String _leftTier = 'TIER 1 PARLAY';
  String _leftSearch = '';

  // --- RIGHT PANE STATE (Tablet / Foldable Dual Mode) ---
  String _rightWorkspaceMode = 'DUAL_FEED'; // DUAL_FEED, DOSSIER, DUO_SLIP
  String _rightMode = 'AUDIT';
  String _rightSport = 'NBA';
  String _rightTier = 'TIER 3 SIDE';
  String _rightSearch = '';

  final _duoSlipGames = [];
  final Map _paneGamesCache = {};
  List _localHydratedGames = [];
  bool _isLoadingCache = false;

  @override
  void initState() {
    super.initState();
    if (widget.masterGamesList == null ||
        (widget.masterGamesList is List &&
            (widget.masterGamesList as List).isEmpty)) {
      _hydrateEdgeCache();
    }
  }

  dynamic _triggerLightHaptic() {
    HapticFeedback.lightImpact();
  }

  // --- EDGE HYDRATION: LOAD FROM DISK CACHE ON COLD STARTS ---
  dynamic _hydrateEdgeCache() async {
    if (_isLoadingCache) return;
    _isLoadingCache = true;
    try {
      final collectionRef = FirebaseFirestore.instance.collection('dossiers');
      dynamic snapshot;

      // 1. Instant local disk cache retrieval (Zero network read cost)
      try {
        snapshot =
            await collectionRef.get(const GetOptions(source: Source.cache));
      } catch (_) {}

      // 2. Query server only if local device storage is cold
      if (snapshot == null || snapshot.docs.isEmpty) {
        snapshot =
            await collectionRef.get(const GetOptions(source: Source.server));
      }

      if (snapshot != null && snapshot.docs.isNotEmpty && mounted) {
        final allGames = [];
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map;
          final docId = doc.id.toLowerCase();

          String docSport = 'nfl';
          if (docId.contains('nba'))
            docSport = 'nba';
          else if (docId.contains('nhl'))
            docSport = 'nhl';
          else if (docId.contains('ncaaf'))
            docSport = 'ncaaf';
          else if (docId.contains('mlb')) docSport = 'mlb';

          final bool isAudit = docId.contains('eod') ||
              docId.contains('audit') ||
              docId.contains('eow');
          final String docMode = isAudit ? 'AUDIT' : 'PROSPECTIVE';

          List rawG = [];
          if (data['games'] is List) {
            rawG = data['games'] as List;
          } else if (data['games'] is Map) {
            rawG = (data['games'] as Map).values.toList();
          }

          for (var g in rawG) {
            if (g is Map) {
              allGames.add({
                ...Map.from(g),
                'sport': docSport,
                'mode': docMode,
              });
            }
          }
        }

        setState(() {
          _localHydratedGames = allGames;
          _paneGamesCache.clear();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) _isLoadingCache = false;
    }
  }

  // --- MEMOIZED FILTER ENGINE FOR INDEPENDENT PANES ---
  dynamic _filterGamesForPane(String mode, String sport, String tier) {
    final List sourceList = (widget.masterGamesList != null &&
            widget.masterGamesList is List &&
            (widget.masterGamesList as List).isNotEmpty)
        ? (widget.masterGamesList as List)
        : _localHydratedGames;

    if (sourceList.isEmpty) return [];

    final String cacheKey = '${mode}_${sport}_${tier}_${sourceList.length}';
    if (_paneGamesCache.containsKey(cacheKey)) {
      return _paneGamesCache[cacheKey];
    }

    final normSport = sport.toLowerCase();
    final normMode = mode.toUpperCase();

    final filtered = sourceList.where((g) {
      if (g is! Map) return true;
      final gSport =
          (g['sport'] ?? g['league'])?.toString().toLowerCase() ?? '';
      if (gSport.isNotEmpty &&
          !gSport.contains(normSport) &&
          !normSport.contains(gSport)) {
        return false;
      }
      final gMode = g['mode']?.toString().toUpperCase() ?? '';
      if (gMode.isNotEmpty && gMode != normMode) {
        return false;
      }
      return true;
    }).toList();

    _paneGamesCache[cacheKey] = filtered;
    return filtered;
  }

  // --- REALTIME DYNAMIC KPI CALCULATOR ---
  Map _calculateKPIs(List games, String activeTier) {
    if (games.isEmpty) {
      return {'eval': 0, 'sweeps': 0, 'winPct': 0.0, 'pending': 0, 'queued': 0};
    }
    int eval = 0;
    int sweeps = 0;
    int wins = 0;
    int totalLegs = 0;
    int pendingCount = 0;
    int tierCount = activeTier.contains('TIER 1')
        ? 3
        : (activeTier.contains('TIER 2') ? 2 : 1);

    for (var game in games) {
      if (game is! Map) continue;
      bool isGamePending = game['badgeType'] == 'PENDING';
      if (isGamePending) {
        pendingCount++;
        continue;
      }
      eval++;
      if (game['badgeType'] == 'SWEEP_HIT') sweeps++;
      for (int i = 1; i <= tierCount; i++) {
        String status = game['l${i}_status']?.toString().toUpperCase() ?? '';
        if (status.contains('WIN')) {
          wins++;
          totalLegs++;
        } else if (status.contains('LOSS')) {
          totalLegs++;
        }
      }
    }
    double pct = totalLegs > 0 ? (wins / totalLegs) * 100.0 : 0.0;
    return {
      'eval': eval,
      'sweeps': sweeps,
      'winPct': pct,
      'pending': pendingCount,
      'queued': games.length,
    };
  }

  // ==========================================
  // LEFT PANE (PRIMARY TERMINAL)
  // ==========================================
  Widget _buildLeftPane(BuildContext context, bool isMobile) {
    final leftGames = _filterGamesForPane(_leftMode, _leftSport, _leftTier);
    final leftKpis = _calculateKPIs(leftGames, _leftTier);

    return Container(
      color: const Color(0xFF080C0E),
      child: Column(
        children: [
          TailzsQuantCommandHeader(
            selectedMode: _leftMode,
            selectedSport: _leftSport,
            selectedTier: _leftTier,
            onModeChanged: (val) async {
              setState(() {
                _leftMode = val;
                _paneGamesCache.clear();
              });
              return true;
            },
            onSportChanged: (val) async {
              setState(() {
                _leftSport = val;
                _paneGamesCache.clear();
              });
              return true;
            },
            onTierChanged: (val) async {
              setState(() {
                _leftTier = val;
                _paneGamesCache.clear();
              });
              return true;
            },
            onSearchChanged: (val) async {
              setState(() => _leftSearch = val);
              return true;
            },
            onSettingsTapped: () async => true,
          ),
          const SizedBox(height: 12),
          TailzsQuantVaultKpiBar(
            isSub: widget.isSub ?? false,
            selectedMode: _leftMode,
            selectedSport: _leftSport,
            evalCount: leftKpis['eval'],
            sweepsCount: leftKpis['sweeps'],
            winPercent: leftKpis['winPct'],
            pendingCount: leftKpis['pending'],
            gamesQueuedCount: leftGames.length,
            onUpgradeTapped: widget.onUpgradeTapped,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TailzsQuantCardFeed(
              games: leftGames,
              isSub: widget.isSub ?? false,
              selectedMode: _leftMode,
              selectedSport: _leftSport,
              selectedTier: _leftTier,
              searchQuery: _leftSearch,
              onUpgradeTapped: widget.onUpgradeTapped,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RIGHT PANE (DUAL APP / MULTITASKING ENGINE)
  // ==========================================
  Widget _buildRightPane(BuildContext context) {
    return Container(
      color: const Color(0xFF050809),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFF24343B), width: 1.5)),
            ),
            child: Row(
              children: [
                _buildRightPaneTab('DUAL_FEED', '📊 DUAL LIVE APP'),
                const SizedBox(width: 8),
                _buildRightPaneTab('DUO_SLIP', '⚡ DUO SLIP'),
                const SizedBox(width: 8),
                _buildRightPaneTab('DOSSIER', '📄 DOSSIER WORKSPACE'),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0, left: 16, right: 16),
              child: _routeRightPaneContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeRightPaneContent() {
    if (_rightWorkspaceMode == 'DUAL_FEED') {
      final rightGames =
          _filterGamesForPane(_rightMode, _rightSport, _rightTier);
      final rightKpis = _calculateKPIs(rightGames, _rightTier);

      return Column(
        children: [
          TailzsQuantCommandHeader(
            selectedMode: _rightMode,
            selectedSport: _rightSport,
            selectedTier: _rightTier,
            onModeChanged: (val) async {
              setState(() {
                _rightMode = val;
                _paneGamesCache.clear();
              });
              return true;
            },
            onSportChanged: (val) async {
              setState(() {
                _rightSport = val;
                _paneGamesCache.clear();
              });
              return true;
            },
            onTierChanged: (val) async {
              setState(() {
                _rightTier = val;
                _paneGamesCache.clear();
              });
              return true;
            },
            onSearchChanged: (val) async {
              setState(() => _rightSearch = val);
              return true;
            },
            onSettingsTapped: () async => true,
          ),
          const SizedBox(height: 12),
          TailzsQuantVaultKpiBar(
            isSub: widget.isSub ?? false,
            selectedMode: _rightMode,
            selectedSport: _rightSport,
            evalCount: rightKpis['eval'],
            sweepsCount: rightKpis['sweeps'],
            winPercent: rightKpis['winPct'],
            pendingCount: rightKpis['pending'],
            gamesQueuedCount: rightGames.length,
            onUpgradeTapped: widget.onUpgradeTapped,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TailzsQuantCardFeed(
              games: rightGames,
              isSub: widget.isSub ?? false,
              selectedMode: _rightMode,
              selectedSport: _rightSport,
              selectedTier: _rightTier,
              searchQuery: _rightSearch,
              onUpgradeTapped: widget.onUpgradeTapped,
            ),
          ),
        ],
      );
    } else if (_rightWorkspaceMode == 'DUO_SLIP') {
      return _buildDuoSlipBuilder();
    } else {
      return _buildDossierPlaceholder();
    }
  }

  Widget _buildRightPaneTab(String modeKey, String label) {
    final bool isSelected = _rightWorkspaceMode == modeKey;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _triggerLightHaptic();
          setState(() => _rightWorkspaceMode = modeKey);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00F5D4).withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00F5D4)
                  : const Color(0xFF24343B),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF00F5D4)
                  : const Color(0xFF8A99A6),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDuoSlipBuilder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1114),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00F5D4), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_to_photos, color: Color(0xFF00F5D4), size: 40),
          SizedBox(height: 16),
          Text(
            'TAILZS DUO SLIP BUILDER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the "+" icon on any game card in the left feed to add it to your Duo Slip and calculate combined synergies.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8A99A6),
              fontSize: 11,
              height: 1.5,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDossierPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1114),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.picture_as_pdf, color: Color(0xFFD4AF37), size: 40),
          SizedBox(height: 16),
          Text(
            'ANALYST WORKSPACE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Active Master PDF loaded. Compare ecosystem directives side-by-side with live terminal signals.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8A99A6),
              fontSize: 11,
              height: 1.5,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RESPONSIVE LAYOUT ENGINE (650px BREAKPOINT)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 650) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 48,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildLeftPane(context, false),
                  ),
                ),
                Container(
                  width: 3,
                  color: const Color(0xFF050809),
                  child: Center(
                    child: Container(
                      width: 1.5,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF24343B),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 52,
                  child: _buildRightPane(context),
                ),
              ],
            );
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildLeftPane(context, true),
            );
          }
        },
      ),
    );
  }
}
