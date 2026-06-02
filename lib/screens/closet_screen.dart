import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/closet_model.dart';
import '../services/closet_service.dart';
import '../theme/app_colors.dart';

class ClosetScreen extends StatefulWidget {
  final int initialAvailablePool;
  final String? initialRepresentativeItemType;

  const ClosetScreen({
    super.key,
    required this.initialAvailablePool,
    this.initialRepresentativeItemType,
  });

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  final _closetService = ClosetService();

  late int _availablePool;
  String? _equippedItemType;

  List<ClosetItem> _myItems = [];
  List<ClosetItem> _shopItems = [];
  bool _isLoading = true;
  bool _isUpdating = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _availablePool = widget.initialAvailablePool;
    _equippedItemType = widget.initialRepresentativeItemType;
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _closetService.getMyItems(),
        _closetService.getShopItems(),
      ]);
      if (mounted) {
        setState(() {
          _myItems = _withOnboardingGift(results[0]);
          _shopItems = results[1];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _myItems = _withOnboardingGift([]);
          _shopItems = ClosetItem.allItems;
          _isLoading = false;
        });
      }
    }
  }

  // 온보딩 선물 아이템이 나의 서랍에 반드시 포함되도록 보장
  List<ClosetItem> _withOnboardingGift(List<ClosetItem> items) {
    final giftType = widget.initialRepresentativeItemType;
    if (giftType == null) return items;

    final alreadyIncluded = items.any((i) => i.itemType == giftType);
    if (alreadyIncluded) return items;

    try {
      final giftItem = ClosetItem.allItems
          .firstWhere((i) => i.itemType == giftType)
          .copyWith(owned: true);
      return [giftItem, ...items];
    } catch (_) {
      return items;
    }
  }

  String _getLeoImagePath() {
    if (_equippedItemType == null) return 'assets/images/leo_default.png';
    try {
      return ClosetItem.allItems
          .firstWhere((item) => item.itemType == _equippedItemType)
          .leoImagePath;
    } catch (_) {
      return 'assets/images/leo_default.png';
    }
  }

  Future<void> _equipItem(ClosetItem item) async {
    if (_isUpdating) return;
    if (_equippedItemType == item.itemType) return;

    final previous = _equippedItemType;

    setState(() {
      _isUpdating = true;
      _equippedItemType = item.itemType;
    });

    try {
      await _closetService.setRepresentativeItem(item.itemType);
    } catch (_) {
      if (mounted) {
        setState(() => _equippedItemType = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('착용 변경에 실패했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showPurchaseSheet(ClosetItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PurchaseSheet(
        item: item,
        availablePool: _availablePool,
        onConfirm: () async {
          Navigator.pop(ctx);
          await _purchaseItem(item);
        },
      ),
    );
  }

  Future<void> _purchaseItem(ClosetItem item) async {
    if (_isUpdating) return;
    if (_availablePool < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('풀이 부족해요! ${item.price - _availablePool}개가 더 필요해요.'),
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final newPool = await _closetService.purchaseItem(item.itemType);
      if (mounted) {
        setState(() {
          _availablePool = newPool;
          final shopIdx = _shopItems.indexWhere(
            (i) => i.itemType == item.itemType,
          );
          if (shopIdx >= 0) {
            _shopItems[shopIdx] = item.copyWith(owned: true);
          }
          _myItems = [..._myItems, item.copyWith(owned: true)];
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('구매에 실패했어요. 다시 시도해 주세요.')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildLeoPreview(),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final fmt = NumberFormat('#,###');
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textMain),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        '레오 꾸미기',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textMain,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              const Icon(Icons.eco, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '${fmt.format(_availablePool)}개',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeoPreview() {
    return Container(
      height: 200,
      color: AppColors.background,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Image.asset(
              _getLeoImagePath(),
              key: ValueKey(_equippedItemType),
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (context, e, s) =>
                  const Text('🦫', style: TextStyle(fontSize: 90)),
            ),
          ),
          const Positioned(
            bottom: 4,
            child: Text(
              '레오를 예쁘게 꾸며봐!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSub,
              ),
            ),
          ),
          const Positioned(
            right: 44,
            top: 36,
            child: Icon(Icons.auto_awesome, size: 20, color: Color(0xFFB0A090)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    const tabs = [
      (label: '나의 서랍', icon: Icons.inventory_2_outlined),
      (label: '상점', icon: Icons.storefront_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pillWidth = (constraints.maxWidth - 8) / 2;
          return Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight, width: 1),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  left: _selectedTab == 0 ? 0 : pillWidth,
                  top: 0,
                  bottom: 0,
                  width: pillWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.textMain,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(tabs.length, (i) {
                    final selected = _selectedTab == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = i),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  tabs[i].icon,
                                  key: ValueKey(selected),
                                  size: 16,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSub,
                                ),
                              ),
                              const SizedBox(width: 6),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSub,
                                ),
                                child: Text(tabs[i].label),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_selectedTab == 0) return _buildMyDrawer();
    return _buildShop();
  }

  Widget _buildMyDrawer() {
    if (_myItems.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inventory_2_outlined,
        message: '아직 아이템이 없어요!',
        subMessage: '상점에서 아이템을 구매해 보세요.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: _myItems.length,
      itemBuilder: (_, i) => _buildMyItemCard(_myItems[i]),
    );
  }

  Widget _buildMyItemCard(ClosetItem item) {
    final isEquipped = item.itemType == _equippedItemType;

    return GestureDetector(
      onTap: () => _equipItem(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isEquipped ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: Image.asset(
                      item.leoImagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, e, s) => const Icon(
                        Icons.pets,
                        size: 40,
                        color: AppColors.textSub,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: isEquipped
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '착용중',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSub,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
            if (isEquipped)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShop() {
    if (_shopItems.isEmpty) {
      return _buildEmptyState(
        icon: Icons.storefront_outlined,
        message: '상점에 아이템이 없어요!',
        subMessage: '곧 새로운 아이템이 추가될 거예요.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: _shopItems.length,
      itemBuilder: (_, i) => _buildShopItemCard(_shopItems[i]),
    );
  }

  Widget _buildShopItemCard(ClosetItem item) {
    final alreadyOwned =
        item.owned || _myItems.any((i) => i.itemType == item.itemType);
    final canAfford = _availablePool >= item.price;

    return GestureDetector(
      onTap: () {
        if (!alreadyOwned) _showPurchaseSheet(item);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: ColorFiltered(
                      colorFilter: alreadyOwned
                          ? const ColorFilter.matrix([
                              0.33,
                              0.33,
                              0.33,
                              0,
                              0,
                              0.33,
                              0.33,
                              0.33,
                              0,
                              0,
                              0.33,
                              0.33,
                              0.33,
                              0,
                              0,
                              0,
                              0,
                              0,
                              1,
                              0,
                            ])
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            ),
                      child: Image.asset(
                        item.leoImagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, e, s) => const Icon(
                          Icons.pets,
                          size: 40,
                          color: AppColors.textSub,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.eco,
                      size: 12,
                      color: alreadyOwned
                          ? AppColors.textSub
                          : (canAfford
                                ? AppColors.primary
                                : AppColors.primaryDisabled),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${item.price}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: alreadyOwned
                            ? AppColors.textSub
                            : (canAfford
                                  ? AppColors.primary
                                  : AppColors.primaryDisabled),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (alreadyOwned)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.textSub,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '구매완료',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subMessage,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppColors.borderLight),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSub,
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseSheet extends StatelessWidget {
  final ClosetItem item;
  final int availablePool;
  final VoidCallback onConfirm;

  const _PurchaseSheet({
    required this.item,
    required this.availablePool,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = availablePool >= item.price;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 100,
            child: Image.asset(
              item.leoImagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, e, s) =>
                  const Icon(Icons.pets, size: 60, color: AppColors.textSub),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '${item.price}개',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(보유: $availablePool개)',
                style: const TextStyle(fontSize: 13, color: AppColors.textSub),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canAfford ? onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primaryDisabled,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                canAfford ? '구매하기' : '풀이 부족해요',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '취소',
              style: TextStyle(fontSize: 15, color: AppColors.textSub),
            ),
          ),
        ],
      ),
    );
  }
}
