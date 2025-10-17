import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'HearingAidControlScreen.dart';

class CustomStatusBar extends StatelessWidget {
  final String primaryText;
  final String secondaryText;
  final Widget icon;
  final bool showLoader;

  const CustomStatusBar({
    required this.primaryText,
    required this.secondaryText,
    required this.icon,
    this.showLoader = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF34C4E3), Color(0xFFFFFFFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  secondaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryText.contains('failed') ? Colors.red : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          if (showLoader)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.icon = Icons.hearing,
    this.iconColor = const Color(0xFF034573),
    this.barHeight = 56,
    this.onBack,
    this.backgroundColor = Colors.transparent,
    this.titleStyle,
    this.showBottomDivider = false,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final double barHeight;
  final VoidCallback? onBack;
  final Color backgroundColor;
  final TextStyle? titleStyle;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    final defaultTitleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: iconColor,
    );

    return Material(
      color: backgroundColor,
      child: Container(
        height: barHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        decoration: showBottomDivider
            ? BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.15), width: 0.5),
          ),
        )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: InkResponse(
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  // Uncomment for icon if needed
                  // child: Icon(icon, size: 24, color: iconColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle ?? defaultTitleStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceListSection extends StatelessWidget {
  final List<ScanResult> scanResults;
  final bool isScanning;
  final bool isConnecting;
  final BluetoothDevice? selectedDevice;
  final Function(BluetoothDevice) onDeviceTap;

  const DeviceListSection({
    required this.scanResults,
    required this.isScanning,
    required this.isConnecting,
    required this.selectedDevice,
    required this.onDeviceTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        child: Column(
          children: [
            if (isScanning && !isConnecting)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Found ${scanResults.length} devices',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              )
            else if (isConnecting && selectedDevice != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  selectedDevice!.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            Expanded(
              child: scanResults.isEmpty && !isScanning
                  ? Center(
                child: Text(
                  'No devices found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: scanResults.length,
                itemBuilder: (context, index) {
                  final result = scanResults[index];
                  final device = result.device;
                  final isSelected = selectedDevice?.id == device.id;

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      onDeviceTap(device);
                      HapticFeedback.selectionClick();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(color: const Color(0xFF34C4E3), width: 2)
                            : null,
                        gradient: LinearGradient(
                          colors: isSelected
                              ? [
                            const Color(0xFFF0FBFD),
                            const Color(0xFFE6F8FA)
                          ]
                              : [Colors.white, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(27),
                                gradient: LinearGradient(
                                  colors: isSelected
                                      ? [
                                    const Color(0xFF34C4E3),
                                    const Color(0xFF2AAEC9),
                                  ]
                                      : [Colors.white, Colors.grey[100]!],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                    offset: const Offset(2, 4),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.9),
                                    blurRadius: 4,
                                    offset: const Offset(-2, -2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.bluetooth,
                                color: isSelected ? Colors.white : Colors.grey[600],
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.name.isNotEmpty ? device.name : 'Unnamed Device',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BLEScannerScreen extends StatefulWidget {
  @override
  _BLEScannerScreenState createState() => _BLEScannerScreenState();
}

class _BLEScannerScreenState extends State<BLEScannerScreen> with WidgetsBindingObserver {
  final Guid apdServiceUuid = Guid('e093f3b5-00a3-a9e5-9eca-40016e0edc24');
  final Guid readCharUuid = Guid('e093f3b5-00a3-a9e5-9eca-40026e0edc24');
  final Guid writeCharUuid = Guid('e093f3b5-00a3-a9e5-9eca-40036e0edc24');

  List<ScanResult> scanResults = [];
  BluetoothDevice? selectedDevice;

  bool isScanning = false;
  bool isConnecting = false;
  String connectionStatus = 'Not Connected';
  String? connectionError;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _bluetoothStateSubscription;

  // Flag to prevent multiple Bluetooth off dialogs
  bool _isBluetoothOffDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionsAndStart();

    _bluetoothStateSubscription = FlutterBluePlus.state.listen((state) {
      if (state == BluetoothAdapterState.on) {
        Future.delayed(const Duration(seconds: 1), () {
          if (!isScanning) {
            _startScan();
          }
        });
        _isBluetoothOffDialogShowing = false;
      } else if (state == BluetoothAdapterState.off) {
        _stopScan();
        if (!_isBluetoothOffDialogShowing && mounted) {
          _isBluetoothOffDialogShowing = true;
          _showBluetoothOffDialog();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bluetoothStateSubscription?.cancel();
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _checkPermissionsAndStart();
      });
    }
  }

  Future<void> _checkPermissionsAndStart() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses.values.any((status) => status != PermissionStatus.granted)) {
      if (!mounted) return;
      _showPermissionDialog();
    } else {
      await _stopScan();
      await Future.delayed(const Duration(milliseconds: 300));
      if (!isScanning) {
        _listenToScanResults();
        await _startScan();
      }
    }
  }

  void _listenToScanResults() {
    _scanSubscription ??= FlutterBluePlus.scanResults.listen((results) {
      final Map<String, ScanResult> filtered = {};
      for (final r in results) {
        if (r.device.name.isNotEmpty) {
          filtered[r.device.id.id] = r;
        }
      }
      if (!mounted) return;
      setState(() {
        scanResults = filtered.values.toList()
          ..sort((a, b) => b.rssi.compareTo(a.rssi));
      });
    });
  }

  Future<void> _startScan() async {
    if (isScanning) return;
    final bluetoothOn = await FlutterBluePlus.isOn;
    if (!bluetoothOn) {
      if (!mounted) return;
      if (!_isBluetoothOffDialogShowing) {
        _isBluetoothOffDialogShowing = true;
        _showBluetoothOffDialog();
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      isScanning = true;
      scanResults.clear();
      selectedDevice = null;
      connectionStatus = 'Not Connected';
      connectionError = null;
    });

    try {
      await FlutterBluePlus.startScan();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isScanning = false;
        connectionError = 'Scan failed: $e';
      });
      _showErrorDialog('Scan failed: $e');
    }
  }

  Future<void> _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      isScanning = false;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (isConnecting) return;
    if (!mounted) return;
    setState(() {
      selectedDevice = device;
      isConnecting = true;
      connectionStatus = 'Connecting to.......';
      connectionError = null;
    });

    await _stopScan();

    try {
      await selectedDevice?.disconnect();
      await Future.delayed(const Duration(milliseconds: 3000));

      await device.connect(timeout: const Duration(seconds: 30), autoConnect: false);

      final services = await device.discoverServices();

      BluetoothCharacteristic? readChar;
      BluetoothCharacteristic? writeChar;

      for (final s in services) {
        if (s.uuid == apdServiceUuid) {
          for (final c in s.characteristics) {
            if (c.uuid == readCharUuid) {
              readChar = c;
            } else if (c.uuid == writeCharUuid) {
              writeChar = c;
            }
          }
        }
      }

      if (readChar == null || writeChar == null) {
        if (!mounted) return;
        setState(() {
          connectionStatus = 'Not Connected';
          connectionError = 'APD characteristics missing';
          isConnecting = false;
        });
        _showErrorDialog('Please Select a Valid Device');
        _startScan();
        return;
      }

      // First Handshake
      final firstHandshake = Uint8List.fromList([
        0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9,
        0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0x00,
        0x0A, 0xAE, 0x00, 0x76, 0x2F, 0xDA,
        0x18, 0x18, 0xDA, 0x2F, 0x76, 0xDC
      ]);
      await writeChar.write(firstHandshake, withoutResponse: false);
      final firstReply = await readChar.read();

      final expectedFirstReply = [
        0xC9, 0x00, 0x0A, 0xAE, 0x01, 0x17, 0x7F,
        0x4F, 0x1C, 0xE8, 0x85, 0x7D, 0x2B, 0xC5
      ];

      if (firstReply.length != 14 ||
          !const ListEquality().equals(firstReply, expectedFirstReply)) {
        await device.disconnect();
        if (!mounted) return;
        setState(() {
          connectionStatus = 'Not Connected';
          connectionError = 'handshake failed';
          isConnecting = false;
        });
        _showErrorDialog("handshake failed. Device not compatible.");
        _startScan();
        return;
      }

      // Second Handshake
      final secondHandshake = Uint8List.fromList([
        0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9,
        0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0x00,
        0x0A, 0xAE, 0x02, 0xCF, 0x6D, 0x93,
        0xEB, 0x90, 0x2A, 0x75, 0x15, 0xAE
      ]);
      await writeChar.write(secondHandshake, withoutResponse: false);
      final secondReply = await readChar.read();

      final expectedSecondReply = [
        0xC9, 0x00, 0x0A, 0xAE, 0x03, 0x33, 0xDE,
        0xB3, 0xC5, 0x94, 0xAD, 0xC8, 0x6A, 0xAD
      ];

      if (secondReply.length != 14 ||
          !const ListEquality().equals(secondReply, expectedSecondReply)) {
        await device.disconnect();
        if (!mounted) return;
        setState(() {
          connectionStatus = 'Not Connected';
          connectionError = 'handshake failed';
          isConnecting = false;
        });
        _showErrorDialog("handshake failed. Device not compatible.");
        _startScan();
        return;
      }

      // Listening Program Query
      final programQueryCmd = Uint8List.fromList([
        0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9,
        0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0x00,
        0x0A, 0xA0, 0x51, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0xF1
      ]);
      await writeChar.write(programQueryCmd, withoutResponse: false);
      final programReply = await readChar.read();

      int batteryLevel = 0;
      int programCount = 0;
      int activeProgram = 0;

      if (programReply.length == 8) {
        final connStatus = programReply[4];
        final programCountByte = programReply[5];
        final activeProgramByte = programReply[6];

        if (connStatus == 0x00) {
          batteryLevel = 85; // Replace with actual battery reading
          programCount = programCountByte;
          activeProgram = activeProgramByte;
        } else {
          await device.disconnect();
          if (!mounted) return;
          setState(() {
            connectionStatus = 'Not Connected';
            connectionError = 'HA reported connection error (code: $connStatus)';
            isConnecting = false;
          });
          _showErrorDialog("Connection error from hearing aid (code: $connStatus).");
          _startScan();
          return;
        }
      } else {
        await device.disconnect();
        if (!mounted) return;
        setState(() {
          connectionStatus = 'Not Connected';
          connectionError = 'Invalid program reply format (length ${programReply.length})';
          isConnecting = false;
        });
        _showErrorDialog("Device returned invalid program reply.");
        _startScan();
        return;
      }

      final Uint8List noiseCancellationQueryCmd = Uint8List.fromList([
        0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9,
        0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0x00,
        0x0A, 0xA0, 0x54,
        0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0xF4
      ]);

      await writeChar.write(noiseCancellationQueryCmd, withoutResponse: false);
      final noiseCancellationReply = await readChar.read();

      bool noiseCancellationOn = false;
      if (noiseCancellationReply.length >= 6) {
        noiseCancellationOn = noiseCancellationReply[5] == 0x01;
      } else {
        await device.disconnect();
        if (!mounted) return;
        setState(() {
          connectionStatus = 'Not Connected';
          connectionError = 'Invalid noise cancellation reply';
          isConnecting = false;
        });
        _showErrorDialog("Device returned invalid noise cancellation status.");
        _startScan();
        return;
      }

      if (!mounted) return;
      setState(() {
        connectionStatus = 'Connected to ${device.name}';
        connectionError = null;
        isConnecting = false;
      });

      device.connectionState.listen((state) {
        if (!mounted) return;
        if (state == BluetoothConnectionState.disconnected) {
          setState(() {
            connectionStatus = 'Disconnected';
            connectionError = null;
            selectedDevice = null;
          });
        }
      });

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => HearingAidControlScreen(
            device: device,
            readChar: readChar!,
            writeChar: writeChar!,
            batteryLevel: batteryLevel,
            programCount: programCount,
            activeProgram: activeProgram,
            noiseCancellationOn: noiseCancellationOn,
          ),
        ),
      );

      if (!mounted) return;
      setState(() {
        selectedDevice = null;
        connectionStatus = 'Not Connected';
        connectionError = null;
      });

      _startScan();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        connectionStatus = 'Connection failed';
        connectionError = '$e';
        isConnecting = false;
      });
      _showErrorDialog('Failed to connect');
      _startScan();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'This app needs Bluetooth and Location permissions to scan for BLE devices.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Do not call _checkPermissionsAndStart() here,
              // let didChangeAppLifecycleState handle scanning on resume
            },
            child: const Text('Retry'),
          )
        ],
      ),
    );
  }

  void _showBluetoothOffDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.blue,
              size: 48,
            ),
            const SizedBox(height: 20),
            const Text(
              'Please turn on Bluetooth to scan for devices.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isBluetoothOffDialogShowing = false;
              Navigator.of(context).pop();
            },
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (isConnecting) {
      return const Icon(Icons.sync, color: Color(0xFF34C4E3), size: 28);
    }
    if (connectionStatus.startsWith('Connected')) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 28);
    }
    if (connectionError != null) {
      return const Icon(Icons.error, color: Colors.red, size: 28);
    }
    if (isScanning) {
      return const Icon(Icons.bluetooth_searching, color: Color(0xFF34C4E3), size: 28);
    }
    return const Icon(Icons.info, color: Color(0xFF034573), size: 28);
  }

  String _primaryStatusText() {
    if (isConnecting) return connectionStatus;
    if (connectionStatus.startsWith('Connected')) return connectionStatus;
    if (connectionError != null) return 'Connection failed';
    if (isScanning) return 'Scanning for devices...';
    return connectionStatus;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // On back press from scanning page, exit app (or behavior as needed)
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              height: double.infinity,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF34C4E3), Color(0xFFFFFFFF)],
                  stops: [0, 0.95],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const PageHeader(title: ''),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatusIcon(),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _primaryStatusText(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                DeviceListSection(
                  scanResults: scanResults,
                  isScanning: isScanning,
                  isConnecting: isConnecting,
                  selectedDevice: selectedDevice,
                  onDeviceTap: _connectToDevice,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
