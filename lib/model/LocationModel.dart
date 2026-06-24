class LocationItem {
  final String id;
  final String name;
  final String countriesId;
  final String statesId;

  LocationItem({
    required this.id,
    required this.name,
    required this.countriesId,
    required this.statesId,
  });

  factory LocationItem.fromJson(Map<String, dynamic> json) => LocationItem(
    id         : json['id']?.toString()          ?? '',
    name       : json['name']?.toString()        ?? '',
    countriesId: json['countries_id']?.toString() ?? '0',
    statesId   : json['states_id']?.toString()   ?? '0',
  );
}

class LocationResponse {
  final bool               status;
  final String             message;
  final List<LocationItem> results;

  LocationResponse({
    required this.status,
    required this.message,
    required this.results,
  });

  factory LocationResponse.fromJson(Map<String, dynamic> json) =>
      LocationResponse(
        status : json['status']  ?? false,
        message: json['message'] ?? '',
        results: (json['results'] as List<dynamic>? ?? [])
            .map((e) => LocationItem.fromJson(e))
            .toList(),
      );
}