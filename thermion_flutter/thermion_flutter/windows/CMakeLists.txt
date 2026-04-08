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

# Fallback: resolve thermion_dart root from the consuming app's package_config.json.
# CMAKE_SOURCE_DIR is <app>/windows/; package_config.json is at <app>/.dart_tool/.
if(NOT DART_PKG_HEADERS)
  set(_APP_ROOT "${CMAKE_SOURCE_DIR}/..")
  set(_PKG_CONFIG "${_APP_ROOT}/.dart_tool/package_config.json")
  if(EXISTS "${_PKG_CONFIG}")
    file(READ "${_PKG_CONFIG}" _PKG_JSON)
    string(REGEX MATCH "\"name\":[ ]*\"thermion_dart\"[^}]*\"rootUri\":[ ]*\"([^\"]+)\"" _ "${_PKG_JSON}")
    if(CMAKE_MATCH_1)
      set(_URI "${CMAKE_MATCH_1}")
      # Convert file:// URI to filesystem path.
      # file:///C:/path → /C:/path after stripping file://, then strip leading / before drive letter.
      string(REGEX REPLACE "^file://" "" _URI "${_URI}")
      string(REGEX REPLACE "^/([A-Za-z]:)" "\\1" _URI "${_URI}")
      if(NOT IS_ABSOLUTE "${_URI}")
        get_filename_component(_URI "${_APP_ROOT}/.dart_tool/${_URI}" ABSOLUTE)
      endif()
      message(STATUS "thermion_flutter: resolved thermion_dart root: ${_URI}")
      if(IS_DIRECTORY "${_URI}/native/include")
        set(DART_PKG_HEADERS
          "${_URI}/native/include"
          "${_URI}/native/include/filament"
          "$<IF:$<CONFIG:Debug>,${_URI}/native/include/filament/debug,${_URI}/native/include/filament/release>"
        )
      else()
        message(STATUS "thermion_flutter: ${_URI}/native/include does not exist")
      endif()
    else()
      message(STATUS "thermion_flutter: thermion_dart not found in ${_PKG_CONFIG}")
    endif()
  else()
    message(STATUS "thermion_flutter: ${_PKG_CONFIG} not found")
  endif()
endif()

if(NOT DART_PKG_HEADERS)
  message(FATAL_ERROR "thermion_flutter: cannot locate thermion_dart headers. "
    "Ensure the build hook has run or thermion_dart is listed in package_config.json.")
endif()

# Public header dir must be INTERFACE so the runner can find
# thermion_flutter/thermion_flutter_plugin_c_api.h.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
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


