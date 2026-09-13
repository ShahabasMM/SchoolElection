import 'package:flutter/material.dart';

import '../models/election_models.dart';
import '../services/election_controller.dart';
import '../widgets/app_scaffold.dart';
import 'candidate_manager.dart';
import 'division_manager.dart';
import 'hss_manager.dart';

class ControlScreen extends StatelessWidget {
  final ElectionController controller;

  const ControlScreen({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ElectionScaffold(
      navIndex: 1,
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONTROL CENTER',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF102A43),
                            letterSpacing: .5,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Manage your election',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: controller.isRealtimeConnected
                          ? const Color(0xFFE7F8EF)
                          : const Color(0xFFFFF3D8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: controller.isRealtimeConnected
                            ? const Color(0xFFB9E6CC)
                            : const Color(0xFFEACF8A),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: controller.isRealtimeConnected
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFD18A00),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          controller.isRealtimeConnected ? 'LIVE' : 'OFFLINE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: controller.isRealtimeConnected
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFD18A00),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              _ControlTile(
                icon: Icons.how_to_vote_rounded,
                title: 'Manage Candidates',
                subtitle: 'Add or remove election candidates',
                accent: const Color(0xFF102A43),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CandidateManager(controller: controller),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _ControlTile(
                icon: Icons.grid_view_rounded,
                title: 'Manage Divisions',
                subtitle: 'Add or remove class divisions',
                accent: const Color(0xFF247BFF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DivisionManager(controller: controller),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _ControlTile(
                icon: Icons.account_tree_rounded,
                title: 'HSS Manage',
                subtitle: 'Manage +1 / +2 streams, batches and candidates',
                accent: const Color(0xFFE59A24),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HssManager(controller: controller),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _ControlTile(
                icon: Icons.restart_alt_rounded,
                title: 'Reset Votes',
                subtitle: 'Password protected • reset one class/division at a time',
                accent: const Color(0xFFE5484D),
                onTap: () => _openReset(context),
              ),
            ],
          );
        },
      ),
    );
  }

  static const String _resetPassword = '20007';

  Future<void> _openReset(BuildContext context) async {
    final passwordController = TextEditingController();

    try {
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          bool obscure = true;
          String? error;

          return StatefulBuilder(
            builder: (dialogContext, setState) {
              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.lock_rounded, color: Color(0xFFE5484D)),
                    SizedBox(width: 10),
                    Text(
                      'Reset Access',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 400,
                  child: TextField(
                    controller: passwordController,
                    autofocus: true,
                    obscureText: obscure,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) {
                      if (passwordController.text.trim() == _resetPassword) {
                        Navigator.pop(dialogContext, true);
                      } else {
                        setState(() => error = 'Incorrect password');
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Enter reset password',
                      prefixIcon: const Icon(Icons.password_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(
                          obscure
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                      ),
                      errorText: error,
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('CANCEL'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE5484D),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (passwordController.text.trim() == _resetPassword) {
                        Navigator.pop(dialogContext, true);
                      } else {
                        setState(() => error = 'Incorrect password');
                      }
                    },
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (ok != true || !context.mounted) return;
      await _showResetSelector(context);
    } finally {
      passwordController.dispose();
    }
  }

  Future<void> _showResetSelector(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _ResetSelectorDialog(
        controller: controller,
      ),
    );
  }
}

class _ResetSelectorDialog extends StatefulWidget {
  final ElectionController controller;

  const _ResetSelectorDialog({required this.controller});

  @override
  State<_ResetSelectorDialog> createState() => _ResetSelectorDialogState();
}

class _ResetSelectorDialogState extends State<_ResetSelectorDialog> {
  String? selectedClass;
  String? selectedDivisionId;
  String? selectedStreamId;
  String? selectedBatch;
  bool resetting = false;

  ElectionController get controller => widget.controller;

  List<Division> get regularDivisions {
    if (selectedClass == null) return const [];
    return controller.divisions
        .where((d) =>
            d.className == selectedClass &&
            !d.id.startsWith('hss_'))
        .toList();
  }

  List<HssStream> get hssStreams {
    if (selectedClass == null) return const [];
    return controller.hssStreamsFor(selectedClass!);
  }

  HssStream? get selectedStream {
    if (selectedStreamId == null) return null;
    for (final stream in hssStreams) {
      if (stream.id == selectedStreamId) return stream;
    }
    return null;
  }

  Division? get selectedHssDivision {
    final stream = selectedStream;
    if (stream == null) return null;
    if (!stream.hasBatches) {
      return controller.hssDirectDivision(stream);
    }
    if (selectedBatch == null) return null;
    return controller.hssBatchDivision(stream, selectedBatch!);
  }

  Division? get selectedTarget {
    if (selectedClass == '+1' || selectedClass == '+2') {
      return selectedHssDivision;
    }
    if (selectedDivisionId == null) return null;
    return controller.division(selectedDivisionId!);
  }

  void _changeClass(String? value) {
    setState(() {
      selectedClass = value;
      selectedDivisionId = null;
      selectedStreamId = null;
      selectedBatch = null;
    });
  }

  void _changeDivision(String? value) {
    setState(() => selectedDivisionId = value);
  }

  void _changeStream(String? value) {
    setState(() {
      selectedStreamId = value;
      selectedBatch = null;
    });
  }

  void _changeBatch(String? value) {
    setState(() => selectedBatch = value);
  }

  Future<void> _resetNow() async {
    final target = selectedTarget;
    if (target == null || resetting) return;

    final candidateCount = controller.candidates
        .where((candidate) => candidate.divisionId == target.id)
        .length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmContext) {
        return AlertDialog(
          title: const Text(
            'Confirm Reset',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Reset votes for ${target.className} • ${target.section}?\n\n'
            '$candidateCount candidate(s) will be set to 0.\n'
            'Candidates and divisions will NOT be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(confirmContext, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE5484D),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(confirmContext, true),
              child: const Text(
                'RESET NOW',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => resetting = true);
    try {
      await controller.resetVotesForDivision(target.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Votes reset: ${target.className} • ${target.section}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        resetting = false;
        selectedDivisionId = null;
        selectedStreamId = null;
        selectedBatch = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => resetting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not reset votes: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHss = selectedClass == '+1' || selectedClass == '+2';
    final stream = selectedStream;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.restart_alt_rounded, color: Color(0xFFE5484D)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'RESET VOTES',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select exactly what you want to reset.',
                style: TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'CLASS',
                style: TextStyle(
                  color: Color(0xFF102A43),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 7),
              DropdownButtonFormField<String>(
                value: selectedClass,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.school_rounded),
                  hintText: 'Select class',
                ),
                items: const [
                  DropdownMenuItem(value: '5', child: Text('Class 5')),
                  DropdownMenuItem(value: '6', child: Text('Class 6')),
                  DropdownMenuItem(value: '7', child: Text('Class 7')),
                  DropdownMenuItem(value: '8', child: Text('Class 8')),
                  DropdownMenuItem(value: '9', child: Text('Class 9')),
                  DropdownMenuItem(value: '10', child: Text('Class 10')),
                  DropdownMenuItem(value: '+1', child: Text('+1')),
                  DropdownMenuItem(value: '+2', child: Text('+2')),
                ],
                onChanged: resetting ? null : _changeClass,
              ),

              if (selectedClass != null) ...[
                const SizedBox(height: 16),
                if (!isHss) ...[
                  const Text(
                    'DIVISION',
                    style: TextStyle(
                      color: Color(0xFF102A43),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (regularDivisions.isEmpty)
                    _InfoBox(
                      icon: Icons.info_outline_rounded,
                      text: 'No divisions have been added for Class $selectedClass.',
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: selectedDivisionId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.grid_view_rounded),
                        hintText: 'Select division',
                      ),
                      items: regularDivisions
                          .map(
                            (division) => DropdownMenuItem<String>(
                              value: division.id,
                              child: Text(division.section),
                            ),
                          )
                          .toList(),
                      onChanged: resetting ? null : _changeDivision,
                    ),
                ] else ...[
                  const Text(
                    'STREAM',
                    style: TextStyle(
                      color: Color(0xFF102A43),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (hssStreams.isEmpty)
                    _InfoBox(
                      icon: Icons.info_outline_rounded,
                      text: 'No streams have been added for $selectedClass.',
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: selectedStreamId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.account_tree_rounded),
                        hintText: 'Select stream',
                      ),
                      items: hssStreams
                          .map(
                            (stream) => DropdownMenuItem<String>(
                              value: stream.id,
                              child: Text(stream.stream),
                            ),
                          )
                          .toList(),
                      onChanged: resetting ? null : _changeStream,
                    ),

                  if (stream != null && stream.hasBatches) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'BATCH',
                      style: TextStyle(
                        color: Color(0xFF102A43),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5,
                      ),
                    ),
                    const SizedBox(height: 7),
                    DropdownButtonFormField<String>(
                      value: selectedBatch,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.layers_rounded),
                        hintText: 'Select batch',
                      ),
                      items: stream.batches
                          .map(
                            (batch) => DropdownMenuItem<String>(
                              value: batch,
                              child: Text(batch),
                            ),
                          )
                          .toList(),
                      onChanged: resetting ? null : _changeBatch,
                    ),
                  ],
                ],

                if (selectedTarget != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFF3C4C6),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFE5484D),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Target: ${selectedTarget!.className} • ${selectedTarget!.section}',
                            style: const TextStyle(
                              color: Color(0xFF7B2529),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: resetting ? null : _resetNow,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE5484D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: resetting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.restart_alt_rounded),
                      label: Text(
                        resetting ? 'RESETTING...' : 'RESET NOW',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: resetting ? null : () => Navigator.pop(context),
          child: const Text('CLOSE'),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE3EAF2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: const Color(0xFF718096)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF718096),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _ControlTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE3EAF2)),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(.07),
                blurRadius: 15,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.09),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: accent, size: 25),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF172B4D),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: accent, size: 25),
            ],
          ),
        ),
      ),
    );
  }
}
