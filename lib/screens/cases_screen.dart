import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/models.dart';

class CasesScreen extends StatefulWidget {
  final ApiClient api;
  const CasesScreen({super.key, required this.api});
  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  late Future<List<CustomerCase>> futureCases;
  @override
  void initState() { super.initState(); futureCases = widget.api.cases(); }
  void refresh() => setState(() => futureCases = widget.api.cases());

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Customer care')),
        body: FutureBuilder<List<CustomerCase>>(
          future: futureCases,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
            final cases = snapshot.data ?? const <CustomerCase>[];
            if (cases.isEmpty) return const Center(child: Text('No customer-care cases found.'));
            return RefreshIndicator(onRefresh: () async => refresh(), child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: cases.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (context, index) {
              final item = cases[index];
              return Card(child: ListTile(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CaseDetailScreen(api: widget.api, caseId: item.id))), leading: const CircleAvatar(child: Icon(Icons.support_agent)), title: Text(item.caseNo, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${item.category} · ${item.priority}'), trailing: Chip(label: Text(item.status))));
            }));
          },
        ),
      );
}

class CaseDetailScreen extends StatelessWidget {
  final ApiClient api;
  final int caseId;
  const CaseDetailScreen({super.key, required this.api, required this.caseId});

  String date(DateTime? value) => value == null ? 'Not available' : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Case details')),
        body: FutureBuilder<CustomerCaseDetail>(
          future: api.caseDetail(caseId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
            final item = snapshot.data!;
            return ListView(padding: const EdgeInsets.all(16), children: [
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.caseNo, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('Category: ${item.category}'), Text('Priority: ${item.priority}'), Text('Status: ${item.status}'), Text('Collected: UGX ${item.amountCollected.toStringAsFixed(0)}')]))) ,
              const SizedBox(height: 16),
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Feedback history', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 8), if (item.activities.isEmpty) const Text('No feedback has been recorded yet.'), ...item.activities.map((activity) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.notes_outlined), title: Text(activity.type), subtitle: Text('${activity.notes ?? ''}\nLogged by ${activity.loggedBy} · ${date(activity.createdAt)}${activity.promisedPayDate == null ? '' : '\nPromised payment: ${date(activity.promisedPayDate)}'}')))]))),
              const SizedBox(height: 16),
              if (item.recordingUrls.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Call recordings', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('Recordings are available from the customer-care team. Audio playback can be added with the selected media package.')]))),
            ]);
          },
        ),
      );
}
