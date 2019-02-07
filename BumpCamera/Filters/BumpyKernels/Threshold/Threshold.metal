//
//  Threshold.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 2/7/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ThresholdParameters
{
    float ThresholdValue;
    //Determines what is compared to the threshold value. 0 = pixel hue, 1 = pixel saturation, 2 = pixel brightness,
    //3 = red channel, 4 = green channel, 5 = blue channel, 6 = cyan channel, 7 = magenta channel, 8 = yellow channel,
    //9 = black channel
    uint ThresholdInput;
    bool ApplyIfHigher;
    float4 LowColor;
    float4 HighColor;
};


float4 ToHSB_ForThreshold(float4 Source)
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

kernel void ThresholdKernel(texture2d<float, access::read> InTexture [[texture(0)]],
                            texture2d<float, access::write> OutTexture [[texture(1)]],
                            constant ThresholdParameters &Threshold [[buffer(0)]],
                            uint2 gid [[thread_position_in_grid]])
{
    float4 InColor = InTexture.read(gid);
    float Red = InColor.r;
    float Green = InColor.g;
    float Blue = InColor.b;
    float4 HSB = ToHSB_ForThreshold(InColor);
    bool UseLowColor = true;
    float K = 0.0;
    float Y = 0.0;
    float M = 0.0;
    float C = 0.0;
    
    K = 1.0 - max(Red, max(Green, Blue));
    if (K == 0.0)
        {
        C = K;
        M = K;
        Y = K;
        }
    else
        {
        C = (1.0 - Red - K) / (1.0 - K);
        M = (1.0 - Green - K) / (1.0 - K);
        Y = (1.0 - Blue - K) / (1.0 - K);
        }
    
    switch (Threshold.ThresholdInput)
    {
        case 0:
        //Pixel hue
        if (Threshold.ApplyIfHigher)
            {
            if (HSB.r > Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        else
            {
            if (HSB.r < Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        break;
        
        case 1:
        //Pixel saturation
        if (Threshold.ApplyIfHigher)
            {
            if (HSB.g > Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        else
            {
            if (HSB.g < Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        break;
        
        case 2:
        //Pixel brightness
        if (Threshold.ApplyIfHigher)
            {
            if (HSB.b > Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        else
            {
            if (HSB.b < Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        break;
        
        case 3:
        //Red channel
        if (Threshold.ApplyIfHigher)
            {
            if (Red > Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        else
            {
            if (Red < Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        break;
        
        case 4:
        //Green channel
        if (Threshold.ApplyIfHigher)
            {
            if (Green > Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        else
            {
            if (Green < Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        break;
        
        case 5:
        //Blue channel
        if (Threshold.ApplyIfHigher)
            {
            if (Blue > Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        else
            {
            if (Blue < Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        break;
        
        case 6:
        //Cyan channel
        if (Threshold.ApplyIfHigher)
            {
            if (C > Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        else
            {
            if (C < Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        break;
        
        case 7:
        //Magenta channel
        if (Threshold.ApplyIfHigher)
            {
            if (M > Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        else
            {
            if (M < Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        break;
        
        case 8:
        //Yellow channel
        if (Threshold.ApplyIfHigher)
            {
            if (Y > Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        else
            {
            if (Y < Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        break;
        
        case 9:
        //Black channel
        if (Threshold.ApplyIfHigher)
            {
            if (K > Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        else
            {
            if (K < Threshold.ThresholdValue)
                {
                UseLowColor = false;
                }
            }
        break;
        
        default:
        break;
    }
    
    if (UseLowColor)
        {
        OutTexture.write(Threshold.LowColor, gid);
        }
    else
        {
        OutTexture.write(Threshold.HighColor, gid);
        }
}
