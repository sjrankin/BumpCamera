//
//  MaskingKernel.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 3/13/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct MaskingKernelParameters
{
    float4 MaskColor;
};

kernel void MaskingKernel(texture2d<float, access::read> BottomImage [[texture(0)]],
                          texture2d<float, access::read> TopImage [[texture(1)]],
                          texture2d<float, access::write> OutTexture [[texture(2)]],
                          constant MaskingKernelParameters &Parameters [[buffer(0)]],
                          device float *ToCPU [[buffer(1)]],
                          uint2 gid [[thread_position_in_grid]])
{
    float4 BottomColor = BottomImage.read(gid);
    float4 TopColor = TopImage.read(gid);
    
    if (TopColor.r == Parameters.MaskColor.r && TopColor.g == Parameters.MaskColor.g && TopColor.b == Parameters.MaskColor.b)
        {
        OutTexture.write(BottomColor, gid);
        }
    else
        {
        OutTexture.write(TopColor, gid);
        }
}
