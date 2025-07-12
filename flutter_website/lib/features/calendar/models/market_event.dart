class MarketEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final EventType type;
  final EventImportance importance;
  final String? symbol;
  final String? url;
  final bool isCompleted;

  const MarketEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    required this.importance,
    this.symbol,
    this.url,
    this.isCompleted = false,
  });

  factory MarketEvent.fromJson(Map<String, dynamic> json) {
    return MarketEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      type: EventType.values.firstWhere((e) => e.name == json['type']),
      importance: EventImportance.values.firstWhere((e) => e.name == json['importance']),
      symbol: json['symbol'],
      url: json['url'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'type': type.name,
      'importance': importance.name,
      'symbol': symbol,
      'url': url,
      'isCompleted': isCompleted,
    };
  }
}

enum EventType {
  earnings,
  listing,
  delisting,
  upgrade,
  partnership,
  regulation,
  technical,
  community,
  conference,
  other,
}

enum EventImportance {
  low,
  medium,
  high,
  critical,
}

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.earnings:
        return 'Earnings';
      case EventType.listing:
        return 'New Listing';
      case EventType.delisting:
        return 'Delisting';
      case EventType.upgrade:
        return 'Network Upgrade';
      case EventType.partnership:
        return 'Partnership';
      case EventType.regulation:
        return 'Regulatory News';
      case EventType.technical:
        return 'Technical Update';
      case EventType.community:
        return 'Community Event';
      case EventType.conference:
        return 'Conference';
      case EventType.other:
        return 'Other';
    }
  }
}

extension EventImportanceExtension on EventImportance {
  String get displayName {
    switch (this) {
      case EventImportance.low:
        return 'Low';
      case EventImportance.medium:
        return 'Medium';
      case EventImportance.high:
        return 'High';
      case EventImportance.critical:
        return 'Critical';
    }
  }
}
