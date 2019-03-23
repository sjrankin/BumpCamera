//
//  Convolution.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 3/23/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct ConvolveParameters
{
    int Width;
    int Height;
    int KernelCenterX;
    int KernelCenterY;
};


//http://www.songho.ca/dsp/convolution/convolution.html
kernel void Convolve(texture2d<float, access::read> InTexture [[texture(0)]],
                     texture2d<float, access::write> OutTexture [[texture(1)]],
                     constant ConvolveParameters &Convolve [[buffer(0)]],
                     constant float *Element [[buffer(1)]],
                     device float *ToCPU [[buffer(2)]],
                     uint2 gid [[thread_position_in_grid]])
{
    int ImageWidth = InTexture.get_width();
    int ImageHeight = InTexture.get_height();
    for (int i = 0; i < 100; i++)
        {
        ToCPU[i] = -100.0;
        }
    float Red = 0.0;
    float Green = 0.0;
    float Blue = 0.0;
    float Sum = 0.0;

    int KHStart = gid.x - Convolve.KernelCenterX;
    if (KHStart < 0)
        {
        KHStart = 0;
        }
    int KHEnd = gid.x + Convolve.KernelCenterX;
    if (KHEnd >= ImageWidth)
        {
        KHEnd = ImageWidth - 1;
        }
    int KVStart = gid.y - Convolve.KernelCenterY;
    if (KVStart < 0)
        {
        KVStart = 0;
        }
    int KVEnd = gid.y + Convolve.KernelCenterX;
    if (KVEnd >= ImageHeight)
        {
        KVEnd = ImageHeight - 1;
        }
    int Kdx = 0;
    for (int KY = KVStart; KY <= KVEnd; KY++)
        {
        for (int KX = KHStart; KX <= KHEnd; KX++)
            {
            float4 Pixel = InTexture.read(uint2(KX,KY));
            float K = Element[Kdx];
            Kdx++;
            Red = Red + (Pixel.r * K);
            Green = Green + (Pixel.g * K);
            Blue = Blue + (Pixel.b * K);
            Sum = Sum + K;
            }
        }
    
    /*
    for (int Y = 0; Y < Convolve.Height; Y++)
        {
        int RowIndex = Convolve.Height - 1 - Y;
        for (int X = 0; X < Convolve.Width; X++)
            {
            int ColumnIndex = Convolve.Width - 1 - X;
            int YTest = gid.y + (Convolve.KernelCenterY - RowIndex);
            int XTest = gid.x + (Convolve.KernelCenterX - ColumnIndex);
            if (YTest >= 0 && YTest < ImageHeight && XTest >= 0 && XTest < ImageWidth)
                {
                float4 KColor = InTexture.read(uint2(YTest, XTest));
                int KernelIndex = (YTest * Convolve.Width) + XTest;
                float Multiplier = Element[KernelIndex];
                ToCPU[8] = Multiplier;
                float KRed = KColor.r;
                float KGreen = KColor.g;
                float KBlue = KColor.b;
                Red = Red + (KRed * Multiplier);
                Green = Green + (KGreen * Multiplier);
                Blue = Blue + (KBlue * Multiplier);
                }
            }
        }
     */

    float KernelSize = Convolve.Width * Convolve.Height;
    Sum = Sum == 0 ? 1 : Sum;
    Red = Red / Sum;//KernelSize;
    Green = Green / Sum;//KernelSize;
    Blue = Blue / Sum;//KernelSize;

    OutTexture.write(float4(Red, Green, Blue, 1.0), gid);
}
