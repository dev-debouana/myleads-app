import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';

enum _DateFilter { allTime, thisMonth, last3Months, last6Months, thisYear }

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  _DateFilter _filter = _DateFilter.allTime;

  static final List<_Transaction> _allTransactions = [
    _Transaction(
      id: 'TXN-2024-001',
      plan: 'Premium',
      amount: 2.99,
      amountUsd: 3.24,
      date: DateTime(2024, 3, 1),
      status: _TxStatus.paid,
    ),
    _Transaction(
      id: 'TXN-2024-002',
      plan: 'Premium',
      amount: 2.99,
      amountUsd: 3.24,
      date: DateTime(2024, 2, 1),
      status: _TxStatus.paid,
    ),
    _Transaction(
      id: 'TXN-2024-003',
      plan: 'Premium',
      amount: 2.99,
      amountUsd: 3.24,
      date: DateTime(2024, 1, 1),
      status: _TxStatus.paid,
    ),
    _Transaction(
      id: 'TXN-2023-012',
      plan: 'Business',
      amount: 5.99,
      amountUsd: 6.49,
      date: DateTime(2023, 12, 1),
      status: _TxStatus.paid,
    ),
    _Transaction(
      id: 'TXN-2023-011',
      plan: 'Business',
      amount: 5.99,
      amountUsd: 6.49,
      date: DateTime(2023, 11, 1),
      status: _TxStatus.failed,
    ),
    _Transaction(
      id: 'TXN-2023-010',
      plan: 'Premium',
      amount: 2.99,
      amountUsd: 3.24,
      date: DateTime(2023, 10, 1),
      status: _TxStatus.paid,
    ),
  ];

  List<_Transaction> get _filtered {
    final now = DateTime.now();
    return _allTransactions.where((tx) {
      switch (_filter) {
        case _DateFilter.allTime:
          return true;
        case _DateFilter.thisMonth:
          return tx.date.year == now.year && tx.date.month == now.month;
        case _DateFilter.last3Months:
          return tx.date.isAfter(now.subtract(const Duration(days: 90)));
        case _DateFilter.last6Months:
          return tx.date.isAfter(now.subtract(const Duration(days: 180)));
        case _DateFilter.thisYear:
          return tx.date.year == now.year;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final currency = ref.watch(settingsProvider).currency;
    final transactions = _filtered;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 24,
              right: 24,
              bottom: 28,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.paymentHistoryTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.filterByDate,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Filter chips
          Container(
            color: AppColors.bg(context),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _DateFilter.values.map((f) {
                  final label = _filterLabel(f, l10n);
                  final isSelected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient:
                              isSelected ? AppColors.primaryGradient : null,
                          color: isSelected
                              ? null
                              : AppColors.surfaceColor(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderColor(context),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.secondary(context),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Transactions list
          Expanded(
            child: transactions.isEmpty
                ? _EmptyState(l10n: l10n)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _TransactionCard(
                      transaction: transactions[i],
                      currency: currency,
                      l10n: l10n,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _filterLabel(_DateFilter f, AppL10n l10n) {
    switch (f) {
      case _DateFilter.allTime:
        return l10n.allTime;
      case _DateFilter.thisMonth:
        return l10n.thisMonth;
      case _DateFilter.last3Months:
        return l10n.last3Months;
      case _DateFilter.last6Months:
        return l10n.last6Months;
      case _DateFilter.thisYear:
        return l10n.thisYear;
    }
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppL10n l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noPayments,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noPaymentsDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondary(context),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Transaction card ─────────────────────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final _Transaction transaction;
  final AppCurrency currency;
  final AppL10n l10n;

  const _TransactionCard({
    required this.transaction,
    required this.currency,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isEur = currency == AppCurrency.eur;
    final displayAmount = isEur
        ? '${transaction.amount.toStringAsFixed(2)}€'
        : '\$${transaction.amountUsd.toStringAsFixed(2)}';
    final statusColor = _statusColor(transaction.status);
    final statusLabel = _statusLabel(transaction.status, l10n);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_rounded,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      transaction.plan,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface(context),
                      ),
                    ),
                    Text(
                      displayAmount,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      transaction.id,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.hint(context),
                        letterSpacing: 0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(transaction.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.secondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(_TxStatus s) {
    switch (s) {
      case _TxStatus.paid:
        return AppColors.success;
      case _TxStatus.failed:
        return AppColors.error;
      case _TxStatus.pending:
        return AppColors.warning;
    }
  }

  String _statusLabel(_TxStatus s, AppL10n l10n) {
    switch (s) {
      case _TxStatus.paid:
        return l10n.statusPaid.toUpperCase();
      case _TxStatus.failed:
        return l10n.statusFailed.toUpperCase();
      case _TxStatus.pending:
        return l10n.statusPending.toUpperCase();
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────

enum _TxStatus { paid, failed, pending }

class _Transaction {
  final String id;
  final String plan;
  final double amount;
  final double amountUsd;
  final DateTime date;
  final _TxStatus status;

  const _Transaction({
    required this.id,
    required this.plan,
    required this.amount,
    required this.amountUsd,
    required this.date,
    required this.status,
  });
}
