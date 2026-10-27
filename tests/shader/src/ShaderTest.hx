package;

import openfl.display.Shader;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterType;
import openfl.display.ShaderPrecision;
import openfl.utils.ByteArray;
import utest.Assert;
import utest.Test;
#if !flash
import openfl.display.GraphicsShader;
#end

class ShaderTest extends Test
{
	public function test_new_()
	{
		var shader = new Shader();

		Assert.equals(ShaderPrecision.FULL, shader.precisionHint);
	}

	@Ignored
	public function test_byteCode()
	{
		// TODO: Confirm functionality

		var shader = new Shader();
		#if !flash
		shader.byteCode = new ByteArray();
		#end
	}

	@Ignored
	public function test_data()
	{
		// TODO: Confirm functionality

		// var shader = new Shader ();
		// var exists = shader.data;

		// #if flash
		// Assert.isNull (exists);
		// #else
		// Assert.notNull (exists);
		// #end
	}

	#if flash
	@Ignored
	#end
	public function test_data_ignoresGLSLComments()
	{
		#if !flash
		var shader = new Shader();
		shader.glVertexSource = "// attribute vec2 lineCommentAttribute;
			/* attribute vec2 blockCommentAttribute; */
			attribute vec4 openfl_Position;
			uniform mat4 openfl_Matrix;

			void main(void) {
				gl_Position = openfl_Matrix * openfl_Position;
			}";
		shader.glFragmentSource = "/**
			 * Here we use the u_time uniform to change the letter
			 */
			// uniform vec4 lineCommentUniform;
			uniform float u_time;

			void main(void) {
				gl_FragColor = vec4(u_time);
			}";

		var data = shader.data;

		Assert.isFalse(Reflect.hasField(data, "change"));
		Assert.isFalse(Reflect.hasField(data, "lineCommentUniform"));
		Assert.isFalse(Reflect.hasField(data, "lineCommentAttribute"));
		Assert.isFalse(Reflect.hasField(data, "blockCommentAttribute"));

		Assert.notNull(Reflect.field(data, "openfl_Position"));
		Assert.notNull(Reflect.field(data, "openfl_Matrix"));

		var time:ShaderParameter<Float> = Reflect.field(data, "u_time");
		Assert.notNull(time);
		Assert.equals(ShaderParameterType.FLOAT, time.type);
		#end
	}

	#if flash
	@Ignored
	#end
	public function test_glSourceMetadata_ignoresGLSLComments()
	{
		#if !flash
		var shader = new CommentedShader();
		var fields = Type.getInstanceFields(CommentedShader);

		Assert.equals(-1, fields.indexOf("change"));
		Assert.equals(-1, fields.indexOf("lineCommentAttribute"));
		Assert.equals(-1, fields.indexOf("blockCommentAttribute"));
		Assert.isFalse(Reflect.hasField(shader.data, "change"));

		Assert.notNull(shader.image);
		Assert.notNull(shader.u_time);
		Assert.equals(ShaderParameterType.FLOAT, shader.u_time.type);
		#end
	}

	public function test_precisionHint()
	{
		var shader = new Shader();

		Assert.equals(ShaderPrecision.FULL, shader.precisionHint);

		shader.precisionHint = ShaderPrecision.FAST;

		Assert.equals(ShaderPrecision.FAST, shader.precisionHint);
	}
}

#if !flash
private class CommentedShader extends GraphicsShader
{
	@:glVertexSource("#pragma header

		// attribute vec2 lineCommentAttribute;
		/* attribute vec2 blockCommentAttribute; */

		void main(void) {

			#pragma body

		}")
	@:glFragmentSource("#pragma header

		/**
		 * Here we use the u_time uniform to change the letter
		 */
		// uniform vec4 image;
		uniform sampler2D image;
		uniform float u_time;

		void main(void) {

			#pragma body

			gl_FragColor *= texture2D(image, openfl_TextureCoordv) * u_time;

		}")
	public function new()
	{
		super();
	}
}
#end
