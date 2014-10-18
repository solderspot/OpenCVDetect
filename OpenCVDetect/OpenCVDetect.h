//
//  VidTest.h
//  vidtest
//
//  Created by trolfs on 10/5/14.
//  Copyright (c) 2014 Solder Spot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <AVFoundation/AVFoundation.h>

//----------------------------------------
//
//----------------------------------------

@interface OpenCVDetect : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    NSArray                 *devices;
    AVCaptureDevice         *device;
    AVCaptureSession        *session;
    
    NSView                  *intputView;
    NSImageView             *outputView;
    NSButton                *startButton;
    
    // device
    NSPopUpButton           *deviceSelect;
    NSPopUpButton           *formatSelect;
    NSButton                *adjustWBButton;
    NSButton                *autoWBCheck;
    
    // image info
    NSTextField             *inputLabel;
    NSTextField             *outputLabel;

    // hue range
    NSSlider                *hueRangeSlider;
    NSTextField             *hueMinLabel;
    NSTextField             *hueMaxLabel;

    // saturation range
    NSSlider                *satMinSlider;
    NSSlider                *satMaxSlider;
    NSTextField             *satMinLabel;
    NSTextField             *satMaxLabel;
    
    // volume range
    NSSlider                *volMinSlider;
    NSSlider                *volMaxSlider;
    NSTextField             *volMinLabel;
    NSTextField             *volMaxLabel;

    // color chooser
    NSColorWell             *colorWell;
    NSSlider                *colorSlider;
    NSTextField             *hueLabel;
    
    // scale input
    NSButton                *scaleInputCheck;
    NSSlider                *scaleInputSlider;
    NSTextField             *scaleInputLabel;
    
    // cull targets
    NSButton                *cullRadiusCheck;
    NSSlider                *cullRadiusSlider;
    NSTextField             *cullRadiusLabel;

    NSButton                *colorThresholdingCheck;
    NSButton                *noiseReductionCheck;
    NSButton                *targetOnlyCheck;
}

@property (nonatomic, strong ) IBOutlet NSView *inputView;
@property (nonatomic, strong ) IBOutlet NSImageView *outputView;
@property (nonatomic, strong ) IBOutlet NSButton *startButton;
@property (nonatomic, strong ) IBOutlet NSPopUpButton *deviceSelect;
@property (nonatomic, strong ) IBOutlet NSPopUpButton *formatSelect;
@property (nonatomic, strong ) IBOutlet NSTextField *inputLabel;
@property (nonatomic, strong ) IBOutlet NSTextField *outputLabel;
@property (nonatomic, strong ) IBOutlet NSSlider *hueRangeSlider;
@property (nonatomic, strong ) IBOutlet NSTextField *hueMinLabel;
@property (nonatomic, strong ) IBOutlet NSTextField *hueMaxLabel;
@property (nonatomic, strong ) IBOutlet NSSlider *satMinSlider;
@property (nonatomic, strong ) IBOutlet NSSlider *satMaxSlider;
@property (nonatomic, strong ) IBOutlet NSTextField *satMinLabel;
@property (nonatomic, strong ) IBOutlet NSTextField *satMaxLabel;
@property (nonatomic, strong ) IBOutlet NSSlider *volMinSlider;
@property (nonatomic, strong ) IBOutlet NSSlider *volMaxSlider;
@property (nonatomic, strong ) IBOutlet NSTextField *volMinLabel;
@property (nonatomic, strong ) IBOutlet NSTextField *volMaxLabel;
@property (nonatomic, strong ) IBOutlet NSColorWell *colorWell;
@property (nonatomic, strong ) IBOutlet NSSlider *colorSlider;
@property (nonatomic, strong ) IBOutlet NSTextField *hueLabel;
@property (nonatomic, strong ) IBOutlet NSButton *scaleInputCheck;
@property (nonatomic, strong ) IBOutlet NSSlider *scaleInputSlider;
@property (nonatomic, strong ) IBOutlet NSTextField *scaleInputLabel;
@property (nonatomic, strong ) IBOutlet NSButton *colorThresholdingCheck;
@property (nonatomic, strong ) IBOutlet NSButton *noiseReductionCheck;

@property (nonatomic, strong ) IBOutlet NSSlider *cullRadiusSlider;
@property (nonatomic, strong ) IBOutlet NSTextField *cullRadiusLabel;
@property (nonatomic, strong ) IBOutlet NSButton *cullRadiusCheck;

@property (nonatomic, strong ) IBOutlet NSButton *autoWBCheck;
@property (nonatomic, strong ) IBOutlet NSButton *adjustWBButton;
@property (nonatomic, strong ) IBOutlet NSButton *targetsOnlyCheck;


-(IBAction) toggleRecording:(id)sender;

-(id) init;

@end
