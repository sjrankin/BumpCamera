//
//  GrayscaleToRGB.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 2/17/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


kernel void GrayscaleToRGB(texture2d<float, access::read> InTexture [[texture(0)]],
                           texture2d<float, access::write> OutTexture [[texture(1)]],
                           device float *Output [[buffer(0)]],
                           uint2 gid [[thread_position_in_grid]])
{
    /*
    uint Gray = InTexture.read(gid);
    float GrayLevel = (float)Gray / 255.0;
    float4 Color = float4(GrayLevel, GrayLevel, GrayLevel, 1.0);
    OutTexture.write(Color, gid);
     */
}
