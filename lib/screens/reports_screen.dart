import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/report_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  String _selectedReportType = 'Financial';
  bool _isPdf = true;
  bool _isGenerating = false;

  final List<String> _reportTypes = ['Financial', 'Health', 'Milk Yield'];

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);
    
    try {
      if (_selectedReportType == 'Financial') {
        await _reportService.generateAndShareFinancialReport(isPdf: _isPdf);
      } else if (_selectedReportType == 'Health') {
        await _reportService.generateAndShareHealthReport(isPdf: _isPdf);
      } else if (_selectedReportType == 'Milk Yield') {
        await _reportService.generateAndShareMilkReport(isPdf: _isPdf);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Report generated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Export Reports')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.containerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Report Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: _reportTypes.map((type) => RadioListTile<String>(
                  title: Text(type, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_getReportSubtitle(type), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  value: type,
                  groupValue: _selectedReportType,
                  activeColor: AppConstants.primaryColor,
                  onChanged: (val) => setState(() => _selectedReportType = val!),
                )).toList(),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Select Format',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFormatCard(
                    title: 'PDF Document',
                    icon: Icons.picture_as_pdf,
                    color: Colors.red,
                    isSelected: _isPdf,
                    onTap: () => setState(() => _isPdf = true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFormatCard(
                    title: 'Excel Spreadsheet',
                    icon: Icons.table_chart,
                    color: Colors.green,
                    isSelected: !_isPdf,
                    onTap: () => setState(() => _isPdf = false),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isGenerating 
                ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Theme.of(context).cardColor, strokeWidth: 3))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Generate & Share', style: TextStyle(fontSize: 18, color: Theme.of(context).cardColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _getReportSubtitle(String type) {
    switch (type) {
      case 'Financial': return 'Monthly payments, expenses, and net profit';
      case 'Health': return 'Complete list of cows and their current health status';
      case 'Milk Yield': return 'Shift-wise milk production records';
      default: return '';
    }
  }

  Widget _buildFormatCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
