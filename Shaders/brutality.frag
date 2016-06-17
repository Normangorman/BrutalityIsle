uniform sampler2D baseMap;
uniform float scale;
uniform float screenWidth;
uniform float screenHeight;

// hq2x stuff
const float mx = 0.325;      // start smoothing wt.
const float k = -0.250;      // wt. decrease factor
const float max_w = 0.25;    // max filter weigth
const float min_w =-0.05;    // min filter weigth
const float lum_add = 0.25;  // effects smoothing

// darkness stuff
uniform float player_x;
uniform float player_y;
uniform int enable_darkness;
uniform float darkness_factor; // 0 for nothing, 1.0 for 'total' darkness

const vec3 black_color = vec3(0.0, 0.0, 0.0);
const vec3 white_color = vec3(1.0, 1.0, 1.0);
const float min_light_radius = 144.0;

vec4 darkness(vec4 inputFragColor)
{
    vec3 inFragColor = inputFragColor.xyz; 
    vec2 fragCoord = vec2(gl_FragCoord);
    vec2 playerCoord = vec2(player_x, screenHeight - player_y);
    
    float d = length(fragCoord - playerCoord);

    //light end and half light end
    float le = max(2.0*screenWidth*(1.0 - darkness_factor), min_light_radius) * scale;  
    float hle = le/2.0;
    if (d <= le)
    {
        if (d >= hle)
        {
            float s = (le - d)/hle;
            vec3 blended = mix(black_color, inFragColor, s);
            return vec4(blended, 1.0);
        }
        else
        {
            return vec4(inFragColor, 1.0);
        }
    }   
    else
    {
        return vec4(black_color, 1.0);
    }
}

void main() 
{
    // Start hq2x
    vec3 c00 = texture2D(baseMap, gl_TexCoord[1].xy).xyz; 
    vec3 c10 = texture2D(baseMap, gl_TexCoord[1].zw).xyz; 
    vec3 c20 = texture2D(baseMap, gl_TexCoord[2].xy).xyz; 
    vec3 c01 = texture2D(baseMap, gl_TexCoord[4].zw).xyz; 
    vec3 c11 = texture2D(baseMap, gl_TexCoord[0].xy).xyz; 
    vec3 c21 = texture2D(baseMap, gl_TexCoord[2].zw).xyz; 
    vec3 c02 = texture2D(baseMap, gl_TexCoord[4].xy).xyz; 
    vec3 c12 = texture2D(baseMap, gl_TexCoord[3].zw).xyz; 
    vec3 c22 = texture2D(baseMap, gl_TexCoord[3].xy).xyz; 
    vec3 dt = vec3(1.0, 1.0, 1.0);

    float md1 = dot(abs(c00 - c22), dt);
    float md2 = dot(abs(c02 - c20), dt);

    float w1 = dot(abs(c22 - c11), dt) * md2;
    float w2 = dot(abs(c02 - c11), dt) * md1;
    float w3 = dot(abs(c00 - c11), dt) * md2;
    float w4 = dot(abs(c20 - c11), dt) * md1;

    float t1 = w1 + w3;
    float t2 = w2 + w4;
    float ww = max(t1, t2) + 0.0001;

    c11 = (w1 * c00 + w2 * c20 + w3 * c22 + w4 * c02 + ww * c11) / (t1 + t2 + ww);

    float lc1 = k / (0.12 * dot(c10 + c12 + c11, dt) + lum_add);
    float lc2 = k / (0.12 * dot(c01 + c21 + c11, dt) + lum_add);

    w1 = clamp(lc1 * dot(abs(c11 - c10), dt) + mx, min_w, max_w);
    w2 = clamp(lc2 * dot(abs(c11 - c21), dt) + mx, min_w, max_w);
    w3 = clamp(lc1 * dot(abs(c11 - c12), dt) + mx, min_w, max_w);
    w4 = clamp(lc2 * dot(abs(c11 - c01), dt) + mx, min_w, max_w);

    vec4 outcolor;
    outcolor.rgb = w1 * c10 + w2 * c21 + w3 * c12 + w4 * c01 + (1.0 - w1 - w2 - w3 - w4) * c11;
    outcolor.a = 1.0;
    // end hq2x

    if (enable_darkness == 0)
    {
        gl_FragColor = outcolor;
    }
    else
    {
        gl_FragColor = darkness(outcolor);
    }
}
