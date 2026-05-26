/// Kodair Pro — Multi-Engine Browser
///
/// The browser with the most browser engines ever integrated.
/// Each engine implements the `EngineBackend` trait.

pub mod engine;

use engine::{EngineId, EngineRegistry};
use tao::event::{Event, WindowEvent};
use tao::event_loop::{ControlFlow, EventLoop};
use tao::window::WindowBuilder;
use wry::WebViewBuilder;

fn main() {
    tracing_subscriber::fmt::init();
    tracing::info!("Kodair Pro v0.1.0 — Multi-Engine Browser");

    // Show available engines
    let registry = EngineRegistry::new();
    tracing::info!("Available engines: {}", registry.engine_count());
    for info in registry.list_engines() {
        let tier_label = match info.tier {
            engine::EngineTier::Native => "NATIVE",
            engine::EngineTier::System => "SYSTEM",
            engine::EngineTier::Emulated => "emulated",
        };
        tracing::info!("  [{tier_label}] {} — {}", info.display_name, info.engine_name);
    }

    // Build the window
    let event_loop = EventLoop::new();
    let window = WindowBuilder::new()
        .with_title("Kodair Pro — Multi-Engine Browser")
        .with_inner_size(tao::dpi::LogicalSize::new(1280.0, 800.0))
        .build(&event_loop)
        .expect("Failed to create window");

    // Start with the system WebView engine (most compatible)
    let active_engine = EngineId::SystemWebView;
    let profile = registry.get_profile(&active_engine);
    tracing::info!("Starting with engine: {}", profile.display_name);

    // Build wry WebView with the active engine's user agent
    let _webview = WebViewBuilder::new()
        .with_url("https://kodair.us/Welcome/Welcome.html")
        .with_user_agent(&profile.user_agent)
        .with_devtools(true)
        .build(&window)
        .expect("Failed to create WebView");

    tracing::info!("Kodair Pro is running!");

    // Event loop
    event_loop.run(move |event, _, control_flow| {
        *control_flow = ControlFlow::Wait;

        match event {
            Event::WindowEvent {
                event: WindowEvent::CloseRequested,
                ..
            } => *control_flow = ControlFlow::Exit,
            _ => {}
        }
    });
}
