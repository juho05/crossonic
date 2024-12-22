#include "gstreamer_ffi.h"

#include <gst/gst.h>

typedef struct
{
  GstElement *playbin;
  GstBus *bus;
  GMainLoop *main_loop;

  OnEOS on_eos;
  OnError on_error;
  OnWarning on_warning;
  OnBuffering on_buffering;
  OnStateChanged on_state_changed;
  OnStreamStart on_stream_start;
  OnAboutToFinish on_about_to_finish;
} GstData;

GstData *data;

char* copyString(const char* str) {
  if (str == NULL) return NULL;
  char* new = malloc((strlen(str)+1)*sizeof(char));
  strcpy(new, str);
  return new;
}

FFI_PLUGIN_EXPORT void free_resources()
{
  if (data->main_loop)
  {
    g_main_loop_quit(data->main_loop);
    g_main_loop_unref(data->main_loop);
    data->main_loop = NULL;
  }
  if (data->bus) gst_object_unref(data->bus);
  data->bus = NULL;

  if (data->playbin)
  {
    gst_element_set_state(data->playbin, GST_STATE_NULL);
    gst_object_unref(data->playbin);
    data->playbin = NULL;
  }

  if (data) free(data);
  data = NULL;
}

void cb_about_to_finish(GstElement* element, void* _)
{
  data->on_about_to_finish();
}

void cb_source_setup(GstElement* element, GstElement* source, void* _)
{
  g_object_set(GST_OBJECT(source), "ssl-strict", 0, NULL);
}

gboolean cb_message(GstBus* bus, GstMessage *msg, void* _)
{
  switch(GST_MESSAGE_TYPE(msg))
  {
  case GST_MESSAGE_EOS:
    {
      if (!data->on_eos) break;
      data->on_eos();
    }
    break;
  case GST_MESSAGE_ERROR:
  {
    if (!data->on_error) break;
    GError *err = NULL;
    gchar *dbg_info = NULL;
    gst_message_parse_error(msg, &err, &dbg_info);
    data->on_error(err->code, copyString(err->message), dbg_info);
    g_error_free(err);
    break;
  }
  case GST_MESSAGE_WARNING: break;
  {
    if (!data->on_warning) break;
    GError *warn = NULL;
    gchar *dbg_info = NULL;
    gst_message_parse_warning(msg, &warn, &dbg_info);
    data->on_warning(warn->code, copyString(warn->message));
    g_error_free(warn);
    g_free(dbg_info);
    break;
  }
  case GST_MESSAGE_INFO: break;
  {
    GError *info = NULL;
    gchar *dbg_info = NULL;
    gst_message_parse_info(msg, &info, &dbg_info);
    g_printerr ("INFO from element %s: %s\n", GST_OBJECT_NAME (msg->src), info->message);
    g_error_free(info);
    g_free(dbg_info);
    break;
  }
  case GST_MESSAGE_BUFFERING:
  {
    if (!data->on_buffering) break;
    gint percent = 0;
    GstBufferingMode mode = -1;
    gint avg_in = 0;
    gint avg_out = 0;
    gst_message_parse_buffering(msg, &percent);
    gst_message_parse_buffering_stats(msg, &mode, &avg_in, &avg_out, NULL);
    data->on_buffering(percent, (BufferingMode)mode, avg_in, avg_out);
    break;
  }
  case GST_MESSAGE_STATE_CHANGED:
  {
    if (!data->on_state_changed) break;
    GstState old_state, new_state;
    gst_message_parse_state_changed(msg, &old_state, &new_state, NULL);
    data->on_state_changed((State)old_state, (State)new_state);
    break;
  }
  case GST_MESSAGE_CLOCK_LOST:
  {
    gst_element_set_state(data->playbin, GST_STATE_PAUSED);
    gst_element_set_state(data->playbin, GST_STATE_PLAYING);
    break;
  }
  case GST_MESSAGE_STREAM_START:
  {
    if (!data->on_stream_start) break;
    data->on_stream_start();
    break;
  }
  default: break;
  }
  return TRUE;
}

gpointer run_main_loop_thread(gpointer _)
{
  g_main_loop_run(data->main_loop);
  return NULL;
}

FFI_PLUGIN_EXPORT ErrorType init(
  OnEOS on_eos,
  OnError on_error,
  OnWarning on_warning,
  OnBuffering on_buffering,
  OnStateChanged on_state_changed,
  OnStreamStart on_stream_start,
  OnAboutToFinish on_about_to_finish,
  int run_main_loop
)
{
  gst_init(NULL, NULL);

  data = calloc(1, sizeof(GstData));
  data->on_eos = on_eos;
  data->on_error = on_error;
  data->on_warning = on_warning;
  data->on_buffering = on_buffering;
  data->on_state_changed = on_state_changed;
  data->on_stream_start = on_stream_start;
  data->on_about_to_finish = on_about_to_finish;

  data->playbin = gst_element_factory_make("playbin3", NULL);
  data->bus = gst_element_get_bus(data->playbin);
  if (!data->playbin || !data->bus) return ERR_CREATE_ELEMENTS;

  if (run_main_loop)
  {
    data->main_loop = g_main_loop_new(NULL, FALSE);
    g_thread_new("main_loop", run_main_loop_thread, NULL);
  }

  GstStateChangeReturn ret = gst_element_set_state(data->playbin, GST_STATE_READY);
  if (ret == GST_STATE_CHANGE_FAILURE)
  {
    free_resources();
    return ERR_SET_PLAYBIN_STATE;
  }

  gst_bus_add_watch(data->bus, (GstBusFunc)cb_message, NULL);

  g_signal_connect(data->playbin, "source-setup", G_CALLBACK(cb_source_setup), NULL);
  if (data->on_about_to_finish)
  {
    g_signal_connect(data->playbin, "about-to-finish", G_CALLBACK(cb_about_to_finish), NULL);
  }

  return ERR_NONE;
}

FFI_PLUGIN_EXPORT ErrorType set_state(State state)
{
  GstStateChangeReturn ret = gst_element_set_state(data->playbin, (GstState)state);
  if (ret == GST_STATE_CHANGE_FAILURE)
  {
    return ERR_SET_PLAYBIN_STATE;
  }
  return ERR_NONE;
}

FFI_PLUGIN_EXPORT void set_url(const char* url)
{
  g_object_set(GST_OBJECT(data->playbin), "uri", url, NULL);
}

FFI_PLUGIN_EXPORT ErrorType seek(int milliseconds)
{
  GstQuery* query = gst_query_new_seeking(GST_FORMAT_TIME);
  if (gst_element_query(data->playbin, query))
  {
    gboolean enabled;
    gint64 start, end;
    gst_query_parse_seeking(query, NULL, &enabled, &start, &end);
    if (enabled)
    {
      if (milliseconds * GST_MSECOND > end)
      {
        milliseconds = end / GST_MSECOND;
      }
      gst_element_seek_simple(data->playbin, GST_FORMAT_TIME, (GstSeekFlags)(GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_KEY_UNIT), milliseconds * GST_MSECOND);
      gst_query_unref(query);
      return ERR_NONE;
    }
  }
  gst_query_unref(query);
  return ERR_SEEKING_NOT_SUPPORTED;
}

FFI_PLUGIN_EXPORT int get_position_ms()
{
  gint64 position_ns = 0;
  gst_element_query_position(data->playbin, GST_FORMAT_TIME, &position_ns);
  return position_ns / 1000000;
}

FFI_PLUGIN_EXPORT void set_volume(double volume)
{
  g_object_set(GST_OBJECT(data->playbin), "volume", volume, NULL);
}