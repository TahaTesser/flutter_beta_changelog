# Flutter Beta Changelog Summary

This app provides a concise weekly summary of the latest changes in the Flutter `beta` channel. Instead of sifting through numerous commits, it organizes updates by week and tags them into categories like **New**, **Improved**, **Fixed**, **Changed**, and **Removed**, making it easy to stay informed.

*Note: This app was created in Gemini.*

## Features
- **Weekly Summaries:** Changes are grouped by week for quick scanning.
- **Categorized Updates:** Clear sections highlight new features, improvements, fixes, and more.
- **Modern UI:** A clean, Material 3-inspired interface with `flex_color_scheme` ensures a pleasant reading experience.
- **Real-Time Data:** Always fetches the latest updates from `flutter/flutter` `beta`.
- **GitHub Token Support:** Add a personal access token directly from the app’s toolbar to avoid rate limit issues when fetching data.

## GitHub Token Setup
If you encounter GitHub’s API rate limits without a token, you’ll see a warning prompt. To add a token:
1. Generate a token at [https://github.com/settings/tokens](https://github.com/settings/tokens) (no special scopes needed).
2. Click the **Settings** icon in the app’s toolbar.
3. Paste the token into the dialog and save.
  
Subsequent data fetches will use the authenticated token, greatly reducing the likelihood of hitting rate limits.

## Try It Live
Check out the latest summary at:  
[http://flutterbetachanelog.codemagic.app](http://flutterbetachanelog.codemagic.app)

## Usage
Clone, run `flutter pub get`, then `flutter run`. Any new changes in the Flutter `beta` branch trigger an automatic version increment and a Codemagic build.

## License
[MIT License](LICENSE)