#include <unistd.h>

#include <iostream>
#include <boost/filesystem.hpp>

#include "VideoInputFromBlackMagic.hpp"

#include <chrono>

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

   std::string saveFolder = "imageSetV";
   boost::filesystem::path dir(saveFolder.c_str());
   if(boost::filesystem::create_directory(dir)) {
      std::cout << "A new folder has been created for the pictures : " << saveFolder << "\n";
   } else {
      std::cout << "Folder already existing" << std::endl;
   }

   int waitkeyNum = -1;
   std::cout << "Print c to save image" << std::endl;

   size_t numImage = 0;
   std::string imageNameR, imageNameL;


   std::chrono::time_point<std::chrono::system_clock> start0, end0;
   float elapsed_ms_0;


   bool startRecord = false;

   while(!endAsk){

      //Get the current image
      testInput->getFrames(cImageL, cImageR);

      if(startRecord){

         end0 = std::chrono::system_clock::now();
         elapsed_ms_0 = std::chrono::duration_cast<std::chrono::milliseconds>(end0-start0).count();

         if(elapsed_ms_0>1000){
            start0 = std::chrono::system_clock::now();
            numImage++;
            imageNameL= saveFolder + "/left/img" + std::to_string(numImage) + ".png";
            imageNameR= saveFolder + "/right/img" + std::to_string(numImage) + ".png";
            imwrite(imageNameL.c_str(), cImageL );
            imwrite(imageNameR.c_str(), cImageR );
            std::cout << "Images Saved : " << numImage << std::endl;

         }

      }
      //SHOW results !
      cv::imshow("Left", cImageL);
      cv::imshow("Right", cImageR);

      waitkeyNum = cv::waitKey(100);

      if(waitkeyNum==1048603){
         endAsk=true;
      } else if(waitkeyNum==1048675){ //"c"
         startRecord=true;
         start0 = std::chrono::system_clock::now();
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
