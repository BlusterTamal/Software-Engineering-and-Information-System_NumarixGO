# 📱 NumarixGO - Your Ultimate Calculation & Conversion Assistant

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![License](https://img.shields.io/badge/license-MIT-orange.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey.svg)
![University Project](https://img.shields.io/badge/project-CSE%203104-blue)

**A comprehensive Flutter application designed to be your all-in-one solution for various calculations and Conversion needs**

[Features](#-features) • [Installation](#-installation) • [Tech Stack](#-tech-stack) • [Project Structure](#-project-structure) • [Screenshots](#-screenshots) • [Contributing](#-contributing)

</div>

---

### 📚 Course Information

**Course:** Softwere Engineering and Information Systems Project (0714 02 CSE 3104)   
**Year:** 3rd Year, 1st Term  
**Institution:** Khulna University

### 👨‍🏫 Course Instructor

- **Name**: Dr. Kazi Masudul Alam
- **Designation**: Professor
- **Discipline**: Computer Science and Engineering
- **Institution**: Khulna University 


## 📋 Table of Contents

- [About](#-about)
- [Features](#-features)
- [Screenshots](#-screenshots)
- [Tech Stack](#-tech-stack)
- [Installation](#-installation)
- [Project Structure](#-project-structure)
- [Usage](#-usage)
- [Build & Deploy](#-build--deploy)
- [Future Enhancements](#-future-enhancements)
- [Team & Course Details](#-team--course-details)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 About

**NumarixGO** is a modern, feature-rich mobile application built with Flutter that provides users with an extensive collection of calculators and utility tools. From everyday math problems to complex scientific calculations, currency conversions, personal finance tracking, and more - Smart Numerix aims to simplify your digital life.

### Key Highlights

- ✅ **11+ Powerful Tools** - Comprehensive collection of calculators and utilities
- 🎨 **Modern UI/UX** - Beautiful glassmorphic design with dark/light theme support
- 🌐 **Multi-language Support** - English and Bengali language options
- 💾 **Local Data Persistence** - Fast and secure offline data storage
- 📊 **Real-time Data** - Live currency rates and historical charts
- 🔒 **Privacy First** - All data stored locally, no cloud sync required

---

## ✨ Features

### 🧮 Calculators

#### 1. **Scientific Calculator**
- Advanced mathematical functions (sin, cos, tan, log, ln, etc.)
- Multiple number system support (Binary, Octal, Decimal, Hexadecimal)
- Matrix operations and calculations
- Degree/Radian mode conversion
- Real-time expression evaluation

#### 2. **BMI Calculator**
- Body Mass Index calculation
- Health category classification
- Height in cm or ft/in support
- Track your BMI history over time
- Personalized health suggestions

#### 3. **BMR Calculator**
- Basal Metabolic Rate calculation
- TDEE (Total Daily Energy Expenditure) estimation
- Gender and activity level considerations
- Fitness planning support

#### 4. **GPA & CGPA Calculator**
- Semester-wise GPA calculation
- Cumulative CGPA tracking
- Grade point conversion
- Student-friendly interface

---

### 💱 Converters

#### 5. **Currency Converter**
- Real-time exchange rates from multiple APIs
- Historical data visualization with FL Chart
- Support for 150+ currencies worldwide
- Offline mode with cached data
- Automatic API fallback mechanism

#### 6. **Unit Converter**
- **Length**: Meter, Kilometer, Mile, Yard, Feet, Inch, etc.
- **Weight**: Kilogram, Gram, Pound, Ounce
- **Temperature**: Celsius, Fahrenheit, Kelvin
- **Area**: Square Meter, Hectare, Acre, Square Feet
- **Volume**: Liter, Milliliter, Gallon, Cubic Meter
- **Speed**: m/s, km/h, mph, knots
- **Time**: Second, Minute, Hour, Day, Week

---

### 🛠️ Utilities

#### 7. **Password Generator**
- Random password generation
- Customizable length (4-32 characters)
- Multiple character sets (uppercase, lowercase, numbers, symbols)
- Word-based password generation
- Password strength indicator
- Save and manage generated passwords

#### 8. **Age Calculator**
- Precise age calculation
- Days, months, years breakdown
- Future date support

#### 9. **Land Size Calculator**
- Area conversion for real estate
- Multiple unit support
- Common regional measurements

#### 10. **Cost Calculator (Expense Tracker)**
- Daily expense tracking with calendar integration
- Category-based organization (Food, Transport, Shopping, etc.)
- Visual expense summary
- Database integration with Hive
- Delete and modify expenses

#### 11. **World Time Clock**
- Multiple timezone display
- Analog and digital clock views
- Beautiful UI with glassmorphic design

---

## 🎨 UI/UX Highlights

- **Glassmorphic Design** - Modern frosted-glass effects throughout
- **Smooth Animations** - Seamless transitions and interactive elements
- **Dark/Light Themes** - User-selectable themes with system integration
- **Intuitive Navigation** - Easy access to all features from centralized dashboard
- **Localization** - Bengali and English language support
- **Haptic Feedback** - Tactile responses for better user interaction
- **Responsive Layout** - Adapts gracefully to different screen sizes

---

## 🛠️ Tech Stack

### Core Framework
- **Flutter** 3.24.0 - Google's UI toolkit
- **Dart** 3.5.0 - Client-optimized language

### State Management & Architecture
- **Provider** - Simple yet powerful state management
- **ChangeNotifierProvider** - For theme and global state

### Data Storage
- **Hive** 2.2.3 - Blazing fast, lightweight database
- **Hive Flutter** - Hive integration for Flutter
- **SharedPreferences** - Key-value storage

### UI & Design
- **Google Fonts** - Font integration
- **Glassmorphic Design** - Modern frosted-glass aesthetics
- **BackdropFilter** - Blur effects
- **Custom Painters** - Dynamic background animations

### Charts & Visualization
- **FL Chart** - Beautiful, customizable charts

### Network & APIs
- **HTTP** - RESTful API communication
- **Currency Exchange APIs** - Multiple provider fallback

### Internationalization
- **Intl** - Date and number formatting
- **flutter_localizations** - Built-in localization support

### Additional Packages
- **Math Expressions** - Mathematical expression parsing and evaluation
- **Table Calendar** - Calendar widget for expense tracking
- **Path Provider** - File system paths

---

## 📦 Installation

### Prerequisites

- Flutter SDK (3.24.0 or higher)
- Dart SDK (3.5.0 or higher)
- Android Studio / VS Code
- Android SDK / Xcode (for iOS)

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/smart_numerix_v2.git
   cd smart_numerix_v2
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

4. **Build for production**
   ```bash
   # Android
   flutter build apk --release
   
   # iOS
   flutter build ios --release
   ```

---

## 📁 Project Structure

```
smart_numerix_v2/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── home_page.dart               # Main dashboard
│   ├── welcome_page.dart            # Onboarding screen
│   ├── app_themes.dart             # Theme definitions
│   ├── theme_provider.dart          # Theme management
│   ├── features/
│   │   ├── scientific_calculator.dart
│   │   ├── currency_converter.dart
│   │   ├── currency_service.dart
│   │   ├── unit_converter.dart
│   │   ├── password_generator.dart
│   │   ├── bmi_calculator.dart
│   │   ├── bmr_calculator.dart
│   │   ├── gpa_calculator.dart
│   │   ├── age_calculator.dart
│   │   ├── land_size_calculator.dart
│   │   ├── cost_calculator_page.dart
│   │   └── world_time.dart
│   └── widgets/
│       ├── feature_card.dart
│       ├── calculator_button.dart
│       └── add_expense_sheet.dart
├── android/                         # Android configuration
├── ios/                            # iOS configuration
├── assets/                         # Images and icons
├── pubspec.yaml                    # Dependencies
└── README.md                       # This file
```

---

## 🚀 Usage

### Getting Started

1. **Launch the app** - The welcome screen will appear
2. **Navigate through onboarding** - Learn about app features
3. **Access tools** - Tap any calculator from the home screen
4. **Switch themes** - Use the theme toggle in settings
5. **Change language** - Toggle between English and Bengali

### Tips

- **Offline Mode**: Most features work without internet
- **Data Persistence**: Your data is saved locally
- **Calendar Integration**: Use the expense tracker to manage daily costs
- **Quick Access**: Pin favorite tools for faster access

---

## 🔨 Build & Deploy

### Generate Hive Adapters

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Android Build

```bash
flutter build apk --release
flutter build appbundle
```

### iOS Build

```bash
flutter build ios --release
```

---

## 🎯 Future Enhancements

- [ ] Cloud backup and synchronization
- [ ] More calculators (Loan Calculator, Tip Calculator)
- [ ] Customizable themes and colors
- [ ] Home screen widgets
- [ ] Advanced analytics and charts
- [ ] Voice input integration
- [ ] Biometric authentication
- [ ] Export data to CSV/PDF
- [ ] Widget support for quick access
- [ ] Multi-currency expense tracking

---

## 👥 Team Details

- **MD. Ishrak Dewan** - Project Design, Developer and Idea Making. **(Student ID: 230212)**
- **Tamal Paul** - Project Lead, Idea Making, Android Studio Expert, App Build. **(Student ID: 230213)**
  - Email: tamalp241@gmail.com
  - GitHub: [@BlusterTamal](https://github.com/yourusername)
- **Jagaran Chakma** - Project Design, Error Solving, App Testing, Coding Expertise. **(Student ID: 230239)**


### 🎓 Project Purpose

This project was developed as part of the Mobile Application Development course curriculum. The application demonstrates proficiency in:

- Flutter framework and Dart programming
- State management using Provider
- Local data persistence with Hive
- RESTful API integration
- Modern UI/UX design principles
- Cross-platform mobile development

### 📝 Acknowledgments

Special thanks to:
- Course instructor for guidance and support
- Team Members for their help and support
- Flutter community for excellent documentation
- Open source package maintainers

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Contribution Guidelines

- Follow Dart style guide
- Write meaningful commit messages
- Add comments for complex logic
- Update README if adding new features
- Test thoroughly before submitting PR

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">


⭐ Star this repo if you find it helpful!

</div>

---

*Last Updated: October 2025*
