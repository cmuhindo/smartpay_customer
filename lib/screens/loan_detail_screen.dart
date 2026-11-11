import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/models.dart';

class LoanDetailScreen extends StatefulWidget {
  final ApiClient api;
  final int loanId;

  const LoanDetailScreen({
    super.key,
    required this.api,
    required this.loanId,
  });

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  late Future<Loan> futureLoan;

  @override
  void initState() {
    super.initState();
    futureLoan = widget.api.loan(widget.loanId);
  }

  Future<void> refresh() async {
    setState(() {
      futureLoan = widget.api.loan(widget.loanId);
    });
    await futureLoan;
  }

  String money(double value) => 'UGX ${value.toStringAsFixed(0)}';

  String date(DateTime? value) {
    if (value == null) return 'Not available';

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/${value.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan details'),
      ),
      body: FutureBuilder<Loan>(
        future: futureLoan,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final loan = snapshot.data;
          if (loan == null) {
            return const Center(child: Text('Loan details are unavailable.'));
          }

          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                loan.contractNo,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Chip(
                              label: Text(loan.status.replaceAll('_', ' ')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loan.phoneName,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _Value(
                                label: 'Balance remaining',
                                value: money(loan.balance),
                              ),
                            ),
                            Expanded(
                              child: _Value(
                                label: 'Total payable',
                                value: money(loan.totalPayable),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _Value(
                          label: 'Coverage paid through',
                          value: date(loan.paidThroughAt),
                        ),
                        const SizedBox(height: 8),
                        _Value(
                          label: 'Next scheduled repayment',
                          value: date(loan.nextRepaymentAt),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (_) => _RepaymentDialog(
                        api: widget.api,
                        loan: loan,
                      ),
                    );

                    if (result == true && mounted) {
                      await refresh();
                    }
                  },
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('Make a Mobile Money repayment'),
                ),
                const SizedBox(height: 20),
                _Section(
                  'Repayment schedule',
                  loan.schedule.isEmpty
                      ? const Text('Schedule not available.')
                      : Column(
                          children: loan.schedule.map<Widget>((row) {
                            final outstanding = row.amountDue > row.amountPaid
                                ? row.amountDue - row.amountPaid
                                : 0.0;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 15,
                                child: Text('${row.installmentNo}'),
                              ),
                              title: Text(money(outstanding)),
                              subtitle: Text('Due ${date(row.dueDate)}'),
                              trailing: Text(
                                row.status.replaceAll('_', ' '),
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 16),
                _Section(
                  'Payment history',
                  loan.repayments.isEmpty
                      ? const Text('No repayment history yet.')
                      : Column(
                          children: loan.repayments.map<Widget>((payment) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.payments_outlined),
                              title: Text(money(payment.amount)),
                              subtitle: Text(
                                '${payment.channel} · '
                                '${date(payment.receivedAt ?? payment.createdAt)}',
                              ),
                              trailing: Text(payment.status),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RepaymentDialog extends StatefulWidget {
  final ApiClient api;
  final Loan loan;

  const _RepaymentDialog({
    required this.api,
    required this.loan,
  });

  @override
  State<_RepaymentDialog> createState() => _RepaymentDialogState();
}

class _RepaymentDialogState extends State<_RepaymentDialog> {
  final amountController = TextEditingController();
  final phoneController = TextEditingController();

  bool busy = false;
  String? message;
  String status = 'idle';

  @override
  void dispose() {
    amountController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> start() async {
    final amount = double.tryParse(amountController.text.trim());
    final phoneNumber = phoneController.text.trim();

    if (amount == null || amount <= 0 || phoneNumber.isEmpty) {
      setState(() {
        message = 'Enter a valid amount and Mobile Money phone number.';
      });
      return;
    }

    setState(() {
      busy = true;
      status = 'pending';
      message = 'Sending the PIN prompt...';
    });

    try {
      var result = await widget.api.initiateRepayment(
        loanId: widget.loan.id,
        amount: amount,
        phoneNumber: phoneNumber,
      );

      if (!mounted) return;
      setState(() {
        message = result.message;
      });

      for (var attempt = 0;
          attempt < 60 && result.status == 'pending';
          attempt++) {
        await Future.delayed(const Duration(seconds: 5));
        result = await widget.api.repaymentStatus(
          loanId: widget.loan.id,
          paymentId: result.paymentId,
        );

        if (!mounted) return;
        setState(() {
          status = result.status;
          message = result.message;
        });
      }

      if (!mounted) return;
      setState(() {
        busy = false;
        status = result.status;
        message = result.message;
      });

      if (result.status == 'success' && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        busy = false;
        status = 'failed';
        message = exception.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mobile Money repayment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amountController,
            enabled: !busy,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (UGX)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneController,
            enabled: !busy,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile Money phone',
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(
              message!,
              style: TextStyle(
                color: status == 'failed'
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: busy ? null : start,
          child: Text(busy ? 'Waiting...' : 'Initiate payment'),
        ),
      ],
    );
  }
}

class _Value extends StatelessWidget {
  final String label;
  final String value;

  const _Value({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section(this.title, this.child);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
