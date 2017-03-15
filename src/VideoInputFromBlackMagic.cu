#include "VideoInputFromBlackMagic.hpp"

// usleep
#include <unistd.h>

#include <stdio.h>

__global__ void separateFramesKernel(unsigned char* bothFrames, unsigned char* rightFrame, unsigned char* leftFrame, int sizeRow){

   const int outputXIndex = blockIdx.x * blockDim.x + threadIdx.x;
   const int outputYIndex = blockIdx.y * blockDim.y + threadIdx.y;

   int output_tid  = outputYIndex * sizeRow + (outputXIndex * 3);
   int output_tid_p1  = (outputYIndex+1) * sizeRow + ((outputXIndex) * 3);
   int output_tid_m1  = (outputYIndex-1) * sizeRow + ((outputXIndex) * 3);

   if(outputYIndex % 2 == 0){
      rightFrame[output_tid] = bothFrames[output_tid];
      rightFrame[output_tid+1] = bothFrames[output_tid+1];
      rightFrame[output_tid+2] = bothFrames[output_tid+2];
      rightFrame[output_tid_p1] = bothFrames[output_tid];
      rightFrame[output_tid_p1+1] = bothFrames[output_tid+1];
      rightFrame[output_tid_p1+2] = bothFrames[output_tid+2];

   } else {
      leftFrame[output_tid_m1] = bothFrames[output_tid];
      leftFrame[output_tid_m1+1] = bothFrames[output_tid+1];
      leftFrame[output_tid_m1+2] = bothFrames[output_tid+2];
      leftFrame[output_tid] = bothFrames[output_tid];
      leftFrame[output_tid+1] = bothFrames[output_tid+1];
      leftFrame[output_tid+2] = bothFrames[output_tid+2];
   }

}

bool VideoInputFromBlackMagic::separateFrames(cv::Mat* left, cv::Mat* right, cv::Mat* combined){

   if(!this->initCuda){
      //Init the array
      this->sizeCurrentImageData = combined->rows * combined->step;
      this->sizeImageRData = right->rows * right->step;
      this->sizeImageLData = left->rows * left->step;
      cudaMalloc((void **) &this->currentImageDevice, this->sizeCurrentImageData);
      cudaMalloc((void **) &this->ImageRightDevice, this->sizeImageRData);
      cudaMalloc((void **) &this->ImageLeftDevice, this->sizeImageLData);
      this->initCuda = true;
   }

   cudaMemcpy(this->currentImageDevice, combined->ptr(), this->sizeCurrentImageData, cudaMemcpyHostToDevice) ;
   cudaMemcpy(this->ImageRightDevice, right->ptr(), this->sizeImageRData, cudaMemcpyHostToDevice) ;
   cudaMemcpy(this->ImageLeftDevice, left->ptr(), this->sizeImageLData, cudaMemcpyHostToDevice) ;

   //Specify a reasonable block size
   const dim3 block(16,16);

   //Grid
   const dim3 grid((combined->cols + block.x - 1)/block.x, (combined->rows + block.y - 1)/block.y);

   //Call the kernel
   separateFramesKernel<<<grid,block>>>(this->currentImageDevice, this->ImageRightDevice, this->ImageLeftDevice, combined->step);

   cudaDeviceSynchronize();
   cudaMemcpy(right->ptr(),this->ImageRightDevice,this->sizeImageRData,cudaMemcpyDeviceToHost);
   cudaMemcpy(left->ptr(),this->ImageLeftDevice,this->sizeImageLData,cudaMemcpyDeviceToHost);

   return true;
}

//Constructor
VideoInputFromBlackMagic::VideoInputFromBlackMagic(): m_refCount(1){

   this->running = false;
   this->initialized = false;
   this->initCuda = false;

}

//Destructor
//TODO FREE CUDA MEMORY
VideoInputFromBlackMagic::~VideoInputFromBlackMagic(){

}

//Run call
std::thread VideoInputFromBlackMagic::run(){
   printf("VideoInputFromBlackMagic : run function has been called...\n");
   std::thread mainThread(runThread, this);
   return mainThread;
}

//Run sub function
void VideoInputFromBlackMagic::runThread(VideoInputFromBlackMagic* context){
   context->runInput();
}

//Run (real stuff)
void VideoInputFromBlackMagic::runInput(){

   fprintf(stdout, "Run\n");

   if(!this->running){

      this->running=true;

      int idx;

      //Check result
      HRESULT result;

      IDeckLink* deckLink = NULL;
      IDeckLinkInput* g_deckLinkInput = NULL;
      IDeckLinkAttributes* deckLinkAttributes = NULL;
      IDeckLinkIterator* deckLinkIterator = CreateDeckLinkIteratorInstance();
      IDeckLinkDisplayModeIterator* displayModeIterator = NULL;
      IDeckLinkDisplayMode* displayMode = NULL;

      char* displayModeName = NULL;
      BMDDisplayModeSupport displayModeSupported;
      bool formatDetectionSupported;

      if (!deckLinkIterator)
      {
         fprintf(stderr, "This application requires the DeckLink drivers installed.\n");
         return;
      } 

      //Get the DeckLink Inputs
      result = deckLinkIterator->Next(&deckLink);
      result = deckLink->QueryInterface(IID_IDeckLinkInput, (void**)&g_deckLinkInput);

      if(result != S_OK){
         fprintf(stdout, "Cannot get the Input : DeckLink Error\n");
         return;
      } 

      //Get the DeckLink attributes (that may not correctly work: format detection does not properly work)
      result = deckLink->QueryInterface(IID_IDeckLinkAttributes, (void**)&deckLinkAttributes);

      if (!(result == S_OK)){
         fprintf(stdout, "Cannot get the DeckLink attributes : DeckLink Error\n");
         return;
      }

      //Format detection
      result = deckLinkAttributes->GetFlag(BMDDeckLinkSupportsInputFormatDetection, &formatDetectionSupported);
      if (result != S_OK || !formatDetectionSupported){
         fprintf(stdout,"Cannot get the format input: DeckLink Error\n");
         return;
      } 

      //Index for the different inputs
      idx = 0;

      //Get all the displayModes
      result = g_deckLinkInput->GetDisplayModeIterator(&displayModeIterator);

      if (result != S_OK){
         fprintf(stdout,"Cannot set an iterator on the different display modes: DeckLink Error\n");
      }

      //Set idx
      while ((result = displayModeIterator->Next(&displayMode)) == S_OK)
      {

         if (idx == 0)
            break;
         --idx;   
         displayMode->Release();

      }

      if (result != S_OK || displayMode == NULL){

         fprintf(stdout,"Cannot get the main display mode: DeckLink Error\n");
         return;

      } 

      //Get Mode name: useless
      result = displayMode->GetName((const char**)&displayModeName);

      // Check display mode is supported with given options
      result = g_deckLinkInput->DoesSupportVideoMode(bmdModeHD1080p30, bmdFormat8BitYUV, bmdDisplayModeColorspaceRec709, &displayModeSupported, NULL);

      if (result != S_OK){
         fprintf(stdout,"Video Mode not supported : aborted\n");
         return;
      } 


      if (displayModeSupported == bmdDisplayModeNotSupported)
      {
         fprintf(stdout, "The display mode %s is not supported with the selected pixel format\n", displayModeName);
         return;

      } 

      //Set the callback on this ( will defined callback on VideoInputFrameArrived and others functions when images arrives or when other events happens
      g_deckLinkInput->SetCallback(this);

      //Enable the video input with the selected format
      result = g_deckLinkInput->EnableVideoInput(bmdModeHD1080p30, bmdFormat8BitYUV, bmdDisplayModeColorspaceRec709);


      if (result != S_OK)
      {
         fprintf(stderr, "Failed to enable video input. Maybe another application is using the card.\n");
         return;

      } 

      //Disable the audio
      result = g_deckLinkInput->DisableAudioInput();

      //Start the stream
      result = g_deckLinkInput->StartStreams();
      if (result != S_OK){
         fprintf(stdout,"Error while starting the streaming : aborted\n");
      }

      while(this->running){
         //Nothing thread must not end... this is dirty TODO mutex?
      }

   }

}

//A frame arrived
HRESULT VideoInputFromBlackMagic::VideoInputFrameArrived(IDeckLinkVideoInputFrame* videoFrame, IDeckLinkAudioInputPacket* audioFrame){

   //Here a good idea can be to ignore frames sometimes..

   if (!videoFrame){

      fprintf(stdout,"Update: No video frame\n");
      return S_FALSE;

   } 

   void* data;

   if (FAILED(videoFrame->GetBytes(&data))){
      fprintf(stdout,"Fail obtaining the data from videoFrame\n");
      return S_FALSE;
   }

   cv::Mat loadedImage;
   cv::Mat mat = cv::Mat(videoFrame->GetHeight(), videoFrame->GetWidth(), CV_8UC2, data, videoFrame->GetRowBytes());
   cv::cvtColor(mat, loadedImage, CV_YUV2BGR_UYVY);
   cv::Mat loadedImageRight = cv::Mat::zeros(loadedImage.rows,loadedImage.cols, loadedImage.type());
   cv::Mat loadedImageLeft = cv::Mat::zeros(loadedImage.rows,loadedImage.cols, loadedImage.type()) ;

   if (!loadedImage.data){
      fprintf(stdout,"No frame loaded from the video : mainImage will not be updated\n");
   } else {

      if(!this->separateFrames(&loadedImageLeft, &loadedImageRight, &loadedImage)){
         fprintf(stdout,"Error while the separation of left and right frame\n");
      }

      //Update the images
      //Mutex here
      this->mtxImages.lock();
      this->currentImageLeft = loadedImageLeft.clone();
      this->currentImageRight = loadedImageRight.clone();
      this->initialized = true;
      this->mtxImages.unlock();

   }

   return S_OK;

}

//DeckLink stuff: not important
ULONG VideoInputFromBlackMagic::AddRef(void)
{
   return __sync_add_and_fetch(&m_refCount, 1);
}

ULONG VideoInputFromBlackMagic::Release(void)
{
   int32_t newRefValue = __sync_sub_and_fetch(&m_refCount, 1);
   if (newRefValue == 0)
   {
      return 0;
   }
   return newRefValue;
}

HRESULT VideoInputFromBlackMagic::VideoInputFormatChanged(BMDVideoInputFormatChangedEvents events, IDeckLinkDisplayMode *mode, BMDDetectedVideoInputFormatFlags formatFlags){

   fprintf(stdout,"VideoInputFormatChanged: Not supported\n");   
   return S_OK;

}

//Stop TODO unlock mutex
void VideoInputFromBlackMagic::stop(){
   this->running=false;
}

bool VideoInputFromBlackMagic::isRunning(){
   return this->running;
}

bool VideoInputFromBlackMagic::isInitialized(){
   return this->initialized;
}

void VideoInputFromBlackMagic::getFrames(cv::Mat & leftI, cv::Mat & rightI){

   this->mtxImages.lock();
   leftI = this->currentImageLeft.clone();
   rightI = this->currentImageRight.clone();
   this->mtxImages.unlock();

}
