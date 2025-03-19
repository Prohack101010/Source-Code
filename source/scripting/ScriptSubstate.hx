package scripting;

import openfl.utils.Assets as OpenFlAssets;
import flixel.util.FlxSave;

import Character;

import options.*;
import editors.*;

import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;

#if VIDEOS_ALLOWED
import vlc.MP4Handler as VideoHandler;
#end

#if LUA_ALLOWED
import substates.*;
#end

#if SScript
import tea.SScript;
#end

class ScriptSubstate extends MusicBeatSubstate
{
    public static var targetFileName:String; 
    
    #if HXVIRTUALPAD_ALLOWED
    public static var _hxvirtualpad:FlxVirtualPad;
    
    public static var dpadMode:StringMap<FlxDPadMode> = new StringMap<FlxDPadMode>();
	public static var actionMode:StringMap<FlxActionMode> = new StringMap<FlxActionMode>();
	#end

    public function new(scriptName:String) 
    {
        super();

        targetFileName = scriptName;
    }

	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();

    public static var instance:ScriptSubstate;

    #if LUA_ALLOWED public var luaArray:Array<FunkinLua> = []; #end
    
    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
    #end

	#if LUA_ALLOWED
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	#end

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<StateHScript> = [];
	public var instancesExclude:Array<String> = [];
	#end

	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	var keysPressed:Array<Int> = [];
	private var keysArray:Array<String>;

    override public function create()
    {
        ScriptingVars.currentScriptableState = 'ScriptSubstate'; //for HScript
        instance = this;
		
		#if HXVIRTUALPAD_ALLOWED
		// FlxDPadModes
		for (data in FlxDPadMode.createAll())
			dpadMode.set(data.getName(), data);

		for (data in FlxActionMode.createAll())
			actionMode.set(data.getName(), data);
		#end
		
		Paths.clearUnusedMemory();

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		add(luaDebugGroup);
		#end
		
		// #if LUA_ALLOWED startLuasNamed('custom_substates/' + targetFileName + '.lua'); #end
		#if HSCRIPT_ALLOWED startHScriptsNamed('custom_substates/' + targetFileName + '.hx'); #end

		callOnScripts('onCreatePost');

        super.create();
    }

    override public function update(elapsed:Float)
    {
		callOnScripts('onUpdate', [elapsed]);

		if (FlxG.sound.music != null && FlxG.sound.music.looped) FlxG.sound.music.onComplete = fixMusic.bind();

		callOnScripts('onUpdatePost', [elapsed]);

        super.update(elapsed);
    }

	var lastStepHit:Int = -1;

	override function stepHit()
	{
		super.stepHit();

		if(curStep >= lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		if(lastBeatHit >= curBeat) {
			return;
		}

		super.beatHit();

		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit');
	}

	var lastSectionHit:Int = -1;

    /*
	override function sectionHit()
	{
		if (lastSectionHit >= curSection)
		{
			return;
		}

		super.sectionHit();

		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}
	*/

	function fixMusic()
	{
		MusicBeatState.instance.resetMusicVars();
		
		lastStepHit = -1;
		lastBeatHit = -1;
		lastSectionHit = -1;
	}

    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    public function addTextToDebug(text:String, color:FlxColor) 
    {
        var newText:DebugLuaText = luaDebugGroup.recycle(DebugLuaText);
        newText.text = text;
        newText.color = color;
        newText.disableTime = 6;
        newText.alpha = 1;
        newText.setPosition(10, 8 - newText.height);

        luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
            spr.y += newText.height + 2;
        });
        luaDebugGroup.add(newText);

        Sys.println(text);
    }
    #end

    public function getLuaObject(tag:String, text:Bool=true):FlxSprite
        return variables.get(tag);

	public static var inCutscene:Bool;

    #if !ios
	public function startVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			return;
		}

		var video:VideoHandler = new VideoHandler();
			#if (hxCodec >= "3.0.0" && !ios)
			// Recent versions
			video.play(filepath);
			video.onEndReached.add(function()
			{
				video.dispose();
				inCutscene = false;
				return;
			}, true);
			#else
			// Older versions
			video.playVideo(filepath);
			video.finishCallback = function()
			{
				inCutscene = false;
				return;
			}
			#end
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}
	#end

    /*
	private function keyPressed(key:Int)
	{
		var ret:Dynamic = callOnScripts('onKeyPressPre', [key]);
		if(ret == FunkinLua.Function_Stop) return;

		if(!keysPressed.contains(key)) keysPressed.push(key);

		callOnScripts('onKeyPress', [key]);
	}

	private function keyReleased(key:Int)
	{
		var ret:Dynamic = callOnScripts('onKeyReleasePre', [key]);
		if(ret == FunkinLua.Function_Stop) return;

		callOnScripts('onKeyRelease', [key]);
	}

	private function keysCheck():Void
	{
		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		for (key in keysArray)
		{
			holdArray.push(controls.pressed(key));
			if(controls.controllerMode)
			{
				pressArray.push(controls.justPressed(key));
				releaseArray.push(controls.justReleased(key));
			}
		}
	}
	*/

	override public function close()
	{
		super.close();

		instance = null;

		#if LUA_ALLOWED
		for (lua in luaArray)
		{
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = null;
		FunkinLua.customFunctions.clear();
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if(script != null)
			{
				script.call('onDestroy');
				script.destroy();
			}

		hscriptArray = null;
		#end
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getScriptPath(luaFile);

		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getScriptPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray)
				if(script.scriptName == luaToLoad) return false;

			new FunkinLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end

	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String)
	{
	    var scriptToLoad:String = Paths.modFolders('scripts/' + scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getScriptPath(scriptFile);

		if(FileSystem.exists(scriptToLoad))
		{
			if (SScript.global.exists(scriptToLoad)) return false;

			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initHScript(file:String)
	{
		var newScript:StateHScript = new StateHScript(null, file);
		try
		{
			@:privateAccess
			if(newScript.parsingExceptions != null && newScript.parsingExceptions.length > 0)
			{
				@:privateAccess
				for (e in newScript.parsingExceptions)
					if(e != null)
						addTextToDebug('ERROR ON LOADING: ${newScript.parsingException.message}', FlxColor.RED);
				newScript.destroy();
				return;
			}
			hscriptArray.push(newScript);
			if(newScript.exists('onCreate'))
			{
				var callValue = newScript.call('onCreate');
				if(!callValue.succeeded)
				{
					for (e in callValue.exceptions)
						if (e != null)
							addTextToDebug('ERROR ($file: onCreate) - ${e.message.substr(0, e.message.indexOf('\n'))}', FlxColor.RED);
					newScript.destroy();
					hscriptArray.remove(newScript);
					trace('failed to initialize sscript interp!!! ($file)');
				}
				else trace('initialized sscript interp successfully: $file');
			}

		}
		catch(e)
		{
			addTextToDebug('ERROR ($file) - ' + e.message.substr(0, e.message.indexOf('\n')), FlxColor.RED);
			if(newScript != null)
			{
				newScript.destroy();
				hscriptArray.remove(newScript);
			}
		}
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [FunkinLua.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [FunkinLua.Function_Continue];

		var arr:Array<FunkinLua> = [];
		for (script in luaArray)
		{
			if(script.closed)
			{
				arr.push(script);
				continue;
			}

			if(exclusions.contains(script.scriptName))
				continue;

			var myValue:Dynamic = script.call(funcToCall, args);
			if((myValue == FunkinLua.Function_StopLua || myValue == FunkinLua.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
			{
				returnVal = myValue;
				break;
			}

			if(myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if(script.closed) arr.push(script);
		}

		if(arr.length > 0)
			for (script in arr)
				luaArray.remove(script);
		#end
		return returnVal;
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(FunkinLua.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;
		for(i in 0...len) {
			var script:StateHScript = hscriptArray[i];
			if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var myValue:Dynamic = null;
			try {
				var callValue = script.call(funcToCall, args);
				if(!callValue.succeeded)
				{
					var e = callValue.exceptions[0];
					if(e != null)
					{
						var len:Int = e.message.indexOf('\n') + 1;
						if(len <= 0) len = e.message.length;
						addTextToDebug('ERROR (${callValue.calledFunction}) - ' + e.message.substr(0, len), FlxColor.RED);
					}
				}
				else
				{
					myValue = callValue.returnValue;

					// compiler fuckup fix
					final stopHscript = myValue == FunkinLua.Function_StopHScript;
					final stopAll = myValue == FunkinLua.Function_StopAll;
					if((stopHscript || stopAll) && !excludeValues.contains(myValue) && !ignoreStops)
					{
						returnVal = myValue;
						break;
					}

					if(myValue != null && !excludeValues.contains(myValue))
						returnVal = myValue;
				}
			}
			catch (e:Dynamic) {}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if(exclusions.contains(script.origin))
				continue;

			if(!instancesExclude.contains(variable))
				instancesExclude.push(variable);
			script.set(variable, arg);
		}
		#end
	}

	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!ClientPrefs.data.shaders) return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if(!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.data.shaders) return false;

		#if (MODS_ALLOWED && !flash && sys)
		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'shaders/'))
		{
			var frag:String = folder + name + '.frag';
			var vert:String = folder + name + '.vert';
			var found:Bool = false;
			if(FileSystem.exists(frag))
			{
				frag = File.getContent(frag);
				found = true;
			}
			else frag = null;

			if(FileSystem.exists(vert))
			{
				vert = File.getContent(vert);
				found = true;
			}
			else vert = null;

			if(found)
			{
				runtimeShaders.set(name, [frag, vert]);
				//trace('Found shader $name!');
				return true;
			}
		}
			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			addTextToDebug('Missing shader $name .frag AND .vert files!', FlxColor.RED);
			#else
			FlxG.log.warn('Missing shader $name .frag AND .vert files!');
			#end
		#else
		FlxG.log.warn('This platform doesn\'t support Runtime Shaders!');
		#end
		return false;
	}

	public function resetScriptState(?doTransition:Bool = false)
	{
		FlxTransitionableState.skipNextTransIn = !doTransition;
		FlxTransitionableState.skipNextTransOut = !doTransition;
		MusicBeatState.switchState(new ScriptState(targetFileName));
	}
	
	#if HXVIRTUALPAD_ALLOWED
	public function addHxVirtualPad(DPad:FlxDPadMode, Action:FlxActionMode)
	{
		if (_hxvirtualpad != null)
			removeHxVirtualPad();

		_hxvirtualpad = new FlxVirtualPad(DPad, Action);
		add(_hxvirtualpad);

		controls.setVirtualPadUI(_hxvirtualpad, DPad, Action);
		trackedinputsUI = controls.trackedInputsUI;
		controls.trackedInputsUI = [];
		_hxvirtualpad.alpha = ClientPrefs.data.VirtualPadAlpha;
	}
	
	public function addHxVirtualPadCamera()
	{
		var camcontrol = new flixel.FlxCamera();
		camcontrol.bgColor.alpha = 0;
		FlxG.cameras.add(camcontrol, false);
		_hxvirtualpad.cameras = [camcontrol];
	}
	
	public function removeHxVirtualPad()
	{
		if (trackedinputsUI.length > 0)
			controls.removeVirtualControlsInput(trackedinputsUI);

		if (_hxvirtualpad != null)
			remove(_hxvirtualpad);
	}
	
	public static function checkVPadPress(buttonPostfix:String, type = 'justPressed') {
		var buttonName = "button" + buttonPostfix;
		var button = Reflect.getProperty(ScriptSubstate._hxvirtualpad, buttonName); //Access Spesific HxVirtualPad Button
		return Reflect.getProperty(button, type);
		return false;
	}
	#end
}