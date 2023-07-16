Shader "AQUAS-Lite/Backface"
{
	Properties
	{
		[NoScaleOffset][Header(Wave Options)]_NormalTexture("Normal Texture", 2D) = "bump" {}
		_NormalTiling("Normal Tiling", Range( 0.01 , 2)) = 1
		_NormalStrength("Normal Strength", Range( 0 , 2)) = 0
		_WaveSpeed("Wave Speed", Float) = 0
		_Refraction("Refraction", Range( 0 , 1)) = 0.1
		_DeepWaterColor("Deep Water Color", Color) = (0,0,0,0)
		[Header(Distance Options)]_MediumTilingDistance("Medium Tiling Distance", Float) = 0
		_FarTilingDistance("Far Tiling Distance", Float) = 0
		_DistanceFade("Distance Fade", Float) = 0
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		LOD 200
		Cull Front
		GrabPass{ }
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "Lighting.cginc"
		#pragma target 4.6
		#pragma shader_feature _GLOSSYREFLECTIONS_OFF
		#pragma multi_compile __ LOD_FADE_CROSSFADE
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float4 screenPos;
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
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

		uniform float4 _DeepWaterColor;
		UNITY_DECLARE_SCREENSPACE_TEXTURE( _GrabTexture )
		uniform float _Refraction;
		uniform sampler2D _NormalTexture;
		uniform float _WaveSpeed;
		uniform float _NormalTiling;
		uniform float _NormalStrength;
		uniform float _MediumTilingDistance;
		uniform float _DistanceFade;
		uniform float _FarTilingDistance;


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


		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			c.rgb = 0;
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
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( ase_screenPos );
			float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
			float temp_output_209_0 = ( _Refraction * 0.2 );
			float waveSpeed675 = _WaveSpeed;
			float2 appendResult1_g272 = (float2(waveSpeed675 , 0.0));
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 temp_output_21_0_g227 = ase_worldNormal;
			float temp_output_17_0_g227 = (temp_output_21_0_g227).y;
			float2 appendResult18_g227 = (float2(sign( temp_output_17_0_g227 ) , 1.0));
			float3 ase_worldPos = i.worldPos;
			float2 BaseUV1197 = ( appendResult18_g227 * (ase_worldPos).xz );
			float normalTiling618 = _NormalTiling;
			float2 temp_output_1196_0 = ( BaseUV1197 * normalTiling618 );
			float2 panner3_g272 = ( _Time.y * appendResult1_g272 + temp_output_1196_0);
			float2 appendResult1_g270 = (float2(waveSpeed675 , 0.0));
			float cos30 = cos( radians( 180.0 ) );
			float sin30 = sin( radians( 180.0 ) );
			float2 rotator30 = mul( temp_output_1196_0 - float2( 0.5,0.5 ) , float2x2( cos30 , -sin30 , sin30 , cos30 )) + float2( 0.5,0.5 );
			float2 panner3_g270 = ( _Time.y * appendResult1_g270 + rotator30);
			float normalStrength681 = _NormalStrength;
			float3 lerpResult67 = lerp( float3(0,0,1) , ( UnpackNormal( tex2D( _NormalTexture, panner3_g272 ) ) + UnpackNormal( tex2D( _NormalTexture, panner3_g270 ) ) ) , normalStrength681);
			float3 NormalsClose1340 = lerpResult67;
			float temp_output_678_0 = ( waveSpeed675 / 10.0 );
			float2 appendResult1_g264 = (float2(temp_output_678_0 , 0.0));
			float2 temp_output_1199_0 = ( BaseUV1197 * ( normalTiling618 / 10.0 ) );
			float2 panner3_g264 = ( _Time.y * appendResult1_g264 + temp_output_1199_0);
			float2 appendResult1_g273 = (float2(temp_output_678_0 , 0.0));
			float cos630 = cos( radians( 180.0 ) );
			float sin630 = sin( radians( 180.0 ) );
			float2 rotator630 = mul( temp_output_1199_0 - float2( 0.5,0.5 ) , float2x2( cos630 , -sin630 , sin630 , cos630 )) + float2( 0.5,0.5 );
			float2 panner3_g273 = ( _Time.y * appendResult1_g273 + rotator630);
			float mediumTilingDistance687 = _MediumTilingDistance;
			float tilingFade689 = _DistanceFade;
			float lerpResult693 = lerp( normalStrength681 , ( normalStrength681 / 20.0 ) , saturate( pow( ( distance( ase_worldPos , _WorldSpaceCameraPos ) / mediumTilingDistance687 ) , tilingFade689 ) ));
			float normalStrengthMedium706 = lerpResult693;
			float3 lerpResult639 = lerp( float3(0,0,1) , ( UnpackNormal( tex2D( _NormalTexture, panner3_g264 ) ) + UnpackNormal( tex2D( _NormalTexture, panner3_g273 ) ) ) , normalStrengthMedium706);
			float3 NormalsMedium1373 = lerpResult639;
			float3 lerpResult664 = lerp( NormalsClose1340 , NormalsMedium1373 , saturate( pow( ( distance( ase_worldPos , _WorldSpaceCameraPos ) / mediumTilingDistance687 ) , tilingFade689 ) ));
			float temp_output_680_0 = ( waveSpeed675 / 30.0 );
			float2 appendResult1_g275 = (float2(temp_output_680_0 , 0.0));
			float2 temp_output_1201_0 = ( BaseUV1197 * ( normalTiling618 / 1200.0 ) );
			float2 panner3_g275 = ( _Time.y * appendResult1_g275 + temp_output_1201_0);
			float2 appendResult1_g276 = (float2(temp_output_680_0 , 0.0));
			float cos646 = cos( radians( 180.0 ) );
			float sin646 = sin( radians( 180.0 ) );
			float2 rotator646 = mul( temp_output_1201_0 - float2( 0.5,0.5 ) , float2x2( cos646 , -sin646 , sin646 , cos646 )) + float2( 0.5,0.5 );
			float2 panner3_g276 = ( _Time.y * appendResult1_g276 + rotator646);
			float farTilingDistance688 = _FarTilingDistance;
			float lerpResult698 = lerp( normalStrengthMedium706 , ( lerpResult693 / 20.0 ) , saturate( pow( ( distance( ase_worldPos , _WorldSpaceCameraPos ) / farTilingDistance688 ) , tilingFade689 ) ));
			float normalStrengthFar704 = lerpResult698;
			float3 lerpResult657 = lerp( float3(0,0,1) , ( UnpackNormal( tex2D( _NormalTexture, panner3_g275 ) ) + UnpackNormal( tex2D( _NormalTexture, panner3_g276 ) ) ) , normalStrengthFar704);
			float3 NormalsFar660 = lerpResult657;
			float3 lerpResult670 = lerp( lerpResult664 , NormalsFar660 , saturate( pow( ( distance( ase_worldPos , _WorldSpaceCameraPos ) / farTilingDistance688 ) , tilingFade689 ) ));
			float2 NormalSign1123 = appendResult18_g227;
			float2 WorldNormalXZ1122 = (temp_output_21_0_g227).xz;
			float WorldNormalY1121 = temp_output_17_0_g227;
			float3 appendResult4_g279 = (float3(( ( (lerpResult670).xy * NormalSign1123 ) + WorldNormalXZ1122 ) , WorldNormalY1121));
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float3 worldToTangentDir = normalize( mul( ase_worldToTangent, (appendResult4_g279).xzy) );
			float3 resultingNormal674 = worldToTangentDir;
			float2 pseudoRefraction484 = ( (ase_grabScreenPosNorm).xy + ( temp_output_209_0 * (resultingNormal674).xy ) );
			float4 screenColor1381 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture,pseudoRefraction484);
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float3x3 ase_tangentToWorldFast = float3x3(ase_worldTangent.x,ase_worldBitangent.x,ase_worldNormal.x,ase_worldTangent.y,ase_worldBitangent.y,ase_worldNormal.y,ase_worldTangent.z,ase_worldBitangent.z,ase_worldNormal.z);
			float fresnelNdotV1379 = dot( mul(ase_tangentToWorldFast,resultingNormal674), ase_worldViewDir );
			float fresnelNode1379 = ( 0.0 + 0.05 * pow( 1.0 - fresnelNdotV1379, 10.0 ) );
			float4 lerpResult1378 = lerp( _DeepWaterColor , screenColor1381 , saturate( fresnelNode1379 ));
			o.Emission = lerpResult1378.rgb;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardCustomLighting alpha:fade keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 4.6
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float4 screenPos : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				o.screenPos = ComputeScreenPos( o.pos );
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				surfIN.screenPos = IN.screenPos;
				SurfaceOutputCustomLightingCustom o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputCustomLightingCustom, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
}