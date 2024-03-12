Shader "StudyTest/Test6/6_TestDiffusePixelLevel"
{
  Properties {
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
	}
	SubShader {
		Pass { 
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			fixed4 _Diffuse;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;//世界空间下的法线坐标
			};
			
			v2f vert(a2v v) {
				v2f o;
				
                //顶点位置从模型空间转到裁剪空间
				o.pos = UnityObjectToClipPos(v.vertex);

				//获取世界坐标空间的法线
				o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);

				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				
                //得到环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				//世界坐标空间的法线 归一化
				fixed3 worldNormal = normalize(i.worldNormal);
				
				//世界坐标空间的光源方向 归一化
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				
                //计算漫反射
				//点乘，saturate函数把参数范围取到[0,1]
                //_LightColor0：光源颜色和强度
                //_Diffuse：材质漫反射颜色
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));
				
				fixed3 color = ambient + diffuse;
				
				return fixed4(color, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Diffuse"
}
