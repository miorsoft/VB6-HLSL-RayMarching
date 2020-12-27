/// RAYMARCHING reference:    https://youtu.be/PGtv-dBi2wE


#define MAX_STEPS 400
#define MAX_DIST 1000.
#define EPS .01

static float ttt;

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

 // p.z=fmod(p.z-3. , 6.)  +3. ;

	float SphereDist = sdSphere(p - float3(0.0, 1.0, 5.0) , 1. ) ;
	float PlaneDist = p.y ;
	float BoxDist = sdBox(p -  float3(3.0, .2+.08, 5.0) , float3( .5 ,.2,.5)) - .08;
	float TorusDist = sdTorus(p.xzy -  float3(-3.0, 5., 1.2) , float2( 1.,.2)) ;
	
	float d = min(SphereDist,PlaneDist);
	
	d = min(d,BoxDist);
	d = min(d,TorusDist);
	
	return d;
}

///////////////////////////////////////// Marching Ray
float RayMarch (float3 ro, float3 rd )
{
	float d0 = 0.0;
	for (int i=0; i<MAX_STEPS; i++) {
		float3 p = ro + rd * d0;
		float DS =  SCENE(p);
		d0 += DS;
		if (d0 > MAX_DIST || DS < EPS) break ;
	}
	return d0;
}

//////////////////////////////////////// Compute SCENE Normal
float3  CalcSceneNormal(float3 p) {
  //  r1 = MUL3(Vn1, SCENE(SUM3(POS, ven1)).X)
  //  R2 = MUL3(Vn2, SCENE(SUM3(POS, ven2)).X)
  //  r3 = MUL3(vn3, SCENE(SUM3(POS, ven3)).X)
  //  r4 = MUL3(vn4, SCENE(SUM3(POS, ven4)).X)
  //  With CalcNormal
  //      .X = r1.X + R2.X + r3.X + r4.X
  //      .y = r1.y + R2.y + r3.y + r4.y
  //      .Z = r1.Z + R2.Z + r3.Z + r4.Z
  //  End With


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
//  float3 lighting(float3 p,float2 time) {
float3 lighting(float3 p) {

	float3 LightPos = float3(0.-3 ,1+3. ,5.-3. ); 
//	LightPos.x= LightPos.x - 4*cos(time.y*1);
//	LightPos.z= LightPos.z - 4*sin(time*5);
	
	float3 L = normalize(LightPos-p);
	float3 n =  CalcSceneNormal(p);

//	float dif = dot(L,n); 

	float dif = clamp(dot(L,n),0.,1.); 
	
	// BASIC SHADOW
	float d = RayMarch(p+n*EPS*2,L);
	if (d<length(LightPos-p)) dif *= .1;
	
return float3(dif,dif,dif);
}

//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////// SHADER //////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////

struct VS_Input {
    float2 pos : POS;
    float2 uv : TEX;
};

struct VS_Output {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD;
//	float2 time : _Time;
	float2 RES : RESOLUTION;
};

Texture2D    mytexture : register(t0);
//Texture2D    mytexture2 : register(t1);

SamplerState mysampler : register(s0);

 float Time :  register(t1) ;

VS_Output vs_main(VS_Input input)
{
    VS_Output output;
    output.pos = float4(input.pos, 0.0f, 1.0f);
    output.uv = input.uv;
    return output;
}

float4 ps_main(VS_Output input) : SV_Target
{

////    float4  col4=  mytexture.Sample(mysampler, input.uv);   
//// float w=mytexture.width;
    float4  col4=  mytexture.Sample(mysampler, frac(input.uv*4.0)  );   	
	return float4(1.0-col4.x,col4.y+cos(Time*10.0),col4.z,col4.w);



	 
	
	
//	  float4 col4;
////    col4.x=input.uv.x;
////    col4.y=input.uv.y;
////    col4.z=0 ;
	
//    float2	UV = input.uv;
////	UV.x = UV.x * input.pos.y / input.pos.x;
	
			
//	///////////////// Minimal Camera
//	float3 ro = float3(0.0, 1.2, 0.0);
//	float3 rd = normalize(float3 ( UV.x, UV.y, 1.0) );
	
	
//	float d = RayMarch(ro , rd ) ;
	
//   //float3 col3 = d * .05 ;    // View Distance
	
//	float3 p = ro + rd * d ;

//    // float3 col3=CalcSceneNormal(p);  // TEST NORMAL

////  float3 col3 = lighting (p, input.time);
//    float3 col3 = lighting (p);		
//	col4 = float4(col3,1.0);	
//	ttt += 1000;
//    return col4;
}





/////////////////////////////////////
//// intrinsic FUNCTIONS
/////////////////////////////////////
// https://docs.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-intrinsic-functions





