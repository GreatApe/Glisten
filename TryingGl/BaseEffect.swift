//
//  BaseEffect.swift
//  Iso
//
//  Created by Gustaf Kugelberg on 14/09/14.
//  Copyright (c) 2014 Gustaf Kugelberg. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import OpenGLES
import GLKit

class BaseEffect: NSObject {
    var programHandle = glCreateProgram()
    var positionSlot = GLuint()
    var colorSlot = GLuint()
    
    var projectionUniform = GLint()
    
    func compileShaders() {
        // Compile our vertex and fragment shaders.
        // Call glCreateProgram, glAttachShader, and glLinkProgram to link the vertex and fragment shaders into a complete program.
        
        var vertexShader = compileShader("SimpleVertex", shaderType: GLenum(GL_VERTEX_SHADER))
        glAttachShader(programHandle, vertexShader)
        
        var fragmentShader = compileShader("SimpleFragment", shaderType: GLenum(GL_FRAGMENT_SHADER))
        glAttachShader(programHandle, fragmentShader)
        
        glLinkProgram(programHandle)
        
        // Check for any errors.
        var linkSuccess: GLint = GLint()
        glGetProgramiv(programHandle, GLenum(GL_LINK_STATUS), &linkSuccess)
        
        if (linkSuccess == GL_FALSE) {
            println("Failed to create shader program!")
            // TODO: Actually output the error that we can get from the glGetProgramInfoLog function.
            exit(1);
        }
        
        // Call glUseProgram to tell OpenGL to actually use this program when given vertex info.
        glUseProgram(programHandle)
        
        // Finally, call glGetAttribLocation to get a pointer to the input values for the vertex shader, so we
        //  can set them in code. Also call glEnableVertexAttribArray to enable use of these arrays (they are disabled by default).
        positionSlot = GLuint(glGetAttribLocation(programHandle, "Position"))
        glEnableVertexAttribArray(positionSlot)
        
        colorSlot = GLuint(glGetAttribLocation(programHandle, "SourceColor"))
        glEnableVertexAttribArray(colorSlot)
        
        projectionUniform = glGetUniformLocation(programHandle, "Projection")
    }
    
    private func compileShader(shaderName: String, shaderType: GLenum) -> GLuint {
        // Get string with contents of our shader file.
        
        if let shaderPath = NSBundle.mainBundle().pathForResource(shaderName, ofType: "glsl") {
            var error: NSError? = nil
            
            var shaderString = NSString(contentsOfFile: shaderPath, encoding: NSUTF8StringEncoding, error: &error)
            
            if (shaderString == nil) {
                println("Failed to set contents shader of shader file!")
            }
            
            // Tell OpenGL to create an OpenGL object to represent the shader, indicating if it's a vertex or a fragment shader.
            var shaderHandle: GLuint = glCreateShader(shaderType)
            
            // Convert shader string to CString and call glShaderSource to give OpenGL the source for the shader.
            var shaderStringUTF8 = shaderString!.UTF8String
            var shaderStringLength = GLint(shaderString!.length)
            //            var shaderStringLength = GLint.convertFromIntegerLiteral(Int32(shaderString!.length))
            glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength)
            
            // Tell OpenGL to compile the shader.
            glCompileShader(shaderHandle)
            
            // But compiling can fail! If we have errors in our GLSL code, we can here and output any errors.
            
            var compileSuccess = GLint()
            glGetShaderiv(shaderHandle, GLenum(GL_COMPILE_STATUS), &compileSuccess)
            
            if (compileSuccess == GL_FALSE) {
                println("Failed to compile shader!")
                
                var value: GLint = 0
                glGetShaderiv(shaderHandle, GLenum(GL_INFO_LOG_LENGTH), &value)
                var infoLog: [GLchar] = [GLchar](count: Int(value), repeatedValue: 0)
                var infoLogLength: GLsizei = 0
                glGetShaderInfoLog(shaderHandle, value, &infoLogLength, &infoLog)
                
                var str = NSString(bytes: infoLog, length: Int(infoLogLength), encoding: NSASCIIStringEncoding)
                println(str!)
                
                exit(1);
            }
            
            return shaderHandle
        }
        
        return 0
    }
}