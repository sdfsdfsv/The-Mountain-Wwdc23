import SwiftUI

let shaderCode="""
#include <metal_stdlib>

#include <metal_texture>

using namespace metal;

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut vert(constant float *vertices [[buffer(0)]], uint vertexId [[vertex_id]]) {
    VertexOut out;
    out.position = float4(vertices[vertexId * 2]*2-1, vertices[vertexId * 2 + 1]*2-1, 0.0, 1.0);
    return out;
}

fragment float4 frag(VertexOut in [[stage_in]],
                                texture2d<float> iChannel0 [[texture(0)]],
                                sampler mySampler [[ sampler(0) ]],
                                constant float &iTime
                                 [[buffer(0)]],
                                constant float2 &iResolution [[buffer(1)]],
                                constant float &iLightness
                                 [[buffer(2)]],
                                constant float &iHeight
                                 [[buffer(3)]],
                                constant float &iXlocation
                                 [[buffer(4)]],
                                constant float &iRenderCnt
                                 [[buffer(5)]]
                                ) {
    float4 p = float4(in.position.xy/iResolution, 1.0, 1.0) -0.5;
    float4 d = p, t, c;
    p.y+=40;
    p.z+=iXlocation+iTime*20;
    
    for (float i = iRenderCnt; i > 0.0; i -= 0.0013) {
        float s = 0.95;
         t = iChannel0.sample(mySampler, float2(0.3 + p.xz*s/3000.0 )) / s;
         s=s*3;
         t += iChannel0.sample(mySampler, float2(0.3 + p.xz * s / 3000.0)) / s*1.3;
         s=s*5;
         t += iChannel0.sample(mySampler, float2(0.3 + p.xz * s / 3000.0)) / s*1.4;
      
        c = iLightness - t * i;
        if (t.x > p.y * 0.007 + iHeight) break;
        p += d;
    }
    return c;
}
"""
