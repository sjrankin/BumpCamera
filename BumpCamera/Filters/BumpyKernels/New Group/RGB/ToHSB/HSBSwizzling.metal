//
//  HSBSwizzling.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 1/27/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ChannelSwizzles
{
    float Channel1;
    float Channel2;
    float Channel3;
};

// Compute kernel
kernel void HSBSwizzling(texture2d<half, access::read>  inputTexture  [[ texture(0) ]],
                         texture2d<half, access::write> outputTexture [[ texture(1) ]],
                         constant ChannelSwizzles &Swizzling [[buffer(0)]],
                         uint2 gid [[thread_position_in_grid]])
{
    // Make sure we don't read or write outside of the texture
    if ((gid.x >= inputTexture.get_width()) || (gid.y >= inputTexture.get_height()))
        {
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
    
    float C1 = 0.0;
    float C2 = 0.0;
    float C3 = 0.0;
    int Channel1 = (int)Swizzling.Channel1;
    switch (Channel1)
    {
        case 3:
        C1 = H;
        break;
        
        case 4:
        C1 = S;
        break;
        
        case 5:
        C1 = L;
        break;
        
        default:
        C1 = H;
        break;
    }
    
    int Channel2 = (int)Swizzling.Channel2;
    switch (Channel2)
    {
        case 3:
        C2 = H;
        break;
        
        case 4:
        C2 = S;
        break;
        
        case 5:
        C2 = L;
        break;
        
        default:
        C2 = S;
        break;
    }
    
    int Channel3 = (int)Swizzling.Channel3;
    switch (Channel3)
    {
        case 3:
        C3 = H;
        break;
        
        case 4:
        C3 = S;
        break;
        
        case 5:
        C3 = L;
        break;
        
        default:
        C3 = L;
        break;
    }
    
    half4 outputColor = half4(C1, C2, C3, 1.0);
    
    outputTexture.write(outputColor, gid);
}
