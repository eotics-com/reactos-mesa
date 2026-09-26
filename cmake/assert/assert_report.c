/* SPDX-License-Identifier: MIT */
#include <stdio.h>
#include <windows.h>

void mesa_assert_failed(const char *expr, const char *file, unsigned line);

void
mesa_assert_failed(const char *expr, const char *file, unsigned line)
{
   char message[512];

   snprintf(message, sizeof(message), "Mesa: assertion failed: %s (%s:%u)\n",
            expr, file, line);
   OutputDebugStringA(message);
   if (IsDebuggerPresent())
      DebugBreak();
}
