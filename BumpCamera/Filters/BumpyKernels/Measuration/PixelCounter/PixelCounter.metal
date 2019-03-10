//
//  PixelCounter.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 3/10/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct PixelCounterParameters
{
    //0 = count, 1 = return mean, 2 = count pixels in ranges
    int Action;
    int PixelSearchCount;
    //0 = unconditionally count, 1 count if hue +/- offset
    int CountIf;
    float HueOffset;
    int ReturnBufferSize;
    float RangeSize;
};

float4 PCToHSB(float4 Source)
{
    float r = Source.r;
    float g = Source.g;
    float b = Source.b;
    
    float H = 0.0;
    float S = 0.0;
    float B = 0.0;
    
    float MinV = min(r, min(g, b));
    float MaxV = max(r, max(g, b));
    float Delta = MaxV - MinV;
    float Hue = 0.0;
    
    if (Delta != 0)
        {
        if (r == MaxV)
            {
            Hue = (g - b) / Delta;
            }
        else
            if (g == MaxV)
                {
                Hue = 2.0 + ((b - r) / Delta);
                }
            else
                {
                Hue = 4.0 + ((r - g) / Delta);
                }
        
        Hue = Hue * 60.0;
        if (Hue < 0)
            {
            Hue = Hue + 360.0;
            }
        }
    
    float Saturation = MaxV == 0.0 ? 0.0 : (Delta / MaxV);
    float Brightness = MaxV;
    
    H = Hue / 360.0;
    S = Saturation;
    B = Brightness;
    float4 Results = float4(H, S, B, 1.0);
    return Results;
}

kernel void PixelCounter(texture2d<float, access::read> InTexture [[texture(0)]],
                         constant PixelCounterParameters &Parameters [[buffer(0)]],
                         constant float4 *CountFor [[buffer(1)]],
                         device float *ToCPU [[buffer(2)]],
                         uint2 gid [[thread_position_in_grid]])
{
    for (int i = 0; i < Parameters.ReturnBufferSize; i++)
        {
        ToCPU[i] = 0.0;
        }
    
    float RedAccumlator = 0.0;
    float GreenAccumulator = 0.0;
    float BlueAccumulator = 0.0;
    int PixelCount = 0;
    
    for (uint Y = 0; Y < InTexture.get_height(); Y++)
        {
        for(uint X = 0; X < InTexture.get_width(); X++)
            {
            float4 InColor = InTexture.read(uint2(X,Y));
            switch (Parameters.Action)
                {
                    case 0:
                    //count pixels
                    for (int i = 0; i < Parameters.PixelSearchCount; i++)
                        {
                        if (CountFor[i].r == InColor.r && CountFor[i].g == InColor.g && CountFor[i].b == InColor.b)
                            {
                            ToCPU[i] = ToCPU[i] + 1.0;
                            break;
                            }
                        }
                    break;
                    
                    case 1:
                    //get mean pixel value
                    PixelCount = PixelCount + 1;
                    RedAccumlator = RedAccumlator + InColor.r;
                    GreenAccumulator = GreenAccumulator + InColor.g;
                    BlueAccumulator = BlueAccumulator + InColor.b;
                    break;
                    
                    case 2:
                    //count pixels in hue ranges
                    float4 HSB = PCToHSB(InColor);
                    int HueIndex = int(HSB.r / Parameters.RangeSize);
                    ToCPU[HueIndex] = ToCPU[HueIndex] + 1.0;
                }
            }
        }
    
    switch (Parameters.Action)
    {
        case 0:
        break;
        
        case 1:
        ToCPU[0] = float(PixelCount);
        if (PixelCount > 0)
            {
            ToCPU[1] = RedAccumlator;
            ToCPU[2] = GreenAccumulator;
            ToCPU[3] = BlueAccumulator;
            }
        ToCPU[4] = InTexture.get_width();
        ToCPU[5] = InTexture.get_height();
        break;
        
        case 2:
        break;
    }
}
