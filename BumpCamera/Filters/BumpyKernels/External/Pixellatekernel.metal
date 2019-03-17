//
//  Pixellatekernel.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 1/28/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct BlockInfoParameters
{
    uint Width;
    uint Height;
    // Highlight values: 0 = Hue, 1 = Saturation, 2 = Brightness, 3 = none
    uint Highlight;
    //0 = set to color, 1 = set to grayscale, 2 = set to transparent, 3 = invert brightness, 4 = invert color
    uint HighlightAction;
    float4 Highlight_Color;
    uint ColorDetermination;
    float HighlightValue;
    bool HighlightIfGreater;
};

//https://stackoverflow.com/questions/11704664/converting-hsb-color-to-rgb-in-objective-c
float4 HSBtoRGB(float4 Source)
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
float4 RGBtoHSB(float4 Source)
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

float4 ApplyHighlight(float4 Source, uint Action)
{
    switch (Action)
    {
        case 0:
        {
        //grayscale
        float4 RGB = HSBtoRGB(Source);
        float Gray = (RGB.r + RGB.g + RGB.b) / 3.0;
        float4 Grayscale = float4(Gray, Gray, Gray, 1.0);
        return Grayscale;
        }
        
        case 1:
        {
        //transparent
        return float4(1.0, 1.0, 1.0, 0.0);
        }
        
        case 2:
        {
        //set to black
        return float4(0.0, 0.0, 0.0, 1.0);
        }
        
        case 3:
        {
        //set to white
        return float4(1.0, 1.0, 1.0, 1.0);
        }
        
        case 4:
        {
        //set to gray
        return float4(0.5, 0.5, 0.5, 1.0);
        }
        
        case 5:
        {
        //invert color
        float4 RGB = HSBtoRGB(Source);
        return float4(1.0 - RGB.r, 1.0 - RGB.g, 1.0 - RGB.b, 1.0);
        }
        
        case 6:
        {
        //invert hue
        float H = 360.0 - Source.r;
        float4 scratch = float4(H, Source.g, Source.b, 1.0);
        return HSBtoRGB(scratch);
        }
        
        case 7:
        {
        //brightness to max
        float4 scratch = float4(Source.r, Source.g, 1.0, 1.0);
        return HSBtoRGB(scratch);
        }
        
        case 8:
        {
        //saturation to max
        float4 scratch = float4(Source.r, 1.0, Source.b, 1.0);
        return HSBtoRGB(scratch);
        }
        
        case 9:
        {
        //draw border
        return HSBtoRGB(Source);
        }
        
        default:
        {
        return HSBtoRGB(Source);
        }
    }
}

kernel void PixellateKernel(texture2d<float, access::read> InTexture [[texture(0)]],
                            texture2d<float, access::write> OutTexture [[texture(1)]],
                            constant BlockInfoParameters &BlockInfo [[buffer(0)]],
                            uint2 gid [[thread_position_in_grid]])
{
    uint Width = BlockInfo.Width;
    uint Height = BlockInfo.Height;
    
    const uint2 PixelattedGrid = uint2((gid.x / Width) * Width, (gid.y / Height) * Height);
    const float4 ColorAtPixel = InTexture.read(PixelattedGrid);
    
    float4 HSB = RGBtoHSB(ColorAtPixel);
    float4 FinalColor = float4(1.0, 1.0, 1.0, 1.0);
    switch (BlockInfo.Highlight)
    {
        case 0:
        {
        float H = HSB.r / 360.0;
        if (BlockInfo.HighlightIfGreater)
            {
            if (H > BlockInfo.HighlightValue)
                {
                FinalColor = ApplyHighlight(HSB, BlockInfo.HighlightAction);
                }
            }
        else
            {
            if (H < BlockInfo.HighlightValue)
                {
                FinalColor = ApplyHighlight(HSB, BlockInfo.HighlightAction);
                }
            }
        break;
        }
        
        case 1:
        {
        float S = HSB.g;
        if (BlockInfo.HighlightIfGreater)
            {
            if (S > BlockInfo.HighlightValue)
                {
                FinalColor = ApplyHighlight(HSB, BlockInfo.HighlightAction);
                }
            }
        else
            {
            if (S < BlockInfo.HighlightValue)
                {
                FinalColor = ApplyHighlight(HSB, BlockInfo.HighlightAction);
                }
            }
        break;
        }
        
        case 2:
        {
        float B = HSB.b;
        if (BlockInfo.HighlightIfGreater)
            {
            if (B > BlockInfo.HighlightValue)
                {
                FinalColor = ApplyHighlight(HSB, BlockInfo.HighlightAction);
                }
            }
        else
            {
            if (B < BlockInfo.HighlightValue)
                {
                FinalColor = ApplyHighlight(HSB, BlockInfo.HighlightAction);
                }
            }
        break;
        }
        
        default:
        {
        FinalColor = HSBtoRGB(HSB);
        break;
        }
    }
    
    OutTexture.write(FinalColor, gid);
}
