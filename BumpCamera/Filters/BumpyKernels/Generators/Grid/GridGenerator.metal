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
    uint Width;
    float4 GridColor;
    float4 BackgroundColor;
    bool InvertGridColor;
    bool InvertBackgroundColor;
};

/// Draw a grid on the output texture. The input texture can be used as the source for the
/// output if the user so desires. At the very least, this kernel uses the dimensions of
/// the input texture.
kernel void GridGenerator(texture2d<float, access::read> InTexture [[texture(0)]],
                          texture2d<float, access::write> OutTexture [[texture(1)]],
                          constant GridParameters &GridParams [[buffer(0)]],
                          uint2 gid [[thread_position_in_grid]])
{
    //Get the basic source pixel that will function as the background unless it's
    //in the location where we need to draw a line.
    float4 OriginalColor = InTexture.read(gid);
    
    //Get the possible background color. Unless the background color's alpha value is less than
    //0.0, it will be used instead of the original color.
    float4 OutColor = GridParams.BackgroundColor;
    if (OutColor.a < 1.0)
        {
        //The background color's alpha value is less than 0.0, so use the original pixel
        //instead of the passed background color.
        OutColor = OriginalColor;
        }
    if (GridParams.InvertBackgroundColor)
        {
        //The invert background color flag is true, so invert the pixel and use it
        //instead fo the passed background color.
        OutColor = float4(1.0 - OriginalColor.r, 1.0 - OriginalColor.g, 1.0 - OriginalColor.b, 1.0);
        }
    
    //Get the grid color.
    float4 GridColor = GridParams.GridColor;
    if (GridParams.InvertGridColor)
        {
        //If the invert grid color is true, invert the background color and use that
        //instead of the passed color.
        GridColor = float4(1.0 - OriginalColor.r, 1.0 - OriginalColor.g, 1.0 - OriginalColor.b, 1.0);
        }
    
    //Draw the grid.
    if (gid.x % GridParams.GridX == 0)
        {
        //We're at an even multiple of the horizontal grid size - time to draw a grid line pixel.
        OutColor = GridColor;
        }
    if (gid.y % GridParams.GridY == 0)
        {
        //We're at an even multiple of the vertical grid size - time to draw a grid line pixel.
        OutColor = GridColor;
        }
    
    OutTexture.write(OutColor, gid);
}
