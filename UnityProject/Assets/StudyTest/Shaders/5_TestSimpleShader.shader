// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "StudyTest/5_TestSimpleShader"//名字
{
    //Properties{}// 可选
    SubShader
    {
        Pass
        {
            CGPROGRAM
            //重要的编译指令，告诉Unity vert函数包含顶点着色器代码，frag包含片元着色器代码
            #pragma vertex vert
            #pragma fragment frag

            //输入v为顶点的位置，通过POSITION语义指定。返回一个float4。
            //POSITION、SV_POSITION都是CG/HLSL中的语义,不可省略
            //POSITION告诉Unity，把模型顶点坐标填充到输入参数v中。
            //SV_POSITION告诉Unity，顶点着色器的输出是裁剪空间中的顶点坐标。
            float4 vert (float4 v: POSITION):SV_POSITION
            {
             // UNITY_MATRIX_MVP为内置的模型观察投影，将模型->世界->相机->裁剪空间
             // return mul(UNITY_MATRIX_MVP,v);//mul()矩阵M和矩阵N的积；Unity会自动更新成UnityObjectToClipPos(*)
                return UnityObjectToClipPos(v);
            }

            //无输入，只输出fixed4。
            //SV_Target,告诉渲染器输出颜色到一个渲染目标。颜色分量取值为[0,1].
            fixed4 frag () : SV_Target
            {
                //输出颜色，(1,1,1)为白色，(0,0,0)为黑色
                return fixed4(1.0,1.0,1.0,1.0);
            }
            ENDCG
        }
    }
}
