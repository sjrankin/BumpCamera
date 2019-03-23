//
//  GradientToAlpha.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 3/23/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


kernel void GradientToAlpha(texture2d<float, access::read> InImage [[texture(0)]],
                            texture2d<float, access::read> Gradient [[texture(1)]],
                            texture2d<float, access::write> OutImage [[texture(2)]],
                            device float *ToCPU [[buffer(0)]],
                            uint2 gid [[thread_position_in_grid]])
{
    float4 InColor = InImage.read(gid);
    float4 GradientColor = Gradient.read(gid);
    
    float Mean = (GradientColor.r + GradientColor.g + GradientColor.b) / 3.0;
    float4 OutColor = float4(InColor.r, InColor.g, InColor.b, Mean);
    
    OutImage.write(OutColor, gid);
}
