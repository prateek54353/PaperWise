# Paperwise PDF Maker

![CI](https://github.com/your-username/paperwise_pdf_maker/actions/workflows/flutter.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A simple, privacy-focused, free and open-source app to scan images and create PDF documents.

## Features

* **Scan from Anywhere**: Pick multiple images from your gallery or take new ones with your camera.
* **Powerful Editing**: Reorder, crop, and delete images before creating your PDF.
* **Flexible Page Sizing**: Choose from standard page sizes (A4, Letter) or use "Fit to Image" to create perfectly sized pages.
* **Quality Control**: Adjust the PDF image quality to balance file size and clarity.
* **Theming**: Includes light, dark, and a battery-saving AMOLED Black theme.
* **Privacy First**: No trackers, no ads, and no unnecessary permissions. Your files are saved locally on your device and are always under your control.
* **FOSS**: Free and Open-Source Software.

## F-Droid

This application is designed to be fully compliant with F-Droid's inclusion policy.

<a href='https://f-droid.org/packages/your.package.id/'>
    <img alt='Get it on F-Droid' src='https://fdroid.gitlab.io/artwork/badge/get-it-on.png' height='100'/>
</a>

*(This badge will work once your app is accepted on F-Droid)*

## Building from Source

To build this project, ensure you have the Flutter SDK installed.

```bash
# Clone the repository
git clone [https://github.com/your-username/paperwise_pdf_maker.git](https://github.com/your-username/paperwise_pdf_maker.git)
cd paperwise_pdf_maker

# Install dependencies
flutter pub get

# Build the APK
flutter build apk --release