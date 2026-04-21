use serde_json::json;
#[cfg(any(target_os = "windows", target_os = "linux", target_os = "macos"))]
use sysproxy::Sysproxy;

// #[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
// pub fn greet(name: String) -> String {
//     format!("Hello, {name}!")
// }

#[flutter_rust_bridge::frb(sync)]
pub fn get_system_proxy_json() -> String {
    #[cfg(any(target_os = "windows", target_os = "linux", target_os = "macos"))]
    {
        match Sysproxy::get_system_proxy() {
            Ok(proxy) => json!({
                "enable": proxy.enable,
                "host": proxy.host,
                "port": proxy.port,
                "bypass": proxy.bypass,
            })
            .to_string(),
            Err(_) => json!({
                "enable": false,
                "host": "",
                "port": 0,
                "bypass": "",
            })
            .to_string(),
        }
    }

    #[cfg(not(any(target_os = "windows", target_os = "linux", target_os = "macos")))]
    {
        json!({
            "enable": false,
            "host": "",
            "port": 0,
            "bypass": "",
        })
        .to_string()
    }
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
