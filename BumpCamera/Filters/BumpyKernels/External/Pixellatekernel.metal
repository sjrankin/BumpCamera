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
    // Highlight values: 0 = no highlighting, 1 = brightness highlighting, 2 = hue highlighting, 3 = saturation highlighting
    uint Highlight;
    //0 = set to color, 1 = set to grayscale, 2 = set to transparent, 3 = invert brightness, 4 = invert color
    uint BrightnessHighlight;
    float4 Highlight_Color;
};

//https://stackoverflow.com/questions/11704664/converting-hsb-color-to-rgb-in-objective-c
float4 ToRGB(float4 Source)
{
    float H = Source.r;
    float S = Source.g;
    float L = Source.b;
    float r = 0.0;
    float g = 0.0;
    float b = 0.0;
    
    float h = H * 360.0;
    if (h >= 360.0)
        {
        h = 0.0;
        }
    h /= 60.0;
    int Index = int(h);
        int ff = h - Index;
    float p = L * (1.0 - S);
    float q = L * (1.0 - (S * ff));
    float t = L * (1.0 - (S * (1.0 - ff)));
    
    switch(Index)
    {
        case 0:
        r = L;
        g = t;
        b = p;
        break;
        
        case 1:
        r = q;
        g = L;
        b = p;
        break;
        
        case 2:
        r = p;
        g = L;
        b = t;
        break;
        
        case 3:
        r = p;
        g = q;
        b = L;
        break;
        
        case 4:
        r = t;
        g = p;
        b = L;
        break;
        
        case 5:
        default:
        r = L;
        g = p;
        b = q;
        break;
    }
    
    float4 Results = float4(r, g, b, 1);
    return Results;
}

float4 ToHSB(float4 Source)
{
    float r = Source.r;
    float g = Source.g;
    float b = Source.b;
    
    float H = 0.0;
    float S = 0.0;
    float L = 0.0;
    
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
    L = Brightness;
    return float4(H, S, L, 1);
}

kernel void PixellateKernel(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            constant BlockInfoParameters &BlockInfo [[buffer(0)]],
                            uint2 gid [[thread_position_in_grid]])
{
    uint Width = BlockInfo.Width;
    uint Height = BlockInfo.Height;
    
    const uint2 PixelattedGrid = uint2((gid.x / Width) * Width, (gid.y / Height) * Height);
    const float4 ColorAtPixel = inTexture.read(PixelattedGrid);
    
    float4 HSB = ToHSB(ColorAtPixel);
    float H = HSB.r;
    float S = HSB.g;
    float L = HSB.b;
    
    float4 FinalColor = float4(H, S, L, 1.0);
    //FinalColor = ToRGB(FinalColor);
    /*
    if (L < 0.5)
        {
        float NewL = L * 1.5;
        if (NewL > 1.0)
            {
            NewL = 1.0;
            }
        float4 NewHSB = float4(H, S, NewL, 1.0);
        FinalColor = ToRGB(NewHSB);
        }
     */
    //float4 FinalColor = L < 0.5 ? float4(1.0 - ColorAtPixel.r, 1.0 - ColorAtPixel.g, 1.0 - ColorAtPixel.b, 0) : ColorAtPixel;
    
    outTexture.write(FinalColor, gid);
}
