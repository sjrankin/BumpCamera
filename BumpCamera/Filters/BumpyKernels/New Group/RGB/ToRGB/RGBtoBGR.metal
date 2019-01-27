//
//  RGBtoBGR.metal
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
kernel void RGBtoBGR(texture2d<half, access::read>  inputTexture  [[ texture(0) ]],
                     texture2d<half, access::write> outputTexture [[ texture(1) ]],
                     constant RelativeStrengths &Strengths [[buffer(0)]],
                     uint2 gid [[thread_position_in_grid]])
{
    // Make sure we don't read or write outside of the texture
    if ((gid.x >= inputTexture.get_width()) || (gid.y >= inputTexture.get_height())) {
        return;
    }
    
    half4 inputColor = inputTexture.read(gid);
    
    half4 outputColor = half4(inputColor.b, inputColor.g, inputColor.r, 1.0);
    
    outputTexture.write(outputColor, gid);
}
