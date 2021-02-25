
//  Created by Mahfuzur Rahman

varying lowp vec2 TexCoordOut;
uniform sampler2D Texture;

void main()
{
    lowp vec4 color  = texture2D(Texture,TexCoordOut);
    
    gl_FragColor = color;

}

