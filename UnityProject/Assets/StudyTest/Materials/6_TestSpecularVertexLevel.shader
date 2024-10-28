// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "StudyTest/Test6/6_TestSpecularVertexLevel" {
	Properties {
		//漫反射材质颜色
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
		//高光反射颜色
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		//光泽度控制亮点大小
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
	SubShader {
		Pass { 
			Tags { "LightMode"="ForwardBase" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				fixed3 color : COLOR;
			};
			
			v2f vert(a2v v) {
				v2f o;
                //顶点位置从模型空间转到裁剪空间
				o.pos = UnityObjectToClipPos(v.vertex);
				
                //得到环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				//将顶点法线从模型空间转换到世界空间
				fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
				
				//获取世界空间的光源方向 并归一化
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				
				//计算逐顶点方式计算漫反射
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));
				
				//计算反射方向光源的反射方向 并归一化,这里计算光源反射需要取反
				fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
				
				//计算世界空间内的视觉方向
				//_WorldSpaceCameraPos 为世界相机位置
				//把顶点位置从模型空间转为世界空间
				//相减得到世界相机到世界顶点的视觉方向 并归一化
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);
				
				//入射光线的颜色和强度
				//材质高光反射颜色
				//视角方向
				//反射方向
				//计算高光反射(这里)对点乘结果来个 光泽度的次方
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);

				//最后结果 = 环境光 + 漫反射 + 高光
				o.color = ambient + diffuse + specular;
							 	
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				return fixed4(i.color, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Specular"
}
