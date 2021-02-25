

//  Created by Mahfuzur Rahman


#import "OpenGLView.h"
#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>


@interface OpenGLView()
{
    EAGLContext *context;
    
    GLuint viewRenderBuffer;
    GLuint viewFrameBuffer;
    // shader
    GLuint texProgramHandle;

    GLuint TexVertex;
    
    //Uniform
    GLuint TexCoordSlot;
    GLuint TextureUniform;
    
    GLuint textureImage;
}

@end;

@implementation OpenGLView


const GLfloat textureCoordinate[] = {
    1.0f, 	1.0f,
    1.0f, 	0.0f,
    0.0f,  	1.0f,
    0.0f,  	0.0f,
};

const GLfloat vertexCoordinate[] = {
  -1.0f,	-1.0f,
  1.0f,		-1.0f,
  -1.0f,	1.0f,
  1.0f,		1.0f,
};

// pragma mark - Functions

+ (Class)layerClass{
    return [CAEAGLLayer class];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    
    if((self != [super initWithCoder:aDecoder]))
        return self;

    //setup layer
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *) self.layer;
    eaglLayer.opaque = YES;
    
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],
                                    kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];

    //setup context
    context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if(!context || ![EAGLContext setCurrentContext:context]){
        return nil;
    }

    textureImage = [self setupTexture: @"leaves.png"];

    //setup RenderBuffer
    glGenRenderbuffers(1, &viewRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderBuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(id<EAGLDrawable>)self.layer];

    //setup FrameBuffer
    glGenFramebuffers(1, &viewFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, viewFrameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, viewRenderBuffer);

    // setup Shader
    {
        //1
        GLuint textureVertexShader = [self compileShader:@"TextureVertex" withType:GL_VERTEX_SHADER];
        GLuint textureFragmentShader = [self compileShader:@"TextureFragment" withType:GL_FRAGMENT_SHADER];

        //2
        texProgramHandle = glCreateProgram();
        glAttachShader(texProgramHandle, textureVertexShader);
        glAttachShader(texProgramHandle, textureFragmentShader);
        glLinkProgram(texProgramHandle);

        //3
        glUseProgram(texProgramHandle);

        //4
        TexCoordSlot = glGetAttribLocation(texProgramHandle, "TexCoordIn");
        TexVertex = glGetAttribLocation(texProgramHandle, "TexVertex");
        TextureUniform = glGetUniformLocation(texProgramHandle, "Texture");

        glEnableVertexAttribArray(TexVertex);
        glEnableVertexAttribArray(TexCoordSlot);
    }
    
    // Render or drawTexture
    {
        NSLog(@"drawTexture:===========");
        
        glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);

        // 1
        glViewport(0, 0, self.frame.size.width, self.frame.size.height);//glViewport(0, 0, backingWidth, backingHeight);

        glUseProgram(texProgramHandle);

        glVertexAttribPointer(TexVertex, 2, GL_FLOAT, 0, 0, vertexCoordinate);
        glVertexAttribPointer(TexCoordSlot,2,GL_FLOAT,0,0, textureCoordinate);

        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, textureImage);
        glUniform1i(TextureUniform, 0);

        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

        // Call a method on the OpenGL context to present the render/color buffer to the UIView’s layer!
        [context presentRenderbuffer:GL_RENDERBUFFER];// viewRenderBuffer];
    }
    
    return self;
}

- (GLuint) compileShader:(NSString*)shaderName withType:(GLenum)shaderType{
    // 1
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName
                                                           ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    // 2
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // 3
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    // 4
    glCompileShader(shaderHandle);
    
    // 5
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
}

- (GLuint)setupTexture:(NSString *)fileName {
    // 1
    UIImage *tmpImage = [UIImage imageNamed:fileName];
    
    CGImageRef spriteImage = tmpImage.CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    // 2
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte * spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 3
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    // 4
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    
    return texName;
}


@end
