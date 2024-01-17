// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "StudyTest/5_TestSimpleModelDataShader" {
	Properties {
        //声明一个Color类型的属性
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
	}
	SubShader {
        Pass {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            //在CG中定义一个与属性名称和类型都匹配的变量,建立关系
            uniform fixed4 _Color;

            // 使用一个结构体定义顶点着色器的输入,a2v表示application、vertex shader，从应用阶段传到顶点着色器中
			struct a2v {
                //POSITION语义告诉Unity使用模型空间的坐标顶点填充vertex变量
                float4 vertex : POSITION;
                //NORMAL语义告诉Unity使用模型空间的法线方向填充normal变量
				float3 normal : NORMAL;
                //TEXCOORD0语义告诉Unity，用模型第一套纹理坐标填充texcoord变量
				float4 texcoord : TEXCOORD0;
            };
            
            //使用一个结构体定义顶点着色器的输出
            struct v2f {
                //SV_POSITION语义告诉Unity，pos包含的顶点在裁剪空间的位置信息
                float4 pos : SV_POSITION;
                //COLOR0 语义可以用于存储颜色信息
                fixed3 color : COLOR0;
            };
            
            v2f vert(a2v v) {
                //声明输出结构体
            	v2f o;
            	o.pos = UnityObjectToClipPos(v.vertex);
                //v.normal 包含了顶点的法线方向，分量范围在[-1，1]
                //将法线分量映射到[0,1]存储到o.color
            	o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);
                //将o传递给片元着色器
                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
            	fixed3 c = i.color;
                //使用_Color属性来控制输出颜色
            	c *= _Color.rgb;
                //将插值后的i.color显示到屏幕上
                return fixed4(c, 1.0);
            }

            ENDCG
        }
    }
}
