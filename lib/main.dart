import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/link.dart';
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
  final String type;

  ChangelogEntry({
    required this.sha,
    required this.message,
    required this.date,
    required this.authorLogin,
    required this.type,
  });
}

class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage>
    with SingleTickerProviderStateMixin {
  List<ChangelogEntry> _flutterEntries = [];
  List<ChangelogEntry> _dartEntries = [];
  bool _isLoadingFlutter = true;
  bool _isLoadingDart = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFlutterChangelog();
    _loadDartChangelog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFlutterChangelog() async {
    setState(() {
      _isLoadingFlutter = true;
    });
    try {
      final jsonString =
          await rootBundle.loadString('assets/flutter_beta_commits.json');
      final List<dynamic> data = json.decode(jsonString);

      final changelog = data.map((entry) {
        final message = entry['commit']['message'] as String;
        final firstLine = message.split('\n').first;

        return ChangelogEntry(
          sha: entry['sha'] as String,
          message: firstLine,
          date: DateTime.parse(entry['commit']['committer']['date'] as String),
          authorLogin: (entry['author']?['login'] as String?) ?? 'unknown',
          type: 'flutter',
        );
      }).toList();

      changelog.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _flutterEntries = changelog;
        _isLoadingFlutter = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFlutter = false;
      });
    }
  }

  Future<void> _loadDartChangelog() async {
    setState(() {
      _isLoadingDart = true;
    });
    try {
      final jsonString =
          await rootBundle.loadString('assets/dart_beta_commits.json');
      final List<dynamic> data = json.decode(jsonString);

      final changelog = data.map((entry) {
        final message = entry['commit']['message'] as String;
        final firstLine = message.split('\n').first;

        return ChangelogEntry(
          sha: entry['sha'] as String,
          message: firstLine,
          date: DateTime.parse(entry['commit']['committer']['date'] as String),
          authorLogin: (entry['author']?['login'] as String?) ?? 'unknown',
          type: 'dart',
        );
      }).toList();

      changelog.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _dartEntries = changelog;
        _isLoadingDart = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDart = false;
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
    if (lower.contains('[improved]') || lower.contains('improve')) {
      return 'Improved';
    }
    if (lower.contains('[fixed]') || lower.contains('fix')) return 'Fixed';
    if (lower.contains('[changed]') || lower.contains('change')) {
      return 'Changed';
    }
    if (lower.contains('[removed]') || lower.contains('remove')) {
      return 'Removed';
    }
    return 'Changed';
  }

  @override
  Widget build(BuildContext context) {
    final flutterWeeklyGroups = _groupByWeek(_flutterEntries);
    final flutterSortedWeeks = flutterWeeklyGroups.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final dartWeeklyGroups = _groupByWeek(_dartEntries);
    final dartSortedWeeks = dartWeeklyGroups.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Beta Changelog'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(context),
            tooltip: 'About',
          ),
          LinkIconButton(
            icon: const Icon(Icons.code),
            uri: Uri.parse(
                'https://github.com/TahaTesser/flutter_beta_changelog'),
            tooltip: 'View Source',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Flutter'),
            Tab(text: 'Dart'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChangelogList(
            weeklyGroups: flutterWeeklyGroups,
            sortedWeeks: flutterSortedWeeks,
            isLoading: _isLoadingFlutter,
            type: 'flutter',
          ),
          _buildChangelogList(
            weeklyGroups: dartWeeklyGroups,
            sortedWeeks: dartSortedWeeks,
            isLoading: _isLoadingDart,
            type: 'dart',
          ),
        ],
      ),
    );
  }

  Widget _buildChangelogList({
    required Map<DateTime, List<ChangelogEntry>> weeklyGroups,
    required List<DateTime> sortedWeeks,
    required bool isLoading,
    required String type,
  }) {
    return isLoading
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
                        context,
                        category,
                        categories[category]!,
                        entries,
                      ),
                    ],
                  ],
                ),
              );
            },
          );
  }

  Widget _buildCategorySection(BuildContext context, String category,
      List<String> items, List<ChangelogEntry> entries) {
    final categoryColor = _categoryColor(context, category);

    String getCommitUrl(ChangelogEntry entry) {
      return entry.type == 'flutter'
          ? 'https://github.com/flutter/flutter/commit/${entry.sha}'
          : 'https://github.com/dart-lang/sdk/commit/${entry.sha}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: SelectableText(
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
                const SelectableText('• ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: SelectableText(
                    item.replaceAll(RegExp(r'\[.*?\]\s*'), ''),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Builder(
                  builder: (context) {
                    final entry = entries
                        .where((e) => item.contains(e.message))
                        .firstOrNull;
                    if (entry == null) return const SizedBox.shrink();

                    return LinkIconButton(
                      icon: const Icon(Icons.link, size: 20),
                      uri: Uri.parse(getCommitUrl(entry)),
                      tooltip: 'View commit',
                    );
                  },
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

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Flutter Beta Changelog',
      applicationVersion: '1.0.0',
      applicationIcon: const FlutterLogo(size: 64),
      children: [
        const Text(
          'A simple app to track changes in Flutter Beta channel. '
          'This app helps developers stay up to date with the latest changes '
          'in Flutter Beta releases.',
        ),
      ],
    );
  }
}

/// A IconButton that opens a link when clicked.
/// Opens a a [Uri] in a new tab. Has native behaviour for clicking on links.
class LinkIconButton extends StatelessWidget {
  final Uri uri;
  final LinkTarget target;
  final Icon icon;
  final String? tooltip;
  const LinkIconButton({
    super.key,
    required this.uri,
    required this.icon,
    this.tooltip,
    this.target = LinkTarget.blank,
  });

  @override
  Widget build(BuildContext context) {
    return Link(
      uri: uri,
      target: target,
      builder: (context, followLink) => IconButton(
        icon: icon,
        tooltip: tooltip,
        onPressed: () {
          followLink!();
        },
      ),
    );
  }
}
