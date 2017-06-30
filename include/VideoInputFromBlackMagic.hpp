#include <string>

// Threading
#include <thread>

#include <opencv2/opencv.hpp>
#include <DeckLinkAPI.h>

#include <mutex>

class VideoInputFromBlackMagic : public IDeckLinkInputCallback {

private:
 
   //IDeckLink
   int32_t m_refCount;
   
   //The left and right frames
   cv::Mat currentImageLeft;
   cv::Mat currentImageRight;

   //Cuda stuffs
   unsigned char* currentImageDevice;
   unsigned char* ImageRightDevice;
   unsigned char* ImageLeftDevice;
   unsigned sizeCurrentImageData;
   unsigned sizeImageRData;
   unsigned sizeImageLData;
   bool initCuda;

   //Function that call cuda kernels in order to separate the frame
   bool separateFrames(cv::Mat* left, cv::Mat* right, cv::Mat* combined);

   //Initialized
   bool initialized;

   //Running subfunction
   bool running;
   void runInput();
   static void runThread(VideoInputFromBlackMagic* context);

   //Mutex
   std::mutex mtxImages;
   bool updating;

   bool isStereo;

public:

   //Constructor & destructors
   VideoInputFromBlackMagic();
   //Dirty but for now, it will stay like that
   VideoInputFromBlackMagic(bool istereo);
   ~VideoInputFromBlackMagic();

   //Running function
   std::thread run();

   //Stop
   void stop();
   bool isRunning();
   bool isInitialized();

   //Get frames
   void getFrames(cv::Mat & leftI, cv::Mat & rightI);
   void getFrames(cv::Mat & leftI);

   virtual HRESULT STDMETHODCALLTYPE VideoInputFrameArrived(IDeckLinkVideoInputFrame*, IDeckLinkAudioInputPacket*);
   virtual HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, LPVOID *ppv) { return E_NOINTERFACE; }
   virtual ULONG STDMETHODCALLTYPE AddRef(void);
   virtual ULONG STDMETHODCALLTYPE  Release(void);
   virtual HRESULT STDMETHODCALLTYPE VideoInputFormatChanged(BMDVideoInputFormatChangedEvents, IDeckLinkDisplayMode*, BMDDetectedVideoInputFormatFlags);

};
