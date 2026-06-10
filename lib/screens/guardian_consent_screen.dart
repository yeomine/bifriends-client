import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/onboarding_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_toast.dart';
import 'parent_setup_screen.dart';

class GuardianConsentScreen extends StatefulWidget {
  const GuardianConsentScreen({super.key});

  @override
  State<GuardianConsentScreen> createState() => _GuardianConsentScreenState();
}

class _GuardianConsentScreenState extends State<GuardianConsentScreen> {
  final OnboardingService _onboardingService = OnboardingService();
  bool _isLoading = false;
  bool _allAgreed = false;
  bool _termsAgreed = false;
  bool _privacyAgreed = false;
  bool _childInfoAgreed = false;

  bool get _canProceed => _termsAgreed && _privacyAgreed && _childInfoAgreed;

  void _toggleAll(bool value) {
    setState(() {
      _allAgreed = value;
      _termsAgreed = value;
      _privacyAgreed = value;
      _childInfoAgreed = value;
    });
  }

  void _updateAllAgreed() {
    setState(() {
      _allAgreed = _termsAgreed && _privacyAgreed && _childInfoAgreed;
    });
  }

  void _showTermsDetail(String title, String content) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 100),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.textSub),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMain,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.2),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '확인했어요',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textMain,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                '보호자 동의',
                style: GoogleFonts.gaegu(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 48),
              _buildAllAgreeCheckbox(),
              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 24),
              _buildTermItem(
                '서비스 이용 약관',
                _termsAgreed,
                (v) {
                  setState(() => _termsAgreed = v);
                  _updateAllAgreed();
                },
                () => _showTermsDetail(
                  '이용약관',
                  'BiFriend 서비스 이용약관입니다. 본 서비스는 아동의 학습과 정서 발달을 돕기 위해 제공되며...',
                ),
              ),
              const SizedBox(height: 24),
              _buildTermItem(
                '개인정보 처리방침',
                _privacyAgreed,
                (v) {
                  setState(() => _privacyAgreed = v);
                  _updateAllAgreed();
                },
                () => _showTermsDetail(
                  '개인정보',
                  '개인정보 수집 및 이용 동의서입니다. 수집한 정보는 서비스 제공 및 개선 목적으로만 사용합니다.',
                ),
              ),
              const SizedBox(height: 24),
              _buildTermItem(
                '아동정보 수집',
                _childInfoAgreed,
                (v) {
                  setState(() => _childInfoAgreed = v);
                  _updateAllAgreed();
                },
                () => _showTermsDetail(
                  '아동정보',
                  '만 14세 미만 아동의 개인정보 수집에 대한 법정대리인 동의서입니다. 보호자의 동의 없이는 아동의 정보를 수집하지 않습니다.',
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.2),
                  ),
                  onPressed: (_canProceed && !_isLoading)
                      ? () async {
                          setState(() => _isLoading = true);
                          try {
                            await _onboardingService.submitTerms(
                              termsAgreed: _termsAgreed,
                              privacyAgreed: _privacyAgreed,
                              marketingAgreed: _childInfoAgreed,
                            );
                            if (!context.mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ParentSetupScreen(),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            AppToast.show(
                              context,
                              e.toString().replaceAll('Exception: ', ''),
                              isError: true,
                            );
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        }
                      : null,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                    '보호자 휴대폰 인증하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllAgreeCheckbox() {
    return GestureDetector(
      onTap: () => _toggleAll(!_allAgreed),
      child: Row(
        children: [
          _buildCheckIcon(_allAgreed, size: 28),
          const SizedBox(width: 12),
          const Text(
            '모든 항목에 동의합니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(
    String title,
    bool isChecked,
    ValueChanged<bool> onChanged,
    VoidCallback onDetailTap,
  ) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => onChanged(!isChecked),
          child: _buildCheckIcon(isChecked, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!isChecked),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSub,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: onDetailTap,
          child: const Text(
            '보기',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMain,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.textMain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckIcon(bool checked, {double size = 24}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: checked ? AppColors.textMain : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: checked ? AppColors.textMain : AppColors.borderLight,
          width: 1.5,
        ),
      ),
      child: checked
          ? Icon(Icons.check, size: size * 0.65, color: Colors.white)
          : null,
    );
  }
}
