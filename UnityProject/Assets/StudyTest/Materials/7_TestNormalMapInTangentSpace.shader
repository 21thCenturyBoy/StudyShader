Shader "StudyTest/Test7/7_TestNormalMapInTangentSpace"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)//色调
        _MainTex ("Main Tex", 2D) = "white" {}//定义一张纹理
        _BumpMap ("Normal Map", 2D) = "bump" {}//法线纹理
        _BumpScale ("Bump Scale", Float) = 1.0
        _Specular ("Specular", Color) = (1, 1, 1, 1)//镜面反射
        _Gloss ("Gloss", Range(8.0, 256)) = 20//光泽
    }
    SubShader
    {
        Pass
        {
            Tags
            {
                //流水线指定渲染模式
                "LightMode"="ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert//定义自定义顶点着色器
            #pragma fragment frag//定义自定义片元着色器

            //引入Unity的内置光照函数
            #include "Lighting.cginc"

            //接收Unity属性
            fixed4 _Color;
            sampler2D _MainTex; //接受纹理数据
            //定义一个floa4类型变量，存储纹理的缩放和平移
            //_MainTex_ST.xy对应Unity的 Tilling 缩放
            //_MainTex_ST.zw对应Unity的 Offset 偏移
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            //顶点着色器输入结构体
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT; //TANGENT语义告诉Unity填充切线方向
                float4 texcoord : TEXCOORD0; //第一组纹理坐标存储位置
            };

            //片元着色器输入结构体
            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 lightDir: TEXCOORD1; //顶点变换后的光线方向
                float3 viewDir : TEXCOORD2; //顶点变换后的视角方向
            };

            // Unity 不支持在原生 shader 中使用 'inverse' 函数
            // 因此我们自己编写一个
            // 注意：此函数仅供演示，对数学或速度没有太大信心
            // 参考：http://answers.unity3d.com/questions/218333/shader-inversefloat4x4-function.html
            float4x4 inverse(float4x4 input)
            {
                #define minor(a,b,c) determinant(float3x3(input.a, input.b, input.c))

                float4x4 cofactors = float4x4(
                    minor(_22_23_24, _32_33_34, _42_43_44),
                    -minor(_21_23_24, _31_33_34, _41_43_44),
                    minor(_21_22_24, _31_32_34, _41_42_44),
                    -minor(_21_22_23, _31_32_33, _41_42_43),

                    -minor(_12_13_14, _32_33_34, _42_43_44),
                    minor(_11_13_14, _31_33_34, _41_43_44),
                    -minor(_11_12_14, _31_32_34, _41_42_44),
                    minor(_11_12_13, _31_32_33, _41_42_43),

                    minor(_12_13_14, _22_23_24, _42_43_44),
                    -minor(_11_13_14, _21_23_24, _41_43_44),
                    minor(_11_12_14, _21_22_24, _41_42_44),
                    -minor(_11_12_13, _21_22_23, _41_42_43),

                    -minor(_12_13_14, _22_23_24, _32_33_34),
                    minor(_11_13_14, _21_23_24, _31_33_34),
                    -minor(_11_12_14, _21_22_24, _31_32_34),
                    minor(_11_12_13, _21_22_23, _31_32_33)
                );
                #undef minor
                return transpose(cofactors) / determinant(input);
            }

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //纹理坐标
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                ///
                /// 请注意，下面的代码可以处理均匀和非均匀缩放
                ///

                //把切线方向、法线方向、副法线方向按行排列成rotation矩阵
                //这个矩阵可以把模型空间的转换到切线空间
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;//计算副切线

                //可以用TANGENT_SPACE_ROTATION宏代替上面的代码
                //TANGENT_SPACE_ROTATION //这个宏定义在Lighting.cginc中

                //wToT = the inverse of tToW = the transpose of tToW as long as tToW is an orthogonal matrix.
                float3x3 worldToTangent = float3x3(worldTangent, worldBinormal, worldNormal);
                
                // 得到模型空间的光线方向和视角方向
                o.lightDir = mul(worldToTangent, WorldSpaceLightDir(v.vertex));
                o.viewDir = mul(worldToTangent, WorldSpaceViewDir(v.vertex));
                
                return o;
            }

            //得到片元着色器只需要获得切线空间的法线
            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);
                
                // 在法线贴图中获取纹素
                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
                fixed3 tangentNormal;

                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}