cmake_minimum_required(VERSION 3.22.1)
project(runtimebinding_android_demo C)

get_filename_component(REPOSITORY_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../../../../.." ABSOLUTE)
set(AJNI_ROOT "${REPOSITORY_ROOT}/.mooncakes/Nanaloveyuki/ajni")
if(DEFINED ENV{MOON_HOME})
  set(MOON_HOME "$ENV{MOON_HOME}")
elseif(DEFINED ENV{HOME})
  set(MOON_HOME "$ENV{HOME}/.moon")
elseif(DEFINED ENV{USERPROFILE})
  set(MOON_HOME "$ENV{USERPROFILE}/.moon")
else()
  message(FATAL_ERROR "Set MOON_HOME to the MoonBit toolchain directory.")
endif()
find_program(MOON_EXECUTABLE moon HINTS "${MOON_HOME}/bin" REQUIRED)

# CMake gives each ABI and build variant its own generated MoonBit output.
set(MOON_TARGET_DIR "${CMAKE_CURRENT_BINARY_DIR}/moonbit")
set(MOON_SOURCE "${MOON_TARGET_DIR}/native/release/build/Nanaloveyuki/runtimebinding_android_demo/runtimebinding_android_demo.c")
set(MOON_RUNTIME_SOURCES
  "${MOON_HOME}/lib/runtime/runtime.c"
  "${MOON_HOME}/lib/runtime/utf.c"
  "${MOON_HOME}/lib/runtime/env.c"
  "${MOON_HOME}/lib/runtime/sync_io.c"
  "${MOON_HOME}/lib/runtime/backtrace.c"
)

file(GLOB_RECURSE MOON_INPUTS CONFIGURE_DEPENDS
  "${REPOSITORY_ROOT}/src/*.mbt"
  "${REPOSITORY_ROOT}/src/moon.pkg"
  "${REPOSITORY_ROOT}/src/moon.pkg.json"
  "${REPOSITORY_ROOT}/examples/android/moon/*.mbt"
  "${REPOSITORY_ROOT}/examples/android/moon/moon.pkg"
  "${REPOSITORY_ROOT}/.mooncakes/*.mbt"
  "${REPOSITORY_ROOT}/.mooncakes/*.c"
  "${REPOSITORY_ROOT}/.mooncakes/*.h"
  "${REPOSITORY_ROOT}/.mooncakes/moon.pkg"
  "${REPOSITORY_ROOT}/.mooncakes/moon.pkg.json"
  "${REPOSITORY_ROOT}/.mooncakes/moon.mod"
  "${REPOSITORY_ROOT}/.mooncakes/moon.mod.json"
  "${MOON_HOME}/include/*.h"
  "${MOON_HOME}/lib/core/*.mbt"
  "${MOON_HOME}/lib/core/_build/native/release/bundle/*.mi"
  "${MOON_HOME}/lib/core/_build/native/release/bundle/*.core"
)
list(APPEND MOON_INPUTS
  "${REPOSITORY_ROOT}/moon.work"
  "${REPOSITORY_ROOT}/moon.mod"
  "${REPOSITORY_ROOT}/examples/android/moon.mod"
)
set(MOON_INPUT_MANIFEST "${CMAKE_CURRENT_BINARY_DIR}/moonbit-inputs.txt")
file(CONFIGURE OUTPUT "${MOON_INPUT_MANIFEST}" CONTENT "${MOON_INPUTS}\n" @ONLY)
add_custom_command(
  OUTPUT "${MOON_SOURCE}"
  COMMAND "${MOON_EXECUTABLE}" build --target native --release
    --target-dir "${MOON_TARGET_DIR}" examples/android/moon
  WORKING_DIRECTORY "${REPOSITORY_ROOT}"
  DEPENDS ${MOON_INPUTS} ${MOON_RUNTIME_SOURCES}
    "${MOON_INPUT_MANIFEST}" "${CMAKE_CURRENT_LIST_FILE}"
    "${MOON_EXECUTABLE}" "${MOON_HOME}/bin/moonc"
  COMMENT "Generating MoonBit Android log demo for ${ANDROID_ABI}"
  VERBATIM
)
add_custom_target(generate_moonbit_demo DEPENDS "${MOON_SOURCE}")
set_source_files_properties("${MOON_SOURCE}" PROPERTIES GENERATED TRUE)
add_library(ajni SHARED
  "${MOON_SOURCE}"
  "${AJNI_ROOT}/src/runtime/ajni_runtime.c"
  "${AJNI_ROOT}/src/android/ajni_bridge.c"
  ${MOON_RUNTIME_SOURCES}
)
add_dependencies(ajni generate_moonbit_demo)
target_compile_features(ajni PRIVATE c_std_11)
target_compile_definitions(ajni PRIVATE AJNI_USE_MOONBIT_EXPORTS=1)
target_compile_options(ajni PRIVATE -fwrapv -fno-strict-aliasing -ffp-contract=off)
target_include_directories(ajni PRIVATE "${MOON_HOME}/include")
target_link_libraries(ajni android log m)
