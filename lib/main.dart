import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightTheme = FlexThemeData.light(
      scheme: FlexScheme.aquaBlue,
      useMaterial3: true,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 9,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
      ),
      visualDensity: VisualDensity.comfortable,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Beta Changelog',
      theme: lightTheme,
      home: const ChangelogPage(),
    );
  }
}

class ChangelogEntry {
  final String sha;
  final String message;
  final DateTime date;
  final String authorLogin;

  ChangelogEntry({
    required this.sha,
    required this.message,
    required this.date,
    required this.authorLogin,
  });
}

class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  List<ChangelogEntry> _changelogEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChangelog();
  }

  Future<void> _loadChangelog() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final jsonString = await rootBundle.loadString('assets/beta_commits.json');
      final List<dynamic> data = json.decode(jsonString);

      final changelog = data.map((entry) {
        final message = entry['commit']['message'] as String;
        final firstLine = message.split('\n').first;
        
        return ChangelogEntry(
          sha: entry['sha'] as String,
          message: firstLine,
          date: DateTime.parse(entry['commit']['committer']['date'] as String),
          authorLogin: (entry['author']?['login'] as String?) ?? 'unknown',
        );
      }).toList();

      // Sort by date descending
      changelog.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _changelogEntries = changelog;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading local changelog: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime _startOfWeek(DateTime date) {
    final dayOfWeek = date.weekday;
    return DateTime(date.year, date.month, date.day - (dayOfWeek - 1));
  }

  Map<DateTime, List<ChangelogEntry>> _groupByWeek(
      List<ChangelogEntry> entries) {
    final map = <DateTime, List<ChangelogEntry>>{};
    for (final entry in entries) {
      final start = _startOfWeek(entry.date);
      map[start] = (map[start] ?? [])..add(entry);
    }
    return map;
  }

  Map<String, List<String>> _categorizeCommits(List<ChangelogEntry> entries) {
    final categories = {
      'New': <String>[],
      'Improved': <String>[],
      'Fixed': <String>[],
      'Changed': <String>[],
      'Removed': <String>[],
    };

    for (final entry in entries) {
      final firstLine = entry.message.split('\n').first.trim();
      final category = _detectCategory(firstLine);
      categories[category]?.add(firstLine);
    }

    categories.removeWhere((key, value) => value.isEmpty);
    return categories;
  }

  String _detectCategory(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('[new]')) return 'New';
    if (lower.contains('[improved]') || lower.contains('improve'))
      return 'Improved';
    if (lower.contains('[fixed]') || lower.contains('fix')) return 'Fixed';
    if (lower.contains('[changed]') || lower.contains('change'))
      return 'Changed';
    if (lower.contains('[removed]') || lower.contains('remove'))
      return 'Removed';
    return 'Changed';
  }

  @override
  Widget build(BuildContext context) {
    final weeklyGroups = _groupByWeek(_changelogEntries);
    final sortedWeeks = weeklyGroups.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Beta Changelog'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: () => launchUrl(
              Uri.parse('https://github.com/TahaTesser/flutter_beta_changelog'),
            ),
            tooltip: 'View Source',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: sortedWeeks.length,
              itemBuilder: (context, index) {
                final weekStart = sortedWeeks[index];
                final entries = weeklyGroups[weekStart]!;
                final categories = _categorizeCommits(entries);

                final endOfWeek = weekStart.add(const Duration(days: 6));
                final dateRangeStr =
                    '${DateFormat.yMMMMd().format(weekStart)} - ${DateFormat.yMMMMd().format(endOfWeek)}';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateRangeStr,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      for (final category in categories.keys) ...[
                        const SizedBox(height: 16),
                        _buildCategorySection(
                            context, category, categories[category]!),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildCategorySection(
      BuildContext context, String category, List<String> items) {
    final categoryColor = _categoryColor(context, category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            category,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: categoryColor,
                ),
          ),
        ),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Text(
                    item.replaceAll(RegExp(r'\[.*?\]\s*'), ''),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _categoryColor(BuildContext context, String category) {
    final scheme = Theme.of(context).colorScheme;
    switch (category) {
      case 'New':
        return scheme.tertiary;
      case 'Improved':
        return scheme.secondary;
      case 'Fixed':
        return scheme.error;
      case 'Changed':
        return scheme.primary;
      case 'Removed':
        return scheme.errorContainer;
      default:
        return scheme.outline;
    }
  }
}
