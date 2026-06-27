class RamStats {
  final double totalRam;
  final double remainingRam;
  final double usedRam;

  RamStats({
    required this.totalRam,
    required this.remainingRam,
    required this.usedRam,
  });

  double get usedPercent =>
      totalRam > 0 ? (usedRam / totalRam).clamp(0.0, 1.0) : 0.0;
  double get remainingPercent =>
      totalRam > 0 ? (remainingRam / totalRam).clamp(0.0, 1.0) : 0.0;
}

class DataEntry {
  final String key;
  final String value;
  final int? ttl;
  final int accessCount;

  DataEntry({
    required this.key,
    required this.value,
    this.ttl,
    required this.accessCount,
  });

  factory DataEntry.fromList(List<dynamic> list) {
    return DataEntry(
      key: list[0]?.toString() ?? '',
      value: list[1]?.toString() ?? '',
      ttl: list[2] != null ? int.tryParse(list[2].toString()) : null,
      accessCount: list[3] != null ? int.tryParse(list[3].toString()) ?? 0 : 0,
    );
  }
}
