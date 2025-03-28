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
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double voc;
  final double pm;
  final double iaqIndex;
  final String iaqCategory;

  IAQRecord({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.voc,
    required this.pm,
    required this.iaqIndex,
    required this.iaqCategory,
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
    };
  }

  factory IAQRecord.fromMap(Map<String, dynamic> map) {
    return IAQRecord(
      timestamp: map['timestamp']?.toDate(),
      temperature: map['temperature'],
      humidity: map['humidity'],
      voc: map['voc'],
      pm: map['pm'],
      iaqIndex: map['iaqIndex'],
      iaqCategory: map['iaqCategory'],
    );
  }
}

