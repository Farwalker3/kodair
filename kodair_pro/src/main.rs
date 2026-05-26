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
        .with_url("http://127.0.0.1:8080/")
        .with_user_agent(&profile.user_agent)
        .with_initialization_script(r#"
            (function() {
                // 1. Firefox Extension Click Interceptor
                window.addEventListener('click', function(e) {
                    var target = e.target;
                    var link = target.closest('a');
                    if (link && (link.href.includes('.xpi') || link.textContent.includes('Add to Firefox') || link.classList.contains('AMOmasterkey-button'))) {
                        e.stopImmediatePropagation();
                        e.preventDefault();
                        window.location.href = link.href;
                    }
                }, true);

                // 2. Dynamic Koparty Watch Party Button Injection
                function injectKoparty() {
                    var appBar = document.getElementById('AppBar');
                    if (appBar && !document.getElementById('Koparty/Koparty.html')) {
                        var btn = document.createElement('div');
                        btn.className = 'AppBtn';
                        btn.id = 'Koparty/Koparty.html';
                        btn.onclick = function() { changeApp(this.id); };
                        btn.ondblclick = function() { changeAppUniversal(this.id); };
                        btn.oncontextmenu = function() { toggleSearch(this.id); return false; };
                        btn.style.color = '#ff007f';
                        btn.style.filter = 'drop-shadow(0 0 4px rgba(255, 0, 127, 0.3))';
                        btn.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/></svg>';
                        
                        var lastBtn = appBar.querySelector('[onclick*="toggleAccountsPanel"]');
                        if (lastBtn) {
                            appBar.insertBefore(btn, lastBtn);
                        } else {
                            appBar.appendChild(btn);
                        }
                    }
                }
                
                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', injectKoparty);
                } else {
                    injectKoparty();
                }
                setInterval(injectKoparty, 1000);
            })();
        "#)
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
