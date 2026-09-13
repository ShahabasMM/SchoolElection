import 'package:flutter/material.dart';

import '../services/election_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/election_banner.dart';
import 'class_screen.dart';

class HomeScreen extends StatelessWidget {
  final ElectionController controller;

  const HomeScreen({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ElectionScaffold(
      navIndex: 0,
      showBack: false,
      backgroundColor: Colors.white,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
        children: [
          const ElectionBanner(height: 150),
          const SizedBox(height: 22),
          const Text(
            'Choose your section',
            style: TextStyle(
              color: textDark,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Select a section to continue to the class and division.',
            style: TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 17),

          SectionCard(
            controller: controller,
            type: 'HS',
            title: 'HIGH SCHOOL',
            subtitle: 'Classes 8 • 9 • 10',
            eyebrow: 'HS SECTION',
            icon: Icons.school_rounded,
            accent: const Color(0xFF1769E0),
            fill: Colors.white,
          ),
          const SizedBox(height: 14),

          SectionCard(
            controller: controller,
            type: 'UP',
            title: 'UP SECTION',
            subtitle: 'Classes 5 • 6 • 7',
            eyebrow: 'UP SECTION',
            icon: Icons.menu_book_rounded,
            accent: const Color(0xFF16845B),
            fill: Colors.white,
          ),
          const SizedBox(height: 14),

          SectionCard(
            controller: controller,
            type: 'HSS',
            title: 'HSS SECTION',
            subtitle: 'Classes +1 • +2',
            eyebrow: 'HIGHER SECONDARY',
            icon: Icons.auto_stories_rounded,
            accent: const Color(0xFFE07A00),
            fill: Colors.white,
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF3A2205)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF0F4B04),
                  size: 20,
                ),
                SizedBox(width: 13),
                Expanded(
                  child: Text(
                    'Developed By Shahabas M',
                    style: TextStyle(
                      color: Color(0xFF121315),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
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

class SectionCard extends StatelessWidget {
  final ElectionController controller;
  final String type;
  final String title;
  final String subtitle;
  final String eyebrow;
  final IconData icon;
  final Color accent;
  final Color fill;

  const SectionCard({
    super.key,
    required this.controller,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.eyebrow,
    required this.icon,
    required this.accent,
    required this.fill,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        splashColor: accent.withOpacity(.12),
        highlightColor: accent.withOpacity(.05),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClassScreen(
                controller: controller,
                section: type,
              ),
            ),
          );
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 144),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFD8DEE6), width: 1.4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon module
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      right: 7,
                      top: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          eyebrow,
                          style: TextStyle(
                            color: accent,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Spacer(),
                        
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Arrow pill
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: navy,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: navy.withOpacity(.16),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
