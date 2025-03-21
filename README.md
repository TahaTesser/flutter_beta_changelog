# Flutter & Dart Beta Changelog Summary

This app provides a concise weekly summary of the latest changes in both the Flutter and Dart `beta` channels. Instead of sifting through numerous commits, it organizes updates by week and tags them into categories like **New**, **Improved**, **Fixed**, **Changed**, and **Removed**, making it easy to stay informed about both Flutter and Dart updates.

## Try It Live
Check out the latest summary at:  
[http://flutterbetachangelog.codemagic.app](http://flutterbetachangelog.codemagic.app)

## Features
- **Weekly Summaries:** Changes are grouped by week for quick scanning.
- **Categorized Updates:** Clear sections highlight new features, improvements, fixes, and more.
- **Modern UI:** A clean, Material 3-inspired interface with `flex_color_scheme` ensures a pleasant reading experience.
- **Real-Time Data:** Always fetches the latest updates from `flutter/flutter` and `dart-lang/sdk` `beta` channels.
- **Dual Coverage:** Track both Flutter SDK and Dart SDK changes in one place.
- **Source Code Access:** View the source code directly from the app's toolbar.

## Categories
Updates are automatically classified into:
- **New** (Purple): Brand new features and additions
- **Improved** (Blue): Enhancements to existing features
- **Fixed** (Red): Bug fixes and corrections
- **Changed** (Primary): General changes and updates
- **Removed** (Error): Deprecated or removed features

## Development
1. Clone the repository
2. Run `flutter pub get`
3. Run `flutter run`

The app reads changelog data from the `assets/flutter_beta_commits.json` and `assets/dart_beta_commits.json` files, which are automatically updated by GitHub Actions workflows whenever new Flutter or Dart beta updates are detected.
