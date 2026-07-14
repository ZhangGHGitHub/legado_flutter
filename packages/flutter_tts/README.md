# flutter_tts (vendored)

Vendored from [flutter_tts 4.2.5](https://pub.dev/packages/flutter_tts) with the
**Windows** plugin platform removed.

Reason: the upstream Windows CMake requires `nuget.exe` (`Microsoft.Windows.CppWinRT`),
which breaks `flutter run -d windows` on machines without NuGet. Android / iOS / macOS / Web
keep the original native plugins. Desktop Windows uses `TtsService` stub speak instead.
