package funkin.backend.shaders;

import haxe.Exception;
import openfl.Assets;

/**
 * Class for custom shaders.
 *
 * To create one, create a `shaders` folder in your assets/mod folder, then add a file named `my-shader.frag` or/and `my-shader.vert`.
 *
 * Non-existent shaders will only load the default one, and throw a warning in the console.
 *
 * To access the shader's uniform variables, use `shader.variable`
 */
class CustomShader extends FunkinShader {
	public var path:String = "";

	/**
	 * Creates a new custom shader
	 * @param name Name of the frag and vert files.
	 * @param glslVersion GLSL version to use. Defaults to `100` in mobile, `120` in desktop.
	 */
	public function new(name:String, glslVersion:String = #if mobile "100" #else "120" #end) {
		var fragCode = Paths.fileExists('shaders/$name.frag', TEXT) ? Paths.getTextFromFile('shaders/$name.frag') : null;
		var vertCode = Paths.fileExists('shaders/$name.vert', TEXT) ? Paths.getTextFromFile('shaders/$name.vert') : null;

		if (fragCode == null && vertCode == null)
			trace('Shader "$fragCode" and "$vertCode" couldn\'t be found.');

		super(fragCode, vertCode, glslVersion);
	}
}