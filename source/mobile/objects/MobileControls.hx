package mobile.objects;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSave;
import flixel.math.FlxPoint;

class Config {
	var save:FlxSave;
	var isExtend:Bool = false;

	public function new(saveName:String) {
		save = new FlxSave();
		save.bind(saveName);

		if (saveName == 'saved-extendControls') isExtend = true;
	}

	public function getcontrolmode():Int {
		if (save.data.buttonsmode != null) 
			return save.data.buttonsmode[0];
		return 0;
	}

	public function setcontrolmode(mode:Int = 0):Int {
		if (save.data.buttonsmode == null) save.data.buttonsmode = new Array();
		save.data.buttonsmode[0] = mode;
		save.flush();
		return save.data.buttonsmode[0];
	}

	public function savecustom(_pad:FlxVirtualPad) {
		if (save.data.buttons == null)
		{
			save.data.buttons = new Array();
			if (!isExtend){
    			for (buttons in _pad){
    				save.data.buttons.push(FlxPoint.get(buttons.x, buttons.y));
    			}
			}
			else{
			    save.data.buttons[0] = FlxPoint.get(_pad.buttonExtra2.x, _pad.buttonExtra2.y);
			    save.data.buttons[1] = FlxPoint.get(_pad.buttonExtra1.x, _pad.buttonExtra1.y);
			    save.data.buttons[2] = FlxPoint.get(_pad.buttonExtra3.x, _pad.buttonExtra3.y);
			    save.data.buttons[3] = FlxPoint.get(_pad.buttonExtra4.x, _pad.buttonExtra4.y);
			}
		}else{
			if (!isExtend){
			    var tempCount:Int = 0;
			    for (buttons in _pad){
				    save.data.buttons[tempCount] = FlxPoint.get(buttons.x, buttons.y);
				    tempCount++;
				}
			}
			else{
			    save.data.buttons[0] = FlxPoint.get(_pad.buttonExtra2.x, _pad.buttonExtra2.y);
			    save.data.buttons[1] = FlxPoint.get(_pad.buttonExtra1.x, _pad.buttonExtra1.y);
			    save.data.buttons[2] = FlxPoint.get(_pad.buttonExtra3.x, _pad.buttonExtra3.y);
			    save.data.buttons[3] = FlxPoint.get(_pad.buttonExtra4.x, _pad.buttonExtra4.y);
			}
		}
		save.flush();
	}

	public function loadcustom(_pad:FlxVirtualPad):FlxVirtualPad {
		if (save.data.buttons == null) 
			return _pad; 
		var tempCount:Int = 0;
		if (!isExtend){
    		for(buttons in _pad){
    			buttons.x = save.data.buttons[tempCount].x;
    			buttons.y = save.data.buttons[tempCount].y;
    			tempCount++;
    		}
		}
		else{
		    if (_pad.buttonExtra2 != null){
		        _pad.buttonExtra2.x = save.data.buttons[0].x;
			    _pad.buttonExtra2.y = save.data.buttons[0].y;
			}
			if (_pad.buttonExtra1 != null){
			    _pad.buttonExtra1.x = save.data.buttons[1].x;
			    _pad.buttonExtra1.y = save.data.buttons[1].y;
			}
			if (_pad.buttonExtra3 != null){
		        _pad.buttonExtra3.x = save.data.buttons[2].x;
			    _pad.buttonExtra3.y = save.data.buttons[2].y;
			}
			if (_pad.buttonExtra4 != null){
		        _pad.buttonExtra4.x = save.data.buttons[3].x;
			    _pad.buttonExtra4.y = save.data.buttons[3].y;
			}
		}
	    return _pad;
	}
}

class MobileControls extends FlxSpriteGroup {
	public var mode:ControlsGroup = HITBOX;

	public var hbox:FlxHitbox;
	public var newhbox:FlxNewHitbox;
	public var vpad:FlxVirtualPad;

	var config:Config;
	var extendConfig:Config;

	public function new() {
		super();

		config = new Config('saved-controls');
		extendConfig = new Config('saved-extendControls');

		mode = getModeFromNumber(config.getcontrolmode());

		switch (mode){
			case VIRTUALPAD_RIGHT:
				initControler(0);
			case VIRTUALPAD_LEFT:
				initControler(1);
			case VIRTUALPAD_CUSTOM:
				initControler(2);
			case DUO:
				initControler(3);
			case HITBOX:
		    if(ClientPrefs.data.hitboxmode != 'New')
				initControler(4);
		    else
		        initControler(5);
			case KEYBOARD:// nothing
		}
	}

	function initControler(vpadMode:Int) {
		switch (vpadMode){
			case 0:
				vpad = new FlxVirtualPad(RIGHT_FULL, controlExtend);	
				add(vpad);						
				vpad = extendConfig.loadcustom(vpad);
			case 1:
				vpad = new FlxVirtualPad(FULL, controlExtend);
				add(vpad);			
				vpad = extendConfig.loadcustom(vpad);
			case 2:
				vpad = new FlxVirtualPad(FULL, controlExtend);
				vpad = config.loadcustom(vpad);
				add(vpad);	
				vpad = extendConfig.loadcustom(vpad);
			case 3:
				vpad = new FlxVirtualPad(DUO, controlExtend);
				add(vpad);		
				vpad = extendConfig.loadcustom(vpad);
			case 4:
				hbox = new FlxHitbox(0.75, ClientPrefs.data.antialiasing);
				add(hbox);
			case 5:
			  newhbox = new FlxNewHitbox();
			  add(newhbox);
			default:
				newhbox = new FlxNewHitbox();
			    add(newhbox);
		}
	}

	public static function getModeFromNumber(modeNum:Int):ControlsGroup {
		return switch (modeNum){
			case 0: 
				VIRTUALPAD_RIGHT;
			case 1: 
				VIRTUALPAD_LEFT;
			case 2: 
				VIRTUALPAD_CUSTOM;
			case 3: 
				DUO;
			case 4:	
				HITBOX;
			case 5: 
				KEYBOARD;
			default: 
				HITBOX;
		}
	}
}

enum ControlsGroup {
	VIRTUALPAD_RIGHT;
	VIRTUALPAD_LEFT;
	VIRTUALPAD_CUSTOM;
	DUO;
	HITBOX;
	KEYBOARD;
}
