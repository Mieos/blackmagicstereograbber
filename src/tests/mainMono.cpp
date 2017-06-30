#include <unistd.h>

#include <iostream>

#include "VideoInputFromBlackMagic.hpp"

int main(int argc, char *argv[]){

   std::cout << "Test input" << std::endl;

   //The test
   VideoInputFromBlackMagic* testInput = new VideoInputFromBlackMagic(false);
   std::thread testInputThread = testInput->run();

   //Start the tests
   namedWindow("Image", cv::WINDOW_AUTOSIZE ); 

   cv::Mat cImage;

   //Dirty
   while(!testInput->isInitialized()){
   }

   bool endAsk=false;

   while(!endAsk){

      //Get the current image
      testInput->getFrames(cImage);
      
      //SHOW results !
      cv::imshow("Image", cImage);

      if(cv::waitKey(100)==1048603){
         endAsk=true;
      }

   }

   testInput->stop();
   cv::destroyWindow("Image");

   //End of the thread
   testInputThread.join();

   std::cout << "STOP " << std::endl;

   return 0;
}
