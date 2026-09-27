import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../constants.dart';

class PaymentDetailScreen extends StatelessWidget {
  final Payment payment;

  const PaymentDetailScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Payment Details'),
        
        
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 8),
                  const Text('Payment Received', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    '₹ ${payment.amount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Info Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _detailRow(context, Icons.label_important_outline, 'Title', payment.title),
                  const Divider(height: 32),
                  _detailRow(context, Icons.category_outlined, 'Category', payment.category ?? 'General'),
                  const Divider(height: 32),
                  _detailRow(context, Icons.calendar_today_outlined, 'Payment Date', DateFormat('EEEE, MMM d, y').format(payment.paymentDate)),
                  
                  if (payment.periodStart != null && payment.periodEnd != null) ...[
                    const Divider(height: 32),
                    _detailRow(
                      context,
                      Icons.date_range_outlined, 
                      'Billing Period', 
                      '${DateFormat('MMM d').format(payment.periodStart!)} to ${DateFormat('MMM d, y').format(payment.periodEnd!)}',
                      subtitle: '${payment.periodEnd!.difference(payment.periodStart!).inDays + 1} days cycle',
                    ),
                  ],

                  if (payment.description != null && payment.description!.isNotEmpty) ...[
                    const Divider(height: 32),
                    _detailRow(context, Icons.notes, 'Notes', payment.description!),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to List'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: AppConstants.primaryColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: AppConstants.primaryColor.withOpacity(0.8))),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
