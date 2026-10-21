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

import 'dart:async';
import 'dart:io' show File, Directory;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TailzsQuantVaultKpiBar extends StatefulWidget {
  const TailzsQuantVaultKpiBar({
    Key? key,
    this.width,
    this.height,
    this.isSub,
    this.selectedSport,
    this.selectedMode,
    this.evalCount,
    this.sweepsCount,
    this.winPercent,
    this.pendingCount,
    this.gamesQueuedCount,
    this.dossierDocs,
    this.dossierUrl,
    this.selectedDossierDocId,
    this.onUpgradeTapped,
  }) : super(key: key);

  final double? width;
  final double? height;
  final bool? isSub;
  final String? selectedSport;
  final String? selectedMode;
  final int? evalCount;
  final int? sweepsCount;
  final double? winPercent;
  final int? pendingCount;
  final int? gamesQueuedCount;
  final DossiersRecord? dossierDocs;
  final String? dossierUrl;
  final String? selectedDossierDocId;
  final Future Function()? onUpgradeTapped;

  @override
  State<TailzsQuantVaultKpiBar> createState() => _TailzsQuantVaultKpiBarState();
}

class _TailzsQuantVaultKpiBarState extends State<TailzsQuantVaultKpiBar> {
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

  String _sanitizeUrl(String rawUrl) {
    if (rawUrl.trim().isEmpty) return '';
    String clean = rawUrl.trim();
    clean = clean
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('\n', '')
        .replaceAll('\r', '');
    while (clean.contains('%252F') ||
        clean.contains('%2520') ||
        clean.contains('%2525')) {
      clean = clean
          .replaceAll('%2525', '%25')
          .replaceAll('%252F', '%2F')
          .replaceAll('%2520', '%20');
    }
    if (clean.toLowerCase().startsWith('gs://')) {
      clean = clean.replaceFirst(RegExp(r'^gs://', caseSensitive: false),
          'https://storage.googleapis.com/');
    }
    if (clean.contains('storage.cloud.google.com')) {
      clean = clean.replaceAll(
          'storage.cloud.google.com', 'storage.googleapis.com');
    }
    if (clean.toLowerCase().startsWith('http://')) {
      clean = clean.replaceFirst(
          RegExp(r'^http://', caseSensitive: false), 'https://');
    } else if (!clean.toLowerCase().startsWith('https://')) {
      clean = clean.replaceFirst(RegExp(r'^\/\/'), '');
      clean = 'https://$clean';
    }
    if (clean.contains(' ') && !clean.contains('%20')) {
      clean = clean.replaceAll(' ', '%20');
    }
    return clean;
  }

  bool _isDocMatchingMode(String docId, String mode) {
    final lower = docId.toLowerCase();
    final bool isAudit = lower.contains('eod') ||
        lower.contains('eow') ||
        lower.contains('audit');
    return (mode == 'AUDIT') ? isAudit : !isAudit;
  }

  int? _extractNcaafWeek(String docId, Map<String, dynamic> data, String url) {
    final m1 =
        RegExp(r'week[_-]?(\d+)', caseSensitive: false).firstMatch(docId);
    if (m1 != null) {
      return int.tryParse(m1.group(1)!);
    }
    if (data.containsKey('week') && data['week'] != null) {
      final w = int.tryParse(data['week'].toString());
      if (w != null) return w;
    }
    if (data.containsKey('slate_week') && data['slate_week'] != null) {
      final w = int.tryParse(data['slate_week'].toString());
      if (w != null) return w;
    }
    final fn = data['pdf_filename']?.toString() ?? '';
    final m2 = RegExp(r'week[_-]?(\d+)', caseSensitive: false).firstMatch(fn) ??
        RegExp(r'week[_-]?(\d+)', caseSensitive: false).firstMatch(url);
    if (m2 != null) {
      return int.tryParse(m2.group(1)!);
    }
    return null;
  }

  String? _extractMlbDate(String docId, Map<String, dynamic> data, String url) {
    final m1 = RegExp(r'date_(\d{4})_(\d{2})_(\d{2})', caseSensitive: false)
        .firstMatch(docId);
    if (m1 != null) {
      return '${m1.group(1)}-${m1.group(2)}-${m1.group(3)}';
    }
    final fn = data['pdf_filename']?.toString() ?? '';
    final m2 = RegExp(r'(\d{4})[-_](\d{2})[-_](\d{2})').firstMatch(fn) ??
        RegExp(r'(\d{4})[-_](\d{2})[-_](\d{2})').firstMatch(url);
    if (m2 != null) {
      return '${m2.group(1)}-${m2.group(2)}-${m2.group(3)}';
    }
    final dField = (data['date'] ?? data['slate_date'])?.toString() ?? '';
    final m3 = RegExp(r'(\d{4})[-_](\d{2})[-_](\d{2})').firstMatch(dField);
    if (m3 != null) {
      return '${m3.group(1)}-${m3.group(2)}-${m3.group(3)}';
    }
    final gd = data['game_date']?.toString() ?? '';
    final m4 = RegExp(
            r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d+)',
            caseSensitive: false)
        .firstMatch(gd);
    if (m4 != null) {
      final months = {
        'jan': '01',
        'feb': '02',
        'mar': '03',
        'apr': '04',
        'may': '05',
        'jun': '06',
        'jul': '07',
        'aug': '08',
        'sep': '09',
        'oct': '10',
        'nov': '11',
        'dec': '12'
      };
      final mo = months[m4.group(1)!.toLowerCase()] ?? '10';
      final dy = m4.group(2)!.padLeft(2, '0');
      return '2026-$mo-$dy';
    }
    return null;
  }

  String _formatMlbDateDisplay(String dateStr) {
    try {
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) {
        const fullMonths = [
          'JANUARY',
          'FEBRUARY',
          'MARCH',
          'APRIL',
          'MAY',
          'JUNE',
          'JULY',
          'AUGUST',
          'SEPTEMBER',
          'OCTOBER',
          'NOVEMBER',
          'DECEMBER'
        ];
        return '${fullMonths[dt.month - 1]} ${dt.day}, ${dt.year}';
      }
    } catch (_) {}
    return dateStr.replaceAll('-', ' ').toUpperCase();
  }

  Future<Map<String, String>?> _resolveActiveMasterDossier() async {
    final String sport = widget.selectedSport ?? 'NCAAF';
    final String mode = widget.selectedMode ?? 'PROSPECTIVE';
    final String sportKey = sport.toLowerCase();
    final List<String> candidateKeys = [
      'pdf_url',
      'dossier_pdf_url',
      'dossier_url',
      'pdf_link',
      'dossier_pdf',
      'url',
      'pdf',
      'download_url',
      'file_url'
    ];

    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('dossiers').get();

      if (widget.selectedDossierDocId != null) {
        for (var doc in querySnapshot.docs) {
          if (doc.id.toLowerCase() ==
              widget.selectedDossierDocId!.toLowerCase()) {
            final data = doc.data();
            for (var k in candidateKeys) {
              if (data.containsKey(k) && data[k] != null) {
                final sanitized = _sanitizeUrl(data[k].toString());
                if (sanitized.isNotEmpty) {
                  return {
                    'url': sanitized,
                    'docId': doc.id,
                    'label': 'MASTER DOSSIER ($sport • $mode)'
                  };
                }
              }
            }
          }
        }
      }

      for (var doc in querySnapshot.docs) {
        final docId = doc.id.toLowerCase();
        if (docId.contains(sportKey) &&
            docId.contains('latest') &&
            _isDocMatchingMode(docId, mode)) {
          if (!docId.contains('master')) continue;
          final data = doc.data();
          for (var k in candidateKeys) {
            if (data.containsKey(k) && data[k] != null) {
              final sanitized = _sanitizeUrl(data[k].toString());
              if (sanitized.isNotEmpty) {
                return {
                  'url': sanitized,
                  'docId': doc.id,
                  'label': 'MASTER DOSSIER ($sport • $mode)'
                };
              }
            }
          }
        }
      }
    } catch (_) {}

    if (widget.dossierUrl != null && widget.dossierUrl!.isNotEmpty) {
      final clean = _sanitizeUrl(widget.dossierUrl!);
      final fallbackDocId = mode == 'AUDIT'
          ? (sport == 'MLB'
              ? 'mlb_eod_master_latest'
              : 'ncaaf_eow_master_latest')
          : (sport == 'MLB' ? 'mlb_master_latest' : 'ncaaf_master_latest');
      return {
        'url': clean,
        'docId': fallbackDocId,
        'label': 'MASTER DOSSIER ($sport • $mode)'
      };
    }
    return null;
  }

  Future<void> _accessDossierSmartCache({
    required BuildContext context,
    required String pdfUrl,
    required String docId,
    required String titleLabel,
  }) async {
    final String cleanUrl = _sanitizeUrl(pdfUrl);
    if (cleanUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Compiling $titleLabel... Please check connection.'),
        backgroundColor: const Color(0xFFFF5E00),
        duration: const Duration(seconds: 3),
      ));
      return;
    }

    if (kIsWeb) {
      await launchURL(cleanUrl);
      return;
    }

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String urlSignature = cleanUrl.hashCode.abs().toString();
      final String cleanDocKey =
          docId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final String filePath = '${appDir.path}/${cleanDocKey}_$urlSignature.pdf';
      final File localFile = File(filePath);

      if (await localFile.exists() && (await localFile.length()) > 1024) {
        OpenResult openRes = await OpenFilex.open(localFile.path);
        if (openRes.type != ResultType.done) {
          await launchURL(cleanUrl);
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                '⚡ Instant Edge Access: Loaded directly from local device storage.'),
            backgroundColor: Color(0xFF00F5D4),
            duration: Duration(seconds: 3),
          ));
        }
        return;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('📥 Downloading $titleLabel to device storage...'),
          backgroundColor: const Color(0xFFFF5E00),
          duration: const Duration(seconds: 2),
        ));
      }

      final response = await http.get(Uri.parse(cleanUrl));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await localFile.writeAsBytes(response.bodyBytes, flush: true);
        OpenResult openRes = await OpenFilex.open(localFile.path);
        if (openRes.type != ResultType.done) {
          await launchURL(cleanUrl);
        }
      } else {
        await launchURL(cleanUrl);
      }
    } catch (_) {
      await launchURL(cleanUrl);
    }
  }

  // --- GUARANTEED WEEK / DATE RESOLUTION (WEEK 6 CANNOT BE DROPPED) ---
  Future<void> _showWeekSelectorModal(BuildContext context) async {
    final String sport = widget.selectedSport ?? 'NCAAF';
    final String mode = widget.selectedMode ?? 'PROSPECTIVE';
    final String sportKey = sport.toLowerCase();
    final bool isAudit = (mode == 'AUDIT');
    final List<String> candidateKeys = [
      'pdf_url',
      'dossier_pdf_url',
      'dossier_url',
      'pdf_link',
      'dossier_pdf',
      'pdf',
      'url',
      'download_url',
      'file_url',
      'media_link'
    ];

    List<Map<String, dynamic>> rawList = [];

    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('dossiers').get();

      for (var doc in querySnapshot.docs) {
        final docId = doc.id.toLowerCase();

        if (!docId.contains(sportKey)) continue;
        if (!docId.contains('master')) continue;

        final bool isDocAudit = docId.contains('eod') ||
            docId.contains('eow') ||
            docId.contains('audit');
        if (isAudit != isDocAudit) continue;

        final data = doc.data();
        String cleanUrl = '';
        for (var k in candidateKeys) {
          if (data.containsKey(k) && data[k] != null) {
            final u = _sanitizeUrl(data[k].toString());
            if (u.isNotEmpty) {
              cleanUrl = u;
              break;
            }
          }
        }

        if (cleanUrl.isEmpty) {
          for (var entry in data.entries) {
            final valStr = entry.value?.toString().trim() ?? '';
            if (valStr.startsWith('http') ||
                valStr.startsWith('gs://') ||
                valStr.toLowerCase().contains('.pdf')) {
              cleanUrl = _sanitizeUrl(valStr);
              if (cleanUrl.isNotEmpty) break;
            }
          }
        }

        if (sport == 'NCAAF') {
          if (docId.contains('date_')) continue;

          final weekNum = _extractNcaafWeek(docId, data, cleanUrl);
          if (weekNum != null) {
            rawList.add({
              'sort_val': weekNum,
              'label':
                  '🏈 NCAAF WEEK $weekNum MASTER ${isAudit ? "AUDIT" : "SLATE"}',
              'url': cleanUrl,
              'docId': doc.id,
            });
          }
        } else {
          final dateStr = _extractMlbDate(docId, data, cleanUrl);
          if (dateStr != null && dateStr.isNotEmpty) {
            final formattedDate = _formatMlbDateDisplay(dateStr);
            final prefix =
                isAudit ? '⚾ MLB EOD MASTER SLATE —' : '⚾ MLB MASTER SLATE —';
            rawList.add({
              'sort_val': dateStr,
              'label': '$prefix $formattedDate',
              'url': cleanUrl,
              'docId': doc.id,
            });
          }
        }
      }
    } catch (_) {}

    // Sort descending: highest week number first for NCAAF, newest date first for MLB
    if (sport == 'NCAAF') {
      rawList.sort(
          (a, b) => (b['sort_val'] as int).compareTo(a['sort_val'] as int));
    } else {
      rawList.sort((a, b) =>
          (b['sort_val'] as String).compareTo(a['sort_val'] as String));
    }

    // Deduplicate strictly by sort_val (Week number or Calendar date)
    final List<Map<String, String>> modalList = [];
    final Set<dynamic> seenSorts = {};

    for (var item in rawList) {
      final sortKey = item['sort_val'];
      if (seenSorts.contains(sortKey)) continue;
      seenSorts.add(sortKey);
      modalList.add({
        'label': item['label'] as String,
        'url': item['url'] as String,
        'docId': item['docId'] as String,
      });
    }

    if (modalList.isEmpty) return;

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF182226),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (mContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('🗓️ SELECT $sport ($mode) MASTER SLATE',
                      style: const TextStyle(
                          color: Color(0xFF00F5D4),
                          fontSize: 11,
                          fontWeight: FontWeight.w900)),
                  IconButton(
                      icon: const Icon(Icons.close,
                          color: Color(0xFF8A99A6), size: 18),
                      onPressed: () => Navigator.pop(mContext)),
                ],
              ),
              const SizedBox(height: 10),
              ...modalList.take(4).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(mContext);
                        await _accessDossierSmartCache(
                            context: context,
                            pdfUrl: item['url']!,
                            docId: item['docId']!,
                            titleLabel: item['label']!);
                      },
                      icon: const Icon(Icons.flash_on,
                          color: Color(0xFFFF5E00), size: 16),
                      label: Text(item['label']!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B1114),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side:
                                  const BorderSide(color: Color(0xFF24343B)))),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF00F5D4),
                fontSize: 8,
                fontWeight: FontWeight.w800)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool subActive = widget.isSub ?? false;
    final String mode = widget.selectedMode ?? 'PROSPECTIVE';
    final String sport = widget.selectedSport ?? 'NCAAF';
    final int evals = widget.evalCount ?? 0;
    final int sweeps = widget.sweepsCount ?? 0;
    final double winPct = widget.winPercent ?? 0.0;
    final int pending = widget.pendingCount ?? 0;
    final int queued = widget.gamesQueuedCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mode == 'AUDIT') ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFF182226),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF5E5C9), width: 1.5)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildKpiItem(evals.toString(), 'EVAL'),
                _buildKpiItem(sweeps.toString(), 'SWEEPS'),
                _buildKpiItem('${winPct.toStringAsFixed(1)}%', 'WIN %'),
                _buildKpiItem(pending.toString(), 'PENDING'),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
                color: const Color(0xFF182226),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF00F5D4).withOpacity(0.6), width: 1)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎯 ', style: TextStyle(fontSize: 12)),
                Flexible(
                  child: Text(
                    'PROSPECTIVE $sport SIGNALS ($queued QUEUED)',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF00F5D4),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              '⭐ Tap star on any matchup to pin favorites to top',
              style: TextStyle(
                color: Color(0xFF8A99A6),
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Dossier Vault Button
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: subActive
                ? [
                    BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: GestureDetector(
            onLongPress: () async {
              if (!subActive) {
                await _triggerElectricHapticBuzz();
                widget.onUpgradeTapped?.call();
                return;
              }
              HapticFeedback.heavyImpact();
              _showWeekSelectorModal(context);
            },
            child: ElevatedButton(
              onPressed: () async {
                if (!subActive) {
                  await _triggerElectricHapticBuzz();
                  widget.onUpgradeTapped?.call();
                  return;
                }
                HapticFeedback.mediumImpact();
                final activeDossier = await _resolveActiveMasterDossier();
                if (activeDossier != null && activeDossier['url']!.isNotEmpty) {
                  await _accessDossierSmartCache(
                      context: context,
                      pdfUrl: activeDossier['url']!,
                      docId: activeDossier['docId']!,
                      titleLabel: activeDossier['label']!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Compiling $sport Master PDF... Please check connection.'),
                    backgroundColor: const Color(0xFFFF5E00),
                    duration: const Duration(seconds: 3),
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: subActive
                      ? const Color(0xFFD4AF37)
                      : const Color(0xFF24343B),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                          color: subActive
                              ? const Color(0xFFF3E5AB)
                              : const Color(0xFF8A99A6),
                          width: 1))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(subActive ? '📄 ' : '🔒 ',
                      style: const TextStyle(fontSize: 14)),
                  Text(
                    subActive
                        ? 'DOSSIER VAULT 🗞'
                        : 'UNLOCK ALL ACCESS (\$9.99/MO)',
                    style: TextStyle(
                        color:
                            subActive ? const Color(0xFF080C0E) : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (subActive) ...[
          const SizedBox(height: 4),
          const Text(
              '💡 Tap for Active Master PDF. Hold for past Master Slates.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF8A99A6),
                  fontSize: 9,
                  fontStyle: FontStyle.italic)),
        ],
      ],
    );
  }
}
