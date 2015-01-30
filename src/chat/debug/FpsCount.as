package chat.debug
{
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	import flash.utils.Dictionary;

	public class FpsCount extends Sprite
	{
		private var ticks:int;
		private var FPS:TextField;
		private var _projectDic:Dictionary;
		private var t:Timer = new Timer(1000);
		private var format:TextFormat = new TextFormat();

		private static var _instance:FpsCount;

		public static function getInstance():FpsCount
		{
			if (!_instance)
			{
				_instance = new FpsCount();
			}

			return _instance;
		}

		public function FpsCount()
		{
			if (_instance)
			{
				throw(new Error('FpsCount is singleton'));
			}else
			{
				this.x = 0;
				this.y = 0;

				init();
			}
		}

		private function init():void
		{
			this.name = 'fpsCount';
			this.mouseChildren = false;

			_projectDic = new Dictionary();
			createText();
			t.addEventListener(TimerEvent.TIMER, update);
			addEventListener(Event.ENTER_FRAME, render);
			t.start();
		}

		private function createText():void
		{
			format.font = 'Verdana';
			format.size = 11;

			FPS = new TextField();
			FPS.defaultTextFormat = format;
			FPS.autoSize = TextFieldAutoSize.LEFT;
			FPS.textColor = 0xFFFFFF;
			FPS.background = true;
			FPS.backgroundColor = 0x666666;
			FPS.antiAliasType = 'advanced';
			FPS.selectable = false;
			FPS.text = 'FPS: ';

			addChild(FPS);
		}

		private function update(event:TimerEvent):void
		{
			FPS.text = 'FPS: ' + String(ticks);
			if(this.stage){
			   FPS.appendText('/' + String(this.stage.frameRate) + '  \nMemory: ' + String(((System.totalMemory >> 10) >> 10) >> 0) + 'M');
			   for(var key:String in _projectDic)
			   {
				   FPS.appendText(' \n' + key + ': ' + _projectDic[key]);
			   }
			}
			ticks = 0;
		}

		private function render(event:Event):void
		{
			ticks ++;
		}

		public function addProject(key:String, value:String):void
		{
			_projectDic[key] = value;
		}
	}
}
