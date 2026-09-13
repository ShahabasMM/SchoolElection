#!/usr/bin/env bash
set -e
# Run this from the project root on a machine with Flutter installed.
flutter create .
flutter pub get
dart run flutter_launcher_icons
