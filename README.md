# Tret

iOS-приложение — социальная сеть для программистов. Аналог Threads, но заточен под код: посты с кодом, привязкой к языку программирования, картинками, лайками, репостами, комментариями.

## Стек

- Swift 6, SwiftUI, iOS 26
- MVVM
- Firebase: Authentication, Firestore, Storage
- Google Sign-In
- Kingfisher для кеширования картинок
- Swift Package Manager — все зависимости
- **XcodeGen** для генерации `Tret.xcodeproj` из `project.yml` (проект не коммитится)

## Сборка

Локальная сборка делается через GitHub Actions (см. `.github/workflows/ios-build.yml`). На каждый push/PR в `main` поднимается macOS-раннер, ставит XcodeGen, генерирует проект и запускает `xcodebuild build` под iOS Simulator.

Если у тебя есть macOS и Xcode 16+:
```bash
brew install xcodegen
xcodegen generate
open Tret.xcodeproj
```

## Структура

```
tret/
├── .github/workflows/        # CI
├── Tret/
│   ├── App/                  # TretApp, AppState, AppDelegate
│   ├── Models/               # AppUser, Post, Comment, Repost, ...
│   ├── Services/             # Auth, User, Post, Storage, ...
│   ├── ViewModels/
│   ├── Views/                # Auth, Onboarding, Home, Profile, Shared
│   ├── Components/           # Переиспользуемые UI-компоненты
│   ├── Utilities/            # Validators, Constants, форматтеры
│   └── Resources/            # Info.plist, Assets, GoogleService-Info.plist
├── project.yml               # XcodeGen spec
├── firestore.rules
├── firestore.indexes.json
├── storage.rules
└── docs/FIREBASE_SETUP.md    # Пошаговая инструкция для настройки Firebase
```

## Firebase

Перед первым запуском нужно создать Firebase-проект — см. [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md).

## Текущий статус

**Stage 1** — фундамент проекта, аутентификация через Google и онбординг (5 шагов).

Дальнейшие стейджи (создание постов, фид, лайки, комментарии, репосты, профиль, поиск) реализуются отдельными итерациями.
