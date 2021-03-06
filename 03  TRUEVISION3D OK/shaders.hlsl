/// RAYMARCHING reference:    https://youtu.be/PGtv-dBi2wE

// - Roberto Mior
// - reexre

#define MAX_STEPS 200
#define MAX_DIST 1000.0
#define EPS 0.01

uniform float TIME1 = 0.0; // Variabliles passed from VB6
//uniform float TIME2 = 0.0;
//uniform float TIME3 = 0.0;

/////////////////////////////////////
//// RAYMARCHING
/////////////////////////////////////

///////////////////////////////////////// SDF FUNCTIONS
float sdSphere( float3 p, float s )
{
  return length(p)-s;
}
float sdBox( float3 p, float3 b )
{
  float3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}
float sdTorus( float3 p, float2 t )
{
  float2 q = float2(length(float2(p.x,p.z))-t.x,p.y);
  return length(q)-t.y;
}
/////////////////////////////////////////



////////////////////////////////////////// Get DISTANCE of a point 
float SCENE(float3 p){

	float SphereDist = sdSphere(p - float3(0.0, 1.0, 5.0) , 1.0 ) ;
	float PlaneDist = p.y ;
	float BoxDist = sdBox(p -  float3(3.0, .2+.08, 5.0) , float3( 0.5 ,0.2,0.5)) - 0.08;
	float TorusDist = sdTorus(p.xzy -  float3(-3.0, 5., 1.2) , float2( 1.0,0.2)) ;
	float d = min(SphereDist,PlaneDist);
	d = min(d,BoxDist);
	d = min(d,TorusDist);
	return d;
}

///////////////////////////////////////// Marching Ray
float RayMarch (float3 ro, float3 rd )
{
	float d0 = 0.0;
	for (int i=0; i < MAX_STEPS; i++) {
		float3 p = ro + rd * d0;
		float DS =  SCENE(p);
		d0 += DS;
		if (d0 > MAX_DIST )  i=MAX_STEPS  ;
		if (DS < EPS)  i=MAX_STEPS  ;
	}
	return d0;
}

//////////////////////////////////////// Compute SCENE Normal
float3  CalcSceneNormal(float3 p) {

	float3 vn1 =float3( 1., -1., -1.);
	float3 vn2 =float3(-1., -1.,  1.);
	float3 vn3 =float3(-1.,  1., -1.);
	float3 vn4 =float3( 1.,  1.,  1.);

	float3 r1 =  vn1 * SCENE(p + vn1 * (EPS));
	float3 r2 =  vn2 * SCENE(p + vn2 * (EPS));
	float3 r3 =  vn3 * SCENE(p + vn3 * (EPS));
	float3 r4 =  vn4 * SCENE(p + vn4 * (EPS));
	
	return normalize(r1 + r2 + r3 + r4  );
}


/////////////////////////////////////////// BASIC LIGHTING

float3 lighting(float3 p) {

//	float3 LightPos = float3(0.-3 ,1+3. *cos(AAA) ,5.-3. ); 
	
	float3 LightPos = float3(-3+cos(TIME1)*2 ,4 ,4+sin(TIME1)*2 ); 
	
	float3 L = normalize(LightPos-p);
	float3 n =  CalcSceneNormal(p);

	float dif = clamp(dot(L,n),0.,1.); 
	
	// BASIC SHADOW
	float d = RayMarch(p+n*EPS*2,L);
	if (d<length(LightPos-p)) dif *= .1;
	
return float3(dif,dif,dif);
}


//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////


struct VS_Input {
    float2 pos : POSITION;
    float2 uv : TEXCOORD;
};


struct VS_Output {
    float4 pos : POSITION;
    float2 uv : TEXCOORD;
};

VS_Output vs_main(VS_Input input)
{
    VS_Output output;
    output.pos = float4(input.pos, 0.0f, 1.0f);
    output.uv = input.uv;
    return output;
}




float4 ps_main(VS_Output input) : COLOR0
{
	
   float4 col4=float4(0.0,0.0,0.0,1.0);
   float2	UV = input.uv;
    //	UV=UV*2-1;
	//		UV.y=-UV.y;
		
	///////////////// Minimal Camera
	float3 ro = float3(0.0, 1.2, 0.0);
	float3 rd = normalize(float3 ( UV.x, UV.y, 1.0) );
	float d = RayMarch(ro , rd ) ;
	
	float3 p = ro + rd * d ;

    float3 col3 = lighting (p);
	
	col4 = float4(col3.x,col3.y,col3.z,1.0);	
//   // col4.x=input.uv.x;
//   // col4.y=input.uv.y;
//   // col4.z=0 ;
  return col4;
}




// http://www.truevision3d.com/forums/shader_development/shader_faq-t6277.0.html
technique PostProcess 
{ 
   pass Pass_0 
   { 
      //VertexShader = compile vs_1_1 vs_main(); 
	  VertexShader = compile vs_3_0 vs_main(); 
	  
      //PixelShader = compile ps_2_0 ps_main(); 
	  PixelShader = compile ps_3_0 ps_main(); // Allows more operations 'https://www.gamedev.net/forums/topic/490094-too-many-arithmetic-instruction/
	  
   } 
} 



/////////////////////////////////////
//// intrinsic FUNCTIONS
/////////////////////////////////////
// https://docs.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-intrinsic-functions


//////////////////////////////////////////////////////////////////////////////////////
