import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _dayStartKey = 'day_start_time';
  static const String _dayEndKey = 'day_end_time';
  static const String _printerIpKey = 'printer_ip_address';
  static const String _printerNameKey = 'printer_name';
  static const String _printer2IpKey = 'printer2_ip_address';
  static const String _printer2NameKey = 'printer2_name';
  
  // Varsayılan değerler
  static const String defaultDayStart = '00:00';
  static const String defaultDayEnd = '23:59';
  static const String defaultPrinterName = 'POS80 Printer';
  static const String defaultPrinter2Name = 'POS80 Printer 2';

  Future<void> setDayStartTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dayStartKey, time);
  }

  Future<void> setDayEndTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dayEndKey, time);
  }

  Future<void> setPrinterIpAddress(String ipAddress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_printerIpKey, ipAddress);
  }

  Future<void> setPrinterName(String printerName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_printerNameKey, printerName);
  }

  Future<void> setPrinter2IpAddress(String ipAddress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_printer2IpKey, ipAddress);
  }

  Future<void> setPrinter2Name(String printerName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_printer2NameKey, printerName);
  }

  Future<String> getDayStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dayStartKey) ?? defaultDayStart;
  }

  Future<String> getDayEndTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dayEndKey) ?? defaultDayEnd;
  }

  Future<String?> getPrinterIpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_printerIpKey);
  }

  Future<String> getPrinterName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_printerNameKey) ?? defaultPrinterName;
  }

  Future<String?> getPrinter2IpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_printer2IpKey);
  }

  Future<String> getPrinter2Name() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_printer2NameKey) ?? defaultPrinter2Name;
  }

  Future<DateTime> getStartDateTime(DateTime date) async {
    final startTime = await getDayStartTime();
    final parts = startTime.split(' ')[0].split(':'); // (+1) varsa yoksay
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  Future<DateTime> getEndDateTime(DateTime date) async {
    final endTime = await getDayEndTime();
    final parts = endTime.split(' ');
    final timeParts = parts[0].split(':');
    final isNextDay = parts.length > 1 && parts[1] == '(+1)';
    
    return DateTime(
      date.year,
      date.month,
      date.day + (isNextDay ? 1 : 0),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }
} 