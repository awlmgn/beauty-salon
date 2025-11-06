class Appointment {
  final int id;
  final String masterName;
  final String service;
  final DateTime dateTime;
  final String clientName;
  final String clientPhone;
  final String status;

  Appointment({
    required this.id,
    required this.masterName,
    required this.service,
    required this.dateTime,
    required this.clientName,
    required this.clientPhone,
    this.status = 'pending',
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      masterName: json['master_name'] ?? 'Неизвестный мастер',
      service: json['service'],
      dateTime: DateTime.parse(json['date_time']),
      clientName: json['client_name'],
      clientPhone: json['client_phone'],
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'master_name': masterName,
      'service': service,
      'date_time': dateTime.toIso8601String(),
      'client_name': clientName,
      'client_phone': clientPhone,
    };
  }
}