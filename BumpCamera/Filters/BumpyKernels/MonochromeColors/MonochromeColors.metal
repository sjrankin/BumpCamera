//
//  MonochromeColors.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 2/10/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct MonochromeColorParameters
{
    uint Colorspace;
    bool ForBright;
    bool ForRed;
    bool ForGreen;
    bool ForBlue;
    bool ForCyan;
    bool ForMagenta;
    bool ForYellow;
    bool ForBlack;
    uint HueSegmentCount;
    uint SelectedIndex;
};

constant const int RedChannel = 0;
constant const int GreenChannel = 1;
constant const int BlueChannel = 2;
constant const int CyanChannel = 3;
constant const int MagentaChannel = 4;
constant const int YellowChannel = 5;
constant const int BlackChannel = 6;
constant const int IsGray = 7;

float4 ToRGBFromHSB(float H, float S, float B)
{
    float Hx = H * 360.0;
    float AbsTerm = fabs((2.0 * B) - 1.0);
    float C = (1.0 - AbsTerm) * S;
    float ModTerm = fmod((Hx / 60.0), 2.0);
    float X = C * (1.0 - fabs(ModTerm - 1.0));
    if ((Hx >= 0.0) && (Hx < 60.0))
        {
        return float4(C, X, 0.0, 1.0);
        }
    if ((Hx >= 60.0) && (Hx < 120.0))
        {
        return float4(X, C, 0.0, 1.0);
        }
    if ((Hx >= 120.0) && (Hx < 180.0))
        {
        return float4(0.0, C, X, 1.0);
        }
    if ((Hx >= 180.0) && (Hx < 240.0))
        {
        return float4(0.0, X, C, 1.0);
        }
    if ((Hx >= 240.0) && (Hx < 300.0))
        {
        return float4(X, 0.0, C, 1.0);
        }
    return float4(C, 0.0, X, 1.0);
}

float4 ToHSB_ForMonochromeColors(float4 Source)
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

int BrightestRGBChannel(float r, float g, float b)
{
    if (r == max(r, max(g, b)))
        {
        return RedChannel;
        }
    if (g == max(r, max(g, b)))
        {
        return GreenChannel;
        }
    if (b == max(r, max(g, b)))
        {
        return BlueChannel;
        }
    return IsGray;
}

int DimmestRGBChannel(float r, float g, float b)
{
    if (r == min(r, min(g, b)))
        {
        return RedChannel;
        }
    if (g == min(r, min(g, b)))
        {
        return GreenChannel;
        }
    if (b == min(r, min(g, b)))
        {
        return BlueChannel;
        }
    return IsGray;
}

int BrightestCMYKChannel(float c, float m, float y, float k)
{
    if (c == max(c, max(m, max(y, k))))
        {
        return CyanChannel;
        }
    if (m == max(c, max(m, max(y, k))))
        {
        return MagentaChannel;
        }
    if (y == max(c, max(m, max(y, k))))
        {
        return YellowChannel;
        }
    if (k == max(c, max(m, max(y, k))))
        {
        return BlackChannel;
        }
    return IsGray;
}

int DimmestCMYKChannel(float c, float m, float y, float k)
{
    if (c == min(c, min(m, min(y, k))))
        {
        return CyanChannel;
        }
    if (m == min(c, min(m, min(y, k))))
        {
        return MagentaChannel;
        }
    if (y == min(c, min(m, min(y, k))))
        {
        return YellowChannel;
        }
    if (k == min(c, min(m, min(y, k))))
        {
        return BlackChannel;
        }
    return IsGray;
}

kernel void MonochromeColorsKernel (texture2d<float, access::read> inTexture [[texture(0)]],
                                    texture2d<float, access::write> outTexture [[texture(1)]],
                                    constant MonochromeColorParameters &MonoColors [[buffer(0)]],
                                    uint2 gid [[thread_position_in_grid]])
{
    float4 InColor = inTexture.read(gid);
    float r = InColor.r;
    float g = InColor.g;
    float b = InColor.b;
    float ChannelValue0 = (r + g + b) / 3.0;
    float ChannelValue1 = ChannelValue0;
    float ChannelValue2 = ChannelValue0;
    float C = 0.0;
    float M = 0.0;
    float Y = 0.0;
    float K = 0.0;
    /*
    if (MonoColors.Colorspace == 0)
        {
        outTexture.write(InColor, gid);
        return;
        }
    if (MonoColors.Colorspace == 1)
        {
        float4 NewColor = float4(g, b, r, 1.0);
        outTexture.write(NewColor, gid);
        return;
        }
    if (MonoColors.Colorspace == 2)
        {
        float4 HSBColor = float4(r, r, r, 1.0);
        outTexture.write(HSBColor, gid);
        return;
        }
    */
    switch (MonoColors.Colorspace)
    {
        case 0:
        {
        //RGB
        float BrightChannel = BrightestRGBChannel(r, g, b);
        float DimChannel = DimmestRGBChannel(r, g, b);
        if (MonoColors.ForRed)
            {
            if (MonoColors.ForBright)
                {
                if (BrightChannel == RedChannel)
                    {
                    ChannelValue0 = r;
                    ChannelValue1 = 0.0;
                    ChannelValue2 = 0.0;
                    }
                }
            else
                {
                if (DimChannel == RedChannel)
                    {
                    ChannelValue0 = r;
                    ChannelValue1 = 0.0;
                    ChannelValue2 = 0.0;
                    }
                }
            }
        if (MonoColors.ForGreen)
            {
            if (MonoColors.ForBright)
                {
                if (BrightChannel == GreenChannel)
                    {
                    ChannelValue0 = 0.0;
                    ChannelValue1 = g;
                    ChannelValue2 = 0.0;
                    }
                }
            else
                {
                if (DimChannel == GreenChannel)
                    {
                    ChannelValue0 = 0.0;
                    ChannelValue1 = g;
                    ChannelValue2 = 0.0;
                    }
                }
            }
        if (MonoColors.ForBlue)
            {
            if (MonoColors.ForBright)
                {
                if (BrightChannel == BlueChannel)
                    {
                    ChannelValue0 = 0.0;
                    ChannelValue1 = 0.0;
                    ChannelValue2 = b;
                    }
                }
            else
                {
                if (DimChannel == BlueChannel)
                    {
                    ChannelValue0 = 0.0;
                    ChannelValue1 = 0.0;
                    ChannelValue2 = b;
                    }
                }
            }
        break;
        }
        
        case 1:
        {
        //CMYK
        K = 1.0 - max(r, max(g, b));
        if (K == 0.0)
            {
            C = K;
            M = K;
            Y = K;
            }
        else
            {
            C = (1.0 - r - K) / (1.0 - K);
            M = (1.0 - g - K) / (1.0 - K);
            Y = (1.0 - b - K) / (1.0 - K);
            }
        float BrightChannel = BrightestCMYKChannel(C, M, Y, K);
        float DimChannel = DimmestCMYKChannel(C, M, Y, K);
        if (MonoColors.ForCyan)
            {
            if (MonoColors.ForBright)
                {
                if (BrightChannel == CyanChannel)
                    {
                    ChannelValue0 = 0.0;
                    ChannelValue1 = C;
                    ChannelValue2 = C;
                    }
                }
            else
                {
                if (DimChannel == CyanChannel)
                    {
                    ChannelValue0 = 0.0;
                    ChannelValue1 = C;
                    ChannelValue2 = C;
                    }
                }
            }
        if (MonoColors.ForMagenta)
            {
            if (MonoColors.ForBright)
                {
                if (BrightChannel == MagentaChannel)
                    {
                    ChannelValue0 = M;
                    ChannelValue1 = 0.0;
                    ChannelValue2 = M;
                    }
                }
            else
                {
                if (DimChannel == MagentaChannel)
                    {
                    ChannelValue0 = M;
                    ChannelValue1 = 0.0;
                    ChannelValue2 = M;
                    }
                }
            }
        if (MonoColors.ForYellow)
            {
            if (MonoColors.ForBright)
                {
                if (BrightChannel == YellowChannel)
                    {
                    ChannelValue0 = Y;
                    ChannelValue1 = Y;
                    ChannelValue2 = 0.0;
                    }
                }
            else
                {
                if (DimChannel == YellowChannel)
                    {
                    ChannelValue0 = Y;
                    ChannelValue1 = Y;
                    ChannelValue2 = 0.0;
                    }
                }
            }
        if (MonoColors.ForBlack)
            {
            if (MonoColors.ForBright)
                {
                if (BrightChannel == BlackChannel)
                    {
                    ChannelValue0 = K;
                    ChannelValue1 = K;
                    ChannelValue2 = K;
                    }
                }
            else
                {
                if (DimChannel == BlackChannel)
                    {
                    ChannelValue0 = K;
                    ChannelValue1 = K;
                    ChannelValue2 = K;
                    }
                }
            }
        break;
        }
        
        case 2:
        {
        //HSB
        float4 HSB = ToHSB_ForMonochromeColors(InColor);
        float H = HSB.r;
        float Denominator = MonoColors.HueSegmentCount == 0 ? 1 : MonoColors.HueSegmentCount;
        float RangeSize = 1.0 / Denominator;
        float SelectedRange = RangeSize * MonoColors.SelectedIndex;
        float NewHue = (SelectedRange + (RangeSize / 2.0));
        if (H >= SelectedRange && H < SelectedRange + RangeSize)
            {
            ChannelValue0 = r;
            ChannelValue1 = g;
            ChannelValue2 = b;
            }
        /*
        if (H >= SelectedRange && H < SelectedRange + RangeSize)
            {
            float4 FromHSB = ToRGBFromHSB(NewHue, HSB.g, HSB.b);
            ChannelValue0 = FromHSB.r;
            ChannelValue1 = FromHSB.g;
            ChannelValue2 = FromHSB.b;
            }
        else
            {
            ChannelValue0 = 1.0 - r;//NewHue;
            ChannelValue1 = 1.0 - g;//NewHue;
            ChannelValue2 = 1.0 - b;//NewHue;
            }
         */
        break;
        }
    }
    
    float4 outputColor = float4(ChannelValue0, ChannelValue1, ChannelValue2, 1.0);
    outTexture.write(outputColor, gid);
}
