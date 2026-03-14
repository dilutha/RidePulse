import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/complaint_models.dart';
import '../../providers/auth_provider.dart';
import '../../services/complaint_service.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {

  final ComplaintService _complaintService = ComplaintService();

  List<Complaint> _complaints = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final complaints = await _complaintService.getComplaintsByPassenger(
        user.userId,
      );

      setState(() {
        _complaints = complaints;
        _isLoading = false;
      });

    } catch (e) {

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case ComplaintStatus.SUBMITTED:
        return Colors.orange;
      case ComplaintStatus.UNDER_REVIEW:
        return Colors.blue;
      case ComplaintStatus.RESOLVED:
        return Colors.green;
      case ComplaintStatus.REJECTED:
        return Colors.red;
      case ComplaintStatus.CLOSED:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case ComplaintStatus.SUBMITTED:
        return Icons.send;
      case ComplaintStatus.UNDER_REVIEW:
        return Icons.pending;
      case ComplaintStatus.RESOLVED:
        return Icons.check_circle;
      case ComplaintStatus.REJECTED:
        return Icons.cancel;
      case ComplaintStatus.CLOSED:
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text('My Complaints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadComplaints,
          ),
        ],
      ),

      body: _buildBody(),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {

          final result = await context.push(
            '/passenger/submit_complaint',
          );

          if (result == true) {
            _loadComplaints();
          }

        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(Icons.error, size: 64, color: Colors.red),

            const SizedBox(height: 16),

            Text('Error: $_error'),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _loadComplaints,
              child: const Text('Retry'),
            ),

          ],
        ),
      );
    }

    if (_complaints.isEmpty) {

      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Icon(Icons.inbox, size: 64, color: Colors.grey),

            SizedBox(height: 16),

            Text(
              'No complaints yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),

            SizedBox(height: 8),

            Text(
              'Tap the + button to submit a complaint',
              style: TextStyle(color: Colors.grey),
            ),

          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComplaints,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _complaints.length,
        itemBuilder: (context, index) {
          return _buildComplaintCard(_complaints[index]);
        },
      ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {

    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),

      child: InkWell(

        onTap: () => _showComplaintDetails(complaint),

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Expanded(
                    child: Text(
                      complaint.complaintNumber ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: _getStatusColor(complaint.status),
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Icon(
                          _getStatusIcon(complaint.status),
                          size: 16,
                          color: Colors.white,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          complaint.status ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              /// CATEGORY
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),

                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),

                child: Text(
                  complaint.categoryDescription ?? complaint.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /// DESCRIPTION
              Text(
                complaint.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              /// DATE
              Row(
                children: [

                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),

                  const SizedBox(width: 4),

                  Text(
                    complaint.submittedAt != null
                        ? dateFormat.format(
                            DateTime.parse(complaint.submittedAt!))
                        : 'N/A',

                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const Spacer(),

                  const Icon(Icons.arrow_forward_ios, size: 16),

                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComplaintDetails(Complaint complaint) {

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (context) {

        return Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                'Complaint Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              const SizedBox(height: 16),

              _buildDetailRow(
                'Complaint Number',
                complaint.complaintNumber ?? 'N/A',
              ),

              _buildDetailRow(
                'Category',
                complaint.categoryDescription ?? complaint.category,
              ),

              _buildDetailRow(
                'Status',
                complaint.status ?? 'N/A',
              ),

              const SizedBox(height: 8),

              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(complaint.description),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(child: Text(value)),

        ],
      ),
    );
  }
}