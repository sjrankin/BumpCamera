//
//  ColorMap2.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 3/10/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ColorMapParameters
{
    bool InvertGradientDirection;
    bool InvertGradientValues;
};

struct GradientTable
{
    float4 Values[256];
};

kernel void ColorMap2(texture2d<float, access::read> InTexture [[texture(0)]],
                           texture2d<float, access::write> OutTexture [[texture(1)]],
                           constant ColorMapParameters &Parameters [[buffer(0)]],
                           constant GradientTable &Gradient [[buffer(1)]],
                           device float *ToCPU [[buffer(2)]],
                           uint2 gid [[thread_position_in_grid]])
{
    float4 InColor = InTexture.read(gid);
    
    float Mean = (InColor.r + InColor.g + InColor.b) / 3.0;
    if (Parameters.InvertGradientValues)
        {
        Mean = 1.0 - Mean;
        }
    int GradientIndex = int(Mean * 255.0);
    if (Parameters.InvertGradientDirection)
        {
        GradientIndex = 255 - GradientIndex;
        }
    
    OutTexture.write(Gradient.Values[GradientIndex], gid);
}
