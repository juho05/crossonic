#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"
#include "gstreamer.h"
#include <iostream>

struct _MyApplication
{
  GtkApplication parent_instance;
  char **dart_entrypoint_arguments;
  FlMethodChannel *gstreamer_method_channel;
  FlEventChannel *gstreamer_event_channel;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

Gstreamer *gstreamer;

static void gstreamer_call_handler(FlMethodChannel *channel, FlMethodCall *method_call, gpointer user_data)
{
  g_autoptr(FlMethodResponse) response = nullptr;
  g_autoptr(GError) error = nullptr;
  const gchar *method = fl_method_call_get_name(method_call);
  FlValue *args = fl_method_call_get_args(method_call);
  try
  {
    if (strcmp(method, "setCurrent") == 0)
    {
      auto url = fl_value_lookup_string(args, "url");
      if (url == nullptr || fl_value_get_type(url) == FL_VALUE_TYPE_NULL)
      {
        gstreamer->set_current("");
      }
      else
      {
        auto str = fl_value_get_string(url);
        gstreamer->set_current(str != nullptr ? str : "");
      }
    }
    else if (strcmp(method, "setNext") == 0)
    {
      auto url = fl_value_lookup_string(args, "url");
      if (url == nullptr || fl_value_get_type(url) == FL_VALUE_TYPE_NULL)
      {
        gstreamer->set_next("");
      }
      else
      {
        auto str = fl_value_get_string(url);
        gstreamer->set_next(str != nullptr ? str : "");
      }
    }
    else if (strcmp(method, "play") == 0)
    {
      gstreamer->play();
    }
    else if (strcmp(method, "pause") == 0)
    {
      gstreamer->pause();
    }
    else if (strcmp(method, "seek") == 0)
    {
      auto milliseconds = fl_value_lookup_string(args, "position");
      gstreamer->seek(fl_value_get_int(milliseconds));
    }
    else if (strcmp(method, "getPosition") == 0)
    {
      auto pos = gstreamer->get_position_ms();
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_value_new_int(pos)));
    }
    else
    {
      response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    }
  }
  catch (const char* msg)
  {
    response = FL_METHOD_RESPONSE(fl_method_error_response_new("EXCEPTION", msg, nullptr));
  }
  catch (...)
  {
    response = FL_METHOD_RESPONSE(fl_method_error_response_new("EXCEPTION", "An unexpected error occured.", nullptr));
  }
  if (response == nullptr)
  {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  }
  if (!fl_method_call_respond(method_call, response, &error))
  {
    g_warning("Failed to send gstreamer channel response: %s", error->message);
  }
}

// Implements GApplication::activate.
static void my_application_activate(GApplication *application)
{
  MyApplication *self = MY_APPLICATION(application);
  GtkWindow *window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen *screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen))
  {
    const gchar *wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0)
    {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar)
  {
    GtkHeaderBar *header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Crossonic");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  }
  else
  {
    gtk_window_set_title(window, "Crossonic");
  }

  gtk_window_set_default_size(window, 1200, 800);
  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView *view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->gstreamer_method_channel = fl_method_channel_new(fl_engine_get_binary_messenger(fl_view_get_engine(view)), "crossonic.julianh.de/gstreamer/method", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->gstreamer_method_channel, gstreamer_call_handler, self, nullptr);

  self->gstreamer_event_channel = fl_event_channel_new(fl_engine_get_binary_messenger(fl_view_get_engine(view)), "crossonic.julianh.de/gstreamer/event", FL_METHOD_CODEC(codec));
  gstreamer->event_channel = self->gstreamer_event_channel;

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication *application, gchar ***arguments, int *exit_status)
{
  MyApplication *self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error))
  {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication *application)
{
  gstreamer = new Gstreamer();
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication *application)
{
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject *object)
{
  MyApplication *self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->gstreamer_method_channel);
  g_clear_object(&self->gstreamer_event_channel);
  delete gstreamer;
  G_OBJECT_CLASS(my_application_parent_class)
      ->dispose(object);
}

static void my_application_class_init(MyApplicationClass *klass)
{
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication *self) {}

MyApplication *my_application_new()
{
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
