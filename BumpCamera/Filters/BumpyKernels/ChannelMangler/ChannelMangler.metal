//
//  ChannelMangler.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 3/5/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>
using namespace metal;


struct ChannelManglerParameters
{
    uint Action;
};

//https://www.geeksforgeeks.org/write-an-efficient-c-program-to-reverse-bits-of-a-number/
uint ReverseBits(uint Source)
{
    uint Working = Source & 0xff;
    uint BitCount = 8;
    uint Final = 0;
    for (uint i = 0; i < BitCount; i++)
        {
        if ((Working & (1 << i)))
            {
            Final |= 1 << ((BitCount - 1) - i);
            }
        }
    return Final;
}

uint Compact(uint Source, bool ShiftHigh)
{
    uint Working = Source & 0xff;
    uint OnCount = 0;
    uint BitCount = 8;
    for (uint i = 0; i < BitCount; i++)
        {
        if ((Working & (1 << i)))
            {
            OnCount++;
            }
        }
    uint Value = uint(pow(2.0, float(OnCount)) - 1);
    if (ShiftHigh)
        {
        uint ShiftBy = 8 - OnCount;
        Value = Value << ShiftBy;
        }
    return Value;
}

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
    uint RValue = uint(255.0 * InColor.r);
    uint GValue = uint(255.0 * InColor.g);
    uint BValue = uint(255.0 * InColor.b);
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
    uint SY = gid.y;
    uint SX = gid.x;
    SX += 8;
    if (SX > Width - 1)
        {
        SX = Width % 8;
        SY++;
        if (SY > Height - 1)
            {
            SY = 0;
            }
        }
    float Sum3x3R = 0.0;
    float Mean3x3R = 0.0;
    float Sum3x3G = 0.0;
    float Mean3x3G = 0.0;
    float Sum3x3B = 0.0;
    float Mean3x3B = 0.0;
    if (Mangle.Action >= 22 && Mangle.Action <= 26)
        {
        if (InX > 0 && InX < Width - 1 && InY > 0 && InY < Height - 1)
            {
            Sum3x3R = Sum3x3R + InTexture.read(uint2(InX - 1, InY - 1)).r;
            Sum3x3R = Sum3x3R + InTexture.read(uint2(InX, InY - 1)).r;
            Sum3x3R = Sum3x3R + InTexture.read(uint2(InX + 1, InY - 1)).r;
            Sum3x3R = Sum3x3R + InTexture.read(uint2(InX - 1, InY)).r;
            Sum3x3R = Sum3x3R + InTexture.read(uint2(InX, InY)).r;
            Sum3x3R = Sum3x3R + InTexture.read(uint2(InX + 1, InY)).r;
            Sum3x3R = Sum3x3R + InTexture.read(uint2(InX - 1, InY + 1)).r;
            Sum3x3R = Sum3x3R + InTexture.read(uint2(InX, InY + 1)).r;
            Sum3x3R = Sum3x3R + InTexture.read(uint2(InX + 1, InY + 1)).r;
            Mean3x3R = Sum3x3R / 9.0;
            Sum3x3G = Sum3x3G + InTexture.read(uint2(InX - 1, InY - 1)).g;
            Sum3x3G = Sum3x3G + InTexture.read(uint2(InX, InY - 1)).g;
            Sum3x3G = Sum3x3G + InTexture.read(uint2(InX + 1, InY - 1)).g;
            Sum3x3G = Sum3x3G + InTexture.read(uint2(InX - 1, InY)).g;
            Sum3x3G = Sum3x3G + InTexture.read(uint2(InX, InY)).g;
            Sum3x3G = Sum3x3G + InTexture.read(uint2(InX + 1, InY)).g;
            Sum3x3G = Sum3x3G + InTexture.read(uint2(InX - 1, InY + 1)).g;
            Sum3x3G = Sum3x3G + InTexture.read(uint2(InX, InY + 1)).g;
            Sum3x3G = Sum3x3G + InTexture.read(uint2(InX + 1, InY + 1)).g;
            Mean3x3G = Sum3x3G / 9.0;
            Sum3x3B = Sum3x3B + InTexture.read(uint2(InX - 1, InY - 1)).b;
            Sum3x3B = Sum3x3B + InTexture.read(uint2(InX, InY - 1)).b;
            Sum3x3B = Sum3x3B + InTexture.read(uint2(InX + 1, InY - 1)).b;
            Sum3x3B = Sum3x3B + InTexture.read(uint2(InX - 1, InY)).b;
            Sum3x3B = Sum3x3B + InTexture.read(uint2(InX, InY)).b;
            Sum3x3B = Sum3x3B + InTexture.read(uint2(InX + 1, InY)).b;
            Sum3x3B = Sum3x3B + InTexture.read(uint2(InX - 1, InY + 1)).b;
            Sum3x3B = Sum3x3B + InTexture.read(uint2(InX, InY + 1)).b;
            Sum3x3B = Sum3x3B + InTexture.read(uint2(InX + 1, InY + 1)).b;
            Mean3x3B = Sum3x3B / 9.0;
            }
        }
    
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
        
        case 19:
        {
        c1 = InTexture.read(uint2(SX,SY)).r;
        c2 = InColor.g;
        c3 = InColor.b;
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 20:
        {
        c1 = InColor.r;
        c2 = InTexture.read(uint2(SX,SY)).g;
        c3 = InColor.b;
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 21:
        {
        c1 = InColor.r;
        c2 = InColor.g;
        c3 = InTexture.read(uint2(SX,SY)).b;
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 22:
        {
        c1 = Mean3x3R;
        c2 = InColor.g;
        c3 = InColor.b;
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 23:
        {
        c1 = InColor.r;
        c2 = Mean3x3G;
        c3 = InColor.b;
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 24:
        {
        c1 = InColor.r;
        c2 = InColor.g;
        c3 = Mean3x3B;
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 25:
        {
        float Greatest = max(Mean3x3R, max(Mean3x3G, Mean3x3B));
        c1 = Greatest;
        c2 = Greatest;
        c3 = Greatest;
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 26:
        {
        float Least = min(Mean3x3R, min(Mean3x3G, Mean3x3B));
        c1 = Least;
        c2 = Least;
        c3 = Least;
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 27:
        {
        c1 = float((RValue & 0xfe) / 255.0);
        c2 = float((GValue & 0xfe) / 255.0);
        c3 = float((BValue & 0xfe) / 255.0);
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 28:
        {
        c1 = float((RValue & 0xfc) / 255.0);
        c2 = float((GValue & 0xfc) / 255.0);
        c3 = float((BValue & 0xfc) / 255.0);
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 29:
        {
        c1 = float((RValue & 0xf8) / 255.0);
        c2 = float((GValue & 0xf8) / 255.0);
        c3 = float((BValue & 0xf8) / 255.0);
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 30:
        {
        c1 = float((RValue & 0xf0) / 255.0);
        c2 = float((GValue & 0xf0) / 255.0);
        c3 = float((BValue & 0xf0) / 255.0);
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 31:
        {
        c1 = float((RValue & 0xe0) / 255.0);
        c2 = float((GValue & 0xe0) / 255.0);
        c3 = float((BValue & 0xe0) / 255.0);
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 32:
        {
        c1 = float((RValue & 0xc0) / 255.0);
        c2 = float((GValue & 0xc0) / 255.0);
        c3 = float((BValue & 0xc0) / 255.0);
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 33:
        {
        c1 = float((RValue & 0x80) / 255.0);
        c2 = float((GValue & 0x80) / 255.0);
        c3 = float((BValue & 0x80) / 255.0);
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 34:
        {
        uint clred = Compact(RValue, false);
        uint clgreen = Compact(GValue, false);
        uint clblue = Compact(BValue, false);
        c1 = float(clred) / 255.0;
        c2 = float(clgreen) / 255.0;
        c3 = float(clblue) / 255.0;
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 35:
        {
        uint chred = Compact(RValue, true);
        uint chgreen = Compact(GValue, true);
        uint chblue = Compact(BValue, true);
        c1 = float(chred) / 255.0;
        c2 = float(chgreen) / 255.0;
        c3 = float(chblue) / 255.0;
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 36:
        {
        uint rred = ReverseBits(RValue);
        uint rgreen = ReverseBits(GValue);
        uint rblue = ReverseBits(BValue);
        c1 = float(rred) / 255.0;
        c2 = float(rgreen) / 255.0;
        c3 = float(rblue) / 255.0;
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 37:
        {
        int ic1 = int(InColor.r * 255.0);
        int ic2 = int(InColor.g * 255.0);
        int ic3 = int(InColor.b * 255.0);
        ic2 = ic2 ^ ic1;
        ic3 = ic3 ^ ic1;
        c1 = InColor.r;
        c2 = float(ic2 / 255.0);
        c3 = float(ic3 / 255.0);
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 38:
        {
        int ic1 = int(InColor.r * 255.0);
        int ic2 = int(InColor.g * 255.0);
        int ic3 = int(InColor.b * 255.0);
        ic1 = ic1 ^ ic2;
        ic3 = ic3 ^ ic2;
        c1 = float(ic1 / 255.0);
        c2 = InColor.g;
        c3 = float(ic3 / 255.0);
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 39:
        {
        int ic1 = int(InColor.r * 255.0);
        int ic2 = int(InColor.g * 255.0);
        int ic3 = int(InColor.b * 255.0);
        ic1 = ic1 ^ ic3;
        ic2 = ic2 ^ ic3;
        c1 = float(ic1 / 255.0);
        c2 = float(ic2 / 255.0);
        c3 = InColor.b;
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 40:
        {
        int ic1 = int(InColor.r * 255.0);
        int ic2 = int(InColor.g * 255.0);
        int ic3 = int(InColor.b * 255.0);
        ic1 = ic1 ^ ic2 ^ ic3;
        ic2 = ic2 ^ ic1 ^ ic3;
        ic3 = ic3 ^ ic1 ^ ic2;
        c1 = float(ic1 / 255.0);
        c2 = float(ic2 / 255.0);
        c3 = float(ic3 / 255.0);
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 41:
        {
        int ic1 = int(InColor.r * 255.0);
        int ic2 = int(InColor.g * 255.0);
        int ic3 = int(InColor.b * 255.0);
        ic1 = ic1 ^ (ic2 | ic3);
        ic2 = ic2 ^ (ic1 | ic3);
        ic3 = ic3 ^ (ic1 | ic2);
        c1 = float(ic1 / 255.0);
        c2 = float(ic2 / 255.0);
        c3 = float(ic3 / 255.0);
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        case 42:
        {
        int ic1 = int(InColor.r * 255.0);
        int ic2 = int(InColor.g * 255.0);
        int ic3 = int(InColor.b * 255.0);
        ic1 = ic1 ^ (ic2 & ic3);
        ic2 = ic2 ^ (ic1 & ic3);
        ic3 = ic3 ^ (ic1 & ic2);
        c1 = float(ic1 / 255.0);
        c2 = float(ic2 / 255.0);
        c3 = float(ic3 / 255.0);
        OutColor = float4(c1, c2, c3, 1.0);
        break;
        }
        
        default:
        break;
    }
    
    OutTexture.write(OutColor, gid);
}
