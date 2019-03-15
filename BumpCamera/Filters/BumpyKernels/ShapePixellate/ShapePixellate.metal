//
//  ShapePixellate.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 3/15/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ShapePixellateParameters
{
    int Size;
    // 0 = square, 1 = circle
    int Shape;
    // 0 = mean of block, 1 = hue of block, 2 = grayscale mean of block, 3 = specified color
    int BlockColorFrom;
    float4 BlockColor;
    bool DrawOutline;
    // 0 = max sat & bri from mean of block, 1 = grayscale mean of block, 2 = specified color
    int OutlineColorFrom;
    float4 OutlineColor;
    int OutlineThickness;
};


float4 ToHSB_SP(float4 Source)
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
    float4 Results = float4(H, S, L, 1);
    return Results;
}

kernel void ShapePixellate(texture2d<float, access::read> InTexture [[texture(0)]],
                           texture2d<float, access::write> OutTexture [[texture(1)]],
                           constant ShapePixellateParameters &Parameters [[buffer(0)]],
                           device float *ToCPU [[buffer(1)]],
                           uint2 gid [[thread_position_in_grid]])
{
    int BufferWidth = InTexture.get_width();
    int BufferHeight = InTexture.get_height();
    int Width = Parameters.Size;
    int Height = Parameters.Size;
    int CellX0 = int(gid.x / Width);
    int CellY0 = int(gid.y / Height);
    CellX0 = CellX0 * Width;
    CellY0 = CellY0 * Height;
    int CellX1 = CellX0 + (Width - 1);
    if (CellX1 >= BufferWidth)
        {
        CellX1 = BufferWidth - 1;
        }
    int CellY1 = CellY0 + (Height - 1);
    if (CellY1 >= BufferHeight)
        {
        CellY1 = BufferHeight - 1;
        }
    
    float RedAccumulator = 0.0;
    float GreenAccumulator = 0.0;
    float BlueAccumulator = 0.0;
    for (int X = CellX0; X <= CellX1; X++)
        {
        for (int Y = CellY0; Y <= CellY1; Y++)
            {
            float4 Pixel = InTexture.read(uint2(X,Y));
            RedAccumulator = RedAccumulator + Pixel.r ;
            GreenAccumulator = GreenAccumulator + Pixel.g;
            BlueAccumulator = BlueAccumulator + Pixel.b;
            }
        }
    float PixelCount = (float)BufferWidth * (float)BufferHeight;
    float4 MeanPixel = float4(float(RedAccumulator / PixelCount), float(GreenAccumulator / PixelCount),
                              float(BlueAccumulator / PixelCount), 1.0);
    
    for (int X = CellX0; X <= CellX1; X++)
        {
        for (int Y = CellY0; Y <= CellY1; Y++)
            {
            OutTexture.write(MeanPixel, uint2(X,Y));
            }
        }
    
    int TopZone = CellY0 + Parameters.OutlineThickness - 1;
    int BottomZone = CellY1 - Parameters.OutlineThickness - 1;
    int LeftZone = CellX0 + Parameters.OutlineThickness - 1;
    int RightZone = CellX1 - Parameters.OutlineThickness - 1;
    float4 BorderPixel = Parameters.OutlineColor;
    for (int X = CellX0; X <= CellX1; X++)
        {
        for (int Y = CellY0; Y <= CellY1; Y++)
            {
            if (X <= LeftZone || X >= RightZone)
                {
                OutTexture.write(BorderPixel, uint2(X,Y));
                }
            if (Y <= TopZone || Y >= BottomZone)
                {
                OutTexture.write(BorderPixel, uint2(X,Y));
                }
            }
        }
}
