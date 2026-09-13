import 'package:flutter/material.dart';

import '../models/election_models.dart';
import '../services/election_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/common.dart';
import 'hss_candidate_manager.dart';

class HssManager extends StatefulWidget {
  final ElectionController controller;

  const HssManager({
    super.key,
    required this.controller,
  });

  @override
  State<HssManager> createState() => _HssManagerState();
}

class _HssManagerState extends State<HssManager>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;

  static const _classes = ['+1', '+2'];

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElectionScaffold(
      navIndex: 1,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFFFE7B8), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.account_tree_rounded, color: Color(0xFF8A4B00))),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('HSS CONTROL', style: TextStyle(color: navy, fontSize: 20, fontWeight: FontWeight.w900)), SizedBox(height: 2), Text('+1 / +2 streams, batches and candidates', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600))])),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: TabBar(
                controller: tabs,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: textDark,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
                tabs: const [
                  Tab(text: '+1'),
                  Tab(text: '+2'),
                ],
              ),
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: widget.controller,
              builder: (context, _) {
                return TabBarView(
                  controller: tabs,
                  children: _classes
                      .map((className) => _StreamList(
                            controller: widget.controller,
                            className: className,
                          ))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStream,
        icon: const Icon(Icons.add),
        label: const Text('ADD STREAM'),
      ),
    );
  }

  Future<void> _addStream() async {
    final streamController = TextEditingController();
    String selected = 'Science';
    const presets = ['Commerce', 'Science', 'Humanities', 'Other'];

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final currentClass = _classes[tabs.index];
              return AlertDialog(
                title: const Text('Add HSS Stream'),
                content: SizedBox(
                  width: 460,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(currentClass, style: const TextStyle(color: muted, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 14),
                        const Text('Stream', style: TextStyle(color: navy, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: presets.map((item) => ChoiceChip(
                            label: Text(item),
                            selected: selected == item,
                            onSelected: (_) => setDialogState(() => selected = item),
                          )).toList(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: streamController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Custom stream name (optional)',
                            hintText: 'e.g. Computer Science',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
                  FilledButton(
                    onPressed: () async {
                      final typed = streamController.text.trim();
                      final stream = typed.isEmpty ? selected : typed;
                      try {
                        final added = await widget.controller.addHssStream(className: currentClass, stream: stream);
                        if (!dialogContext.mounted) return;
                        if (!added) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('That stream already exists.')));
                          return;
                        }
                        Navigator.pop(dialogContext);
                      } catch (e) {
                        if (!dialogContext.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add stream: $e')));
                      }
                    },
                    child: const Text('ADD STREAM'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      streamController.dispose();
    }
  }

}

class _StreamList extends StatelessWidget {
  final ElectionController controller;
  final String className;

  const _StreamList({
    required this.controller,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    final streams = controller.hssStreamsFor(className);

    if (streams.isEmpty) {
      return const EmptyState(
        title: 'No HSS streams',
        subtitle:
            'Add Science, Commerce, Humanities or a custom stream.',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 105),
      itemCount: streams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final stream = streams[index];

        return _StreamCard(
          controller: controller,
          stream: stream,
        );
      },
    );
  }
}

class _StreamCard extends StatelessWidget {
  final ElectionController controller;
  final HssStream stream;

  const _StreamCard({
    required this.controller,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    final divisions = controller.hssDivisionsForStream(stream);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE7D6B7),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4D9A8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stream.stream,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stream.hasBatches
                          ? '${stream.batches.length} batches'
                          : 'Direct voting • no batches',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete stream',
                onPressed: () => _deleteStream(context),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),

          if (stream.hasBatches)
            ...stream.batches.map(
              (batch) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BatchRow(
                  controller: controller,
                  stream: stream,
                  batch: batch,
                ),
              ),
            )
          else
            _DirectRow(
              controller: controller,
              stream: stream,
            ),

          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addBatch(context),
                  icon: const Icon(Icons.layers_rounded, size: 18),
                  label: Text(
                    stream.hasBatches
                        ? 'ADD BATCH'
                        : 'ENABLE BATCHES',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStream(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete stream?'),
        content: Text(
          'Delete ${stream.className} ${stream.stream} and all candidates inside it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: red,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await controller.removeHssStream(stream.id);
    }
  }

  Future<void> _addBatch(BuildContext context) async {
    final batchController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          stream.hasBatches
              ? 'Add batch'
              : 'Enable batches',
        ),
        content: TextField(
          controller: batchController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Batch name',
            hintText: 'e.g. Batch A',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () async {
              final batch = batchController.text.trim();
              if (batch.isEmpty) return;

              final added = await controller.addHssBatch(
                streamId: stream.id,
                batch: batch,
              );

              if (!dialogContext.mounted) return;

              if (!added) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Batch already exists or the stream has candidates.',
                    ),
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );

    batchController.dispose();
  }
}

class _DirectRow extends StatelessWidget {
  final ElectionController controller;
  final HssStream stream;

  const _DirectRow({
    required this.controller,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    final division = controller.hssDirectDivision(stream);
    final candidateCount =
        division == null ? 0 : controller.candidatesFor(division.id).length;

    return _ManagementRow(
      title: stream.stream,
      subtitle: '$candidateCount candidates • direct voting',
      icon: Icons.arrow_forward_rounded,
      onCandidates: division == null
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HssCandidateManager(
                    controller: controller,
                    stream: stream,
                    division: division,
                  ),
                ),
              );
            },
    );
  }
}

class _BatchRow extends StatelessWidget {
  final ElectionController controller;
  final HssStream stream;
  final String batch;

  const _BatchRow({
    required this.controller,
    required this.stream,
    required this.batch,
  });

  @override
  Widget build(BuildContext context) {
    final division = controller.hssBatchDivision(
      stream,
      batch,
    );
    final candidateCount =
        division == null ? 0 : controller.candidatesFor(division.id).length;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.layers_rounded,
            color: blue,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batch,
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$candidateCount candidates',
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Manage candidates',
            onPressed: division == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HssCandidateManager(
                          controller: controller,
                          stream: stream,
                          division: division,
                        ),
                      ),
                    );
                  },
            icon: const Icon(
              Icons.how_to_vote_rounded,
              color: navy,
            ),
          ),
          IconButton(
            tooltip: 'Delete batch',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Delete batch?'),
                  content: Text(
                    'Delete ${stream.stream} • $batch and its candidates?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext, false),
                      child: const Text('CANCEL'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: red,
                      ),
                      onPressed: () =>
                          Navigator.pop(dialogContext, true),
                      child: const Text('DELETE'),
                    ),
                  ],
                ),
              );

              if (ok == true) {
                await controller.removeHssBatch(
                  streamId: stream.id,
                  batch: batch,
                );
              }
            },
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: red,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onCandidates;

  const _ManagementRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onCandidates,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.school_rounded,
            color: blue,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Manage candidates',
            onPressed: onCandidates,
            icon: Icon(
              icon,
              color: navy,
            ),
          ),
        ],
      ),
    );
  }
}
