package ui
{
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.events.FocusEvent;

	import chat.ChatManager;
	import data.ChatData;

	public class LoginPanel extends Sprite
	{
		private var _asset:Sprite;
		private var _loginBtn:MovieClip;
		private var _name_input_txt:TextField;
		private var _ac:Aschat;

		public function LoginPanel(cls:Class, ac:Aschat)
		{
			if (cls)
			{
				_asset = new cls() as Sprite;
			}

			if (_asset)
			{
				addChild(_asset);

				init();
			}

			_ac = ac;
		}

		private function init():void
		{
			_name_input_txt = _asset.getChildByName('name_input_txt') as TextField;
			_name_input_txt.addEventListener(Event.ADDED_TO_STAGE, setInputTf);
			_name_input_txt.addEventListener(FocusEvent.FOCUS_IN, focusInHandler);
			_name_input_txt.addEventListener(FocusEvent.FOCUS_OUT, focusOutHandler);

			_loginBtn = _asset.getChildByName('loginBtn') as MovieClip;
			_loginBtn.buttonMode = true;
			_loginBtn.mouseChildren = false;
			_loginBtn.gotoAndStop(3);
			_loginBtn.addEventListener(MouseEvent.CLICK, loginBtnClick);
			_loginBtn.addEventListener(MouseEvent.MOUSE_OVER, btnHandler);
			_loginBtn.addEventListener(MouseEvent.MOUSE_OUT, btnHandler);

		}

		private function setInputTf(event:Event):void
		{
			var tf:TextField = event.target as TextField;

			if (tf.stage)
			{
				tf.stage.focus = tf;
				tf.text = '';
				tf.restrict = 'A-Za-z0-9\u4e00-\u9fa5';
				//tf.setSelection(0, 0);
				//tf.type = TextFieldType.INPUT;

				tf.addEventListener(Event.CHANGE, textInput);
			}
		}

		private function textInput(event:Event):void
		{
			var tf:TextField = event.target as TextField;

			if (tf)
			{

				if (nameTxt.length)
				{
					_loginBtn.gotoAndStop(1);
				}else
				{
					_loginBtn.gotoAndStop(3);
				}
			}
		}

		private function btnHandler(event:MouseEvent):void
		{
			var btn:MovieClip = event.target as MovieClip;

			if (btn)
			{
				if (btn.currentFrame > 2) return;

				if(event.type == MouseEvent.MOUSE_OVER)
				{
					btn.gotoAndStop(2);
				}else
				{
					btn.gotoAndStop(1);
				}
			}
		}

		private function loginBtnClick(event:MouseEvent):void
		{
			var btn:MovieClip = event.target as MovieClip;

			login(btn);
		}

		private function login(btn:MovieClip):void
		{
			if (btn)
			{
				if (btn.currentFrame > 2) return;

				if (nameTxt.toUpperCase() == 'ALL')
				{
					return;
				}

				ChatManager.singleton.doConnect(nameTxt);

				btn.gotoAndStop(3);
				_name_input_txt.mouseEnabled = false;
				_ac.showLoading();

				mouseEnabled = false;
				_name_input_txt.stage.focus = null;
			}
		}

		public function onEnterKey():void
		{
			login(_loginBtn);
		}

		private function focusInHandler(event:FocusEvent):void
		{
			ChatData.singleton.enableIME();
		}

		private function focusOutHandler(event:FocusEvent):void
		{
			ChatData.singleton.disableIME();
		}

		private function get nameTxt():String
		{
			return ChatData.singleton.trim(_name_input_txt.text);
		}
	}
}
