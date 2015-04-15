//
//  glvc.swift
//  Iso
//
//  Created by Gustaf Kugelberg on 13/09/14.
//  Copyright (c) 2014 Gustaf Kugelberg. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import OpenGLES
import GLKit

struct Vertex {
    var position: (CFloat, CFloat, CFloat)
    var color: (CFloat, CFloat, CFloat, CFloat)
}

class IsoViewController: GLKViewController {
    let glContext: EAGLContext
    let glDelegate: GLDelegate
    
    required init(coder aDecoder: NSCoder) {
        glContext = EAGLContext(API: .OpenGLES2)
        
        if !EAGLContext.setCurrentContext(glContext) {
            println("Failed to set current OpenGL context!")
            exit(1)
        }
        
        glDelegate = GLDelegate()
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        EAGLContext.setCurrentContext(glContext)
        setupVertexBuffer()
    }
    
    func setupView() {
        let glkView = view as! GLKView
        glkView.context = glContext
        glkView.delegate = glDelegate
        glkView.drawableColorFormat = .RGBA8888
        glkView.drawableDepthFormat = .Format16
        glkView.drawableMultisample = .Multisample4X
        
        glViewport(0, 0, GLint(view.frame.width), GLint(view.frame.height))
        
        preferredFramesPerSecond = 30
    }

    func setupVertexBuffer() {
        glDelegate.vertices = [
            Vertex(position: (0, -1, 0) , color: (1, 0, 0, 1)), // 0:
            Vertex(position: (0, 1, 0)  , color: (0, 1, 0, 1)), // 1:
            Vertex(position: (-2, 1, 0) , color: (0, 0, 1, 1)), // 2:
            Vertex(position: (-2, -1, 0), color: (1, 1, 1, 1)), // 3:
            Vertex(position: (2, -1, 0) , color: (0, 1, 1, 1)), // 4:
            Vertex(position: (2, 1, 0)  , color: (1, 0, 1, 1)), // 5:
        ]
        glDelegate.indices = [
            0, 1, 2,
            2, 3, 0,
            4, 5, 1,
            1, 0, 4
        ]
        
        glDelegate.setupVertexArrays()
    }
    
    func update() {
        glDelegate.time = Float(timeSinceLastResume)
    }
    
    func checkForOpenGLErrors() {
        let error = glGetError()
        switch (error) {
        case GLenum(GL_INVALID_ENUM):
            println("GL_INVALID_ENUM")
        case GLenum(GL_INVALID_VALUE):
            println("GL_INVALID_VALUE")
        case GLenum(GL_INVALID_OPERATION):
            println("GL_INVALID_OPERATION")
        case GLenum(GL_OUT_OF_MEMORY):
            println("GL_OUT_OF_MEMORY")
        default:
            return
        }
    }
}

class GLDelegate: NSObject, GLKViewDelegate {
    var time = Float()
    
    let baseEffect = BaseEffect()
    
    var vertices: [Vertex]!
    var indices: [GLubyte]!
    
    var indexBuffer: GLuint = GLuint()
    var vertexBuffer: GLuint  = GLuint()
    var vao = GLuint()
    
    override init() {
        baseEffect.compileShaders()
        
        super.init()
    }
    
    func setupVertexArrays() {
        glGenVertexArraysOES(1, &vao);
        glBindVertexArrayOES(vao);
        
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), vertices.size(), vertices, GLenum(GL_STATIC_DRAW))

        let positionOffset: UnsafePointer<Void> = UnsafePointer<Void>(bitPattern: 0)
        glEnableVertexAttribArray(baseEffect.positionSlot)
        glVertexAttribPointer(baseEffect.positionSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(sizeof(Vertex)), positionOffset)
        
        let colorOffset: UnsafePointer<Void> = UnsafePointer<Void>(bitPattern: 3*sizeof(Float))
        glEnableVertexAttribArray(baseEffect.colorSlot)
        glVertexAttribPointer(baseEffect.colorSlot, 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(sizeof(Vertex)), colorOffset)
        
        glGenBuffers(1, &indexBuffer)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), indices.size(), indices, GLenum(GL_STATIC_DRAW))
        
        glBindVertexArrayOES(0)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
    }
    
    func glkView(view: GLKView!, drawInRect rect: CGRect) {        
        glClearColor(1, 1, 1, 1);
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        var mat = GLKMatrix4MakeRotation(0, 0, 0, 1)
        mat = GLKMatrix4Scale(mat, 0.5 + 0.2*sin(time), 0.5 + 0.2*cos(time), 1)
        
        glUniformMatrix4fv(baseEffect.projectionUniform, GLsizei(1), GLboolean(GL_FALSE), mat.m)
        
        glBindVertexArrayOES(vao);
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(indices.count), GLenum(GL_UNSIGNED_BYTE), nil)
    }
}

extension GLKMatrix4 {
    var m: [Float] {
        return [m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31, m32, m33]
    }
}

extension Array {
    func size() -> Int {
        return count*sizeofValue(self[0])
    }
}
