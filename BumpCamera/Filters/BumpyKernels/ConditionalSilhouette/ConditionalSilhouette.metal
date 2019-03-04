//
//  ConditionalSilhouette.metal
//  BumpCamera
//
//  Created by Stuart Rankin on 3/4/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


struct SilhouetteParameters
{
    //0 = hue, 1 = saturation, 2 = brightness
    uint Trigger;
    float HueThreshold;
    float HueRange;
    float SaturationThreshold;
    float SaturationRange;
    float BrightnessThreshold;
    float BrightnessRange;
    bool GreaterThan;
    float4 SilhouetteColor;
};

float4 ToHSB_ForSilhouette(float4 Source)
{
    float r = Source.r;
    float g = Source.g;
    float b = Source.b;
    
    float H = 0.0;
    float S = 0.0;
    float B = 0.0;
    
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
    B = Brightness;
    float4 Results = float4(H, S, B, 1.0);
    return Results;
}

kernel void ConditionalSilhouette(texture2d<float, access::read> InTexture [[texture(0)]],
                                  texture2d<float, access::write> OutTexture [[texture(1)]],
                                  constant SilhouetteParameters &Parameters [[buffer(0)]],
                                  device float *Results [[buffer(1)]],
                                  uint2 gid [[thread_position_in_grid]])
{
    float4 InPixel = InTexture.read(gid);
    float4 OutPixel = float4(0.0, 0.0, 0.0, 1.0);
    float4 HSB = ToHSB_ForSilhouette(InPixel);
    bool ApplySilhouette = false;
    switch (Parameters.Trigger)
    {
        case 0:
        {
        //Hue
        float HalfHueRange = Parameters.HueRange / 2.0;
        if (HSB.r >= HalfHueRange && HSB.r <= Parameters.HueThreshold + HalfHueRange)
            {
            ApplySilhouette = true;
            }
        break;
        }
        
        case 1:
        {
        //Saturation
        float HalfSaturationRange = Parameters.SaturationRange / 2.0;
        if (HSB.g >= HalfSaturationRange && HSB.g <= Parameters.SaturationThreshold + HalfSaturationRange)
            {
            ApplySilhouette = true;
            }
        break;
        }
        
        case 2:
        {
        //Brightness
        if (Parameters.GreaterThan)
            {
            if (HSB.b > Parameters.BrightnessThreshold)
                {
                ApplySilhouette = true;
                }
            }
        else
            {
            if (HSB.b < Parameters.BrightnessThreshold)
                {
                ApplySilhouette = true;
                }
            }
        break;
        }
    }
    
    if (ApplySilhouette)
        {
        OutPixel = Parameters.SilhouetteColor;
        }
    else
        {
        OutPixel = InPixel;
        }
    
    OutTexture.write(OutPixel, gid);
}
