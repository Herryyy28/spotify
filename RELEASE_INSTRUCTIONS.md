# Spotify App Release Build Instructions

This guide provides step-by-step instructions for preparing, signing, and building production-ready packages for the Android and iOS platforms.

---

## 🤖 Android Release Build

Android builds are configured to securely read signing credentials from `android/key.properties`. This keeps your passwords and keystores out of source control.

### Step 1: Generate a Release Keystore
If you do not have an existing Java Keystore (`.jks`), generate one using the Java `keytool` command.

Open your terminal and run:

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

*Follow the prompts to set your passwords, name, organizational unit, and other metadata.*

### Step 2: Create a Local properties file
Create a file named `key.properties` in the `android/` directory:

📁 **File**: `android/key.properties`
```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=upload-keystore.jks
```

> [!WARNING]
> Do not commit `key.properties` or `upload-keystore.jks` to GitHub/Git. They are already listed in your `android/.gitignore` file.

### Step 3: Build the Android Packages
Run the appropriate Flutter build commands from the root directory of your project:

#### 1. Generate an APK (For direct installation / manual sharing):
```bash
flutter build apk --release
```
*Output path*: `build/app/outputs/flutter-apk/app-release.apk`

#### 2. Generate an Android App Bundle (AAB - Recommended for Google Play Store upload):
```bash
flutter build appbundle --release
```
*Output path*: `build/app/outputs/bundle/release/app-release.aab`

---

## 🍎 iOS Release Build (IPA)

Building for iOS requires a macOS machine with **Xcode** installed, as well as an active **Apple Developer Program** account.

### Step 1: Set up Signing in Xcode
1. Open the project in Xcode by launching `/ios/Runner.xcworkspace`.
2. Select the **Runner** project in the left sidebar.
3. Choose the **Runner** target, then click on the **Signing & Capabilities** tab.
4. Check **Automatically manage signing**.
5. Select your **Developer Team**. Xcode will automatically fetch your provisioning profiles and certificates.
6. Verify that your **Bundle Identifier** is set to `com.example.spotify` (or your custom bundle ID) and matches your Apple App Store Connect profile.

### Step 2: Add Firebase Configuration (GoogleService-Info.plist)
For real-time data sync to work on iOS:
1. Go to your **Firebase Console** -> Project Settings -> Add App -> **iOS**.
2. Enter the Bundle ID: `com.example.spotify`.
3. Download the `GoogleService-Info.plist` configuration file.
4. Drag and drop the downloaded file into Xcode under the `Runner` folder (`Runner/Runner` group).
5. When prompted by Xcode, make sure **"Copy items if needed"** and **"Runner"** target are checked.

### Step 3: Configure Versioning
Under the **General** tab in Xcode:
* Ensure **Version** (e.g., `1.0.0`) and **Build** (e.g., `1`) are set correctly. Each upload to App Store Connect requires a higher build number than the previous one.

### Step 3: Build and Archive
1. In Xcode's menu bar, select **Product** -> **Clean Build Folder**.
2. Select the build target device as **Any iOS Device (arm64)** from the device selector dropdown.
3. Click **Product** -> **Archive**. Xcode will compile your project and open the Organizer window when complete.

### Step 4: Export the IPA
1. In the Xcode Organizer window, select your latest archive and click **Distribute App**.
2. Choose your distribution method (e.g., **App Store Connect** for TestFlight/App Store, or **Ad Hoc** for manual testing on registered devices).
3. Follow the wizard prompts to sign the app.
4. Export the bundle. Xcode will save the generated `.ipa` file to a folder of your choice on your Mac.

#### Alternative: Command Line Build (Requires configured Signing profiles)
From the project root:
```bash
flutter build ipa --release
```
*This command generates the `.xcarchive` and output folder inside the `build/ios/archive/` and `build/ios/ipa/` directories.*

---

## 📂 Project Structure & Feature Review

During our codebase cleanup review, we identified several fully-implemented screens and modules that are not currently linked to the main navigation flow. They remain intact in the project structure for future integration:

* **Podcast Feature**:
  * [PodcastBrowseScreen](file:///c:/Users/praja.HERRY/AndroidStudioProjects/spotify/lib/screens/podcast/podcast_browse_screen.dart): Browse trending and subscribed podcasts.
  * [PodcastDetailScreen](file:///c:/Users/praja.HERRY/AndroidStudioProjects/spotify/lib/screens/podcast/podcast_detail_screen.dart): Lists episodes for a specific podcast.
  * [EpisodePlayerScreen](file:///c:/Users/praja.HERRY/AndroidStudioProjects/spotify/lib/screens/podcast/episode_player_screen.dart): UI for playing podcast episodes.
* **Social Feeds**:
  * [SocialFeedScreen](file:///c:/Users/praja.HERRY/AndroidStudioProjects/spotify/lib/screens/social/social_feed_screen.dart): Sharing and music status updates feed.
  * [ActivityFeedScreen](file:///c:/Users/praja.HERRY/AndroidStudioProjects/spotify/lib/screens/social/activity_feed_screen.dart): Friend activity stream.
* **Statistics & Analytics**:
  * [StatisticsScreen](file:///c:/Users/praja.HERRY/AndroidStudioProjects/spotify/lib/screens/statistics/statistics_screen.dart): Detailed user listening statistics and graphs.
* **Queue**:
  * [QueueScreen](file:///c:/Users/praja.HERRY/AndroidStudioProjects/spotify/lib/screens/queue/queue_screen.dart): View and reorder upcoming music queue items.
* **Recommendations**:
  * [RecommendationsScreen](file:///c:/Users/praja.HERRY/AndroidStudioProjects/spotify/lib/screens/recommendations/recommendations_screen.dart): Generated custom mixes and recommendations.
