#include <gst/gst.h>
#include <gio/gio.h>

#define GST_G_IO_MODULE_DECLARE(name) \
extern void G_PASTE(g_io_, G_PASTE(name, _load)) (gpointer data)

#define GST_G_IO_MODULE_LOAD(name) \
G_PASTE(g_io_, G_PASTE(name, _load)) (NULL)

/* Declaration of static plugins */
 
GST_PLUGIN_STATIC_DECLARE(coreelements);
GST_PLUGIN_STATIC_DECLARE(adder);
GST_PLUGIN_STATIC_DECLARE(app);
GST_PLUGIN_STATIC_DECLARE(audioconvert);
GST_PLUGIN_STATIC_DECLARE(audiomixer);
GST_PLUGIN_STATIC_DECLARE(audiorate);
GST_PLUGIN_STATIC_DECLARE(audioresample);
GST_PLUGIN_STATIC_DECLARE(gio);
GST_PLUGIN_STATIC_DECLARE(volume);
GST_PLUGIN_STATIC_DECLARE(autodetect);
GST_PLUGIN_STATIC_DECLARE(opensles);
GST_PLUGIN_STATIC_DECLARE(ogg);
GST_PLUGIN_STATIC_DECLARE(vorbis);
GST_PLUGIN_STATIC_DECLARE(opus);
GST_PLUGIN_STATIC_DECLARE(audioparsers);
GST_PLUGIN_STATIC_DECLARE(flac);
GST_PLUGIN_STATIC_DECLARE(lame);
GST_PLUGIN_STATIC_DECLARE(wavparse);
GST_PLUGIN_STATIC_DECLARE(opusparse);
GST_PLUGIN_STATIC_DECLARE(tcp);
GST_PLUGIN_STATIC_DECLARE(typefindfunctions);
GST_PLUGIN_STATIC_DECLARE(insertbin);
GST_PLUGIN_STATIC_DECLARE(switchbin);
GST_PLUGIN_STATIC_DECLARE(fallbackswitch);
GST_PLUGIN_STATIC_DECLARE(threadshare);
GST_PLUGIN_STATIC_DECLARE(playback);
GST_PLUGIN_STATIC_DECLARE(soup);

/* Declaration of static gio modules */
 
GST_G_IO_MODULE_DECLARE(openssl);

/* Call this function to load GIO modules */
static void
gst_android_load_gio_modules (void)
{
  GTlsBackend *backend;
  const gchar *ca_certs;

  
GST_G_IO_MODULE_LOAD(openssl);

  ca_certs = g_getenv ("CA_CERTIFICATES");

  backend = g_tls_backend_get_default ();
  if (backend && ca_certs) {
    GTlsDatabase *db;
    GError *error = NULL;

    db = g_tls_file_database_new (ca_certs, &error);
    if (db) {
      g_tls_backend_set_default_database (backend, db);
      g_object_unref (db);
    } else {
      g_warning ("Failed to create a database from file: %s",
          error ? error->message : "Unknown");
    }
  }
}

/* This is called by gst_init() */
void
gst_init_static_plugins (void)
{
  
GST_PLUGIN_STATIC_REGISTER(coreelements);
GST_PLUGIN_STATIC_REGISTER(adder);
GST_PLUGIN_STATIC_REGISTER(app);
GST_PLUGIN_STATIC_REGISTER(audioconvert);
GST_PLUGIN_STATIC_REGISTER(audiomixer);
GST_PLUGIN_STATIC_REGISTER(audiorate);
GST_PLUGIN_STATIC_REGISTER(audioresample);
GST_PLUGIN_STATIC_REGISTER(gio);
GST_PLUGIN_STATIC_REGISTER(volume);
GST_PLUGIN_STATIC_REGISTER(autodetect);
GST_PLUGIN_STATIC_REGISTER(opensles);
GST_PLUGIN_STATIC_REGISTER(ogg);
GST_PLUGIN_STATIC_REGISTER(vorbis);
GST_PLUGIN_STATIC_REGISTER(opus);
GST_PLUGIN_STATIC_REGISTER(audioparsers);
GST_PLUGIN_STATIC_REGISTER(flac);
GST_PLUGIN_STATIC_REGISTER(lame);
GST_PLUGIN_STATIC_REGISTER(wavparse);
GST_PLUGIN_STATIC_REGISTER(opusparse);
GST_PLUGIN_STATIC_REGISTER(tcp);
GST_PLUGIN_STATIC_REGISTER(typefindfunctions);
GST_PLUGIN_STATIC_REGISTER(insertbin);
GST_PLUGIN_STATIC_REGISTER(switchbin);
GST_PLUGIN_STATIC_REGISTER(fallbackswitch);
GST_PLUGIN_STATIC_REGISTER(threadshare);
GST_PLUGIN_STATIC_REGISTER(playback);
GST_PLUGIN_STATIC_REGISTER(soup);
  gst_android_load_gio_modules ();
}
