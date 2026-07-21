#ifndef FLUTTER_PLUGIN_PROXY_GETTER_PLUGIN_H_
#define FLUTTER_PLUGIN_PROXY_GETTER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace proxy_getter {

class ProxyGetterPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  ProxyGetterPlugin();

  virtual ~ProxyGetterPlugin();

  // Disallow copy and assign.
  ProxyGetterPlugin(const ProxyGetterPlugin&) = delete;
  ProxyGetterPlugin& operator=(const ProxyGetterPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace proxy_getter

#endif  // FLUTTER_PLUGIN_PROXY_GETTER_PLUGIN_H_
