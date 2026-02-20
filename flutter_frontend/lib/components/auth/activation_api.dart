
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../access/access.dart';

class ActivationService {
  static const String _activationKey = "is_activated";

  Future<String> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isWindows) {
        WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
        return windowsInfo.deviceId; 
      } else if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? "unknown_ios_id";
      } else if (Platform.isLinux) {
        LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
        return linuxInfo.machineId ?? "unknown_linux_id";
      } else if (Platform.isMacOS) {
        MacOsDeviceInfo macosInfo = await deviceInfo.macOsInfo;
        return macosInfo.systemGUID ?? "unknown_macos_id";
      }
    } catch (e) {
      print("Error getting device id: $e");
    }
    return "unknown_device_id";
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
