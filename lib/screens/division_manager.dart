import 'package:flutter/material.dart';
import '../models/election_models.dart';
import '../services/election_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/common.dart';

class DivisionManager extends StatefulWidget {
  final ElectionController controller;
  const DivisionManager({super.key, required this.controller});
  @override State<DivisionManager> createState() => _DivisionManagerState();
}

class _DivisionManagerState extends State<DivisionManager> {
  String cls = '5';

  @override
  Widget build(BuildContext context) {
    return ElectionScaffold(
      navIndex: 1,
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final current = widget.controller.divisionsFor(int.parse(cls));
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: AppDropdown(
                value: cls,
                items: const ['5', '6', '7', '8', '9', '10'],
                labels: const ['Class 5', 'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'],
                onChanged: (v) { if (v != null) setState(() => cls = v); },
              ),
            ),
            Expanded(
              child: current.isEmpty
                  ? const EmptyState(title: 'No divisions', subtitle: 'Tap ADD DIVISION to create one.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 105),
                      itemCount: current.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 9),
                      itemBuilder: (_, i) {
                        final d = current[i];
                        final students = widget.controller.students.where((s) => s.className == d.className && s.division.toUpperCase() == d.section.toUpperCase()).length;
                        return ManageRow(
                          photo: Container(width: 50, height: 50, decoration: BoxDecoration(color: blueSoft, borderRadius: BorderRadius.circular(15)), child: Center(child: Text(d.section, style: const TextStyle(fontWeight: FontWeight.w900, color: blue, fontSize: 18)))),
                          title: 'Class ${d.className} • Division ${d.section}',
                          subtitle: '$students students • ${widget.controller.candidatesFor(d.id).length} candidates',
                          onDelete: () => _delete(d),
                        );
                      },
                    ),
            ),
          ]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: const Text('ADD DIVISION')),
    );
  }

  Future<void> _delete(Division division) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete division?'),
        content: Text('Delete Class ${division.className} • Division ${division.section}? Candidates in this division will also be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('CANCEL')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: red), onPressed: () => Navigator.pop(dialogContext, true), child: const Text('DELETE')),
        ],
      ),
    );
    if (ok == true) await widget.controller.removeDivision(division.id);
  }

  Future<void> _add() async {
    final sectionController = TextEditingController();
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Add Division'),
          content: TextField(
            controller: sectionController,
            textCapitalization: TextCapitalization.characters,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Division / Section',
              hintText: 'e.g. A',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
            FilledButton(
              onPressed: () async {
                final section = sectionController.text.trim();
                if (section.isEmpty) return;
                try {
                  final before = widget.controller.divisionsFor(int.parse(cls)).length;
                  await widget.controller.addDivision(cls, section);
                  if (!dialogContext.mounted) return;
                  final after = widget.controller.divisionsFor(int.parse(cls)).length;
                  if (after == before) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('That division already exists.')));
                    return;
                  }
                  Navigator.pop(dialogContext);
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add division: $e')));
                }
              },
              child: const Text('ADD DIVISION'),
            ),
          ],
        ),
      );
    } finally {
      sectionController.dispose();
    }
  }
}
