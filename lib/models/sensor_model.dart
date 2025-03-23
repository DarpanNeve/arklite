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
  final double co2;
  final double voc;
  final double iaqIndex;
  final String iaqCategory;
  
  IAQRecord({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.co2,
    required this.voc,
    required this.iaqIndex,
    required this.iaqCategory,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'temperature': temperature,
      'humidity': humidity,
      'co2': co2,
      'voc': voc,
      'iaqIndex': iaqIndex,
      'iaqCategory': iaqCategory,
    };
  }
  
  factory IAQRecord.fromMap(Map<String, dynamic> map) {
    return IAQRecord(
      timestamp: map['timestamp']?.toDate(),
      temperature: map['temperature'],
      humidity: map['humidity'],
      co2: map['co2'],
      voc: map['voc'],
      iaqIndex: map['iaqIndex'],
      iaqCategory: map['iaqCategory'],
    );
  }
}

