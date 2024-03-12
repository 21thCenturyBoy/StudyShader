// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "StudyTest/Test6/6_TestDiffuseVertexLevel"
{
    //逐顶点
    Properties
    {
        //声明一个Color,控制漫反射颜色
        _Diffuse("Diffuse",Color) = (1,1,1,1)

    }
    SubShader
    {
        Tags
        {
            //Unity内置的光照模式，获取内置变量用
            "LightMode"="ForwardBase"
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert //定义顶点着色器名称
            #pragma fragment frag //定义片元着色器名称

            //导入Unity内置文件，因为_LightColor0包含在里面
            #include "Lighting.cginc"

            fixed4 _Diffuse; //定义一个与Properties _Diffuse相匹配的变量，由于颜色属性的范围在0,1之间，可以使用fixed精度变量来存储

            struct a2v
            {
                float4 vertex : POSITION; //
                float3 normal : NORMAL; //为了访问顶点法线，使用NORMAL语义，告诉Unity把模型顶点的法线信息存储到normal变量里
            };

            struct v2f
            {
                float4 pos : SV_POSITION; //
                float3 color : COLOR; //为了访问顶点法线，使用NORMAL语义，告诉Unity把模型顶点的法线信息存储到normal变量里
            };

            //顶点着色器处理
            v2f vert(a2v v)
            {
                v2f o;
                //顶点位置从模型空间转到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);

                //得到环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //计算漫反射需要知道
                //漫反射颜色_Diffuse
                //顶点法线v.normal
                //还需要知道光源颜色和强度信息
                //光源方向的计算并不通用，但平行光情况下可以由——WorldSpaceLightPos0得到

                //计算法线和光源方向的点积时，需要选择他们的所在坐标系，因为只有两者处于同一坐标空间下，他们的点积才有意义。
                //这里选择世界坐标空间，a2v得到的顶点法线是位于模型空间下的，所以通过点乘将法线转换到世界空间中。
                //WorldToObject是模型空间到世界空间的变换矩阵的逆矩阵，通过调换mul函数位置得到和转置矩阵相同的乘法
                //归一化
                fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));

                //光源方向 归一化
                fixed3 worldlight = normalize(_WorldSpaceLightPos0.xyz);

                //计算漫反射
                //点乘，saturate函数把参数范围取到[0,1]
                //_LightColor0：光源颜色和强度
                //_Diffuse：材质漫反射颜色
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldlight));

                //最后加上环境光
                o.color = ambient + diffuse;

                return o;
            }

            //片元着色器
            fixed4 frag(v2f i) : SV_Target
            {
                //直接输出顶点颜色
                return fixed4(i.color, 1.0);
            }
            ENDCG
        }
    }

    FallBack "Diffuse"//最后走
}