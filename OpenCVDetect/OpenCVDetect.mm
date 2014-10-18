//
//  VidTest.m
//  vidtest
//
//  Created by trolfs on 10/5/14.
//  Copyright (c) 2014 Solder Spot. All rights reserved.
//

#import "OpenCVDetect.h"
#include <opencv2/opencv.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#import "NSImageOpenCV.h"

@interface OpenCVDetect ()
{
    cv::Mat     currentMat;
    int         width;
    int         height;
    BOOL        processingMat;
    
    int         satMinValue;
    int         satMaxValue;
    
    int         volMinValue;
    int         volMaxValue;
    
    int         hueValue;
    int         hueRange;
    
    int         hueMin;
    int         hueMax;
    
    float       scaleInputValue;
    float       radiusCullingRatio;
    float       cullRadiusRatio;
    
    float       captureHz;
    float       processHz;
    float       processTime;
    
    BOOL        enableColorThresholding;
    BOOL        enableNoiseReduction;
    BOOL        enableInputScaling;
    BOOL        enableRadiusCulling;
    BOOL        enableAutoWB;
    BOOL        enableTargetsOnly;
    
    NSTimeInterval  lastCaptureTime;
    NSTimeInterval  lastProcessTime;
    
}

@end

@implementation OpenCVDetect

@synthesize inputView, outputView, startButton, deviceSelect, formatSelect, volMaxLabel, volMaxSlider, volMinLabel, volMinSlider, satMaxSlider, satMaxLabel, satMinLabel, satMinSlider, hueLabel, hueMaxLabel, hueMinLabel, hueRangeSlider, colorSlider, colorWell, outputLabel, inputLabel, scaleInputLabel, scaleInputSlider, colorThresholdingCheck, noiseReductionCheck, adjustWBButton, autoWBCheck, scaleInputCheck, cullRadiusCheck, cullRadiusLabel, cullRadiusSlider, targetsOnlyCheck;

//----------------------------------------
//
//----------------------------------------

-(id) init
{
    self = [super init];
    
    if (self )
    {
        devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        
        satMinValue = 20;
        satMaxValue = 250;
        volMinValue = 25;
        volMaxValue = 250;
        hueValue = 120;
        hueRange = 40;
        scaleInputValue = 0.5f;
        enableColorThresholding = YES;
        enableNoiseReduction = YES;
        enableInputScaling = NO;
        enableRadiusCulling = YES;
        radiusCullingRatio = 0.15;
        enableAutoWB = NO;
        enableTargetsOnly = NO;
    }
    
    return self;
    
}

//----------------------------------------
//
//----------------------------------------

- (void)awakeFromNib
{
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    [deviceSelect removeAllItems];
    [deviceSelect setEnabled:YES];

    [formatSelect removeAllItems];
    [formatSelect setEnabled:NO];
    
    for( AVCaptureDevice *d in devices)
    {
        NSString *title = [d localizedName];
        [deviceSelect addItemWithTitle:title];
        NSMenuItem *item = [deviceSelect itemWithTitle:title];
        [item setRepresentedObject:d];
        if (d == device)
        {
            [deviceSelect selectItem:item];
            [self deviceSelected:deviceSelect];
        }
    }
    
    [satMinSlider setMinValue:0];
    [satMinSlider setMaxValue:255];
    [satMaxSlider setMinValue:0];
    [satMaxSlider setMaxValue:255];
    [satMaxSlider setIntValue:satMaxValue];
    [satMinSlider setIntValue:satMinValue];
    [volMinSlider setMinValue:0];
    [volMinSlider setMaxValue:255];
    [volMaxSlider setMinValue:0];
    [volMaxSlider setMaxValue:255];
    [volMaxSlider setIntValue:volMaxValue];
    [volMinSlider setIntValue:volMinValue];
    [hueRangeSlider setMinValue:0];
    [hueRangeSlider setMaxValue:255];
    [hueRangeSlider setIntValue:hueRange];
    [colorSlider setMaxValue:359];
    [colorSlider setMinValue:0];
    [colorSlider setIntValue:hueValue];
    [scaleInputSlider setMaxValue:100];
    [scaleInputSlider setMinValue:1];
    [scaleInputSlider setIntValue:scaleInputValue*100];
    [colorThresholdingCheck setState:enableColorThresholding];
    [noiseReductionCheck setState:enableNoiseReduction];
    [scaleInputCheck setState:enableInputScaling];
    [targetsOnlyCheck setState:enableTargetsOnly];
    
    [cullRadiusSlider setMaxValue:100];
    [cullRadiusSlider setMinValue:1];
    [cullRadiusSlider setIntValue:radiusCullingRatio*100];
    
    
    [self satMaxChanged:satMaxSlider];
    [self satMinChanged:satMinSlider];
    
    [self volMaxChanged:satMaxSlider];
    [self volMinChanged:satMinSlider];
    
    [self hueRangeChanged:hueRangeSlider];
    [self colorWheelChanged:colorSlider];
    
    [self updateHueControls];
    
    [self scaleInputChanged:scaleInputSlider];
    [self cullRaduisSliderChanged:cullRadiusSlider];
}

//----------------------------------------
//
//----------------------------------------

-(void) processMat
{
    cv::vector<cv::vector<cv::Point> > contours;
    cv::vector<cv::Vec4i> heirarchy;
    cv::vector<cv::Point2i> center;
    cv::vector<int> radius;
    
    processingMat = YES;
    
    // timing
    NSTimeInterval start = CACurrentMediaTime();
    NSTimeInterval delta = (start - lastProcessTime);
    
    cv::cvtColor(currentMat, currentMat, CV_BGR2RGB);
    
    processHz = delta != 0 ? 1.0 / delta : 0 ;
    lastProcessTime = start;

    // update input info
    [inputLabel setStringValue:[NSString stringWithFormat:@"%d x %d @ %.02f", currentMat.cols, currentMat.rows, captureHz]];
    

    // start processing input
    cv::Mat frame = currentMat;
    
    // reduce input size if requested
    if( enableInputScaling && scaleInputValue < 1.0 && scaleInputValue > 0.0)
    {
        cv::resize( frame, frame, cv::Size(), scaleInputValue, scaleInputValue, cv::INTER_NEAREST);
    }
    
    float minDim = (float)(frame.rows > frame.cols ? frame.cols : frame.rows);
    float minTargetRadius = minDim * cullRadiusRatio;

    // do color thresholding if enabled
    if (enableColorThresholding)
    {
        cv::cvtColor(frame, frame, CV_RGB2HSV);
        cv::inRange(frame, cv::Scalar(hueMin, satMinValue, volMinValue), cv::Scalar(hueMax, satMaxValue, volMaxValue), frame);
        
        // apply noise reduction if needed
        if( enableNoiseReduction)
        {
            cv::Mat str_el = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(3, 3));
            morphologyEx(frame, frame, cv::MORPH_OPEN, str_el);
            morphologyEx(frame, frame, cv::MORPH_CLOSE, str_el);
        }
        
        
        cv::findContours( frame.clone(), contours, heirarchy, CV_RETR_TREE, CV_CHAIN_APPROX_NONE);
        
        size_t count = contours.size();
        
        for( int i=0; i<count; i++)
        {
            cv::Point2f c;
            float r;
            cv::minEnclosingCircle( contours[i], c, r);
            
            if (!enableRadiusCulling || r >= minTargetRadius)
            {
                center.push_back(c);
                radius.push_back(r);
            }
        }
        
        
    }
    
    // calc and update output stats
    double end = CACurrentMediaTime();
    delta = end - start;
    [outputLabel setStringValue:[NSString stringWithFormat:@"%d x %d @ %.02f (%.04f ms)", frame.cols, frame.rows, processHz, delta*1000]];

    // display output
    if( enableColorThresholding)
    {
        if (enableTargetsOnly)
        {
            frame =  cv::Scalar(0);
        }
        // convert threshold back to image so we can display it
        cvtColor( frame, frame, CV_GRAY2RGBA);
        
        // draw all the bounding circles
        
        size_t count = center.size();
        
        for( int i = 0; i < count; i++)
        {
            cv::circle(frame, center[i], radius[i], cv::Scalar(255,0,0), 3);
        }
    }
    
    [outputView setImage:[NSImage imageWithCVMat:frame]];
    
    processingMat = NO;
}

//----------------------------------------
//
//----------------------------------------

-(void) stopRecording
{
    if (session)
    {
        [session stopRunning];
        session = nil;
    }
    [startButton setTitle:@"Start"];
    [deviceSelect setEnabled:YES];
    [self deviceSelected:deviceSelect];
}

//----------------------------------------
//
//----------------------------------------

-(BOOL) startRecording
{
    [self stopRecording];
    
    [device lockForConfiguration:nil];
    session = [[AVCaptureSession alloc] init];
    [startButton setTitle:@"Stop"];
    [deviceSelect setEnabled:NO];
    [formatSelect setEnabled:NO];
    
    if ( inputView )
    {
        
        AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
        [inputView setLayer:captureVideoPreviewLayer];
        [inputView setWantsLayer:YES];
    }
    
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (input)
    {
    
        [session addInput:input];
    
        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
        [session addOutput:output];
    
        output.videoSettings = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    
        dispatch_queue_t queue = dispatch_queue_create("MyQueue", NULL);
        [output setSampleBufferDelegate:self queue:queue];
        lastCaptureTime = CACurrentMediaTime();
        lastProcessTime = lastCaptureTime;
        [session startRunning];
        [device unlockForConfiguration];
        
        return YES;
    }

    [self stopRecording];
    return NO;
}

//----------------------------------------
//
//----------------------------------------

-(IBAction) toggleRecording:(id)sender
{
    if( session )
    {
        [self stopRecording];
    }
    else
    {
        [self startRecording];
    }
}

//----------------------------------------
//
//----------------------------------------

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // calculate capture rate
    NSTimeInterval now = CACurrentMediaTime();
    NSTimeInterval delta = (now - lastCaptureTime);
    captureHz = delta != 0 ? 1.0 / delta : 0 ;
    lastCaptureTime = now;

    
    if (processingMat)
    {
        // ignore the frame
        NSLog(@"ignoring frame");
        return;
    }
    
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
    
    int bufferWidth = (int) CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    
    cv::Mat oframe = cv::Mat(bufferHeight,bufferWidth,CV_8UC4,pixel); //put buffer in open cv, no memory copied
    
    currentMat = oframe.clone();
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self processMat];
    });
    
    
    //End processing
    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
}

// GUI Control actions and logic

//----------------------------------------
//
//----------------------------------------

-(void) updateHueControls
{
    [colorWell setColor:[NSColor colorWithHue:((CGFloat)hueValue)/360.0f saturation:1 brightness:.5 alpha:1]];
    [colorSlider setIntValue:hueValue];
    
    hueMin = hueValue - hueRange;
    hueMax = hueValue + hueRange;
    
    hueMin = hueMin < 0 ? 0 : hueMin;
    hueMax = hueMax > 359 ? 359 : hueMax;
    
    [hueMinLabel setStringValue:[NSString stringWithFormat:@"%d", hueMin]];
    [hueMaxLabel setStringValue:[NSString stringWithFormat:@"%d", hueMax]];
    [hueLabel setStringValue:[NSString stringWithFormat:@"%d", hueValue]];
    
    // for OpenCV the values are actually halved
    hueMin /= 2;
    hueMax /= 2;
}

//----------------------------------------
//
//----------------------------------------

-(IBAction)colorThresholdingChanged:(id)sender
{
    enableColorThresholding = [colorThresholdingCheck state];
}

//----------------------------------------
//
//----------------------------------------

-(IBAction)nosieReductionChanged:(id)sender
{
    enableNoiseReduction = [noiseReductionCheck state];
}

//----------------------------------------
//
//----------------------------------------

-(IBAction)targetsOnlyChanged:(id)sender
{
    enableTargetsOnly = [targetsOnlyCheck state];
}

//----------------------------------------
//
//----------------------------------------

-(IBAction)autoWBChanged:(id)sender
{
    
    if( [device lockForConfiguration:nil])
    {
        device.whiteBalanceMode = [autoWBCheck state] ?  AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance : AVCaptureWhiteBalanceModeLocked ;
        [device unlockForConfiguration];
    }
}

//----------------------------------------
//
//----------------------------------------

-(IBAction)adjustWBPressed:(id)sender
{
}

//----------------------------------------
//
//----------------------------------------

-(IBAction)scaleInputButtonChanged:(id)sender
{
    enableInputScaling = [scaleInputCheck state];
}

//----------------------------------------
//
//----------------------------------------

-(IBAction)scaleInputChanged:(id)sender
{
    int val = [scaleInputSlider intValue];
    scaleInputValue = ((float)val)/100.0f;
    [scaleInputLabel setStringValue:[NSString stringWithFormat:@"%d %%", val]];
}

//----------------------------------------
//
//----------------------------------------

-(IBAction)cullRadiusButtonChanged:(id)sender
{
    enableRadiusCulling = [cullRadiusCheck state];
}

//----------------------------------------
//
//----------------------------------------

-(IBAction)cullRaduisSliderChanged:(id)sender
{
    int val = [cullRadiusSlider intValue];
    cullRadiusRatio = ((float)val)/100.0f;
    [cullRadiusLabel setStringValue:[NSString stringWithFormat:@"%d %%", val]];
}

//----------------------------------------
//
//----------------------------------------

-(IBAction)colorWheelChanged:(id)sender
{
    hueValue = [colorSlider intValue];
    [self updateHueControls];
}

//----------------------------------------
//
//----------------------------------------

-(IBAction)colorWellChanged:(id)sender
{
    hueValue = [[colorWell color] hueComponent]*360;
    [self updateHueControls];
}


//----------------------------------------
//
//----------------------------------------

-(IBAction)hueRangeChanged:(id)sender
{
    hueRange = [hueRangeSlider intValue];
    
    [self updateHueControls];
}

//----------------------------------------
//
//----------------------------------------

-(IBAction)satMinChanged:(id)sender
{
    satMinValue = [satMinSlider intValue];
    
    if ([satMaxSlider intValue] < satMinValue )
    {
        [satMaxSlider setIntValue:satMinValue];
        [satMaxLabel setStringValue:[NSString stringWithFormat:@"%d", satMinValue]];
    }
    
    [satMinLabel setStringValue:[NSString stringWithFormat:@"%d", satMinValue]];
}

//----------------------------------------
//
//----------------------------------------

-(IBAction)satMaxChanged:(id)sender
{
    satMaxValue = [satMaxSlider intValue];
    
    if ([satMinSlider intValue] > satMaxValue)
    {
        [satMinSlider setIntValue:satMaxValue];
        [satMinLabel setStringValue:[NSString stringWithFormat:@"%d", satMaxValue]];
    }
    [satMaxLabel setStringValue:[NSString stringWithFormat:@"%d", satMaxValue]];
}

//----------------------------------------
//
//----------------------------------------

-(IBAction)volMinChanged:(id)sender
{
    volMinValue = [volMinSlider intValue];
    
    if ([volMaxSlider intValue] < volMinValue )
    {
        [volMaxSlider setIntValue:volMinValue];
        [volMaxLabel setStringValue:[NSString stringWithFormat:@"%d", volMinValue]];
    }
    
    [volMinLabel setStringValue:[NSString stringWithFormat:@"%d", volMinValue]];
}

//----------------------------------------
//
//----------------------------------------

-(IBAction)volMaxChanged:(id)sender
{
    volMaxValue = [volMaxSlider intValue];
    
    if ([volMinSlider intValue] > volMaxValue)
    {
        [volMinSlider setIntValue:volMaxValue];
        [volMinLabel setStringValue:[NSString stringWithFormat:@"%d", volMaxValue]];
    }
    [volMaxLabel setStringValue:[NSString stringWithFormat:@"%d", volMaxValue]];
}

//----------------------------------------
//
//----------------------------------------

-(IBAction)formatSelected:(id)sender
{
    NSMenuItem *fitem = [formatSelect selectedItem];
    if( [device lockForConfiguration:nil])
    {
        device.activeFormat = fitem.representedObject;
        [device unlockForConfiguration];
    }
}

//----------------------------------------
//
//----------------------------------------

-(IBAction)deviceSelected:(id)sender
{
    [formatSelect removeAllItems];
    
    NSMenuItem *ditem = [deviceSelect selectedItem];
    device = ditem.representedObject;
    
    if( !ditem || !device )
    {
        [formatSelect setEnabled:NO];
        [formatSelect addItemWithTitle:@"No device selected"];
        [adjustWBButton setEnabled:NO];
        return;
    }
    
    [formatSelect setEnabled:YES];
    
    for ( AVCaptureDeviceFormat *format in device.formats )
    {
        NSString *title = format.description;
        [formatSelect addItemWithTitle:title];
        NSMenuItem *fitem = [formatSelect itemWithTitle:title];
        [fitem setRepresentedObject:format];
    }
    
    for ( NSMenuItem *fitem in formatSelect.menu.itemArray )
    {
        AVCaptureDeviceFormat *format = [fitem representedObject];
        AVCaptureDeviceFormat *active = device.activeFormat;
        if (format == active)
        {
            [formatSelect selectItem:fitem];
            [self formatSelected:formatSelect];
            break;
        }
    }
    
    [autoWBCheck setEnabled:[device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]];
    [adjustWBButton setEnabled:[device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]];
    if ( [autoWBCheck isEnabled])
    {
        [self autoWBChanged:autoWBCheck];
    }
}


@end
