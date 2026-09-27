import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/report_service.dart';
import '../widgets/app_ui.dart';

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
          SnackBar(content: const Text('Report generated successfully!'), backgroundColor: AppConstants.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e'), backgroundColor: AppConstants.dangerColor),
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
            const SectionHeader('Report type'),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: _reportTypes.map((type) => RadioListTile<String>(
                  title: Text(type, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(_getReportSubtitle(type), style: TextStyle(fontSize: 12, color: context.mutedText)),
                  value: type,
                  groupValue: _selectedReportType,
                  activeColor: AppConstants.primaryColor,
                  onChanged: (val) => setState(() => _selectedReportType = val!),
                )).toList(),
              ),
            ),
            const SizedBox(height: 24),
            
            const SectionHeader('Format'),
            Row(
              children: [
                Expanded(
                  child: _buildFormatCard(
                    title: 'PDF Document',
                    icon: Icons.picture_as_pdf_outlined,
                    isSelected: _isPdf,
                    onTap: () => setState(() => _isPdf = true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFormatCard(
                    title: 'Excel Spreadsheet',
                    icon: Icons.table_chart_outlined,
                    isSelected: !_isPdf,
                    onTap: () => setState(() => _isPdf = false),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateReport,
              style: primaryButtonStyle(),
              child: _isGenerating 
                ? const ButtonSpinner()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.ios_share, size: 20),
                      SizedBox(width: 8),
                      Text('Generate & share'),
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
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const color = AppConstants.primaryColor;
    return AppCard(
      onTap: onTap,
      color: isSelected ? color.withOpacity(0.06) : null,
      borderColor: isSelected ? color : null,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, size: 28, color: isSelected ? color : context.mutedText),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
