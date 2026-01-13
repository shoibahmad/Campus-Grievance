/// App Configuration
/// Contains API keys and configuration constants
class AppConfig {
  // Gemini API Configuration
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  
  // Firebase Configuration (will be auto-configured via google-services.json)
  
  // App Constants
  static const String appName = 'Campus Grievance';
  static const String appVersion = '1.0.0';
  
  // Categories
  static const List<String> categories = [
    'Plumbing',
    'Electrical',
    'Infrastructure',
    'Cleaning',
    'Security',
    'IT Support',
    'Hostel',
    'Canteen',
    'Library',
    'Other',
  ];
  
  // Severity Keywords
  static const Map<String, int> severityKeywords = {
    // Critical (8-10)
    'sparking': 10,
    'fire': 10,
    'emergency': 10,
    'urgent': 9,
    'danger': 9,
    'broken': 8,
    'overflowing': 8,
    'leaking': 8,
    
    // High (6-7)
    'damaged': 7,
    'not working': 7,
    'faulty': 6,
    'problem': 6,
    
    // Medium (4-5)
    'issue': 5,
    'concern': 5,
    'needs attention': 4,
    'repair': 4,
    
    // Low (1-3)
    'minor': 3,
    'small': 2,
    'suggestion': 1,
  };
}
