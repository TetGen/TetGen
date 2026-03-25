# Set  the minimum  required version  of cmake  for a  project.
cmake_minimum_required(VERSION 3.6)

include_directories(./)

set(INC
  tetgen.h
)

set(SRC
  tetgen.cxx
  predicates.cxx
)

# Add an executable to the project using the specified source files.
add_executable(tetgen ${INC} ${SRC})

#Add a library to the project using the specified source files. 
# In Linux/Unix, it will creates the libtet.a
#add_library(tet STATIC tetgen.cxx predicates.cxx)

#Set properties on a target. 
#We use this here to set -DTETLIBRARY for when compiling the
#library
#set_target_properties(tet PROPERTIES "COMPILE_DEFINITIONS" TETLIBRARY)