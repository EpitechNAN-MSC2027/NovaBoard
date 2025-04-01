# Contributing to NovaBoard
Thank you for considering contributing to the NovaBoard project! We welcome contributions from the community and are happy to help you get started.

## Project Structure

- `lib/screens/` – Flutter screens (Workspaces, Lists, Cards...)
- `lib/services/` – Trello API service logic
- `test/widget/` – Widget/UI tests
- `test/services/` – Service logic and API tests

## Prerequisites

- Flutter SDK (stable version)
- Dart SDK
- IntelliJ IDEA or Android Studio with Flutter plugin
- A `.env` file with the following keys:
  ```
  TRELLO_API_KEY=your_api_key
  TRELLO_SECRET=your_secret
  ```

## How to Contribute
### 1. Download the repository
Start by forking the [NovaBoard GitHub repository](https://github.com/EpitechNAN-MSC2027/NovaBoard.git) to your own account. This allows you to freely make changes without affecting the main project.
### 2. Clone the Project on Your repository

Clone the project on your local machine:
git clone https://github.com/EpitechNAN-MSC2027/NovaBoard.git

cd novaboard

### 3. Create a Branch
Before making any changes, create a new branch for your feature or bug fix:
git checkout -b feature-name

### 4. Make Your Changes
Make your changes in the appropriate files and be sure to:
	•	Follow the existing coding style.
	•	Write meaningful commit messages.
	•	Ensure your changes pass tests.

For Flutter projects, run:
flutter run
flutter analyze

## Running Tests

To run all tests:
flutter test

To generate a test coverage report:
flutter test --coverage
To view the report, open `coverage/lcov.info` with your IDE.
In IntelliJ IDEA, you can also right-click on the `test/` folder and select “Run with Coverage”.

### 5. Commit Your Changes
Commit your changes with a clear and concise commit message:

git add .
git commit -m "Fix: Add feature XYZ"

### 6. Push Your Changes
Push your changes to your forked repository:
git push origin feature-name

### 7. Create a Pull Request (PR)
Go to the NovaBoard repository and create a pull request with a description of the changes you’ve made. We will review your PR and provide feedback.

Code Style
	•	Follow the Dart style guide: https://dart.dev/guides/language/effective-dart
	•	Use flutter analyze to check for any linting issues before committing.

Pull Request Process
	1.	Ensure your pull request has a descriptive title and summary.
	2.	We will review your PR and either approve or request modifications.
	3.	After approval, your PR will be merged into the main branch.

Reporting Issues

If you find a bug or want to request a feature:
	1.	Search for existing issues to avoid duplicates.
	2.	If not found, open a new issue with the following template:

## Issue

**Describe the bug/feature request:**

## Steps to Reproduce

1. Step 1
2. Step 2

## Expected Behavior

What should happen?

## Actual Behavior

What happens instead?

License

By contributing, you agree that your code will be shared under the same license as this project (MIT License).