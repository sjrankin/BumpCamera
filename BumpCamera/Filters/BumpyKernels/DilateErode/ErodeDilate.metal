//
//  ErodeDilate.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 2/14/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct DEParameters
{
    //Half of a window size. Must be odd.
    uint WindowSize;
    //0 = red, 1 = green, 2 = blue, 3 = hue, 4 = saturation, 5 = brightness, 6 = cyan, 7 = magenta, 8 = yellow, 9 = black
    uint ValueDetermination;
    //Determines the operation. 0 = erode, 1 = dilate
    uint Operation;
};

float4 ToHSB_ForErosion(float4 Source)
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

float GetPixelValue(float4 Pixel, uint ValueDetermination)
{
    float Red = Pixel.r;
    float Green = Pixel.g;
    float Blue = Pixel.b;
    float4 HSB = ToHSB_ForErosion(Pixel);
    
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
    
    switch(ValueDetermination)
    {
        case 0:
        return Red;
        
        case 1:
        return Green;
        
        case 2:
        return Blue;
        
        case 3:
        return HSB.r;
        
        case 4:
        return HSB.g;
        
        case 5:
        return HSB.b;
        
        case 6:
        return C;
        
        case 7:
        return M;
        
        case 8:
        return Y;
        
        case 9:
        return K;
        
        default:
        return Red;
    }
}

kernel void DilateErodeKernel(texture2d<float, access::read> InTexture [[texture(0)]],
                              texture2d<float, access::write> OutTexture [[texture(1)]],
                              constant DEParameters &DEParm [[buffer(0)]],
                              device float *Output [[buffer(1)]],
                              uint2 gid [[thread_position_in_grid]])
{
    float4 InColor = InTexture.read(gid);
    int Width = InTexture.get_width();
    int Height = InTexture.get_height();
    float PixelValue = GetPixelValue(InColor, DEParm.ValueDetermination);
    uint BlockSize = 0;
    BlockSize = DEParm.WindowSize;
    
    int XStart = gid.x - ((BlockSize - 1) / 2);
    if (XStart < 0)
        {
        XStart = 0;
        }
    int XEnd = gid.x + ((BlockSize - 1) / 2);
    if (XEnd > Width - 1)
        {
        XEnd = Width - 1;
        }
    int YStart = gid.y - ((BlockSize - 1) / 2);
    if (YStart < 0)
        {
        YStart = 0;
        }
    int YEnd = gid.y + ((BlockSize - 1) / 2);
    if (YEnd > Height - 1)
        {
        YEnd = Height - 1;
        }
    
    float4 WindowColor = float4(0.0, 0.0, 0.0, 1.0);
    float BestValue = 0.0;
    if (DEParm.Operation == 0)
        {
        BestValue = 10000.0;
        }
    uint2 Working = uint2(0,0);
    for (int X = XStart; X <= XEnd; X++)
        {
        for (int Y = YStart; Y <= YEnd; Y++)
            {
            Working = uint2(X,Y);
            float4 WorkingPixel = InTexture.read(Working);
            float WorkingValue = GetPixelValue(WorkingPixel, DEParm.ValueDetermination);
            if (DEParm.Operation == 0)
                {
                if (WorkingValue < BestValue)
                    {
                    WindowColor = WorkingPixel;
                    BestValue = WorkingValue;
                    }
                }
            else
                {
                if (WorkingValue > BestValue)
                    {
                    WindowColor = WorkingPixel;
                    BestValue = WorkingValue;
                    }
                }
            }
        }
    for (int X = XStart; X <= XEnd; X++)
        {
        for (int Y = YStart; Y <= YEnd; Y++)
            {
            Working = uint2(X,Y);
            OutTexture.write(WindowColor, Working);
            }
        }
}
