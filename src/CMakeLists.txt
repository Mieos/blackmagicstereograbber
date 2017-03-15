include_directories(${BLACKMAGIC_INCLUDE_DIR})

cuda_add_library(blackmagicstereograbber_LIB VideoInputFromBlackMagic.cu OPTIONS -lcuda -lcudart )
target_link_libraries(blackmagicstereograbber_LIB ${OpenCV_LIBS} ${BLACKMAGIC_LIBRARY_DIR})

add_subdirectory(tests)
