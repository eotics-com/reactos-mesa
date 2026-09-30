/**************************************************************************
 *
 * Copyright 2012-2021 VMware, Inc.
 * All Rights Reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sub license, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL
 * THE COPYRIGHT HOLDERS, AUTHORS AND/OR ITS SUPPLIERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
 * USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * The above copyright notice and this permission notice (including the
 * next paragraph) shall be included in all copies or substantial portions
 * of the Software.
 *
 **************************************************************************/

/*
 * Draw.h --
 *    Functions that render 3D primitives.
 */


#include "Draw.h"
#include "State.h"
#include "Shader.h"
#include "Query.h"

#include "Debug.h"

#include "tgsi/tgsi_scan.h"
#include "util/u_draw.h"
#include "util/u_prim.h"
#include "util/u_memory.h"

static unsigned
ClampedUAdd(unsigned a,
            unsigned b)
{
   unsigned c = a + b;
   if (c < a) {
      return 0xffffffff;
   }
   return c;
}


/* stride is required in order to set the element data */
static void
update_velems(Device *pDevice)
{
   struct cso_velems_state empty_state = {};
   struct cso_velems_state *state;

   if (!pDevice->velems_changed)
      return;

   state = pDevice->element_layout ? &pDevice->element_layout->state
                                   : &empty_state;
   if (pDevice->element_layout) {
      for (unsigned i = 0; i < state->count; i++)
         state->velems[i].src_stride =
            (pDevice->element_layout->constant_mask & (1u << i)) ? 0 :
            pDevice->vertex_strides[state->velems[i].vertex_buffer_index];
   }
   cso_set_vertex_elements(pDevice->cso, state);

   pDevice->velems_changed = false;
}

/*
 * We have to resolve the stream output state for empty geometry shaders.
 * In particular we've remapped the output indices when translating the
 * shaders so now the register_index variables in the stream output
 * state are incorrect and we need to remap them back to the correct
 * state.
 */
static void
ScanShaderOutputs(Shader *pShader)
{
   if (!pShader->position_checked) {
      struct tgsi_shader_info info;

      tgsi_scan_shader(pShader->state.tokens, &info);
      pShader->writes_position = false;
      for (unsigned i = 0; i < info.num_outputs; ++i) {
         if (info.output_semantic_name[i] == TGSI_SEMANTIC_POSITION)
            pShader->writes_position = true;
      }
      pShader->clip_distances = MIN2(info.num_written_clipdistance,
                                     PIPE_MAX_CLIP_PLANES);
      pShader->position_checked = true;
   }
}


static void
ResolveRasterizerVariant(Device *pDevice)
{
   struct pipe_context *pipe = pDevice->pipe;
   Shader *last = pDevice->bound_gs ? pDevice->bound_gs : pDevice->bound_vs;
   bool discard = false;
   unsigned clips = 0;
   void *handle;
   void *(*variants)[PIPE_MAX_CLIP_PLANES + 1];
   struct pipe_rasterizer_state state;

   if (last && last->state.tokens) {
      ScanShaderOutputs(last);
      discard = !last->writes_position;
      clips = last->clip_distances;
   }

   if (pDevice->bound_rasterizer) {
      handle = pDevice->bound_rasterizer->handle;
      variants = pDevice->bound_rasterizer->variants;
      state = pDevice->bound_rasterizer->state;
   } else {
      handle = pDevice->default_rasterizer_state;
      variants = pDevice->default_rasterizer_variants;
      state = pDevice->default_rasterizer_desc;
   }

   if (discard || clips) {
      if (!variants[discard][clips]) {
         state.rasterizer_discard = discard;
         state.clip_plane_enable = (1u << clips) - 1;
         variants[discard][clips] = pipe->create_rasterizer_state(pipe, &state);
      }
      if (variants[discard][clips])
         handle = variants[discard][clips];
   }

   if (handle && handle != pDevice->bound_rasterizer_handle) {
      pipe->bind_rasterizer_state(pipe, handle);
      pDevice->bound_rasterizer_handle = handle;
   }
}


static void
ResolveShaderResources(Device *pDevice, mesa_shader_stage stage,
                       Shader *pShader)
{
   struct pipe_context *pipe = pDevice->pipe;
   struct pipe_sampler_view *views[PIPE_MAX_SHADER_SAMPLER_VIEWS] = {};
   const unsigned max_views = MIN2(
         pipe->screen->shader_caps[stage].max_sampler_views,
         PIPE_MAX_SHADER_SAMPLER_VIEWS);

   if (!pDevice->sampler_views_dirty[stage] || !max_views)
      return;

   if (pShader) {
      unsigned count = MIN2(pShader->resources.count, max_views);

      LOG_UNSUPPORTED(pShader->resources.count > max_views);
      for (unsigned i = 0; i < count; ++i)
         views[i] = pDevice->sampler_views[stage][pShader->resources.slots[i]];
   }

   pipe->set_sampler_views(pipe, stage, 0, max_views, 0, views);
   pDevice->sampler_views_dirty[stage] = false;
}


static void
ResolveState(Device *pDevice)
{
   if (pDevice->bound_empty_gs && pDevice->bound_vs &&
       pDevice->bound_vs->state.tokens) {
      Shader *gs = pDevice->bound_empty_gs;
      Shader *vs = pDevice->bound_vs;
      bool remapped = false;
      struct pipe_context *pipe = pDevice->pipe;
      if (!gs->output_resolved) {
         for (unsigned i = 0; i < gs->state.stream_output.num_outputs; ++i) {
            unsigned mapping =
               ShaderFindOutputMapping(vs, gs->state.stream_output.output[i].register_index);
            if (mapping != gs->state.stream_output.output[i].register_index) {
               gs->state.stream_output.output[i].register_index = mapping;
               remapped = true;
            }
         }
         if (remapped && pDevice->so_variant_gs == gs)
            pDevice->so_variant_vs = NULL;
         gs->output_resolved = true;
      }
      if (pDevice->so_variant_vs != vs || pDevice->so_variant_gs != gs) {
         struct pipe_shader_state state = vs->state;
         void *previous = pDevice->so_variant_handle;

         state.stream_output = gs->state.stream_output;
         pDevice->so_variant_handle = pipe->create_vs_state(pipe, &state);
         pDevice->so_variant_vs = vs;
         pDevice->so_variant_gs = gs;
         pipe->bind_vs_state(pipe, pDevice->so_variant_handle);
         if (previous)
            pipe->delete_vs_state(pipe, previous);
      } else {
         pipe->bind_vs_state(pipe, pDevice->so_variant_handle);
      }
      pipe->bind_gs_state(pipe, NULL);
   }
   update_velems(pDevice);
   ResolveRasterizerVariant(pDevice);
   ResolveShaderResources(pDevice, MESA_SHADER_VERTEX, pDevice->bound_vs);
   ResolveShaderResources(pDevice, MESA_SHADER_GEOMETRY, pDevice->bound_gs);
   ResolveShaderResources(pDevice, MESA_SHADER_FRAGMENT, pDevice->bound_ps);

   if (pDevice->vbuffers_changed) {
      cso_set_vertex_buffers(pDevice->cso, PIPE_MAX_ATTRIBS, pDevice->vertex_buffers);
      pDevice->vbuffers_changed = false;
   }
}


static bool
ShaderResourcesExceedLimit(Device *pDevice, mesa_shader_stage stage,
                           Shader *pShader)
{
   struct pipe_screen *screen = pDevice->pipe->screen;

   return pShader && pShader->resources.count >
      MIN2(screen->shader_caps[stage].max_sampler_views,
           PIPE_MAX_SHADER_SAMPLER_VIEWS);
}


static bool
DrawSkipped(Device *pDevice)
{
   if (ShaderResourcesExceedLimit(pDevice, MESA_SHADER_VERTEX, pDevice->bound_vs) ||
       ShaderResourcesExceedLimit(pDevice, MESA_SHADER_GEOMETRY, pDevice->bound_gs) ||
       ShaderResourcesExceedLimit(pDevice, MESA_SHADER_FRAGMENT, pDevice->bound_ps)) {
      LOG_UNSUPPORTED(true);
      return true;
   }
   return pDevice->predicate_emulated && !CheckPredicate(pDevice);
}


static void
CountDraw(Device *pDevice, unsigned count, unsigned instances)
{
   uint64_t primitives =
      (uint64_t)u_decomposed_prims_for_vertices(pDevice->primitive, count) * instances;

   pDevice->ia_vertices += (uint64_t)count * instances;
   pDevice->ia_primitives += primitives;
   if (pDevice->gs_bound)
      pDevice->gs_invocations += primitives;
   if (pDevice->ps_bound)
      pDevice->ps_draws++;
   for (unsigned i = 0; i < PIPE_MAX_SO_BUFFERS; ++i) {
      if (pDevice->so_targets[i]) {
         pDevice->so_draws++;
         break;
      }
   }
}


static struct pipe_resource *
create_null_index_buffer(struct pipe_context *ctx, uint num_indices,
                         unsigned *restart_index, unsigned *index_size,
                         unsigned *ib_offset)
{
   unsigned buf_size = num_indices * sizeof(unsigned);
   unsigned *buf = (unsigned*)MALLOC(buf_size);
   struct pipe_resource *ibuf;

   memset(buf, 0, buf_size);

   ibuf = pipe_buffer_create_with_data(ctx,
                                       PIPE_BIND_INDEX_BUFFER,
                                       PIPE_USAGE_IMMUTABLE,
                                       buf_size, buf);
   *index_size = 4;
   *restart_index = 0xffffffff;
   *ib_offset = 0;

   FREE(buf);

   return ibuf;
}

/*
 * ----------------------------------------------------------------------
 *
 * Draw --
 *
 *    The Draw function draws nonindexed primitives.
 *
 * ----------------------------------------------------------------------
 */

void APIENTRY
Draw(D3D10DDI_HDEVICE hDevice,   // IN
     UINT VertexCount,           // IN
     UINT StartVertexLocation)   // IN
{
   LOG_ENTRYPOINT();

   Device *pDevice = CastDevice(hDevice);

   if (DrawSkipped(pDevice)) {
      return;
   }

   ResolveState(pDevice);

   assert(pDevice->primitive < MESA_PRIM_COUNT);
   CountDraw(pDevice, VertexCount, 1);
   cso_draw_arrays(pDevice->cso,
                   pDevice->primitive,
                   StartVertexLocation,
                   VertexCount);
}


/*
 * ----------------------------------------------------------------------
 *
 * DrawIndexed --
 *
 *    The DrawIndexed function draws indexed primitives.
 *
 * ----------------------------------------------------------------------
 */

void APIENTRY
DrawIndexed(D3D10DDI_HDEVICE hDevice,  // IN
            UINT IndexCount,           // IN
            UINT StartIndexLocation,   // IN
            INT BaseVertexLocation)    // IN
{
   LOG_ENTRYPOINT();

   Device *pDevice = CastDevice(hDevice);

   if (DrawSkipped(pDevice)) {
      return;
   }
   struct pipe_draw_info info;
   struct pipe_draw_start_count_bias draw;
   struct pipe_resource *null_ib = NULL;
   unsigned restart_index = pDevice->restart_index;
   unsigned index_size = pDevice->index_size;
   unsigned ib_offset = pDevice->ib_offset;

   assert(pDevice->primitive < MESA_PRIM_COUNT);

   /* XXX I don't think draw still needs this? */
   if (!pDevice->index_buffer) {
      null_ib =
         create_null_index_buffer(pDevice->pipe,
                                  StartIndexLocation + IndexCount,
                                  &restart_index, &index_size, &ib_offset);
   }

   ResolveState(pDevice);

   util_draw_init_info(&info);
   info.index_size = index_size;
   info.mode = pDevice->primitive;
   draw.start = ClampedUAdd(StartIndexLocation, ib_offset / index_size);
   draw.count = IndexCount;
   info.index.resource = null_ib ? null_ib : pDevice->index_buffer;
   draw.index_bias = BaseVertexLocation;
   info.primitive_restart = true;
   info.restart_index = restart_index;

   CountDraw(pDevice, draw.count, info.instance_count);
   cso_draw_vbo(pDevice->cso, &info, 0, NULL, &draw, 1);

   if (null_ib) {
      pipe_resource_reference(&null_ib, NULL);
   }
}


/*
 * ----------------------------------------------------------------------
 *
 * DrawInstanced --
 *
 *    The DrawInstanced function draws particular instances
 *    of nonindexed primitives.
 *
 * ----------------------------------------------------------------------
 */

void APIENTRY
DrawInstanced(D3D10DDI_HDEVICE hDevice,      // IN
              UINT VertexCountPerInstance,   // IN
              UINT InstanceCount,            // IN
              UINT StartVertexLocation,      // IN
              UINT StartInstanceLocation)    // IN
{
   LOG_ENTRYPOINT();

   Device *pDevice = CastDevice(hDevice);

   if (DrawSkipped(pDevice)) {
      return;
   }

   if (!InstanceCount) {
      return;
   }

   ResolveState(pDevice);

   assert(pDevice->primitive < MESA_PRIM_COUNT);
   CountDraw(pDevice, VertexCountPerInstance, InstanceCount);
   cso_draw_arrays_instanced(pDevice->cso,
                             pDevice->primitive,
                             StartVertexLocation,
                             VertexCountPerInstance,
                             StartInstanceLocation,
                             InstanceCount);
}


/*
 * ----------------------------------------------------------------------
 *
 * DrawIndexedInstanced --
 *
 *    The DrawIndexedInstanced function draws particular
 *    instances of indexed primitives.
 *
 * ----------------------------------------------------------------------
 */

void APIENTRY
DrawIndexedInstanced(D3D10DDI_HDEVICE hDevice,   // IN
                     UINT IndexCountPerInstance, // IN
                     UINT InstanceCount,         // IN
                     UINT StartIndexLocation,    // IN
                     INT BaseVertexLocation,     // IN
                     UINT StartInstanceLocation) // IN
{
   LOG_ENTRYPOINT();

   Device *pDevice = CastDevice(hDevice);

   if (DrawSkipped(pDevice)) {
      return;
   }
   struct pipe_draw_info info;
   struct pipe_draw_start_count_bias draw;
   struct pipe_resource *null_ib = NULL;
   unsigned restart_index = pDevice->restart_index;
   unsigned index_size = pDevice->index_size;
   unsigned ib_offset = pDevice->ib_offset;

   assert(pDevice->primitive < MESA_PRIM_COUNT);

   if (!InstanceCount) {
      return;
   }

   /* XXX I don't think draw still needs this? */
   if (!pDevice->index_buffer) {
      null_ib =
         create_null_index_buffer(pDevice->pipe,
                                  StartIndexLocation + IndexCountPerInstance,
                                  &restart_index, &index_size, &ib_offset);
   }

   ResolveState(pDevice);

   util_draw_init_info(&info);
   info.index_size = index_size;
   info.mode = pDevice->primitive;
   draw.start = ClampedUAdd(StartIndexLocation, ib_offset / index_size);
   draw.count = IndexCountPerInstance;
   info.index.resource = null_ib ? null_ib : pDevice->index_buffer;
   draw.index_bias = BaseVertexLocation;
   info.start_instance = StartInstanceLocation;
   info.instance_count = InstanceCount;
   info.primitive_restart = true;
   info.restart_index = restart_index;

   CountDraw(pDevice, draw.count, info.instance_count);
   cso_draw_vbo(pDevice->cso, &info, 0, NULL, &draw, 1);

   if (null_ib) {
      pipe_resource_reference(&null_ib, NULL);
   }
}


/*
 * ----------------------------------------------------------------------
 *
 * DrawAuto --
 *
 *    The DrawAuto function works similarly to the Draw function,
 *    except DrawAuto is used for the special case where vertex
 *    data is written through the stream-output unit and then
 *    recycled as a vertex buffer. The driver determines the number
 *    of primitives, in part, by how much data was written to the
 *    buffer through stream output.
 *
 * ----------------------------------------------------------------------
 */

void APIENTRY
DrawAuto(D3D10DDI_HDEVICE hDevice)  // IN
{
   LOG_ENTRYPOINT();

   Device *pDevice = CastDevice(hDevice);

   if (DrawSkipped(pDevice)) {
      return;
   }
   struct pipe_draw_info info;
   struct pipe_draw_indirect_info indirect;


   if (!pDevice->draw_so_target) {
      LOG_UNSUPPORTED("DrawAuto without a set source buffer!");
      return;
   }

   assert(pDevice->primitive < MESA_PRIM_COUNT);

   ResolveState(pDevice);

   util_draw_init_info(&info);
   info.mode = pDevice->primitive;
   memset(&indirect, 0, sizeof indirect);
   indirect.count_from_stream_output = pDevice->draw_so_target;

   struct pipe_draw_start_count_bias draw = {};
   cso_draw_vbo(pDevice->cso, &info, 0, &indirect, &draw, 1);
}
