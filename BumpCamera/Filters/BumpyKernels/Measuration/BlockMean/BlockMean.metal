//
//  BlockMean.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 3/18/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct BlockMeanParameters
{
    int Width;
    int Height;
    int BlockStride;
    int OriginX;
    int OriginY;
    int RegionWidth;
    int RegionHeight;
};

struct ReturnBlockData
{
    int X;
    int Y;
    float Red;
    float Green;
    float Blue;
    float Alpha;
    int Count;
};

kernel void BlockMean(texture2d<float, access::read> InTexture [[texture(0)]],
                      constant BlockMeanParameters &Parameters [[buffer(0)]],
                      device ReturnBlockData *BlockData [[buffer(1)]],
                      device float *Output [[buffer(2)]],
                      uint2 gid [[thread_position_in_grid]])
{

    for (int Y = Parameters.OriginY; Y < Parameters.OriginY + Parameters.RegionHeight; Y++)
        {
        for (int X = Parameters.OriginX; X < Parameters.OriginX + Parameters.RegionWidth; X++)
            {
            uint2 gid2 = uint2(X,Y);
            Output[0] = Output[0] + 1.0;
            float4 InColor = InTexture.read(gid2);
            int BlockX = X / Parameters.Width;
            int BlockY = Y / Parameters.Height;
            int ResultIndex = (BlockY * Parameters.BlockStride) + BlockX;
            Output[100 + ResultIndex] = Output[100 + ResultIndex] + 1.0;
            Output[1] = float(ResultIndex);
            Output[2] = float(BlockX);
            Output[3] = float(BlockY);
            BlockData[ResultIndex].X = BlockX;
            BlockData[ResultIndex].Y = BlockY;
            BlockData[ResultIndex].Red += InColor.r;
            BlockData[ResultIndex].Green += InColor.g;
            BlockData[ResultIndex].Blue += InColor.b;
            BlockData[ResultIndex].Alpha += InColor.a;
            BlockData[ResultIndex].Count += 1;
            }
        }

/*
    Output[0] = Output[0] + 1.0;
    float4 InColor = InTexture.read(gid);
    int BlockX = gid.x / Parameters.Width;
    int BlockY = gid.y / Parameters.Height;
    int ResultIndex = (BlockY * Parameters.BlockStride) + BlockX;
    Output[100 + ResultIndex] = Output[100 + ResultIndex] + 1.0;
    Output[1] = float(ResultIndex);
    Output[2] = float(BlockX);
    Output[3] = float(BlockY);
    BlockData[ResultIndex].X = BlockX;
    BlockData[ResultIndex].Y = BlockY;
    BlockData[ResultIndex].Red += InColor.r;
    BlockData[ResultIndex].Green += InColor.g;
    BlockData[ResultIndex].Blue += InColor.b;
    BlockData[ResultIndex].Alpha += InColor.a;
    BlockData[ResultIndex].Count += 1;
*/
}
