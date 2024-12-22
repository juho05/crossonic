# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(gstreamer_ffi_library VERSION 0.0.1 LANGUAGES C)

IF(ANDROID OR __ANDROID__)
  SET(GST_FOLDER ${CMAKE_CURRENT_SOURCE_DIR}/../third-party/gst-android)
  SET(ABI_SUFFIX ${ANDROID_ABI})

  IF(${ANDROID_ABI} STREQUAL "armeabi-v7a")
    SET(ABI_SUFFIX armv7)
  ELSEIF(${ANDROID_ABI} STREQUAL "arm64-v8a")
    SET(ABI_SUFFIX arm64)
  ELSEIF(${ANDROID_ABI} STREQUAL "x86")
    # already correct
  ELSEIF(${ANDROID_ABI} STREQUAL "x86_64")
    # already correct
  ENDIF()

  SET(GST_ROOT ${GST_FOLDER}/${ABI_SUFFIX})
  include_directories(
    ${GST_ROOT}/include/gstreamer-1.0
    ${GST_ROOT}/include/glib-2.0
    ${GST_ROOT}/lib/glib-2.0/include
  )

  link_directories(
    ${GST_ROOT}/lib
    ${GST_ROOT}/lib/gstreamer-1.0
    ${GST_ROOT}/lib/gio/modules
  )

  SET(PLUGINS_DECLARATION)
  SET(PLUGINS_REGISTRATION)
  SET(G_IO_MODULES_DECLARE)
  SET(G_IO_MODULES_LOAD)

  LIST(APPEND GST_PLUGINS coreelements adder app audioconvert audiomixer audiorate audioresample gio volume autodetect opensles ogg vorbis opus audioparsers flac lame wavparse opusparse tcp typefindfunctions insertbin switchbin fallbackswitch threadshare playback soup)
  LIST(APPEND GIO_MODULES openssl)

  LIST(APPEND LINK_LIBS gstreamer-1.0 gobject-2.0 glib-2.0 gio-2.0 harfbuzz ogg vorbis vorbisenc mp3lame opus gstpbutils-1.0 gsttag-1.0 gstriff-1.0 FLAC gstvideo-1.0 gstnet-1.0 gstinsertbin-1.0 gstrtp-1.0 soup-2.4 psl)

  foreach(GST_P ${GST_PLUGINS})
    LIST(APPEND LINK_LIBS "gst${GST_P}")
    LIST(APPEND PLUGINS_DECLARATION "\nGST_PLUGIN_STATIC_DECLARE(${GST_P})")
    LIST(APPEND PLUGINS_REGISTRATION "\nGST_PLUGIN_STATIC_REGISTER(${GST_P})")
  endforeach(GST_P ${GST_PLUGINS})

  foreach(GIO_M ${GIO_MODULES})
    LIST(APPEND LINK_LIBS "gio${GIO_M}")
    LIST(APPEND G_IO_MODULES_DECLARE "\nGST_G_IO_MODULE_DECLARE(${GIO_M})")
    LIST(APPEND G_IO_MODULES_LOAD "\nGST_G_IO_MODULE_LOAD(${GIO_M})")
  endforeach(GST_P ${GST_PLUGINS})

  configure_file(gst_android.c.in ${CMAKE_CURRENT_SOURCE_DIR}/gst_plugin_init_android.c)

  LIST(APPEND APPENDED_SOURCE gst_plugin_init_android.c)
  LIST(APPEND LINK_LIBS intl ffi iconv gmodule-2.0 pcre2-8 gstbase-1.0 gstaudio-1.0 orc-0.4 gstapp-1.0 gio-2.0 log z OpenSLES ssl crypto)

ELSE()
  find_package(PkgConfig REQUIRED)
  pkg_search_module(GST REQUIRED gstreamer-1.0)
  include_directories(${GST_INCLUDE_DIRS})
ENDIF()

add_library(gstreamer_ffi SHARED
  "gstreamer_ffi.c"
  ${APPENDED_SOURCE}
)

target_link_libraries(gstreamer_ffi PRIVATE ${GST_LDFLAGS} ${LINK_LIBS})

set_target_properties(gstreamer_ffi PROPERTIES
  PUBLIC_HEADER gstreamer_ffi.h
  OUTPUT_NAME "gstreamer_ffi"
)

target_compile_definitions(gstreamer_ffi PUBLIC DART_SHARED_LIB)
