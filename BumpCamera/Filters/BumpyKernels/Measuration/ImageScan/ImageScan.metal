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
    float4 ColorToCount;
};

kernel void ImageScan(texture2d<float, access::read> InTexture [[texture(0)]],
                      constant ImageScanParameters &Parameters [[buffer(0)]],
                      device float *ToCPU [[buffer(1)]],
                      uint2 gid [[thread_position_in_grid]])
{
    float4 InColor = InTexture.read(gid);
    
    switch (Parameters.Action)
    {
        case 0:
        break;
        
        case 6:
        if (InColor.r == Parameters.ColorToCount.r &&
            InColor.g == Parameters.ColorToCount.g &&
            InColor.b == Parameters.ColorToCount.b)
            {
            ToCPU[0] = ToCPU[0] + 1;
            }
        break;
    }
}
