#!/usr/bin/env bash
# One-time project setup. Run from anywhere:  bash tool/setup.sh
#
# The android/ and ios/ folders are already configured and committed
# (bundle ids, permissions, signing, iPhone-only portrait), so unlike a fresh
# project there is no `flutter create` step. This script:
#   1. Installs packages and generates localizations.
#   2. Regenerates the app icon PNGs (needs Pillow) and installs launcher
#      icons and the splash screen.
#   3. Runs the analyzer and tests.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> Packages"
flutter pub get

echo "==> Localizations"
flutter gen-l10n

echo "==> App icons & splash"
if python3 -c "import PIL" 2>/dev/null; then
  python3 tool/make_icon.py
else
  echo "   (Pillow not installed; using the committed assets/icon/*.png)"
fi
dart run flutter_launcher_icons
dart run flutter_native_splash:create
# flutter_launcher_icons may rewrite this Xcode setting; restore it.
sed -i.bak 's/ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = AppIcon;/ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;/' \
  ios/Runner.xcodeproj/project.pbxproj && rm -f ios/Runner.xcodeproj/project.pbxproj.bak

echo "==> Checks"
flutter analyze
flutter test

echo
echo "Done. Try it:  flutter run"
