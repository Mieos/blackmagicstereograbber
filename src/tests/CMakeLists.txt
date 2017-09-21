add_executable(run main.cpp)
target_link_libraries(run
   blackmagicstereograbber_LIB   
   )

add_executable(runMono mainMono.cpp)
target_link_libraries(runMono
   blackmagicstereograbber_LIB   
   )

add_executable(runSaveImages mainSaveImages.cpp)
target_link_libraries(runSaveImages
   blackmagicstereograbber_LIB  
   ${Boost_FILESYSTEM_LIBRARY}
   ${Boost_SYSTEM_LIBRARY}
   )

add_executable(runSaveImagesInterval mainSaveImagesV.cpp)
target_link_libraries(runSaveImagesInterval
   blackmagicstereograbber_LIB  
   ${Boost_FILESYSTEM_LIBRARY}
   ${Boost_SYSTEM_LIBRARY}
   )
