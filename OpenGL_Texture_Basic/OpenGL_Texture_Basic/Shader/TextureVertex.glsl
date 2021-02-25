
//  Created by Mahfuzur Rahman

attribute vec4 TexVertex;
attribute vec4 TexCoordIn;

varying vec2 TexCoordOut;

void main()
{
    gl_Position = TexVertex;
    TexCoordOut = TexCoordIn.xy;
    
}
