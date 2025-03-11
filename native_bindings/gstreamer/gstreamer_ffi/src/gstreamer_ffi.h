#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

typedef enum
{
  ERR_NONE,
  ERR_UNKNOWN,
  ERR_CREATE_ELEMENTS,
  ERR_SET_PLAYBIN_STATE,
  ERR_SEEKING_NOT_SUPPORTED,
} ErrorType;

typedef enum
{
  BUFFERING_STREAM,
  BUFFERING_DOWNLOAD,
  BUFFERING_TIMESHIFT,
  BUFFERING_LIVE,
} BufferingMode;

typedef enum
{
  STATE_VOID_PENDING,
  STATE_NULL,
  STATE_READY,
  STATE_PAUSED,
  STATE_PLAYING,
} State;

typedef void (*OnEOS)();
typedef void (*OnError)(int code, const char* message, const char* debug_msg);
typedef void (*OnWarning)(int code, const char* message);
typedef void (*OnBuffering)(int percent, BufferingMode mode, int avg_in, int avg_out);
typedef void (*OnStateChanged)(State old_state, State new_state);
typedef void (*OnStreamStart)();

typedef void (*OnAboutToFinish)();

FFI_PLUGIN_EXPORT void free_resources();
FFI_PLUGIN_EXPORT ErrorType init(
  OnEOS on_eos,
  OnError on_error,
  OnWarning on_warning,
  OnBuffering on_buffering,
  OnStateChanged on_state_changed,
  OnStreamStart on_stream_start,
  OnAboutToFinish on_about_to_finish,
  int run_main_loop
);

FFI_PLUGIN_EXPORT ErrorType set_state(State state);

FFI_PLUGIN_EXPORT void set_url(const char* url);
FFI_PLUGIN_EXPORT void set_volume(double volume);

FFI_PLUGIN_EXPORT ErrorType seek(int milliseconds);

FFI_PLUGIN_EXPORT int get_position_ms();

FFI_PLUGIN_EXPORT void waitUntilReady();