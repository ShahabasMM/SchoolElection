import 'package:flutter/material.dart';
import '../models/election_models.dart';
import '../services/election_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/common.dart';

class CandidateManager extends StatefulWidget {
  final ElectionController controller;
  const CandidateManager({super.key, required this.controller});
  @override State<CandidateManager> createState() => _CandidateManagerState();
}

class _CandidateManagerState extends State<CandidateManager> {
  String cls = '5';
  String? divId;

  List<Division> get divs => widget.controller.divisionsFor(int.parse(cls));

  @override
  void initState() {
    super.initState();
    final available = divs;
    divId = available.isEmpty ? null : available.first.id;
  }

  void changeClass(String value) {
    final available = widget.controller.divisionsFor(int.parse(value));
    setState(() {
      cls = value;
      divId = available.isEmpty ? null : available.first.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElectionScaffold(
      navIndex: 1,
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final currentDivisions = widget.controller.divisionsFor(int.parse(cls));
          String? selected = divId;
          if (!currentDivisions.any((division) => division.id == selected)) {
            selected = currentDivisions.isEmpty ? null : currentDivisions.first.id;
          }
          final current = selected == null ? null : widget.controller.division(selected);
          final candidates = current == null ? <Candidate>[] : widget.controller.candidatesFor(current.id);

          if (selected != divId && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => divId = selected);
            });
          }

          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(children: [
                Expanded(child: AppDropdown(value: cls, items: const ['5', '6', '7', '8', '9', '10'], labels: const ['Class 5', 'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'], onChanged: (v) { if (v != null) changeClass(v); })),
                const SizedBox(width: 9),
                Expanded(
                  child: currentDivisions.isEmpty
                      ? const SizedBox()
                      : AppDropdown(value: selected!, items: currentDivisions.map((x) => x.id).toList(), labels: currentDivisions.map((x) => 'Division ${x.section}').toList(), onChanged: (v) { if (v != null) setState(() => divId = v); }),
                ),
              ]),
            ),
            Expanded(
              child: current == null
                  ? const EmptyState(title: 'No divisions', subtitle: 'Add a division first from Control.')
                  : candidates.isEmpty
                      ? const EmptyState(title: 'No candidates', subtitle: 'Tap ADD CANDIDATE to add one.')
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 5, 16, 105),
                          itemCount: candidates.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 9),
                          itemBuilder: (_, index) {
                            final student = widget.controller.student(candidates[index].studentId);
                            return ManageRow(
                              photo: StudentPhoto(student: student, size: 50),
                              title: student?.name ?? 'Unknown student',
                              subtitle: 'Class ${current.className} • Division ${current.section}',
                              onDelete: () => _delete(candidates[index], student?.name),
                            );
                          },
                        ),
            ),
          ]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: const Text('ADD CANDIDATE')),
    );
  }

  Future<void> _delete(Candidate candidate, String? name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete candidate?'),
        content: Text('Remove ${name ?? 'this candidate'} from this division?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('CANCEL')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: red), onPressed: () => Navigator.pop(dialogContext, true), child: const Text('DELETE')),
        ],
      ),
    );
    if (ok == true) await widget.controller.removeCandidate(candidate.id);
  }

  Future<void> _add() async {
    String formClass = cls;
    String? formDivision = divId;
    final nameController = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final available = widget.controller.divisionsFor(int.parse(formClass));
              if (formDivision == null || !available.any((d) => d.id == formDivision)) {
                formDivision = available.isEmpty ? null : available.first.id;
              }

              return AlertDialog(
                title: const Text('Add Candidate'),
                content: SizedBox(
                  width: 430,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: formClass,
                          decoration: const InputDecoration(labelText: 'Class'),
                          items: const [
                            DropdownMenuItem(value: '5', child: Text('Class 5')),
                            DropdownMenuItem(value: '6', child: Text('Class 6')),
                            DropdownMenuItem(value: '7', child: Text('Class 7')),
                            DropdownMenuItem(value: '8', child: Text('Class 8')),
                            DropdownMenuItem(value: '9', child: Text('Class 9')),
                            DropdownMenuItem(value: '10', child: Text('Class 10')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            final next = widget.controller.divisionsFor(int.parse(value));
                            setDialogState(() {
                              formClass = value;
                              formDivision = next.isEmpty ? null : next.first.id;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        if (available.isNotEmpty)
                          DropdownButtonFormField<String>(
                            value: formDivision,
                            decoration: const InputDecoration(labelText: 'Division'),
                            items: available.map((d) => DropdownMenuItem(value: d.id, child: Text('Division ${d.section}'))).toList(),
                            onChanged: (value) => setDialogState(() => formDivision = value),
                          )
                        else
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('No divisions available for this class. Add a division first.'),
                          ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(labelText: 'Student name'),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
                  FilledButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final target = formDivision == null ? null : widget.controller.division(formDivision!);
                      if (name.isEmpty || target == null) return;
                      try {
                        final added = await widget.controller.addCandidateByName(
                          name: name,
                          className: target.className,
                          divisionId: target.id,
                          section: target.section,
                        );
                        if (!dialogContext.mounted) return;
                        if (!added) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Already a candidate in this division.')));
                          return;
                        }
                        Navigator.pop(dialogContext);
                      } catch (e) {
                        if (!dialogContext.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add candidate: $e')));
                      }
                    },
                    child: const Text('ADD CANDIDATE'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
    }
  }
}
