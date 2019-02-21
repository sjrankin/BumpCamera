//
//  FindPixelKernel.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 2/21/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

/*
struct FindPixelParameters
{
    //0 = Brightest pixel, 1 = darkest pixel, 2 = closest to white, 3 = closest to black, 4 = closest to passed color
    uint FindWhat;
    //If FindWhat is 4, look for this color.
    float4 FindMe;
    //If true, stop execution on first exact match. Otherwise, last exact match will be returned.
    bool ReturnOnFirst;
};

kernel void FindPixelKernel(texture2d<float, access::read> InTexture [[texture(0)]],
                            constant FindPixelParameters &FindPixel [[buffer(0)]],
                            device uint2 *Locations [[buffer(1)]]
                            uint2 gid [[thread_position_in_grid]])
{
    
}
*/
