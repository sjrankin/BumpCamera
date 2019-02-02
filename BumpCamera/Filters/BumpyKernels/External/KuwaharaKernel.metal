//
//  KuwaharaKernel.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 1/28/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


kernel void KuwaharaKernel(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           constant float &R [[buffer(0)]],
                           uint2 gid [[thread_position_in_grid]])
{
    int Radius = int(R);
    float N = float((Radius + 1) * (Radius + 1));
    
    float3 Means[4];
    float3 StDevs[4];
    
    for (int i = 0; i < 4; i++)
        {
        Means[i] = float3(0.0);
        StDevs[i] = float3(0.0);
        }
    
    for (int x = -Radius; x <= Radius; x++)
        {
        for (int y = -Radius; y <= Radius; y++)
            {
            float3 Color = inTexture.read(uint2(gid.x + x, gid.y + y)).rgb;
            
            float3 ColorA = float3(float(x <= 0 && y <= 0)) * Color;
            Means[0] += ColorA;
            StDevs[0] += ColorA * ColorA;
            
            float3 ColorB = float3(float(x >= 0 && y <= 0)) * Color;
            Means[1] += ColorB;
            StDevs[1] += ColorB * ColorB;
            
            float3 ColorC = float3(float(x <= 0 && y >= 0)) * Color;
            Means[2] += ColorC;
            StDevs[2] += ColorC * ColorC;
            
            float3 ColorD = float3(float(x >= 0 && y >= 0)) * Color;
            Means[3] += ColorD;
            StDevs[3] += ColorD * ColorD;
            }
        }
    
    float MinSigma2 = 1e+2;
    float3 ReturnColor = float3(0.0);
    
    for (int j = 0; j < 4; j++)
        {
        Means[j] /= N;
        StDevs[j] = abs(StDevs[j] / N - Means[j] * Means[j]);
        float Sigma2 = StDevs[j].r + StDevs[j].g + StDevs[j].b;
        ReturnColor = (Sigma2 < MinSigma2) ? Means[j] : ReturnColor;
        MinSigma2 = (Sigma2 < MinSigma2) ? Sigma2 : MinSigma2;
        }
    
    outTexture.write(float4(ReturnColor, 1), gid);
}
