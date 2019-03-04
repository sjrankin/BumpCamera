//
//  ColorInverter.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 3/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct ColorInverterParameters
{
    //0 = rgb, 2 = hsb, 3 = xyz, 4 = yuv, 5 = cmyk
    uint Colorspace;
    bool InvertChannel1;
    bool InvertChannel2;
    bool InvertChannel3;
    bool InvertChannel4;
    bool EnableChannel1Threshold;
    bool EnableChannel2Threshold;
    bool EnableChannel3Threshold;
    bool EnableChannel4Threshold;
    float Channel1Threshold;
    float Channel2Threshold;
    float Channel3Threshold;
    float Channel4Threshold;
    bool InvertChannel1IfGreater;
    bool InvertChannel2IfGreater;
    bool InvertChannel3IfGreater;
    bool InvertChannel4IfGreater;
    bool InvertAlpha;
    bool EnableAlphaThreshold;
    float AlphaThreshold;
    bool AlphaInvertIfGreater;
};

float4 ToRGBFromHSB_ForInversion(float4 Source)
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

float4 ToHSB_ForInversion(float4 Source)
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

kernel void ColorInverter(texture2d<float, access::read> InTexture [[texture(0)]],
                          texture2d<float, access::write> OutTexture [[texture(1)]],
                          constant ColorInverterParameters &Parameters [[buffer(0)]],
                          device float *Results [[buffer(1)]],
                          uint2 gid [[thread_position_in_grid]])
{
    float4 InColor = InTexture.read(gid);
    float4 OutColor = float4(0.0, 0.0, 0.0, 1.0);
    
    switch (Parameters.Colorspace)
    {
        case 0:
        {
        //RGB
        float r = InColor.r;
        float g = InColor.g;
        float b = InColor.b;
        float a = InColor.a;
        if (Parameters.InvertChannel1)
            {
            if (Parameters.EnableChannel1Threshold)
                {
                if (Parameters.InvertChannel1IfGreater)
                    {
                    if (r > Parameters.Channel1Threshold)
                        {
                        r = 1.0 - r;
                        }
                    }
                else
                    {
                    if (r < Parameters.Channel1Threshold)
                        {
                        r = 1.0 - r;
                        }
                    }
                }
            else
                {
                r = 1.0 - r;
                }
            }
        if (Parameters.InvertChannel2)
            {
            if (Parameters.EnableChannel2Threshold)
                {
                if (Parameters.InvertChannel2IfGreater)
                    {
                    if (g > Parameters.Channel2Threshold)
                        {
                        g = 1.0 - g;
                        }
                    }
                else
                    {
                    if (g < Parameters.Channel2Threshold)
                        {
                        g = 1.0 - g;
                        }
                    }
                }
            else
                {
                g = 1.0 - g;
                }
            }
        if (Parameters.InvertChannel3)
            {
            if (Parameters.EnableChannel3Threshold)
                {
                if (Parameters.InvertChannel3IfGreater)
                    {
                    if (b > Parameters.Channel3Threshold)
                        {
                        b = 1.0 - b;
                        }
                    }
                else
                    {
                    if (b < Parameters.Channel3Threshold)
                        {
                        b = 1.0 - b;
                        }
                    }
                }
            else
                {
                b = 1.0 - b;
                }
            }
        if (Parameters.InvertAlpha)
            {
            if (Parameters.EnableAlphaThreshold)
                {
                if (Parameters.AlphaInvertIfGreater)
                    {
                    if (a > Parameters.AlphaThreshold)
                        {
                        a = 1.0 - a;
                        }
                    }
                else
                    {
                    if (a < Parameters.AlphaThreshold)
                        {
                        a = 1.0 - a;
                        }
                    }
                }
            else
                {
                a = 1.0 - a;
                }
            }
        OutColor = float4(r, g, b, a);
        break;
        }
        
        case 1:
        {
        //HSB
        float4 HSB = ToHSB_ForInversion(InColor);
        float h = InColor.r;
        float s = InColor.g;
        float b = InColor.b;
        float a = InColor.a;
        if (Parameters.InvertChannel1)
            {
            if (Parameters.EnableChannel1Threshold)
                {
                if (Parameters.InvertChannel1IfGreater)
                    {
                    if (h > Parameters.Channel1Threshold)
                        {
                        h = 1.0 - h;
                        }
                    }
                else
                    {
                    if (h < Parameters.Channel1Threshold)
                        {
                        h = 1.0 - h;
                        }
                    }
                }
            else
                {
                h = 1.0 - h;
                }
            }
        if (Parameters.InvertChannel2)
            {
            if (Parameters.EnableChannel2Threshold)
                {
                if (Parameters.InvertChannel2IfGreater)
                    {
                    if (s > Parameters.Channel2Threshold)
                        {
                        s = 1.0 - s;
                        }
                    }
                else
                    {
                    if (s < Parameters.Channel2Threshold)
                        {
                        s = 1.0 - s;
                        }
                    }
                }
            else
                {
                s = 1.0 - s;
                }
            }
        if (Parameters.InvertChannel3)
            {
            if (Parameters.EnableChannel3Threshold)
                {
                if (Parameters.InvertChannel3IfGreater)
                    {
                    if (b > Parameters.Channel3Threshold)
                        {
                        b = 1.0 - b;
                        }
                    }
                else
                    {
                    if (b < Parameters.Channel3Threshold)
                        {
                        b = 1.0 - b;
                        }
                    }
                }
            else
                {
                b = 1.0 - b;
                }
            }
        if (Parameters.InvertAlpha)
            {
            if (Parameters.EnableAlphaThreshold)
                {
                if (Parameters.AlphaInvertIfGreater)
                    {
                    if (a > Parameters.AlphaThreshold)
                        {
                        a = 1.0 - a;
                        }
                    }
                else
                    {
                    if (a < Parameters.AlphaThreshold)
                        {
                        a = 1.0 - a;
                        }
                    }
                }
            else
                {
                a = 1.0 - a;
                }
            }
        OutColor = ToRGBFromHSB_ForInversion(float4(h, s, b, a));
        break;
        }
    }
    
    OutTexture.write(OutColor, gid);
}
