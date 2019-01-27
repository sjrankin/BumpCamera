//
//  RGBSwizzling.metal
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
kernel void RGBSwizzling(texture2d<half, access::read>  inputTexture  [[ texture(0) ]],
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
    
    float C1 = 0.0;
    float C2 = 0.0;
    float C3 = 0.0;
    int Channel1 = (int)Swizzling.Channel1;
    switch (Channel1)
    {
        case 0:
        C1 = r;
        break;
        
        case 1:
        C1 = g;
        break;
        
        case 2:
        C1 = b;
        break;
        
        default:
        C1 = r;
        break;
    }
    
    int Channel2 = (int)Swizzling.Channel2;
    switch (Channel2)
    {
        case 0:
        C2 = r;
        break;
        
        case 1:
        C2 = g;
        break;
        
        case 2:
        C2 = b;
        break;
        
        default:
        C2 = g;
        break;
    }
    
    int Channel3 = (int)Swizzling.Channel3;
    switch (Channel3)
    {
        case 0:
        C3 = r;
        break;
        
        case 1:
        C3 = g;
        break;
        
        case 2:
        C3 = b;
        break;
        
        default:
        C3 = b;
        break;
    }
    
    half4 outputColor = half4(C1, C2, C3, 1.0);
    
    outputTexture.write(outputColor, gid);
}
