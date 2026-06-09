import 'package:flutter/material.dart';
import '../models/guardian_mission_model.dart';
import '../theme/app_colors.dart';

class GuardianMissionSheet extends StatelessWidget {
  final GuardianMission mission;

  const GuardianMissionSheet({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          if (!mission.isReady) ...[
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.hourglass_empty_rounded, size: 44, color: AppColors.textSub),
                  const SizedBox(height: 16),
                  const Text(
                    '미션이 아직 준비되지 않았어요',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '리포트 생성 후 잠시 기다리면 미션이 만들어져요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSub,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ] else ...[
            _buildSectionLabel(icon: Icons.crop_square, label: '아이에게 건넬 칭찬 멘트'),
            const SizedBox(height: 10),
            _buildMissionCard(
              child: Text(
                mission.praisePhrase,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionLabel(icon: Icons.adjust, label: '함께하면 좋은 활동'),
            const SizedBox(height: 10),
            _buildMissionCard(
              child: Text(
                mission.activitySuggestion,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                  height: 1.7,
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textMain,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '기억할게요!',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSub),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSub,
          ),
        ),
      ],
    );
  }

  Widget _buildMissionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
