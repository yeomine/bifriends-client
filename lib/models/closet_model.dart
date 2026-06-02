class ClosetItem {
  final String itemType;
  final String name;
  final String emoji;
  final int price;
  final bool owned;

  const ClosetItem({
    required this.itemType,
    required this.name,
    required this.emoji,
    required this.price,
    required this.owned,
  });

  String get leoImagePath {
    const images = {
      'GIFT_1': 'assets/images/leo_studying.png',
      'GIFT_2': 'assets/images/leo_ribbon.png',
      'GIFT_3': 'assets/images/leo_flower.png',
      'GIFT_4': 'assets/images/leo_sunglasses.png',
      'GIFT_5': 'assets/images/leo_dinosaur.png',
      'GIFT_6': 'assets/images/leo_scientist.png',
      'GIFT_7': 'assets/images/leo_singer.png',
    };
    return images[itemType] ?? 'assets/images/leo_default.png';
  }

  factory ClosetItem.fromJson(Map<String, dynamic> json) {
    final itemType = json['itemType'] as String;
    return ClosetItem(
      itemType: itemType,
      name: json['name'] as String? ?? _defaultName(itemType),
      emoji: json['emoji'] as String? ?? _defaultEmoji(itemType),
      price: json['price'] as int? ?? 0,
      owned: json['owned'] as bool? ?? false,
    );
  }

  ClosetItem copyWith({bool? owned}) => ClosetItem(
    itemType: itemType,
    name: name,
    emoji: emoji,
    price: price,
    owned: owned ?? this.owned,
  );

  static String _defaultName(String itemType) {
    const names = {
      'GIFT_1': '책',
      'GIFT_2': '리본',
      'GIFT_3': '꽃다발',
      'GIFT_4': '선글라스',
      'GIFT_5': '공룡 의상',
      'GIFT_6': '과학자 가운',
      'GIFT_7': '가수 의상',
    };
    return names[itemType] ?? '아이템';
  }

  static String _defaultEmoji(String itemType) {
    const emojis = {
      'GIFT_1': '📚',
      'GIFT_2': '🎀',
      'GIFT_3': '🍓',
      'GIFT_4': '🕶️',
      'GIFT_5': '🦕',
      'GIFT_6': '🔬',
      'GIFT_7': '🎤',
    };
    return emojis[itemType] ?? '🎁';
  }

  static List<ClosetItem> get allItems => const [
    ClosetItem(
      itemType: 'GIFT_1',
      name: '책',
      emoji: '📚',
      price: 8,
      owned: false,
    ),
    ClosetItem(
      itemType: 'GIFT_2',
      name: '리본',
      emoji: '🎀',
      price: 12,
      owned: false,
    ),
    ClosetItem(
      itemType: 'GIFT_3',
      name: '꽃다발',
      emoji: '🍓',
      price: 15,
      owned: false,
    ),
    ClosetItem(
      itemType: 'GIFT_4',
      name: '선글라스',
      emoji: '🕶️',
      price: 20,
      owned: false,
    ),
    ClosetItem(
      itemType: 'GIFT_5',
      name: '공룡 의상',
      emoji: '🦕',
      price: 30,
      owned: false,
    ),
    ClosetItem(
      itemType: 'GIFT_6',
      name: '과학자 가운',
      emoji: '🔬',
      price: 35,
      owned: false,
    ),
    ClosetItem(
      itemType: 'GIFT_7',
      name: '가수 의상',
      emoji: '🎤',
      price: 30,
      owned: false,
    ),
  ];
}
