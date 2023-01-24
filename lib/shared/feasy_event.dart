class FeasyEventType {
  static String HELLO = "HELLO";
  static String TRANSFER = "TRANSFER";
  static String HEARTBEAT = "HEARTBEAT";
}

class FeasyEvent {
  FeasyEvent({this.type, this.data});

  String? type;
  String? data;

  static FeasyEvent fromJson(Map json) =>
      FeasyEvent(type: json['type'], data: json['data']);

  Map<String, String?> toJson() => {'type': type, 'data': data};
}
