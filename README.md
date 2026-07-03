<h1 align="center">TG WS Proxy iOS</h1>

<h4 align="center">Локальный MTProto-прокси для Telegram на iOS с Rust-ядром, WidgetKit, Live Activity и опциональным Packet Tunnel.</h4>

<p align="center">
  <a href="docs/README.md">English</a>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPLv3-blue?style=for-the-badge&logo=gnu&logoColor=white" alt="GPLv3"></a>
  <img src="https://img.shields.io/badge/iOS-17%2B-black?style=for-the-badge&logo=apple&logoColor=white" alt="iOS 17+">
  <img src="https://img.shields.io/badge/Swift-SwiftUI-F05138?style=for-the-badge&logo=swift&logoColor=white" alt="SwiftUI">
  <img src="https://img.shields.io/badge/Core-Rust-000000?style=for-the-badge&logo=rust&logoColor=white" alt="Rust">
</p>

---

**TG WS Proxy iOS** запускает Rust-версию TG WS Proxy на iPhone и предоставляет Telegram локальный MTProto endpoint:

```text
Telegram → 127.0.0.1:1443 → Rust TG WS Proxy → WSS / Cloudflare → Telegram DC
```

> [!CAUTION]
> **Это экспериментальный сетевой инструмент. Он работает, но ошибочная конфигурация Packet Tunnel может полностью «убить» интернет на устройстве до отключения VPN, переустановки приложения или перезагрузки iPhone. Приложение не проходило аудит безопасности. Используйте только на свой риск и не устанавливайте IPA из источников, которым не доверяете.**

---

## ✨ Возможности

- локальный MTProto-прокси на Rust;
- Cloudflare Workers, пользовательский домен и обновляемый список доменов;
- размеры WebSocket-пула `2`, `4` или `6`;
- статистика трафика, состояние пула, логи и диагностика;
- Liquid Glass с возможностью отключения;
- Live Activity и Dynamic Island одним компонентом `la`;
- интерактивный Home Screen Widget;
- системный toggle для Control Center;
- App Intents и Siri Shortcuts;
- deep links для запуска, остановки и настройки;
- RU/EN интерфейс;
- автоматический fallback на loopback, если Packet Tunnel недоступен.

---

## 📚 Подробное описание работы

[Как работает iOS-приложение: режимы, фон, поток данных, ограничения](docs/ARCHITECTURE.ru.md)

---

## 🧬 Происхождение и благодарности

- [Flowseal/tg-ws-proxy](https://github.com/Flowseal/tg-ws-proxy) — оригинальный проект и основная идея;
- [amurcanov/tg-ws-proxy-android](https://github.com/amurcanov/tg-ws-proxy-android) — Rust-ядро и Android-форк, используемые как upstream;
- [Flowseal/tg-ws-proxy issue #389](https://github.com/Flowseal/tg-ws-proxy/issues/389) — FAQ и полезное обсуждение;
- [IMDelewer/tg-ws-proxy-ios](https://github.com/IMDelewer/tg-ws-proxy-ios) — iOS-оболочка, сборочная система и интеграция Apple frameworks.

Rust-ядро подключено как git submodule в `vendor/tg-ws-proxy-android`. Из него используются только `src/*.rs`, `Cargo.toml` и `Cargo.lock`. iOS-адаптация накладывается патчем `scripts/patches/ios-ffi.patch`.

---

## 📦 Варианты установки

| Вариант | Bundle ID | Расширения | Фон |
| :--- | :--- | :---: | :--- |
| AltStore / SideStore | `com.delewer.tgwsproxy.altstore` | опционально | зависит от entitlements |
| Sideload / iLoader / TrollStore | `com.delewer.tgwsproxy.sideload` | опционально | Packet Tunnel при подходящей подписи |
| LiveContainer | `com.delewer.tgwsproxy.lc` | нет | только пока гостевое приложение активно |
| Simulator | `com.delewer.tgwsproxy.sim` | все для проверки | loopback fallback |

Обычное iOS-приложение нельзя бесконечно удерживать в фоне. Для постоянной работы нужен `PacketTunnelProvider`, который запускается системой отдельно от интерфейса.

### Бесплатный Apple ID

- provisioning profile и App IDs действуют 7 дней;
- AltStore может обновлять подпись, пока AltServer доступен по Wi‑Fi или USB;
- бесплатный профиль может не содержать Network Extension или App Groups entitlement;
- LiveContainer не регистрирует вложенные app extensions.

---

## 🚀 Сборка

Требуются полный Xcode и Rust stable:

```bash
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
```

Инициализация submodule:

```bash
git submodule update --init
```

Универсальный builder:

```bash
./build.sh -p sim --install
./build.sh -p sim -c wd,la,cc,vpn --install
./build.sh -p side -c wd,la,cc,vpn
./build.sh -p alt
./build.sh -p lc
```

Платформы:

| Код | Назначение |
| :---: | :--- |
| `sim` | активный iOS Simulator |
| `side` | iLoader, Sideloadly, TrollStore и другие signer-ы |
| `alt` | AltStore / SideStore |
| `lc` | LiveContainer без extensions |

Компоненты:

| Код | Компонент |
| :---: | :--- |
| `wd` | Home Screen Widget |
| `la` | Live Activity + Dynamic Island |
| `cc` | Control Center toggle, iOS 18+ |
| `vpn` | Packet Tunnel / Network Extension |
| `none` | только приложение |

`--install` доступен для `sim`: builder собирает Rust, приложение и выбранные extensions, устанавливает их в активный Simulator и запускает приложение.

Артефакты сохраняются в `dist/`.

---

## 🔗 Deep links

```text
tgwsproxy://home
tgwsproxy://settings
tgwsproxy://logs
tgwsproxy://info
tgwsproxy://collect_logs?copy=true

tgwsproxy://?action=start
tgwsproxy://?action=stop
tgwsproxy://?action=update_cf_link
tgwsproxy://?action=show_cf_domains
tgwsproxy://?action=add_cf_domain&domain=worker.example.com
tgwsproxy://?action=clear_cf_domain
```

Полная настройка:

```text
tgwsproxy://?action=config&addr=127.0.0.1&port=1443&pool=4&cf_proxy=true&cf_domain=worker.example.com&verbose=false&autostart=true&reconnect=true&glass=true&dynamic_island=true&language=ru&theme=system&accent=telegram&start=true&open=home
```

---

## 🔄 Rust upstream

Ручная синхронизация из submodule:

```bash
./scripts/sync-rust-upstream.sh
cargo check --manifest-path src-wrapper/Cargo.toml --locked
```

Текущий commit записан в `src-wrapper/UPSTREAM_COMMIT`, источник — в `src-wrapper/UPSTREAM_URL`, iOS-адаптация — в `scripts/patches/ios-ffi.patch`.

---

## 🗂 Структура

```text
tg-ws-proxy-ios/
├── .github/workflows/       GitHub Actions
├── config/                  варианты bundle ID
├── docs/                    документация
├── ios/
│   ├── TgWsProxy/           SwiftUI-приложение
│   ├── PacketTunnel/        Network Extension
│   └── StatusWidgets/       widgets, Live Activity, Control Center
├── scripts/
│   ├── patches/             iOS FFI patch
│   ├── build-rust-ios.sh
│   └── sync-rust-upstream.sh
├── src-wrapper/             рабочая копия Rust (upstream + patch)
├── tests/                   C ABI smoke test
├── vendor/
│   └── tg-ws-proxy-android/ upstream репозиторий (submodule)
├── build.sh                 единая точка сборки
└── dist/                    собранные IPA
```

---

## ⚖️ Лицензии

- Rust fork и этот объединённый проект распространяются по [GPLv3](LICENSE).
- Оригинальный проект Flowseal содержит MIT-лицензированный код; копия лицензии находится в [LICENSE-flowseal](LICENSE-flowseal).
- Названия Telegram и Apple принадлежат соответствующим правообладателям. Проект не аффилирован с Telegram FZ-LLC или Apple Inc.

---

<p align="center">
  Powered by <a href="https://github.com/Flowseal/tg-ws-proxy">Flowseal/tg-ws-proxy</a>
  and <a href="https://github.com/amurcanov/tg-ws-proxy-android">amurcanov/tg-ws-proxy-android</a>
</p>

<p align="center"><sub>Maintained by <a href="https://github.com/IMDelewer">IMDelewer</a></sub></p>
