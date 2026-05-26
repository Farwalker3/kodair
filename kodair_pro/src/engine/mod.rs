/// Engine module — defines all 15 browser engines.
///
/// Tier 1 (Native):   Engines that render pages natively in-process
/// Tier 2 (System):   Engines that use platform APIs (COM, GTK)
/// Tier 3 (Emulated): Legacy/discontinued engines via UA string emulation

pub mod profiles;

use std::path::Path;

/// Unique identifier for each engine.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum EngineId {
    // Tier 1 — Native rendering
    Servo,          // Rust-native engine (servo crate)
    Chrome,         // Blink via CEF (cef-rs)
    SystemWebView,  // Platform WebView via wry (WebView2/WebKit)
    Firefox,        // Gecko via libxul FFI

    // Tier 2 — System-level
    InternetExplorer, // Trident via MSHTML COM (Windows)
    WebKitGTK,        // WebKitGTK widget (Linux)

    // Tier 3 — UA-emulated
    Safari,        // WebKit UA on system WebView
    Tor,           // Firefox UA + SOCKS5 proxy
    Edge,          // Edge UA on system WebView
    PaleMoon,      // Goanna UA (Gecko fork)
    OperaClassic,  // Presto UA (legacy)
    LegacyEdge,    // EdgeHTML UA (legacy)
    NetSurf,       // NetSurf UA
    Ladybird,      // LibWeb UA
    Dillo,         // Dillo UA
    Flow,          // Ekioh Flow UA
    Konqueror,     // KHTML UA
}

/// Rendering tier — how this engine actually works.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EngineTier {
    /// Actually renders pages via an embedded engine binary
    Native,
    /// Uses a platform/system API to render
    System,
    /// Uses UA string emulation on top of another engine
    Emulated,
}

/// Static info about a browser engine.
#[derive(Debug, Clone)]
pub struct EngineProfile {
    pub id: EngineId,
    pub display_name: &'static str,
    pub engine_name: &'static str,
    pub description: &'static str,
    pub user_agent: String,
    pub tier: EngineTier,
    pub extension_stores: Vec<ExtensionStore>,
    pub is_legacy: bool,
}

/// An extension store compatible with a given engine.
#[derive(Debug, Clone)]
pub struct ExtensionStore {
    pub name: &'static str,
    pub url: &'static str,
}

/// Error type for engine operations.
#[derive(Debug)]
pub enum EngineError {
    NotSupported(String),
    LoadFailed(String),
    NavigationFailed(String),
}

impl std::fmt::Display for EngineError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            EngineError::NotSupported(msg) => write!(f, "Not supported: {msg}"),
            EngineError::LoadFailed(msg) => write!(f, "Load failed: {msg}"),
            EngineError::NavigationFailed(msg) => write!(f, "Navigation failed: {msg}"),
        }
    }
}

/// Trait that every engine backend implements.
pub trait EngineBackend {
    fn id(&self) -> EngineId;
    fn name(&self) -> &str;
    fn user_agent(&self) -> &str;
    fn tier(&self) -> EngineTier;
    fn supports_extensions(&self) -> bool;

    fn navigate(&mut self, url: &str) -> Result<(), EngineError>;
    fn go_back(&mut self) -> Result<(), EngineError>;
    fn go_forward(&mut self) -> Result<(), EngineError>;
    fn reload(&mut self) -> Result<(), EngineError>;
    fn get_title(&self) -> String;
    fn get_url(&self) -> String;
    fn execute_js(&mut self, script: &str) -> Result<String, EngineError>;
    fn load_extension(&mut self, _path: &Path) -> Result<(), EngineError> {
        Err(EngineError::NotSupported(format!(
            "{} does not support extensions",
            self.name()
        )))
    }
}

/// Registry of all available engines.
pub struct EngineRegistry {
    profiles: Vec<EngineProfile>,
}

impl EngineRegistry {
    pub fn new() -> Self {
        Self {
            profiles: profiles::all_profiles(),
        }
    }

    pub fn engine_count(&self) -> usize {
        self.profiles.len()
    }

    pub fn list_engines(&self) -> &[EngineProfile] {
        &self.profiles
    }

    pub fn get_profile(&self, id: &EngineId) -> &EngineProfile {
        self.profiles
            .iter()
            .find(|p| p.id == *id)
            .unwrap_or(&self.profiles[0])
    }

    pub fn active_engines(&self) -> Vec<&EngineProfile> {
        self.profiles.iter().filter(|p| !p.is_legacy).collect()
    }

    pub fn legacy_engines(&self) -> Vec<&EngineProfile> {
        self.profiles.iter().filter(|p| p.is_legacy).collect()
    }

    pub fn native_engines(&self) -> Vec<&EngineProfile> {
        self.profiles
            .iter()
            .filter(|p| p.tier == EngineTier::Native)
            .collect()
    }
}
