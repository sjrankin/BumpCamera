//
//  BlockMean.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 3/18/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct BlockMeanParameters
{
    int Width;
    int Height;
    bool CalculateMean;
};

kernel void BlockMean(texture2d<float, access::read> InTexture [[texture(0)]],
                      constant BlockMeanParameters &Parameters [[buffer(0)]],
                      device float4 *MeanValues [[buffer(1)]],
                      device float *Output [[buffer(2)]],
                      uint2 gid [[thread_position_in_grid]])
{
    if (Parameters.Width % gid.x != 0)
        {
        Output[0] = Output[0] + 1.0;
        return;
        }
    if (Parameters.Height % gid.y != 0)
        {
        Output[1] = Output[1] + 1.0;
        return;
        }
    
    float4 Acc = float4(0.0, 0.0, 0.0, 0.0);
    for (uint X = gid.x; X < gid.x + Parameters.Width; X++)
        {
        for (uint Y = gid.y; Y < gid.y + Parameters.Height; Y++)
            {
            float4 InColor = InTexture.read(uint2(X,Y));
            Acc.r = Acc.r + InColor.r;
            Acc.g = Acc.g + InColor.g;
            Acc.b = Acc.b + InColor.b;
            Acc.a = Acc.a + InColor.a;
            }
        }
    if (Parameters.CalculateMean)
        {
        int PixelCount = Parameters.Width * Parameters.Height;
        Output[3] = float(PixelCount);
        Acc.r = Acc.r / (float)PixelCount;
        Acc.g = Acc.g / (float)PixelCount;
        Acc.b = Acc.g / (float)PixelCount;
        Acc.a = Acc.a / (float)PixelCount;
        }
    int ResultIndex = (gid.y * gid.x) + gid.x;
    Output[4] = float(ResultIndex);
    MeanValues[ResultIndex] = Acc;
    Output[2] = Output[2] + 1.0;
}
