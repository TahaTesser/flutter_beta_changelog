import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _rateLimitExceeded = false;
  String? _githubToken;

  final DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _loadTokenAndChangelog();
  }

  Future<void> _loadTokenAndChangelog() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _githubToken = prefs.getString('github_token');
    });
    await _loadChangelog();
  }

  Future<List<Map<String, dynamic>>> fetchCommits({
    int? maxCommits,
    DateTime? since,
    DateTime? until,
  }) async {
    final baseUrl = 'https://api.github.com/repos/flutter/flutter/commits';
    final queryParams = {
      'sha': 'beta',
      if (since != null) 'since': since.toUtc().toIso8601String(),
      if (until != null) 'until': until.toUtc().toIso8601String(),
      'per_page': '100',
    };

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    final headers = {
      'Accept': 'application/vnd.github.v3+json',
      if (_githubToken != null && _githubToken!.isNotEmpty)
        'Authorization': 'Bearer $_githubToken',
    };

    try {
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 403 && 
          response.body.toLowerCase().contains('rate limit')) {
        setState(() {
          _rateLimitExceeded = true;
        });
        return [];
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch commits: ${response.statusCode}');
      }

      final List<dynamic> data = json.decode(response.body);
      return data.take(maxCommits ?? data.length).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error fetching commits: $e');
      return [];
    }
  }

  Future<List<ChangelogEntry>> buildChangelog(DateTime fromDate) async {
    final entries = <ChangelogEntry>[];
    final commits = await fetchCommits(since: fromDate, maxCommits: 100);

    for (final commit in commits) {
      final commitData = commit['commit'] as Map<String, dynamic>;
      final committer = commitData['committer'] as Map<String, dynamic>;
      final author = commit['author'] as Map<String, dynamic>?;

      entries.add(ChangelogEntry(
        sha: commit['sha'] as String,
        message: commitData['message'] as String,
        date: DateTime.parse(committer['date'] as String),
        authorLogin: author?['login'] as String? ?? 'unknown',
      ));
    }

    // Sort by date descending
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Future<void> _loadChangelog() async {
    setState(() {
      _isLoading = true;
      _rateLimitExceeded = false;
    });
    try {
      final changelog = await buildChangelog(_fromDate);
      setState(() {
        _changelogEntries = changelog;
        _isLoading = false;
      });
    } catch (e) {
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

  void _showTokenDialog() {
    final controller = TextEditingController(text: _githubToken);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set GitHub Token'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your GitHub Personal Access Token to avoid rate limits:\n\n'
                '- Generate a token at https://github.com/settings/tokens\n'
                '- No special scopes are needed for read-only access.\n',
              ),
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'GitHub Token'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newToken = controller.text.trim();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('github_token', newToken);
                setState(() {
                  _githubToken = newToken.isEmpty ? null : newToken;
                });
                Navigator.pop(context);
                _loadChangelog(); // Reload data with new token
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRateLimitWarning() {
    if (_rateLimitExceeded && (_githubToken == null || _githubToken!.isEmpty)) {
      return Container(
        color: Colors.amber.shade100,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'GitHub rate limit exceeded. Please add a personal access token to continue.',
                style: TextStyle(color: Colors.amber.shade900),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showTokenDialog,
            tooltip: 'Set GitHub Token',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildRateLimitWarning(),
                Expanded(
                  child: ListView.builder(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
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
                ),
              ],
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
