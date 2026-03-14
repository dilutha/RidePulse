import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/complaint_models.dart';
import '../../providers/auth_provider.dart';
import '../../services/complaint_service.dart';
/**
 * Manage Complaints Screen (Authority)
 * 
 * PRESENTATION LAYER:
 * Allows authorities to view, assign, and resolve complaints
 */
class ManageComplaintsScreen extends StatefulWidget {
  const ManageComplaintsScreen({Key? key}) : super(key: key);
  
  @override
  State<ManageComplaintsScreen> createState() => _ManageComplaintsScreenState();
}

class _ManageComplaintsScreenState extends State<ManageComplaintsScreen> 
    with SingleTickerProviderStateMixin {
  
  final ComplaintService _complaintService = ComplaintService();
  
  late TabController _tabController;
  
  List<Complaint> _unresolvedComplaints = [];
  List<Complaint> _resolvedComplaints = [];
  Map<String, int> _statistics = {};
  
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Load all data in parallel
      final results = await Future.wait([
        _complaintService.getUnresolvedComplaints(),
        _complaintService.getComplaintsByStatus(ComplaintStatus.RESOLVED),
        _complaintService.getComplaintStatistics(),
      ]);
      
      setState(() {
        _unresolvedComplaints = results[0] as List<Complaint>;
        _resolvedComplaints = results[1] as List<Complaint>;
        _statistics = results[2] as Map<String, int>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Complaints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.pending_actions),
              text: 'Unresolved (${_unresolvedComplaints.length})',
            ),
            Tab(
              icon: const Icon(Icons.check_circle),
              text: 'Resolved (${_resolvedComplaints.length})',
            ),
            Tab(
              icon: const Icon(Icons.analytics),
              text: 'Statistics',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUnresolvedTab(),
                    _buildResolvedTab(),
                    _buildStatisticsTab(),
                  ],
                ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUnresolvedTab() {
    if (_unresolvedComplaints.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No unresolved complaints',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _unresolvedComplaints.length,
        itemBuilder: (context, index) {
          final complaint = _unresolvedComplaints[index];
          return _buildComplaintCard(complaint, isResolved: false);
        },
      ),
    );
  }
  
  Widget _buildResolvedTab() {
    if (_resolvedComplaints.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No resolved complaints yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _resolvedComplaints.length,
        itemBuilder: (context, index) {
          final complaint = _resolvedComplaints[index];
          return _buildComplaintCard(complaint, isResolved: true);
        },
      ),
    );
  }
  
  Widget _buildStatisticsTab() {
    if (_statistics.isEmpty) {
      return const Center(
        child: Text('No statistics available'),
      );
    }
    
    final totalComplaints = _statistics.values.fold(0, (sum, count) => sum + count);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Total Complaints',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$totalComplaints',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Complaints by Category',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Category Breakdown
          ..._statistics.entries.map((entry) {
            final category = entry.key;
            final count = entry.value;
            final percentage = totalComplaints > 0 
                ? (count / totalComplaints * 100).toStringAsFixed(1)
                : '0.0';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ComplaintCategory.getDescription(category),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: count / totalComplaints,
                      backgroundColor: Colors.grey.shade200,
                      minHeight: 8,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$percentage% of total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildComplaintCard(Complaint complaint, {required bool isResolved}) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _showComplaintActions(complaint, isResolved),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint.complaintNumber ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          complaint.passengerName ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(complaint.status),
                ],
              ),
              const SizedBox(height: 12),
              
              // Category
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              
              // Description
              Text(
                complaint.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              
              // Priority Badge
              if (complaint.priority != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.flag,
                      size: 16,
                      color: _getPriorityColor(complaint.priority!),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      complaint.priority!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getPriorityColor(complaint.priority!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              // Metadata
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    complaint.submittedAt != null
                        ? dateFormat.format(DateTime.parse(complaint.submittedAt!))
                        : 'N/A',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  if (!isResolved)
                    TextButton.icon(
                      onPressed: () => _showComplaintActions(complaint, isResolved),
                      icon: const Icon(Icons.build, size: 16),
                      label: const Text('Take Action'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusBadge(String? status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case ComplaintStatus.SUBMITTED:
        color = Colors.orange;
        icon = Icons.send;
        break;
      case ComplaintStatus.UNDER_REVIEW:
        color = Colors.blue;
        icon = Icons.pending;
        break;
      case ComplaintStatus.RESOLVED:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case ComplaintStatus.REJECTED:
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            status ?? 'N/A',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.blue;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  void _showComplaintActions(Complaint complaint, bool isResolved) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ComplaintActionsSheet(
        complaint: complaint,
        isResolved: isResolved,
        onActionCompleted: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }
}

/**
 * Complaint Actions Bottom Sheet
 */
class _ComplaintActionsSheet extends StatefulWidget {
  final Complaint complaint;
  final bool isResolved;
  final VoidCallback onActionCompleted;
  
  const _ComplaintActionsSheet({
    required this.complaint,
    required this.isResolved,
    required this.onActionCompleted,
  });
  
  @override
  State<_ComplaintActionsSheet> createState() => _ComplaintActionsSheetState();
}

class _ComplaintActionsSheetState extends State<_ComplaintActionsSheet> {
  final ComplaintService _complaintService = ComplaintService();
  final _resolutionController = TextEditingController();
  bool _isLoading = false;
  
  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }
  
  Future<void> _assignToMe() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user == null) {
        throw Exception('Not authenticated');
      }
      
      await _complaintService.assignComplaint(
        widget.complaint.complaintId!,
        user.userId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint assigned to you'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onActionCompleted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _resolveComplaint() async {
    if (_resolutionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter resolution notes'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await _complaintService.resolveComplaint(
        widget.complaint.complaintId!,
        _resolutionController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint resolved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onActionCompleted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _rejectComplaint() async {
    if (_resolutionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter rejection reason'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await _complaintService.rejectComplaint(
        widget.complaint.complaintId!,
        _resolutionController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        widget.onActionCompleted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Complaint Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              // Complaint Info
              _buildDetailRow('Complaint Number', widget.complaint.complaintNumber ?? 'N/A'),
              _buildDetailRow('Passenger', widget.complaint.passengerName ?? 'Unknown'),
              _buildDetailRow('Category', widget.complaint.categoryDescription ?? widget.complaint.category),
              _buildDetailRow('Priority', widget.complaint.priority ?? 'N/A'),
              _buildDetailRow('Status', widget.complaint.status ?? 'N/A'),
              _buildDetailRow(
                'Submitted',
                widget.complaint.submittedAt != null
                    ? dateFormat.format(DateTime.parse(widget.complaint.submittedAt!))
                    : 'N/A',
              ),
              
              const Divider(height: 32),
              
              // Description
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(widget.complaint.description),
              const SizedBox(height: 24),
              
              // Resolution Section (if not resolved)
              if (!widget.isResolved) ...[
                const Text(
                  'Resolution Notes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _resolutionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter resolution notes or rejection reason...',
                  ),
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  // Assign Button
                  if (widget.complaint.assignedToId == null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _assignToMe,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Assign to Me'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  
                  // Resolve Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _resolveComplaint,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Resolve Complaint'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Reject Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _rejectComplaint,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Reject Complaint'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ] else ...[
                // Show resolution notes if resolved
                const Text(
                  'Resolution',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(widget.complaint.resolutionNotes ?? 'No notes'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}