class SensorModel {
  final String id;
  final String name;
  final String unit;
  final String icon;
  final double? currentValue;

  SensorModel({
    required this.id,
    required this.name,
    required this.unit,
    required this.icon,
    this.currentValue,
  });
}

class IAQRecord {
  final String? id;
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double voc;
  final double pm;
  final double iaqIndex;
  final String iaqCategory;
  final String? location;

  IAQRecord({
    this.id,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.voc,
    required this.pm,
    required this.iaqIndex,
    required this.iaqCategory,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'temperature': temperature,
      'humidity': humidity,
      'voc': voc,
      'pm': pm,
      'iaqIndex': iaqIndex,
      'iaqCategory': iaqCategory,
      'location': location,
    };
  }

  factory IAQRecord.fromMap(Map<String, dynamic> map, {String? id}) {
    return IAQRecord(
      id: id,
      timestamp: map['timestamp']?.toDate(),
      temperature: map['temperature'] ?? 0.0,
      humidity: map['humidity'] ?? 0.0,
      voc: map['voc'] ?? 0.0,
      pm: map['pm'] ?? 0.0,
      iaqIndex: map['iaqIndex'] ?? 0.0,
      iaqCategory: map['iaqCategory'] ?? '',
      location: map['location'],
    );
  }

  IAQRecord copyWith({
    String? id,
    DateTime? timestamp,
    double? temperature,
    double? humidity,
    double? voc,
    double? pm,
    double? iaqIndex,
    String? iaqCategory,
    String? location,
  }) {
    return IAQRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      voc: voc ?? this.voc,
      pm: pm ?? this.pm,
      iaqIndex: iaqIndex ?? this.iaqIndex,
      iaqCategory: iaqCategory ?? this.iaqCategory,
      location: location ?? this.location,
    );
  }
}

