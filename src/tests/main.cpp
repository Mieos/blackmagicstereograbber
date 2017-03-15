#include <unistd.h>

#include <iostream>

#include "VideoInputFromBlackMagic.hpp"

int main(int argc, char *argv[]){

   std::cout << "Test input" << std::endl;

   //The test
   VideoInputFromBlackMagic* testInput = new VideoInputFromBlackMagic();
   std::thread testInputThread = testInput->run();

   //Start the tests
   namedWindow("Left", cv::WINDOW_AUTOSIZE ); 
   namedWindow("Right", cv::WINDOW_AUTOSIZE );

   cv::Mat cImageL;
   cv::Mat cImageR;
   //Dirty
   while(!testInput->isInitialized()){
   }

   bool endAsk=false;

   while(!endAsk){

      //Get the current image
      testInput->getFrames(cImageL, cImageR);

      //SHOW results !
      cv::imshow("Left", cImageL);
      cv::imshow("Right", cImageR);

      if(cv::waitKey(1)==1048603){
         endAsk=true;
      }

   }

   testInput->stop();
   cv::destroyWindow("Left");
   cv::destroyWindow("Right");

   //End of the thread
   testInputThread.join();

   std::cout << "STOP " << std::endl;

   return 0;
}
