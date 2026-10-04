# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 Ahmed ARIF <arif.ing@outlook.com>
# Generator graph for the Imagination PowerVR Vulkan ICD.

set(_mesa_img "${PROJECT_SOURCE_DIR}/src/imagination")
set(_mesa_img_build "${PROJECT_BINARY_DIR}/src/imagination")

foreach(_mesa_pvr_arch rogue volcanic)
    if(_mesa_pvr_arch STREQUAL "rogue")
        set(_mesa_pvr_xml cdm cr ipf kmd_stream lls pbestate pds ppp texstate vdm)
    else()
        set(_mesa_pvr_xml cdm ipf lls pbestate pds texstate)
    endif()
    foreach(_mesa_pvr_name IN LISTS _mesa_pvr_xml)
        mesa_generate(
            OUTPUT "${_mesa_img_build}/csbgen/${_mesa_pvr_arch}/${_mesa_pvr_name}.h"
            COMMAND
                "${Python3_EXECUTABLE}" "${_mesa_img}/csbgen/gen_pack_header.py"
                "${_mesa_img}/csbgen/${_mesa_pvr_arch}/${_mesa_pvr_name}.xml"
            CAPTURE "${_mesa_img_build}/csbgen/${_mesa_pvr_arch}/${_mesa_pvr_name}.h"
            DEPENDS
                "${_mesa_img}/csbgen/gen_pack_header.py"
                "${_mesa_img}/csbgen/${_mesa_pvr_arch}/${_mesa_pvr_name}.xml"
                "${Python3_EXECUTABLE}")
    endforeach()
endforeach()

set(_mesa_pco_pygen_deps
    "${_mesa_img}/pco/pco_pygen_common.py"
    "${_mesa_img}/pco/pco_isa.py"
    "${_mesa_img}/pco/pco_ops.py"
    "${_mesa_img}/pco/pco_map.py")
foreach(_mesa_pco_out pco_builder_ops.h pco_common.h pco_info.c pco_isa.h pco_map.h pco_ops.h)
    mesa_generate(
        OUTPUT "${_mesa_img_build}/pco/${_mesa_pco_out}"
        COMMAND "${Python3_EXECUTABLE}" "${_mesa_img}/pco/${_mesa_pco_out}.py"
        CAPTURE "${_mesa_img_build}/pco/${_mesa_pco_out}"
        DEPENDS "${_mesa_img}/pco/${_mesa_pco_out}.py" ${_mesa_pco_pygen_deps} "${Python3_EXECUTABLE}")
endforeach()

mesa_generate(
    OUTPUT "${_mesa_img_build}/pco/pco_nir_algebraic.c"
    COMMAND
        "${Python3_EXECUTABLE}" "${_mesa_img}/pco/pco_nir_algebraic.py"
        -p "${PROJECT_SOURCE_DIR}/src/compiler/nir"
    CAPTURE "${_mesa_img_build}/pco/pco_nir_algebraic.c"
    DEPENDS
        "${_mesa_img}/pco/pco_nir_algebraic.py"
        "${PROJECT_SOURCE_DIR}/src/compiler/nir/nir_algebraic.py"
        "${PROJECT_SOURCE_DIR}/src/compiler/nir/nir_opcodes.py"
        "${Python3_EXECUTABLE}")

foreach(_mesa_pco_precomp
        "pco/usclib/pco_usclib.cpp"
        "pco/usclib/pco_usclib.h"
        "pco/uscgen/pco_uscgen_programs.c"
        "pco/uscgen/pco_uscgen_programs.h")
    get_filename_component(_mesa_pco_precomp_name "${_mesa_pco_precomp}" NAME)
    configure_file("${_mesa_img}/precomp/${_mesa_pco_precomp_name}"
        "${_mesa_img_build}/${_mesa_pco_precomp}" COPYONLY)
endforeach()

mesa_generate(
    OUTPUT
        "${_mesa_img_build}/vulkan/pvr_entrypoints.h"
        "${_mesa_img_build}/vulkan/pvr_entrypoints.c"
    COMMAND
        "${Python3_EXECUTABLE}" "${PROJECT_SOURCE_DIR}/src/vulkan/util/vk_entrypoints_gen.py"
        --xml "${PROJECT_SOURCE_DIR}/src/vulkan/registry/vk.xml" --proto --weak
        --out-h "${_mesa_img_build}/vulkan/pvr_entrypoints.h"
        --out-c "${_mesa_img_build}/vulkan/pvr_entrypoints.c"
        --prefix pvr --device-prefix pvr_rogue --beta false
    DEPENDS
        "${PROJECT_SOURCE_DIR}/src/vulkan/util/vk_entrypoints_gen.py"
        "${PROJECT_SOURCE_DIR}/src/vulkan/util/vk_entrypoints.py"
        "${PROJECT_SOURCE_DIR}/src/vulkan/util/vk_extensions.py"
        "${PROJECT_SOURCE_DIR}/src/vulkan/registry/vk.xml" "${Python3_EXECUTABLE}")

mesa_generate(
    OUTPUT
        "${_mesa_img_build}/vulkan/pvr_drirc.c"
        "${_mesa_img_build}/vulkan/pvr_drirc.h"
    COMMAND
        "${Python3_EXECUTABLE}" "${_mesa_img}/vulkan/pvr_drirc_gen.py"
        --import-path "${PROJECT_SOURCE_DIR}/src/util"
        --drirc-src "${_mesa_img_build}/vulkan/pvr_drirc.c"
        --drirc-hdr "${_mesa_img_build}/vulkan/pvr_drirc.h"
        --validate "${_mesa_img}/vulkan/00-pvr-defaults.conf"
    DEPENDS
        "${_mesa_img}/vulkan/pvr_drirc_gen.py"
        "${_mesa_img}/vulkan/00-pvr-defaults.conf"
        "${PROJECT_SOURCE_DIR}/src/util/drirc_gen.py"
        "${Python3_EXECUTABLE}")

set(MESA_POWERVR_MANIFEST "${_mesa_img_build}/vulkan/powervr_mesa_icd.json")
mesa_generate(
    OUTPUT "${MESA_POWERVR_MANIFEST}"
    COMMAND
        "${Python3_EXECUTABLE}" "${PROJECT_SOURCE_DIR}/src/vulkan/util/vk_icd_gen.py"
        --api-version 1.3 --xml "${PROJECT_SOURCE_DIR}/src/vulkan/registry/vk.xml"
        --sizeof-pointer "${CMAKE_SIZEOF_VOID_P}"
        --icd-lib-path . --icd-filename vulkan_powervr_mesa.dll
        --out "${MESA_POWERVR_MANIFEST}" --use-backslash
    DEPENDS
        "${PROJECT_SOURCE_DIR}/src/vulkan/util/vk_icd_gen.py"
        "${PROJECT_SOURCE_DIR}/src/vulkan/registry/vk.xml" "${Python3_EXECUTABLE}")
