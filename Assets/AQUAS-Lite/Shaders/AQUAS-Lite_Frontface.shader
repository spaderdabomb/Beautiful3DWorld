Shader "AQUAS-Lite/Frontface"
{
	Properties
	{
		[NoScaleOffset][Header(Wave Options)]_NormalTexture("Normal Texture", 2D) = "bump" {}
		_NormalTiling("Normal Tiling", Range( 0.01 , 2)) = 1
		_NormalStrength("Normal Strength", Range( 0 , 2)) = 0
		_WaveSpeed("Wave Speed", Float) = 0
		[Header(Color Options)]_MainColor("Main Color", Color) = (0,0.4867925,0.6792453,0)
		_DeepWaterColor("Deep Water Color", Color) = (0.5,0.2712264,0.2712264,0)
		_Density("Density", Range( 0 , 1)) = 1
		_Fade("Fade", Float) = 0
		[Header(Transparency Options)]_DepthTransparency("Depth Transparency", Float) = 0
		_TransparencyFade("Transparency Fade", Float) = 0
		_Refraction("Refraction", Range( 0 , 1)) = 0.1
		[Header(Lighting Options)]_Specular("Specular", Float) = 0
		_SpecularColor("Specular Color", Color) = (0,0,0,0)
		_Gloss("Gloss", Float) = 0
		_LightWrapping("Light Wrapping", Range( 0 , 2)) = 0
		[NoScaleOffset][Header(Foam Options)]_FoamTexture("Foam Texture", 2D) = "white" {}
		_FoamTiling("Foam Tiling", Range( 0 , 2)) = 0
		_FoamVisibility("Foam Visibility", Range( 0 , 1)) = 0
		_FoamBlend("Foam Blend", Float) = 0
		_FoamColor("Foam Color", Color) = (0.8773585,0,0,0)
		_FoamContrast("Foam Contrast", Range( 0 , 0.5)) = 0
		_FoamIntensity("Foam Intensity", Float) = 0.21
		_FoamSpeed("Foam Speed", Float) = 0.1
		[Header(Reflection Options)][Toggle]_EnableRealtimeReflections("Enable Realtime Reflections", Float) = 1
		_RealtimeReflectionIntensity("Realtime Reflection Intensity", Range( 0 , 1)) = 0
		[Toggle]_EnableProbeRelfections("Enable Probe Relfections", Float) = 1
		_ProbeReflectionIntensity("Probe Reflection Intensity", Range( 0 , 1)) = 0
		_Distortion("Distortion", Range( 0 , 1)) = 0
		[HideInInspector]_ReflectionTex("Reflection Tex", 2D) = "white" {}
		[Header(Distance Options)]_MediumTilingDistance("Medium Tiling Distance", Float) = 0
		_FarTilingDistance("Far Tiling Distance", Float) = 0
		_DistanceFade("Distance Fade", Float) = 0
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" }
		Cull Back
		GrabPass{ }
		CGPROGRAM
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#pragma target 3.0
		#pragma surface surf StandardCustomLighting alpha:fade keepalpha noshadow vertex:vertexDataFunc 
		struct Input
		{
			float4 screenPos;
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
			float eyeDepth;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		UNITY_DECLARE_SCREENSPACE_TEXTURE( _GrabTexture )
		uniform sampler2D _NormalTexture;
		uniform float _WaveSpeed;
		uniform float _NormalTiling;
		uniform float _NormalStrength;
		uniform float _Refraction;
		UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
		uniform float4 _CameraDepthTexture_TexelSize;
		uniform float _LightWrapping;
		uniform float _MediumTilingDistance;
		uniform float _DistanceFade;
		uniform float _FarTilingDistance;
		uniform float _EnableProbeRelfections;
		uniform float _EnableRealtimeReflections;
		uniform float4 _DeepWaterColor;
		uniform float4 _MainColor;
		uniform float _Density;
		uniform float _Fade;
		uniform sampler2D _ReflectionTex;
		uniform float _Distortion;
		uniform float _RealtimeReflectionIntensity;
		uniform float _ProbeReflectionIntensity;
		uniform float _FoamBlend;
		uniform sampler2D _FoamTexture;
		uniform float _FoamSpeed;
		uniform float _FoamTiling;
		uniform float _FoamContrast;
		uniform float4 _FoamColor;
		uniform float _FoamIntensity;
		uniform float _FoamVisibility;
		uniform float _Gloss;
		uniform float _Specular;
		uniform float4 _SpecularColor;
		uniform float _DepthTransparency;
		uniform float _TransparencyFade;


		inline float4 ASE_ComputeGrabScreenPos( float4 pos )
		{
			#if UNITY_UV_STARTS_AT_TOP
			float scale = -1.0;
			#else
			float scale = 1.0;
			#endif
			float4 o = pos;
			o.y = pos.w * 0.5f;
			o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
			return o;
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			o.eyeDepth = -UnityObjectToViewPos( v.vertex.xyz ).z;
		}

		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			#ifdef UNITY_PASS_FORWARDBASE
			float ase_lightAtten = data.atten;
			if( _LightColor0.a == 0)
			ase_lightAtten = 0;
			#else
			float3 ase_lightAttenRGB = gi.light.color / ( ( _LightColor0.rgb ) + 0.000001 );
			float ase_lightAtten = max( max( ase_lightAttenRGB.r, ase_lightAttenRGB.g ), ase_lightAttenRGB.b );
			#endif
			#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
			half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
			float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
			float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
			ase_lightAtten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
			#endif
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			float waveSpeed675 = _WaveSpeed;
			float2 appendResult1_g280 = (float2(waveSpeed675 , 0.0));
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 temp_output_21_0_g227 = ase_worldNormal;
			float temp_output_17_0_g227 = (temp_output_21_0_g227).y;
			float2 appendResult18_g227 = (float2(sign( temp_output_17_0_g227 ) , 1.0));
			float3 ase_worldPos = i.worldPos;
			float2 BaseUV1197 = ( appendResult18_g227 * (ase_worldPos).xz );
			float normalTiling618 = _NormalTiling;
			float2 temp_output_1196_0 = ( BaseUV1197 * normalTiling618 );
			float2 panner3_g280 = ( _Time.y * appendResult1_g280 + temp_output_1196_0);
			float2 appendResult1_g275 = (float2(waveSpeed675 , 0.0));
			float cos30 = cos( radians( 180.0 ) );
			float sin30 = sin( radians( 180.0 ) );
			float2 rotator30 = mul( temp_output_1196_0 - float2( 0.5,0.5 ) , float2x2( cos30 , -sin30 , sin30 , cos30 )) + float2( 0.5,0.5 );
			float2 panner3_g275 = ( _Time.y * appendResult1_g275 + rotator30);
			float normalStrength681 = _NormalStrength;
			float3 lerpResult67 = lerp( float3(0,0,1) , ( UnpackNormal( tex2D( _NormalTexture, panner3_g280 ) ) + UnpackNormal( tex2D( _NormalTexture, panner3_g275 ) ) ) , normalStrength681);
			float3 NormalsClose207 = lerpResult67;
			float temp_output_209_0 = ( _Refraction * 0.2 );
			float refractiveStrength496 = temp_output_209_0;
			float screenDepth514 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,UNITY_PROJ_COORD( ase_screenPos )));
			float distanceDepth514 = saturate( ( screenDepth514 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( 0.1 ) );
			float2 temp_output_461_0 = ( (NormalsClose207).xy * refractiveStrength496 * distanceDepth514 );
			float2 refraction511 = temp_output_461_0;
			float4 screenColor86_g1 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture,( (ase_screenPosNorm).xy + ( float2( 0.2,0 ) * refraction511 ) ));
			float3 LightWrapVector47_g1 = (( _LightWrapping * 0.5 )).xxx;
			float temp_output_678_0 = ( waveSpeed675 / 10.0 );
			float2 appendResult1_g278 = (float2(temp_output_678_0 , 0.0));
			float2 temp_output_1199_0 = ( BaseUV1197 * ( normalTiling618 / 10.0 ) );
			float2 panner3_g278 = ( _Time.y * appendResult1_g278 + temp_output_1199_0);
			float2 appendResult1_g277 = (float2(temp_output_678_0 , 0.0));
			float cos630 = cos( radians( 180.0 ) );
			float sin630 = sin( radians( 180.0 ) );
			float2 rotator630 = mul( temp_output_1199_0 - float2( 0.5,0.5 ) , float2x2( cos630 , -sin630 , sin630 , cos630 )) + float2( 0.5,0.5 );
			float2 panner3_g277 = ( _Time.y * appendResult1_g277 + rotator630);
			float mediumTilingDistance687 = _MediumTilingDistance;
			float tilingFade689 = _DistanceFade;
			float lerpResult693 = lerp( normalStrength681 , ( normalStrength681 / 20.0 ) , saturate( pow( ( distance( ase_worldPos , _WorldSpaceCameraPos ) / mediumTilingDistance687 ) , tilingFade689 ) ));
			float normalStrengthMedium706 = lerpResult693;
			float3 lerpResult639 = lerp( float3(0,0,1) , ( UnpackNormal( tex2D( _NormalTexture, panner3_g278 ) ) + UnpackNormal( tex2D( _NormalTexture, panner3_g277 ) ) ) , normalStrengthMedium706);
			float3 NormalsMedium1373 = lerpResult639;
			float3 lerpResult664 = lerp( NormalsClose207 , NormalsMedium1373 , saturate( pow( ( distance( ase_worldPos , _WorldSpaceCameraPos ) / mediumTilingDistance687 ) , tilingFade689 ) ));
			float temp_output_680_0 = ( waveSpeed675 / 30.0 );
			float2 appendResult1_g281 = (float2(temp_output_680_0 , 0.0));
			float2 temp_output_1201_0 = ( BaseUV1197 * ( normalTiling618 / 1200.0 ) );
			float2 panner3_g281 = ( _Time.y * appendResult1_g281 + temp_output_1201_0);
			float2 appendResult1_g282 = (float2(temp_output_680_0 , 0.0));
			float cos646 = cos( radians( 180.0 ) );
			float sin646 = sin( radians( 180.0 ) );
			float2 rotator646 = mul( temp_output_1201_0 - float2( 0.5,0.5 ) , float2x2( cos646 , -sin646 , sin646 , cos646 )) + float2( 0.5,0.5 );
			float2 panner3_g282 = ( _Time.y * appendResult1_g282 + rotator646);
			float farTilingDistance688 = _FarTilingDistance;
			float lerpResult698 = lerp( normalStrengthMedium706 , ( lerpResult693 / 20.0 ) , saturate( pow( ( distance( ase_worldPos , _WorldSpaceCameraPos ) / farTilingDistance688 ) , tilingFade689 ) ));
			float normalStrengthFar704 = lerpResult698;
			float3 lerpResult657 = lerp( float3(0,0,1) , ( UnpackNormal( tex2D( _NormalTexture, panner3_g281 ) ) + UnpackNormal( tex2D( _NormalTexture, panner3_g282 ) ) ) , normalStrengthFar704);
			float3 NormalsFar660 = lerpResult657;
			float3 lerpResult670 = lerp( lerpResult664 , NormalsFar660 , saturate( pow( ( distance( ase_worldPos , _WorldSpaceCameraPos ) / farTilingDistance688 ) , tilingFade689 ) ));
			float2 NormalSign1123 = appendResult18_g227;
			float2 WorldNormalXZ1122 = (temp_output_21_0_g227).xz;
			float WorldNormalY1121 = temp_output_17_0_g227;
			float3 appendResult4_g285 = (float3(( ( (lerpResult670).xy * NormalSign1123 ) + WorldNormalXZ1122 ) , WorldNormalY1121));
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float3 worldToTangentDir = normalize( mul( ase_worldToTangent, (appendResult4_g285).xzy) );
			float3 resultingNormal674 = worldToTangentDir;
			float3 break736 = resultingNormal674;
			float3 appendResult735 = (float3(break736.x , break736.y , 1));
			float3 CurrentNormal23_g1 = normalize( (WorldNormalVector( i , appendResult735 )) );
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float dotResult20_g1 = dot( CurrentNormal23_g1 , ase_worldlightDir );
			float NDotL21_g1 = dotResult20_g1;
			#if defined(LIGHTMAP_ON) && ( UNITY_VERSION < 560 || ( defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) ) )//aselc
			float4 ase_lightColor = 0;
			#else //aselc
			float4 ase_lightColor = _LightColor0;
			#endif //aselc
			float3 AttenuationColor8_g1 = ( ase_lightColor.rgb * ase_lightAtten );
			float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( ase_screenPos );
			float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
			float2 pseudoRefraction484 = ( (ase_grabScreenPosNorm).xy + ( temp_output_209_0 * (resultingNormal674).xy ) );
			float4 screenColor146 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture,pseudoRefraction484);
			float eyeDepth135 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,UNITY_PROJ_COORD( ase_screenPos )));
			float temp_output_141_0 = ( eyeDepth135 - i.eyeDepth );
			float3 appendResult258 = (float3(temp_output_141_0 , temp_output_141_0 , temp_output_141_0));
			float3 clampResult142 = clamp( (float3( 1,1,1 ) + (appendResult258 - float3(0,0,0)) * (float3( 0,0,0 ) - float3( 1,1,1 )) / (( _MainColor * ( 1.0 / _Density ) ).rgb - float3(0,0,0))) , float3( 0,0,0 ) , float3( 1,1,1 ) );
			float3 temp_cast_1 = (_Fade).xxx;
			float4 blendOpSrc147 = _DeepWaterColor;
			float4 blendOpDest147 = ( screenColor146 * float4( pow( clampResult142 , temp_cast_1 ) , 0.0 ) );
			float4 waterColor488 = ( saturate( ( blendOpSrc147 + blendOpDest147 ) ));
			float4 realtimeReflection600 = tex2D( _ReflectionTex, ( (ase_screenPosNorm).xy + ( (resultingNormal674).xy * _Distortion ) ) );
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float3x3 ase_tangentToWorldFast = float3x3(ase_worldTangent.x,ase_worldBitangent.x,ase_worldNormal.x,ase_worldTangent.y,ase_worldBitangent.y,ase_worldNormal.y,ase_worldTangent.z,ase_worldBitangent.z,ase_worldNormal.z);
			float fresnelNdotV1378 = dot( mul(ase_tangentToWorldFast,resultingNormal674), ase_worldViewDir );
			float fresnelNode1378 = ( 0.0 + 1.0 * pow( 1.0 - fresnelNdotV1378, 2.0 ) );
			float temp_output_1380_0 = saturate( fresnelNode1378 );
			float4 lerpResult1377 = lerp( waterColor488 , realtimeReflection600 , ( temp_output_1380_0 * _RealtimeReflectionIntensity ));
			float Distortion761 = _Distortion;
			float3 break775 = ( resultingNormal674 * Distortion761 );
			float3 appendResult776 = (float3(break775.x , break775.y , 1.0));
			float3 indirectNormal727 = WorldNormalVector( i , appendResult776 );
			Unity_GlossyEnvironmentData g727 = UnityGlossyEnvironmentSetup( 1.0, data.worldViewDir, indirectNormal727, float3(0,0,0));
			float3 indirectSpecular727 = UnityGI_IndirectSpecular( data, 1.0, indirectNormal727, g727 );
			float fresnelNdotV755 = dot( ase_worldNormal, ase_worldViewDir );
			float fresnelNode755 = ( 0.0 + 1.0 * pow( 1.0 - fresnelNdotV755, 4.0 ) );
			float3 lerpResult754 = lerp( ( indirectSpecular727 * float3( 0.3,0.3,0.3 ) ) , indirectSpecular727 , fresnelNode755);
			float3 probeReflection766 = lerpResult754;
			float4 lerpResult1382 = lerp( lerp(waterColor488,lerpResult1377,_EnableRealtimeReflections) , float4( probeReflection766 , 0.0 ) , ( temp_output_1380_0 * _ProbeReflectionIntensity ));
			float screenDepth313 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,UNITY_PROJ_COORD( ase_screenPos )));
			float distanceDepth313 = saturate( ( screenDepth313 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( _FoamBlend ) );
			float2 appendResult1_g288 = (float2(_FoamSpeed , 0.0));
			float3 temp_output_21_0_g286 = ase_worldNormal;
			float temp_output_17_0_g286 = (temp_output_21_0_g286).y;
			float2 appendResult18_g286 = (float2(sign( temp_output_17_0_g286 ) , 1.0));
			float2 temp_output_1212_0 = ( ( appendResult18_g286 * (ase_worldPos).xz ) * _FoamTiling );
			float2 panner3_g288 = ( _Time.y * appendResult1_g288 + temp_output_1212_0);
			float2 appendResult1_g287 = (float2(_FoamSpeed , 0.0));
			float cos296 = cos( radians( 90.0 ) );
			float sin296 = sin( radians( 90.0 ) );
			float2 rotator296 = mul( temp_output_1212_0 - float2( 0.5,0.5 ) , float2x2( cos296 , -sin296 , sin296 , cos296 )) + float2( 0.5,0.5 );
			float2 panner3_g287 = ( _Time.y * appendResult1_g287 + rotator296);
			float3 desaturateInitialColor304 = ( tex2D( _FoamTexture, panner3_g288 ) - tex2D( _FoamTexture, panner3_g287 ) ).rgb;
			float desaturateDot304 = dot( desaturateInitialColor304, float3( 0.299, 0.587, 0.114 ));
			float3 desaturateVar304 = lerp( desaturateInitialColor304, desaturateDot304.xxx, 1.0 );
			float3 temp_cast_5 = (_FoamContrast).xxx;
			float3 temp_cast_6 = (( 1.0 - _FoamContrast )).xxx;
			float2 _Vector3 = float2(0,1);
			float3 temp_cast_7 = (_Vector3.x).xxx;
			float3 temp_cast_8 = (_Vector3.y).xxx;
			float4 temp_output_319_0 = ( ( 1.0 - distanceDepth313 ) * ( float4( (temp_cast_7 + (desaturateVar304 - temp_cast_5) * (temp_cast_8 - temp_cast_7) / (temp_cast_6 - temp_cast_5)) , 0.0 ) * _FoamColor * _FoamIntensity * -1.0 ) );
			float3 temp_cast_10 = (_FoamContrast).xxx;
			float3 temp_cast_11 = (( 1.0 - _FoamContrast )).xxx;
			float3 temp_cast_12 = (_Vector3.x).xxx;
			float3 temp_cast_13 = (_Vector3.y).xxx;
			float4 foam406 = ( temp_output_319_0 * temp_output_319_0 );
			float4 foamyWater490 = ( lerp(lerp(waterColor488,lerpResult1377,_EnableRealtimeReflections),lerpResult1382,_EnableProbeRelfections) + ( foam406 * _FoamVisibility ) );
			float clampResult100_g1 = clamp( ase_worldlightDir.y , ( length( (UNITY_LIGHTMODEL_AMBIENT).rgb ) / 3.0 ) , 1.0 );
			float3 diffuseColor131_g1 = ( ( ( max( ( LightWrapVector47_g1 + ( ( 1.0 - LightWrapVector47_g1 ) * NDotL21_g1 ) ) , float3(0,0,0) ) * AttenuationColor8_g1 ) * foamyWater490.rgb ) * clampResult100_g1 );
			float3 normalizeResult77_g1 = normalize( ase_worldlightDir );
			float3 normalizeResult28_g1 = normalize( ( normalizeResult77_g1 + ase_worldViewDir ) );
			float3 HalfDirection29_g1 = normalizeResult28_g1;
			float dotResult32_g1 = dot( HalfDirection29_g1 , CurrentNormal23_g1 );
			float SpecularPower14_g1 = exp2( ( ( _Gloss * 10.0 ) + 1.0 ) );
			float screenDepth402 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,UNITY_PROJ_COORD( ase_screenPos )));
			float distanceDepth402 = saturate( abs( ( screenDepth402 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( 0.2 ) ) );
			float4 specularity504 = ( ( distanceDepth402 * _Specular ) * _SpecularColor );
			float3 specularFinalColor42_g1 = ( AttenuationColor8_g1 * pow( max( dotResult32_g1 , 0.0 ) , SpecularPower14_g1 ) * specularity504.rgb );
			float3 diffuseSpecular132_g1 = ( diffuseColor131_g1 + specularFinalColor42_g1 );
			float screenDepth261 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,UNITY_PROJ_COORD( ase_screenPos )));
			float distanceDepth261 = saturate( ( screenDepth261 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( _DepthTransparency ) );
			float opacity508 = pow( distanceDepth261 , _TransparencyFade );
			float4 lerpResult87_g1 = lerp( screenColor86_g1 , float4( diffuseSpecular132_g1 , 0.0 ) , opacity508);
			c.rgb = ( lerpResult87_g1 * ase_lightAtten ).rgb;
			c.a = 1;
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
		}

		ENDCG
	}
}