package mobile.options;

#if desktop
import Discord.DiscordClient;
#end
import openfl.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import openfl.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;
import options.BaseOptionsMenu;
import options.Option;
import openfl.Lib;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import mobile.backend.StorageUtil;
import mobile.options.MobileOptionsSubState;

using StringTools;

class MobileOptionsSubState extends BaseOptionsMenu
{
    #if android
	var storageTypes:Array<String> = ["EXTERNAL_DATA", "EXTERNAL", "EXTERNAL_EX", "EXTERNAL_NF", "EXTERNAL_OBB", "EXTERNAL_MEDIA", "EXTERNAL_ONLINE"];
	var externalPaths:Array<String> = StorageUtil.checkExternalPaths(true);
	final lastStorageType:String = ClientPrefs.data.storageType;
	#end
	final lastVirtualPadType:String = ClientPrefs.data.virtualpadType;
	
	var virtualpadTypes:Array<String> = ["VirtualPad", "TouchPad"];
	var virtualpadSkinList:Array<String> = CoolUtil.coolTextFile(Paths.getSharedPath('images/virtualpad/virtualpadSkinList'));
	var virtualpadSkinListModsFolder:Array<String> = CoolUtil.coolTextFile(Paths.modsTxt('virtualpad/virtualpadSkinList'));
	
	public function new()
	{
	    #if android
	    storageTypes = storageTypes.concat(externalPaths); //SD Card
	    #end
		title = 'Mobile Options';
		rpcTitle = 'Mobile Options Menu'; //hi, you can ask what is that, i will answer it's all what you needed lol.
		
		if (ClientPrefs.data.virtualpadType == 'TouchPad')
		    virtualpadSkinList = CoolUtil.coolTextFile(Paths.getPreloadPath('images/touchpad/touchpadSkinList.txt'));
		    
		#if MODS_ALLOWED
		final modsPath:String = Paths.modsTxt('virtualpad/virtualpadSkinList');
		final modsPathTouch:String = Paths.modsTxt('touchpad/touchpadSkinList');
		
		if(FileSystem.exists(modsPathTouch) && ClientPrefs.data.virtualpadType == 'TouchPad')
		    virtualpadSkinList = CoolUtil.coolTextFile(Paths.modsTxt('touchpad/touchpadSkinList'));
		else if(FileSystem.exists(modsPath) && ClientPrefs.data.virtualpadType != 'TouchPad')
		    virtualpadSkinList = CoolUtil.coolTextFile(Paths.modsTxt('virtualpad/virtualpadSkinList'));
		#end
		
	if (ClientPrefs.data.VirtualPadAlpha != 0) {
		var option:Option = new Option('VirtualPad Skin',
			"Choose VirtualPad Skin",
			'VirtualPadSkin',
			'string',
			virtualpadSkinList);

		addOption(option);
		option.onChange = resetVirtualPad;
	}
		
		var option:Option = new Option('VirtualPad Alpha:',
			'Changes VirtualPad Alpha -cool feature',
			'VirtualPadAlpha',
			'percent');
		option.scrollSpeed = 1;
		option.minValue = 0.001;
		option.maxValue = 1;
		option.changeValue = 0.05;
		option.decimals = 1;
		option.onChange = () ->
		{
			_virtualpad.alpha = curOption.getValue();
		};
		addOption(option);
		super();
		
	if (ClientPrefs.data.VirtualPadAlpha != 0) {
		var option:Option = new Option('Colored VirtualPad',
			'If unchecked, disables VirtualPad colors\n(can be used to make custom colored VirtualPad)',
			'coloredvpad',
			'bool');
		addOption(option);
		option.onChange = resetVirtualPad;
		
		var option:Option = new Option('VirtualPad Type',
			'Which VirtualPad should use??',
			'virtualpadType',
			'string',
			virtualpadTypes);
		addOption(option);
		option.onChange = resetVirtualPad; //remove buggy virtualpad/touchpad and add new one
		
		var option:Option = new Option('Extra Controls',
			"Allow Extra Controls",
			'extraKeys',
			'float');
		option.scrollSpeed = 1.6;
		option.minValue = 0;
		option.maxValue = 4;
		option.changeValue = 1;
		option.decimals = 1;
		addOption(option);
	}
		
	var option:Option = new Option('Extra Control Location:',
		"Choose Extra Control Location",
		'hitboxLocation',
		'string',
		['Bottom', 'Top', 'Middle']);
	addOption(option);
		  
	var option:Option = new Option('Hitbox Mode:',
		"Choose your Hitbox Style!  -mariomaster",
		'hitboxmode',
		'string',
		['Classic', 'New']);
	addOption(option);
		  
	var option:Option = new Option('Hitbox Design:',
		"Choose how your hitbox should look like.",
		'hitboxtype',
		'string',
		['Gradient', 'No Gradient' , 'No Gradient (Old)']);
	addOption(option);

	var option:Option = new Option('Hitbox Hint',
		'Hitbox Hint -I hate this',
		'hitboxhint',
		'bool');
	addOption(option);
		
	var option:Option = new Option('Hitbox Opacity', //mariomaster was here again
		'Changes hitbox opacity -omg',
		'hitboxalpha',
		'float');
	option.scrollSpeed = 1.6;
	option.minValue = 0.0;
	option.maxValue = 1;
	option.changeValue = 0.1;
	option.decimals = 1;
	addOption(option);
		
	#if mobile
	var option:Option = new Option('Wide Screen Mode',
		'If checked, The game will stetch to fill your whole screen. (WARNING: Can result in bad visuals & break some mods that resizes the game/cameras)',
		'wideScreen',
		'bool');
	option.onChange = () -> FlxG.scaleMode = new MobileScaleMode();
	addOption(option);
	#end
	
	#if FuckYou
	var option:Option = new Option('Keep My Files',
		"If checked, your files won't remove when you changed StorageType (only debug build)",
		'KeepMyFiles',
		'bool');
	addOption(option);
	#end
		
	#if android
	var option:Option = new Option('Storage Type',
		'Which folder Psych Engine should use?',
		'storageType',
		'string',
		storageTypes);
		addOption(option);
	#end

		super();
	}

	#if android
	function onStorageChange():Void
	{
		File.saveContent(lime.system.System.applicationStorageDirectory + 'storagetype.txt', ClientPrefs.data.storageType);
	
		var lastStoragePath:String = StorageType.fromStrForce(lastStorageType) + '/';
		
    	try
    	{
    	// *sigh* this shit deleted my Psych Extended v1.0.2 Source Code 😭
    	 #if Allow_RemoveFiles
    		if ((lastStorageType != 'EXTERNAL' || lastStorageType != 'EXTERNAL_EX' || lastStorageType != 'EXTERNAL_NF' || lastStorageType != 'EXTERNAL_ONLINE') #if FuckYou && !ClientPrefs.data.KeepMyFiles #end)
    		Sys.command('rm', ['-rf', lastStoragePath]);
    	#end
    	}
    	catch (e:haxe.Exception)
    		trace('Failed to remove last directory. (${e.message})');
	}
	#end

	override public function destroy() {
		super.destroy();
		
		if (ClientPrefs.data.virtualpadType != lastVirtualPadType) //Better Way -AloneDark
		{
        	ClientPrefs.data.VirtualPadSkin = 'original';
        	ClientPrefs.saveSettings();
        	ClientPrefs.data.VirtualPadSkin = 'original';
        	
        	//Restart Game
        	TitleState.initialized = false;
    		TitleState.closedState = false;
    		FlxG.sound.music.fadeOut(0.3);
    		if(FreeplayState.vocals != null)
    		{
    			FreeplayState.vocals.fadeOut(0.3);
    			FreeplayState.vocals = null;
    		}
    		FlxG.camera.fade(FlxColor.BLACK, 0.5, false, FlxG.resetGame, false);
        }
        	
		#if android
		if (ClientPrefs.data.storageType != lastStorageType) {
			onStorageChange();
			ClientPrefs.saveSettings();
			CoolUtil.showPopUp('Storage Type has been changed and you needed restart the game!!\nPress OK to close the game.', 'Notice!');
			lime.system.System.exit(0);
		}
		#end
	}
	
	function resetVirtualPad()
	{
	    removeVirtualPad();
	    addVirtualPad(FULL, A_B_C);
	}
}
