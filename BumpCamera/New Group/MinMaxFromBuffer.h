//
//  MinMaxFromBuffer.h
//  BumpCamera
//
//  Created by Stuart Rankin on 1/20/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#ifndef MinMaxFromBuffer_h
#define MinMaxFromBuffer_h

#import <CoreVideo/CoreVideo.h>
#import <Metal/Metal.h>

void minMaxFromPixelBuffer(CVPixelBufferRef pixelBuffer, float* minValue, float* maxValue, MTLPixelFormat pixelFormat);

#endif /* MinMaxFromBuffer_h */
