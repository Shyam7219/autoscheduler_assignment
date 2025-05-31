class Customer {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<DateTime> recurringTimes;

  Customer({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.recurringTimes = const [],
  });
}