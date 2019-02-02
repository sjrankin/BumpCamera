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

constant const uint Top = 0;
constant const uint Bottom = 1;
constant const uint Left = 0;
constant const uint Right = 1;
constant const uint ReflectHorizontally = 0;
constant const uint ReflectVertically = 1;

kernel void MirroringKernel(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            constant MirrorParameters &Mirror [[buffer(0)]],
                            uint2 gid [[thread_position_in_grid]])
{
    float4 InColor = inTexture.read(gid);
    uint2 SourceLocation = gid;
    uint2 NewLocation;
    switch (Mirror.Direction)
    {
    case ReflectHorizontally:
    //horizontal mirroring
    if (Mirror.HorizontalSide == Left)
        {
        //Left-side mirroring
        if (SourceLocation.x > Mirror.HorizontalAxis)
            {
            //The destination pixel has already been written and we don't care about the
            //source pixel on this side with mirroring.
            return;
            }
        NewLocation.x = Mirror.HorizontalAxis + (Mirror.HorizontalAxis - SourceLocation.x);
        NewLocation.y = SourceLocation.y;
        outTexture.write(InColor, NewLocation);
        }
    if (Mirror.HorizontalSide == Right)
        {
        //Right-side mirroring
        if (SourceLocation.x < Mirror.HorizontalAxis)
            {
            //The destination pixel has already been written and we don't care about the
            //source pixel on this side with mirroring.
            return;
            }
        NewLocation.x = Mirror.HorizontalAxis - (SourceLocation.x - Mirror.HorizontalAxis);
        NewLocation.y = SourceLocation.y;
        outTexture.write(InColor, NewLocation);
        }
    break;
    
    case ReflectVertically:
    //vertical mirroring

    if (Mirror.VerticalSide == Top)
        {
        //Top-side mirroring
        if (SourceLocation.y > Mirror.VerticalAxis)
            {
            //The destination pixel has already been written and we don't care about the
            //source pixel on this side with mirroring.
            return;
            }
        NewLocation.y = Mirror.VerticalAxis + (Mirror.VerticalAxis - SourceLocation.y);
        NewLocation.x = SourceLocation.x;
        outTexture.write(InColor, NewLocation);
        }
    if (Mirror.VerticalSide == Bottom)
        {
        //Bottom-side mirroring
        if (SourceLocation.y < Mirror.VerticalAxis)
            {
            //The destination pixel has already been written and we don't care about the
            //source pixel on this side with mirroring.
            return;
            }
        NewLocation.y = Mirror.VerticalAxis - (SourceLocation.y - Mirror.VerticalAxis);
        NewLocation.x = SourceLocation.x;
        outTexture.write(InColor, NewLocation);
        }
    break;
    
    default:
    break;
    }
    
    outTexture.write(InColor, gid);
}
