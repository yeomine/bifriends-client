import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/closet_model.dart';
import '../services/closet_service.dart';
import '../theme/app_colors.dart';

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key});

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  final _closetService = ClosetService();

  int _availablePool = 0;
  EquippedItems _equipped = const EquippedItems();

  List<ClosetItem> _myItems = [];
  List<ClosetItem> _shopItems = [];
  bool _isLoading = true;
  bool _isUpdating = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
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
        final myResult =
            results[0] as ({List<ClosetItem> items, EquippedItems equipped});
        final shopResult =
            results[1] as ({List<ClosetItem> items, int availablePool});
        setState(() {
          _myItems = myResult.items;
          _equipped = myResult.equipped;
          _shopItems = shopResult.items;
          _availablePool = shopResult.availablePool;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ClosetItem? _findItemByCode(String code) {
    try {
      return _myItems.firstWhere((item) => item.itemCode == code);
    } catch (_) {
      return null;
    }
  }

  Future<void> _toggleEquip(ClosetItem item) async {
    if (_isUpdating) return;
    final alreadyEquipped = _equipped.isEquipped(item.itemCode);
    final previousEquipped = _equipped;

    // 낙관적 업데이트: 서버 응답 전에 UI 먼저 반영
    setState(() {
      _isUpdating = true;
      _equipped = alreadyEquipped
          ? _equipped.clear()
          : EquippedItems(outfitCode: item.itemCode);
    });

    try {
      final newEquipped = alreadyEquipped
          ? await _closetService.unequipItem()
          : await _closetService.equipItem(item.itemCode);
      if (mounted) setState(() => _equipped = newEquipped);
    } catch (e) {
      debugPrint('equip error: $e');
      if (mounted) {
        setState(() => _equipped = previousEquipped);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(alreadyEquipped ? '탈착에 실패했어요.' : '착용에 실패했어요.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showEquipSheet(ClosetItem item) {
    final alreadyEquipped = _equipped.isEquipped(item.itemCode);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EquipSheet(
        item: item,
        isEquipped: alreadyEquipped,
        onConfirm: () {
          Navigator.pop(ctx);
          _toggleEquip(item);
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
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
      final remainingPool = await _closetService.purchaseItem(item.itemCode);
      if (mounted) {
        final purchasedItem = item.copyWith(owned: true);
        setState(() {
          _availablePool = remainingPool;
          final idx = _shopItems.indexWhere((i) => i.itemCode == item.itemCode);
          if (idx >= 0) _shopItems[idx] = purchasedItem;
          _myItems = [..._myItems, purchasedItem];
        });
        _showPurchaseSuccessSheet(purchasedItem);
      }
    } catch (e) {
      debugPrint('purchase error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('구매에 실패했어요. 다시 시도해 주세요.')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showPurchaseSuccessSheet(ClosetItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      isScrollControlled: true,
      builder: (ctx) => _PurchaseSuccessSheet(
        item: item,
        onEquip: () {
          Navigator.pop(ctx);
          setState(() => _selectedTab = 0);
          _toggleEquip(item);
        },
        onClose: () => Navigator.pop(ctx),
      ),
    );
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
    final assetPath = _equipped.outfitCode != null
        ? (_findItemByCode(_equipped.outfitCode!)?.localAssetPath ??
              'assets/images/leo_default.png')
        : 'assets/images/leo_default.png';

    return Container(
      height: 200,
      color: AppColors.background,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Image.asset(
              assetPath,
              key: ValueKey(assetPath),
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (_, e, s) =>
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
          final pillWidth = (constraints.maxWidth - 10) / 2;
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
    final isEquipped = _equipped.isEquipped(item.itemCode);

    return GestureDetector(
      onTap: () => _showEquipSheet(item),
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
                      item.localAssetPath,
                      height: 60,
                      fit: BoxFit.contain,
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
        item.owned || _myItems.any((i) => i.itemCode == item.itemCode);
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
                        item.localAssetPath,
                        height: 60,
                        fit: BoxFit.contain,
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
              item.localAssetPath,
              height: 100,
              fit: BoxFit.contain,
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

class _PurchaseSuccessSheet extends StatelessWidget {
  final ClosetItem item;
  final VoidCallback onEquip;
  final VoidCallback onClose;

  const _PurchaseSuccessSheet({
    required this.item,
    required this.onEquip,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.fromLTRB(24, 28, 24, 32 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFE5EDD6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '구매 완료!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.name}을(를) 얻었어요',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSub,
            ),
          ),
          const SizedBox(height: 20),
          Image.asset(item.localAssetPath, height: 110, fit: BoxFit.contain),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onEquip,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                '지금 바로 착용하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onClose,
            child: const Text(
              '나중에',
              style: TextStyle(fontSize: 15, color: AppColors.textSub),
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipSheet extends StatelessWidget {
  final ClosetItem item;
  final bool isEquipped;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _EquipSheet({
    required this.item,
    required this.isEquipped,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
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
              item.localAssetPath,
              height: 100,
              fit: BoxFit.contain,
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
          const SizedBox(height: 6),
          Text(
            isEquipped ? '지금 착용 중인 아이템이에요' : '레오에게 입혀볼까요?',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSub,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: isEquipped
                    ? AppColors.textSub
                    : AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                isEquipped ? '탈착하기' : '착용하기',
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
            onPressed: onCancel,
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
