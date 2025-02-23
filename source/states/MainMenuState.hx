package states;

import mikolka.compatibility.ModsHelper;
import mikolka.vslice.freeplay.FreeplayState;
import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import haxe.Json;
import openfl.Assets;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '2.0'; // This is also used for Discord RPC
	public static var pSliceVersion:String = '2.0'; 
	public static var funkinVersion:String = '0.5.1'; // Version of funkin' we are emulationg
	public static var curSelected:Int = 0;

	private static var splitter:FlxSprite;

	private static var char:FlxSprite;

	var characters:FlxTypedGroup<FlxSprite>;

	var menuItems:FlxTypedGroup<FlxSprite>;

/*	var jsonString:String = Paths.getTextFromFile("images/charactersData.json");
	var JSON:Dynamic = tjson.TJSON.parse(jsonString);

	var characterImage = JSON.asset;
	var characterAnim = JSON.idleAnimation;
	var characterPlay = JSON.play; */


	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		'credits',
		'options'
	];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	public function new(isDisplayingRank:Bool = false) {

		//TODO
		super();
	}
	override function create()
	{


/*		var JSON:Dynamic = tjson.TJSON.parse(jsonString);

// Now you can access the properties of JSON
var characterImage = JSON.asset;
var characterAnim = JSON.idleAnimation;
var characterPlay = JSON.play; */
		

		FlxG.camera.zoom = 1;

		Paths.clearUnusedMemory();
		ModsHelper.clearStoredWithoutStickers();
		
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end


		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBGBlue'));
		bg.antialiasing = false;
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.375));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = false;
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.375));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		splitter = new FlxSprite(0, 0).loadGraphic(Paths.image('splitter'));
		splitter.scrollFactor.set(0, 0); //yScroll + 0.05
		splitter.screenCenter();
		add(splitter);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		char = new FlxSprite(680, 0);
		char.frames = Paths.getSparrowAtlas('menuCharacter');
		char.animation.addByPrefix('idle', 'idle', 24);
		char.animation.addByPrefix('hey!', 'hey', 24, false);
		char.animation.play('idle');
		char.scrollFactor.set(0, yScroll + 0.1);
		char.antialiasing = false;
		add(char);
		char.setGraphicSize(Std.int(char.width * 0.80));
		char.screenCenter(Y);
		char.y = char.y + 50;
		char.updateHitbox();


		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80 + 50;
			var menuItem:FlxSprite = new FlxSprite(100, (i * 140) + offset);
			menuItem.antialiasing = false;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if (optionShit.length < 6)
				scr = 0;
			menuItem.scrollFactor.set(0, yScroll + 0.125);
			menuItem.setGraphicSize(Std.int(menuItem.width * 0.90));
			menuItem.updateHitbox();
			//menuItem.screenCenter(X);
		}

		var psychVer:FlxText = new FlxText(0, FlxG.height - 18, FlxG.width, "Obscure Engine " + psychEngineVersion, 12);
		var fnfVer:FlxText = new FlxText(0, FlxG.height - 18, FlxG.width, 'Menu was replicated to look like PH8NTOM\'s April Fools Scratch Edition', 8);

		psychVer.setFormat(Paths.font("handwriting.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		fnfVer.setFormat(Paths.font("handwriting.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		
		psychVer.scrollFactor.set();
		fnfVer.scrollFactor.set();

		fnfVer.alpha = 0.5;
		psychVer.alpha = 0.5;
		add(psychVer);
		//add(fnfVer);
		//var fnfVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' ", 12);
	
		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		// Unlocks "Freaky on a Friday Night" achievement if it's a Friday and between 18:00 PM and 23:59 PM
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
			Achievements.unlock('friday_night_play');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end

		super.create();

		FlxG.camera.follow(camFollow, null, 0.06);
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			//if (FreeplayState.vocals != null)
				//FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
				changeItem(-1);

			if (controls.UI_DOWN_P)
				changeItem(1);

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
				{
					char.animation.play('hey!');
					FlxG.sound.play(Paths.sound('confirmMenu'));
				
					// Start zoom-in transition
					FlxTween.tween(FlxG.camera, {zoom: 1.5}, 0.5, {
						ease: FlxEase.backInOut,
						onComplete: Reflect.makeVarArgs(function(_) // Adjust callback to match expected type
						{
							FlxTransitionableState.skipNextTransIn = false;
							FlxTransitionableState.skipNextTransOut = false;
				
							// Proceed with menu item actions
							switch (optionShit[curSelected])
							{
								case 'story_mode':
									MusicBeatState.switchState(new StoryMenuState());
								case 'freeplay':
									persistentDraw = true;
									persistentUpdate = false;
									FlxTransitionableState.skipNextTransIn = true;
									FlxTransitionableState.skipNextTransOut = true;
									openSubState(new FreeplayState());
									char.animation.play('idle');
									FlxG.camera.zoom = 1;
								case 'options':
									MusicBeatState.switchState(new OptionsState());
									OptionsState.onPlayState = false;
									if (PlayState.SONG != null)
									{
										PlayState.SONG.arrowSkin = null;
										PlayState.SONG.splashSkin = null;
										PlayState.stageUI = 'normal';
									}
								case 'credits':
									MusicBeatState.switchState(new CreditsState());
							}
						})
					});
				}
				
			#if desktop
			if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				FlxTransitionableState.skipNextTransIn = false;
				FlxTransitionableState.skipNextTransOut = false;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		menuItems.members[curSelected].animation.play('idle');
		menuItems.members[curSelected].updateHitbox();
		//menuItems.members[curSelected].screenCenter(X);

		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.members[curSelected].animation.play('selected');
		menuItems.members[curSelected].centerOffsets();
		//menuItems.members[curSelected].screenCenter(X);

		camFollow.setPosition(menuItems.members[curSelected].getGraphicMidpoint().x,
			menuItems.members[curSelected].getGraphicMidpoint().y - (menuItems.length > 4 ? menuItems.length * 8 : 0));
	}
}
