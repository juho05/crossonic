#include "gstreamer.h"
#include <iostream>

void Gstreamer::cb_about_to_finish(GstElement *element, Gstreamer *data)
{
  if (data->next_url.length() == 0)
    return;
  g_object_set(GST_OBJECT(data->playbin), "uri", data->next_url.c_str(), NULL);
  data->loaded_url = data->next_url;
  data->next_url = "";
}

gboolean Gstreamer::cb_message(GstBus *bus, GstMessage *msg, Gstreamer *data)
{
  switch (GST_MESSAGE_TYPE(msg))
  {
  case GST_MESSAGE_ERROR:
  {
    GError *err;
    gchar *debug;

    gst_message_parse_error(msg, &err, &debug);
    std::cout << err << "\n"
              << debug << std::endl;
    g_error_free(err);
    g_free(debug);
    break;
  }
  case GST_MESSAGE_STATE_CHANGED:
    GstState old_state, new_state;
    gst_message_parse_state_changed(msg, &old_state, &new_state, NULL);
    if (old_state != new_state)
    {
      const gchar *state;
      switch (new_state)
      {
      case GST_STATE_PAUSED:
        if (data->should_play || data->is_loading)
          return TRUE;
        state = "paused";
        break;
      case GST_STATE_PLAYING:
        state = "playing";
        data->is_loading = false;
        break;
      default:
        if (data->is_loading)
          return TRUE;
        if (data->should_play)
          state = "loading";
        else
          state = "stopped";
        break;
      }
      fl_event_channel_send(data->event_channel, fl_value_new_string(state), nullptr, nullptr);
    }
    break;
  case GST_MESSAGE_EOS:
    if (data->is_loading)
      return TRUE;
    fl_event_channel_send(data->event_channel, fl_value_new_string("stopped"), nullptr, nullptr);
    break;
  case GST_MESSAGE_ASYNC_DONE:
    if (!data->seeking)
      return TRUE;
    data->seeking = false;
    data->is_loading = data->should_play;
    GstState currentState;
    gst_element_get_state(data->playbin, &currentState, nullptr, GST_CLOCK_TIME_NONE);
    const gchar *state;
    switch (currentState)
    {
    case GST_STATE_PAUSED:
      if (data->should_play)
        state = "playing";
      else
        state = "paused";
      break;
    case GST_STATE_PLAYING:
      state = "playing";
      break;
    default:
      if (data->should_play)
        state = "loading";
      else
        state = "stopped";
      break;
    }
    fl_event_channel_send(data->event_channel, fl_value_new_string(state), nullptr, nullptr);
    break;
  case GST_MESSAGE_BUFFERING:
  {
    gint percent = 0;
    if (data->is_live)
      break;
    gst_message_parse_buffering(msg, &percent);
    if (percent < 100)
    {
      if (data->should_play)
      {
        if (!data->is_loading)
        {
          data->is_loading = true;
          fl_event_channel_send(data->event_channel, fl_value_new_string("loading"), nullptr, nullptr);
        }
      }
      gst_element_set_state(data->playbin, GST_STATE_PAUSED);
    }
    else
    {
      data->is_loading = false;
      if (data->should_play)
        gst_element_set_state(data->playbin, GST_STATE_PLAYING);
      else
        gst_element_set_state(data->playbin, GST_STATE_PAUSED);
    }
    break;
  }
  case GST_MESSAGE_CLOCK_LOST:
    gst_element_set_state(data->playbin, GST_STATE_PAUSED);
    gst_element_set_state(data->playbin, GST_STATE_PLAYING);
    break;
  case GST_MESSAGE_STREAM_START:
    if (!data->url_changed)
    {
      fl_event_channel_send(data->event_channel, fl_value_new_string("advance"), nullptr, nullptr);
    }
    data->current_url = data->loaded_url;
    data->url_changed = false;
    break;
  default:
    break;
  }
  return TRUE;
}

Gstreamer::Gstreamer()
{
  gst_init(nullptr, nullptr);
  playbin = gst_element_factory_make("playbin3", NULL);
  bus = gst_element_get_bus(playbin);
  if (!playbin || !bus)
  {
    throw "Failed to create gstreamer elements";
  }
  auto ret = gst_element_set_state(playbin, GST_STATE_READY);
  if (ret == GST_STATE_CHANGE_FAILURE)
  {
    gst_object_unref(playbin);
    throw "Failed to set gstreamer playbin to READY state";
  }

  gst_bus_add_watch(bus, (GstBusFunc)Gstreamer::cb_message, this);
  g_signal_connect(playbin, "about-to-finish", G_CALLBACK(cb_about_to_finish), this);
}

Gstreamer::~Gstreamer()
{
  gst_object_unref(bus);
  gst_element_set_state(playbin, GST_STATE_NULL);
  gst_object_unref(playbin);
}

void Gstreamer::set_current(const std::string &url)
{
  is_loading = url.length() > 0;
  if (is_loading)
    fl_event_channel_send(event_channel, fl_value_new_string("loading"), nullptr, nullptr);
  auto ret = gst_element_set_state(playbin, GST_STATE_READY);
  if (ret == GST_STATE_CHANGE_FAILURE)
  {
    throw "Failed to set gstreamer playbin to READY state for media change";
  }
  if (url.length() == 0)
  {
    return;
  }
  current_url = url;
  loaded_url = url;
  url_changed = true;
  g_object_set(GST_OBJECT(playbin), "uri", url.c_str(), NULL);
}

void Gstreamer::set_next(const std::string &url)
{
  if (loaded_url != current_url)
  {
    g_object_set(GST_OBJECT(playbin), "uri", url.c_str(), NULL);
    loaded_url = url;
  }
  else
  {
    next_url = url;
  }
}

void Gstreamer::play()
{
  should_play = true;
  auto ret = gst_element_set_state(playbin, GST_STATE_PLAYING);
  if (ret == GST_STATE_CHANGE_FAILURE)
  {
    throw "Failed to set gstreamer playbin to PLAYING state";
  }
  is_live = ret == GST_STATE_CHANGE_NO_PREROLL;
}

void Gstreamer::pause()
{
  should_play = false;
  auto ret = gst_element_set_state(playbin, GST_STATE_PAUSED);
  if (ret == GST_STATE_CHANGE_FAILURE)
  {
    throw "Failed to set gstreamer playbin to PLAYING state";
  }
  is_live = ret == GST_STATE_CHANGE_NO_PREROLL;
}

void Gstreamer::seek(int milliseconds)
{
  auto query = gst_query_new_seeking(GST_FORMAT_TIME);
  if (gst_element_query(playbin, query))
  {
    gboolean enabled;
    gint64 start, end;
    gst_query_parse_seeking(query, NULL, &enabled, &start, &end);
    if (enabled)
    {
      if (milliseconds * GST_MSECOND > end)
        milliseconds = end / GST_MSECOND;
      is_loading = true;
      seeking = true;
      fl_event_channel_send(event_channel, fl_value_new_string("loading"), nullptr, nullptr);
      gst_element_seek_simple(playbin, GST_FORMAT_TIME, (GstSeekFlags)(GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_KEY_UNIT), milliseconds * GST_MSECOND);
    }
  }
}

int Gstreamer::get_position_ms()
{
  gint64 position_ns = 0;
  gst_element_query_position(playbin, GST_FORMAT_TIME, &position_ns);
  return position_ns / 1000000;
}