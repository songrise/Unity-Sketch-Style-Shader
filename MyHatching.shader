// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/HatchingShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _NormalTex ("Normal Texture", 2D) = "bump" { }
        _Hatch0 ("Hatch0", 2D) = "white" { }
        _Hatch1 ("Hatch1", 2D) = "white" { }
        _Hatch2 ("Hatch2", 2D) = "white" { }
        _Hatch3 ("Hatch3", 2D) = "white" { }
        _Hatch4 ("Hatch4", 2D) = "white" { }
        _Hatch5 ("Hatch5", 2D) = "white" { }
        _OutlineMask ("Outline Mask Texture", 2D) = "black" { }
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineWidth ("Outline Width", Float) = 0



        _Threshold ("Threshold", Range(0.0, 1.0)) = 0.5
        _BlendFactor("Blend Factor", Range(1.0, 10.0)) = 10.0
        _Density ("Density", Range(0.0, 1.0)) = 0.6
        _Roughness ("Roughness", Range(0.1, 30)) = 8.0
        [Enum(OFF, 0, ON, 1)] _Hoge ("Toggle Gray Scale", int) = 0
        [Enum(OFF, 0, FRONT, 1, BACK, 2)] _CullMode ("Cull Mode", int) = 0

        
    }
    
    SubShader
    {
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull[_CullMode]
        LOD 100

        CGINCLUDE
        #pragma target 3.0
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile_fog
        
        #include "UnityCG.cginc"
        #include "AutoLight.cginc"
        #include "UnityPBSLighting.cginc"
        
        float2x2 rotateFnc(float b)
        {
            float alpha = b * UNITY_PI / 180.0;
            float sina, cosa;
            sincos(alpha, sina, cosa);
            return float2x2(cosa, -sina, sina, cosa);
        }

        float4 Rotate(float4 a, float b)
        {
            float2x2 m = rotateFnc(b);
            return float4(mul(m, a.xz), a.yw).xzyw;
        }

        #ifdef USING_STEREO_MATRICES
        static float3 centerCameraPos = 0.5 * (unity_StereoWorldSpaceCameraPos[0] +  unity_StereoWorldSpaceCameraPos[1]);
        #else
        static float3 centerCameraPos = _WorldSpaceCameraPos;
        #endif

        ENDCG

        Pass
        {
            //outline and rimlight?
            Cull Front
            CGPROGRAM

            struct appdata
            {
                float4 vertex: POSITION;
                float2 uvM: TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex: SV_POSITION;
                float2 uvM: TEXCOORD0;
                float3 normal: TEXCOORD1;
                float4 wpos: TEXCOORD2;
            };

            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _OutlineMask; uniform float4 _OutlineMask_ST;
            uniform int _Hoge;

            uniform fixed4 _OutlineColor;

            uniform float _OutlineWidth;

            
            v2f vert(appdata v)
            {
                v2f o;
                _OutlineWidth /= 1000;
                o.uvM = v.uvM;
                float3 outlineMask = tex2Dlod(_OutlineMask, float4(TRANSFORM_TEX(o.uvM, _OutlineMask), 0.0, 0)).rgb;
                v.vertex.xyz += lerp(0, v.normal * (1.0 - outlineMask.rgb) * _OutlineWidth, saturate(_OutlineWidth * 1000));

                float4 pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_MV, float4(0, 0, 0, 1)) + float4(v.vertex.x, v.vertex.y, v.vertex.z, 0));
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.wpos = mul(unity_ObjectToWorld, v.vertex);
                // UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }
            
            fixed4 frag(v2f i): SV_Target
            {
                    // float3 N = i.normal;
                    // float3 V = normalize(centerCameraPos.xyz - i.wpos.xyz);

                    // float NdotV = max(0, dot(N, V));
                    // float NNdotV = 1.001 - dot(N, V);



            
                    fixed4 col = _OutlineColor;
                    col.rgb = lerp(col.rgb, dot(col.rgb, half3(0.2326, 0.7152, 0.0722)), _Hoge);
                    // col.rgb = float3(1,0,0);


                    // UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
            
        }

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            
            #pragma multi_compile_fwdbase
            //enable per-vertice light computation
            //https://blog.csdn.net/qq_38275140/article/details/85297474
            #pragma multi_compile _ VERTEXLIGHT_ON

            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
                float3 normal: NORMAL;
                float3 tangent: TANGENT;
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex: SV_POSITION;
                float3 normal: TEXCOORD2;
                float2 huv: TEXCOORD3;
                float4 wpos: TEXCOORD4;
                LIGHTING_COORDS(5, 6)
                float3 tangent: TEXCOORD7;
                float3 binormal: TEXCOORD8;
                #if defined(VERTEXLIGHT_ON)
                    fixed3 vertexLightColor: TEXCOORD9;
                #endif
            };

            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _NormalTex; uniform float4 _NormalTex_ST;
            uniform sampler2D _Hatch0;
            uniform sampler2D _Hatch1;
            uniform sampler2D _Hatch2;
            uniform sampler2D _Hatch3;
            uniform sampler2D _Hatch4;
            uniform sampler2D _Hatch5;

            uniform float _Threshold;
            
            uniform float _BlendFactor;
            uniform float _Density;
            uniform float _Roughness;
            uniform int _Hoge;



            void ComputeVertexLightColor(inout v2f i)
            {
                #if defined(VERTEXLIGHT_ON)
                    //https://zhuanlan.zhihu.com/p/27842876
                    i.vertexLightColor = Shade4PointLights(
                        unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                        unity_LightColor[0].rgb, unity_LightColor[1].rgb,
                        unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                        unity_4LightAtten0, i.wpos, i.normal
                    );
                #endif
            }
            
            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                o.wpos = mul(unity_ObjectToWorld, v.vertex);

                float4 pos = mul(UNITY_MATRIX_P, mul(UNITY_MATRIX_MV, float4(0, 0, 0, 1)) + float4(v.vertex.x, v.vertex.y, v.vertex.z, 0));
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.huv = TRANSFORM_TEX(v.uv, _MainTex) * _Roughness;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.tangent = UnityObjectToWorldNormal(v.tangent);
                o.binormal = normalize(cross(o.tangent, o.normal));
                ComputeVertexLightColor(o);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }
            
            fixed4 frag(v2f i): SV_Target
            {
                float3 tangentNormal = float4(UnpackNormal(tex2D(_NormalTex, i.uv)), 1);
                float3x3 TBN = float3x3(i.tangent, i.binormal, i.normal);
                TBN = transpose(TBN);
                float3 worldNormal = mul(TBN, tangentNormal);
                //averaging the normal map and the vertex normal
                float3 N = lerp(i.normal, worldNormal, saturate(length(tangentNormal) * 100));

                float3 lightDir;
                #if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
                    lightDir = normalize(_WorldSpaceLightPos0.xyz - i.wpos.xyz);
                #else
                    lightDir = _WorldSpaceLightPos0.xyz;
                #endif

                fixed4 lightCol;
                #if defined(VERTEXLIGHT_ON)
                    lightCol = fixed4(i.vertexLightColor, 1);
                #else
                    lightCol = _LightColor0;
                #endif

                lightCol.rgb += max(0, ShadeSH9(float4(N, 1)));

                float3 L = lightDir;
                float3 V = normalize(centerCameraPos.xyz - i.wpos.xyz);

                float NdotV = max(0, dot(N, V));
                float NNdotV = 1.001 - dot(N, V);


                float NdotL = max(0, dot(L, N));
                UNITY_LIGHT_ATTENUATION(attenuation, i, N)
                lightCol *= attenuation;

                fixed4 col = tex2D(_MainTex, i.uv);

                fixed4 hatch0 = tex2D(_Hatch0, i.huv);
                fixed4 hatch1 = tex2D(_Hatch1, i.huv);
                fixed4 hatch2 = tex2D(_Hatch2, i.huv);
                fixed4 hatch3 = tex2D(_Hatch3, i.huv);
                fixed4 hatch4 = tex2D(_Hatch4, i.huv);
                fixed4 hatch5 = tex2D(_Hatch5, i.huv);
                fixed4 hatch6 = float4(0, 0, 0, 1);
                float blendFactor = _BlendFactor;

                if (length(lightCol.rgb) < _Threshold)
                {
                    float3 diffuse = col.rgb * NdotV;
                    float intensity = lerp(saturate(length(diffuse)), 0.5 * saturate(dot(diffuse, half3(0.2326, 0.7152, 0.0722))), _Density);


                    if(0.7 < intensity)
                    {
                        col *= fixed4(1, 1, 1, 1);
                    }
                    else if (0.6 < intensity) {
                        //alpha blending
                        // the intensity should be mapped to [0, 1]
                        intensity = (intensity - 0.6) * blendFactor;
                        col *= lerp(fixed4(1, 1, 1, 1), hatch0, 1 - intensity);
                    }
                    else if(0.5 < intensity)
                    {

                    intensity = (intensity - 0.5) * blendFactor;
                    col *= lerp(hatch0, hatch1, 1 - intensity);
                    }
                    else if(0.4 < intensity)
                    {
                        intensity = (intensity - 0.4) * blendFactor;
                        col *= lerp(hatch1, hatch2, 1 - intensity);
                    }
                    else if(0.3 < intensity )
                    {
                        intensity = (intensity - 0.3) * blendFactor;
                        col *= lerp(hatch2, hatch3, 1 - intensity);
                    }
                    else if(0.2 < intensity)
                    {
                        intensity = (intensity - 0.2) * blendFactor;
                        col *= lerp(hatch3, hatch4, 1 - intensity);
                    }
                    else if(0.1 < intensity )
                    {
                        intensity = (intensity - 0.1) * blendFactor;
                        col *= lerp(hatch4, hatch5, 1 - intensity);
                    }else{
                        intensity = intensity  * blendFactor;

                        col *= lerp(hatch5, hatch6, 1 - intensity);
                    }


                }
                else
                {
                    float manipulate = lerp(NdotL, NdotV, 0);
                    float3 diffuse = lerp(col.rgb * manipulate, lightCol, 1.0 / pow(3.3, length(lightCol)));
                    // diffuse = NdotL;
                    //interpolate between Lambertian and base color (ambient)
                    float intensity = lerp( saturate(length(diffuse)), 0.5 * saturate(dot(diffuse, half3(0.2326, 0.7152, 0.0722))), _Density);

                    // intensity = saturate(length(diffuse));
                    // compute tone
                    // use linear interpolation for smooth tone
                    if(0.9 < intensity)
                    {
                        col *= fixed4(1, 1, 1, 1);
                    }
                    else if (0.6 < intensity){
                        //alpha blending
                        // the intensity should be mapped to [0, 1]
                        intensity = (intensity - 0.6) * blendFactor / 3;
                        col *= lerp(fixed4(1, 1, 1, 1), hatch0, 1 - intensity);
                    }
                    else if(0.5 < intensity )
                    {
                        intensity = (intensity - 0.5) * blendFactor;
                        col *= lerp(hatch0, hatch1, 1 - intensity);
                    }
                    else if(0.4 < intensity )
                    {
                        intensity = (intensity - 0.4) * blendFactor;
                        col *= lerp(hatch1, hatch2, 1 - intensity);
                    }
                    else if(0.3 < intensity )
                    {
                        intensity = (intensity - 0.3) * blendFactor;
                        col *= lerp(hatch2, hatch3, 1 - intensity);
                    }
                    else if(0.2 < intensity )
                    {
                        intensity = (intensity - 0.2) * blendFactor;
                        col *= lerp(hatch3, hatch4, 1 - intensity);
                    }
                    else if(0.1 < intensity)
                    {
                        intensity = (intensity - 0.1) * blendFactor;
                        col *= lerp(hatch4, hatch5, 1 - intensity);
                    }else{
                        intensity = intensity  * blendFactor;
                        col *= lerp(hatch5, hatch6, 1 - intensity);
                    }
                    //---tone visulization---
                    // if(0.9 < intensity)
                    // {
                    //     col *= fixed4(1, 1, 1, 1);
                    // }
                    // else if (0.6 < intensity){
                        
                    //     col *= fixed4(0.6,0.6,0.6,1);
                    // }
                    // else if(0.5 < intensity )
                    // {
                    //     col *= fixed4(0.5,0.5,0.5,1);
                    // }
                    // else if(0.4 < intensity )
                    // {
                    //     col *= fixed4(0.4,0.4,0.4,1);
                    // }
                    // else if(0.3 < intensity )
                    // {
                    //     col *= fixed4(0.3,0.3,0.3,1);
                    // }
                    // else if(0.2 < intensity )
                    // {
                    //     col *= fixed4(0.2,0.2,0.2,1);
                    // }
                    // else if(0.1 < intensity)
                    // {
                    //     col *= fixed4(0.1,0.1,0.1,1);
                    // }else{
                    //     col *= fixed4(0.0,0.0,0.0,1);
                    // }
                    //---end tone visulization---
                    //unlit
                    // col.rgb = fixed3(0.7, 0.7, 0.7);

                    //lambertian
                    // col.rgb = diffuse;
                }

                // col.rgb = lerp(col.rgb, dot(col.rgb, half3(0.2326, 0.7152, 0.0722)), _Hoge) * _LightColor0.rgb;
                col.rgb = lerp(col.rgb, dot(col.rgb, half3(0.2326, 0.7152, 0.0722)), _Hoge) * _LightColor0.rgb;

                col.a = 1;

                UNITY_APPLY_FOG(i.fogCoord, col);
                return saturate(col);
            }
            ENDCG
            
        }

        


    }
    Fallback "Diffuse"
}
