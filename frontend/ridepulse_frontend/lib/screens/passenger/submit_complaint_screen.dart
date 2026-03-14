import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../models/complaint_models.dart';
import '../../providers/auth_provider.dart';
import '../../services/complaint_service.dart';

class SubmitComplaintScreen extends StatefulWidget {
  const SubmitComplaintScreen({super.key});

  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ComplaintService _complaintService = ComplaintService();

  String _selectedCategory = ComplaintCategory.DISRUPTIVE_DRIVING;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final request = CreateComplaintRequest(
        passengerId: user.userId,
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
      );

      final complaint = await _complaintService.createComplaint(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complaint submitted successfully!\nComplaint #: ${complaint.complaintNumber}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      /// Return success to previous screen
      context.pop(true);

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );

    } finally {

      if (mounted) {
        setState(() => _isLoading = false);
      }

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text('Submit Complaint'),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              /// INFO CARD
              Card(
                color: Colors.blue.shade50,

                child: const Padding(
                  padding: EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'How to Submit a Complaint',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 8),

                      Text(
                        '1. Select the category that best describes your issue\n'
                        '2. Provide a detailed description\n'
                        '3. Submit and track the status',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// CATEGORY
              const Text(
                'Complaint Category *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: _selectedCategory,

                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),

                items: ComplaintCategory.all.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      ComplaintCategory.getDescription(category),
                    ),
                  );
                }).toList(),

                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),

              const SizedBox(height: 24),

              /// DESCRIPTION
              const Text(
                'Description *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: _descriptionController,
                maxLines: 6,

                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText:
                      'Please provide detailed information about the issue...',
                ),

                validator: (value) {

                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }

                  if (value.length < 10) {
                    return 'Description must be at least 10 characters';
                  }

                  if (value.length > 1000) {
                    return 'Description must be less than 1000 characters';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 32),

              /// SUBMIT BUTTON
              ElevatedButton(

                onPressed: _isLoading ? null : _submitComplaint,

                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),

                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Complaint',
                        style: TextStyle(fontSize: 16),
                      ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}