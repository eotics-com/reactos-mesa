/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2026 Ahmed ARIF <arif.ing@outlook.com>
 *
 * Direct3D Gallium target that renders through Zink on the adapter's Vulkan driver.
 */

#include <stdbool.h>

#include <windows.h>
#include "winddk_compat.h"
#include <d3dkmthk.h>

#include "pipe/p_defines.h"
#include "pipe/p_screen.h"
#include "target-helpers/inline_debug_helper.h"
#include "zink/zink_public.h"
#include "Resource.h"

struct pipe_screen *
d3d10_create_screen(void *adapter, void *device, const void *callbacks);

UINT
d3d10_get_pipeline_support_caps(void);

struct pipe_resource *
d3d10_create_resource(struct pipe_screen *screen,
                      const struct pipe_resource *templ,
                      const D3D10GalliumResourceDesc *desc,
                      void *runtime_resource, D3DKMT_HANDLE *allocation);

bool
d3d10_get_open_resource_desc(
   const D3D10DDIARG_OPENRESOURCE *open_resource,
   D3D10GalliumResourceDesc *desc);

struct pipe_resource *
d3d10_open_resource(struct pipe_screen *screen,
                    const struct pipe_resource *templ,
                    const D3D10DDIARG_OPENRESOURCE *open_resource,
                    void *runtime_resource,
                    D3DKMT_HANDLE *allocation);

void *
d3d10_get_present_context(struct pipe_screen *screen);

bool
d3d10_rotate_resource_identities(struct pipe_context *pipe,
                                 struct pipe_resource *const *resources,
                                 void *const *runtime_resources,
                                 unsigned count);

struct pipe_screen *
d3d10_create_screen(void *adapter, void *device, const void *callbacks)
{
   struct pipe_screen *screen;

   (void)adapter;
   (void)device;
   (void)callbacks;

   screen = zink_create_screen(NULL, NULL);
   if (!screen)
      return NULL;
   return debug_screen_wrap(screen);
}

UINT
d3d10_get_pipeline_support_caps(void)
{
   return D3D11DDI_ENCODE_3DPIPELINESUPPORT_CAP(D3D11DDI_3DPIPELINELEVEL_10_0);
}

void *
d3d10_get_present_context(struct pipe_screen *screen)
{
   (void)screen;
   return NULL;
}

bool
d3d10_rotate_resource_identities(struct pipe_context *pipe,
                                 struct pipe_resource *const *resources,
                                 void *const *runtime_resources,
                                 unsigned count)
{
   (void)pipe;
   (void)resources;
   (void)runtime_resources;
   (void)count;
   return false;
}

struct pipe_resource *
d3d10_create_resource(struct pipe_screen *screen,
                      const struct pipe_resource *templ,
                      const D3D10GalliumResourceDesc *desc,
                      void *runtime_resource, D3DKMT_HANDLE *allocation)
{
   struct pipe_resource local = *templ;

   (void)desc;
   (void)runtime_resource;
   if (allocation)
      *allocation = 0;
   local.bind &= ~(PIPE_BIND_DISPLAY_TARGET | PIPE_BIND_SCANOUT | PIPE_BIND_SHARED);
   return screen->resource_create(screen, &local);
}

bool
d3d10_get_open_resource_desc(
   const D3D10DDIARG_OPENRESOURCE *open_resource,
   D3D10GalliumResourceDesc *desc)
{
   (void)open_resource;
   (void)desc;
   return false;
}

struct pipe_resource *
d3d10_open_resource(struct pipe_screen *screen,
                    const struct pipe_resource *templ,
                    const D3D10DDIARG_OPENRESOURCE *open_resource,
                    void *runtime_resource,
                    D3DKMT_HANDLE *allocation)
{
   (void)screen;
   (void)templ;
   (void)open_resource;
   (void)runtime_resource;
   if (allocation)
      *allocation = 0;
   return NULL;
}
