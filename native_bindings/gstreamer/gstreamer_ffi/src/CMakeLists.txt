# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(gstreamer_ffi_library VERSION 0.0.1 LANGUAGES C)

find_package(PkgConfig REQUIRED)
pkg_search_module(GST REQUIRED gstreamer-1.0)
include_directories(${GST_INCLUDE_DIRS})

IF(WIN32)
  find_program(CMAKE_PKGCONFIG_EXECUTABLE pkg-config)
  IF(CMAKE_PKGCONFIG_EXECUTABLE)
    # pkg-config.exe gstreamer-1.0 --libs --msvc-syntax
    execute_process(COMMAND ${CMAKE_PKGCONFIG_EXECUTABLE} --libs --msvc-syntax gstreamer-1.0 OUTPUT_VARIABLE GST_LDFLAGS RESULT_VARIABLE result OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(REPLACE "\\ " "%%%" GST_LDFLAGS ${GST_LDFLAGS})
    string(REPLACE " " "$$$" GST_LDFLAGS ${GST_LDFLAGS})
    string(REPLACE "%%%" " " GST_LDFLAGS ${GST_LDFLAGS})
    string(REPLACE "$$$" ";" GST_LDFLAGS ${GST_LDFLAGS})
  ENDIF()
ENDIF()

add_library(gstreamer_ffi SHARED
  "gstreamer_ffi.c"
  ${APPENDED_SOURCE}
)

IF(WIN32)
  target_link_options(gstreamer_ffi PRIVATE ${GST_LDFLAGS})
ELSE()
  target_link_libraries(gstreamer_ffi PRIVATE ${GST_LDFLAGS} ${LINK_LIBS})
ENDIF()

set_target_properties(gstreamer_ffi PROPERTIES
  PUBLIC_HEADER gstreamer_ffi.h
  OUTPUT_NAME "gstreamer_ffi"
)

target_compile_definitions(gstreamer_ffi PUBLIC DART_SHARED_LIB)
