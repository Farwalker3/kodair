/// All 17 engine profiles with plain consumer-friendly names.
///
/// Chrome, Firefox, Safari, Tor are listed first (top browsers).

use super::{EngineId, EngineProfile, EngineTier, ExtensionStore};

pub fn all_profiles() -> Vec<EngineProfile> {
    vec![
        // ═══════════════════════════════════════════════════════════
        // TOP BROWSERS (most familiar to users)
        // ═══════════════════════════════════════════════════════════

        EngineProfile {
            id: EngineId::Chrome,
            display_name: "Chrome",
            engine_name: "Blink / Chromium (CEF)",
            description: "Google Chrome — the world's most popular browser engine. \
                Powers Chrome, Edge, Opera, Vivaldi, and Brave.",
            user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 \
                (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36".into(),
            tier: EngineTier::Native,
            extension_stores: vec![
                ExtensionStore { name: "Chrome Web Store", url: "https://chromewebstore.google.com" },
                ExtensionStore { name: "Edge Add-ons", url: "https://microsoftedge.microsoft.com/addons" },
            ],
            is_legacy: false,
        },

        EngineProfile {
            id: EngineId::Firefox,
            display_name: "Firefox",
            engine_name: "Gecko (libxul)",
            description: "Mozilla Firefox — privacy-focused, open-source engine. \
                Independent from Chromium.",
            user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:138.0) \
                Gecko/20100101 Firefox/138.0".into(),
            tier: EngineTier::Native,
            extension_stores: vec![
                ExtensionStore { name: "Firefox Add-ons", url: "https://addons.mozilla.org" },
            ],
            is_legacy: false,
        },

        EngineProfile {
            id: EngineId::Safari,
            display_name: "Safari",
            engine_name: "WebKit",
            description: "Apple Safari — powers all iOS browsers and macOS Safari. \
                Known for energy efficiency.",
            user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 \
                (KHTML, like Gecko) Version/18.4 Safari/605.1.15".into(),
            tier: EngineTier::Emulated,
            extension_stores: vec![],
            is_legacy: false,
        },

        EngineProfile {
            id: EngineId::Tor,
            display_name: "Tor",
            engine_name: "Gecko + Tor Network",
            description: "Tor Browser — maximum privacy via onion routing. \
                Access .onion sites. Routes through SOCKS5 proxy.",
            user_agent: "Mozilla/5.0 (Windows NT 10.0; rv:128.0) \
                Gecko/20100101 Firefox/128.0".into(),
            tier: EngineTier::Emulated,
            extension_stores: vec![
                ExtensionStore { name: "Firefox Add-ons", url: "https://addons.mozilla.org" },
            ],
            is_legacy: false,
        },

        // ═══════════════════════════════════════════════════════════
        // NATIVE / SYSTEM ENGINES
        // ═══════════════════════════════════════════════════════════

        EngineProfile {
            id: EngineId::Servo,
            display_name: "Servo",
            engine_name: "Servo (Rust)",
            description: "Servo — experimental engine written in Rust. \
                Memory safe, GPU-accelerated. Passes 1.8M+ web tests.",
            user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Servo/0.1".into(),
            tier: EngineTier::Native,
            extension_stores: vec![],
            is_legacy: false,
        },

        EngineProfile {
            id: EngineId::SystemWebView,
            display_name: "System WebView",
            engine_name: "WebView2 / WebKitGTK",
            description: "Uses the operating system's built-in WebView. \
                WebView2 on Windows, WebKitGTK on Linux, WKWebView on macOS.",
            user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 \
                (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0".into(),
            tier: EngineTier::System,
            extension_stores: vec![
                ExtensionStore { name: "Edge Add-ons", url: "https://microsoftedge.microsoft.com/addons" },
            ],
            is_legacy: false,
        },

        EngineProfile {
            id: EngineId::Edge,
            display_name: "Edge",
            engine_name: "Blink / WebView2",
            description: "Microsoft Edge — Chromium-based with Microsoft integrations. \
                Default Windows browser.",
            user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 \
                (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 Edg/136.0.0.0".into(),
            tier: EngineTier::Emulated,
            extension_stores: vec![
                ExtensionStore { name: "Edge Add-ons", url: "https://microsoftedge.microsoft.com/addons" },
                ExtensionStore { name: "Chrome Web Store", url: "https://chromewebstore.google.com" },
            ],
            is_legacy: false,
        },

        EngineProfile {
            id: EngineId::InternetExplorer,
            display_name: "Internet Explorer",
            engine_name: "Trident (MSHTML)",
            description: "Internet Explorer — Microsoft's legacy engine. \
                Available via MSHTML COM on Windows for compatibility testing.",
            user_agent: "Mozilla/5.0 (Windows NT 10.0; WOW64; Trident/7.0; rv:11.0) \
                like Gecko".into(),
            tier: EngineTier::System,
            extension_stores: vec![],
            is_legacy: false,
        },

        #[cfg(target_os = "linux")]
        EngineProfile {
            id: EngineId::WebKitGTK,
            display_name: "WebKitGTK",
            engine_name: "WebKit (GTK)",
            description: "WebKitGTK — the WebKit engine for Linux/GNOME. \
                Native GTK widget rendering.",
            user_agent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/605.1.15 \
                (KHTML, like Gecko) Version/18.0 Safari/605.1.15".into(),
            tier: EngineTier::System,
            extension_stores: vec![],
            is_legacy: false,
        },

        // ═══════════════════════════════════════════════════════════
        // ALTERNATIVE / NICHE ENGINES
        // ═══════════════════════════════════════════════════════════

        EngineProfile {
            id: EngineId::PaleMoon,
            display_name: "Pale Moon",
            engine_name: "Goanna",
            description: "Pale Moon — Gecko fork focused on customization. \
                Independent rendering engine since 2016.",
            user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:33.5) \
                Gecko/20100101 Goanna/6.8 Firefox/68.0 PaleMoon/33.5.0".into(),
            tier: EngineTier::Emulated,
            extension_stores: vec![
                ExtensionStore { name: "Pale Moon Add-ons", url: "https://addons.palemoon.org" },
            ],
            is_legacy: false,
        },

        EngineProfile {
            id: EngineId::Ladybird,
            display_name: "Ladybird",
            engine_name: "LibWeb",
            description: "Ladybird — independent engine from SerenityOS. \
                Built from scratch, now transitioning to Rust. Alpha in 2026.",
            user_agent: "Mozilla/5.0 (Windows NT 10.0; x64) LibWeb+LibJS/1.0 Ladybird/1.0".into(),
            tier: EngineTier::Emulated,
            extension_stores: vec![],
            is_legacy: false,
        },

        EngineProfile {
            id: EngineId::NetSurf,
            display_name: "NetSurf",
            engine_name: "NetSurf",
            description: "NetSurf — ultra-lightweight C engine. Under 1 MB. \
                For embedded and low-resource systems.",
            user_agent: "NetSurf/3.11 (Windows; x86_64)".into(),
            tier: EngineTier::Emulated,
            extension_stores: vec![],
            is_legacy: false,
        },

        // ═══════════════════════════════════════════════════════════
        // LEGACY / DISCONTINUED ENGINES
        // ═══════════════════════════════════════════════════════════

        EngineProfile {
            id: EngineId::OperaClassic,
            display_name: "Opera Classic",
            engine_name: "Presto",
            description: "Opera Classic (pre-2013) — the Presto engine. \
                Pioneered tabs, speed dial, and mouse gestures.",
            user_agent: "Opera/9.80 (Windows NT 10.0; U; Edition Campaign 21) \
                Presto/2.12.388 Version/12.18".into(),
            tier: EngineTier::Emulated,
            extension_stores: vec![],
            is_legacy: true,
        },

        EngineProfile {
            id: EngineId::LegacyEdge,
            display_name: "Edge Legacy",
            engine_name: "EdgeHTML",
            description: "Microsoft Edge Legacy — the original Edge before \
                switching to Chromium in 2020. Discontinued.",
            user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 \
                (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36 Edge/18.19041".into(),
            tier: EngineTier::Emulated,
            extension_stores: vec![],
            is_legacy: true,
        },

        EngineProfile {
            id: EngineId::Dillo,
            display_name: "Dillo",
            engine_name: "Dillo",
            description: "Dillo — extremely minimal C browser. Under 1 MB. \
                For the most constrained environments.",
            user_agent: "Dillo/3.1".into(),
            tier: EngineTier::Emulated,
            extension_stores: vec![],
            is_legacy: true,
        },

        EngineProfile {
            id: EngineId::Flow,
            display_name: "Flow",
            engine_name: "Ekioh Flow",
            description: "Flow by Ekioh — GPU-first engine for smart TVs \
                and embedded devices. Multi-threaded rendering.",
            user_agent: "Mozilla/5.0 (Smart TV; Linux) Flow/1.0".into(),
            tier: EngineTier::Emulated,
            extension_stores: vec![],
            is_legacy: true,
        },

        EngineProfile {
            id: EngineId::Konqueror,
            display_name: "Konqueror",
            engine_name: "KHTML",
            description: "Konqueror / KHTML — KDE's engine, ancestor of \
                both WebKit and Blink. Discontinued in 2023.",
            user_agent: "Mozilla/5.0 (compatible; Konqueror/4.14; Linux) KHTML/4.14.3 \
                (like Gecko)".into(),
            tier: EngineTier::Emulated,
            extension_stores: vec![],
            is_legacy: true,
        },
    ]
}
