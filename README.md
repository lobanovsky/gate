# Gate iOS App

Нативное iOS-приложение на SwiftUI для управления ограждающими устройствами ELDES. Приложение повторяет основной сценарий PWA из `/Users/evgeny/Projects/tsn/eldes-app`: после авторизации пользователь видит две зоны, `Двор` и `Паркинг`, и по две команды в каждой зоне: `Заехать` и `Выехать`.

## Что реализовано

- вход через backend `POST /api/auth/login`
- загрузка устройств через `GET /api/private/devices`
- отправка команды открытия через `POST /api/private/devices/:id/open`
- сохранение сессии в `UserDefaults`
- фиксированный главный экран `2 x 2`, построенный поверх данных backend

Если backend возвращает динамический список зон и устройств, приложение маппит его в четыре кнопки по названиям зон и устройств. Сначала ищутся ключевые слова (`двор`, `паркинг`, `заезд`, `выезд`), затем используется fallback по порядку устройств в зоне.

## Структура проекта

```text
GateApp/
├── App/             # entry point, root navigation
├── Features/
│   ├── Auth/        # экран логина
│   └── Gates/       # главный экран и карточки зон
├── Models/          # модели API и UI
├── Services/        # API client, state, mapping
└── Resources/       # asset catalogs
```

## Настройка backend

Базовый URL задаётся в:

- `Configs/Debug.xcconfig`
- `Configs/Release.xcconfig`

Измените значение:

```xcconfig
BACKEND_BASE_URL = https://gate-backend.housekpr.ru
```

## Запуск

1. Откройте [GateApp.xcodeproj](/Users/evgeny/Projects/ios/gate/GateApp.xcodeproj) в Xcode.
2. Выберите target `Gate`.
3. Укажите ваш `BACKEND_BASE_URL` в `xcconfig`.
4. Запустите приложение на симуляторе или устройстве.

## Проверка

На этой машине проверено следующее:

- `xcodebuild -list -project GateApp.xcodeproj` проходит
- Swift-исходники проходят `swiftc -typecheck` с iOS SDK

Полный `xcodebuild test` не выполнен, потому что в установленном Xcode отсутствуют iOS simulator/device runtimes. После установки platform components в `Xcode > Settings > Components` проект можно собрать и прогнать тесты штатно.
