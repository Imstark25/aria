// Configuration file for API endpoints
// Change this based on whether you're using emulator or real device

class AppConfig {
  // For Android Emulator: use '10.0.2.2'
  // For Real Android Device: use your PC's local IP (e.g., '192.168.1.5')
  // To find your PC's IP on Windows: run 'ipconfig' in command prompt
  // Look for "IPv4 Address" under your active network adapter
  
  // Updated for real device - Your PC's IP: 10.105.136.156
  static const String baseUrl = 'http://10.105.136.156:3000';
  
  // For emulator, use:
  // static const String baseUrl = 'http://10.0.2.2:3000';
  
  // API Endpoints
  static String get createOrderUrl => '$baseUrl/create-order';
  static String get createSubscriptionUrl => '$baseUrl/create-subscription';
}
