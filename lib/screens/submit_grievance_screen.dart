import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/grievance.dart';
import '../services/ai_service.dart';
import '../services/firebase_service.dart';

class SubmitGrievanceScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentEmail;

  const SubmitGrievanceScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
  });

  @override
  State<SubmitGrievanceScreen> createState() => _SubmitGrievanceScreenState();
}

class _SubmitGrievanceScreenState extends State<SubmitGrievanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  final AIService _aiService = AIService();
  final FirebaseService _firebaseService = FirebaseService();
  
  bool _isAnalyzing = false;
  bool _isSubmitting = false;
  String? _detectedCategory;
  int? _detectedSeverity;
  String? _aiReasoning;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _analyzeComplaint() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description first'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _aiService.analyzeComplaint(
        _descriptionController.text,
      );

      setState(() {
        _detectedCategory = result['category'];
        _detectedSeverity = result['severity'];
        _aiReasoning = result['reasoning'];
        _isAnalyzing = false;
      });

      // Show analysis result
      if (mounted) {
        _showAnalysisDialog();
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showAnalysisDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('AI Analysis Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalysisItem(
              'Category',
              _detectedCategory ?? 'Unknown',
              Icons.category_outlined,
              AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            _buildAnalysisItem(
              'Severity Score',
              '${_detectedSeverity ?? 0}/10',
              Icons.priority_high,
              AppTheme.getSeverityColor(_detectedSeverity ?? 0),
            ),
            const SizedBox(height: 16),
            Text(
              'Reasoning:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _aiReasoning ?? 'No reasoning provided',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ).animate().scale(),
    );
  }

  Widget _buildAnalysisItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitGrievance() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_detectedCategory == null || _detectedSeverity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please analyze the complaint first'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final grievance = Grievance(
        id: const Uuid().v4(),
        studentId: widget.studentId,
        studentName: widget.studentName,
        studentEmail: widget.studentEmail,
        title: _titleController.text,
        description: _descriptionController.text,
        category: _detectedCategory!,
        severityScore: _detectedSeverity!,
        createdAt: DateTime.now(),
        location: _locationController.text,
      );

      await _firebaseService.submitGrievance(grievance);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grievance submitted successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title Field
                        Text(
                          'Title',
                          style: Theme.of(context).textTheme.titleMedium,
                        ).animate().fadeIn().slideX(),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            hintText: 'Brief title for your complaint',
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 100.ms).slideX(),
                        
                        const SizedBox(height: 24),
                        
                        // Description Field
                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.titleMedium,
                        ).animate().fadeIn(delay: 200.ms).slideX(),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            hintText: 'Describe your complaint in detail...',
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 5,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 300.ms).slideX(),
                        
                        const SizedBox(height: 24),
                        
                        // Location Field
                        Text(
                          'Location',
                          style: Theme.of(context).textTheme.titleMedium,
                        ).animate().fadeIn(delay: 400.ms).slideX(),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            hintText: 'Where is the issue located?',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a location';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 500.ms).slideX(),
                        
                        const SizedBox(height: 32),
                        
                        // AI Analysis Button
                        ElevatedButton.icon(
                          onPressed: _isAnalyzing ? null : _analyzeComplaint,
                          icon: _isAnalyzing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            _isAnalyzing
                                ? 'Analyzing with AI...'
                                : 'Analyze with AI',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ).animate().fadeIn(delay: 600.ms).slideY(),
                        
                        // Analysis Result
                        if (_detectedCategory != null && _detectedSeverity != null)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.getSeverityColor(_detectedSeverity!)
                                    .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.successColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Analysis Complete',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildResultChip(
                                        'Category',
                                        _detectedCategory!,
                                        AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildResultChip(
                                        'Severity',
                                        '$_detectedSeverity/10',
                                        AppTheme.getSeverityColor(
                                          _detectedSeverity!,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideY(),
                        
                        const SizedBox(height: 32),
                        
                        // Submit Button
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitGrievance,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            _isSubmitting
                                ? 'Submitting...'
                                : 'Submit Grievance',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ).animate().fadeIn(delay: 700.ms).slideY(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            color: AppTheme.textPrimary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Submit Complaint',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                Text(
                  'AI will analyze and prioritize',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn().slideX(),
    );
  }

  Widget _buildResultChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
