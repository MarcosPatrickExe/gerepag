class DreNode {
  final String code;
  final String name;
  double total;
  final Map<String, DreNode> children;
  final int level;

  DreNode({
    required this.code,
    required this.name,
    this.total = 0.0,
    required this.level,
  }) : children = {};

  List<DreNode> get sortedChildren {
    final list = children.values.toList();
    list.sort((a, b) => a.code.compareTo(b.code));
    return list;
  }
}
