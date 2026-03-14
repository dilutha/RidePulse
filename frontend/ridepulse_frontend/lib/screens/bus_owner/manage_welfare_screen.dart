import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/welfare_models.dart';
import '../../services/welfare_service.dart';

class ManageWelfareScreen extends StatefulWidget {
  const ManageWelfareScreen({super.key});

  @override
  State<ManageWelfareScreen> createState() => _ManageWelfareScreenState();
}

class _ManageWelfareScreenState extends State<ManageWelfareScreen>
    with SingleTickerProviderStateMixin {

  final WelfareService _welfareService = WelfareService();

  late TabController _tabController;

  List<WelfareRecord> _pendingRecords = [];
  List<WelfareRecord> _approvedRecords = [];
  List<WelfareRecord> _allRecords = [];

  bool _isLoading = true;
  String? _error;

  final int busId = 1;

  final NumberFormat currency = NumberFormat.currency(symbol: "Rs ");
  final DateFormat dateFormat = DateFormat('MMM dd, yyyy');

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

      final results = await Future.wait([
        _welfareService.getWelfareRecordsByStatus('PENDING'),
        _welfareService.getWelfareRecordsByStatus('APPROVED'),
        _welfareService.getWelfareRecordsByBus(busId),
      ]);

      setState(() {
        _pendingRecords = results[0] as List<WelfareRecord>;
        _approvedRecords = results[1] as List<WelfareRecord>;
        _allRecords = results[2] as List<WelfareRecord>;
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
        title: const Text("Manage Welfare"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Pending (${_pendingRecords.length})"),
            Tab(text: "Approved (${_approvedRecords.length})"),
            const Tab(text: "All Records"),
          ],
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_pendingRecords, true),
                    _buildList(_approvedRecords, false),
                    _buildAllRecords(),
                  ],
                ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 60, color: Colors.red),
          const SizedBox(height: 10),
          Text(_error ?? "Unknown error"),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text("Retry"),
          )
        ],
      ),
    );
  }

  Widget _buildList(List<WelfareRecord> records, bool showActions) {

    if (records.isEmpty) {
      return const Center(child: Text("No records"));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        itemBuilder: (context, index) {
          return _welfareCard(records[index], showActions);
        },
      ),
    );
  }

  Widget _buildAllRecords() {

    double total = 0;
    double pending = 0;
    double approved = 0;

    for (var r in _allRecords) {
      final amount = r.welfareAmount ?? 0;

      total += amount;

      if (r.status == "PENDING") pending += amount;
      if (r.status == "APPROVED") approved += amount;
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            _summaryCard(total, pending, approved),

            const SizedBox(height: 20),

            ..._allRecords.map((r) => _welfareCard(r, false))

          ],
        ),
      ),
    );
  }

  Widget _summaryCard(double total, double pending, double approved) {

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const Text("Total Welfare Budget"),

            const SizedBox(height: 10),

            Text(
              currency.format(total),
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: _summaryItem("Pending", pending, Colors.orange)),
                const SizedBox(width: 10),
                Expanded(child: _summaryItem("Approved", approved, Colors.green)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, double amount, Color color) {

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(currency.format(amount),
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold
              )),
          Text(label)
        ],
      ),
    );
  }

  Widget _welfareCard(WelfareRecord record, bool showActions) {

    Color statusColor = Colors.grey;

    if (record.status == "PENDING") statusColor = Colors.orange;
    if (record.status == "APPROVED") statusColor = Colors.green;
    if (record.status == "REJECTED") statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Text(
                  record.staffName ?? "Unknown Staff",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold
                  ),
                ),

                Chip(
                  backgroundColor: statusColor,
                  label: Text(
                    record.status ?? "",
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),

            const SizedBox(height: 10),

            _buildDetailRow("Daily Revenue", currency.format(record.dailyRevenue)),
            _buildDetailRow("Fuel Cost", currency.format(record.fuelCost ?? 0)),
            _buildDetailRow("Maintenance", currency.format(record.maintenanceCost ?? 0)),
            _buildDetailRow("Wages", currency.format(record.wages ?? 0)),
            _buildDetailRow("Profit", currency.format(record.dailyProfit ?? 0)),

            const Divider(),

            _buildDetailRow(
              "Welfare (${record.welfarePercentage ?? 0}%)",
              currency.format(record.welfareAmount ?? 0),
            ),

            if (showActions)
              Row(
                children: [

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text("Approve"),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {},
                      child: const Text("Reject"),
                    ),
                  )
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold))
        ],
      ),
    );
  }
}