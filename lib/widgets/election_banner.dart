import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ElectionBanner extends StatelessWidget {
  final String? voteFor;
  final double height;

  const ElectionBanner({super.key, this.voteFor, this.height = 150});

  @override
  Widget build(BuildContext context) {
    final label = voteFor == null ? null : 'VOTE FOR ${voteFor!.toUpperCase()}';

    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2DD),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: navy, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF454B52),
            offset: Offset(0, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -35,
            bottom: -48,
            child: Transform.rotate(
              angle: -.22,
              child: Container(
                width: 145,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFF1B72E8),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(65),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -30,
            top: -35,
            child: Container(
              width: 170,
              height: 115,
              decoration: const BoxDecoration(
                color: Color(0xFFEF3D5A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(90),
                ),
              ),
            ),
          ),
          Positioned(
            right: -18,
            bottom: -22,
            child: Transform.rotate(
              angle: -.12,
              child: Container(
                width: 125,
                height: 70,
                color: const Color(0xFFFFC928),
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 14,
            child: Row(
              children: const [
                _Dot(Color(0xFFEF3D5A)),
                SizedBox(width: 5),
                _Dot(Color(0xFF1B72E8)),
                SizedBox(width: 5),
                _Dot(Color(0xFFFFC928)),
              ],
            ),
          ),
          Positioned(
            left: 20,
            top: 39,
            right: height * .52,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                'GHSS ELECTION',
                maxLines: 1,
                style: const TextStyle(
                  color: navy,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.6,
                  height: 1,
                ),
              ),
            ),
          ),
          Positioned(
            left: 21,
            bottom: 17,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label ?? 'YOUR VOICE • YOUR CHOICE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .9,
                ),
              ),
            ),
          ),
          Positioned(
            right: 23,
            top: 31,
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD86B),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.how_to_vote_rounded,
                  color: Color(0xFF4B0B67),
                  size: 39,
                ),
              ),
            ),
          ),
          Positioned(
            right: 21,
            bottom: 12,
            child: Transform.rotate(
              angle: .06,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: navy, width: 1),
                ),
                child: Text(
                  voteFor == null ? 'EVM' : voteFor!.toUpperCase(),
                  style: const TextStyle(
                    color: navy,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          if (voteFor != null)
            Positioned(
              left: 20,
              top: 88,
              child: Text(
                'CAST YOUR VOTE • ${voteFor!.toUpperCase()}',
                style: const TextStyle(
                  color: navy,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);
  @override
  Widget build(BuildContext context) => Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
