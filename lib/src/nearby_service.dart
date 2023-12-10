part of flutter_nearby_connections;

const String _initNearbyService = 'init_nearby_service';
const String _startAdvertisingPeer = 'start_advertising_peer';
const String _stopAdvertisingPeer = 'stop_advertising_peer';
const String _startBrowsingForPeers = 'start_browsing_for_peers';
const String _stopBrowsingForPeers = 'stop_browsing_for_peers';
const String _invitePeer = 'invite_peer';
const String _disconnectPeer = 'disconnect_peer';
const String _sendMessage = 'send_message';
const String _invokeChangeStateMethod = 'invoke_change_state_method';
const String _invokeMessageReceiveMethod = 'invoke_message_receive_method';
const String _invokeNearbyRunning = 'nearby_running';

class NearbyService {
  static const MethodChannel _channel =
      MethodChannel('flutter_nearby_connections');

  final StreamController<List<Device>> _stateChangedController =
      StreamController<List<Device>>.broadcast();

  final StreamController<dynamic> _dataReceivedController =
      StreamController<dynamic>.broadcast();

  String? _deviceName;

  /// The class [NearbyService] supports the discovery of services provided by
  /// nearby devices and supports communicating with those services through
  /// message-based data, streaming data, and resources (such as files).
  /// In iOS, the framework uses infrastructure
  /// Wi-Fi networks, peer-to-peer Wi-Fi,
  /// and Bluetooth personal area networks for the underlying transport.
  /// param [serviceType] max length 15 character,
  /// need to be defined in Info.plist
  ///
  /// <key>NSBonjourServices</key>
  /// 	<array>
  /// 		<string>_[serviceType]._tcp</string>
  /// 	</array>
  ///
  /// param [deviceName] is unique, you should use the UDID for [deviceName]
  /// param [strategy] Nearby Connections supports different Strategies
  /// for advertising and discovery. The best Strategy to use
  /// depends on the use case. only support android OS
  Future<void> init({
    required String serviceType,
    required Strategy strategy,
    String? deviceName,
    required ValueChanged<bool> callback,
  }) async {
    assert(
      serviceType.length <= 15 && serviceType.isNotEmpty,
      'Service type must be less than 15 chars and not empty.',
    );

    _deviceName = deviceName;

    _channel.setMethodCallHandler(_methodCallHandler);

    await _channel.invokeMethod(
      _initNearbyService,
      <String, Object?>{
        'deviceName': deviceName ?? '',
        'serviceType': serviceType,
        'strategy': strategy.value,
      },
    );

    if (Platform.isIOS) {
      await Future<void>.delayed(const Duration(seconds: 1));
      callback(true);
    }
  }

  /// Begins advertising the service provided by a local peer.
  /// The [startAdvertising] publishes an advertisement for a specific service
  /// that your app provides through the flutter_nearby_connections plugin and
  /// notifies its delegate about invitations from nearby peers.
  Future<void> startAdvertising() async {
    await _channel.invokeMethod(_startAdvertisingPeer);
  }

  /// Starts browsing for peers.
  /// Searches (by `serviceType`) for services offered by nearby devices using
  /// infrastructure Wi-Fi, peer-to-peer Wi-Fi, and Bluetooth or Ethernet, and
  /// provides the ability to easily invite
  /// those [Device] to a nearby connections session [SessionState].
  Future<void> startBrowsing() async {
    await _channel.invokeMethod(_startBrowsingForPeers);
  }

  /// Stops advertising this peer device for connection.
  Future<void> stopAdvertising() async {
    await _channel.invokeMethod(_stopAdvertisingPeer);
  }

  /// Stops browsing for peers.
  Future<void> stopBrowsing() async {
    await _channel.invokeMethod(_stopBrowsingForPeers);
  }

  /// Invites a discovered peer to join a nearby connections session.
  /// the [deviceId] is current Device
  Future<void> invitePeer({
    required String deviceId,
    @required String? deviceName,
  }) async {
    await _channel.invokeMethod(
      _invitePeer,
      <String, Object?>{
        'deviceId': deviceId,
        'deviceName': deviceName,
      },
    );
  }

  /// Disconnects the local peer from the session.
  /// the [deviceId] is current Device
  Future<void> disconnectPeer({
    required String? deviceId,
  }) async {
    await _channel.invokeMethod(_disconnectPeer, <String, Object?>{
      'deviceId': deviceId,
    });
  }

  /// Sends a message encapsulated in a Data instance to nearby peers.
  Future<void> sendMessage({
    required String deviceId,
    required String message,
  }) async {
    await _channel.invokeMethod(_sendMessage, <String, Object?>{
      'deviceId': deviceId,
      if (_deviceName != null) 'senderDeviceId': _deviceName,
      'message': message,
    });
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case _invokeChangeStateMethod:
        final List<Device> devices =
            jsonDecode(call.arguments).map<Device>(Device.fromJson).toList();
        _stateChangedController.add(devices);
      case _invokeMessageReceiveMethod:
        _dataReceivedController.add(call.arguments);
      case _invokeNearbyRunning:
        await Future<void>.delayed(const Duration(seconds: 1));
      // callback.call(call.arguments as bool);
    }
  }
}
