import 'package:flutter/material.dart';
import '../services/parent_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_toast.dart';

class ParentResetScreen extends StatefulWidget {
  const ParentResetScreen({super.key});

  @override
  State<ParentResetScreen> createState() => _ParentResetScreenState();
}

class _ParentResetScreenState extends State<ParentResetScreen> {
  final _parentService = ParentService();

  int _step = 0; // 0: 새 비밀번호 입력, 1: 확인
  String _newPin = '';
  String _confirmPin = '';
  bool _isError = false;
  bool _isLoading = false;

  String get _currentPin => _step == 0 ? _newPin : _confirmPin;

  void _onNumTap(String value) {
    if (_isLoading) return;
    final current = _currentPin;
    if (current.length >= 4) return;
    setState(() {
      _isError = false;
      if (_step == 0) {
        _newPin += value;
      } else {
        _confirmPin += value;
      }
    });
    if (_currentPin.length == 4) _onPinComplete();
  }

  void _onDelete() {
    if (_isLoading) return;
    setState(() {
      _isError = false;
      if (_step == 0) {
        if (_newPin.isNotEmpty) _newPin = _newPin.substring(0, _newPin.length - 1);
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  void _onPinComplete() {
    if (_step == 0) {
      setState(() {
        _step = 1;
        _confirmPin = '';
      });
    } else {
      _confirmAndReset();
    }
  }

  Future<void> _confirmAndReset() async {
    if (_newPin != _confirmPin) {
      setState(() {
        _isError = true;
        _confirmPin = '';
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _parentService.resetPassword(_newPin, _confirmPin);
      if (mounted) {
        Navigator.pop(context, true);
        AppToast.show(context, '비밀번호가 변경되었어요.');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isError = true;
          _confirmPin = '';
        });
        AppToast.show(context, '비밀번호 초기화에 실패했어요. 다시 시도해 주세요.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textMain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '비밀번호 초기화',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            _buildHeader(),
            const SizedBox(height: 40),
            _buildPinBoxes(),
            if (_isError) ...[
              const SizedBox(height: 14),
              const Text(
                '비밀번호가 일치하지 않아요',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF8A80),
                ),
              ),
            ],
            const Spacer(),
            _buildNumpad(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_reset_outlined,
            color: AppColors.primary,
            size: 44,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _step == 0 ? '새 비밀번호 입력' : '한 번 더 입력해주세요',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _step == 0
              ? '새로운 4자리 비밀번호를 입력해주세요.'
              : '비밀번호가 맞는지 확인이 필요해요.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white60,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildPinBoxes() {
    final current = _currentPin;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < current.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 56,
          height: 64,
          decoration: BoxDecoration(
            color: isFilled
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isError
                  ? const Color(0xFFFF8A80)
                  : Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isFilled
                ? const Text(
                    '●',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  )
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildNumpad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildNumRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildNumRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildNumRow(['7', '8', '9']),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildActionButton(
                _step == 0 ? '취소' : '뒤로',
                onTap: () {
                  if (_step == 0) {
                    Navigator.pop(context);
                  } else {
                    setState(() {
                      _step = 0;
                      _confirmPin = '';
                      _isError = false;
                    });
                  }
                },
              ),
              _buildNumberButton('0'),
              _buildActionButton('지우기', onTap: _onDelete),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumRow(List<String> numbers) {
    return Row(children: numbers.map(_buildNumberButton).toList());
  }

  Widget _buildNumberButton(String number) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: InkWell(
          onTap: () => _onNumTap(number),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      number,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, {required VoidCallback onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: InkWell(
          onTap: _isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white60,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
