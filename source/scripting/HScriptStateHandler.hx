package scripting;

#if SScript
import tea.SScript;
#end

class HScriptStateHandler extends MusicBeatState
{
	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
    #end
    
    public static var instance:HScriptStateHandler;
    
    #if HSCRIPT_ALLOWED
	public var hscriptArray:Array<StateHScript> = [];
	public var instancesExclude:Array<String> = [];
	#end
	
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	
	#if HXVIRTUALPAD_ALLOWED
    public static var _hxvirtualpad:FlxVirtualPad;
    
	public static var dpadMode:StringMap<FlxDPadMode> = new StringMap<FlxDPadMode>();
	public static var actionMode:StringMap<FlxActionMode> = new StringMap<FlxActionMode>();
	#end
	
	override function create()
	{
	    ScriptingVars.currentScriptableState = 'HScriptStateHandler'; //for HScript
	    instance = this;
	    
	    #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		add(luaDebugGroup);
		#end
	    
	    #if HXVIRTUALPAD_ALLOWED
		// FlxDPadModes
		for (data in FlxDPadMode.createAll())
			dpadMode.set(data.getName(), data);

		for (data in FlxActionMode.createAll())
			actionMode.set(data.getName(), data);
		#end

        super.create();
        
		callOnScripts('onCreatePost');
	}
	
	override function update(elapsed:Float)
	{
	    super.update(elapsed);
	    
		callOnScripts('onUpdatePost', [elapsed]);
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
	
	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
    public function addTextToDebug(text:String, color:FlxColor) 
    {
        var newText:DebugLuaText = luaDebugGroup.recycle(DebugLuaText);
        newText.text = text;
        newText.color = color;
        newText.disableTime = 6;
        newText.alpha = 1;
        newText.setPosition(10, 8 - newText.height);
        newText.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

        luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
            spr.y += newText.height + 2;
        });
        luaDebugGroup.add(newText);

        Sys.println(text);
    }
    #end
    
    override function destroy() {
        instance = null;
        
		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if(script != null)
			{
				script.call('onDestroy');
				script.destroy();
			}

		hscriptArray = null;
		#end
		
		super.destroy();
		
		#if HXVIRTUALPAD_ALLOWED
		if (_hxvirtualpad != null)
			_hxvirtualpad = FlxDestroyUtil.destroy(_hxvirtualpad);
		#end
	}
	
	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String)
	{
	    var scriptToLoad:String = Paths.modFolders('scripts/states/' + scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getScriptPath('states/' + scriptFile);

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

		var result:Dynamic = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
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
		setOnHScript(variable, arg, exclusions);
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
		var button = Reflect.getProperty(HScriptStateHandler._hxvirtualpad, buttonName); //Access Spesific HxVirtualPad Button
		return Reflect.getProperty(button, type);
		return false;
	}
	#end
}