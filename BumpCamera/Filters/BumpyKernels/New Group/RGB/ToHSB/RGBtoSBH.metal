//
//  RGBtoSBH.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 1/27/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct RelativeStrengths
{
    float Red;
    float Green;
    float Blue;
    float Hue;
    float Saturation;
    float Brightness;
    float Cyan;
    float Magenta;
    float Black;
};

// Compute kernel
kernel void RGBtoSBH(texture2d<half, access::read>  inputTexture  [[ texture(0) ]],
                     texture2d<half, access::write> outputTexture [[ texture(1) ]],
                     constant RelativeStrengths &Strengths [[buffer(0)]],
                     uint2 gid [[thread_position_in_grid]])
{
    // Make sure we don't read or write outside of the texture
    if ((gid.x >= inputTexture.get_width()) || (gid.y >= inputTexture.get_height())) {
        return;
    }
    
    half4 inputColor = inputTexture.read(gid);
    
    float r = inputColor.r;
    float g = inputColor.g;
    float b = inputColor.b;
    
    int CMax = max(r, max(g, b));
    int CMin = min(r, min(g, b));
    
    float L = float(CMax) / 255.0;
    float S = 0.0;
    if (CMax != 0)
        {
        S = float(CMax - CMin) / float(CMax);
        }
    float H = 0.0;
    if (S > 0.0)
        {
        float RedC = (float(CMax) - r) / float(CMax - CMin);
        float GreenC = (float(CMax) - g) / float(CMax - CMin);
        float BlueC = (float(CMax) - b) / float(CMax - CMin);
        if (int(r) == CMax)
            {
            H = BlueC - GreenC;
            }
        else
            {
            if (int(g) == CMax)
                {
                H = 2.0 + RedC - BlueC;
                }
            else
                {
                H = 4.0 + GreenC - RedC;
                }
            }
        H = H / 6.0;
        if (H < 0.0)
            {
            H = H + 1.0;
            }
        }
    
    half4 outputColor = half4(S * Strengths.Saturation, L * Strengths.Brightness, H * Strengths.Hue, 1.0);
    
    outputTexture.write(outputColor, gid);
}

