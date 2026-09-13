import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PageBottomNav extends StatelessWidget {
  final int selectedIndex;

  const PageBottomNav({
    super.key,
    required this.selectedIndex,
  });

  // ===========================================================================
  // NAVIGATION
  // ===========================================================================

  void go(BuildContext context, int index) {
    final target = index == 0 ? '/home' : '/control';

    // Replace the entire route stack with one stable root route. This avoids
    // rebuilding/deactivating the root Scaffold tree while a nested route is
    // still alive, which was triggering Flutter's `_dependents.isEmpty`
    // assertion in this project.
    Navigator.of(context).pushNamedAndRemoveUntil(
      target,
      (route) => false,
    );
  }

  // ===========================================================================
  // SAFE SELECTED INDEX
  // ===========================================================================

  int get safeSelectedIndex {
    if (selectedIndex < 0) {
      return 0;
    }

    if (selectedIndex > 1) {
      return 1;
    }

    return selectedIndex;
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,

      minimum: const EdgeInsets.fromLTRB(
        14,
        0,
        14,
        10,
      ),

      child: Container(
        height: 72,

        decoration: BoxDecoration(
          color:
              Colors.white.withOpacity(.78),

          borderRadius:
              BorderRadius.circular(30),

          border: Border.all(
            color: Colors.white,
          ),

          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 18,
              offset: Offset(0, 7),
            ),
          ],
        ),

        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(29),

          child: NavigationBar(
            height: 70,

            // IMPORTANT:
            // Results tab removed.
            // Only Home = 0 and Control = 1.
            selectedIndex:
                safeSelectedIndex,

            onDestinationSelected: (index) {
              go(
                context,
                index,
              );
            },

            backgroundColor:
                Colors.transparent,

            surfaceTintColor:
                Colors.transparent,

            shadowColor:
                Colors.transparent,

            indicatorColor:
                blueSoft,

            labelBehavior:
                NavigationDestinationLabelBehavior
                    .alwaysShow,

            destinations: const [
              // =================================================================
              // HOME
              // =================================================================

              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                  color: navy,
                ),

                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: blue,
                ),

                label: 'Home',
              ),

              // =================================================================
              // CONTROL
              // =================================================================

              NavigationDestination(
                icon: Icon(
                  Icons.tune_outlined,
                  color: navy,
                ),

                selectedIcon: Icon(
                  Icons.tune_rounded,
                  color: blue,
                ),

                label: 'Control',
              ),
            ],
          ),
        ),
      ),
    );
  }
}