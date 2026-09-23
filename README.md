<div align="center">
  <img src="https://raw.githubusercontent.com/prateek54353/PaperWise/main/icon.png" alt="Paperwise logo" width="120" />
  <h1>Paperwise</h1>
  <p><strong>A private, open-source document scanner and PDF toolkit for Android.</strong></p>
</div>

<div align="center">
  <a href="https://github.com/prateek54353/PaperWise/releases/tag/v2.6.2">
    <img src="https://img.shields.io/badge/Latest%20release-v2.6.2-blue?style=for-the-badge" alt="Latest release: v2.6.2" />
  </a>
  <a href="https://github.com/prateek54353/PaperWise/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/prateek54353/PaperWise?style=for-the-badge&label=License" alt="MIT License" />
  </a>
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Platform: Android" />
</div>

---

Paperwise turns photos and scanned pages into PDF documents while keeping your files on your device. It is ad-free, tracker-free, and built with Flutter.

## What's new in v2.6.2

Version 2.6.1 introduces a complete PDF-management workflow:

- **Merge PDFs** with preview thumbnails, drag-to-reorder, custom output names, and merge progress.
- **Split PDFs** from a visual page selector—either create one PDF from selected pages or export every page separately.
- **Sort documents** by date, name, size, or page count.
- **Use quick actions**: long-press a PDF for merge, share, or delete operations.
- **Undo and redo image edits** in the scan screen with history-based controls.
- **Enjoy a refined Material 3 experience** with automatic light/dark theme switching, clearer feedback, and improved validation and error handling.

> **PDF fidelity note:** Merge and split operations render pages to images. Complex vector content, text layers, and annotations may not be preserved exactly.

See the full details in the [v2.6.2 release notes](https://github.com/prateek54353/PaperWise/releases/tag/v2.6.2).

## Features

- **Scan from camera or gallery**: Capture documents or import multiple images at once.
- **Edit before export**: Reorder, crop, filter, or remove pages, then undo or redo edits when needed.
- **Create PDFs your way**: Choose A4, Letter, Legal, or Fit to Image; adjust compression to balance quality and file size.
- **Manage PDFs**: Preview, sort, merge, split, share, and delete PDFs directly in the app.
- **Themes that fit your device**: Light, dark, and AMOLED Black options.
- **Private by design**: No ads, trackers, or unnecessary permissions; files remain on your device.
- **Open source**: Free to use, inspect, modify, and distribute under the MIT License.

## Screenshots

<div align="center">
  <img src="https://raw.githubusercontent.com/prateek54353/PaperWise/main/screenshots/1.jpg" alt="Paperwise scan screen" height="500" />
  <img src="https://raw.githubusercontent.com/prateek54353/PaperWise/main/screenshots/2.jpg" alt="Paperwise editing screen" height="500" />
  <img src="https://raw.githubusercontent.com/prateek54353/PaperWise/main/screenshots/3.jpg" alt="Paperwise PDF screen" height="500" />
</div>

## Download

Download the latest Android release from [GitHub Releases](https://github.com/prateek54353/PaperWise/releases/tag/v2.6.2). You can also install Paperwise through [IzzyOnDroid](https://apt.izzysoft.de/packages/org.paperwise.app/), which is recommended for automatic updates.

## Build from source

Paperwise requires Flutter 3.32.8 (managed through FVM) and a compatible Android toolchain.

```bash
git clone https://github.com/prateek54353/PaperWise.git
cd PaperWise
fvm install
fvm flutter pub get
fvm flutter build apk --release --split-per-abi
```

## Contributing

Contributions are welcome. Fork the project, create a feature branch, make and test your changes, then open a pull request.

## Support

If Paperwise is useful to you, consider [buying me a coffee](https://coff.ee/prateek.aish).

## License

Paperwise is distributed under the [MIT License](LICENSE).
