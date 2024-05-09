#pragma once
#include <string>

#include "flutter/generated_plugin_registrant.h"
#include <gst/gst.h>
#include <map>

class Gstreamer
{
public:
  Gstreamer();
  ~Gstreamer();

  void set_current(const std::string &url);
  void set_next(const std::string &url);
  void play();
  void pause();
  void seek(int milliseconds);

  int get_position_ms();

  FlEventChannel *event_channel = nullptr;

private:
  GstElement *playbin;
  GstBus *bus;
  std::string current_url = "";
  std::string loaded_url = "";
  std::string next_url = "";
  bool is_live = false;
  bool is_loading = false;
  bool should_play = false;
  bool seeking = false;
  bool url_changed = false;

  static gboolean cb_message(GstBus *bus, GstMessage *msg, Gstreamer *data);
  static void cb_about_to_finish(GstElement *element, Gstreamer *data);
};