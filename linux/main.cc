#include "my_application.h"

int main(int argc, char **argv)
{
  g_setenv("GTK_USE_PORTAL", "1", FALSE);
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
