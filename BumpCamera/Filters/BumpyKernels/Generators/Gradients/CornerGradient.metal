//
//  CornerGradient.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 2/13/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct CornerGradientParameters
{
    bool HasUL;
    bool HasUR;
    bool HasLL;
    bool HasLR;
    uint2 UL;
    uint2 UR;
    uint2 LL;
    uint2 LR;
    float4 ULColor;
    float4 URColor;
    float4 LLColor;
    float4 LRColor;
    bool IncludeAlpha;
};

uint ULDistance(uint2 Location)
{
    uint X2 = Location.x * Location.x;
    uint Y2 = Location.y * Location.y;
    return uint(sqrt(float(X2 + Y2)));
}

uint URDistance(uint2 Location, uint Width)
{
    uint X2 = Width - Location.x;
    X2 = X2 * X2;
    uint Y2 = Location.y * Location.y;
    return uint(sqrt(float(X2 + Y2)));
}

uint LLDistance(uint2 Location, uint Height)
{
    uint X2 = Location.x * Location.x;
    uint Y2 = Height - Location.y;
    Y2 = Y2 * Y2;
    return uint(sqrt(float(X2 + Y2)));
}

uint LRDistance(uint2 Location, uint Width, uint Height)
{
    uint X2 = Width - Location.x;
    X2 = X2 * X2;
    uint Y2 = Height - Location.y;
    Y2 = Y2 * Y2;
    return uint(sqrt(float(X2 + Y2)));
}

kernel void CornerGradient(texture2d<float, access::read> InTexture [[texture(0)]],
                           texture2d<float, access::write> OutTexture [[texture(1)]],
                           constant CornerGradientParameters &Gradient [[buffer(0)]],
                           uint2 gid [[thread_position_in_grid]])
{
    uint Width = InTexture.get_width();
    uint Height = InTexture.get_height();
    uint ToUL = ULDistance(gid);
    uint ToUR = URDistance(gid, Width);
    uint ToLL = LLDistance(gid, Height);
    uint ToLR = LRDistance(gid, Width, Height);
    float4 GradientColor;
    OutTexture.write(GradientColor, gid);
}
