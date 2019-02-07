//
//  HSBSwizzling.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 1/27/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ChannelSwizzles
{
    int Channel1;
    int Channel2;
    int Channel3;
    bool HasHSB;
    bool HasCMYK;
    bool InvertRed;
    bool InvertGreen;
    bool InvertBlue;
};

// Compute kernel
// https://medium.com/simple-swift-programming-tips/how-to-convert-rgb-to-hue-in-swift-1d25338cad28
kernel void HSBSwizzling(texture2d<float, access::read> inputTexture  [[ texture(0) ]],
                         texture2d<float, access::write> outputTexture [[ texture(1) ]],
                         constant ChannelSwizzles &Swizzling [[buffer(0)]],
                         uint2 gid [[thread_position_in_grid]])
{
    // Make sure we don't read or write outside of the texture
    if ((gid.x >= inputTexture.get_width()) || (gid.y >= inputTexture.get_height()))
        {
        return;
        }
    
    float4 inputColor = inputTexture.read(gid);
    
    float r = inputColor.r;
    float g = inputColor.g;
    float b = inputColor.b;
    
    float H = 0.0;
    float S = 0.0;
    float L = 0.0;
    float C = 0.0;
    float M = 0.0;
    float Y = 0.0;
    float K = 0.0;
    
    bool RunHSB = Swizzling.HasHSB;
    bool RunCMYK = Swizzling.HasCMYK;
    
    if (RunHSB)
        {
        float MinV = min(r, min(g, b));
        float MaxV = max(r, max(g, b));
        float Delta = MaxV - MinV;
        float Hue = 0.0;
        
        if (Delta != 0)
            {
            if (r == MaxV)
                {
                Hue = (g - b) / Delta;
                }
            else
                if (g == MaxV)
                    {
                    Hue = 2.0 + ((b - r) / Delta);
                    }
                else
                    {
                    Hue = 4.0 + ((r - g) / Delta);
                    }
            
            Hue = Hue * 60.0;
            if (Hue < 0)
                {
                Hue = Hue + 360.0;
                }
            }
        
        float Saturation = MaxV == 0.0 ? 0.0 : (Delta / MaxV);
        float Brightness = MaxV;
        
        H = Hue / 360.0;
        S = Saturation;
        L = Brightness;
        }
    
    if (RunCMYK)
        {
        K = 1.0 - max(r, max(g, b));
        if (K == 0.0)
            {
            C = K;
            M = K;
            Y = K;
            }
        else
            {
            C = (1.0 - r - K) / (1.0 - K);
            M = (1.0 - g - K) / (1.0 - K);
            Y = (1.0 - b - K) / (1.0 - K);
            }
        }
    
    float C1 = 0.0;
    float C2 = 0.0;
    float C3 = 0.0;
    int Channel1 = Swizzling.Channel1;
    switch (Channel1)
    {
        case 0:
        C1 = r;
        break;
        
        case 1:
        C1 = g;
        break;
        
        case 2:
        C1 = b;
        break;
        
        case 3:
        C1 = H;
        break;
        
        case 4:
        C1 = S;
        break;
        
        case 5:
        C1 = L;
        break;
        
        case 6:
        C1 = C;
        break;
        
        case 7:
        C1 = M;
        break;
        
        case 8:
        C1 = Y;
        break;
        
        case 9:
        C1 = K;
        break;
        
        default:
        C1 = H;
        break;
    }
    
    int Channel2 = Swizzling.Channel2;
    switch (Channel2)
    {
        case 0:
        C2 = r;
        break;
        
        case 1:
        C2 = g;
        break;
        
        case 2:
        C2 = b;
        break;
        
        case 3:
        C2 = H;
        break;
        
        case 4:
        C2 = S;
        break;
        
        case 5:
        C2 = L;
        break;
        
        case 6:
        C2 = C;
        break;
        
        case 7:
        C2 = M;
        break;
        
        case 8:
        C2 = Y;
        break;
        
        case 9:
        C2 = K;
        break;
        
        default:
        C2 = S;
        break;
    }
    
    int Channel3 = Swizzling.Channel3;
    switch (Channel3)
    {
        case 0:
        C3 = r;
        break;
        
        case 1:
        C3 = g;
        break;
        
        case 2:
        C3 = b;
        break;
        
        case 3:
        C3 = H;
        break;
        
        case 4:
        C3 = S;
        break;
        
        case 5:
        C3 = L;
        break;
        
        case 6:
        C3 = C;
        break;
        
        case 7:
        C3 = M;
        break;
        
        case 8:
        C3 = Y;
        break;
        
        case 9:
        C3 = K;
        break;
        
        default:
        C3 = L;
        break;
    }
    
    float F1 = C1;
    if (Swizzling.InvertRed)
        {
        F1 = 1.0 - F1;
        }
    float F2 = C2;
    if (Swizzling.InvertGreen)
        {
        F2 = 1.0 - F2;
        }
    float F3 = C3;
    if (Swizzling.InvertBlue)
        {
        F3 = 1.0 - F3;
        }
    
    float4 outputColor = float4(F1, F2, F3, 1.0);
    
    outputTexture.write(outputColor, gid);
}
