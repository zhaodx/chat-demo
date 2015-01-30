package chat
{
	import flash.utils.getTimer;

	import chat.debug.Debug;
	import chat.event.ChatEvent;
	import chat.system.IChatSystem;
	import chat.system.BaseChatSystem;
	import chat.system.sfs.SfsChatSystem;
	import chat.system.pnb.PnbChatSystem;

	public class ChatManager
	{
		public static const PUBLIC_MESSAGE:String = 'public_message';
		public static const PRIVATE_MESSAGE:String = 'private_message';
		public static const BUDDY_MESSAGE:String = 'buddy_message';

		public static const SFS_SYSTEM:String = 'sfs_system';
		public static const PNB_SYSTEM:String = 'pnb_system';

		private static var _instance:ChatManager;

		private var _debug:Boolean;
		private var _autoReConn:Boolean;
		private var _systemType:String;
		private var _systemTime:int;
		private var _updateTime:int;
		private var _userId:String;
		private var _password:String;
		private var _mainClass:String;
		private var _chatSystem:IChatSystem;
		private var _channel_pre:String;
		private var _log_url:String;

		public function ChatManager()
		{
		}

		public static function get singleton():ChatManager
		{
			if (!_instance)
			{
				_instance = new ChatManager();
			}

			return _instance;
		}

		public function init(config:Object):void
		{
			_userId = config.id;
			_debug = config.debug;
			_systemType = config.type;
			_password = config.password;
			_autoReConn = config.reconn;
			_mainClass = config.mainClass;
			_channel_pre = config.channel_pre;
			_log_url = config.log_url;

			if (_systemType == SFS_SYSTEM)
			{
				_chatSystem = new SfsChatSystem();
			}else
			{
				_chatSystem = new PnbChatSystem();
			}
		}

		public function process():void
		{
			_chatSystem.process();
		}

		public function doConnect(id:String=null, password:String=null):void
		{
			if (id)
			{
				_userId = id;
			}

			if (password)
			{
				_password = password;
			}

			//_userId = '100001063346705';
			//_password = '60552c29769d52e3';

			_chatSystem.doConnect();
		}

		public function get sysTime():int
		{
			return _systemTime + (int(getTimer() * 0.001) - _updateTime);
		}

		public function setSysTime(time:int):void
		{
			_systemTime = time;
			_updateTime = int(getTimer() * 0.001);
		}

		public function get systemType():String
		{
			return _systemType;
		}

		public function get debug():Boolean
		{
			return _debug;
		}

		public function get autoReConn():Boolean
		{
			return _autoReConn;
		}

		public function get userId():String
		{
			return _userId;
		}

		public function get password():String
		{
			return _password;
		}

		public function isMe(userId:String):Boolean
		{
			return _userId == userId;
		}

		public function joinRoom(roomId:String):void
		{
			_chatSystem.joinRoom(roomId);
		}

		public function leaveRoom(roomId:String):void
		{
			_chatSystem.leaveRoom(roomId);
		}

		public function autoJoinRoom(group:String='alice', roomId:String=null):void
		{
			_chatSystem.autoJoinRoom(group, roomId);
		}

		//public function joinBuddyRoom(userId:String):void
		//{
		//	_chatSystem.joinBuddyRoom(userId);
		//}

		public function sendPublicMsg(msg:String, params:Object=null):void
		{
			_chatSystem.sendPublicMsg(msg, params);
		}

		public function sendPrivateMsg(msg:String, toId:String, params:Object=null):Boolean
		{
			return _chatSystem.sendPrivateMsg(msg, toId, params);
		}

		public function sendBuddyMsg(msg:String, toId:String, params:Object=null):Boolean
		{
			return _chatSystem.sendBuddyMsg(msg, toId, params);
		}

		public function extRequest(extCmd:String, params:Object=null):void
		{
			_chatSystem.extRequest(extCmd, params);
		}

		public function initBuddyList(buddyList:Array=null):void
		{
			_chatSystem.initBuddyList(buddyList);
		}

		public function addBuddy(userId:String):void
		{
			_chatSystem.addBuddy(userId);
		}

		public function removeBuddy(userId:String):void
		{
			_chatSystem.removeBuddy(userId);
		}

		public function setMyVars(userVars:Object):void
		{
			_chatSystem.setMyVars(userVars);
		}

		public function get currRoom():Object
		{
			return _chatSystem.currRoomObj;
		}

		public function get config():Object
		{
			return _chatSystem.config;
		}

		public function get mainClass():String
		{
			return _mainClass;
		}

		public function set configPath(filePath:String):void
		{
			if (filePath)
			{
				_chatSystem.configPath = filePath;
			}
		}

		public function roomListFromGroup(groupId:String):Array
		{
			return _chatSystem.roomListFromGroup(groupId);
		}

		public function addEventListener(eventType:String, callback:Function):void
		{
			(_chatSystem as BaseChatSystem).addEventListener(eventType, callback);
		}

		public function removeEventListener(eventType:String, callback:Function):void
		{
			(_chatSystem as BaseChatSystem).removeEventListener(eventType, callback);
		}

		public function showMsg(type:String, obj:Object=null):void
		{
			if (debug)
			{
				Debug.consoleStr('[ CHAT ]' + type);

				if (obj)
				{
					Debug.consoleObj(obj);
				}
			}
		}

		public function showError(type:String, obj:Object=null):void
		{
			Debug.consoleStr('[ CHAT::ERROR ]' + type);

			if (obj)
			{
				Debug.consoleObj(obj);
			}
		}

		public function getNewUserObj(userId:String):Object
		{
			return {
				userId: userId,
				isMe: isMe(userId),
				isOnline: false,
				variables: null
			};
		}

		public function get channel_pre():String
		{
			return _channel_pre;
		}

		public function get log_url():String
		{
			return _log_url;
		}
	}
}
