import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_scanner_screen.dart';

class HearingAidControlScreen extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic readChar;
  final BluetoothCharacteristic writeChar;
  final int batteryLevel;
  final int programCount;
  final int activeProgram;
  final bool noiseCancellationOn;

  const HearingAidControlScreen({
    required this.device,
    required this.readChar,
    required this.writeChar,
    required this.batteryLevel,
    required this.programCount,
    required this.activeProgram,
    required this.noiseCancellationOn,
    Key? key,
  }) : super(key: key);

  @override
  State<HearingAidControlScreen> createState() => _HearingAidControlScreenState();
}

class _HearingAidControlScreenState extends State<HearingAidControlScreen> {
  late int currentProgram;
  bool isBusy = false;
  late bool noiseCancellationOn;
  bool initialized = false;

  final List<int> volumeCommandTemplate = [
    0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9,
    0x00, 0x0A, 0xA9, 0x52,
    0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
  ];

  final List<int> programChangeTemplate = [
    0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9,
    0x00, 0x0A, 0xA9, 0x50,
    0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
  ];

  late List<int> noiseCancelOffCommand;
  late List<int> noiseCancelOnCommand;

  int calculateChecksum(List<int> bytes) {
    int sum = 0;
    for (int i = 13; i <= 22; i++) {
      sum += bytes[i];
    }
    return sum & 0xFF;
  }

  Future<Uint8List> _readDataWithTimeout(int expectedLength, Duration timeout) async {
    final buffer = <int>[];
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout && buffer.length < expectedLength) {
      List<int> chunk = await widget.readChar.read();

      if (chunk.isNotEmpty) {
        buffer.addAll(chunk);
        if (buffer.length >= expectedLength) {
          break;
        }
      }
      await Future.delayed(const Duration(milliseconds: 50));
    }
    stopwatch.stop();
    return Uint8List.fromList(buffer);
  }

  Future<void> _sendVolumeCommand(int volumeAction) async {
    if (isBusy) return;
    setState(() => isBusy = true);

    try {
      final cmd = List<int>.from(volumeCommandTemplate);
      cmd[15] = volumeAction;
      cmd[23] = calculateChecksum(cmd);

      await widget.writeChar.write(Uint8List.fromList(cmd), withoutResponse: false);

      final reply = await _readDataWithTimeout(8, const Duration(milliseconds: 500));

      if (reply.length == 8 && reply[4] == 0x00) {
        // Success
      } else {
        final errCode = (reply.length >= 6) ? reply[2] : -1;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Volume change failed. Error code: $errCode')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('BLE error during volume change: $e')),
      );
    } finally {
      setState(() => isBusy = false);
    }
  }

  Future<void> _changeProgram(int newProgram) async {
    if (isBusy) return;
    setState(() => isBusy = true);

    try {
      final cmd = List<int>.from(programChangeTemplate);
      cmd[15] = newProgram;
      cmd[23] = calculateChecksum(cmd);

      await widget.writeChar.write(Uint8List.fromList(cmd), withoutResponse: false);

      final reply = await _readDataWithTimeout(8, const Duration(milliseconds: 500));

      if (reply.length == 8 && reply[4] == 0x00) {
        setState(() => currentProgram = newProgram);
      } else {
        final errCode = (reply.length >= 6) ? reply[2] : -1;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Program change failed. Error code: $errCode')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('BLE error during program change: $e')),
      );
    } finally {
      setState(() => isBusy = false);
    }
  }

  Future<void> _increaseVolume() => _sendVolumeCommand(0x01);
  Future<void> _decreaseVolume() => _sendVolumeCommand(0x02);

  Future<void> _nextProgram() async {
    if (currentProgram < widget.programCount) {
      await _changeProgram(currentProgram + 1);
    }
  }

  Future<void> _prevProgram() async {
    if (currentProgram > 1) {
      await _changeProgram(currentProgram - 1);
    }
  }

  Future<void> _setNoiseCancellation(bool enable) async {
    if (isBusy) return;
    setState(() => isBusy = true);

    try {
      final cmd = enable ? List<int>.from(noiseCancelOnCommand) : List<int>.from(noiseCancelOffCommand);
      cmd[15] = enable ? 0x01 : 0x00;
      cmd[23] = calculateChecksum(cmd);

      await widget.writeChar.write(Uint8List.fromList(cmd), withoutResponse: false);

      final reply = await _readDataWithTimeout(8, const Duration(milliseconds: 500));

      if (reply.length == 8 && reply[4] == 0x00) {
        setState(() {
          noiseCancellationOn = enable;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Noise cancellation toggle failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Noise cancellation toggle error: $e')),
      );
    } finally {
      setState(() => isBusy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    currentProgram = widget.activeProgram;

    noiseCancellationOn = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        noiseCancellationOn = widget.noiseCancellationOn;
        initialized = true;
      });
    });

    noiseCancelOffCommand = [
      0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9, 0xC9,
      0xC9, 0xC9, 0xC9, 0x00, 0x0A, 0xA9, 0x54,
      0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00,
    ];

    noiseCancelOnCommand = List<int>.from(noiseCancelOffCommand);
  }

  Widget _dynamicNoiseCancelIcon(bool isOn) {
    return Container(
      width: 30,
      height: 6,
      decoration: BoxDecoration(
        color: isOn ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    double cardHeight = 180;

    return WillPopScope(
      onWillPop: () async {
        try {
          await widget.device.disconnect();
        } catch (_) {}
        Navigator.of(context).pop(true); // send disconnection info back
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
                  colors: [
                    Color(0xFF34C4E3),
                    Colors.white,
                    Color(0xFFFFFFFF),
                  ],
                  stops: [0.0, 0.95, 0.0],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Container(
                    height: 80,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.device.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _batteryChip(widget.batteryLevel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: cardHeight,
                    width: MediaQuery.of(context).size.width - 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _SectionTitle("Volume"),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _iconOnlyControlCard(
                                Icons.remove,
                                isBusy ? null : _decreaseVolume,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.volume_up,
                                    size: 28,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _iconOnlyControlCard(
                                Icons.add,
                                isBusy ? null : _increaseVolume,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: cardHeight,
                    width: MediaQuery.of(context).size.width - 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _SectionTitle("Listening Program"),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _iconOnlyControlCard(
                                Icons.arrow_left,
                                (currentProgram > 1 && !isBusy) ? _prevProgram : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _programPill(currentProgram, widget.programCount),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _iconOnlyControlCard(
                                Icons.arrow_right,
                                (currentProgram < widget.programCount && !isBusy) ? _nextProgram : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: cardHeight,
                    width: MediaQuery.of(context).size.width - 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _SectionTitle("Noise Cancellation"),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _iconOnlyControlCard(
                                null,
                                isBusy || !noiseCancellationOn ? null : () => _setNoiseCancellation(false),
                                label: "OFF",
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: _dynamicNoiseCancelIcon(noiseCancellationOn),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _iconOnlyControlCard(
                                null,
                                isBusy || noiseCancellationOn ? null : () => _setNoiseCancellation(true),
                                label: "ON",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppColors {
  static const primary = Color(0xFF34C4E3);
  static const primaryDark = Color(0xFF034573);
  static const surface = Color(0xFFF7FBFD);
  static const card = Colors.white;
  static const shadow = Color(0x1A034573);
  static const disabled = Color(0xFFBFDCE8);
  static const disabledBG = Color(0xFFC5D7E8);
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryDark,
      ),
      textAlign: TextAlign.center,
    );
  }
}

Widget _batteryChip(int level) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.primary.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          level >= 80
              ? Icons.battery_full
              : level >= 50
              ? Icons.battery_6_bar
              : level >= 20
              ? Icons.battery_3_bar
              : Icons.battery_alert,
          color: AppColors.primaryDark,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          '$level%',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    ),
  );
}

Widget _programPill(int current, int total) {
  return Container(
    height: 64,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, Color(0xFFFFFFFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Center(
      child: Text(
        '$current/$total',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryDark,
          letterSpacing: 0.3,
        ),
      ),
    ),
  );
}

Widget _iconOnlyControlCard(IconData? icon, VoidCallback? onTap, {String? label}) {
  final enabled = onTap != null;
  double circleSize = 60;

  return Material(
    color: AppColors.card,
    elevation: 2,
    shadowColor: AppColors.shadow,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      splashColor: AppColors.primary.withOpacity(0.12),
      highlightColor: AppColors.primary.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.primary.withOpacity(0.12)
                  : AppColors.disabled.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: label != null
                ? Center(
              child: Text(
                label,
                style: TextStyle(
                  color: enabled ? AppColors.primaryDark : AppColors.disabled,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
                : Icon(
              icon,
              color: enabled ? AppColors.primaryDark : AppColors.disabled,
              size: 36,
            ),
          ),
        ),
      ),
    ),
  );
}
