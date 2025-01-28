class Device {
  String? type;
  String? deviceName;
  String? deviceToken;
  int? employeeId;
  int? locationId;
  int? id;
  String? createdBy;
  DateTime? createdDate;
  bool? isActive;

  Device({
    this.type,
    this.deviceName,
    this.deviceToken,
    this.employeeId,
    this.locationId,
    this.id,
    this.createdBy,
    this.createdDate,
    this.isActive,
  });

  // Factory method to create an instance from JSON
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      type: json['type'],
      deviceName: json['deviceName'],
      deviceToken: json['deviceToken'],
      employeeId: json['employeeId'],
      locationId: json['locationId'],
      id: json['id'],
      createdBy: json['createdBy'],
      createdDate: json['createdDate'] != null ? DateTime.parse(json['createdDate']) : null,
      isActive: json['isActive'],
    );
  }

  // Method to convert an instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'deviceName': deviceName,
      'deviceToken': deviceToken,
      'employeeId': employeeId,
      'locationId': locationId,
      'id': id,
      'createdBy': createdBy,
      'createdDate': createdDate?.toIso8601String(),
      'isActive': isActive,
    };
  }
}
