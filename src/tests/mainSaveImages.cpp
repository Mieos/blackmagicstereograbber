#include <unistd.h>

#include <iostream>
#include <boost/filesystem.hpp>

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

   std::string saveFolder = "imagesSet";
   boost::filesystem::path dir(saveFolder.c_str());
   if(boost::filesystem::create_directory(dir)) {
      std::cout << "A new folder has been created for the pictures : " << saveFolder "\n";
   } else {
      std::cout << "Folder already existing" << std::endl;
   }

   int waitkeyNum = -1;
   std::cout << "Print c to save image" << std::endl;

   size_t numImage = 0;
   std::string imageNameR, imageNameL;

   while(!endAsk){

      //Get the current image
      testInput->getFrames(cImageL, cImageR);

      //SHOW results !
      cv::imshow("Left", cImageL);
      cv::imshow("Right", cImageR);

      waitkeyNum = cv::waitKey(100);
      
      if(waitkeyNum==1048603){
         endAsk=true;
      } else if(waitkeyNum==1048675){ //"c"
         numImage++;
         imageNameL= saveFolder + "/img_left_" + std::to_string(numImage) + ".png";
         imageNameR= saveFolder + "/img_right_" + std::to_string(numImage) + ".png";
         imwrite(imageNameL.c_str(), cImageL );
         imwrite(imageNameR.c_str(), cImageR );
         std::cout << "Images Saved : " << numImage << std::endl;
         cv::imshow(imageNameL.c_str(), cImageL);
         cv::imshow(imageNameR.c_str(), cImageR);
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
