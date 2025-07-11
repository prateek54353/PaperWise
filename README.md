<div align="center">

  <img src="https://github.com/prateek54353/PaperWise/blob/ea0529bc6f8384ab947f9b9c91ed5a57ae44222d/icon.png" alt="Paperwise Logo" width="120" />

  # **Paperwise PDF Maker**
  
  **A simple, private, and open-source app to scan images and create PDF documents.**

</div>

<div align="center">

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/prateek54353/PaperWise?style=for-the-badge)](https://github.com/prateek54353/PaperWise/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://github.com/prateek54353/PaperWise/blob/main/LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/prateek54353/PaperWise/release.yml?branch=main&style=for-the-badge)](https://github.com/prateek54353/PaperWise/actions/workflows/release.yml)

</div>

---

<div align="center">
  <table>
    <tr>
      <td>
        <img src="https://raw.githubusercontent.com/prateek54353/PaperWise/main/screenshots/screenshot_1.jpg" height="600"/>
      </td>
      <td>
        <img src="https://raw.githubusercontent.com/prateek54353/PaperWise/main/screenshots/screenshot_2.jpg" height="600"/>
      </td>
    </tr>
  </table>
</div>

## ✨ Features

* 📸 **Scan from Anywhere**: Pick multiple images from your gallery or use the intelligent document scanner with automatic edge detection.
* ✂️ **Powerful Editing**: Reorder and delete images before creating your PDF.
* 📄 **Flexible Page Sizing**: Choose from standard page sizes (A4, Letter) or use "Fit to Image" for borderless scans.
* ⚖️ **Quality Control**: Adjust the PDF image quality (Low, Medium, High) to balance file size and clarity.
* 🎨 **Theming**: Includes light, dark, and a battery-saving **AMOLED Black** theme.
* 🔒 **Privacy First**: No trackers, no ads, and only essential permissions. Your files are saved locally on your device.
* ❤️ **FOSS**: 100% Free and Open-Source Software.

## 📥 Download & Installation

You can download the latest version of Paperwise from the official sources below. Getting the app from IzzyOnDroid is recommended for automatic updates.

<div align="center">
  <table border="0" cellpadding="0" cellspacing="10">
    <tr>
      <td valign="middle">
        <a href="https://github.com/prateek54353/PaperWise/releases/latest">
          <img src="https://img.shields.io/badge/Download-GitHub%20Releases-blue?style=for-the-badge&logo=github" alt="Download from GitHub" />
        </a>
      </td>
      <td valign="middle">
        <a href="https://apt.izzysoft.de/packages/org.paperwise.app/">
          <img alt="Get it on IzzyOnDroid" src="https://gitlab.com/IzzyOnDroid/repo/-/raw/master/assets/IzzyOnDroid.png" height="80"/>
        </a>
      </td>
    </tr>
  </table>
</div>

## ☕ Support This Project

If you find Paperwise useful and believe in the mission of privacy-focused, open-source software, please consider supporting my work. It helps me dedicate more time to building and maintaining tools like this.

<div align="center">
  <a href="https://coff.ee/prateek.aish" target="_blank">
    <img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me a Coffee" />
  </a>
</div>

## 🛠️ Building from Source

To build this project, ensure you have the Flutter SDK and FVM installed.

```bash
# Clone the repository
git clone [https://github.com/prateek54353/PaperWise.git](https://github.com/prateek54353/PaperWise.git)
cd PaperWise

# Use FVM to ensure you have the correct Flutter version
fvm install
fvm use

# Install dependencies
fvm flutter pub get

# Build the APK
fvm flutter build apk --release --split-per-abi
