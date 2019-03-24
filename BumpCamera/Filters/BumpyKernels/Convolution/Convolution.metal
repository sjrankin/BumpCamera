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
    float Factor;
    float Bias;
};

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
    
    //float KernelSize = Convolve.Width * Convolve.Height;
    Sum = Sum == 0 ? 1 : Sum;
    Red = Red / Sum;
    Red = min(max(Red * Convolve.Factor + Convolve.Bias, 0.0), 1.0);
    Green = Green / Sum;
    Green = min(max(Green * Convolve.Factor + Convolve.Bias, 0.0), 1.0);
    Blue = Blue / Sum;
    Blue = min(max(Blue * Convolve.Factor + Convolve.Bias, 0.0), 1.0);
    
    OutTexture.write(float4(Red, Green, Blue, 1.0), gid);
}
