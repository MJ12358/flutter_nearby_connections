import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';

void main() {
  runApp(const MyApp());
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute<void>(builder: (_) => const Home());
    case 'browser':
      return MaterialPageRoute<void>(
        builder: (_) => const DevicesListScreen(deviceType: DeviceType.browser),
      );
    case 'advertiser':
      return MaterialPageRoute<void>(
        builder: (_) =>
            const DevicesListScreen(deviceType: DeviceType.advertiser),
      );
    default:
      return MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('No route defined for ${settings.name}'),
          ),
        ),
      );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      onGenerateRoute: generateRoute,
      initialRoute: '/',
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, 'browser');
              },
              child: Container(
                color: Colors.red,
                child: const Center(
                  child: Text(
                    'BROWSER',
                    style: TextStyle(color: Colors.white, fontSize: 40),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, 'advertiser');
              },
              child: Container(
                color: Colors.green,
                child: const Center(
                  child: Text(
                    'ADVERTISER',
                    style: TextStyle(color: Colors.white, fontSize: 40),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum DeviceType { advertiser, browser }

class DevicesListScreen extends StatefulWidget {
  const DevicesListScreen({super.key, required this.deviceType});

  final DeviceType deviceType;

  @override
  _DevicesListScreenState createState() => _DevicesListScreenState();
}

class _DevicesListScreenState extends State<DevicesListScreen> {
  List<Device> devices = <Device>[];
  List<Device> connectedDevices = <Device>[];
  late NearbyService nearbyService;
  late StreamSubscription subscription;
  late StreamSubscription receivedDataSubscription;

  bool isInit = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    subscription.cancel();
    receivedDataSubscription.cancel();
    nearbyService.stopBrowsing();
    nearbyService.stopAdvertising();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deviceType.toString().substring(11).toUpperCase()),
      ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        itemCount: getItemCount(),
        itemBuilder: (BuildContext context, int index) {
          final Device device = widget.deviceType == DeviceType.advertiser
              ? connectedDevices[index]
              : devices[index];
          return Container(
            margin: const EdgeInsets.all(8.0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _onTabItemListener(device),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(device.deviceName),
                            Text(
                              getStateName(device.state),
                              style: TextStyle(
                                color: getStateColor(device.state),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Request connect
                    GestureDetector(
                      onTap: () => _onButtonClicked(device),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        padding: const EdgeInsets.all(8.0),
                        height: 35,
                        width: 100,
                        color: getButtonColor(device.state),
                        child: Center(
                          child: Text(
                            getButtonStateName(device.state),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8.0,
                ),
                const Divider(
                  height: 1,
                  color: Colors.grey,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String getStateName(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
        return 'disconnected';
      case SessionState.connecting:
        return 'waiting';
      default:
        return 'connected';
    }
  }

  String getButtonStateName(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
      case SessionState.connecting:
        return 'Connect';
      default:
        return 'Disconnect';
    }
  }

  Color getStateColor(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
        return Colors.black;
      case SessionState.connecting:
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  Color getButtonColor(SessionState state) {
    switch (state) {
      case SessionState.notConnected:
      case SessionState.connecting:
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  _onTabItemListener(Device device) {
    if (device.state == SessionState.connected) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          final TextEditingController myController = TextEditingController();
          return AlertDialog(
            title: const Text('Send message'),
            content: TextField(controller: myController),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Send'),
                onPressed: () {
                  nearbyService.sendMessage(
                    deviceId: device.deviceId,
                    message: myController.text,
                  );
                  myController.text = '';
                },
              ),
            ],
          );
        },
      );
    }
  }

  int getItemCount() {
    if (widget.deviceType == DeviceType.advertiser) {
      return connectedDevices.length;
    } else {
      return devices.length;
    }
  }

  _onButtonClicked(Device device) {
    switch (device.state) {
      case SessionState.notConnected:
        nearbyService.invitePeer(
          deviceId: device.deviceId,
          deviceName: device.deviceName,
        );
      case SessionState.connected:
        nearbyService.disconnectPeer(deviceId: device.deviceId);
      case SessionState.connecting:
        break;
    }
  }

  Future<void> init() async {
    nearbyService = NearbyService();
    String devInfo = '';
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      devInfo = androidInfo.model;
    }
    if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      devInfo = iosInfo.localizedModel;
    }
    await nearbyService.init(
      serviceType: 'mpconn',
      deviceName: devInfo,
      strategy: Strategy.P2P_CLUSTER,
      callback: (bool isRunning) async {
        if (isRunning) {
          if (widget.deviceType == DeviceType.browser) {
            await nearbyService.stopBrowsing();
            await Future<void>.delayed(const Duration(microseconds: 200));
            await nearbyService.startBrowsing();
          } else {
            await nearbyService.stopAdvertising();
            await nearbyService.stopBrowsing();
            await Future<void>.delayed(const Duration(microseconds: 200));
            await nearbyService.startAdvertising();
            await nearbyService.startBrowsing();
          }
        }
      },
    );
    // subscription = nearbyService.stateChangedSubscription(
    //   callback: (List<Device> devicesList) {
    //     for (final Device element in devicesList) {
    //       if (Platform.isAndroid) {
    //         if (element.state == SessionState.connected) {
    //           nearbyService.stopBrowsing();
    //         } else {
    //           nearbyService.startBrowsing();
    //         }
    //       }
    //     }

    //     setState(() {
    //       devices.clear();
    //       devices.addAll(devicesList);
    //       connectedDevices.clear();
    //       connectedDevices.addAll(
    //         devicesList
    //             .where((Device d) => d.state == SessionState.connected)
    //             .toList(),
    //       );
    //     });
    //   },
    // );

    // receivedDataSubscription = nearbyService.dataReceivedSubscription(
    //   callback: (data) {
    //     showToast(
    //       jsonEncode(data),
    //       context: context,
    //       axis: Axis.horizontal,
    //       alignment: Alignment.center,
    //       position: StyledToastPosition.bottom,
    //     );
    //   },
    // );
  }
}
