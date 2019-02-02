//
//  Mirroring.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 2/2/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct MirrorParameters
{
    //0 = horizontal (left to right), 1 = vertical (top to bottom)
    uint Direction;
    //0 = left, 1 = right
    uint HorizontalSide;
    //0 = top, 1 = bottom
    uint VerticalSide;
    //location of the center horizontal axis
    uint HorizontalAxis;
    //location of the center vertical axis
    uint VerticalAxis;
};

kernel void MirroringKernel(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            constant MirrorParameters &Mirror [[buffer(0)]],
                            uint2 gid [[thread_position_in_grid]])
{
    float4 InColor = inTexture.read(gid);
    uint2 NewLocation;
    switch (Mirror.Direction)
    {
    case 0:
    //horizontal mirroring
    if (Mirror.HorizontalSide == 0)
        {
        //Left-side mirroring
        if (gid.x > Mirror.HorizontalAxis)
            {
            //The destination pixel has already been written and we don't care about the
            //source pixel on this side with mirroring.
            return;
            }
        NewLocation.x = Mirror.HorizontalAxis + (Mirror.HorizontalAxis - gid.x);
        NewLocation.y = gid.y;
        outTexture.write(InColor, NewLocation);
        }
    if (Mirror.HorizontalSide == 1)
        {
        //Right-side mirroring
        if (gid.x < Mirror.HorizontalAxis)
            {
            //The destination pixel has already been written and we don't care about the
            //source pixel on this side with mirroring.
            return;
            }
        NewLocation.x = Mirror.HorizontalAxis - (Mirror.HorizontalAxis - gid.x);
        NewLocation.y = gid.y;
        outTexture.write(InColor, NewLocation);
        }
    break;
    
    case 1:
    //vertical mirroring
    if (Mirror.VerticalSide == 0)
        {
        //Top-side mirroring
        if (gid.x > Mirror.HorizontalAxis)
            {
            //The destination pixel has already been written and we don't care about the
            //source pixel on this side with mirroring.
            return;
            }
        NewLocation.y = Mirror.VerticalAxis + (Mirror.VerticalAxis - gid.y);
        NewLocation.x = gid.x;
        outTexture.write(InColor, NewLocation);
        }
    if (Mirror.VerticalSide == 1)
        {
        //Right-side mirroring
        if (gid.x < Mirror.VerticalAxis)
            {
            //The destination pixel has already been written and we don't care about the
            //source pixel on this side with mirroring.
            return;
            }
        NewLocation.y = Mirror.VerticalAxis - (Mirror.VerticalAxis - gid.y);
        NewLocation.x = gid.x;
        outTexture.write(InColor, NewLocation);
        }
    break;
    
    default:
    break;
    }
    
    outTexture.write(InColor, gid);
}
