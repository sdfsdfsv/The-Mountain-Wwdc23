import MetalKit


class MountainMTKView: MTKView {
    
    private var renderer: MountainRenderer
    
    init(frame: CGRect, pattern: Pattern, update: Bool, scale:Float) {
        self.renderer = MountainRenderer(p: pattern, update: update, scaleEffect: scale)
        super.init(frame: frame, device: renderer.device)
        self.delegate = renderer
        
    }
    func updateMountain(pattern: Pattern,update:Bool, scaleEffect:Float){
        self.renderer = MountainRenderer(p: pattern, update:update, scaleEffect: scaleEffect)
        self.delegate = renderer
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



class MountainRenderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let pipelineState: MTLRenderPipelineState
    var pattern:Pattern
    
    var texture: MTLTexture
    let vertexBuffer: MTLBuffer
    let resolutionBuffer: MTLBuffer
    let lightnessBuffer:MTLBuffer
    let heightBuffer: MTLBuffer
    let xlocationBuffer: MTLBuffer
    let rendercntBuffer:MTLBuffer
    
    
    let samplerState:MTLSamplerState
    
    let update:Bool
    var updated:Int
    let scaleEffect:Float
    init(p:Pattern,update:Bool,scaleEffect:Float=1) {
        
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = device.makeCommandQueue()!
        
        // Create a library and a shader function from the Shadertoy shader code
        let library = try! device.makeLibrary(source: shaderCode, options: nil)
        let vertexFunction = library.makeFunction(name: "vert")
        let fragmentFunction = library.makeFunction(name: "frag")
        
        self.pattern=p
        self.update=update
        self.updated=0
        self.scaleEffect=scaleEffect
        // Create a render pipeline descriptor and set the shader functions
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        
        // Create the render pipeline state
        self.pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        samplerDescriptor.rAddressMode = .repeat
        samplerDescriptor.normalizedCoordinates = true
        
        self.samplerState =  device.makeSamplerState(descriptor: samplerDescriptor)! // Create the sampler state
        
        var vertices: [Float] = Array(repeating: 0.0, count: p.imageX*p.imageY*8)
        var cnti=0
        let x=Float(p.imageX)
        let y=Float(p.imageY)
        for i in 0...p.imageY{
            for j in 0...p.imageX{
                if i>0 && j>0{
                    let a=Float(i)
                    let b=Float(j)
                    
                    vertices[cnti]=(a-1)
                    vertices[cnti+1]=(b-1)
                    vertices[cnti+2]=(a-1)
                    vertices[cnti+3]=b
                    vertices[cnti+4]=a
                    vertices[cnti+5]=(b-1)
                    vertices[cnti+6]=a
                    vertices[cnti+7]=b
                    cnti+=8
                }
            }
        }
        
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: [])!
        
        
        
        //create buffers that are passed to the shaders 
        var resolution = vector_float2(x*scaleEffect, y*scaleEffect) 
        self.resolutionBuffer = device.makeBuffer(bytes: &resolution, length: MemoryLayout<vector_float2>.size, options: [])!
        
        var l=p.lightness
        self.lightnessBuffer = device.makeBuffer(bytes: &l, length: MemoryLayout<Float>.size, options: [])!
        
        var h=p.height
        self.heightBuffer = device.makeBuffer(bytes: &h, length: MemoryLayout<Float>.size, options: [])!
        
        self.xlocationBuffer = device.makeBuffer(bytes: &p.xLocation, length: MemoryLayout<Float>.size, options: [])!
        self.rendercntBuffer = device.makeBuffer(bytes: &p.renderCnt, length: MemoryLayout<Float>.size, options: [])!
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = .type2D
        textureDescriptor.pixelFormat = .rgba8Unorm
        textureDescriptor.width =  StaticTextures.textureDict[self.pattern.texture]?.x ?? 1
        textureDescriptor.height =  StaticTextures.textureDict[self.pattern.texture]?.y ?? 1
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        
        
        self.texture = device.makeTexture(descriptor: textureDescriptor)!
        
        
        
    }
    
    func draw(in view: MTKView) {
        
        guard( update==true || (update==false && updated<2)) else{
            if updated==2 {
                view.isPaused=true
            }
            return}
        updated+=1
        
        
        // Create a command buffer and a render pass descriptor
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let renderPassDescriptor = view.currentRenderPassDescriptor!
        
        
        let textureLoader = MTKTextureLoader(device: device)
        let image = UIImage(named: self.pattern.texture)!
        
        
        
        do {
            try textureLoader.newTexture(cgImage: image.cgImage!, options: nil, completionHandler: { (newTexture: MTLTexture?, error: Error?) in
                if let newTexture = newTexture {
                    self.texture = newTexture
                }
            })
        } 
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        
        var time = pattern.saveTime==0 ? Float(CACurrentMediaTime()) : pattern.saveTime
        
        let itimeBuffer = device.makeBuffer(bytes: &time, length: MemoryLayout<Float>.size, options: [])!
        renderEncoder.setFragmentBuffer(itimeBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentBuffer(resolutionBuffer, offset: 0, index: 1)
        renderEncoder.setFragmentBuffer(lightnessBuffer, offset: 0, index: 2)
        renderEncoder.setFragmentBuffer(heightBuffer, offset: 0, index: 3)
        renderEncoder.setFragmentBuffer(xlocationBuffer, offset: 0, index: 4)
        renderEncoder.setFragmentBuffer(rendercntBuffer, offset: 0, index: 5)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: self.pattern.imageX*self.pattern.imageY*4)       
        renderEncoder.endEncoding()
        
        
        
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle drawable size changes, if needed
    }
}
