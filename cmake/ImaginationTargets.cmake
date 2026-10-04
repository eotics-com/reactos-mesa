# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 Ahmed ARIF <arif.ing@outlook.com>
# Native CMake target graph for the Imagination PowerVR Vulkan ICD over the
# ReactOS pvrkmt transport.

set(_mesa_img "${PROJECT_SOURCE_DIR}/src/imagination")
set(_mesa_img_build "${PROJECT_BINARY_DIR}/src/imagination")
set(_mesa_pvrkmt_include "${MESA_REACTOS_SOURCE_DIR}/sdk/lib/pvrkmt/include")
set(_mesa_pvrkmt_library "${MESA_REACTOS_BUILD_DIR}/sdk/lib/pvrkmt/libpvrkmt.a")

function(mesa_pvr_target_defaults target)
    mesa_target_defaults(${target})
    target_include_directories(${target} BEFORE PRIVATE "${_mesa_pvrkmt_include}")
    target_include_directories(${target} PRIVATE
        "${PROJECT_BINARY_DIR}/include"
        "${PROJECT_SOURCE_DIR}/include"
        "${PROJECT_BINARY_DIR}/src"
        "${PROJECT_SOURCE_DIR}/src"
        "${PROJECT_BINARY_DIR}/src/util"
        "${PROJECT_SOURCE_DIR}/src/util"
        "${PROJECT_BINARY_DIR}/src/util/format"
        "${PROJECT_BINARY_DIR}/src/compiler"
        "${PROJECT_SOURCE_DIR}/src/compiler"
        "${PROJECT_BINARY_DIR}/src/compiler/nir"
        "${PROJECT_SOURCE_DIR}/src/compiler/nir"
        "${PROJECT_BINARY_DIR}/src/compiler/spirv"
        "${PROJECT_SOURCE_DIR}/src/compiler/spirv"
        "${PROJECT_BINARY_DIR}/src/vulkan/util"
        "${PROJECT_SOURCE_DIR}/src/vulkan/util"
        "${PROJECT_BINARY_DIR}/src/vulkan/wsi"
        "${PROJECT_SOURCE_DIR}/src/vulkan/wsi"
        "${PROJECT_BINARY_DIR}/src/vulkan/runtime"
        "${PROJECT_SOURCE_DIR}/src/vulkan/runtime"
        "${_mesa_img_build}"
        "${_mesa_img}"
        "${_mesa_img}/common"
        "${_mesa_img}/include"
        "${_mesa_img_build}/pco"
        "${_mesa_img}/pco"
        "${_mesa_img_build}/pco/usclib"
        "${_mesa_img_build}/pco/uscgen"
        "${_mesa_img_build}/vulkan"
        "${_mesa_img}/vulkan"
        "${_mesa_img}/vulkan/winsys"
        "${_mesa_img}/vulkan/pds"
        "${_mesa_img}/vulkan/pds/pvr_pds_programs")
    target_compile_definitions(${target} PRIVATE
        VK_USE_PLATFORM_WIN32_KHR
        HAVE_LIBDRM=1
        MESA_VK_LOG=0
        XXH_FORCE_ALIGN_CHECK=0
        XXH_FORCE_MEMORY_ACCESS=0)
    target_compile_options(${target} PRIVATE
        "$<$<COMPILE_LANGUAGE:C>:-fvisibility=hidden>"
        "$<$<COMPILE_LANGUAGE:C>:-Werror=pointer-arith>"
        "$<$<COMPILE_LANGUAGE:C>:-Wno-override-init>"
        "$<$<COMPILE_LANGUAGE:C>:-Wno-initializer-overrides>")
endfunction()

if(NOT TARGET vulkan_util)
    add_library(vulkan_util STATIC EXCLUDE_FROM_ALL)
    mesa_pvr_target_defaults(vulkan_util)
    target_sources(vulkan_util PRIVATE
        "${PROJECT_SOURCE_DIR}/src/vulkan/util/vk_alloc.c"
        "${PROJECT_SOURCE_DIR}/src/vulkan/util/vk_format.c"
        "${PROJECT_SOURCE_DIR}/src/vulkan/util/vk_util.c"
        "${PROJECT_BINARY_DIR}/src/vulkan/util/vk_dispatch_table.c"
        "${PROJECT_BINARY_DIR}/src/vulkan/util/vk_enum_to_str.c"
        "${PROJECT_BINARY_DIR}/src/vulkan/util/vk_extensions.c")
endif()

set(_mesa_sdk_dx_include "${PROJECT_BINARY_DIR}/reactos-sdk/include")
file(WRITE "${_mesa_sdk_dx_include}/directx/d3d12.h" "#pragma once\n#include <d3d12.h>\n")
file(WRITE "${_mesa_sdk_dx_include}/dxguids/dxguids.h" "#pragma once\n")

add_library(pvr_vulkan_runtime STATIC EXCLUDE_FROM_ALL)
mesa_pvr_target_defaults(pvr_vulkan_runtime)
target_include_directories(pvr_vulkan_runtime SYSTEM PRIVATE "${_mesa_sdk_dx_include}")
set_source_files_properties(
    "${PROJECT_SOURCE_DIR}/src/vulkan/wsi/wsi_common.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/wsi/wsi_common_win32.cpp"
    "${PROJECT_BINARY_DIR}/src/vulkan/wsi/wsi_common_entrypoints.c"
    PROPERTIES COMPILE_OPTIONS "-UHAVE_LIBDRM")
target_sources(pvr_vulkan_runtime PRIVATE
    "${PROJECT_SOURCE_DIR}/src/vulkan/wsi/wsi_common.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/wsi/wsi_common_win32.cpp"
    "${PROJECT_SOURCE_DIR}/src/util/u_sync_provider.c"
    "${PROJECT_BINARY_DIR}/src/vulkan/wsi/wsi_common_entrypoints.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/rmv/vk_rmv_common.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/rmv/vk_rmv_exporter.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_blend.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_buffer.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_buffer_view.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_cmd_copy.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_cmd_enqueue.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_command_buffer.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_command_pool.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_debug_report.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_debug_utils.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_deferred_operation.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_descriptor_set_layout.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_descriptors.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_descriptor_update_template.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_device.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_device_generated_commands.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_device_memory.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_drm_syncobj.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_fence.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_framebuffer.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_graphics_state.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_image.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_instance.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_log.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_meta.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_meta_blit_resolve.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_meta_clear.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_meta_copy_fill_update.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_meta_draw_rects.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_meta_object_list.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_nir.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_nir_convert_ycbcr.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_nir_lower_descriptor_heaps.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_object.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_physical_device.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_pipeline.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_pipeline_cache.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_pipeline_layout.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_query_pool.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_queue.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_render_pass.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_sampler.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_semaphore.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_shader.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_shader_module.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_standard_sample_locations.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_sync.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_sync_binary.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_sync_dummy.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_sync_timeline.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_synchronization.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_texcompress_etc2.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_video.c"
    "${PROJECT_SOURCE_DIR}/src/vulkan/runtime/vk_ycbcr_conversion.c"
    "${PROJECT_BINARY_DIR}/src/vulkan/runtime/vk_cmd_enqueue_entrypoints.c"
    "${PROJECT_BINARY_DIR}/src/vulkan/runtime/vk_cmd_queue.c"
    "${PROJECT_BINARY_DIR}/src/vulkan/runtime/vk_common_entrypoints.c"
    "${PROJECT_BINARY_DIR}/src/vulkan/runtime/vk_dispatch_trampolines.c"
    "${PROJECT_BINARY_DIR}/src/vulkan/runtime/vk_format_info.c"
    "${PROJECT_BINARY_DIR}/src/vulkan/runtime/vk_physical_device_features.c"
    "${PROJECT_BINARY_DIR}/src/vulkan/runtime/vk_physical_device_properties.c"
    "${PROJECT_BINARY_DIR}/src/vulkan/runtime/vk_physical_device_spirv_caps.c"
    "${PROJECT_BINARY_DIR}/src/vulkan/runtime/vk_synchronization_helpers.c")

add_library(powervr_common STATIC EXCLUDE_FROM_ALL)
mesa_pvr_target_defaults(powervr_common)
target_sources(powervr_common PRIVATE
    "${_mesa_img}/common/pvr_debug.c"
    "${_mesa_img}/common/pvr_device_info.c"
    "${_mesa_img}/common/pvr_dump.c"
    "${_mesa_img}/common/pvr_dump_info.c"
    "${_mesa_img}/common/pvr_util.c"
    "${_mesa_img}/common/pvr_ycbcr.c")

add_library(powervr_compiler STATIC EXCLUDE_FROM_ALL)
mesa_pvr_target_defaults(powervr_compiler)
target_sources(powervr_compiler PRIVATE
    "${_mesa_img}/pco/pco.c"
    "${_mesa_img}/pco/pco_binary.c"
    "${_mesa_img}/pco/pco_bool.c"
    "${_mesa_img}/pco/pco_cf.c"
    "${_mesa_img}/pco/pco_const_imms.c"
    "${_mesa_img}/pco/pco_debug.c"
    "${_mesa_img}/pco/pco_end.c"
    "${_mesa_img}/pco/pco_group_instrs.c"
    "${_mesa_img}/pco/pco_index.c"
    "${_mesa_img}/pco/pco_ir.c"
    "${_mesa_img}/pco/pco_legalize.c"
    "${_mesa_img}/pco/pco_nir.c"
    "${_mesa_img}/pco/pco_nir_compute.c"
    "${_mesa_img}/pco/pco_nir_io.c"
    "${_mesa_img}/pco/pco_nir_lower_null_descriptors.c"
    "${_mesa_img}/pco/pco_nir_pvfio.c"
    "${_mesa_img}/pco/pco_nir_sync.c"
    "${_mesa_img}/pco/pco_nir_tex.c"
    "${_mesa_img}/pco/pco_nir_vk.c"
    "${_mesa_img}/pco/pco_opt.c"
    "${_mesa_img}/pco/pco_print.c"
    "${_mesa_img}/pco/pco_ra.c"
    "${_mesa_img}/pco/pco_schedule.c"
    "${_mesa_img}/pco/pco_trans_nir.c"
    "${_mesa_img}/pco/pco_validate.c"
    "${_mesa_img_build}/pco/pco_info.c"
    "${_mesa_img_build}/pco/pco_nir_algebraic.c"
    "${_mesa_img_build}/pco/usclib/pco_usclib.cpp")

add_library(powervr_uscgen STATIC EXCLUDE_FROM_ALL)
mesa_pvr_target_defaults(powervr_uscgen)
target_sources(powervr_uscgen PRIVATE
    "${_mesa_img_build}/pco/uscgen/pco_uscgen_programs.c")

add_library(powervr_pds STATIC EXCLUDE_FROM_ALL)
mesa_pvr_target_defaults(powervr_pds)
target_sources(powervr_pds PRIVATE
    "${_mesa_img}/vulkan/pds/pvr_pds.c"
    "${_mesa_img}/vulkan/pds/pvr_pds_disasm.c"
    "${_mesa_img}/vulkan/pds/pvr_pds_printer.c"
    "${_mesa_img}/vulkan/pds/pvr_pipeline_pds.c")

add_library(powervr_rogue STATIC EXCLUDE_FROM_ALL)
mesa_pvr_target_defaults(powervr_rogue)
target_compile_definitions(powervr_rogue PRIVATE PVR_BUILD_ARCH_ROGUE)
target_sources(powervr_rogue PRIVATE
    "${_mesa_img}/vulkan/pvr_arch_border.c"
    "${_mesa_img}/vulkan/pvr_arch_cmd_buffer.c"
    "${_mesa_img}/vulkan/pvr_arch_cmd_query.c"
    "${_mesa_img}/vulkan/pvr_arch_csb.c"
    "${_mesa_img}/vulkan/pvr_arch_descriptor_set.c"
    "${_mesa_img}/vulkan/pvr_arch_device.c"
    "${_mesa_img}/vulkan/pvr_arch_formats.c"
    "${_mesa_img}/vulkan/pvr_arch_framebuffer.c"
    "${_mesa_img}/vulkan/pvr_arch_hw_pass.c"
    "${_mesa_img}/vulkan/pvr_arch_pass.c"
    "${_mesa_img}/vulkan/pvr_arch_pipeline.c"
    "${_mesa_img}/vulkan/pvr_arch_image.c"
    "${_mesa_img}/vulkan/pvr_arch_job_common.c"
    "${_mesa_img}/vulkan/pvr_arch_job_compute.c"
    "${_mesa_img}/vulkan/pvr_arch_job_context.c"
    "${_mesa_img}/vulkan/pvr_arch_job_render.c"
    "${_mesa_img}/vulkan/pvr_arch_job_transfer.c"
    "${_mesa_img}/vulkan/pvr_arch_mrt.c"
    "${_mesa_img}/vulkan/pvr_arch_queue.c"
    "${_mesa_img}/vulkan/pvr_arch_query_compute.c"
    "${_mesa_img}/vulkan/pvr_arch_sampler.c"
    "${_mesa_img}/vulkan/pvr_arch_spm.c"
    "${_mesa_img}/vulkan/pvr_arch_tex_state.c"
    "${_mesa_img}/vulkan/rogue/pvr_blit.c"
    "${_mesa_img}/vulkan/rogue/pvr_clear.c"
    "${_mesa_img}/vulkan/rogue/pvr_dump_csb.c")

add_library(vulkan_powervr_mesa SHARED EXCLUDE_FROM_ALL)
mesa_pvr_target_defaults(vulkan_powervr_mesa)
target_sources(vulkan_powervr_mesa PRIVATE
    "${_mesa_img}/vulkan/winsys/powervr/pvr_drm.c"
    "${_mesa_img}/vulkan/winsys/powervr/pvr_drm_bo.c"
    "${_mesa_img}/vulkan/winsys/powervr/pvr_drm_job_compute.c"
    "${_mesa_img}/vulkan/winsys/powervr/pvr_drm_job_null.c"
    "${_mesa_img}/vulkan/winsys/powervr/pvr_drm_job_render.c"
    "${_mesa_img}/vulkan/winsys/powervr/pvr_drm_job_transfer.c"
    "${_mesa_img}/vulkan/winsys/pvr_winsys.c"
    "${_mesa_img}/vulkan/winsys/pvr_winsys_helper.c"
    "${_mesa_img}/vulkan/pvr_bo.c"
    "${_mesa_img}/vulkan/pvr_csb.c"
    "${_mesa_img}/vulkan/pvr_descriptor_set.c"
    "${_mesa_img}/vulkan/pvr_device.c"
    "${_mesa_img}/vulkan/pvr_dump_bo.c"
    "${_mesa_img}/vulkan/pvr_free_list.c"
    "${_mesa_img}/vulkan/pvr_formats.c"
    "${_mesa_img}/vulkan/pvr_image.c"
    "${_mesa_img}/vulkan/pvr_instance.c"
    "${_mesa_img}/vulkan/pvr_nir_lower_ycbcr.c"
    "${_mesa_img}/vulkan/pvr_physical_device.c"
    "${_mesa_img}/vulkan/pvr_transfer_frag_store.c"
    "${_mesa_img}/vulkan/pvr_query.c"
    "${_mesa_img}/vulkan/pvr_robustness.c"
    "${_mesa_img}/vulkan/pvr_rt_dataset.c"
    "${_mesa_img}/vulkan/pvr_spm.c"
    "${_mesa_img}/vulkan/pvr_usc.c"
    "${_mesa_img}/vulkan/pvr_wsi.c"
    "${_mesa_img_build}/vulkan/pvr_entrypoints.c"
    "${_mesa_img_build}/vulkan/pvr_drirc.c"
    "${MESA_VULKAN_DEF}")
target_link_libraries(vulkan_powervr_mesa PRIVATE
    "-Wl,--whole-archive"
    powervr_rogue
    pvr_vulkan_runtime
    "-Wl,--no-whole-archive"
    powervr_common
    powervr_compiler
    powervr_uscgen
    powervr_pds
    vulkan_util
    vtn
    nir
    compiler
    xmlconfig
    mesa_util
    mesa_util_simd
    blake3
    mesa_util_c11
    "${_mesa_pvrkmt_library}"
    "-lkernelbase"
    "-lgdi32"
    "-luser32"
    "-ladvapi32"
    "-lole32"
    "-lshell32"
    "-luuid")
set_target_properties(vulkan_powervr_mesa PROPERTIES
    PREFIX ""
    LINKER_LANGUAGE CXX
    RUNTIME_OUTPUT_DIRECTORY "${_mesa_img_build}/vulkan")

add_custom_target(powervr_icd DEPENDS "${MESA_POWERVR_MANIFEST}")
