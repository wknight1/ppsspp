// Enter your shader in this window
// xBRZ freescale
// based on :

// 4xBRZ shader - Copyright (C) 2014-2016 DeSmuME team
//
// This file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with the this software.  If not, see <http://www.gnu.org/licenses/>.


/*
   Hyllian's xBR-vertex code and texel mapping
   
   Copyright (C) 2011/2016 Hyllian - sergiogdb@gmail.com

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is 
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.

*/ 

#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#define BLEND_NONE 0
#define BLEND_NORMAL 1
#define BLEND_DOMINANT 2
#define LUMINANCE_WEIGHT 1.0
#define EQUAL_COLOR_TOLERANCE 30.0/255.0
#define STEEP_DIRECTION_THRESHOLD 2.2
#define DOMINANT_DIRECTION_THRESHOLD 3.6

uniform sampler2D sampler0;
uniform vec2 u_pixelDelta;
varying vec2 v_texcoord0;


float DistYCbCr(vec3 pixA, vec3 pixB)
{
	const vec3 w = vec3(0.2627, 0.6780, 0.0593);
	const float scaleB = 0.5 / (1.0 - w.b);
	const float scaleR = 0.5 / (1.0 - w.r);
	vec3 diff = pixA - pixB;
	float Y = dot(diff.rgb, w);
	float Cb = scaleB * (diff.b - Y);
	float Cr = scaleR * (diff.r - Y);

	return sqrt(((LUMINANCE_WEIGHT * Y) * (LUMINANCE_WEIGHT * Y)) + (Cb * Cb) + (Cr * Cr));
}

bool IsPixEqual(const vec3 pixA, const vec3 pixB)
{
	return (DistYCbCr(pixA, pixB) < EQUAL_COLOR_TOLERANCE);
}

float get_left_ratio(vec2 center, vec2 origin, vec2 direction, vec2 scale)
{
	vec2 P0 = center - origin;
	vec2 proj = direction * (dot(P0, direction) / dot(direction, direction));
	vec2 distv = P0 - proj;
	vec2 orth = vec2(-direction.y, direction.x);
	float side = sign(dot(P0, orth));
	float v = side * length(distv * scale);

//	return step(0, v);
	return smoothstep(-sqrt(2.0)/2.0, sqrt(2.0)/2.0, v);
}

#define eq(a,b)  (a == b)
#define neq(a,b) (a != b)

//#define P(x,y) COMPAT_TEXTURE(Source, coord + SourceSize.zw * vec2(x, y)).rgb

void main()
{
	//---------------------------------------
	// Input Pixel Mapping:	-|x|x|x|-
	//                       x|A|B|C|x
	//                       x|D|E|F|x
	//                       x|G|H|I|x
	//                       -|x|x|x|-
	float sampleMod = 0.791;//0.829;
	float scaleFactor = 480.0 * u_pixelDelta.x * sampleMod;
	vec2 scale = 1.0 / (u_pixelDelta.xy / scaleFactor);
	vec2 pos = fract(v_texcoord0.xy*scale.xy)- vec2(0.5, 0.5);
	vec2 coord = v_texcoord0.xy-pos*(u_pixelDelta.xy / scaleFactor);
	vec2 dx  = vec2(u_pixelDelta.x / scaleFactor,0.0);
	vec2 dy  = vec2(0.0,u_pixelDelta.y / scaleFactor);
	vec2 y2  = dy + dy; vec2 x2  = dx + dx;
/*
	vec3 A = P(-1.,-1.);
	vec3 B = P( 0.,-1.);
	vec3 C = P( 1.,-1.);
	vec3 D = P(-1., 0.);
	vec3 E = P( 0., 0.);
	vec3 F = P( 1., 0.);
	vec3 G = P(-1., 1.);
	vec3 H = P( 0., 1.);
	vec3 I = P( 1., 1.);
*/
	vec3 A  = texture2D(sampler0, coord -dx -dy	).xyz;
	vec3 B  = texture2D(sampler0, coord	 -dy	).xyz;
	vec3 C  = texture2D(sampler0, coord +dx -dy	).xyz;
	vec3 D  = texture2D(sampler0, coord -dx		).xyz;
	vec3 E  = texture2D(sampler0, coord		).xyz;
	vec3 F  = texture2D(sampler0, coord +dx		).xyz;
	vec3 G  = texture2D(sampler0, coord -dx +dy	).xyz;
	vec3 H  = texture2D(sampler0, coord	 +dy	).xyz;
	vec3 I  = texture2D(sampler0, coord +dx +dy	).xyz;

	vec3 A1 = texture2D(sampler0, coord	 -dx -y2).xyz; //-1,-2
	vec3 C1 = texture2D(sampler0, coord	 +dx -y2).xyz; //1,-2
	vec3 A0 = texture2D(sampler0, coord -x2	     -dy).xyz; //-2,-1
	vec3 G0 = texture2D(sampler0, coord -x2	     +dy).xyz; //-2,1
	vec3 C4 = texture2D(sampler0, coord +x2	     -dy).xyz; //2,-1
	vec3 I4 = texture2D(sampler0, coord +x2	     +dy).xyz; //2,1
	vec3 G5 = texture2D(sampler0, coord	 -dx +y2).xyz; //-1,2
	vec3 I5 = texture2D(sampler0, coord	 +dx +y2).xyz; //1,2
	vec3 B1 = texture2D(sampler0, coord	     -y2).xyz; //0,-2
	vec3 D0 = texture2D(sampler0, coord -x2		).xyz; //-2,0
	vec3 H5 = texture2D(sampler0, coord	     +y2).xyz; //0,2
	vec3 F4 = texture2D(sampler0, coord +x2		).xyz; //2,0

	// blendResult Mapping: x|y|
	//                      w|z|
	ivec4 blendResult = ivec4(BLEND_NONE,BLEND_NONE,BLEND_NONE,BLEND_NONE);

	// Preprocess corners
	// Pixel Tap Mapping: -|-|-|-|-
	//                    -|-|B|C|-
	//                    -|D|E|F|x
	//                    -|G|H|I|x
	//                    -|-|x|x|-
	if (!((eq(E,F) && eq(H,I)) || (eq(E,H) && eq(F,I))))
	{
		float dist_H_F = DistYCbCr(G, E) + DistYCbCr(E, C) + DistYCbCr(H5, I) + DistYCbCr(I, F4) + (4.0 * DistYCbCr(H, F));
		float dist_E_I = DistYCbCr(D, H) + DistYCbCr(H, I5) + DistYCbCr(B, F) + DistYCbCr(F, I4) + (4.0 * DistYCbCr(E, I));
		bool dominantGradient = (DOMINANT_DIRECTION_THRESHOLD * dist_H_F) < dist_E_I;
		blendResult.z = ((dist_H_F < dist_E_I) && neq(E,F) && neq(E,H)) ? ((dominantGradient) ? BLEND_DOMINANT : BLEND_NORMAL) : BLEND_NONE;
	}


	// Pixel Tap Mapping: -|-|-|-|-
	//                    -|A|B|-|-
	//                    x|D|E|F|-
	//                    x|G|H|I|-
	//                    -|x|x|-|-
	if (!((eq(D,E) && eq(G,H)) || (eq(D,G) && eq(E,H))))
	{
		float dist_G_E = DistYCbCr(G0, D) + DistYCbCr(D, B) + DistYCbCr(G5, H) + DistYCbCr(H, F) + (4.0 * DistYCbCr(G, E));
		float dist_D_H = DistYCbCr(D0, G) + DistYCbCr(G, H5) + DistYCbCr(A, E) + DistYCbCr(E, I) + (4.0 * DistYCbCr(D, H));
		bool dominantGradient = (DOMINANT_DIRECTION_THRESHOLD * dist_D_H) < dist_G_E;
		blendResult.w = ((dist_G_E > dist_D_H) && neq(E,D) && neq(E,H)) ? ((dominantGradient) ? BLEND_DOMINANT : BLEND_NORMAL) : BLEND_NONE;
	}

	// Pixel Tap Mapping: -|-|x|x|-
	//                    -|A|B|C|x
	//                    -|D|E|F|x
	//                    -|-|H|I|-
	//                    -|-|-|-|-
	if (!((eq(B,C) && eq(E,F)) || (eq(B,E) && eq(C,F))))
	{
		float dist_E_C = DistYCbCr(D, B) + DistYCbCr(B, C1) + DistYCbCr(H, F) + DistYCbCr(F, C4) + (4.0 * DistYCbCr(E, C));
		float dist_B_F = DistYCbCr(A, E) + DistYCbCr(E, I) + DistYCbCr(B1, C) + DistYCbCr(C, F4) + (4.0 * DistYCbCr(B, F));
		bool dominantGradient = (DOMINANT_DIRECTION_THRESHOLD * dist_B_F) < dist_E_C;
		blendResult.y = ((dist_E_C > dist_B_F) && neq(E,B) && neq(E,F)) ? ((dominantGradient) ? BLEND_DOMINANT : BLEND_NORMAL) : BLEND_NONE;
	}

	// Pixel Tap Mapping: -|x|x|-|-
	//                    x|A|B|C|-
	//                    x|D|E|F|-
	//                    -|G|H|-|-
	//                    -|-|-|-|-
	if (!((eq(A,B) && eq(D,E)) || (eq(A,D) && eq(B,E))))
	{
		float dist_D_B = DistYCbCr(D0, A) + DistYCbCr(A, B1) + DistYCbCr(G, E) + DistYCbCr(E, C) + (4.0 * DistYCbCr(D, B));
		float dist_A_E = DistYCbCr(A0, D) + DistYCbCr(D, H) + DistYCbCr(A1, B) + DistYCbCr(B, F) + (4.0 * DistYCbCr(A, E));
		bool dominantGradient = (DOMINANT_DIRECTION_THRESHOLD * dist_D_B) < dist_A_E;
		blendResult.x = ((dist_D_B < dist_A_E) && neq(E,D) && neq(E,B)) ? ((dominantGradient) ? BLEND_DOMINANT : BLEND_NORMAL) : BLEND_NONE;
	}

	vec3 res = E;

	// Pixel Tap Mapping: -|-|-|-|-
	//                    -|-|B|C|-
	//                    -|D|E|F|x
	//                    -|G|H|I|x
	//                    -|-|x|x|-
	if(blendResult.z != BLEND_NONE)
	{
		float dist_F_G = DistYCbCr(F, G);
		float dist_H_C = DistYCbCr(H, C);
		bool doLineBlend = (blendResult.z == BLEND_DOMINANT ||
				!((blendResult.y != BLEND_NONE && !IsPixEqual(E, G)) || (blendResult.w != BLEND_NONE && !IsPixEqual(E, C)) ||
				(IsPixEqual(G, H) && IsPixEqual(H, I) && IsPixEqual(I, F) && IsPixEqual(F, C) && !IsPixEqual(E, I))));

		vec2 origin = vec2(0.0, 1.0 / sqrt(2.0));
		vec2 direction = vec2(1.0, -1.0);
		if(doLineBlend)
		{
			bool haveShallowLine = (STEEP_DIRECTION_THRESHOLD * dist_F_G <= dist_H_C) && neq(E,G) && neq(D,G);
			bool haveSteepLine = (STEEP_DIRECTION_THRESHOLD * dist_H_C <= dist_F_G) && neq(E,C) && neq(B,C);
			origin = haveShallowLine? vec2(0.0, 0.25) : vec2(0.0, 0.5);
			direction.x += haveShallowLine? 1.0: 0.0;
			direction.y -= haveSteepLine? 1.0: 0.0;
		}

		vec3 blendPix = mix(H,F, step(DistYCbCr(E, F), DistYCbCr(E, H)));
		res = mix(res, blendPix, get_left_ratio(pos, origin, direction, scale));
	}

	// Pixel Tap Mapping: -|-|-|-|-
	//                    -|A|B|-|-
	//                    x|D|E|F|-
	//                    x|G|H|I|-
	//                    -|x|x|-|-
	if(blendResult.w != BLEND_NONE)
	{
		float dist_H_A = DistYCbCr(H, A);
		float dist_D_I = DistYCbCr(D, I);
		bool doLineBlend = (blendResult.w == BLEND_DOMINANT ||
				!((blendResult.z != BLEND_NONE && !IsPixEqual(E, A)) || (blendResult.x != BLEND_NONE && !IsPixEqual(E, I)) ||
				(IsPixEqual(A, D) && IsPixEqual(D, G) && IsPixEqual(G, H) && IsPixEqual(H, I) && !IsPixEqual(E, G))));

		vec2 origin = vec2(-1.0 / sqrt(2.0), 0.0);
		vec2 direction = vec2(1.0, 1.0);
		if(doLineBlend)
		{
			bool haveShallowLine = (STEEP_DIRECTION_THRESHOLD * dist_H_A <= dist_D_I) && neq(E,A) && neq(B,A);
			bool haveSteepLine	= (STEEP_DIRECTION_THRESHOLD * dist_D_I <= dist_H_A) && neq(E,I) && neq(F,I);
			origin = haveShallowLine? vec2(-0.25, 0.0) : vec2(-0.5, 0.0);
			direction.y += haveShallowLine? 1.0: 0.0;
			direction.x += haveSteepLine? 1.0: 0.0;
		}
		origin = origin;
		direction = direction;

		vec3 blendPix = mix(H,D, step(DistYCbCr(E, D), DistYCbCr(E, H)));
		res = mix(res, blendPix, get_left_ratio(pos, origin, direction, scale));
	}

	// Pixel Tap Mapping: -|-|x|x|-
	//                    -|A|B|C|x
	//                    -|D|E|F|x
	//                    -|-|H|I|-
	//                    -|-|-|-|-
	if(blendResult.y != BLEND_NONE)
	{
		float dist_B_I = DistYCbCr(B, I);
		float dist_F_A = DistYCbCr(F, A);
		bool doLineBlend = (blendResult.y == BLEND_DOMINANT ||
				!((blendResult.x != BLEND_NONE && !IsPixEqual(E, I)) || (blendResult.z != BLEND_NONE && !IsPixEqual(E, A)) ||
				(IsPixEqual(I, F) && IsPixEqual(F, C) && IsPixEqual(C, B) && IsPixEqual(B, A) && !IsPixEqual(E, C))));

		vec2 origin = vec2(1.0 / sqrt(2.0), 0.0);
		vec2 direction = vec2(-1.0, -1.0);

		if(doLineBlend)
		{
			bool haveShallowLine = (STEEP_DIRECTION_THRESHOLD * dist_B_I <= dist_F_A) && neq(E,I) && neq(H,I);
			bool haveSteepLine	= (STEEP_DIRECTION_THRESHOLD * dist_F_A <= dist_B_I) && neq(E,A) && neq(D,A);
			origin = haveShallowLine? vec2(0.25, 0.0) : vec2(0.5, 0.0);
			direction.y -= haveShallowLine? 1.0: 0.0;
			direction.x -= haveSteepLine? 1.0: 0.0;
		}

		vec3 blendPix = mix(F,B, step(DistYCbCr(E, B), DistYCbCr(E, F)));
		res = mix(res, blendPix, get_left_ratio(pos, origin, direction, scale));
	}

	// Pixel Tap Mapping: -|x|x|-|-
	//                    x|A|B|C|-
	//                    x|D|E|F|-
	//                    -|G|H|-|-
	//                    -|-|-|-|-
	if(blendResult.x != BLEND_NONE)
	{
		float dist_D_C = DistYCbCr(D, C);
		float dist_B_G = DistYCbCr(B, G);
		bool doLineBlend = (blendResult.x == BLEND_DOMINANT ||
				!((blendResult.w != BLEND_NONE && !IsPixEqual(E, C)) || (blendResult.y != BLEND_NONE && !IsPixEqual(E, G)) ||
				(IsPixEqual(C, B) && IsPixEqual(B, A) && IsPixEqual(A, D) && IsPixEqual(D, G) && !IsPixEqual(E, A))));

		vec2 origin = vec2(0.0, -1.0 / sqrt(2.0));
		vec2 direction = vec2(-1.0, 1.0);
		if(doLineBlend)
		{
			bool haveShallowLine = (STEEP_DIRECTION_THRESHOLD * dist_D_C <= dist_B_G) && neq(E,C) && neq(F,C);
			bool haveSteepLine	= (STEEP_DIRECTION_THRESHOLD * dist_B_G <= dist_D_C) && neq(E,G) && neq(H,G);
			origin = haveShallowLine? vec2(0.0, -0.25) : vec2(0.0, -0.5);
			direction.x -= haveShallowLine? 1.0: 0.0;
			direction.y += haveSteepLine? 1.0: 0.0;
		}

		vec3 blendPix = mix(D,B, step(DistYCbCr(E, B), DistYCbCr(E, D)));
		res = mix(res, blendPix, get_left_ratio(pos, origin, direction, scale));
	}

 	gl_FragColor.rgb = res;
	gl_FragColor.a = 1.0;
} 