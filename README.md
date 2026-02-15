# Project Branching & Contribution Guidelines

Welcome to the **dev branch** of this project.  
This branch is for **stable, verified code only**. Please read carefully before contributing.

---

## Ã°Å¸Å’Å¸ Branch Purpose

- **`dev` branch**
  - Stores **stable and verified code**.
  - **Do NOT edit or push directly here.**
  - This branch is only for **cloning** to get a reliable version of the project.

- **Team branches**
  - **`frontend_dev`** Ã¢â€ â€™ For frontend teamÃ¢â‚¬â„¢s final files.
  - **`backend_dev`** Ã¢â€ â€™ For backend teamÃ¢â‚¬â„¢s final files.
  - Team members **create pull requests (PRs) to these branches** before merging into `dev`.

- **Personal branches**
  - Each developer should create their **own branch** for development.
  - Branch names **must start with your name** (e.g., `arkshayan_b01`).
  - You can create as many branches as needed for your tasks.
  - Branches not following this naming rule may be removed.

---

## Ã°Å¸Å¡â‚¬ How to Work Safely

1. **Clone the stable dev branch:**

   ```bash
   git clone -b dev https://github.com/USERNAME/REPO_NAME.git

   ```

2. **Create your personal branch:**

   ```bash
   git checkout -b yourname_feature

   ```

3. **Do your work on your branch:**
   - Add, commit, and push only to your branch.

   ```bash
   git add .
   git commit -m "Add new feature"
   git push -u origin yourname_feature

   ```

4. **Team contribution**
   - Frontend Ã¢â€ â€™ PR to **`frontend_dev`**
   - Backend Ã¢â€ â€™ PR to **`backend_dev`**

5. **Merging to dev:**
   - Only after team branch review (**`frontend_dev`** or **`backend_dev`**) are changes merged into **`dev`**.

---

## Ã¢Å¡Â Ã¯Â¸Â Important Rules

      - Never push directly to dev.

      - Follow branch naming rules for personal branches.

      - Use pull requests for team branches ('frontend_dev' or 'backend_dev').

      - Keep 'dev' stable - it should always be safe to clone.

---

## Ã°Å¸â€œÂ Project Structure

```bash

arma2 - Copy
Ã¢â€Å“Ã¢â€â‚¬ .metadata
Ã¢â€Å“Ã¢â€â‚¬ analysis_options.yaml
Ã¢â€Å“Ã¢â€â‚¬ android
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ .gradle
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ 8.14
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ checksums
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ checksums.lock
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ md5-checksums.bin
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ sha1-checksums.bin
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ executionHistory
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ executionHistory.bin
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ executionHistory.lock
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ expanded
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ fileChanges
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ last-build.bin
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ fileHashes
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ fileHashes.bin
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ fileHashes.lock
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ resourceHashesCache.bin
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ gc.properties
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ vcsMetadata
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ 8.9
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ checksums
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ checksums.lock
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ expanded
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ fileChanges
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ last-build.bin
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ fileHashes
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ fileHashes.lock
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ gc.properties
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ vcsMetadata
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ buildOutputCleanup
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ buildOutputCleanup.lock
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ cache.properties
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ outputFiles.bin
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ file-system.probe
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ noVersion
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ buildLogic.lock
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ vcs-1
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ gc.properties
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ .kotlin
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ sessions
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ app
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ build.gradle.kts
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ google-services.json
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ src
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ debug
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ AndroidManifest.xml
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ main
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ AndroidManifest.xml
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ java
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ io
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ flutter
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š  Ã¢â€â€š        Ã¢â€â€Ã¢â€â‚¬ plugins
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š  Ã¢â€â€š           Ã¢â€â€Ã¢â€â‚¬ GeneratedPluginRegistrant.java
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ kotlin
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ com
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ example
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š  Ã¢â€â€š        Ã¢â€â€Ã¢â€â‚¬ arma2
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š  Ã¢â€â€š           Ã¢â€â€Ã¢â€â‚¬ MainActivity.kt
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ res
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ drawable
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š     Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ launch_background.xml
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ drawable-v21
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š     Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ launch_background.xml
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ mipmap-hdpi
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š     Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ ic_launcher.png
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ mipmap-mdpi
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š     Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ ic_launcher.png
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ mipmap-xhdpi
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š     Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ ic_launcher.png
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ mipmap-xxhdpi
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š     Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ ic_launcher.png
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ mipmap-xxxhdpi
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š     Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ ic_launcher.png
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ values
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š     Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ styles.xml
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ values-night
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€š        Ã¢â€â€Ã¢â€â‚¬ styles.xml
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ profile
Ã¢â€â€š  Ã¢â€â€š        Ã¢â€â€Ã¢â€â‚¬ AndroidManifest.xml
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ build.gradle.kts
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ gradle
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ wrapper
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ gradle-wrapper.jar
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ gradle-wrapper.properties
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ gradle.properties
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ gradlew
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ gradlew.bat
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ local.properties
Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ settings.gradle.kts
Ã¢â€Å“Ã¢â€â‚¬ assets
Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ logo.png
Ã¢â€Å“Ã¢â€â‚¬ CODE_EXPLANATION.txt
Ã¢â€Å“Ã¢â€â‚¬ ios
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Flutter
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ AppFrameworkInfo.plist
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Debug.xcconfig
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ ephemeral
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ flutter_lldbinit
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ flutter_lldb_helper.py
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ flutter_export_environment.sh
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Generated.xcconfig
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ Release.xcconfig
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Runner
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ AppDelegate.swift
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Assets.xcassets
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ AppIcon.appiconset
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Contents.json
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Icon-App-1024x1024@1x.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Icon-App-20x20@1x.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Icon-App-20x20@2x.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Icon-App-20x20@3x.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Icon-App-29x29@1x.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Icon-App-29x29@2x.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Icon-App-29x29@3x.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Icon-App-40x40@1x.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Icon-App-40x40@2x.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Icon-App-40x40@3x.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Icon-App-60x60@2x.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Icon-App-60x60@3x.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Icon-App-76x76@1x.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Icon-App-76x76@2x.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ Icon-App-83.5x83.5@2x.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ LaunchImage.imageset
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ Contents.json
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ LaunchImage.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ LaunchImage@2x.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ LaunchImage@3x.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ README.md
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Base.lproj
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ LaunchScreen.storyboard
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ Main.storyboard
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ GeneratedPluginRegistrant.h
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ GeneratedPluginRegistrant.m
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Info.plist
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ Runner-Bridging-Header.h
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Runner.xcodeproj
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ project.pbxproj
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ project.xcworkspace
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ contents.xcworkspacedata
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ xcshareddata
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ IDEWorkspaceChecks.plist
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ WorkspaceSettings.xcsettings
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ xcshareddata
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ xcschemes
Ã¢â€â€š  Ã¢â€â€š        Ã¢â€â€Ã¢â€â‚¬ Runner.xcscheme
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Runner.xcworkspace
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ contents.xcworkspacedata
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ xcshareddata
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ IDEWorkspaceChecks.plist
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ WorkspaceSettings.xcsettings
Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ RunnerTests
Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ RunnerTests.swift
Ã¢â€Å“Ã¢â€â‚¬ lib
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ backend
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ services
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ auth_service.dart
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ messaging_service.dart
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ notification_service.dart
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ frontend
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ pages
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ forgot_password_page.dart
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ home_screen.dart
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ login_page.dart
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ signup_page.dart
Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ main.dart
Ã¢â€Å“Ã¢â€â‚¬ linux
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ CMakeLists.txt
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ flutter
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ CMakeLists.txt
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ generated_plugins.cmake
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ generated_plugin_registrant.cc
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ generated_plugin_registrant.h
Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ runner
Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ CMakeLists.txt
Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ main.cc
Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ my_application.cc
Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ my_application.h
Ã¢â€Å“Ã¢â€â‚¬ macos
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Flutter
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ ephemeral
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Flutter-Generated.xcconfig
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ flutter_export_environment.sh
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Flutter-Debug.xcconfig
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Flutter-Release.xcconfig
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ GeneratedPluginRegistrant.swift
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Runner
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ AppDelegate.swift
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Assets.xcassets
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ AppIcon.appiconset
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ app_icon_1024.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ app_icon_128.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ app_icon_16.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ app_icon_256.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ app_icon_32.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ app_icon_512.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ app_icon_64.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ Contents.json
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Base.lproj
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ MainMenu.xib
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Configs
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ AppInfo.xcconfig
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Debug.xcconfig
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Release.xcconfig
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ Warnings.xcconfig
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ DebugProfile.entitlements
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Info.plist
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ MainFlutterWindow.swift
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ Release.entitlements
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Runner.xcodeproj
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ project.pbxproj
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ project.xcworkspace
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ xcshareddata
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ IDEWorkspaceChecks.plist
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ xcshareddata
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ xcschemes
Ã¢â€â€š  Ã¢â€â€š        Ã¢â€â€Ã¢â€â‚¬ Runner.xcscheme
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Runner.xcworkspace
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ contents.xcworkspacedata
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ xcshareddata
Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ IDEWorkspaceChecks.plist
Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ RunnerTests
Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ RunnerTests.swift
Ã¢â€Å“Ã¢â€â‚¬ pubspec.lock
Ã¢â€Å“Ã¢â€â‚¬ pubspec.yaml
Ã¢â€Å“Ã¢â€â‚¬ README.md
Ã¢â€Å“Ã¢â€â‚¬ test
Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ widget_test.dart
Ã¢â€Å“Ã¢â€â‚¬ web
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ favicon.png
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ icons
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Icon-192.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Icon-512.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ Icon-maskable-192.png
Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ Icon-maskable-512.png
Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ index.html
Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ manifest.json
Ã¢â€â€Ã¢â€â‚¬ windows
   Ã¢â€Å“Ã¢â€â‚¬ CMakeLists.txt
   Ã¢â€Å“Ã¢â€â‚¬ flutter
   Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ CMakeLists.txt
   Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ ephemeral
   Ã¢â€â€š  Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ .plugin_symlinks
   Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ cloud_firestore
   Ã¢â€â€š  Ã¢â€â€š     Ã¢â€Å“Ã¢â€â‚¬ firebase_auth
   Ã¢â€â€š  Ã¢â€â€š     Ã¢â€â€Ã¢â€â‚¬ firebase_core
   Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ generated_plugins.cmake
   Ã¢â€â€š  Ã¢â€Å“Ã¢â€â‚¬ generated_plugin_registrant.cc
   Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ generated_plugin_registrant.h
   Ã¢â€â€Ã¢â€â‚¬ runner
      Ã¢â€Å“Ã¢â€â‚¬ CMakeLists.txt
      Ã¢â€Å“Ã¢â€â‚¬ flutter_window.cpp
      Ã¢â€Å“Ã¢â€â‚¬ flutter_window.h
      Ã¢â€Å“Ã¢â€â‚¬ main.cpp
      Ã¢â€Å“Ã¢â€â‚¬ resource.h
      Ã¢â€Å“Ã¢â€â‚¬ resources
      Ã¢â€â€š  Ã¢â€â€Ã¢â€â‚¬ app_icon.ico
      Ã¢â€Å“Ã¢â€â‚¬ runner.exe.manifest
      Ã¢â€Å“Ã¢â€â‚¬ Runner.rc
      Ã¢â€Å“Ã¢â€â‚¬ utils.cpp
      Ã¢â€Å“Ã¢â€â‚¬ utils.h
      Ã¢â€Å“Ã¢â€â‚¬ win32_window.cpp
      Ã¢â€â€Ã¢â€â‚¬ win32_window.h

```
