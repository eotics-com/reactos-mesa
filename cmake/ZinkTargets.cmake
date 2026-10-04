# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 Ahmed ARIF <arif.ing@outlook.com>
# Native CMake target graph for the Zink Gallium driver in the WGL ICD.

set(_mesa_zink "${PROJECT_SOURCE_DIR}/src/gallium/drivers/zink")
set(_mesa_zink_build "${PROJECT_BINARY_DIR}/src/gallium/drivers/zink")

function(mesa_zink_target_defaults target)
    mesa_target_defaults(${target})
    target_include_directories(${target} PRIVATE
        "${_mesa_zink_build}"
        "${_mesa_zink}"
        "${_mesa_zink}/nir_to_spirv"
        "${PROJECT_BINARY_DIR}/include"
        "${PROJECT_SOURCE_DIR}/include"
        "${PROJECT_BINARY_DIR}/src"
        "${PROJECT_SOURCE_DIR}/src"
        "${PROJECT_BINARY_DIR}/src/util"
        "${PROJECT_SOURCE_DIR}/src/util"
        "${PROJECT_BINARY_DIR}/src/util/format"
        "${PROJECT_SOURCE_DIR}/src/gallium/include"
        "${PROJECT_BINARY_DIR}/src/gallium/auxiliary"
        "${PROJECT_SOURCE_DIR}/src/gallium/auxiliary"
        "${PROJECT_BINARY_DIR}/src/compiler"
        "${PROJECT_SOURCE_DIR}/src/compiler"
        "${PROJECT_BINARY_DIR}/src/compiler/nir"
        "${PROJECT_SOURCE_DIR}/src/compiler/nir"
        "${PROJECT_BINARY_DIR}/src/compiler/spirv"
        "${PROJECT_SOURCE_DIR}/src/compiler/spirv"
        "${PROJECT_BINARY_DIR}/src/vulkan/util"
        "${PROJECT_SOURCE_DIR}/src/vulkan/util"
        "${PROJECT_BINARY_DIR}/src/vulkan/wsi"
        "${PROJECT_SOURCE_DIR}/src/vulkan/wsi")
    target_compile_definitions(${target} PRIVATE
        VK_USE_PLATFORM_WIN32_KHR
        XXH_FORCE_ALIGN_CHECK=0
        XXH_FORCE_MEMORY_ACCESS=0)
    target_compile_options(${target} PRIVATE
        "$<$<COMPILE_LANGUAGE:C>:-fvisibility=hidden>")
endfunction()

if(NOT TARGET vulkan_util)
    add_library(vulkan_util STATIC EXCLUDE_FROM_ALL)
    mesa_zink_target_defaults(vulkan_util)
    target_sources(vulkan_util PRIVATE
        "${PROJECT_SOURCE_DIR}/src/vulkan/util/vk_alloc.c"
        "${PROJECT_SOURCE_DIR}/src/vulkan/util/vk_format.c"
        "${PROJECT_SOURCE_DIR}/src/vulkan/util/vk_util.c"
        "${PROJECT_BINARY_DIR}/src/vulkan/util/vk_dispatch_table.c"
        "${PROJECT_BINARY_DIR}/src/vulkan/util/vk_enum_to_str.c"
        "${PROJECT_BINARY_DIR}/src/vulkan/util/vk_extensions.c")
endif()

add_library(zink STATIC EXCLUDE_FROM_ALL)
mesa_zink_target_defaults(zink)
target_sources(zink PRIVATE
    "${_mesa_zink}/zink_lower_cubemap_to_array.c"
    "${_mesa_zink}/zink_batch.c"
    "${_mesa_zink}/zink_blit.c"
    "${_mesa_zink}/zink_bo.c"
    "${_mesa_zink}/zink_clear.c"
    "${_mesa_zink}/zink_compiler.c"
    "${_mesa_zink}/zink_context.c"
    "${_mesa_zink}/zink_kopper.c"
    "${_mesa_zink}/zink_descriptors.c"
    "${_mesa_zink}/zink_draw.cpp"
    "${_mesa_zink}/zink_fence.c"
    "${_mesa_zink}/zink_format.c"
    "${_mesa_zink}/zink_pipeline.c"
    "${_mesa_zink}/zink_program.c"
    "${_mesa_zink}/zink_query.c"
    "${_mesa_zink}/zink_render_pass.c"
    "${_mesa_zink}/zink_resource.c"
    "${_mesa_zink}/zink_screen.c"
    "${_mesa_zink}/zink_state.c"
    "${_mesa_zink}/zink_surface.c"
    "${_mesa_zink}/zink_synchronization.cpp"
    "${_mesa_zink}/nir_to_spirv/nir_to_spirv.c"
    "${_mesa_zink}/nir_to_spirv/spirv_builder.c"
    "${_mesa_zink_build}/zink_device_info.c"
    "${_mesa_zink_build}/zink_instance.c"
    "${_mesa_zink_build}/zink_nir_algebraic.c")

target_compile_options(mesa_gallium PRIVATE "$<$<COMPILE_LANGUAGE:C>:-DGALLIUM_ZINK>")
target_link_libraries(mesa_gallium PRIVATE zink vulkan_util)

add_library(d3d10zink SHARED EXCLUDE_FROM_ALL
    "${PROJECT_SOURCE_DIR}/src/gallium/frontends/d3d10umd/Adapter.cpp"
    "${PROJECT_SOURCE_DIR}/src/gallium/frontends/d3d10umd/Debug.cpp"
    "${PROJECT_SOURCE_DIR}/src/gallium/frontends/d3d10umd/Device.cpp"
    "${PROJECT_SOURCE_DIR}/src/gallium/frontends/d3d10umd/Draw.cpp"
    "${PROJECT_SOURCE_DIR}/src/gallium/frontends/d3d10umd/DxgiFns.cpp"
    "${PROJECT_SOURCE_DIR}/src/gallium/frontends/d3d10umd/Format.cpp"
    "${PROJECT_SOURCE_DIR}/src/gallium/frontends/d3d10umd/InputAssembly.cpp"
    "${PROJECT_SOURCE_DIR}/src/gallium/frontends/d3d10umd/OutputMerger.cpp"
    "${PROJECT_SOURCE_DIR}/src/gallium/frontends/d3d10umd/Query.cpp"
    "${PROJECT_SOURCE_DIR}/src/gallium/frontends/d3d10umd/Rasterizer.cpp"
    "${PROJECT_SOURCE_DIR}/src/gallium/frontends/d3d10umd/Resource.cpp"
    "${PROJECT_SOURCE_DIR}/src/gallium/frontends/d3d10umd/Shader.cpp"
    "${PROJECT_SOURCE_DIR}/src/gallium/frontends/d3d10umd/ShaderDump.cpp"
    "${PROJECT_SOURCE_DIR}/src/gallium/frontends/d3d10umd/ShaderParse.c"
    "${PROJECT_SOURCE_DIR}/src/gallium/frontends/d3d10umd/ShaderTGSI.c"
    "${PROJECT_SOURCE_DIR}/src/gallium/targets/d3d10umd/d3d10_zink.c"
    "${PROJECT_SOURCE_DIR}/src/gallium/targets/d3d10umd/d3d10zink.def")
mesa_target_defaults(d3d10zink)
target_include_directories(d3d10zink BEFORE PRIVATE
    "${MESA_REACTOS_SOURCE_DIR}/sdk/include/ddk")
target_include_directories(d3d10zink PRIVATE
    "${PROJECT_BINARY_DIR}/include"
    "${PROJECT_SOURCE_DIR}/include"
    "${PROJECT_SOURCE_DIR}/include/winddk"
    "${PROJECT_BINARY_DIR}/src"
    "${PROJECT_SOURCE_DIR}/src"
    "${PROJECT_BINARY_DIR}/src/util"
    "${PROJECT_BINARY_DIR}/src/util/format"
    "${PROJECT_BINARY_DIR}/src/compiler"
    "${PROJECT_SOURCE_DIR}/src/compiler"
    "${PROJECT_BINARY_DIR}/src/compiler/nir"
    "${PROJECT_SOURCE_DIR}/src/compiler/nir"
    "${PROJECT_SOURCE_DIR}/src/gallium/include"
    "${PROJECT_BINARY_DIR}/src/gallium/auxiliary"
    "${PROJECT_SOURCE_DIR}/src/gallium/auxiliary"
    "${PROJECT_BINARY_DIR}/src/gallium/frontends/d3d10umd"
    "${PROJECT_SOURCE_DIR}/src/gallium/frontends/d3d10umd"
    "${PROJECT_BINARY_DIR}/src/gallium/drivers"
    "${PROJECT_SOURCE_DIR}/src/gallium/drivers"
    "${MESA_REACTOS_SOURCE_DIR}/sdk/include/reactos")
target_compile_options(d3d10zink PRIVATE
    "$<$<COMPILE_LANGUAGE:C>:-DXXH_FORCE_ALIGN_CHECK=0>"
    "$<$<COMPILE_LANGUAGE:C>:-DXXH_FORCE_MEMORY_ACCESS=0>")
target_link_libraries(d3d10zink PRIVATE
    "-Wl,-O1"
    "-Wl,--gc-sections"
    "-Wl,--nxcompat"
    "-Wl,--dynamicbase"
    gallium
    zink
    vulkan_util
    nir
    compiler
    mesa_util
    mesa_util_simd
    blake3
    mesa_util_c11
    vtn
    xmlconfig
    ${MESA_LINK_LIBM}
    "-lkernel32"
    "-luser32"
    "-lgdi32"
    "-ladvapi32"
    ${MESA_LINK_SYNCHRONIZATION}
    "-lws2_32")
set_target_properties(d3d10zink PROPERTIES
    PREFIX ""
    LINKER_LANGUAGE CXX
    RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/src/gallium/targets/d3d10umd")
