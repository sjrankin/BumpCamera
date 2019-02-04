//
//  GridGenerator.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 2/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct GridParameters
{
    uint GridX;
    uint GridY;
    float4 GridColor;
    float4 BackgroundColor;
};

kernel void GridGenerator(texture2d<float, access::read> IgnoreMe [[texture(0)]],
                          texture2d<float, access::write> OutTexture [[texture(1)]],
                          constant GridParameters &GridParams [[buffer(0)]],
                          uint2 gid [[thread_position_in_grid]])
{
    float4 OutColor = GridParams.BackgroundColor;
    if (gid.x % GridParams.GridX == 0)
        {
        OutColor = GridParams.GridColor;
        }
    if (gid.y % GridParams.GridY == 0)
        {
        OutColor = GridParams.GridColor;
        }
    OutTexture.write(OutColor, gid);
}
