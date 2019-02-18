//
//  BayerDecode.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 2/17/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

//https://www.azooptics.com/Article.aspx?ArticleID=1097
//http://slazebni.cs.illinois.edu/spring19/assignment0.html

#include <metal_stdlib>
using namespace metal;

struct BayerDecodeParameters
{
    //0 = RGGB, 1 = BGGR
    uint Order;
    //0 = Naive nearest neighbor, 1 = 5x5 pixel averaging
    uint Method;
};

constant const uint LinearInterpolation = 0;
constant const uint PixelAveraging5x5 = 1;

constant const uint BayerRGGB = 0;
//
// RGR  (0,0), (1,0), (2,0)
// GBG  (0,1), (1,1), (2,1)
// RGR  (0,2), (1,2), (2,2)
//
// R always has even Y coordinates.
// B always as odd Y coordinates.
// For even Y coordinates, G always has odd X coordinates.
// For odd Y coordinates, G always has even X coordinates.
//
constant const uint BayerBGGR = 1;
//
// BGB  (0,0), (1,0), (2,0)
// GRG  (0,1), (1,1), (2,1)
// BGB  (0,2), (1,2), (2,2)
//

kernel void BayerDecode(texture2d<float, access::read> InTexture [[texture(0)]],
                        texture2d<float, access::write> OutTexture [[texture(1)]],
                        constant BayerDecodeParameters &DecodeParam [[buffer(0)]],
                        device float *Output [[buffer(1)]],
                        uint2 gid [[thread_position_in_grid]])
{
    uint Width = InTexture.get_width();
    uint Height = InTexture.get_height();
    uint OnEvenRow = gid.x % 2 == 0 ? 0 : 1;
    uint OnEvenColumn = gid.y % 2 == 0 ? 0 : 1;
    uint GridLocation = (OnEvenColumn * 10) + OnEvenRow;
    // GridLocation  Row   Column  Color (RGGB)     Color (BGGR)
    // 0             Even  Even    Red              Blue
    // 1             Odd   Even    Green            Green
    // 10            Even  Odd     Green            Green
    // 11            Odd   Odd     Blue             Red
    
    //Guard against going out of bounds.
    if (gid.x + 1 >= Width || gid.x == 0)
        {
        return;
        }
    if (gid.y + 1 >= Height || gid.y == 0)
        {
        return;
        }
    
    float4 Source = InTexture.read(gid);
    float4 Final = float4(0.0, 0.0, 0.0, 1.0);
    
    switch (GridLocation)
    {
        case 0:
        {
        //On a red pixel, need green and blue.
        float BlueSum = 0.0;
        float BlueCount = 0.0;
        float GreenSum = 0.0;
        float GreenCount = 0.0;
        if (gid.x > 0 && gid.y > 0 && gid.x < Width - 1 && gid.y < Height - 1)
            {
            //In the middle.
            BlueCount = 4.0;
            BlueSum = InTexture.read(uint2(gid.x - 1, gid.y - 1)).b;
            BlueSum = BlueSum + InTexture.read(uint2(gid.x - 1, gid.y + 1)).b;
            BlueSum = BlueSum + InTexture.read(uint2(gid.x + 1, gid.y - 1)).b;
            BlueSum = BlueSum + InTexture.read(uint2(gid.x + 1, gid.y + 1)).b;
            GreenCount = 4.0;
            GreenSum = InTexture.read(uint2(gid.x - 1, gid.y)).g;
            GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y - 1)).g;
            GreenSum = GreenSum + InTexture.read(uint2(gid.x + 1, gid.y)).g;
            GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y + 1)).g;
            }
        if (gid.x == 0)
            {
            //On the left side.
            if (gid.y == 0)
                {
                //Special case - literally a corner case. Pixel is in upper-left corner.
                BlueCount = 1.0;
                BlueSum = InTexture.read(uint2(gid.x + 1, gid.y + 1)).b;
                GreenCount = 2.0;
                GreenSum = InTexture.read(uint2(gid.x, gid.y + 1)).g;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x + 1, gid.y)).g;
                }
            if (gid.y == Height - 1)
                {
                //Another corner case - lower left.
                BlueCount = 1.0;
                BlueSum = InTexture.read(uint2(gid.x + 1, gid.y - 1)).b;
                GreenCount = 2.0;
                GreenSum = InTexture.read(uint2(gid.x, gid.y - 1)).g;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x + 1, gid.y)).g;
                }
            if (gid.y > 0 && gid.y < Height - 1)
                {
                //On the left side but not on a corner.
                BlueCount = 2.0;
                BlueSum = InTexture.read(uint2(gid.x + 1, gid.y - 1)).b;
                BlueSum = BlueSum + InTexture.read(uint2(gid.x + 1, gid.y + 1)).b;
                GreenCount = 2.0;
                GreenSum = InTexture.read(uint2(gid.x, gid.y - 1)).g;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y + 1)).g;
                }
            }
        if (gid.x == Width - 1)
            {
            //On the right side.
            if (gid.y == 0)
                {
                //Special case - pixel is in upper-right corner.
                BlueCount = 1.0;
                BlueSum = InTexture.read(uint2(gid.x - 1, gid.y - 1)).b;
                GreenCount = 2.0;
                GreenSum = InTexture.read(uint2(gid.x, gid.y + 1)).g;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x - 1, gid.y)).g;
                }
            if (gid.y == Height - 1)
                {
                //Another corner case - lower right.
                BlueCount = 1.0;
                BlueSum = InTexture.read(uint2(gid.x - 1, gid.y - 1)).b;
                GreenCount = 2.0;
                GreenSum = InTexture.read(uint2(gid.x, gid.y - 1)).g;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x - 1, gid.y)).g;
                }
            if (gid.y > 0 && gid.y < Height - 1)
                {
                //On the left side but not on a corner.
                BlueCount = 2.0;
                BlueSum = InTexture.read(uint2(gid.x - 1, gid.y - 1)).b;
                BlueSum = BlueSum + InTexture.read(uint2(gid.x - 1, gid.y + 1)).b;
                GreenCount = 2.0;
                GreenSum = InTexture.read(uint2(gid.x, gid.y - 1)).g;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y + 1)).g;
                }
            }
        if (gid.y == 0)
            {
            //On top row.
            //Both corner cases were addressed earlier by the left and right sides.
            BlueCount = 2.0;
            BlueSum = InTexture.read(uint2(gid.x - 1, gid.y + 1)).b;
            BlueSum = BlueSum + InTexture.read(uint2(gid.x + 1, gid.y + 1)).b;
            GreenCount = 3.0;
            GreenSum = InTexture.read(uint2(gid.x - 1, gid.y)).g;
            GreenSum = GreenSum + InTexture.read(uint2(gid.x + 1, gid.y)).g;
            GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y + 1)).g;
            }
        if (gid.y == Height - 1)
            {
            //On bottom row.
            //Both corner cases were addressed earlier by the left and right sides.
            BlueCount = 2.0;
            BlueSum = InTexture.read(uint2(gid.x - 1, gid.y - 1)).b;
            BlueSum = BlueSum + InTexture.read(uint2(gid.x + 1, gid.y - 1)).b;
            GreenCount = 3.0;
            GreenSum = InTexture.read(uint2(gid.x - 1, gid.y)).g;
            GreenSum = GreenSum + InTexture.read(uint2(gid.x + 1, gid.y)).g;
            GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y - 1)).g;
            }
        
        float MeanGreen = GreenSum / GreenCount;
        float MeanBlue = BlueSum / BlueCount;
        Final = float4(Source.r, MeanGreen, MeanBlue, 1.0);
        break;
        }
        
        case 1:
        case 10:
        {
        //On a green pixel, need blue and red.
        float BlueSum = 0.0;
        float BlueCount = 0.0;
        float RedSum = 0.0;
        float RedCount = 0.0;
        
        if (gid.x > 0 && gid.y > 0 && gid.x < Width - 1 && gid.y < Height - 1)
            {
            //In the middle.
            BlueCount = 2.0;
            BlueSum = InTexture.read(uint2(gid.x - 1, gid.y)).b;
            BlueSum = BlueSum + InTexture.read(uint2(gid.x + 1, gid.y)).b;
            RedCount = 2.0;
            RedSum = InTexture.read(uint2(gid.x, gid.y - 1)).r;
            RedSum = RedSum + InTexture.read(uint2(gid.x, gid.y + 1)).r;
            }
        if (gid.x == 0)
            {
            //Left side.
            if (gid.y == 0)
                {
                //Upper-left corner.
                BlueCount = 1.0;
                BlueSum = InTexture.read(uint2(gid.x + 1, gid.y)).b;
                RedCount = 1.0;
                RedSum = InTexture.read(uint2(gid.x, gid.y + 1)).r;
                }
            if (gid.y == Height - 1)
                {
                //Lower-left corner.
                BlueCount = 1.0;
                BlueSum = InTexture.read(uint2(gid.x + 1, gid.y)).b;
                RedCount = 1.0;
                RedSum = InTexture.read(uint2(gid.x, gid.y - 1)).r;
                }
            if (gid.y > 0 && gid.y < Height - 1)
                {
                //On the left side but not in a corner.
                BlueCount = 1.0;
                BlueSum = InTexture.read(uint2(gid.x + 1, gid.y)).b;
                RedCount = 2.0;
                RedSum = InTexture.read(uint2(gid.x, gid.y - 1)).r;
                RedSum = RedSum + InTexture.read(uint2(gid.x, gid.y + 1)).r;
                }
            }
        if (gid.x == Width - 1)
            {
            //Right side.
            if (gid.y == 0)
                {
                //Upper-right corner.
                BlueCount = 1.0;
                BlueSum = InTexture.read(uint2(gid.x, gid.y + 1)).b;
                RedCount = 1.0;
                RedSum = InTexture.read(uint2(gid.x - 1, gid.y)).r;
                }
            if (gid.y == Height - 1)
                {
                //Lower-right corner.
                BlueCount = 1.0;
                BlueSum = InTexture.read(uint2(gid.x, gid.y - 1)).b;
                RedCount = 1.0;
                RedSum = InTexture.read(uint2(gid.x - 1, gid.y)).r;
                }
            if (gid.y > 0 && gid.y < Height - 1)
                {
                //On the right side but not in a corner.
                BlueCount = 2.0;
                BlueSum = InTexture.read(uint2(gid.x, gid.y - 1)).b;
                BlueSum = BlueSum + InTexture.read(uint2(gid.x, gid.y + 1)).b;
                RedCount = 1.0;
                RedSum = InTexture.read(uint2(gid.x - 1, gid.y)).r;
                }
            }
        if (gid.y == 0)
            {
            //On the top edge - don't worry about corners as they've already been taken care of above.
            BlueCount = 1.0;
            BlueSum = InTexture.read(uint2(gid.x, gid.y + 1)).b;
            RedCount = 2.0;
            RedSum = InTexture.read(uint2(gid.x - 1, gid.y)).r;
            RedSum = RedSum + InTexture.read(uint2(gid.x + 1, gid.y)).r;
            }
        if (gid.y == Height - 1)
            {
            //On the bottom edge - corners already taken care of.
            BlueCount = 2.0;
            BlueSum = InTexture.read(uint2(gid.x - 1, gid.y)).b;
            BlueSum = BlueSum + InTexture.read(uint2(gid.x + 1, gid.y)).b;
            RedCount = 1.0;
            RedSum = InTexture.read(uint2(gid.x, gid.y - 1)).r;
            }
        
        float MeanRed = RedSum / RedCount;
        float MeanBlue = BlueSum / BlueCount;
        Final = float4(MeanRed, Source.g, MeanBlue, 1.0);
        break;
        }
        
        case 11:
        {
        //On a blue pixel. Need green and red.
        float GreenSum = 0.0;
        float GreenCount = 0.0;
        float RedSum = 0.0;
        float RedCount = 0.0;
        
        if (gid.x > 0 && gid.x < Width - 1 && gid.y > 0 && gid.y < Height - 1)
            {
            //In the middle of the grid.
            GreenCount = 4.0;
            GreenSum = InTexture.read(uint2(gid.x, gid.y - 1)).g;
            GreenSum = GreenSum + InTexture.read(uint2(gid.x + 1, gid.y)).g;
            GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y + 1)).g;
            GreenSum = GreenSum + InTexture.read(uint2(gid.x - 1, gid.y)).g;
            RedCount = 4.0;
            RedSum = InTexture.read(uint2(gid.x - 1, gid.y - 1)).r;
            RedSum = RedSum + InTexture.read(uint2(gid.x + 1, gid.y - 1)).r;
            RedSum = RedSum + InTexture.read(uint2(gid.x + 1, gid.y + 1)).r;
            RedSum = RedSum + InTexture.read(uint2(gid.x - 1, gid.y + 1)).r;
            }
        if (gid.x == 0)
            {
            //On left side of grid.
            if (gid.y == 0)
                {
                //In upper-left corner.
                GreenCount = 2.0;
                GreenSum = InTexture.read(uint2(gid.x + 1, gid.y)).b;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y + 1)).b;
                RedCount = 1.0;
                RedSum = InTexture.read(uint2(gid.x + 1, gid.y + 1)).r;
                }
            if (gid.y == Height - 1)
                {
                //In lower-left corner.
                GreenCount = 2.0;
                GreenSum = InTexture.read(uint2(gid.x + 1, gid.y - 1)).b;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x + 1, gid.y)).b;
                RedCount = 1.0;
                RedSum = InTexture.read(uint2(gid.x + 1, gid.y - 1)).r;
                }
            if (gid.y > 0 && gid.y < Height - 1)
                {
                //On the left side but not in a corner.
                GreenCount = 3.0;
                GreenSum = InTexture.read(uint2(gid.x, gid.y - 1)).g;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y + 1)).g;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x + 1, gid.y)).g;
                RedCount = 2.0;
                RedSum = InTexture.read(uint2(gid.x + 1, gid.y - 1)).r;
                RedSum = RedSum + InTexture.read(uint2(gid.x + 1, gid.y + 1)).r;
                }
            }
        if (gid.x == Width - 1)
            {
            //On right side of grid.
            if (gid.y == 0)
                {
                //In upper-right corner.
                GreenCount = 2.0;
                GreenSum = InTexture.read(uint2(gid.x - 1, gid.y)).b;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y + 1)).b;
                RedCount = 1.0;
                RedSum = InTexture.read(uint2(gid.x - 1, gid.y + 1)).r;
                }
            if (gid.y == Height - 1)
                {
                //In lower-right corner.
                GreenCount = 2.0;
                GreenSum = InTexture.read(uint2(gid.x, gid.y - 1)).b;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x - 1, gid.y)).b;
                RedCount = 1.0;
                RedSum = InTexture.read(uint2(gid.x - 1, gid.y - 1)).r;
                }
            if (gid.y > 0 && gid.y < Height - 1)
                {
                //On the left side but not in a corner.
                GreenCount = 3.0;
                GreenSum = InTexture.read(uint2(gid.x, gid.y - 1)).g;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y + 1)).g;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x - 1, gid.y)).g;
                RedCount = 2.0;
                RedSum = InTexture.read(uint2(gid.x - 1, gid.y - 1)).r;
                RedSum = RedSum + InTexture.read(uint2(gid.x - 1, gid.y + 1)).r;
                }
            }
        if (gid.y == 0)
            {
            //Top row - corner cases already taken care of.
            GreenCount = 3.0;
            GreenSum = InTexture.read(uint2(gid.x - 1, gid.y)).g;
            GreenSum = GreenSum + InTexture.read(uint2(gid.x + 1, gid.y)).g;
            GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y + 1)).g;
            RedCount = 2.0;
            RedSum = InTexture.read(uint2(gid.x - 1, gid.y + 1)).r;
            RedSum = RedSum + InTexture.read(uint2(gid.x + 1, gid.y + 1)).r;
            }
        if (gid.y == Height - 1)
            {
            //Bottom row - corner cases already taken care of.
            GreenCount = 3.0;
            GreenSum = InTexture.read(uint2(gid.x - 1, gid.y)).g;
            GreenSum = GreenSum + InTexture.read(uint2(gid.x + 1, gid.y)).g;
            GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y - 1)).g;
            RedCount = 2.0;
            RedSum = InTexture.read(uint2(gid.x - 1, gid.y - 1)).r;
            RedSum = RedSum + InTexture.read(uint2(gid.x + 1, gid.y - 1)).r;
            }
        
        float MeanRed = RedSum / RedCount;
        float MeanGreen = GreenSum / GreenCount;
        Final = float4(MeanRed, MeanGreen, Source.b, 1.0);
        break;
        }
    }
    
    OutTexture.write(Final, gid);
}
