add_executable(run main.cpp)
target_link_libraries(run
   blackmagicstereograbber_LIB   
   )

add_executable(runMono mainMono.cpp)
target_link_libraries(runMono
   blackmagicstereograbber_LIB   
   )

