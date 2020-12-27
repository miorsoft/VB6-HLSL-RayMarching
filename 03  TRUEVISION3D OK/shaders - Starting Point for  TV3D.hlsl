
struct VS_Input {
    float2 pos : POSITION;
    float2 uv : TEXCOORD;
};

struct VS_Output {
    float4 pos : POSITION;
    float2 uv : TEXCOORD;
};

//Texture2D    mytexture : register(t0);
//SamplerState mysampler : register(s0);

VS_Output vs_main(VS_Input input)
{
    VS_Output output;
    output.pos = float4(input.pos, 0.0f, 1.0f);
    output.uv = input.uv;
    return output;
}

float4 ps_main(VS_Output input) : COLOR0
{
    // return mytexture.Sample(mysampler, input.uv);   
	
	  float4 col = float4(0.0,0.0,0.0,0.5);
    col.x=input.uv.x;
    col.y=input.uv.y;
    col.z=0 ;
    return col;
}

technique PostProcess 
{ 
   pass Pass_0 
   { 
      VertexShader = compile vs_1_1 vs_main(); 
      PixelShader = compile ps_3_0 ps_main(); 
   } 
} 