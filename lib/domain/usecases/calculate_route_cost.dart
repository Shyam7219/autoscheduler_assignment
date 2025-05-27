class RouteCostResult {
  final double totalDistance; // in meters
  final double totalTime; // in seconds
  final double cost;

  RouteCostResult({
    required this.totalDistance,
    required this.totalTime,
    required this.cost,
  });
}

class CalculateRouteCostUseCase {
  double mileageRate = 0.45; // £/mile
  double timeRate = 15.0; // £/hour

  RouteCostResult calculate({
    required double totalDistanceInMeters,
    required double totalTimeInSeconds,
  }) {
    final distanceInMiles = totalDistanceInMeters / 1609.34;
    final timeInHours = totalTimeInSeconds / 3600.0;

    final cost = (distanceInMiles * mileageRate) + (timeInHours * timeRate);

    return RouteCostResult(
      totalDistance: totalDistanceInMeters,
      totalTime: totalTimeInSeconds,
      cost: cost,
    );
  }
}
