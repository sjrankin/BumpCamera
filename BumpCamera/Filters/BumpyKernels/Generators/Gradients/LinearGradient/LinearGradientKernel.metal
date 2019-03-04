//
//  LinearGradientKernel.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 3/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// Gradient stop structure.
struct GradientColorStop
{
    float4 Color;
    float Location;
};


struct GradientParameters
{
    uint GradientStopCount;
    float4 Background;
    bool IsHorizontal;
    float ImplicitOffset1;
    float ImplicitOffset2;
};

kernel void LinearGradientKernel(texture2d<float, access::read> NotUsed [[texture(0)]],
                                 texture2d<float, access::write> OutTexture [[texture(1)]],
                                 constant GradientColorStop *ColorStops [[buffer(0)]],
                                 constant GradientParameters &Parameters [[buffer(1)]],
                                 device float *Results [[buffer(2)]],
                                 uint2 gid [[thread_position_in_grid]])
{
    float4 OutPixel = float4(0.0, 0.0, 0.0, 1.0);
    
    if (Parameters.IsHorizontal)
        {
        
        }
    else
        {
        
        }
}
