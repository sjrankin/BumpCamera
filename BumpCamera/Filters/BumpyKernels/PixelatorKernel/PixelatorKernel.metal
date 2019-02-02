//
//  PixelatorKernel.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 1/11/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void PixelatorKernel(texture2d<float, access::read> inTexture [[ texture(0) ]],
                            texture2d<float, access::write> outTexture [[ texture(1) ]],
                            constant float &PixelWidth [[ buffer(0) ]],
                            constant float &PixelHeight [[ buffer(1) ]],
                            uint2 gid [[thread_position_in_grid]])
{
    /*
    uint width = uint(PixelWidth);
    uint height = uint(PixelHeight);
    const uint PixellatedGid = uint2((gid.x / width) * width, (gid.y / height) * height);
    const float4 ColorAtPixel = InTexture.read(PixellatedGid);
    outTexture.write(ColorAtPixel, gid);
     */
}
