Shader "StudyTest/Test7/7_TestRampTexture"
{
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_RampTex ("Ramp Tex", 2D) = "white" {}
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
	SubShader {
		Pass { 
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"
			
			fixed4 _Color;
			sampler2D _RampTex;
			float4 _RampTex_ST;
			fixed4 _Specular;
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				//用TRANSFORM_TEX来计算经过偏移和平铺的纹理坐标
				o.uv = TRANSFORM_TEX(v.texcoord, _RampTex);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {

				//使用半兰伯特定律计算漫反射光照
				//漫反射光照 = 0.5 * dot(法线, 光线) + 0.5
				
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				// Use the texture to sample the diffuse color
				fixed halfLambert  = 0.5 * dot(worldNormal, worldLightDir) + 0.5;

				//对渐变纹理进行采样，获取漫反射颜色
				fixed3 diffuseColor = tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * _Color.rgb;

				//计算漫反射光照
				//漫反射光照 = 光照颜色 * 漫反射颜色
				fixed3 diffuse = _LightColor0.rgb * diffuseColor;
				
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
