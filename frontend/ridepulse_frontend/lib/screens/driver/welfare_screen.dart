import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/welfare_models.dart';
import '../../providers/auth_provider.dart';
import '../../services/welfare_service.dart';

/**
 * Welfare Screen for Driver/Conductor
 * 
 * Shows welfare records and summary
 */
class WelfareScreen extends StatefulWidget {
  const WelfareScreen({Key? key}) : super(key: key);
  
  @override
  State<WelfareScreen> createState() => _WelfareScreenState();
}

class _WelfareScreenState extends State<WelfareScreen> {
  final WelfareService _welfareService = WelfareService();
  
  WelfareSummary? _summary;
  List<WelfareRecord> _records = [];
  bool _isLoading = true;
  String? _error;
  
  // Mock staff ID - In real app, get from user profile
  final int staffId = 1;
  
  @override
  void initState() {
    super.initState();
    _loadWelfareData();
  }
  
  Future<void> _loadWelfareData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Load summary and records in parallel
      final results = await Future.wait([
        _welfareService.getWelfareSummary(staffId),
        _welfareService.getWelfareRecordsByStaff(staffId),
      ]);
      
      setState(() {
        _summary = results[0] as WelfareSummary;
        _records = results[1] as List<WelfareRecord>;
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
        title: const Text('My Welfare'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWelfareData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadWelfareData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWelfareData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Card
                        if (_summary != null) _buildSummaryCard(_summary!),
                        const SizedBox(height: 24),
                        
                        // Records List
                        const Text(
                          'Welfare History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        if (_records.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'No welfare records yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ..._records.map((record) => _buildRecordCard(record)),
                      ],
                    ),
                  ),
                ),
    );
  }
  
  Widget _buildSummaryCard(WelfareSummary summary) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ');
    
    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Total Welfare
            Text(
              'Total Welfare',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(summary.totalWelfareAmount),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            
            // Breakdown
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Pending',
                    summary.pendingWelfareAmount,
                    Colors.orange,
                    Icons.pending,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    'Approved',
                    summary.approvedWelfareAmount,
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Paid',
                    summary.paidWelfareAmount,
                    Colors.blue,
                    Icons.payment,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long, color: Colors.grey),
                        const SizedBox(height: 4),
                        Text(
                          '${summary.totalRecords}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Records',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            NumberFormat.currency(symbol: 'Rs ').format(amount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecordCard(WelfareRecord record) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: 'Rs ');
    
    Color statusColor;
    IconData statusIcon;
    
    switch (record.status) {
      case 'PENDING':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'APPROVED':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'PAID':
        statusColor = Colors.blue;
        statusIcon = Icons.payment;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(DateTime.parse(record.recordDate)),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        record.status ?? 'N/A',
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
            const Divider(),
            
            // Financial Details
            _buildDetailRow(
              'Daily Revenue',
              currencyFormat.format(record.dailyRevenue),
            ),
            _buildDetailRow(
              'Total Expenses',
              currencyFormat.format(record.totalExpenses ?? 0),
            ),
            _buildDetailRow(
              'Daily Profit',
              currencyFormat.format(record.dailyProfit ?? 0),
              valueColor: Colors.green,
            ),
            const Divider(),
            _buildDetailRow(
              'Welfare (${record.welfarePercentage ?? 0}%)',
              currencyFormat.format(record.welfareAmount ?? 0),
              valueColor: Colors.blue,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}