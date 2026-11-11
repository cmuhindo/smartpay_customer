import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/models.dart';
import 'loan_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ApiClient api;
  final UserProfile user;

  const DashboardScreen({super.key, required this.api, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Loan>> futureLoans;

  @override
  void initState() {
    super.initState();
    futureLoans = widget.api.loans();
  }

  void refresh() => setState(() => futureLoans = widget.api.loans());

  String money(double value) => 'UGX ${value.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => refresh(),
        child: FutureBuilder<List<Loan>>(
          future: futureLoans,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return _ErrorState(message: snapshot.error.toString(), onRetry: refresh);
            final loans = snapshot.data ?? const <Loan>[];
            final totalBalance = loans.fold<double>(0, (sum, loan) => sum + loan.balance);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Good day,', style: Theme.of(context).textTheme.bodyMedium), Text(widget.user.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))])),
                  CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: const Icon(Icons.person_outline)),
                ]),
                const SizedBox(height: 22),
                Card(color: Theme.of(context).colorScheme.primary, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Total balance remaining', style: TextStyle(color: Colors.white.withOpacity(.8))), const SizedBox(height: 8), Text(money(totalBalance), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text('${loans.length} loan${loans.length == 1 ? '' : 's'} linked to your account', style: TextStyle(color: Colors.white.withOpacity(.8))) ]))),
                const SizedBox(height: 24),
                Text('Your loans', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (loans.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('No loans are currently linked to your account.'))),
                ...loans.map((loan) => _LoanCard(loan: loan, money: money, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoanDetailScreen(api: widget.api, loanId: loan.id))))),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Loan loan;
  final String Function(double) money;
  final VoidCallback onTap;

  const _LoanCard({required this.loan, required this.money, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(loan.contractNo, style: const TextStyle(fontWeight: FontWeight.bold))), Chip(label: Text(loan.status.replaceAll('_', ' '), style: const TextStyle(fontSize: 11)))]),
            const SizedBox(height: 8),
            Text(loan.phoneName, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: _Metric(label: 'Balance', value: money(loan.balance))), Expanded(child: _Metric(label: 'Installment', value: money(loan.installmentAmount)))]),
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerRight, child: Icon(Icons.arrow_forward_ios, size: 16)),
          ]),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 3), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]);
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 44), const SizedBox(height: 10), Text(message, textAlign: TextAlign.center), const SizedBox(height: 14), OutlinedButton(onPressed: onRetry, child: const Text('Try again'))])));
}
