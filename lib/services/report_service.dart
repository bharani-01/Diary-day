import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import 'database_service.dart';

class ReportService {
  final DatabaseService _db = DatabaseService();

  Future<void> generateAndShareFinancialReport({required bool isPdf}) async {
    final payments = await _db.getPayments();
    final expenses = await _db.getExpenses();

    if (isPdf) {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        header: (context) => _buildPdfHeader('Financial Report'),
        build: (context) {
          return [
            pw.Text('Payments/Income', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            _buildPdfTable(
              ['Date', 'Title', 'Description', 'Amount'],
              payments.map((p) => <String>[
                DateFormat('yyyy-MM-dd').format(p.paymentDate),
                p.title,
                p.description ?? '',
                'Rs ${p.amount.toStringAsFixed(2)}'
              ]).toList()
            ),
            pw.SizedBox(height: 20),
            pw.Text('Expenses', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            _buildPdfTable(
              ['Date', 'Title', 'Category', 'Amount'],
              expenses.map((e) => <String>[
                DateFormat('yyyy-MM-dd').format(e.expenseDate),
                e.title,
                e.category,
                'Rs ${e.amount.toStringAsFixed(2)}'
              ]).toList()
            ),
          ];
        }
      ));
      await _shareFile(await pdf.save(), 'financial_report.pdf');
    } else {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];
      
      _appendExcelRow(sheetObject, ['Financial Report']);
      _appendExcelRow(sheetObject, ['Date', 'Title', 'Description', 'Amount']);
      for(var p in payments){
        _appendExcelRow(sheetObject, [
          DateFormat('yyyy-MM-dd').format(p.paymentDate),
          p.title,
          p.description ?? '',
          p.amount.toStringAsFixed(2)
        ]);
      }
      
      _appendExcelRow(sheetObject, ['']);
      _appendExcelRow(sheetObject, ['Expenses']);
      _appendExcelRow(sheetObject, ['Date', 'Title', 'Category', 'Amount']);
      for(var e in expenses){
         _appendExcelRow(sheetObject, [
           DateFormat('yyyy-MM-dd').format(e.expenseDate),
           e.title,
           e.category,
           e.amount.toStringAsFixed(2)
         ]);
      }
      
      await _shareFile(excel.encode()!, 'financial_report.xlsx');
    }
  }

  pw.Widget _buildPdfHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('KRB Dairy Farms', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
              pw.Text('Official $title', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
            ],
          ),
          pw.Text(DateFormat('yyyy-MM-dd').format(DateTime.now()), style: const pw.TextStyle(color: PdfColors.grey)),
        ]
      )
    );
  }

  pw.Widget _buildPdfTable(List<String> headers, List<List<String>> data) {
    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }
  
  void _appendExcelRow(Sheet sheet, List<String> row) {
    // In older excel package versions the method just accepts List<dynamic>
    sheet.appendRow(row);
  }

  Future<void> _shareFile(List<int> bytes, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Here is the $fileName');
  }

  Future<void> generateAndShareMilkReport({required bool isPdf}) async {
    final entries = await _db.getShiftMilkEntries();
    
    if (isPdf) {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        header: (context) => _buildPdfHeader('Milk Production Report'),
        build: (context) {
          return [
            _buildPdfTable(
              ['Date', 'Shift', 'Quantity (L)', 'SNF %', 'Fat %'],
              entries.map((e) => <String>[
                DateFormat('yyyy-MM-dd').format(e.entryDate),
                e.shift,
                e.quantity.toString(),
                e.snf?.toString() ?? '-',
                e.fatPercentage?.toString() ?? '-',
              ]).toList()
            ),
          ];
        }
      ));
      await _shareFile(await pdf.save(), 'milk_report.pdf');
    } else {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];
      _appendExcelRow(sheetObject, ['Date', 'Shift', 'Quantity (L)', 'SNF %', 'Fat %']);
      for(var e in entries){
        _appendExcelRow(sheetObject, [
          DateFormat('yyyy-MM-dd').format(e.entryDate),
          e.shift,
          e.quantity.toString(),
          e.snf?.toString() ?? '',
          e.fatPercentage?.toString() ?? '',
        ]);
      }
      await _shareFile(excel.encode()!, 'milk_report.xlsx');
    }
  }

  Future<void> generateAndShareHealthReport({required bool isPdf}) async {
    final cows = await _db.getCows();
    if (isPdf) {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        header: (context) => _buildPdfHeader('Herd Health Report'),
        build: (context) {
          return [
            _buildPdfTable(
              ['Tag', 'Name', 'Age', 'Type', 'Health Status'],
              cows.map((c) => <String>[
                c.tagNumber,
                c.name ?? '',
                c.formattedAge,
                c.cowType,
                c.healthStatus
              ]).toList()
            ),
          ];
        }
      ));
      await _shareFile(await pdf.save(), 'health_report.pdf');
    } else {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];
      _appendExcelRow(sheetObject, ['Tag', 'Name', 'Age', 'Type', 'Health Status']);
      for(var c in cows){
        _appendExcelRow(sheetObject, [
          c.tagNumber,
          c.name ?? '',
          c.formattedAge,
          c.cowType,
          c.healthStatus
        ]);
      }
      await _shareFile(excel.encode()!, 'health_report.xlsx');
    }
  }

  Future<void> generateCowProfilePdf({
    required String tagNumber,
    required String? name,
    required String age,
    required String type,
    required String? breed,
    required String healthStatus,
    required List<Map<String, String>> healthRecords,
    required List<Map<String, String>> breedingRecords,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.teal,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('KRB Dairy Farms', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      pw.SizedBox(height: 4),
                      pw.Text('Cow Profile Card', style: const pw.TextStyle(fontSize: 14, color: PdfColors.white)),
                    ],
                  ),
                  pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now()), style: const pw.TextStyle(color: PdfColors.white)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Identity Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Tag: $tagNumber', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                        if (name != null && name.isNotEmpty) pw.Text('Name: $name', style: const pw.TextStyle(fontSize: 16)),
                        pw.SizedBox(height: 8),
                        pw.Row(children: [
                          _profileChip('Type', type),
                          pw.SizedBox(width: 8),
                          _profileChip('Breed', breed ?? 'Native'),
                          pw.SizedBox(width: 8),
                          _profileChip('Age', age),
                        ]),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: healthStatus == 'Healthy' ? PdfColors.green50 : PdfColors.red50,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      healthStatus,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: healthStatus == 'Healthy' ? PdfColors.green800 : PdfColors.red800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Health Records Table
            pw.Text('Health / Medical Records', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
            pw.SizedBox(height: 8),
            if (healthRecords.isEmpty)
              pw.Text('No health records found.', style: const pw.TextStyle(color: PdfColors.grey))
            else
              _buildPdfTable(
                ['Date', 'Treatment', 'Type', 'Administered By'],
                healthRecords.map((r) => <String>[r['date']!, r['treatment']!, r['type']!, r['administeredBy']!]).toList(),
              ),
            pw.SizedBox(height: 20),

            // Breeding Records Table
            pw.Text('Breeding History', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
            pw.SizedBox(height: 8),
            if (breedingRecords.isEmpty)
              pw.Text('No breeding records found.', style: const pw.TextStyle(color: PdfColors.grey))
            else
              _buildPdfTable(
                ['Date', 'Details'],
                breedingRecords.map((r) => <String>[r['date']!, r['details']!]).toList(),
              ),

            pw.Spacer(),

            // Footer
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 10),
              decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300))),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated by KRB Dairy Farms App', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  pw.Text('Confidential', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                ],
              ),
            ),
          ],
        );
      },
    ));

    await _shareFile(await pdf.save(), 'cow_profile_$tagNumber.pdf');
  }

  pw.Widget _profileChip(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal50,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text('$label: $value', style: const pw.TextStyle(fontSize: 10, color: PdfColors.teal900)),
    );
  }
}
