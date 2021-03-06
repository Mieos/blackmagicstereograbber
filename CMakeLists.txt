cmake_minimum_required(VERSION 2.8)

project(blackmagicstereograbber)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -pthread")

#Packages
find_package(CUDA REQUIRED)
find_package(OpenCV REQUIRED)
find_package(Boost COMPONENTS system filesystem REQUIRED)

#Blackmagic
message("BlackMagic package: searching")
if(WIN32)

   message("Using Windows: Not supported ")

   #NOPE FIXME Check Linux version to understand how it works
   #FIND_PATH( BLACKMAGIC_INCLUDE_DIR DeckLinkAPI.h
   #   PATHS "external/blackMagicSDK/Win/include/" )

   #TODO FIXME change that with the correct lib
   #FIND_LIBRARY( BLACKMAGIC_LIBRARY_DIR DeckLinkAPI
   #   PATHS /usr/lib/
   #   /usr/local/lib/
   #   )

   #TODO FIXME same here
   #set(BLACKMAGIC_LIBRARY_EXT_SRC
   #   ${CMAKE_CURRENT_SOURCE_DIR}/external/blackMagicSDK/Win/include/Nope.cpp
   #   )

else (WIN32)
   if(UNIX)
      if(APPLE)
         message("Using Mac : not currently supported")
      else(APPLE)

         message("Using Linux...")
         FIND_PATH( BLACKMAGIC_INCLUDE_DIR DeckLinkAPI.h
            PATHS "external/blackMagicSDK/Linux/include/" )

         FIND_LIBRARY( BLACKMAGIC_LIBRARY_DIR DeckLinkAPI
            PATHS /usr/lib/
            /usr/local/lib/
            )

         set(BLACKMAGIC_LIBRARY_EXT_SRC
            ${CMAKE_CURRENT_SOURCE_DIR}/external/blackMagicSDK/Linux/include/DeckLinkAPIDispatch.cpp
            )

      endif(APPLE)
   else(UNIX)
      message("Using unrecognize OS : not suported")
   endif(UNIX)
endif(WIN32)

set( BLACKMAGIC_FOUND FALSE )
if ( BLACKMAGIC_INCLUDE_DIR AND BLACKMAGIC_LIBRARY_DIR )

   SET ( BLACKMAGIC_FOUND TRUE )
   message("BlackMagic found")

   set(ALL_LIBS
      ${OpenCV_LIBS}
      )

   #include
   include_directories(include)

   #Outputs for tests
   set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)

   #src
   add_subdirectory(src)

else ( BLACKMAGIC_INCLUDE_DIR AND BLACKMAGIC_LIBRARY_DIR )
   message("BlackMagic not found")
   message("Library cannot be used")
endif ( BLACKMAGIC_INCLUDE_DIR AND BLACKMAGIC_LIBRARY_DIR )

