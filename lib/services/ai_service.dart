import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/app_config.dart';

/// AI Service for analyzing grievances using Gemini API
class AIService {
  late final GenerativeModel _model;

  AIService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',  // Latest Gemini 2.0 Flash (experimental)
      apiKey: AppConfig.geminiApiKey,
    );
  }

  /// Analyze complaint text and return category, severity, and suggestions
  Future<Map<String, dynamic>> analyzeComplaint(String complaintText) async {
    try {
      // Create a detailed prompt for Gemini
      final prompt = '''
You are an expert campus facilities manager analyzing student grievances.

Analyze this complaint and provide:
1. Category (choose ONE from: ${AppConfig.categories.join(', ')})
2. Severity Score (0-10)
3. Brief reasoning
4. Detailed suggestions for admin on how to resolve this issue

Complaint: "$complaintText"

Severity Guidelines:
- CRITICAL (9-10): Immediate safety hazards, fire, sparking, gas leak, structural damage, emergency
- HIGH (7-8): Major equipment failure, significant damage, urgent repairs needed, affecting many people
- MEDIUM (5-6): Broken equipment, repairs needed, moderate issues, affecting some people
- LOW (3-4): Minor problems, maintenance needed, small improvements
- MINIMAL (1-2): Suggestions, cosmetic issues, non-urgent improvements

Respond in this EXACT JSON format (no markdown, just JSON):
{
  "category": "category_name",
  "severity": number,
  "reasoning": "why this severity and category",
  "suggestions": "Detailed step-by-step action plan for admin to resolve this issue. Include: 1) Immediate actions, 2) Resources needed, 3) Timeline, 4) Safety precautions if applicable, 5) Follow-up steps"
}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null) {
        throw Exception('No response from AI');
      }

      // Parse the response
      final responseText = response.text!.trim();
      
      // Extract JSON from response (handle markdown code blocks)
      String jsonText = responseText;
      if (jsonText.contains('```json')) {
        jsonText = jsonText.split('```json')[1].split('```')[0].trim();
      } else if (jsonText.contains('```')) {
        jsonText = jsonText.split('```')[1].split('```')[0].trim();
      }

      // Parse JSON
      final result = _parseAIResponse(jsonText);
      
      // Validate and adjust severity based on keywords
      final adjustedSeverity = _adjustSeverityWithKeywords(
        complaintText, 
        result['severity'] as int
      );

      return {
        'category': result['category'],
        'severity': adjustedSeverity,
        'reasoning': result['reasoning'],
        'suggestions': result['suggestions'] ?? _generateDefaultSuggestions(result['category'] as String, adjustedSeverity),
      };
    } catch (e) {
      print('AI Analysis Error: $e');
      // Fallback to keyword-based analysis
      return _fallbackAnalysis(complaintText);
    }
  }

  /// Parse AI response
  Map<String, dynamic> _parseAIResponse(String responseText) {
    try {
      // Simple JSON parsing (in production, use dart:convert)
      final categoryMatch = RegExp(r'"category"\s*:\s*"([^"]+)"')
          .firstMatch(responseText);
      final severityMatch = RegExp(r'"severity"\s*:\s*(\d+)')
          .firstMatch(responseText);
      final reasoningMatch = RegExp(r'"reasoning"\s*:\s*"([^"]+)"')
          .firstMatch(responseText);
      final suggestionsMatch = RegExp(r'"suggestions"\s*:\s*"([^"]+)"', multiLine: true, dotAll: true)
          .firstMatch(responseText);

      final category = categoryMatch?.group(1) ?? 'Other';
      final severity = int.tryParse(severityMatch?.group(1) ?? '5') ?? 5;
      final reasoning = reasoningMatch?.group(1) ?? 'AI analysis completed';
      final suggestions = suggestionsMatch?.group(1) ?? '';

      // Validate category
      final validCategory = AppConfig.categories.contains(category) 
          ? category 
          : 'Other';

      return {
        'category': validCategory,
        'severity': severity.clamp(0, 10),
        'reasoning': reasoning,
        'suggestions': suggestions,
      };
    } catch (e) {
      return {
        'category': 'Other',
        'severity': 5,
        'reasoning': 'Default analysis',
        'suggestions': '',
      };
    }
  }

  /// Generate default suggestions based on category and severity
  String _generateDefaultSuggestions(String category, int severity) {
    final urgency = severity >= 8 ? 'URGENT' : severity >= 5 ? 'High Priority' : 'Normal Priority';
    
    final baseSuggestions = {
      'Plumbing': '''
$urgency Action Required:

1. IMMEDIATE ACTIONS:
   - Turn off water supply to affected area
   - Place warning signs if water spillage
   - Assess extent of damage

2. RESOURCES NEEDED:
   - Licensed plumber
   - Plumbing tools and materials
   - Replacement parts if needed

3. TIMELINE:
   - Response: ${severity >= 8 ? '1-2 hours' : '4-8 hours'}
   - Resolution: ${severity >= 8 ? 'Same day' : '1-2 days'}

4. FOLLOW-UP:
   - Test water pressure after repair
   - Check for additional leaks
   - Monitor for 24 hours
''',
      'Electrical': '''
$urgency Action Required:

1. IMMEDIATE ACTIONS:
   - ${severity >= 8 ? 'EVACUATE AREA and cut power immediately' : 'Isolate affected circuit'}
   - Post warning signs
   - Ensure no one uses affected equipment

2. RESOURCES NEEDED:
   - Licensed electrician
   - Electrical testing equipment
   - Replacement components

3. TIMELINE:
   - Response: ${severity >= 8 ? 'IMMEDIATE (within 1 hour)' : '2-4 hours'}
   - Resolution: ${severity >= 8 ? 'Same day' : '1-2 days'}

4. SAFETY PRECAUTIONS:
   - No unauthorized access
   - Fire extinguisher nearby
   - Emergency contacts ready

5. FOLLOW-UP:
   - Full electrical inspection
   - Test all circuits
   - Safety certification
''',
      'Cleaning': '''
$urgency Action Required:

1. IMMEDIATE ACTIONS:
   - Deploy cleaning staff
   - Assess cleaning requirements
   - Gather necessary supplies

2. RESOURCES NEEDED:
   - Cleaning staff (${severity >= 7 ? '2-3 people' : '1-2 people'})
   - Cleaning supplies and equipment
   - Waste disposal bags

3. TIMELINE:
   - Response: ${severity >= 7 ? '2-4 hours' : '4-8 hours'}
   - Resolution: ${severity >= 7 ? 'Same day' : '1-2 days'}

4. FOLLOW-UP:
   - Schedule regular cleaning
   - Implement preventive measures
   - Monitor cleanliness
''',
      'Infrastructure': '''
$urgency Action Required:

1. IMMEDIATE ACTIONS:
   - ${severity >= 8 ? 'Cordon off dangerous area' : 'Inspect damage'}
   - Document with photos
   - Assess structural integrity

2. RESOURCES NEEDED:
   - ${severity >= 8 ? 'Structural engineer' : 'Maintenance team'}
   - Construction materials
   - Safety equipment

3. TIMELINE:
   - Assessment: ${severity >= 8 ? 'IMMEDIATE' : '1-2 days'}
   - Repairs: ${severity >= 8 ? '1-3 days' : '3-7 days'}

4. SAFETY PRECAUTIONS:
   - Restrict access if needed
   - Temporary support if required
   - Safety barriers

5. FOLLOW-UP:
   - Structural inspection
   - Quality check
   - Preventive maintenance plan
''',
    };

    return baseSuggestions[category] ?? '''
$urgency Action Required:

1. IMMEDIATE ACTIONS:
   - Assess the situation
   - Assign responsible personnel
   - Document the issue

2. RESOURCES NEEDED:
   - Appropriate staff/contractor
   - Necessary tools and materials
   - Budget approval if needed

3. TIMELINE:
   - Response: ${severity >= 8 ? '1-2 hours' : severity >= 5 ? '4-8 hours' : '1-2 days'}
   - Resolution: ${severity >= 8 ? 'Same day' : severity >= 5 ? '2-3 days' : '3-7 days'}

4. FOLLOW-UP:
   - Verify resolution
   - Student feedback
   - Preventive measures
''';
  }

  /// Adjust severity based on keywords
  int _adjustSeverityWithKeywords(String text, int aiSeverity) {
    final lowerText = text.toLowerCase();
    int maxKeywordSeverity = 0;

    // Check for severity keywords
    AppConfig.severityKeywords.forEach((keyword, severity) {
      if (lowerText.contains(keyword.toLowerCase())) {
        if (severity > maxKeywordSeverity) {
          maxKeywordSeverity = severity;
        }
      }
    });

    // Return the higher of AI severity or keyword severity
    return maxKeywordSeverity > aiSeverity ? maxKeywordSeverity : aiSeverity;
  }

  /// Fallback analysis when AI fails
  Map<String, dynamic> _fallbackAnalysis(String complaintText) {
    final lowerText = complaintText.toLowerCase();
    
    // Determine category based on keywords
    String category = 'Other';
    if (lowerText.contains('plumb') || lowerText.contains('water') || 
        lowerText.contains('leak') || lowerText.contains('tap')) {
      category = 'Plumbing';
    } else if (lowerText.contains('electric') || lowerText.contains('light') || 
               lowerText.contains('power') || lowerText.contains('spark')) {
      category = 'Electrical';
    } else if (lowerText.contains('clean') || lowerText.contains('dirty') || 
               lowerText.contains('garbage')) {
      category = 'Cleaning';
    } else if (lowerText.contains('security') || lowerText.contains('safe')) {
      category = 'Security';
    } else if (lowerText.contains('wifi') || lowerText.contains('internet') || 
               lowerText.contains('computer')) {
      category = 'IT Support';
    } else if (lowerText.contains('hostel') || lowerText.contains('room')) {
      category = 'Hostel';
    } else if (lowerText.contains('canteen') || lowerText.contains('food')) {
      category = 'Canteen';
    } else if (lowerText.contains('library') || lowerText.contains('book')) {
      category = 'Library';
    } else if (lowerText.contains('building') || lowerText.contains('wall') || 
               lowerText.contains('floor')) {
      category = 'Infrastructure';
    }

    // Calculate severity based on keywords
    int severity = 3; // Default medium-low
    AppConfig.severityKeywords.forEach((keyword, score) {
      if (lowerText.contains(keyword.toLowerCase())) {
        if (score > severity) severity = score;
      }
    });

    return {
      'category': category,
      'severity': severity,
      'reasoning': 'Keyword-based analysis (AI unavailable)',
      'suggestions': _generateDefaultSuggestions(category, severity),
    };
  }
}
