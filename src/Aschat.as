package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.StageScaleMode;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.geom.ColorTransform;
	import flash.ui.Keyboard;

	import ui.LoginPanel;
	import ui.ChatPanel;
	import chat.ChatManager;
	import chat.debug.FpsCount;
	import chat.event.ChatEvent;
	import data.ChatData;

	[SWF(width='1000', height='700')]

	public class Aschat extends Sprite
	{
		private var _loader:Loader;
		private var _loadInfo:LoaderInfo;
		private var _loginPanel:LoginPanel;
		private var _chatPanel:ChatPanel;
		private var _loading_icon:Sprite;
		private var _basContainer:Sprite;
		private var _winContainer:Sprite;
		private var _icnContainer:Sprite;

		public function Aschat()
		{
			Security.allowDomain('*');
			Security.allowInsecureDomain('*');

			if (stage)
			{
				init();
			}else
			{
				addEventListener(Event.ADDED_TO_STAGE, init);
			}
		}

		private function init(event:Event=null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);

			stage.frameRate = 30;
			stage.stageFocusRect = false;
			stage.showDefaultContextMenu = false;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.quality = StageQuality.HIGH;

			_loader = new Loader();
			var loaderContext:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain);
			_loader.load(new URLRequest('asset.swf'), loaderContext);
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComp);

			_basContainer = new Sprite();
			addChild(_basContainer);

			_winContainer = new Sprite();
			addChild(_winContainer);

			_icnContainer = new Sprite();
			addChild(_icnContainer);

			_icnContainer.addChild(FpsCount.getInstance());
			addEventListener(Event.ENTER_FRAME, process);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);

			//注册信息
			ChatManager.singleton.init({
				id:'sns-id',
				password:'user-session',
				mainClass:'Aschat',
				channel_pre:'as3_chat_demo_',
				log_url:'',
				debug:true,
				reconn:true,
				type:ChatManager.PNB_SYSTEM
				//type:ChatManager.SFS_SYSTEM
			});
			ChatManager.singleton.addEventListener(ChatEvent.SYS_LOGIN, onLogin);
			ChatManager.singleton.addEventListener(ChatEvent.SYS_DISCONN, onDisConn);
			ChatManager.singleton.addEventListener(ChatEvent.SYS_BUDDY_ONLINE_STATE_UPDATE, onBuddyOnlineState);
			ChatManager.singleton.addEventListener(ChatEvent.SYS_SERVER_PUSH, onServerPush);
			ChatManager.singleton.addEventListener(ChatEvent.SYS_AUTO_ROOMJOIN_ERROR, onAutoJoinRoomError);
		}

		private function keyDownHandler(event:KeyboardEvent):void
		{
			if (event.keyCode == Keyboard.ENTER)
			{
				if (_loginPanel)
				{
					_loginPanel.onEnterKey();
				}

				if (_chatPanel)
				{
					_chatPanel.onEnterKey();
				}
			}
		}

		private function onLogin(event:ChatEvent):void
		{
			hideLoginPanel();

			if (event.data && event.data.auto)
			{
				ChatManager.singleton.autoJoinRoom();
				hideLoading();
			}else
			{
				initBuddy();
				_chatPanel.showRoomList();
			}
		}

		private function initBuddy():void
		{
			ChatManager.singleton.addEventListener(ChatEvent.SYS_BUDDY_LIST_INIT, onBuddyInit);

			ChatManager.singleton.initBuddyList(['11', '22']);
		}

		private function onBuddyInit(event:ChatEvent):void
		{
			ChatManager.singleton.removeEventListener(ChatEvent.SYS_BUDDY_LIST_INIT, onBuddyInit);

			if (event.data && event.data.status)
			{
				if (event.data.buddyListData)
				{
					var buddyList:Array = event.data.buddyListData as Array;

					if (buddyList.length)
					{
						ChatData.singleton.loadBuddyData(buddyList);
					}
				}

				_chatPanel.infoTxtUpdate();

				hideLoading();
			}else
			{
				//initBuddy error
				initBuddy();
			}
		}

		private function onBuddyOnlineState(event:ChatEvent):void
		{
			ChatData.singleton.updateBuddyState(event.data.buddyData);

			_chatPanel.infoTxtUpdate();
		}

		private function onServerPush(event:ChatEvent):void
		{
			var pushData:String = event.data.pushData;
		}

		private function onAutoJoinRoomError(event:ChatEvent):void
		{

		}

		private function onDisConn(event:ChatEvent):void
		{
			if (event.data && event.data.auto)
			{
				disableToChat();
				showLoading();
			}else
			{
				hideLoading();
				showLoginPanel();
			}
		}

		private function onLoaderComp(event:Event):void
		{
			_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoaderComp);
			_loadInfo = event.currentTarget as LoaderInfo;

			createChatPanel();
		}

		public function getAssetClass(name:String):Class
		{
			if (name && _loadInfo)
			{
				return _loadInfo.applicationDomain.getDefinition(name) as Class;
			}

			return null;
		}

		public function showLoading():void
		{
			if (!_loading_icon)
			{
				var cls:Class = getAssetClass('loading_icon');
				_loading_icon = new cls() as Sprite;
			}

			_icnContainer.addChild(_loading_icon);

			_loading_icon.x = (stage.stageWidth - _loading_icon.width) >> 1;
			_loading_icon.y = (stage.stageHeight - _loading_icon.height) >> 1;

			_loading_icon.x += 50;

			disableToChat();
		}

		public function hideLoading():void
		{
			if (_loading_icon)
			{
				_icnContainer.removeChild(_loading_icon);
				_loading_icon = null;
			}

			ableToChat();
		}

		private function createChatPanel():void
		{
			if (!_chatPanel)
			{
				var cls:Class = getAssetClass('chat_panel');

				if (cls)
				{
					_chatPanel = new ChatPanel(cls, this);
					_chatPanel.x = (stage.stageWidth - _chatPanel.width) >> 1;
					_chatPanel.y = (stage.stageHeight - _chatPanel.height) >> 1;
				}

				_basContainer.addChild(_chatPanel);
				showLoginPanel();
			}
		}

		private function showLoginPanel():void
		{
			hideLoginPanel();

			var cls:Class = getAssetClass('login_panel');

			if (cls)
			{
				_loginPanel = new LoginPanel(cls, this);
				_loginPanel.x = (stage.stageWidth - _loginPanel.width) >> 1;
				_loginPanel.y = (stage.stageHeight - _loginPanel.height) >> 1;
			}

			_winContainer.addChild(_loginPanel);
			disableToChat();
		}

		private function hideLoginPanel():void
		{
			if (_loginPanel)
			{
				_winContainer.removeChild(_loginPanel);
				_loginPanel = null;
			}

			ableToChat();
		}

		private function disableToChat():void
		{
			if (_chatPanel)
			{
				_chatPanel.mouseEnabled = false;
				_chatPanel.mouseChildren = false;
				_chatPanel.transform.colorTransform = new ColorTransform(0.8,0.8,0.8,1,0,0,0);
			}
		}

		private function ableToChat():void
		{
			if (_chatPanel)
			{
				_chatPanel.mouseEnabled = true;
				_chatPanel.mouseChildren = true;
				_chatPanel.transform.colorTransform = new ColorTransform(1,1,1,1,0,0,0);
			}
		}

		private function process(event:Event):void
		{
			//enterFrame中注册驱动
			ChatManager.singleton.process();
		}
	}
}
