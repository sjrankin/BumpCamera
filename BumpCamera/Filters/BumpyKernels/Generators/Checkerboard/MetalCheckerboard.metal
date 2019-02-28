//
//  MetalCheckerboard.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 2/28/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct CheckerboardParameters
{
    float4 Q1Color;
    float4 Q2Color;
    float4 Q3Color;
    float4 Q4Color;
    uint BlockSize;
};


kernel void MetalCheckerboard(texture2d<float, access::read> InTexture [[texture(0)]],
                              texture2d<float, access::write> OutTexture [[texture(1)]],
                              constant CheckerboardParameters &Checker [[buffer(0)]],
                              device float *Output [[buffer(1)]],
                              uint2 gid [[thead_position_in_grid]])
{
    float4 OriginalColor = InTexture.read(gid);
    
    float4 FinalColor = OriginalColor;
    
    int XCell = (int)(gid.x / Checker.BlockSize);
    int YCell = (int)(gid.y / Checker.BlockSize);
}
