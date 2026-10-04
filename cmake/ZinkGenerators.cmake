# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 Ahmed ARIF <arif.ing@outlook.com>
# Generator graph for the Zink Gallium driver.

set(_mesa_zink "${PROJECT_SOURCE_DIR}/src/gallium/drivers/zink")
set(_mesa_zink_build "${PROJECT_BINARY_DIR}/src/gallium/drivers/zink")
set(_mesa_zink_vk_xml "${PROJECT_SOURCE_DIR}/src/vulkan/registry/vk.xml")

foreach(_mesa_zink_gen device_info instance)
    mesa_generate(
        OUTPUT
            "${_mesa_zink_build}/zink_${_mesa_zink_gen}.h"
            "${_mesa_zink_build}/zink_${_mesa_zink_gen}.c"
        COMMAND
            "${Python3_EXECUTABLE}" "${_mesa_zink}/zink_${_mesa_zink_gen}.py"
            "${_mesa_zink_build}/zink_${_mesa_zink_gen}.h"
            "${_mesa_zink_build}/zink_${_mesa_zink_gen}.c"
            "${_mesa_zink_vk_xml}"
        DEPENDS
            "${_mesa_zink}/zink_${_mesa_zink_gen}.py"
            "${_mesa_zink}/zink_extensions.py"
            "${_mesa_zink_vk_xml}" "${Python3_EXECUTABLE}")
endforeach()

mesa_generate(
    OUTPUT "${_mesa_zink_build}/zink_nir_algebraic.c"
    CAPTURE "${_mesa_zink_build}/zink_nir_algebraic.c"
    COMMAND
        "${Python3_EXECUTABLE}" "${_mesa_zink}/nir_to_spirv/zink_nir_algebraic.py"
        -p "${PROJECT_SOURCE_DIR}/src/compiler/nir/"
    DEPENDS
        "${_mesa_zink}/nir_to_spirv/zink_nir_algebraic.py"
        "${PROJECT_SOURCE_DIR}/src/compiler/nir/nir_algebraic.py"
        "${PROJECT_SOURCE_DIR}/src/compiler/nir/nir_opcodes.py"
        "${Python3_EXECUTABLE}")
