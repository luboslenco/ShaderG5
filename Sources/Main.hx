package;

import haxe.ds.Vector;
import kha.Color;
import kha.Framebuffer;
import kha.Shaders;
import kha.System;
import kha.graphics5.CommandList;
import kha.graphics5.RenderTarget;
import kha.graphics5.PipelineState;
import kha.graphics5.VertexBuffer;
import kha.graphics5.IndexBuffer;
import kha.graphics5.VertexStructure;
import kha.graphics5.VertexData;
import kha.graphics5.Usage;
import kha.graphics5.TextureFormat;

class Main {
	private static inline var bufferCount = 2;
	private static var currentBuffer = -1;
	private static var commandList:CommandList;
	private static var framebuffers = new Vector<RenderTarget>(bufferCount);
	private static var pipeline:PipelineState;
	private static var vertices:VertexBuffer;
	private static var indices:IndexBuffer;
	
	public static function main(): Void {
		System.start({title: "Shader", width: 640, height: 480}, function (_) {
			commandList = new CommandList();
			for (i in 0...bufferCount) {
				framebuffers[i] = new RenderTarget(640, 480, 16, false, TextureFormat.RGBA32,
				                                   -1, -i - 1 /* hack in an index for backbuffer render targets */);
			}

			var structure = new VertexStructure();
			structure.add("pos", VertexData.Float3);
			
			pipeline = new PipelineState();
			pipeline.inputLayout = [structure];
			pipeline.vertexShader = Shaders.shader_vert;
			pipeline.fragmentShader = Shaders.shader_frag;
			pipeline.compile();
			
			vertices = new VertexBuffer(3, structure, Usage.StaticUsage);
			var v = vertices.lock();
			v.set(0, -1); v.set(1, -1); v.set(2, 0.5);
			v.set(3,  1); v.set(4, -1); v.set(5, 0.5);
			v.set(6, -1); v.set(7,  1); v.set(8, 0.5);
			vertices.unlock();
			
			indices = new IndexBuffer(3, Usage.StaticUsage);
			var i = indices.lock();
			i[0] = 0; i[1] = 1; i[2] = 2;
			indices.unlock();
			
			System.notifyOnFrames(render);
		});
	}
	
	private static function render(frames: Array<Framebuffer>): Void {
		var g = frames[0].g5;
		currentBuffer = (currentBuffer + 1) % bufferCount;

		g.begin(framebuffers[currentBuffer]);

		commandList.begin();
		commandList.framebufferToRenderTargetBarrier(framebuffers[currentBuffer]);
		commandList.setRenderTargets([framebuffers[currentBuffer]]);

		commandList.clear(framebuffers[currentBuffer], 0xff000000);
		commandList.setPipeline(pipeline);
		commandList.setPipelineLayout();

		var offsets = [0];
		commandList.setVertexBuffers([vertices], offsets);
		commandList.setIndexBuffer(indices);
		commandList.drawIndexedVertices();

		commandList.renderTargetToFramebufferBarrier(framebuffers[currentBuffer]);
		commandList.end();
		
		g.end();
		g.swapBuffers();
	}
}
