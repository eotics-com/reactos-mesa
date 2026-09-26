/* SPDX-License-Identifier: MIT */
/*
 * Mesa runs inside other processes, the compositor among them. The CRT's
 * assertion handler stops the failing thread in a modal dialog and reports
 * nothing to the debugger, so a failed assertion in the compositor froze the
 * desktop without a trace. Report the failure to the debugger instead and
 * continue as a build without assertions would.
 *
 * No include guard: <assert.h> redefines assert on every inclusion, and this
 * wrapper has to reapply its definition each time as well.
 */
#include_next <assert.h>

#ifndef NDEBUG
#undef assert
#ifdef __cplusplus
extern "C"
#endif
void mesa_assert_failed(const char *expr, const char *file, unsigned line);
#define assert(e) \
   ((void)(!!(e) || (mesa_assert_failed(#e, __FILE__, __LINE__), 0)))
#endif
