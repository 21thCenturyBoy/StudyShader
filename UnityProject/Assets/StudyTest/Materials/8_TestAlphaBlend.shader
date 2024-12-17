Shader "StudyTest/Test8/8_TestAlphaBlend"
{
    Properties
    {
        _Color ("Main Tint", Color) = (1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white"{}
        _AlphaScale ("Alpha Scale", Range(0, 1)) = 1
    }
    SubShader
    {
        // 具体含义可参考https://zhuanlan.zhihu.com/p/51080323
        // RenderType其实就是分组，可以配合camera.SetReplacementShader (EffectShader, Tag)进行着色器替换
        // 比如要将某个RenderType的物体的shader切换成选中的shader（可以overlay突出）
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
        }
        Pass
        {
            // 开启深度写入，并不输出颜色
            ZWrite On
            ColorMask 0
        }
        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
            }
            // 关闭深度写入以及设置混合因子（会自动打开混合模式）
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert;
            #pragma fragment frag;

            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaScale;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 texColor = tex2D(_MainTex, i.uv);

                fixed3 albedo = texColor.rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal, worldLightDir));

                return fixed4(ambient + diffuse, texColor.a * _AlphaScale);
            }
            ENDCG
        }
    }
    // 保证透明度测试的物体能正确向其他物体投射阴影
    FallBack "Transparent/VertexLit"
}