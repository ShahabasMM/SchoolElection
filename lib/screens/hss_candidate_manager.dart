import 'package:flutter/material.dart';

import '../models/election_models.dart';
import '../services/election_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/common.dart';

class HssCandidateManager extends StatefulWidget {
  final ElectionController controller;
  final HssStream stream;
  final Division division;

  const HssCandidateManager({
    super.key,
    required this.controller,
    required this.stream,
    required this.division,
  });

  @override
  State<HssCandidateManager> createState() => _HssCandidateManagerState();
}

class _HssCandidateManagerState extends State<HssCandidateManager> {
  Future<void> _delete(Candidate candidate, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete candidate?'),
        content: Text('Remove $name from this HSS group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await widget.controller.removeCandidate(candidate.id);
    }
  }

  Future<void> _addCandidate() async {
    final nameController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            15,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Add HSS Candidate',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: navy,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _groupLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Student name',
                  hintText: 'Enter candidate name',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final added =
                        await widget.controller.addCandidateByName(
                      name: name,
                      className: widget.division.className,
                      divisionId: widget.division.id,
                      section: widget.division.section,
                    );

                    if (!sheetContext.mounted) return;

                    if (!added) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Already a candidate in this group.'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(sheetContext);
                  },
                  child: const Text(
                    'ADD CANDIDATE',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    nameController.dispose();
  }

  String get _groupLabel {
    final batch = widget.stream.hasBatches
        ? widget.division.section
            .replaceFirst('${widget.stream.stream} • ', '')
        : null;

    if (batch == null || batch.isEmpty) {
      return '${widget.stream.className} • ${widget.stream.stream}';
    }

    return '${widget.stream.className} • ${widget.stream.stream} • $batch';
  }

  @override
  Widget build(BuildContext context) {
    return ElectionScaffold(
      navIndex: 1,
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final candidates =
              widget.controller.candidatesFor(widget.division.id);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8EC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE7D6B7),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.stream.className} • ${widget.stream.stream}',
                        style: const TextStyle(
                          color: navy,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.stream.hasBatches
                            ? widget.division.section
                            : 'Direct voting',
                        style: const TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: candidates.isEmpty
                    ? const EmptyState(
                        title: 'No candidates',
                        subtitle:
                            'Tap ADD CANDIDATE to add a student candidate.',
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          5,
                          16,
                          105,
                        ),
                        itemCount: candidates.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 9),
                        itemBuilder: (_, index) {
                          final candidate = candidates[index];
                          final student = widget.controller.student(
                            candidate.studentId,
                          );

                          return ManageRow(
                            photo: StudentPhoto(
                              student: student,
                              size: 50,
                            ),
                            title: student?.name ?? 'Unknown student',
                            subtitle: _groupLabel,
                            onDelete: () => _delete(
                              candidate,
                              student?.name ?? 'this candidate',
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCandidate,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('ADD CANDIDATE'),
      ),
    );
  }
}
