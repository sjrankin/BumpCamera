//
//  DesaturationKernel.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 1/26/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct DesaturationAdjustment
{
    float DesaturationValue;
};

kernel void DesaturationKernel(texture2d<float, access::read> inTexture [[texture(0)]],
                               texture2d<float, access::write> outTexture [[texture(1)]],
                               constant DesaturationAdjustment &Adjustment [[buffer(0)]],
                               uint2 gid [[thread_position_in_grid]])
{
   float4 inColor = inTexture.read(gid);
   float value = dot(inColor.rgb, float3(0.299, 0.587, 0.144));
   float4 grayColor(value, value, value, 1.0);
   float4 outColor = mix(grayColor, inColor, Adjustment.DesaturationValue);
   outTexture.write(outColor, gid);
}
