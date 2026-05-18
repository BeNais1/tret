# Firebase Setup для Tret

Пошаговая инструкция для настройки Firebase backend. Делается один раз перед первым релизом.

## 1. Создание проекта Firebase

1. Зайди на [console.firebase.google.com](https://console.firebase.google.com).
2. Нажми **Create a project** (или **Add project**).
3. Имя проекта: `tret-app` (или своё). Можно отключить Google Analytics для MVP — добавим позже.
4. Дождись создания.

## 2. Регистрация iOS-приложения

1. На странице проекта → иконка iOS (или **Add app** → iOS).
2. **Apple bundle ID:** `io.tret.ios` — обязательно именно такой.
3. **App nickname:** `Tret iOS`.
4. **App Store ID** — оставь пустым.
5. Нажми **Register app**.
6. Скачай `GoogleService-Info.plist`.
7. Положи файл в `Tret/Resources/GoogleService-Info.plist` (рядом с `Info.plist`).
8. Закоммить и запушь. Файл НЕ секретный — он защищён Firestore Rules и App Check.

Шаги «Add Firebase SDK» и «Add initialization code» в консоли можно **пропустить** — SDK уже подключён через SPM, инициализация в `Tret/App/TretApp.swift`.

## 3. Включить Authentication

1. В консоли → **Build** → **Authentication** → **Get started**.
2. Вкладка **Sign-in method** → **Google** → **Enable**.
3. **Support email** — твой email.
4. Сохрани.

## 4. Включить Cloud Firestore

1. **Build** → **Firestore Database** → **Create database**.
2. Локация: `eur3 (europe-west)` или ближайшая. **Менять её потом нельзя.**
3. Режим: **Start in production mode** — наши правила в `firestore.rules` рассчитаны на это.
4. Done.

## 5. Storage (опционально, требует план Blaze)

В MVP без Storage аватарка берётся из Google-аккаунта (поле `photoURL`), а картинки в постах будут реализованы в Stage 2 — к тому моменту понадобится Storage.

Когда будешь готов:
1. Перейди на тариф **Blaze (Pay as you go)** в **Settings → Usage and billing**. Бесплатный лимит щедрый (5 GB хранилища + 1 GB/день трафика).
2. **Build** → **Storage** → **Get started** → **Start in production mode**, регион — тот же, что у Firestore.
3. Раскомментируй вызов `StorageService.uploadAvatar` в [OnboardingViewModel.swift](../Tret/ViewModels/OnboardingViewModel.swift) и верни `PhotosPicker` в `OnboardingStep1`.
4. Деплой правил Storage: `firebase deploy --only storage`.

SDK Firebase Storage уже подключён через SPM, так что в коде ничего пересобирать не нужно.

## 6. Настроить Google Sign-In URL scheme

`GoogleService-Info.plist` содержит ключ `REVERSED_CLIENT_ID` (что-то вроде `com.googleusercontent.apps.1234567890-abcdefg`).

1. Открой `Tret/Resources/GoogleService-Info.plist` в любом текстовом редакторе.
2. Найди значение `REVERSED_CLIENT_ID`.
3. Открой `Tret/Resources/Info.plist`.
4. В `CFBundleURLTypes` → `CFBundleURLSchemes` подставь это значение вместо `REVERSED_CLIENT_ID_PLACEHOLDER`.

## 7. Деплой Firestore-правил и индексов

Установи Firebase CLI (работает на Windows через npm):
```powershell
npm install -g firebase-tools
firebase login
```

Привяжи локальный репозиторий к проекту:
```powershell
firebase use --add
# выбери проект tret-app, alias: default
```

Деплой правил Firestore и индексов:
```powershell
firebase deploy --only firestore:rules,firestore:indexes
```

`storage` к команде добавишь когда апгрейднешь план до Blaze и включишь Storage (см. шаг 5).

## 8. Проверка

1. Запушь изменения — GitHub Actions должен успешно собрать проект.
2. На устройстве/симуляторе после запуска должен открыться экран Welcome → Continue with Google.
3. После входа: либо онбординг (новый пользователь), либо главное меню (существующий).

## Дальнейшие шаги (потом)

- **App Check** — защита от злоупотреблений API. Включить в Stage 4.
- **Firebase Cloud Messaging** — пуш-уведомления (Stage 10).
- **Cloud Functions** — для обновления `topCommentPreview`, миграций username, счётчиков.
