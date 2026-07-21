#include "include/proxy_getter/proxy_getter_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
#include <map>

void ProxyGetterPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  proxy_getter::ProxyGetterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

namespace proxy_getter {

// static
void ProxyGetterPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "proxy_getter/system_proxy",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<ProxyGetterPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

ProxyGetterPlugin::ProxyGetterPlugin() {}

ProxyGetterPlugin::~ProxyGetterPlugin() {}

// Helper to read DWORD
bool ReadRegistryDword(HKEY hKeyParent, const std::wstring& subKey, const std::wstring& valueName, DWORD& outValue) {
    HKEY hKey;
    if (RegOpenKeyExW(hKeyParent, subKey.c_str(), 0, KEY_READ, &hKey) != ERROR_SUCCESS) {
        return false;
    }
    DWORD type = REG_DWORD;
    DWORD size = sizeof(DWORD);
    LSTATUS status = RegQueryValueExW(hKey, valueName.c_str(), nullptr, &type, reinterpret_cast<LPBYTE>(&outValue), &size);
    RegCloseKey(hKey);
    return status == ERROR_SUCCESS && type == REG_DWORD;
}

// Helper to read String
std::wstring ReadRegistryString(HKEY hKeyParent, const std::wstring& subKey, const std::wstring& valueName) {
    HKEY hKey;
    if (RegOpenKeyExW(hKeyParent, subKey.c_str(), 0, KEY_READ, &hKey) != ERROR_SUCCESS) {
        return L"";
    }
    DWORD type = REG_SZ;
    DWORD size = 0;
    // first query size
    LSTATUS status = RegQueryValueExW(hKey, valueName.c_str(), nullptr, &type, nullptr, &size);
    if (status != ERROR_SUCCESS) {
        RegCloseKey(hKey);
        return L"";
    }
    std::wstring result;
    result.resize(size / sizeof(wchar_t));
    status = RegQueryValueExW(hKey, valueName.c_str(), nullptr, &type, reinterpret_cast<LPBYTE>(&result[0]), &size);
    RegCloseKey(hKey);
    // remove null terminator if present
    while (!result.empty() && result.back() == L'\0') {
        result.pop_back();
    }
    return result;
}

std::string WideToUtf8(const std::wstring& wstr) {
    if (wstr.empty()) return std::string();
    int size_needed = WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), NULL, 0, NULL, NULL);
    std::string strTo(size_needed, 0);
    WideCharToMultiByte(CP_UTF8, 0, &wstr[0], (int)wstr.size(), &strTo[0], size_needed, NULL, NULL);
    return strTo;
}

void ProxyGetterPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getSystemProxy") == 0) {
    const std::wstring subKey = L"Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings";
    DWORD proxyEnable = 0;
    bool enabled = false;
    std::string host = "";
    int port = 0;
    std::string bypass = "";

    if (ReadRegistryDword(HKEY_CURRENT_USER, subKey, L"ProxyEnable", proxyEnable)) {
        enabled = (proxyEnable != 0);
    }

    std::wstring server_w = ReadRegistryString(HKEY_CURRENT_USER, subKey, L"ProxyServer");
    std::string server = WideToUtf8(server_w);

    std::wstring bypass_w = ReadRegistryString(HKEY_CURRENT_USER, subKey, L"ProxyOverride");
    bypass = WideToUtf8(bypass_w);

    // Parse server (e.g., "127.0.0.1:8080" or "http=127.0.0.1:8080;https=127.0.0.1:8080")
    if (!server.empty()) {
        std::string target_proxy = server;
        size_t http_pos = server.find("http=");
        if (http_pos != std::string::npos) {
            size_t end_pos = server.find(";", http_pos);
            target_proxy = server.substr(http_pos + 5, end_pos == std::string::npos ? std::string::npos : end_pos - (http_pos + 5));
        } else {
            size_t socks_pos = server.find("socks=");
            if (socks_pos != std::string::npos) {
                size_t end_pos = server.find(";", socks_pos);
                target_proxy = server.substr(socks_pos + 6, end_pos == std::string::npos ? std::string::npos : end_pos - (socks_pos + 6));
            }
        }

        size_t colon_pos = target_proxy.find(":");
        if (colon_pos != std::string::npos) {
            host = target_proxy.substr(0, colon_pos);
            try {
                port = std::stoi(target_proxy.substr(colon_pos + 1));
            } catch (...) {
                port = 0;
            }
        } else {
            host = target_proxy;
            port = 80;
        }
    }

    flutter::EncodableMap response;
    response[flutter::EncodableValue("enable")] = flutter::EncodableValue(enabled);
    response[flutter::EncodableValue("host")] = flutter::EncodableValue(host);
    response[flutter::EncodableValue("port")] = flutter::EncodableValue(port);
    response[flutter::EncodableValue("bypass")] = flutter::EncodableValue(bypass);

    result->Success(flutter::EncodableValue(response));
  } else {
    result->NotImplemented();
  }
}

}  // namespace proxy_getter
