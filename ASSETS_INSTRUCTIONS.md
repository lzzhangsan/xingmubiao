Place your desired launcher icon image in the project and generate icons

1) Copy the image file you provided (e.g. `faa73922ff8ba3977545f3e04d1c6d2e.jpg`) into the project as `assets/app_icon.png`.
   - Rename the file to `app_icon.png` and ensure it's a square PNG (recommended >= 1024x1024). If your file is JPG, convert to PNG to preserve transparency if needed.

2) Run the following commands in the project root:

```powershell
flutter pub get
flutter pub run flutter_launcher_icons:main
```

This will generate Android and iOS launcher icons from `assets/app_icon.png` and update the native resources.

3) Rebuild your app:

```powershell
flutter clean; flutter run
```

Notes:
- I updated `pubspec.yaml` with a `flutter_icons` configuration that uses `assets/app_icon.png` as the source. If you prefer another path, update `pubspec.yaml` accordingly.
- I updated the Android `AndroidManifest.xml` and iOS `Info.plist` to set the display name to `每日目标`.
- I can't write binary image files from this environment; please copy the image into the `assets` folder yourself and run the commands above to generate icons.
