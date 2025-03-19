package mobile.backend;

import haxe.ds.StringMap;

class Data
{
	public static var dpadMode:StringMap<FlxDPadMode> = new StringMap<FlxDPadMode>();
	public static var actionMode:StringMap<FlxActionMode> = new StringMap<FlxActionMode>();

	public static function setup()
	{
		for (data in FlxDPadMode.createAll())
			dpadMode.set(data.getName(), data);

		for (data in FlxActionMode.createAll())
			actionMode.set(data.getName(), data);
	}
}

enum FlxDPadMode {
	UP_DOWN;
	LEFT_RIGHT;
	UP_LEFT_RIGHT;
	FULL;
	ChartingStateC;
	OptionsC;
	RIGHT_FULL;
	DUO;
	PAUSE;
	NONE;
}

enum FlxActionMode {
    E;
	A;
	B;
	A_B;
	A_B_C;
	A_B_E;
	A_B_E_C_M;
	A_B_X_Y;
	B_X_Y;
	A_B_C_X_Y_Z;
	FULL;
	OptionsC;
	ChartingStateC;
	controlExtend;
	B_E;
	NONE;
}