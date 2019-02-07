//
//  GrayscaleKernel.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 1/27/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct GrayscaleParameters
{
    int Command;
    float RMultiplier;
    float GMultiplier;
    float BMultiplier;
    int Test;
};


//http://www.tannerhelland.com/3643/grayscale-image-algorithm-vb6/
kernel void GrayscaleKernel(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            constant GrayscaleParameters &Grayscale [[buffer(0)]],
                            //device float *ToCPU [[buffer(2)]],
                            uint2 gid [[thread_position_in_grid]])
{
    float4 InColor = inTexture.read(gid);
    float r = InColor.r;
    float g = InColor.g;
    float b = InColor.b;
    float gray = 0.0;

    //for (int i = 0; i < 10; i++)
    //    {
    //    ToCPU[i] = (float)i;
    //    }
    
    switch (Grayscale.Command)
    {
        case 0:
        //Mean
        gray = (r + g + b) / 3.0;
        break;
        
        case 1:
        //Red
        gray = r;
        break;
        
        case 2:
        //Green
        gray = g;
        break;
        
        case 3:
        //Blue
        gray = b;
        break;
        
        case 4:
        //Luma/luminance for eye
        gray = ((r * 0.3) + (g * 0.59) + (b * 0.11));
        break;
        
        case 5:
        //BT.601
        gray = ((r * 0.299) + (g * 0.587) + (b * 0.114));
        break;
        
        case 6:
        //BT.709
        gray = ((r * 0.2126) + (g * 0.7152) + (b * 0.0722));
        break;
        
        case 7:
        //Desaturation
        gray = (max(r, max(g, b)) + min(r, min(g, b))) / 2.0;
        break;
        
        case 8:
        //Maximum decomposition
        gray = max(r, max(g, b));
        break;
        
        case 9:
        //Minimum decomposition
        gray = min(r, min(g, b));
        break;
        
        case 10:
        //Cyan channel
        gray = (g + b) / 2.0;
        break;
        
        case 11:
        //Magenta channel
        gray = (r + b) /  2.0;
        break;
        
        case 12:
        //Yellow channel
        gray = (r + g) /  2.0;
        break;
        
        case 13:
        case 14:
        case 15:
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
        
        float H = Hue / 360.0;
        float S = Saturation;
        float L = Brightness;
        if (Grayscale.Command == 13)
            {
            gray = H;
            }
        if (Grayscale.Command == 14)
            {
            gray = S;
            }
        if (Grayscale.Command == 15)
            {
            gray = L;
            }
        break;
        }
        
        case 100:
        //Multiply by parameters
        gray = ((r * Grayscale.RMultiplier) + (g * Grayscale.GMultiplier) + (b * Grayscale.BMultiplier));
        if (gray > 1.0)
            {
            gray = 1.0;
            }
        break;
        
        default:
        gray = r;
        break;
    }
    
    float4 outputColor = float4(gray, gray, gray, 1.0);
    outTexture.write(outputColor, gid);
}
