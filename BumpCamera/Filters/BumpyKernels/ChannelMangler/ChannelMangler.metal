//
//  ChannelMangler.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 3/5/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct ChannelManglerParameters
{
    uint Action;
};

float4 CMToRGBFromHSB(float H, float S, float B)
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

float4 CMToHSB(float4 Source)
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

float4 CMToCMYK(float4 Source)
{
    float C = 0.0;
    float M = 0.0;
    float Y = 0.0;
    float K = 0.0;
    K = 1.0 - max(Source.r, max(Source.g, Source.b));
    if (K == 0.0)
        {
        C = K;
        M = K;
        Y = K;
        }
    else
        {
        C = (1.0 - Source.r - K) / (1.0 - K);
        M = (1.0 - Source.g - K) / (1.0 - K);
        Y = (1.0 - Source.b - K) / (1.0 - K);
        }
    return float4(C, M, Y, K);
}

float4 CMCMYKToRGB(float4 Source)
{
    float C = Source.r;
    float M = Source.g;
    float Y = Source.b;
    float K = Source.a;
    float Red = (1.0 - C) * (1.0 - K);
    float Green = (1.0 - M) * (1.0 - K);
    float Blue = (1.0 - Y) * (1.0 - K);
    return float4(Red, Green, Blue, 1.0);
}

kernel void ChannelMangler(texture2d<float, access::read> InTexture [[texture(0)]],
                           texture2d<float, access::write> OutTexture [[texture(1)]],
                           constant ChannelManglerParameters &Mangle [[buffer(0)]],
                           device float *ToCPU [[buffer(1)]],
                           uint2 gid [[thread_position_in_grid]])
{
    uint Width = InTexture.get_width();
    uint Height = InTexture.get_height();
    float4 InColor = InTexture.read(gid);
    float4 OutColor = InColor;
    float c1, c2, c3, c4;
    uint InX = gid.x;
    uint InY = gid.y;
    uint NewY = (Height - 1) - InY;
    uint NewX = (Width - 1) - InX;
    float4 TransposedPixel = InTexture.read(uint2(NewX, NewY));
    float4 HSBIn = CMToHSB(InColor);
    float Hue = HSBIn.r;
    float Saturation = HSBIn.g;
    float Brightness = HSBIn.b;
    float4 TrHSBIn = CMToHSB(TransposedPixel);
    float TrHue = TrHSBIn.r;
    float TrSaturation = TrHSBIn.g;
    float TrBrightness = TrHSBIn.b;
    float4 CMYKIn = CMToCMYK(InColor);
    float C = CMYKIn.r;
    float M = CMYKIn.g;
    float Y = CMYKIn.b;
    float K = CMYKIn.a;
    float4 TrCMYKIn = CMToCMYK(TransposedPixel);
    float TrC = TrCMYKIn.r;
    float TrM = TrCMYKIn.g;
    float TrY = TrCMYKIn.b;
    float TrK = TrCMYKIn.a;
    
    switch (Mangle.Action)
    {
        case 0:
        //NOP
        break;
        
        case 1:
        c1 = max(InColor.g, InColor.b);
        c2 = max(InColor.r, InColor.b);
        c3 = max(InColor.r, InColor.g);
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        
        case 2:
        c1 = min(InColor.g, InColor.b);
        c2 = min(InColor.r, InColor.b);
        c3 = min(InColor.r, InColor.g);
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        
        case 3:
        c1 = (InColor.r + ((InColor.g + InColor.b) / 2.0)) / 2.0;
        c2 = (InColor.g + ((InColor.r + InColor.b) / 2.0)) / 2.0;
        c3 = (InColor.b + ((InColor.r + InColor.g) / 2.0)) / 2.0;
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        
        case 4:
        c1 = InColor.r;
        c2 = InColor.g;
        c3 = InColor.b;
        if ((max(InColor.r, max(InColor.g, InColor.b))) == InColor.r)
            {
            c1 = 1.0 - InColor.r;
            }
        if ((max(InColor.r, max(InColor.g, InColor.b))) == InColor.g)
            {
            c2 = 1.0 - InColor.g;
            }
        if ((max(InColor.r, max(InColor.g, InColor.b))) == InColor.b)
            {
            c3 = 1.0 - InColor.b;
            }
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        
        case 5:
        c1 = InColor.r;
        c2 = InColor.g;
        c3 = InColor.b;
        if ((min(InColor.r, min(InColor.g, InColor.b))) == InColor.r)
            {
            c1 = 1.0 - InColor.r;
            }
        if ((min(InColor.r, min(InColor.g, InColor.b))) == InColor.g)
            {
            c2 = 1.0 - InColor.g;
            }
        if ((min(InColor.r, min(InColor.g, InColor.b))) == InColor.b)
            {
            c3 = 1.0 - InColor.b;
            }
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        
        case 6:
        {
        c1 = TransposedPixel.r;
        c2 = InColor.g;
        c3 = InColor.b;
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 7:
        {
        c1 = InColor.r;
        c2 = TransposedPixel.g;
        c3 = InColor.b;
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 8:
        {
        c1 = InColor.r;
        c2 = InColor.g;
        c3 = TransposedPixel.b;
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 9:
        {
        c1 = TrC;
        c2 = M;
        c3 = Y;
        c4 = K;
        OutColor = CMCMYKToRGB(float4(c1, c2, c3, c4));
        break;
        }
        
        case 10:
        {
        c1 = C;
        c2 = TrM;
        c3 = Y;
        c4 = K;
        OutColor = CMCMYKToRGB(float4(c1, c2, c3, c4));
        break;
        }
        
        case 11:
        {
        c1 = C;
        c2 = M;
        c3 = TrY;
        c4 = K;
        OutColor = CMCMYKToRGB(float4(c1, c2, c3, c4));
        break;
        }
        
        case 12:
        {
        c1 = C;
        c2 = M;
        c3 = Y;
        c4 = TrK;
        OutColor = CMCMYKToRGB(float4(c1, c2, c3, c4));
        break;
        }
        
        case 13:
        {
        c1 = TrHue;
        c2 = Saturation;
        c3 = Brightness;
        OutColor = CMToRGBFromHSB(c1, c2, c3);
        break;
        }
        
        case 14:
        {
        c1 = Hue;
        c2 = TrSaturation;
        c3 = Brightness;
        OutColor = CMToRGBFromHSB(c1, c2, c3);
        break;
        }
        
        case 15:
        {
        c1 = Hue;
        c2 = Saturation;
        c3 = TrBrightness;
        OutColor = CMToRGBFromHSB(c1, c2, c3);
        break;
        }
        
        case 16:
        {
        int Hm = int(Hue * 360.0);
        Hm = Hm / 10;
        Hm = Hm * 10;
        c1 = float(Hm) / 360.0;
        c2 = Saturation;
        c3 = Brightness;
        OutColor = CMToRGBFromHSB(c1, c2, c3);
        break;
        }
        
        case 17:
        {
        c1 = Hue;
        int Sm = int(Saturation * 1000.0);
        Sm = Sm / 10;
        Sm = Sm * 10;
        c2 = float(Sm) / 1000.0;
        c3 = Brightness;
        OutColor = CMToRGBFromHSB(c1, c2, c3);
        break;
        }
        
        case 18:
        {
        int Hm = int(Hue * 360.0);
        Hm = Hm / 10;
        Hm = Hm * 10;
        c1 = Hue;
        c2 = Saturation;
        int Bm = int(Brightness * 1000.0);
        Bm = Bm / 10;
        Bm = Bm * 10;
        c3 = float(Bm) / 1000.0;
        OutColor = CMToRGBFromHSB(c1, c2, c3);
        break;
        }
        
        default:
        break;
    }
    
    OutTexture.write(OutColor, gid);
}
