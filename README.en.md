[Português](README.md) | **English**

# DiaKit

Everyday document tools — running on your own device, with no third-party servers involved.

## What it is

DiaKit is a cross-platform app (Android, iOS, Windows, macOS, Linux and Web) that bundles small everyday document tasks that usually require several different websites or programs. The first and main tool converts Word, Excel and PowerPoint files into print-ready PDFs.

**Already working:**
- Word / Excel / PowerPoint (`.doc`, `.docx`, `.xls`, `.xlsx`, `.ppt`, `.pptx`) → PDF
- PDF → Images
- CSV ↔ Excel

**Planned:**
- PDF → Word
- Compress PDF
- Sign PDF

## How it works

DiaKit has two parts that run locally, without sending your files to the cloud:

```
app/       Flutter — the interface (mobile, desktop and web)
backend/   Node.js/Express — receives the file and calls LibreOffice
           in headless mode to do the actual conversion
```

The app talks to the backend over HTTP (address configurable under *Profile › Conversion server*) — usually the device itself, but it can be another machine on the same local network. The backend never talks to the internet: it only calls the LibreOffice binary installed on the machine (or a portable copy fetched by `backend/scripts/fetch-libreoffice.ps1`) and returns the result.

## Running locally

**Backend**
```bash
cd backend
npm install
npm run fetch-libreoffice   # downloads a portable copy of LibreOffice (~1.5GB), or set SOFFICE_PATH to an existing install
npm start                   # starts on http://localhost:4123
```

**App**
```bash
cd app
flutter pub get
flutter run
```

## Roadmap

Development follows the "planned" tools listed above — each one becomes a new screen in the app and a new route in the backend, following the same pattern as the existing ones (`backend/src/routes/convert.js`). Suggestions, bug reports and pull requests are welcome via Issues/Pull Requests.

## License

This project is distributed under the [PolyForm Noncommercial License 1.0.0](LICENSE): you may use, study, modify and distribute the code freely for **noncommercial** purposes. Commercial use (selling, reselling, offering as a paid service, bundling into a paid product) requires a separate license — open an [issue](../../issues) to discuss it.
