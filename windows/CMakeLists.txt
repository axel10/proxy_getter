cmake_minimum_required(VERSION 3.14)

set(PLUGIN_NAME "proxy_getter_plugin")

project(${PLUGIN_NAME} LANGUAGES CXX)

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# Define the library target.
add_library(${PLUGIN_NAME} SHARED
  "proxy_getter_plugin.cpp"
  "include/proxy_getter/proxy_getter_plugin.h"
)

# Apply standard build settings.
target_compile_features(${PLUGIN_NAME} PUBLIC cxx_std_17)
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)

target_compile_definitions(${PLUGIN_NAME} PRIVATE "FLUTTER_PLUGIN_IMPL")

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# Add the directory containing the header file to the search path.
target_include_directories(${PLUGIN_NAME} PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

# Copy the plugin DLL to the output directory.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/outputs/plugins/${PLUGIN_NAME}"
)

