import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../constants.dart';
import '../widgets/app_ui.dart';

class PaymentDetailScreen extends StatelessWidget {
  final Payment payment;

  const PaymentDetailScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StatusPill(label: 'Payment received', color: AppConstants.successColor, icon: Icons.check),
                      const SizedBox(height: 12),
                      Text(
                        '₹ ${payment.amount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      _detailRow(context, Icons.label_outline, 'Title', payment.title),
                      const Divider(height: 1),
                      _detailRow(context, Icons.category_outlined, 'Category', payment.category ?? 'General'),
                      const Divider(height: 1),
                      _detailRow(context, Icons.calendar_today_outlined, 'Payment date', DateFormat('EEEE, MMM d, y').format(payment.paymentDate)),
                      
                      if (payment.periodStart != null && payment.periodEnd != null) ...[
                        const Divider(height: 1),
                        _detailRow(
                          context,
                          Icons.date_range_outlined, 
                          'Billing period', 
                          '${DateFormat('MMM d').format(payment.periodStart!)} to ${DateFormat('MMM d, y').format(payment.periodEnd!)}',
                          subtitle: '${payment.periodEnd!.difference(payment.periodStart!).inDays + 1}-day cycle',
                        ),
                      ],

                      if (payment.description != null && payment.description!.isNotEmpty) ...[
                        const Divider(height: 1),
                        _detailRow(context, Icons.notes, 'Notes', payment.description!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String label, String value, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: context.mutedText),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: context.mutedText)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: context.mutedText)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
