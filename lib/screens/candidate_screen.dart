import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/election_models.dart';
import '../services/election_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/election_banner.dart';
import '../widgets/page_header.dart';

class CandidateScreen extends StatefulWidget {
  final ElectionController controller;
  final Division division;

  const CandidateScreen({
    super.key,
    required this.controller,
    required this.division,
  });

  @override
  State<CandidateScreen> createState() => _CandidateScreenState();
}

class _CandidateScreenState extends State<CandidateScreen> {
  bool fullscreen = false;

  ElectionController get controller => widget.controller;

  Division get division => widget.division;

  // ===========================================================================
  // FULLSCREEN
  // ===========================================================================

  Future<void> enterFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    if (mounted) {
      setState(() {
        fullscreen = true;
      });
    }
  }

  Future<void> exitFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    if (mounted) {
      setState(() {
        fullscreen = false;
      });
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final list = controller.candidatesFor(
          division.id,
        );

        return Scaffold(
          backgroundColor: ballotBg,
          appBar: fullscreen
              ? null
              : ElectionPageHeader(
                  onFullscreen: enterFullscreen,
                ),
          body: Stack(
            children: [
              list.isEmpty
                  ? const EmptyState(
                      title: 'No candidates yet',
                      subtitle: 'Candidates can be added from Control.',
                    )
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 820,
                        ),
                        child: _ballot(list),
                      ),
                    ),

              // ---------------------------------------------------------------
              // DEVELOPER CREDIT — FIXED AT THE BOTTOM OF THE SCREEN
              // ---------------------------------------------------------------

              Positioned(
                left: 14,
                right: 14,
                bottom: fullscreen ? 12 : 14,
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.96),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE3EAF2),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF0F4B04),
                          size: 17,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Developed By Shahabas M',
                          style: TextStyle(
                            color: Color(0xFF121315),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ---------------------------------------------------------------
              // FULLSCREEN CLOSE
              // ---------------------------------------------------------------

              if (fullscreen)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.white.withOpacity(.94),
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: IconButton(
                      tooltip: 'Exit fullscreen',
                      onPressed: exitFullscreen,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: navy,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // BALLOT
  // ===========================================================================

  Widget _ballot(
    List<Candidate> list,
  ) {
    final target = '${division.className}${division.section}';

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        fullscreen ? 12 : 14,
        fullscreen ? 12 : 14,
        fullscreen ? 12 : 14,
        fullscreen ? 26 : 30,
      ),
      children: [
        // =====================================================================
        // ELECTION BANNER
        // =====================================================================

        ElectionBanner(
          voteFor: target,
          height: fullscreen ? 126 : 138,
        ),

        const SizedBox(
          height: 50,
        ),

        // =====================================================================
        // EVM CABINET
        // =====================================================================

        _evmCabinet(list),

        const SizedBox(
          height: 14,
        ),

        // =====================================================================
        // VIEW RESULTS
        // =====================================================================

        OutlinedButton.icon(
          onPressed: _openProtectedResults,
          icon: const Icon(
            Icons.bar_chart_rounded,
          ),
          label: Text(
            'VIEW RESULTS',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: .5,
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(
              54,
            ),
            side: const BorderSide(
              color: Color(0xFF70767C),
              width: 1.6,
            ),
            foregroundColor: navy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  // ===========================================================================
  // EVM CABINET
  // ===========================================================================

  Widget _evmCabinet(
    List<Candidate> list,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: ballotPanel,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: const Color(0xFF7C8389),
          width: 2.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 10,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          _cabinetTop(
            list.length,
          ),
          ...list.asMap().entries.map(
            (entry) {
              return EvmCandidateRow(
                controller: controller,
                candidate: entry.value,
                student: controller.student(
                  entry.value.studentId,
                ),
                division: division,
                last: entry.key == list.length - 1,
              );
            },
          ),
          _cabinetBottom(),
        ],
      ),
    );
  }

  // ===========================================================================
  // CABINET TOP
  // ===========================================================================

  Widget _cabinetTop(
    int count,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        12,
        11,
      ),
      decoration: const BoxDecoration(
        color: ballotHeader,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            15,
          ),
        ),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF8A9095),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: ballotGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ballotGreen.withOpacity(
                    .55,
                  ),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 9,
          ),
          Expanded(
            child: Text(
              'BALLOT UNIT',
              style: GoogleFonts.poppins(
                color: const Color(
                  0xFF40474D,
                ),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Text(
            '$count CANDIDATE${count == 1 ? '' : 'S'}',
            style: GoogleFonts.poppins(
              color: const Color(
                0xFF596168,
              ),
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CABINET BOTTOM
  // ===========================================================================

  Widget _cabinetBottom() {
    return Container(
      height: 18,
      decoration: const BoxDecoration(
        color: Color(0xFFB8BDC1),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(15),
        ),
        border: Border(
          top: BorderSide(
            color: Color(0xFF92989D),
            width: 1.3,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PROTECTED RESULTS
  // ===========================================================================

  Future<void> _openProtectedResults() async {
    final unlocked = await _showPasswordDialog();

    if (!mounted) return;

    if (unlocked == true) {
      await _showResultsDialog();
    }
  }

  // ===========================================================================
  // PASSWORD DIALOG
  // ===========================================================================

  Future<bool?> _showPasswordDialog() async {
    final passwordController = TextEditingController();

    try {
      return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          bool obscure = true;
          String? errorText;
          bool checking = false;

          Future<void> submit(StateSetter setDialogState) async {
            if (checking) return;

            final password = passwordController.text.trim();

            if (password.length != 5) {
              setDialogState(() {
                errorText = 'Enter the 5-digit password';
              });
              return;
            }

            setDialogState(() {
              checking = true;
              errorText = null;
            });

            await Future<void>.delayed(
              const Duration(milliseconds: 120),
            );

            if (password == '20007') {
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop(true);
              }
              return;
            }

            if (!dialogContext.mounted) return;

            setDialogState(() {
              checking = false;
              errorText = 'Incorrect password';
            });

            passwordController.clear();
          }

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 24,
                ),
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 390,
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    22,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F0F8),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 30,
                        offset: Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFDDE0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: Color(0xFFE5484D),
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Results Access',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF202027),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: passwordController,
                        autofocus: true,
                        enabled: !checking,
                        obscureText: obscure,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        maxLength: 5,
                        onSubmitted: (_) => submit(setDialogState),
                        decoration: InputDecoration(
                          labelText: 'Enter results password',
                          labelStyle: GoogleFonts.poppins(
                            color: const Color(0xFF49669D),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFFF8F7FC),
                          prefixIcon: const Icon(
                            Icons.password_rounded,
                            color: Color(0xFF555A63),
                          ),
                          suffixIcon: IconButton(
                            tooltip:
                                obscure ? 'Show password' : 'Hide password',
                            onPressed: checking
                                ? null
                                : () {
                                    setDialogState(() {
                                      obscure = !obscure;
                                    });
                                  },
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              color: const Color(0xFF4C5159),
                            ),
                          ),
                          errorText: errorText,
                          errorStyle: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 17,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Color(0xFF8C929A),
                              width: 1.4,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Color(0xFF247BFF),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5484D),
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5484D),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: checking
                                ? null
                                : () => Navigator.of(dialogContext).pop(false),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF49669D),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 13,
                              ),
                            ),
                            child: Text(
                              'CANCEL',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed:
                                checking ? null : () => submit(setDialogState),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE5484D),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFB9B9BE),
                              minimumSize: const Size(128, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              checking ? 'CHECKING...' : 'CONTINUE',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      passwordController.dispose();
    }
  }

  // ===========================================================================
  // RESULTS DIALOG
  // ===========================================================================

  Future<void> _showResultsDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AnimatedBuilder(
          animation: controller,
          builder: (
            context,
            _,
          ) {
            final list = controller.candidatesFor(
              division.id,
            );

            final sorted = [...list];

            sorted.sort(
              (a, b) => b.votes.compareTo(
                a.votes,
              ),
            );

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.fromLTRB(
                14,
                22,
                14,
                22,
              ),
              child: _ResultsPopup(
                controller: controller,
                division: division,
                candidates: sorted,
                onClose: () {
                  Navigator.of(
                    dialogContext,
                  ).pop();
                },
                onPdf: () {
                  _generatePdf(
                    division,
                    sorted,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // PDF
  // ===========================================================================

  Future<void> _generatePdf(
    Division division,
    List<Candidate> candidates,
  ) async {
    final pdf = pw.Document();

    final target = '${division.className}${division.section}';

    final winner = candidates.isEmpty ||
            candidates.first.votes <= 0 ||
            (candidates.length >= 2 &&
                candidates.first.votes == candidates[1].votes)
        ? null
        : candidates.first;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(
          32,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'GHSS EVM',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(
                height: 3,
              ),
              pw.Text(
                'GHSS MEZHATHUR',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(
                height: 20,
              ),
              pw.Text(
                'ELECTION RESULTS',
                style: pw.TextStyle(
                  fontSize: 19,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(
                height: 5,
              ),
              pw.Text(
                'Class $target',
                style: const pw.TextStyle(
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(
                height: 16,
              ),
              if (candidates.length >= 2)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    candidates.first.votes == candidates[1].votes
                        ? 'TIED RESULT: ${candidates.first.votes} - ${candidates[1].votes}'
                        : 'LEAD: ${candidates.first.votes - candidates[1].votes} votes | ${controller.student(candidates.first.studentId)?.name ?? 'Unknown student'} vs ${controller.student(candidates[1].studentId)?.name ?? 'Unknown student'}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              pw.SizedBox(height: 12),
              if (winner != null)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(
                    13,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColors.grey400,
                    ),
                    borderRadius: pw.BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'WINNER',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(
                        width: 12,
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          controller
                                  .student(
                                    winner.studentId,
                                  )
                                  ?.name ??
                              'Unknown student',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Text(
                        '${winner.votes} votes',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              pw.SizedBox(
                height: 16,
              ),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                ),
                columnWidths: const {
                  0: pw.FixedColumnWidth(
                    42,
                  ),
                  1: pw.FlexColumnWidth(),
                  2: pw.FixedColumnWidth(
                    75,
                  ),
                },
                children: [
                  pw.TableRow(
                    children: [
                      _pdfCell(
                        '#',
                        bold: true,
                      ),
                      _pdfCell(
                        'Student',
                        bold: true,
                      ),
                      _pdfCell(
                        'Votes',
                        bold: true,
                      ),
                    ],
                  ),
                  ...candidates.asMap().entries.map(
                    (entry) {
                      final candidate = entry.value;

                      final student = controller.student(
                        candidate.studentId,
                      );

                      return pw.TableRow(
                        children: [
                          _pdfCell(
                            '${entry.key + 1}',
                          ),
                          _pdfCell(
                            student?.name ?? 'Unknown student',
                          ),
                          _pdfCell(
                            '${candidate.votes}',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Text(
                'Generated by GHSS EVM',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async {
        return pdf.save();
      },
    );
  }

  pw.Widget _pdfCell(
    String text, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(
        7,
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}

// ============================================================================
// RESULTS POPUP
// ============================================================================

class _ResultsPopup extends StatelessWidget {
  final ElectionController controller;
  final Division division;
  final List<Candidate> candidates;
  final VoidCallback onClose;
  final VoidCallback onPdf;

  const _ResultsPopup({
    required this.controller,
    required this.division,
    required this.candidates,
    required this.onClose,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    final winner = candidates.isEmpty ? null : candidates.first;

    final winnerStudent = winner == null
        ? null
        : controller.student(
            winner.studentId,
          );

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 470,
        maxHeight: 720,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F1),
        borderRadius: BorderRadius.circular(
          25,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 35,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ===================================================================
          // POPUP HEADER
          // ===================================================================

          Container(
            padding: const EdgeInsets.fromLTRB(
              18,
              15,
              10,
              13,
            ),
            decoration: const BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(
                  25,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                      .10,
                    ),
                    borderRadius: BorderRadius.circular(
                      11,
                    ),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ELECTION RESULTS',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .7,
                        ),
                      ),
                      Text(
                        'Class ${division.className} • Division ${division.section}',
                        style: GoogleFonts.poppins(
                          color: const Color(
                            0xB8FFFFFF,
                          ),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: 21,
                  ),
                ),
              ],
            ),
          ),

          // ===================================================================
          // BODY
          // ===================================================================

          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                14,
                14,
                14,
                8,
              ),
              child: Column(
                children: [
                  // ===========================================================
                  // GRAPHICAL WINNER CARD
                  // ===========================================================

                  if (winner != null &&
                      winner.votes > 0 &&
                      (candidates.length == 1 ||
                          winner.votes > candidates[1].votes))
                    _WinnerResultCard(
                      name: winnerStudent?.name ?? 'Unknown student',
                      votes: winner.votes,
                      division: division,
                    ),

                  if (candidates.length >= 2) ...[
                    const SizedBox(height: 10),
                    _LeadSummary(
                      leader: candidates[0],
                      runnerUp: candidates[1],
                      leaderName:
                          controller.student(candidates[0].studentId)?.name ??
                              'Unknown student',
                      runnerUpName:
                          controller.student(candidates[1].studentId)?.name ??
                              'Unknown student',
                    ),
                  ],

                  const SizedBox(
                    height: 12,
                  ),

                  // ===========================================================
                  // RESULT LIST
                  // ===========================================================

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'STUDENT RESULTS',
                      style: GoogleFonts.poppins(
                        color: const Color(
                          0xFF6C7379,
                        ),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  ...candidates.asMap().entries.map(
                    (entry) {
                      final candidate = entry.value;

                      final student = controller.student(
                        candidate.studentId,
                      );

                      final hasWinner = candidates.isNotEmpty &&
                          candidates.first.votes > 0 &&
                          (candidates.length == 1 ||
                              candidates.first.votes > candidates[1].votes);

                      final isWinner = entry.key == 0 && hasWinner;

                      return _ResultStudentRow(
                        name: student?.name ?? 'Unknown student',
                        votes: candidate.votes,
                        rank: entry.key + 1,
                        winner: isWinner,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ===================================================================
          // PDF BUTTON
          // ===================================================================

          Container(
            padding: const EdgeInsets.fromLTRB(
              14,
              8,
              14,
              14,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(
                  25,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 49,
              child: ElevatedButton.icon(
                onPressed: candidates.isEmpty ? null : onPdf,
                icon: const Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 18,
                ),
                label: Text(
                  'EXPORT RESULTS PDF',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .4,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  disabledBackgroundColor: const Color(
                    0xFFD5D9DD,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// GRAPHICAL WINNER CARD
// ============================================================================

class _WinnerResultCard extends StatelessWidget {
  final String name;
  final int votes;
  final Division division;

  const _WinnerResultCard({
    required this.name,
    required this.votes,
    required this.division,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 7,
      shadowColor: const Color(0x55000000),
      borderRadius: BorderRadius.circular(
        18,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          18,
        ),
        child: Container(
          height: 108,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF3DE),
          ),
          child: Stack(
            children: [
              // ===============================================================
              // RED SHAPE
              // ===============================================================

              Positioned(
                right: -28,
                top: -58,
                child: Container(
                  width: 190,
                  height: 125,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF3C5B),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(
                        100,
                      ),
                    ),
                  ),
                ),
              ),

              // ===============================================================
              // BLUE SHAPE
              // ===============================================================

              Positioned(
                left: -30,
                bottom: -60,
                child: Container(
                  width: 165,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2375E8),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(
                        90,
                      ),
                    ),
                  ),
                ),
              ),

              // ===============================================================
              // YELLOW SHAPE
              // ===============================================================

              Positioned(
                right: -25,
                bottom: -17,
                child: Transform.rotate(
                  angle: -0.10,
                  child: Container(
                    width: 150,
                    height: 52,
                    color: const Color(
                      0xFFFFC928,
                    ),
                  ),
                ),
              ),

              // ===============================================================
              // TOP DOTS
              // ===============================================================

              Positioned(
                left: 12,
                top: 10,
                child: Row(
                  children: [
                    _smallDot(
                      const Color(
                        0xFFEF3C5B,
                      ),
                    ),
                    const SizedBox(
                      width: 6,
                    ),
                    _smallDot(
                      const Color(
                        0xFF2375E8,
                      ),
                    ),
                    const SizedBox(
                      width: 6,
                    ),
                    _smallDot(
                      const Color(
                        0xFFFFC928,
                      ),
                    ),
                  ],
                ),
              ),

              // ===============================================================
              // TROPHY
              // ===============================================================

              Positioned(
                left: 13,
                bottom: 12,
                child: Container(
                  width: 59,
                  height: 59,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFFD76A,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(
                        0xFF102A43,
                      ),
                      width: 2.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(
                          0x18000000,
                        ),
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFF54207D),
                    size: 31,
                  ),
                ),
              ),

              // ===============================================================
              // CENTER WINNER
              // ===============================================================

              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    72,
                    7,
                    72,
                    7,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // -------------------------------------------------------
                      // WINNER LABEL
                      // -------------------------------------------------------

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF102A43,
                          ),
                          borderRadius: BorderRadius.circular(
                            5,
                          ),
                        ),
                        child: Text(
                          'WINNER',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 6.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      // -------------------------------------------------------
                      // WINNER NAME
                      // -------------------------------------------------------

                      Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.3,
                        ),
                      ),

                      const SizedBox(
                        height: 1,
                      ),

                      // -------------------------------------------------------
                      // VOTES
                      // -------------------------------------------------------

                      Text(
                        '$votes VOTES',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: const Color(
                            0xFF172B4D,
                          ),
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ===============================================================
              // CLASS LABEL
              // ===============================================================

              Positioned(
                right: 11,
                bottom: 8,
                child: Transform.rotate(
                  angle: -0.03,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFFFD45A,
                      ),
                      borderRadius: BorderRadius.circular(
                        4,
                      ),
                    ),
                    child: Text(
                      'CLASS ${division.className}${division.section}',
                      style: GoogleFonts.poppins(
                        color: const Color(
                          0xFF102A43,
                        ),
                        fontSize: 6,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _smallDot(
    Color color,
  ) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ============================================================================
// LEAD SUMMARY
// ============================================================================

class _LeadSummary extends StatelessWidget {
  final Candidate leader;
  final Candidate runnerUp;
  final String leaderName;
  final String runnerUpName;

  const _LeadSummary({
    required this.leader,
    required this.runnerUp,
    required this.leaderName,
    required this.runnerUpName,
  });

  @override
  Widget build(BuildContext context) {
    final tied = leader.votes == runnerUp.votes;
    final lead = leader.votes - runnerUp.votes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tied ? const Color(0xFFF4F1F8) : const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tied ? const Color(0xFFD8D0E2) : const Color(0xFFBCD7FA),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                tied ? Icons.compare_arrows_rounded : Icons.trending_up_rounded,
                color: tied ? const Color(0xFF705A83) : const Color(0xFF247BFF),
                size: 19,
              ),
              const SizedBox(width: 7),
              Text(
                tied ? 'TIED RESULT' : 'CURRENT LEAD',
                style: GoogleFonts.poppins(
                  color:
                      tied ? const Color(0xFF705A83) : const Color(0xFF247BFF),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .9,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tied ? 'TIED' : '+$lead LEAD',
                  style: GoogleFonts.poppins(
                    color: tied
                        ? const Color(0xFF705A83)
                        : const Color(0xFF102A43),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _LeadCandidateBox(
                  label: '1ST',
                  name: leaderName,
                  votes: leader.votes,
                  emphasized: !tied,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'VS',
                style: TextStyle(
                  color: Color(0xFF7C858D),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LeadCandidateBox(
                  label: '2ND',
                  name: runnerUpName,
                  votes: runnerUp.votes,
                  emphasized: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeadCandidateBox extends StatelessWidget {
  final String label;
  final String name;
  final int votes;
  final bool emphasized;

  const _LeadCandidateBox({
    required this.label,
    required this.name,
    required this.votes,
    required this.emphasized,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: emphasized ? const Color(0xFF8FBDF5) : const Color(0xFFE0E3E6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: emphasized
                  ? const Color(0xFFEAF3FF)
                  : const Color(0xFFF0F2F4),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: emphasized
                    ? const Color(0xFF247BFF)
                    : const Color(0xFF6E767D),
                fontSize: 7,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF172B4D),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$votes votes',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF7C858D),
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RESULT STUDENT ROW
// ============================================================================

class _ResultStudentRow extends StatelessWidget {
  final String name;
  final int votes;
  final int rank;
  final bool winner;

  const _ResultStudentRow({
    required this.name,
    required this.votes,
    required this.rank,
    required this.winner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 7,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: winner
              ? const Color(
                  0xFFE0C15A,
                )
              : const Color(
                  0xFFE0E3E6,
                ),
          width: winner ? 1.3 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // -------------------------------------------------------------------
          // RANK
          // -------------------------------------------------------------------

          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: winner
                  ? const Color(
                      0xFFFFF1C5,
                    )
                  : const Color(
                      0xFFF0F2F4,
                    ),
              borderRadius: BorderRadius.circular(
                7,
              ),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: GoogleFonts.poppins(
                  color: winner
                      ? const Color(
                          0xFF866600,
                        )
                      : const Color(
                          0xFF6E767D,
                        ),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          // -------------------------------------------------------------------
          // NAME
          // -------------------------------------------------------------------

          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: const Color(
                  0xFF101820,
                ),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // -------------------------------------------------------------------
          // VOTES
          // -------------------------------------------------------------------

          Text(
            '$votes',
            style: GoogleFonts.poppins(
              color: winner
                  ? const Color(
                      0xFF856600,
                    )
                  : const Color(
                      0xFF102A43,
                    ),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(
            width: 4,
          ),

          Text(
            'votes',
            style: GoogleFonts.poppins(
              color: const Color(
                0xFF8A9298,
              ),
              fontSize: 7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EVM CANDIDATE ROW
// ============================================================================

class EvmCandidateRow extends StatefulWidget {
  final ElectionController controller;
  final Candidate candidate;
  final Student? student;
  final Division division;
  final bool last;

  const EvmCandidateRow({
    super.key,
    required this.controller,
    required this.candidate,
    required this.student,
    required this.division,
    required this.last,
  });

  @override
  State<EvmCandidateRow> createState() => _EvmCandidateRowState();
}

class _EvmCandidateRowState extends State<EvmCandidateRow> {
  bool active = false;

  // ===========================================================================
  // VOTE
  // ===========================================================================

  Future<void> vote() async {
    if (widget.student == null || active || widget.controller.isVoting) {
      return;
    }

    setState(() {
      active = true;
    });

    try {
      await widget.controller.vote(
        widget.candidate.id,
        widget.division.id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vote could not be saved: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          active = false;
        });
      }
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final disabled =
        widget.student == null || active || widget.controller.isVoting;

    final buttonColor = active ? ballotGreen : ballotBlue;

    return Container(
      constraints: const BoxConstraints(
        minHeight: 92,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: ballotPaper,
        border: Border(
          bottom: widget.last
              ? BorderSide.none
              : const BorderSide(
                  color: Color(0xFFC0C4C8),
                  width: 1.2,
                ),
        ),
      ),
      child: Row(
        children: [
          // -------------------------------------------------------------------
          // PHOTO
          // -------------------------------------------------------------------

          StudentPhoto(
            student: widget.student,
            size: 54,
          ),

          const SizedBox(
            width: 10,
          ),

          // -------------------------------------------------------------------
          // NAME
          // -------------------------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.student?.name ?? 'Unknown student',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: active ? ballotGreen : textDark,
                    fontSize: 13,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  'CLASS ${widget.division.className}${widget.division.section}',
                  style: GoogleFonts.poppins(
                    color: const Color(
                      0xFF777D82,
                    ),
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .7,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 7,
          ),

          // -------------------------------------------------------------------
          // BUTTON + LED
          // -------------------------------------------------------------------

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(
                0xFFD8DADC,
              ),
              borderRadius: BorderRadius.circular(
                8,
              ),
              border: Border.all(
                color: const Color(
                  0xFFA7ADB2,
                ),
                width: 1.1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: disabled ? null : vote,
                    borderRadius: BorderRadius.circular(
                      5,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 140,
                      ),
                      width: 102,
                      height: 52,
                      decoration: BoxDecoration(
                        color: disabled
                            ? buttonColor.withOpacity(
                                .52,
                              )
                            : buttonColor,
                        borderRadius: BorderRadius.circular(
                          5,
                        ),
                        border: Border.all(
                          color: const Color(
                            0xFF15191C,
                          ),
                          width: 1.8,
                        ),
                        boxShadow: disabled
                            ? const []
                            : const [
                                BoxShadow(
                                  color: Color(
                                    0x44000000,
                                  ),
                                  blurRadius: 5,
                                  offset: Offset(
                                    0,
                                    3,
                                  ),
                                ),
                              ],
                      ),
                      child: Center(
                        child: Text(
                          active ? 'VOTED' : 'VOTE',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 7,
                ),
                AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 140,
                  ),
                  width: 17,
                  height: 17,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? ballotGreen : ballotRed,
                    border: Border.all(
                      color: const Color(
                        0xFF6F767C,
                      ),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (active ? ballotGreen : ballotRed).withOpacity(
                          .45,
                        ),
                        blurRadius: 6,
                        spreadRadius: .5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
