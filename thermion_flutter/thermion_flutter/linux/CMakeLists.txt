cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "thermion_flutter")
project(${PROJECT_NAME} LANGUAGES C CXX)
set(PLUGIN_NAME "thermion_flutter_plugin")

add_library(${PLUGIN_NAME} SHARED
  "thermion_flutter_plugin.cc"
  "egl_texture.cc"
)

find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

set_target_properties(${PLUGIN_NAME} PROPERTIES CXX_VISIBILITY_PRESET hidden)
target_compile_features(${PLUGIN_NAME} PUBLIC cxx_std_17)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  "/usr/include/gtk-3.0"
  )

# thermion_dart native-assets output
# Flutter places native-assets at: <project>/build/native_assets/linux/
# CMake build dir is: <project>/build/linux/x64/{release,debug}/
# So relative path from CMAKE_BINARY_DIR is ../../../native_assets/linux/
set(NATIVE_ASSETS_DIR "${CMAKE_BINARY_DIR}/../../../native_assets/linux")

# Prefer hook-generated headers when available.
set(GENERATED_HEADERS_CMAKE "${CMAKE_CURRENT_SOURCE_DIR}/../.dart_tool/generated_headers.cmake")
if(EXISTS "${GENERATED_HEADERS_CMAKE}")
  include("${GENERATED_HEADERS_CMAKE}")
endif()

# Fallback: derive from monorepo sibling layout.
if(NOT DART_PKG_HEADERS)
  get_filename_component(_THERMION_DART
    "${CMAKE_CURRENT_SOURCE_DIR}/../../../thermion_dart" ABSOLUTE)
  if(IS_DIRECTORY "${_THERMION_DART}/native/include")
    set(DART_PKG_HEADERS
      "${_THERMION_DART}/native/include"
      "${_THERMION_DART}/native/include/filament"
      "$<IF:$<CONFIG:Debug>,${_THERMION_DART}/native/include/filament/debug,${_THERMION_DART}/native/include/filament/release>"
      "${_THERMION_DART}/native/include/vulkan/linux"
      "${_THERMION_DART}/native/include/opengl/linux"
    )
  endif()
endif()

if(NOT DART_PKG_HEADERS)
  message(FATAL_ERROR "thermion_flutter: cannot locate thermion_dart headers. "
    "Ensure the build hook has run or thermion_dart is a sibling package.")
endif()

target_include_directories(${PLUGIN_NAME} PRIVATE "${NATIVE_ASSETS_DIR}")
target_include_directories(${PLUGIN_NAME} PRIVATE ${DART_PKG_HEADERS})
target_link_directories(${PLUGIN_NAME} PRIVATE "${NATIVE_ASSETS_DIR}")

# thermion_dart.so has unresolved basisu/draco encoder symbols (pulled in by
# --whole-archive on filamat). These code paths are never called at runtime.
# Propagate --allow-shlib-undefined to the executable that links against this plugin.
set_property(TARGET ${PLUGIN_NAME} APPEND PROPERTY
  INTERFACE_LINK_OPTIONS "-Wl,--allow-shlib-undefined")

target_compile_options(${PLUGIN_NAME} PRIVATE -stdlib=libc++)
target_link_options(${PLUGIN_NAME} PRIVATE -nostdlib++ -l:libc++.a -l:libc++abi.a)
target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  PkgConfig::GTK
  thermion_dart
  EGL
  GL
  gbm
)

# List of absolute paths to libraries that should be bundled with the plugin.
set(thermion_flutter_bundled_libraries
  ""
  PARENT_SCOPE
)
