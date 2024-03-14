// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "StudyTest/Test7/7_TestSingleTexture"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)//色调
        _MainTex ("Main Tex", 2D) = "white" {}//定义一张纹理
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex; //接受纹理数据

            //定义一个floa4类型变量，存储纹理的缩放和平移
            //_MainTex_ST.xy对应Unity的 Tilling 缩放
            //_MainTex_ST.zw对应Unity的 Offset 偏移
            float4 _MainTex_ST;
            fixed4 _Specular;
            float _Gloss;

            //输入结构体
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;//第一组纹理坐标存储位置
            };

            //输出结构体
            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;//第一组纹理坐标的uv，片元着色器纹理采样用。
            };

            //Blinn-Phong 高光模型
            v2f vert(a2v v)
            {
                v2f o;

                //顶点位置从模型空间转到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                //计算uv
                //顶点的Uv坐标 =  纹理原存储位置*纹理缩放+偏移
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                
                // Or just call the built-in function
                // TRANSFORM_TEX为Unity中定义转纹理UV的方法
                // o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //计算世界空间下的法线
                fixed3 worldNormal = normalize(i.worldNormal);
                //计算世界空间下的光源方向
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                // 使用tex2D进行纹理采样
                // tex2D(需要采样的纹理，纹理坐标) 返回纹素值
                // 和基础颜色点乘 得到作为 材质的反射率
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                //相乘环境光 得到环境光部分
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //计算逐顶点方式计算漫反射
                //光强和颜色* 反射率 * 
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}