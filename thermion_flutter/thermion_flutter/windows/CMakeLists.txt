cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "thermion_flutter")
project(${PROJECT_NAME} LANGUAGES C CXX)

cmake_policy(VERSION 3.14...3.25)

set(PLUGIN_NAME "thermion_flutter_plugin")

list(APPEND PLUGIN_SOURCES
  "thermion_flutter_plugin.cpp"
  "thermion_flutter_plugin.h"
  "flutter_d3d_texture.cpp"
  "include/dart/dart_api_dl.c"
)

add_library(${PLUGIN_NAME} SHARED
  "include/thermion_flutter/thermion_flutter_plugin_c_api.h"
  "thermion_flutter_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_features(${PLUGIN_NAME} PUBLIC cxx_std_20)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

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
    )
  endif()
endif()

if(NOT DART_PKG_HEADERS)
  message(FATAL_ERROR "thermion_flutter: cannot locate thermion_dart headers. "
    "Ensure the build hook has run or thermion_dart is a sibling package.")
endif()

target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  "${CMAKE_CURRENT_SOURCE_DIR}"
  ${DART_PKG_HEADERS}
)

target_link_directories(${PLUGIN_NAME} PRIVATE ${runner_BINARY_DIR}/../../../native_assets/windows/)

target_link_libraries(${PLUGIN_NAME} PRIVATE 
 flutter
 flutter_wrapper_plugin 
 Shlwapi
 thermion_dart
)

set(thermion_flutter_bundled_libraries
  ${runner_BINARY_DIR}/../../../native_assets/windows/thermion_dart.dll
  ${runner_BINARY_DIR}/../../../native_assets/windows/thermion_dart.lib
  PARENT_SCOPE
)

add_definitions(-DTHERMION_WIN32_KHR_BUILD=1)


