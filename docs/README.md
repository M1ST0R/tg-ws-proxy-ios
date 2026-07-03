<h1 align="center">TG WS Proxy iOS</h1>

<h4 align="center">A local Telegram MTProto proxy for iOS powered by a Rust core, WidgetKit, Live Activity, and an optional Packet Tunnel.</h4>

<p align="center">
  <a href="../README.md">Русский</a>
</p>

<p align="center">
  <a href="../LICENSE"><img src="https://img.shields.io/badge/License-GPLv3-blue?style=for-the-badge&logo=gnu&logoColor=white" alt="GPLv3"></a>
  <img src="https://img.shields.io/badge/iOS-17%2B-black?style=for-the-badge&logo=apple&logoColor=white" alt="iOS 17+">
  <img src="https://img.shields.io/badge/Swift-SwiftUI-F05138?style=for-the-badge&logo=swift&logoColor=white" alt="SwiftUI">
  <img src="https://img.shields.io/badge/Core-Rust-000000?style=for-the-badge&logo=rust&logoColor=white" alt="Rust">
</p>

---

**TG WS Proxy iOS** runs the Rust version of TG WS Proxy on iPhone and exposes a local MTProto endpoint to Telegram:

```text
Telegram → 127.0.0.1:1443 → Rust TG WS Proxy → WSS / Cloudflare → Telegram DC
```

> [!CAUTION]
> **This is experimental networking software. It works, but an invalid Packet Tunnel configuration may completely break device connectivity until the VPN is disabled, the app is reinstalled, or the iPhone is restarted. The project has not received a security audit. Use it at your own risk and never install an IPA from an untrusted source.**

---

## ✨ Features

- Rust-powered local MTProto proxy;
- Cloudflare Workers and custom domains;
- WebSocket pool sizes `2`, `4`, or `6`;
- traffic, pool, logs, and diagnostics;
- optional Liquid Glass interface;
- Live Activity and Dynamic Island through the single `la` component;
- interactive Home Screen Widget and Control Center toggle;
- App Intents, Siri Shortcuts, and configuration deep links;
- Russian and English UI;
- loopback fallback when Packet Tunnel is unavailable.

---

## 🧬 Credits

- [Flowseal/tg-ws-proxy](https://github.com/Flowseal/tg-ws-proxy) — original project and concept;
- [amurcanov/tg-ws-proxy-android](https://github.com/amurcanov/tg-ws-proxy-android) — Rust core and upstream fork;
- [Flowseal/tg-ws-proxy issue #389](https://github.com/Flowseal/tg-ws-proxy/issues/389) — FAQ and discussion;
- [IMDelewer/tg-ws-proxy-ios](https://github.com/IMDelewer/tg-ws-proxy-ios) — iOS application, Apple framework integrations, and build tooling.

The Rust source is included as a git submodule under `vendor/tg-ws-proxy-android`. Only the `src/*.rs` files, `Cargo.toml`, and `Cargo.lock` are used. iOS-specific changes are applied through `scripts/patches/ios-ffi.patch`.

---

## 📦 Installation variants

| Variant | Bundle ID | Background operation |
| :--- | :--- | :--- |
| AltStore / SideStore | `com.delewer.tgwsproxy.altstore` | depends on available entitlements |
| Sideload / iLoader / TrollStore | `com.delewer.tgwsproxy.sideload` | Packet Tunnel with a compatible signature |
| LiveContainer | `com.delewer.tgwsproxy.lc` | foreground guest process only |
| Simulator | `com.delewer.tgwsproxy.sim` | automatic loopback fallback |

A regular iOS application cannot remain active forever in the background. Persistent operation requires `PacketTunnelProvider`, which iOS runs separately from the application UI.

With a free Apple ID, profiles expire after seven days. AltStore may refresh them while AltServer is reachable, but it cannot add missing Network Extension or App Groups entitlements. LiveContainer cannot register embedded app extensions.

---

## 🚀 Build

```bash
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
./build.sh -p sim --install
./build.sh -p sim -c wd,la,cc,vpn --install
./build.sh -p side -c wd,la,cc,vpn
./build.sh -p alt
./build.sh -p lc
```

Platforms are `sim`, `side`, `alt`, and `lc`.

Components:

| Code | Component |
| :---: | :--- |
| `wd` | Home Screen Widget |
| `la` | Live Activity and Dynamic Island |
| `cc` | Control Center toggle on iOS 18+ |
| `vpn` | Packet Tunnel / Network Extension |
| `none` | application only |

---

## 🔗 Deep links

```text
tgwsproxy://?action=start
tgwsproxy://?action=stop
tgwsproxy://?action=update_cf_link
tgwsproxy://?action=show_cf_domains
tgwsproxy://?action=add_cf_domain&domain=worker.example.com
tgwsproxy://?action=clear_cf_domain
tgwsproxy://?action=config&addr=127.0.0.1&port=1443&pool=4&cf_proxy=true&start=true
```

---

## 🔄 Upstream automation

Initialize the submodule:

```bash
git submodule update --init
```

Sync the Rust wrapper to the current submodule commit:

```bash
./scripts/sync-rust-upstream.sh
cargo check --manifest-path src-wrapper/Cargo.toml --locked
```

---

## 📚 Documentation

- [Architecture and how it works (Russian)](ARCHITECTURE.ru.md)

---

## 🗂 Structure

```text
ios/TgWsProxy/App/       app lifecycle, settings, deep links
ios/TgWsProxy/Logs/      log capture and export
ios/TgWsProxy/Proxy/     engines, FFI, ActivityKit, intents
ios/TgWsProxy/UI/        SwiftUI and Liquid Glass
ios/PacketTunnel/        Network Extension
ios/StatusWidgets/       widgets, Live Activity, Control Center
src-wrapper/             Rust working copy (upstream + iOS patch)
vendor/tg-ws-proxy-android/  upstream Rust repository (submodule)
scripts/patches/         reproducible iOS FFI patch
```

---

## ⚖️ Licenses

The combined project and Rust fork are distributed under [GPLv3](../LICENSE). The original Flowseal project contains MIT-licensed work; its license is included as [LICENSE-flowseal](../LICENSE-flowseal).

---

<p align="center">
  Powered by <a href="https://github.com/Flowseal/tg-ws-proxy">Flowseal/tg-ws-proxy</a>
  and <a href="https://github.com/amurcanov/tg-ws-proxy-android">amurcanov/tg-ws-proxy-android</a>
</p>
