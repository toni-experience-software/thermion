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

set(GENERATED_HEADERS_CMAKE "${CMAKE_CURRENT_SOURCE_DIR}/../.dart_tool/generated_headers.cmake")
include("${GENERATED_HEADERS_CMAKE}" OPTIONAL)

if(NOT DART_PKG_HEADERS)
  # Fallback: find thermion_dart via the app's package_config.json
  get_filename_component(_APP_ROOT "${CMAKE_SOURCE_DIR}/.." ABSOLUTE)
  set(_PKG_CONFIG "${_APP_ROOT}/.dart_tool/package_config.json")
  if(EXISTS "${_PKG_CONFIG}")
    file(READ "${_PKG_CONFIG}" _PKG_CONFIG_CONTENT)
    # Flatten JSON for reliable regex matching
    string(REGEX REPLACE "[ \t\r\n]+" "" _PKG_CONFIG_FLAT "${_PKG_CONFIG_CONTENT}")
    string(REGEX MATCH "\"name\":\"thermion_dart\",\"rootUri\":\"([^\"]+)\"" _MATCH1 "${_PKG_CONFIG_FLAT}")
    set(_THERMION_DART_URI "${CMAKE_MATCH_1}")
    if(NOT _THERMION_DART_URI)
      string(REGEX MATCH "\"rootUri\":\"([^\"]+)\",\"packageUri\":\"lib/\",\"languageVersion\":[^,}]+,\"name\":\"thermion_dart\"" _MATCH2 "${_PKG_CONFIG_FLAT}")
      set(_THERMION_DART_URI "${CMAKE_MATCH_1}")
    endif()
    if(_THERMION_DART_URI)
      if(_THERMION_DART_URI MATCHES "^\\.\\.?/")
        get_filename_component(_THERMION_DART_ROOT "${_APP_ROOT}/.dart_tool/${_THERMION_DART_URI}" ABSOLUTE)
      elseif(_THERMION_DART_URI MATCHES "^file:///([A-Za-z]:.*)")
        set(_THERMION_DART_ROOT "${CMAKE_MATCH_1}")
        file(TO_CMAKE_PATH "${_THERMION_DART_ROOT}" _THERMION_DART_ROOT)
      elseif(_THERMION_DART_URI MATCHES "^file:///(.*)")
        set(_THERMION_DART_ROOT "/${CMAKE_MATCH_1}")
      else()
        set(_THERMION_DART_ROOT "${_THERMION_DART_URI}")
      endif()
      set(DART_PKG_HEADERS
        "${_THERMION_DART_ROOT}/native/include"
        "${_THERMION_DART_ROOT}/native/include/filament"
        "${_THERMION_DART_ROOT}/native/include/filament/release"
      )
      message(STATUS "thermion_flutter: resolved thermion_dart headers from ${_THERMION_DART_ROOT}")
    else()
      message(WARNING "thermion_flutter: could not find thermion_dart in package_config.json; DART_PKG_HEADERS will be empty")
    endif()
  else()
    message(WARNING "thermion_flutter: package_config.json not found at ${_PKG_CONFIG}; run 'flutter pub get' first")
  endif()
endif()

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${DART_PKG_HEADERS}"
)

include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${DART_PKG_HEADERS}"
)

get_cmake_property(_variableNames VARIABLES)
list (SORT _variableNames)
foreach (_variableName ${_variableNames})
    message(STATUS "${_variableName}=${${_variableName}}")
endforeach()

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


