import 'package:flutter/material.dart';

import '../models/election_models.dart';
import '../services/election_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/common.dart';
import 'candidate_screen.dart';

class ClassScreen extends StatefulWidget {
  final ElectionController controller;
  final String section;

  const ClassScreen({
    super.key,
    required this.controller,
    required this.section,
  });

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  late final List<String> labels;

  @override
  void initState() {
    super.initState();

    labels = widget.section.toUpperCase() == 'HSS'
        ? const ['+1', '+2']
        : widget.controller
            .classesFor(widget.section)
            .map((e) => '$e')
            .toList();

    tabs = TabController(
      length: labels.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElectionScaffold(
      navIndex: 0,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
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
                  color: widget.section.toUpperCase() == 'HSS'
                      ? const Color(0xFF102A43)
                      : navy,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: textDark,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
                tabs: labels
                    .map(
                      (label) => Tab(
                        text: widget.section.toUpperCase() == 'HSS'
                            ? label
                            : 'Class $label',
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: widget.controller,
              builder: (context, _) {
                if (widget.section.toUpperCase() == 'HSS') {
                  return TabBarView(
                    controller: tabs,
                    children: labels
                        .map(
                          (className) => _HssStreamList(
                            controller: widget.controller,
                            className: className,
                          ),
                        )
                        .toList(),
                  );
                }

                final classes = widget.controller
                    .classesFor(widget.section);

                return TabBarView(
                  controller: tabs,
                  children: classes.map((cls) {
                    final ds =
                        widget.controller.divisionsFor(cls);

                    return ds.isEmpty
                        ? const EmptyState(
                            title: 'No divisions',
                            subtitle:
                                'No divisions are available for this class.',
                          )
                        : ListView.separated(
                            physics:
                                const BouncingScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(
                              16,
                              4,
                              16,
                              105,
                            ),
                            itemCount: ds.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 11),
                            itemBuilder: (_, i) =>
                                DivisionCard(
                              controller: widget.controller,
                              division: ds[i],
                            ),
                          );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HSS STREAM LIST
// ============================================================================

class _HssStreamList extends StatelessWidget {
  final ElectionController controller;
  final String className;

  const _HssStreamList({
    required this.controller,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    final streams = controller.hssStreamsFor(className);

    if (streams.isEmpty) {
      return const EmptyState(
        title: 'No streams configured',
        subtitle:
            'Ask the admin to add Science, Commerce or Humanities from HSS Manage.',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 105),
      itemCount: streams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        return _HssStreamCard(
          controller: controller,
          stream: streams[index],
        );
      },
    );
  }
}

class _HssStreamCard extends StatelessWidget {
  final ElectionController controller;
  final HssStream stream;

  const _HssStreamCard({
    required this.controller,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    final divisions = controller.hssDivisionsForStream(stream);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          if (!stream.hasBatches) {
            final division =
                controller.hssDirectDivision(stream);

            if (division != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CandidateScreen(
                    controller: controller,
                    division: division,
                  ),
                ),
              );
            }
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HssBatchScreen(
                controller: controller,
                stream: stream,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8EC),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE7D6B7),
              width: 1.4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4D9A8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: navy,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      stream.stream,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      stream.hasBatches
                          ? '${divisions.length} batches • Choose batch'
                          : 'Direct voting • No batch',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: navy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HSS BATCH SCREEN
// ============================================================================

class HssBatchScreen extends StatelessWidget {
  final ElectionController controller;
  final HssStream stream;

  const HssBatchScreen({
    super.key,
    required this.controller,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return ElectionScaffold(
      navIndex: 0,
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final current =
              controller.hssStreams.cast<HssStream?>().firstWhere(
                    (s) => s?.id == stream.id,
                    orElse: () => null,
                  );

          if (current == null) {
            return const EmptyState(
              title: 'Stream unavailable',
              subtitle: 'This HSS stream was removed.',
            );
          }

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              105,
            ),
            children: [
              Text(
                '${current.className} • ${current.stream}',
                style: const TextStyle(
                  color: navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Choose a batch to continue to voting.',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              ...current.batches.map(
                (batch) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 11,
                  ),
                  child: _BatchChoiceCard(
                    controller: controller,
                    stream: current,
                    batch: batch,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BatchChoiceCard extends StatelessWidget {
  final ElectionController controller;
  final HssStream stream;
  final String batch;

  const _BatchChoiceCard({
    required this.controller,
    required this.stream,
    required this.batch,
  });

  @override
  Widget build(BuildContext context) {
    final division =
        controller.hssBatchDivision(stream, batch);

    final candidateCount = division == null
        ? 0
        : controller.candidatesFor(division.id).length;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: division == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CandidateScreen(
                      controller: controller,
                      division: division,
                    ),
                  ),
                );
              },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: blueSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.layers_rounded,
                  color: blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$candidateCount candidates',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: navy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// STANDARD DIVISION CARD
// ============================================================================

class DivisionCard extends StatelessWidget {
  final ElectionController controller;
  final Division division;

  const DivisionCard({
    super.key,
    required this.controller,
    required this.division,
  });

  @override
  Widget build(BuildContext context) {
    final count =
        controller.candidatesFor(division.id).length;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CandidateScreen(
              controller: controller,
              division: division,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: blueSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    division.section,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF071730),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Division ${division.section}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: textDark,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count candidates • Class ${division.className}',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF0B2347),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
