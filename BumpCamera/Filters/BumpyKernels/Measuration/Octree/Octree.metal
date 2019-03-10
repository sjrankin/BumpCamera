//
//  Octree.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 3/10/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct OctreeParameters
{
    bool ModifyImage;
    bool ReturnOctree;
    float4 Gradient[256];
    bool ConvertToGradient;
    int PaletteSize;
};

struct OctreeResults
{
    int TBD;
};

struct OctNode
{
    int Level;
    bool IsLeaf;
    bool Mark;
    int ColorCount;
    unsigned char Red;
    unsigned char Green;
    unsigned char Blue;
    int Index;
    int ChildCount;
    threadgroup OctNode *Children[8];
    threadgroup OctNode *Next;
    threadgroup OctNode *Previous;
};
/*
threadgroup OctNode *CreateOctNode(int NodeLevel, bool IsLeafNode)
{
    //threadgroup OctNode *NewNode = new OctNode;
}
*/
kernel void Octree(texture2d<float, access::read> InTexture [[texture(0)]],
                   texture2d<float, access::write> OutTexture [[texture(1)]],
                   constant OctreeParameters &Parameters [[buffer(0)]],
                   constant OctreeResults *Results [[buffer(1)]],
                   device float *ToCPU [[buffer(2)]],
                   uint2 gid [[thread_position_in_grid]])
{
    
}
