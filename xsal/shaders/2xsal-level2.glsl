/*
    Copyright (C) 2016 guest(r) - guest.r@gmail.com

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#define COMPAT_TEXTURE texture
#else
#define COMPAT_VARYING varying 
#define COMPAT_ATTRIBUTE attribute 
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 COL0;
COMPAT_VARYING vec4 TEX0;
// out variables go here as COMPAT_VARYING whatever

uniform mat4 MVPMatrix;
uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// vertex compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy * 1.00001;
}

#elif defined(FRAGMENT)

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

uniform int FrameDirection;
uniform int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;
// in variables go here as COMPAT_VARYING whatever

// fragment compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    vec2 tex = vTexCoord;   
    //vec2 texsize = IN.texture_size;
    float dx = 0.25*SourceSize.z;
    float dy = 0.25*SourceSize.w;
    vec3  dt = vec3(1.0, 1.0, 1.0);

    vec4 yx = vec4(dx, dy, -dx, -dy);
    vec4 xh = yx*vec4(3.0, 1.0, 3.0, 1.0);
    vec4 yv = yx*vec4(1.0, 3.0, 1.0, 3.0);

    vec3 c11 = texture(Source, tex        ).xyz;    
    vec3 s00 = texture(Source, tex + yx.zw).xyz; 
    vec3 s20 = texture(Source, tex + yx.xw).xyz; 
    vec3 s22 = texture(Source, tex + yx.xy).xyz; 
    vec3 s02 = texture(Source, tex + yx.zy).xyz;
    vec3 h00 = texture(Source, tex + xh.zw).xyz; 
    vec3 h20 = texture(Source, tex + xh.xw).xyz; 
    vec3 h22 = texture(Source, tex + xh.xy).xyz; 
    vec3 h02 = texture(Source, tex + xh.zy).xyz;
    vec3 v00 = texture(Source, tex + yv.zw).xyz; 
    vec3 v20 = texture(Source, tex + yv.xw).xyz; 
    vec3 v22 = texture(Source, tex + yv.xy).xyz; 
    vec3 v02 = texture(Source, tex + yv.zy).xyz;     

    float m1 = 1.0/(dot(abs(s00 - s22), dt) + 0.00001);
    float m2 = 1.0/(dot(abs(s02 - s20), dt) + 0.00001);
    float h1 = 1.0/(dot(abs(s00 - h22), dt) + 0.00001);
    float h2 = 1.0/(dot(abs(s02 - h20), dt) + 0.00001);
    float h3 = 1.0/(dot(abs(h00 - s22), dt) + 0.00001);
    float h4 = 1.0/(dot(abs(h02 - s20), dt) + 0.00001);
    float v1 = 1.0/(dot(abs(s00 - v22), dt) + 0.00001);
    float v2 = 1.0/(dot(abs(s02 - v20), dt) + 0.00001);
    float v3 = 1.0/(dot(abs(v00 - s22), dt) + 0.00001);
    float v4 = 1.0/(dot(abs(v02 - s20), dt) + 0.00001);

    vec3 t1 = 0.5*(m1*(s00 + s22) + m2*(s02 + s20))/(m1 + m2);
    vec3 t2 = 0.5*(h1*(s00 + h22) + h2*(s02 + h20) + h3*(h00 + s22) + h4*(h02 + s20))/(h1 + h2 + h3 + h4);
    vec3 t3 = 0.5*(v1*(s00 + v22) + v2*(s02 + v20) + v3*(v00 + s22) + v4*(v02 + s20))/(v1 + v2 + v3 + v4);

    float k1 = 1.0/(dot(abs(t1 - c11), dt) + 0.00001);
    float k2 = 1.0/(dot(abs(t2 - c11), dt) + 0.00001);
    float k3 = 1.0/(dot(abs(t3 - c11), dt) + 0.00001);

    FragColor = vec4((k1*t1 + k2*t2 + k3*t3)/(k1 + k2 + k3), 1.0);
} 
#endif
