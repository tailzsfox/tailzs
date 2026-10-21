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

import 'package:flutter/services.dart';

class TailzsQuantCommandHeader extends StatefulWidget {
  const TailzsQuantCommandHeader({
    Key? key,
    this.width,
    this.height,
    required this.selectedMode,
    required this.selectedSport,
    required this.selectedTier,
    this.onModeChanged,
    this.onSportChanged,
    this.onTierChanged,
    this.onSearchChanged,
    this.onSettingsTapped,
  }) : super(key: key);

  final double? width;
  final double? height;
  final String selectedMode;
  final String selectedSport;
  final String selectedTier;
  final Future Function(String mode)? onModeChanged;
  final Future Function(String sport)? onSportChanged;
  final Future Function(String tier)? onTierChanged;
  final Future Function(String query)? onSearchChanged;
  final Future Function()? onSettingsTapped;

  @override
  State<TailzsQuantCommandHeader> createState() =>
      _TailzsQuantCommandHeaderState();
}

class _TailzsQuantCommandHeaderState extends State<TailzsQuantCommandHeader> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> activeSportsList = ['MLB', 'NCAAF'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF182226),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5E5C9), width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33F5E5C9), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 32,
                margin: const EdgeInsets.only(right: 6),
                child: Image.network(
                  'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/tailzs-9bbvkw/assets/i4jahngiofzu/appleicon.png',
                  fit: BoxFit.contain,
                ),
              ),
              RichText(
                text: const TextSpan(children: [
                  TextSpan(
                    text: 'TAIL',
                    style: TextStyle(
                        color: Color(0xFFFF5E00),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8),
                  ),
                  TextSpan(
                    text: 'ZS',
                    style: TextStyle(
                        color: Color(0xFF00F5D4),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8),
                  )
                ]),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    onChanged: (val) {
                      widget.onSearchChanged?.call(val);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search team, game, or keyword...',
                      hintStyle: const TextStyle(
                          color: Color(0xFF8A99A6), fontSize: 10),
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0xFF8A99A6), size: 15),
                      filled: true,
                      fillColor: const Color(0xFF0B1114),
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF24343B)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF00F5D4)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.settings,
                    color: Color(0xFFF5E5C9), size: 20),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onSettingsTapped?.call();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: ['PROSPECTIVE', 'AUDIT'].map((mode) {
              final bool isSelected = widget.selectedMode == mode;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onModeChanged?.call(mode);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF5E00)
                          : const Color(0xFF0B1114),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF5E00)
                            : const Color(0xFF24343B),
                      ),
                      boxShadow: isSelected
                          ? [
                              const BoxShadow(
                                  color: Color(0x73FF5E00), blurRadius: 8)
                            ]
                          : null,
                    ),
                    child: Text(
                      mode,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF8A99A6),
                          fontSize: 11,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: activeSportsList.map((sport) {
                final bool isSelected = widget.selectedSport == sport;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onSportChanged?.call(sport);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00F5D4)
                          : const Color(0xFF0B1114),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00F5D4)
                            : const Color(0xFF24343B),
                      ),
                    ),
                    child: Text(
                      sport,
                      style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF0B1114)
                              : const Color(0xFF8A99A6),
                          fontSize: 10,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: ['TIER 1 PARLAY', 'TIER 2 ML', 'TIER 3 SIDE'].map((tier) {
              final bool isSelected = widget.selectedTier == tier;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onTierChanged?.call(tier);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF5E5C9).withOpacity(0.12)
                          : const Color(0xFF0B1114),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFF5E5C9)
                            : const Color(0xFF24343B),
                      ),
                    ),
                    child: Text(
                      tier,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFF5E5C9)
                              : const Color(0xFF8A99A6),
                          fontSize: 9,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
