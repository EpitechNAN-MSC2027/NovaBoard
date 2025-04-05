# NovaBoard

NovaBoard is a Trello-like mobile board management application developed as part of a course at Epitech. It allows users to view and interact with Trello boards, lists, and cards directly from a Flutter-based mobile app. The application uses the official Trello API and is available for both Android and iOS.

---

## 🚀 Key Features

- 📂 View Trello boards
- 📅 Display lists and cards
- 🔐 Trello authentication via API key/token
- 📆 Check card deadlines
- 📄 View card descriptions
- 💼 Mobile-friendly interface

---

## 📁 Project Structure

```
NovaBoard/
├── lib/               # Flutter source code
├── assets/            # Images and other static assets
├── android/           # Android-specific config
├── ios/               # iOS-specific config
├── pubspec.yaml       # Flutter dependencies
```

---

## 🧰 Technologies Used

- Flutter
- Dart
- Trello API
- Provider (for state management)
- HTTP package for API calls

---

## 📂 Local Installation

### Prerequisites

- Flutter SDK (3.x recommended)
- Android Studio / Xcode for emulators or physical device

### 1. Clone the repository

```bash
git clone https://github.com/EpitechNAN-MSC2027/NovaBoard.git
cd NovaBoard
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Trello API access

Create a `.env` file (or use a secrets config) with your Trello API key and token:

```env
TRELLO_API_KEY=your_key_here
TRELLO_TOKEN=your_token_here
```

You can obtain your credentials from [Trello Developer API](https://trello.com/app-key)

### 4. Run the app

```bash
flutter run
```

---

## 🌐 API Reference

This app uses the official Trello REST API:
- [Trello API Docs](https://developer.atlassian.com/cloud/trello/rest/)

---

## 🎓 Authors

This project was developed by Epitech students.

---

## ✉️ Contributions

Contributions are welcome! Please follow these best practices:

- Fork the repository
- Create a feature branch
- Submit a descriptive Pull Request

---

## 🛡️ License

This project is under the MIT license. See the [LICENSE](../LICENSE) file for details.

---

## 🚧 TODO (Roadmap)

- [ ] Offline mode
- [ ] Better drag and drop features
- [ ] Push notifications
- [ ] UI customization options

