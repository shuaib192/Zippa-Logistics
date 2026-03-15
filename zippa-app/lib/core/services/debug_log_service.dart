import 'package:flutter/material.dart';

class DebugLogService {
  static final ValueNotifier<List<String>> logs = ValueNotifier([]);

  static void addLog(String message) {
    final time = DateTime.now().toString().split(' ').last.substring(0, 8);
    logs.value = [...logs.value, '[$time] $message'];
    if (logs.value.length > 50) {
      logs.value = logs.value.sublist(logs.value.length - 50);
    }
  }

  static void showDebugOverlay(BuildContext context) {
    OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🚀 Zippa Debug', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const Divider(color: Colors.white24),
                ValueListenableBuilder<List<String>>(
                  valueListenable: logs,
                  builder: (context, currentLogs, _) {
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: currentLogs.length,
                        itemBuilder: (context, index) => Text(
                          currentLogs[currentLogs.length - 1 - index],
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlayEntry);
  }
}
