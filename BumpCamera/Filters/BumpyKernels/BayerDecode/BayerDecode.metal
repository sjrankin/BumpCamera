//
//  BayerDecode.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 2/17/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

//https://www.azooptics.com/Article.aspx?ArticleID=1097

#include <metal_stdlib>
using namespace metal;

struct BayerDecodeParameters
{
    uint Order;
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
    float MeanRed = 0.0;
    float MeanGreen = 0.0;
    float MeanBlue = 0.0;
    
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
                GreenSum = GreenSum + InTexture(uint2(gid.x + 1, gid.y)).g;
                }
            if (gid.y == Height - 1)
                {
                //Another corner case - lower left.
                BlueCount = 1.0;
                BlueSum = InTexture.read(uint2(gid.x + 1, gid.y - 1)).b;
                GreenCount = 2.0;
                GreenSum = InTexture.read(uint2(gid.x, gid.y - 1)).g;
                GreenSum = GreenSum + InTexture(uint2(gid.x + 1, gid.y)).g;
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
                GreenSum = GreenSum + InTexture(uint2(gid.x - 1, gid.y)).g;
                }
            if (gid.y == Height - 1)
                {
                //Another corner case - lower right.
                BlueCount = 1.0;
                BlueSum = InTexture.read(uint2(gid.x - 1, gid.y - 1)).b;
                GreenCount = 2.0;
                GreenSum = InTexture.read(uint2(gid.x, gid.y - 1)).g;
                GreenSum = GreenSum + InTexture(uint2(gid.x - 1, gid.y)).g;
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
        if (grid.y == 0)
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
        if (grid.y == Height - 1)
            {
            //On bottom row.
            //Both corner cases were addressed earlier by the left and right sides.
            BlueCount = 2.0;
            BlueSum = InTexture.read(uint2(gid.x - 1, gid.y 1 1)).b;
            BlueSum = BlueSum + InTexture.read(uint2(gid.x + 1, gid.y 1 1)).b;
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
        break;
        }
        
        case 11:
        {
        //On a blue pixel. Need green and red.
        break;
        }
    }
    
    /*
    switch (GridLocation)
    {
        case 0:
        {
        //At red pixel, get green and blue.
        //First, green.
        float GreenCount = 0.0;
        float GreenSum = 0.0;
        if (gid.y == 0)
            {
            //Top row.
            if (gid.x == 0)
                {
                //In upper-left corner of image.
                GreenCount++;
                GreenSum = InTexture.read(uint2(gid.x + 1, gid.y)).g;
                GreenCount++;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y + 1)).g;
                }
            else
                if (gid.x == Width - 1)
                    {
                    //In upper-right corner of image.
                    GreenCount++;
                    GreenSum = InTexture.read(uint2(gid.x - 1, gid.y)).g;
                    GreenCount++
                    GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y + 1)).g;
                    }
            else
                {
                //On the top row (but not in a corner).
                GreenCount++;
                GreenSum = InTexture.read(uint2(gid.x - 1, gid.y)).g;
                GreenCount++;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x + 1, gid.y)).g;
                GreenCount++;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y + 1)).g;
                }
            }
        if (gid.y == Height - 1)
            {
            //Bottom row.
            if (gid.x == 0)
                {
                //In lower-left corner.
                GreenCount++;
                GreenSum = InTexture.read(uint2(gid.x, gid.y - 1)).g;
                GreenCount++;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x + 1, gid.y)).g;
                }
            else
                if (gid.x == Width - 1)
                    {
                    //In lower-right corner.
                    GreenCount++;
                    GreenSum = InTexture.read(uint2(gid.x - 1, gid.y)).g;
                    GreenCount++;
                    GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y - 1)).g;
                    }
            else
                {
                //On the bottom row but not in a corner.
                GreenCount++;
                GreenSum = InTexture.read(uint2(gid.x - 1, gid.y)).g;
                GreenCount++;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x + 1, gid.y)).g;
                GreenCount++;
                GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y - 1)).g;
                }
            }
        
        MeanGreen = GreenSum / GreenCount;
        
        //Next, blue.
        float BlueCount = 0.0;
        float BlueSum = 0.0;
        if (gid.x == 0 && gid.y == 0)
            {
            //Red is in upper-left corner.
            BlueCount++;
            BlueSum = InTexture.read(uint2(gid.x + 1, gid.y + 1)).b;
            }
        if (gid.x == 0 && gid.y > 0)
            {
            //Red is on left border but not in upper-left corner.
            BlueCount++;
            BlueSum = InTexture.read(uint2(gid.x + 1, gid.y - 1)).b;
            BlueCount++;
            BlueSum = BlueSum + InTexture.read(uint2(gid.x + 1, gid.y + 1)).b;
            }
        if (gid.y == 0 && gid.x < Width - 1)
            {
            //Red is on right border but not in upper-right corner.
            BlueCount++;
            BlueSum = InTexture.read(uint2(gid.x + 1, gid.y + 1)).b;
            BlueCount++;
            BlueSum = BlueSum + InTexture.read(uint2(gid.x - 1, gid.y + 1)).b;
            }
        if (gid.y > 0 && gid.x < Width - 1)
            {
            //Red is somewhere in the middle.
            BlueCount++;
            BlueSum = InTexture.read(uint2(gid.x + 1, gid.y - 1)).b;
            BlueCount++;
            BlueSum = BlueSum + InTexture.read(uint2(gid.x + 1, gid.y + 1)).b;
            BlueCount++;
            BlueSum = BlueSum + InTexture.read(uint2(gid.x - 1, gid.y - 1)).b;
            BlueCount++;
            BlueSum = BlueSum + InTexture.read(uint2(gid.x - 1, gid.y + 1)).b;
            }
        MeanBlue = BlueSum / BlueCount;
        
        Final = float4(Source.r, MeanGreen, MeanBlue, 1.0);
        break;
        }
        
        case 1:
        case 10:
        {
        //At green pixel, get red and blue.
        float BlueCount = 0.0;
        float BlueSum = 0.0;
        float RedCount = 0.0;
        float RedSum = 0.0;
        if (gid.x == 0)
            {
            //We're on the left-hand border.
            if (gid.y == Height - 1)
                {
                //We're in the lower-left corner.
                BlueCount++;
                BlueSum = InTexture.read(uint2(gid.x + 1, gid.y)).b;
                RedCount++;
                RedSum = InTexture.read(uint2(gid.x, gid.y - 1)).r;
                }
            else
                {
                //We're on the left side but not lower-left corner.
                BlueCount++;
                BlueSum = InTexture.read(uint2(gid.x + 1, gid.y)).b;
                RedCount++;
                RedSum = InTexture.read(uint2(gid.x, gid.y - 1)).r;
                RedCount++;
                RedSum = RedSum + InTexture.read(uint2(gid.x, gid.y + 1)).r;
                }
            }
        if (gid.x == Width - 1)
            {
            //We're on the right-hand border.
            if (gid.y == 0)
                {
                //We're in the upper-right corner.
                BlueCount++;
                BlueSum = InTexture.read(uint2(gid.x, gid.y - 1)).b;
                RedCount++;
                RedSum = InTexture.read(uint2(gid.x - 1, gid.y)).r;
                }
            else
                {
                //We're somewhere on the right-hand border but not the upper-right corner.
                BlueCount++;
                BlueSum = InTexture.read(uint2(gid.x, gid.y - 1)).b;
                BlueCount++;
                BlueSum = BlueSum + InTexture.read(uint2(gid.x, gid.y + 1)).b;
                RedCount++;
                RedSum = InTexture.read(uint2(gid.x - 1, gid.y)).r;
                }
            }
        if (gid.y == 0)
            {
            //We're on the top border.
            if (gid.x == Width - 1)
                {
                //We're in the upper-right corner.
                BlueCount++;
                BlueSum = InTexture.read(uint2(gid.x, gid.y - 1)).b;
                RedCount++;
                RedSum = InTexture.read(uint2(gid.x - 1, gid.y)).r;
                }
            else
                {
                //We're on the upper border but not in the upper-right corner.
                BlueCount++;
                BlueSum = InTexture.read(uint2(gid.x, gid.y + 1)).b;
                RedCount++;
                RedSum = InTexture.read(uint2(gid.x - 1, gid.y)).r;
                RedCount++;
                RedSum = InTexture.read(uint2(gid.x + 1, gid.y)).r;
                }
            }
        if (gid.y == Height - 1)
            {
            //We're on the bottom row.
            if (gid.x == 0)
                {
                //We're in the lower-left corner.
                RedCount++;
                RedSum = InTexture.read(uint2(gid.x, gid.y - 1)).r;
                BlueCount++;
                BlueSum = InTexture.read(uint2(gid.x + 1, gid.y)).b;
                }
            else
                {
                //We're on the bottom row but not the lower-left corner.
                RedCount++;
                RedSum = InTexture.read(uint2(gid.x, gid.y - 1)).r;
                BlueCount++;
                BlueSum = InTexture.read(uint2(gid.x + 1, gid.y)).b;
                BlueCount++;
                BlueSum = BlueSum + InTexture.read(uint2(gid.x - 1, gid.y)).b;
                }
            }
        if (gid.x > 0 && gid.x < Width - 1 && gid.y > 0 && gid.y < Height - 1)
            {
            //We're somewhere in the middle.
            BlueCount++;
            BlueSum = InTexture.read(uint2(gid.x + 1, gid.y)).b;
            BlueCount++;
            BlueSum = BlueSum + InTexture.read(uint2(gid.x - 1, gid.y)).b;
            RedCount++;
            RedSum = InTexture.read(uint2(gid.x, gid.y - 1)).r;
            RedCount++;
            RedSum = RedSum + InTexture.read(uint2(gid.x, gid.y + 1)).r;
            }
        MeanRed = RedSum / RedCount;
        MeanBlue = BlueSum / BlueCount;
        
        Final = float4(MeanRed, Source.g, MeanBlue, 1.0);
        break;
        }
        
        case 11:
        {
        //At blue pixel, get green and red.
        //First, green.
        float GreenCount = 0.0;
        float GreenSum = 0.0;
        if (gid.x > 0)
            {
            GreenCount++;
            GreenSum = InTexture.read(uint2(gid.x - 1, gid.y)).g;
            }
        if (gid.x < Width - 1)
            {
            //This is probably always true - need to find out and remove if statement if that's the case.
            GreenCount++;
            GreenSum = GreenSum + InTexture.read(uint2(gid.x + 1,gid.y)).g;
            }
        if (gid.y > 0)
            {
            GreenCount++;
            GreenSum = InTexture.read(uint2(gid.x, gid.y - 1)).g;
            }
        if (gid.y < Height - 1)
            {
            //Probably always true.
            GreenCount++;
            GreenSum = GreenSum + InTexture.read(uint2(gid.x, gid.y + 1)).g;
            }
        MeanGreen = GreenSum / GreenCount;
        
        //Next, red.
        float RedCount = 0.0;
        float RedSum = 0.0;
        if (gid.x == Width - 1 && gid.y == Height - 1)
            {
            //Blue is in upper-left corner.
            RedCount++;
            RedSum = InTexture.read(uint2(gid.x + 1, gid.y + 1)).r;
            }
        if (gid.x == 0 && gid.y > 0)
            {
            //Blue is on right border but not in bottom-right corner.
            RedCount++;
            RedSum = InTexture.read(uint2(gid.x - 1, gid.y - 1)).r;
            RedCount++;
            RedSum = RedSum + InTexture.read(uint2(gid.x - 1, gid.y + 1)).r;
            }
        if (gid.y == Height - 1 && gid.x < Width - 1)
            {
            //Blue is on bottom border but not in bottom-right corner.
            RedCount++;
            RedSum = InTexture.read(uint2(gid.x + 1, gid.y - 1)).r;
            RedCount++;
            RedSum = RedSum + InTexture.read(uint2(gid.x - 1, gid.y - 1)).r;
            }
        if (gid.y > 0 && gid.x < Width - 1)
            {
            //Blue is somewhere in the middle.
            RedCount++;
            RedSum = InTexture.read(uint2(gid.x + 1, gid.y - 1)).r;
            RedCount++;
            RedSum = RedSum + InTexture.read(uint2(gid.x + 1, gid.y + 1)).r;
            RedCount++;
            RedSum = RedSum + InTexture.read(uint2(gid.x - 1, gid.y - 1)).r;
            RedCount++;
            RedSum = RedSum + InTexture.read(uint2(gid.x - 1, gid.y + 1)).r;
            }
        MeanRed = RedSum / RedCount;
        
        Final = float4(MeanRed, MeanGreen, Source.b, 1.0);
        break;
        }
    }
     */
    
    OutTexture.write(Final, gid);
}
