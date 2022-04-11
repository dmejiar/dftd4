# This file is part of dftd4.
# SPDX-Identifier: LGPL-3.0-or-later
#
# dftd4 is free software: you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# dftd4 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with dftd4.  If not, see <https://www.gnu.org/licenses/>.

function(check_blas)
set(CMAKE_REQUIRED_FLAGS)
set(CMAKE_REQUIRED_LINK_OPTIONS)
set(CMAKE_REQUIRED_INCLUDES)
set(CMAKE_REQUIRED_LIBRARIES ${LAPACK_LIBRARIES})
check_fortran_source_compiles("
      program check_blas
      implicit none (type, external)
      external :: dgemm
      end program" BLAS_links)
set(BLAS_links ${BLAS_links} PARENT_SCOPE)
endfunction(check_blas)


if(NOT BLAS_FOUND)

  # Safeguard in case a vendor was specified
  if(BLA_VENDOR MATCHES "_64ilp")
    if(NOT WITH_ILP64)
      message(STATUS "BLA_VENDOR ${BLA_VENDOR} uses 64-bit integers. Setting WITH_ILP64")
      set(WITH_ILP64 ON PARENT_SCOPE)
    endif()
  endif()

  # ILP64 check
  if (WITH_ILP64 AND (NOT LAPACK_LIBRARIES))
    if(NOT ((BLA_VENDOR MATCHES "_64ilp") OR (BLA_VENDOR MATCHES "_dyn")))
      if(CMAKE_VERSION VERSION_LESS "3.22")
        message(FATAL_ERROR
          "Use of WITH_ILP64 with CMAKE_VERSION < 3.22 requires user to set BLA_VENDOR to a valid ilp64 provider or to set LAPACK_LIBRARIES")
      elseif(NOT BLA_SIZEOF_INTEGER EQUAL 8)
        set(BLA_SIZEOF_INTEGER 8 FORCE)
      endif()
    endif()
  endif()

  if(LAPACK_LIBRARIES)
    # Check if BLAS links with the same set of libraries
    if(NOT TARGET BLAS::BLAS)
      check_blas()
      if(BLAS_links)
        set (BLAS_links ${BLAS_links})
        add_library(BLAS::BLAS INTERFACE IMPORTED)
        set_target_properties(BLAS::BLAS PROPERTIES
          INTERFACE_LINK_LIBRARIES "${LAPACK_LIBRARIES}")
      else()
        message(FATAL_ERROR "Custom LAPACK library must contain BLAS")
      endif()
    endif()

    set(BLAS_FOUND TRUE)

  else()

    find_package("BLAS")
    if(NOT TARGET "BLAS::BLAS")
      add_library("BLAS::BLAS" INTERFACE IMPORTED)
      target_link_libraries("BLAS::BLAS" INTERFACE "${BLAS_LIBRARIES}")
    endif()
  endif()
endif()
