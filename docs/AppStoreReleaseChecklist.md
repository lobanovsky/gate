# App Store Release Checklist

## Перед архивом

- Проверьте `BACKEND_BASE_URL` в `Configs/Release.xcconfig`.
- Убедитесь, что `PRODUCT_BUNDLE_IDENTIFIER` и `Team` соответствуют production App ID.
- Проверьте отображаемое имя приложения, иконку и тексты на экране логина.
- Проверьте на реальном iPhone:
  - логин
  - регистрация
  - восстановление пароля
  - вход по Face ID
  - открытие устройств через API
  - телефонные вызовы через `tel:`

## App Store Connect

- Создайте приложение в App Store Connect.
- Заполните:
  - `Name`
  - `Subtitle`
  - `Description`
  - `Keywords`
  - `Support URL`
  - `Privacy Policy URL`
  - `Category`
  - `Age Rating`
- Подготовьте `App Privacy`:
  - email
  - номер телефона
  - логин/учётные данные
  - diagnostics/analytics, если используются

## Reviewer Notes

- Подготовьте тестовый аккаунт для App Review.
- Опишите основной сценарий:
  - пользователь логинится
  - видит зоны `Паркинг` и `Двор`
  - открывает устройство кнопкой
  - при отсутствии интернета может использовать вызов через `tel:`
- Укажите, что приложение предназначено для управления дворовыми шлагбаумами и воротами паркинга.

## Archive / Upload

- В Xcode выполните `Product > Archive`.
- Выполните `Validate App`.
- Загрузите build в App Store Connect.
- Раскатайте build в TestFlight и пройдите smoke test до отправки в Review.

## Smoke Test

- Проверить запуск после установки из TestFlight.
- Проверить сохранённые credentials и вход через Passwords / Face ID.
- Проверить поведение без интернета.
- Проверить сообщение об ошибке backend при неверном логине и при конфликте регистрации.
- Проверить, что layout кнопок не ломается на маленьких экранах.

