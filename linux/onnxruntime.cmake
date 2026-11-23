# ONNX Runtime for flutter_onnxruntime (page translation's OCR).
#
# The plugin downloads ONNX Runtime from github.com/microsoft/onnxruntime
# releases, which answer 404. Microsoft's NuGet package has the same build:
# this lays it out where the plugin looks
# (<build>/plugins/flutter_onnxruntime/onnxruntime/onnxruntime-linux-<arch>-<v>),
# so the plugin finds it and skips its download. Included before the plugins.
#
# The library's SONAME is libonnxruntime.so.1 while the plugin bundles it as
# libonnxruntime.so: ORT_SONAME_COPY is installed beside it (see
# CMakeLists.txt) so the app finds it at run time.

set(ONNXRUNTIME_VERSION "1.28.0")
set(USE_SYSTEM_ONNXRUNTIME OFF CACHE BOOL "" FORCE)

if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
  set(_ort_arch "x64")
  set(_ort_runtime "linux-x64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
  set(_ort_arch "aarch64")
  set(_ort_runtime "linux-arm64")
else()
  message(FATAL_ERROR "No ONNX Runtime for ${CMAKE_SYSTEM_PROCESSOR}")
endif()

set(_ort_dir "${CMAKE_BINARY_DIR}/plugins/flutter_onnxruntime/onnxruntime/onnxruntime-linux-${_ort_arch}-${ONNXRUNTIME_VERSION}")
set(ORT_SONAME_COPY "${_ort_dir}/lib/libonnxruntime.so.1")
if(NOT EXISTS "${_ort_dir}/include/onnxruntime_cxx_api.h")
  set(_ort_pkg "${CMAKE_BINARY_DIR}/onnxruntime-${ONNXRUNTIME_VERSION}.nupkg")
  set(_ort_url "https://api.nuget.org/v3-flatcontainer/microsoft.ml.onnxruntime/${ONNXRUNTIME_VERSION}/microsoft.ml.onnxruntime.${ONNXRUNTIME_VERSION}.nupkg")
  message(STATUS "Downloading ONNX Runtime ${ONNXRUNTIME_VERSION} from NuGet")
  file(DOWNLOAD "${_ort_url}" "${_ort_pkg}" STATUS _ort_status TLS_VERIFY ON)
  list(GET _ort_status 0 _ort_code)
  if(NOT _ort_code EQUAL 0)
    message(FATAL_ERROR "Could not download ONNX Runtime from ${_ort_url}: ${_ort_status}")
  endif()

  set(_ort_unpacked "${CMAKE_BINARY_DIR}/onnxruntime-nuget")
  file(REMOVE_RECURSE "${_ort_unpacked}")
  file(MAKE_DIRECTORY "${_ort_unpacked}")
  execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar xf "${_ort_pkg}"
    WORKING_DIRECTORY "${_ort_unpacked}"
    RESULT_VARIABLE _ort_tar)
  if(NOT _ort_tar EQUAL 0)
    message(FATAL_ERROR "Could not unpack ${_ort_pkg}")
  endif()

  file(MAKE_DIRECTORY "${_ort_dir}/lib")
  file(COPY "${_ort_unpacked}/build/native/include/" DESTINATION "${_ort_dir}/include")
  set(_ort_so "${_ort_unpacked}/runtimes/${_ort_runtime}/native/libonnxruntime.so")
  configure_file("${_ort_so}" "${_ort_dir}/lib/libonnxruntime.so" COPYONLY)
  configure_file("${_ort_so}" "${ORT_SONAME_COPY}" COPYONLY)
  file(REMOVE_RECURSE "${_ort_unpacked}")
  file(REMOVE "${_ort_pkg}")
endif()
