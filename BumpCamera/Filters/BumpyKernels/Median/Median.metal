//
//  Median.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 3/24/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct MedianParameters
{
    int Width;
    int Height;
    int KernelCenterX;
    int KernelCenterY;
    int MedianOn;
};

float ChannelOf(float4 Color, int Channel)
{
    switch(Channel)
    {
        case 0:
        return Color.r;
        
        case 1:
        return Color.g;
        
        case 2:
        return Color.b;
        
        case 3:
        return Color.a;
        
        default:
        return Color.r;
    }
}

void Sort(float4 Array[], int Count, int Channel)
{
    int n = Count;
    bool Swapped = false;
    do
        {
        Swapped = false;
        for (int i = 0; i <= n - 1; i++)
            {
            if (ChannelOf(Array[i], Channel) > ChannelOf(Array[i + 1], Channel))
                {
                float4 temp = Array[i];
                Array[i] = Array[i + 1];
                Array[i + 1] = temp;
                Swapped = true;
                }
            }
        n = n - 1;
        }
    while(!Swapped);
}

//https://stackoverflow.com/questions/11704664/converting-hsb-color-to-rgb-in-objective-c
float4 HSBtoRGB0(float4 Source)
{
    float Hue = Source.r;
    float Saturation = Source.g;
    float Luminance = Source.b;
    if (Saturation == 0.0)
        {
        return float4(Source.b, Source.b, Source.b, 1.0);
        }
    float H = Hue / 60.0;
    float I = floor(H);
    float F = H - I;
    float P = Luminance * (1.0 - Saturation);
    float Q = Luminance * (1.0 - (Saturation * F));
    float T = Luminance * (1.0 - (Saturation * (1.0 - F)));
    float r = 0.0;
    float g = 0.0;
    float b = 0.0;
    switch ((int)I)
    {
        case 0:
        r = Luminance;
        g = T;
        b = P;
        break;
        
        case 1:
        r = Q;
        g = Luminance;
        b = P;
        break;
        
        case 2:
        r = P;
        g = Luminance;
        b = T;
        break;
        
        case 3:
        r = P;
        g = Q;
        b = Luminance;
        break;
        
        case 4:
        r = T;
        g = P;
        b = Luminance;
        break;
        
        default:
        r = Luminance;
        g = P;
        b = Q;
        break;
    }
    return float4(r, g, b, 1.0);
}

//https://www.cs.rit.edu/~ncs/color/t_convert.html
float4 RGBtoHSB0(float4 Source)
{
    float r = Source.r;
    float g = Source.g;
    float b = Source.b;
    
    float S = 0.0;
    float L = 0.0;
    
    float CMin = min(r, min(g, b));
    float CMax = max(r, max(g, b));
    float Delta = CMax - CMin;
    float Hue = 0.0;
    
    if (Delta == 0.0)
        {
        Hue = 0.0;
        }
    else
        {
        if (CMax == r)
            {
            Hue = (g - b) / Delta + (g < b ? 6.0 : 0.0);
            }
        else
            if (CMax == g)
                {
                Hue = (((b - r) / Delta) + 2.0);
                }
            else
                if (CMax == b)
                    {
                    Hue = (((r - g) / Delta) + 4.0);
                    }
        }
    Hue = Hue * 60.0;
    if (Hue < 0.0)
        {
        Hue = Hue + 360.0;
        }
    L = CMax;
    S = CMax == 0.0 ? 0.0 : (CMax - CMin) / CMax;
    
    return float4(Hue, S, L, 1);
}

kernel void Median(texture2d<float, access::read> InTexture [[texture(0)]],
                   texture2d<float, access::write> OutTexture [[texture(1)]],
                   constant MedianParameters &Median [[buffer(0)]],
                   device float *ToCPU [[buffer(1)]],
                   uint2 gid [[thread_position_in_grid]])
{
    int ImageWidth = InTexture.get_width();
    int ImageHeight = InTexture.get_height();
    for (int i = 0; i < 100; i++)
        {
        ToCPU[i] = -100.0;
        }
    
    int KHStart = gid.x - Median.KernelCenterX;
    if (KHStart < 0)
        {
        KHStart = 0;
        }
    int KHEnd = gid.x + Median.KernelCenterX;
    if (KHEnd >= ImageWidth)
        {
        KHEnd = ImageWidth - 1;
        }
    int KVStart = gid.y - Median.KernelCenterY;
    if (KVStart < 0)
        {
        KVStart = 0;
        }
    int KVEnd = gid.y + Median.KernelCenterX;
    if (KVEnd >= ImageHeight)
        {
        KVEnd = ImageHeight - 1;
        }
    int Kdx = 0;
    float4 List[81];
    for (int KY = KVStart; KY <= KVEnd; KY++)
        {
        for (int KX = KHStart; KX <= KHEnd; KX++)
            {
            float4 Pixel = RGBtoHSB0(InTexture.read(uint2(KX,KY)));
            List[Kdx++] = Pixel;
            }
        }
    
    int HPixels = KHEnd - KHStart + 1;
    int VPixels = KVEnd - KVStart + 1;
    int PixelCount = HPixels * VPixels;
    Sort(List, PixelCount, Median.MedianOn);
    float4 MedianHSB = List[PixelCount / 2];
    float4 FinalPixel = HSBtoRGB0(MedianHSB);
    
    OutTexture.write(FinalPixel, gid);
}
