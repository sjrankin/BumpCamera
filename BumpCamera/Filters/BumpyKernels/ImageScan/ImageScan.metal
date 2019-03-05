//
//  ImageScan.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 3/5/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct ImageScanParameters
{
    uint Action;
};

kernel void ImageScan(texture2d<float, access::read> InTexture [[texture(0)]],
                      constant ImageScanParameters &Parameters [[buffer(0)]],
                      device float *ToCPU [[buffer(1)]],
                      uint2 gid [[thread_position_in_grid]])
{
    float4 InColor = InTexture.read(gid);
}
