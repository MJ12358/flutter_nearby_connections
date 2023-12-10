part of flutter_nearby_connections;

/// The class [Message] data transmitted between two peers.
/// it will contain [Message.deviceId] and [Message.message]
class Message {
  /// Sender's ID
  final String deviceId;

  /// Data will be kept here, in text type
  final String message;

  Message(this.deviceId, this.message);

  factory Message.fromJson(Map<String, Object> json) {
    return Message(
      json['deviceId']! as String,
      json['message']! as String,
    );
  }
}
