import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../access/access.dart';

class ActivationService {
  static const String _activationKey = "is_activated";
  static const String _deviceIdKey = "persistent_device_id";

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Use cached ID if available to ensure persistence
    String? storedId = prefs.getString(_deviceIdKey);
    if (storedId != null && storedId.isNotEmpty) {
      return storedId;
    }

    String deviceId = "unknown_device_id";
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    try {
      if (kIsWeb) {
        WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
        // Combine multiple properties for a "pseudo-id" on web
        deviceId = "web_${webInfo.vendor}_${webInfo.userAgent?.hashCode}";
      } else if (Platform.isWindows) {
        WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
        deviceId = windowsInfo.deviceId.replaceAll('{', '').replaceAll('}', '');
      } else if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? "unknown_ios_id";
      } else if (Platform.isLinux) {
        LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
        deviceId = linuxInfo.machineId ?? "unknown_linux_id";
      } else if (Platform.isMacOS) {
        MacOsDeviceInfo macosInfo = await deviceInfo.macOsInfo;
        deviceId = macosInfo.systemGUID ?? "unknown_macos_id";
      }
    } catch (e) {
      debugPrint("Error getting device info: $e");
    }

    // If still unknown or empty after platform-specific attempt, generate a random one
    if (deviceId == "unknown_device_id" || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
    }

    // Save for future use
    await prefs.setString(_deviceIdKey, deviceId);
    return deviceId;
  }

  Future<bool> isActivated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_activationKey) ?? false;
  }

  Future<Map<String, dynamic>> activate(String productKey) async {
    String deviceId = await getDeviceId();
    
    try {
      final response = await http.post(
        Uri.parse(createApiUrl('api/activate/')),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "product_key": productKey,
          "device_id": deviceId,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_activationKey, true);
        return {"success": true, "message": data['message']};
      } else {
        return {"success": false, "message": data['message'] ?? "Activation failed"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
