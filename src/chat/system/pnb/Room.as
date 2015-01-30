package chat.system.pnb
{
	import chat.ChatManager;

	public class Room
	{
		protected var _name:String;
		protected var _chatManager:ChatManager;
		protected var _userList:Object;
		protected var _userCount:int;
		protected var _isConn:Boolean;
		protected var _opKey:String;

		public function Room(name:String)
		{
			_name = name;
			_chatManager = ChatManager.singleton;

			_userList = {};
		}

		public function dispose():void
		{
			_name = null;
			_chatManager = null;
			_userList = null;
			_userCount = 0;
			_isConn = false;
			_opKey = null;
		}

		public function get name():String
		{
			return _name;
		}

		public function get channel():String
		{
			return _chatManager.channel_pre + _name;
		}

		public function get userCount():int
		{
			return _userCount;
		}

		public function get userList():Object
		{
			return _userList;
		}

		public function get userArray():Array
		{
			var userArr:Array = [];

			for each(var userObj:Object in _userList)
			{
				userArr.push(userObj);
			}

			return userArr;
		}

		public function clearUsers():void
		{
			_userList = {};
			_userCount = 0;
		}

		public function getUserObj(userId:String):Object
		{
			return _userList[userId];
		}

		public function addUser(userId:String):Object
		{
			var userObj:Object;

			if (!_userList[userId])
			{
				userObj = _chatManager.getNewUserObj(userId);
				userObj['isOnline'] = true;

				_userList[userId] = userObj;
				_userCount++;
			}

			return _userList[userId];
		}

		public function removeUser(userId:String):Object
		{
			var userObj:Object;

			if (_userList[userId])
			{
				userObj = _userList[userId];
				delete _userList[userId];
				_userCount--;
			}

			return userObj;
		}

		public function updateUser(user:Object):void
		{
			var userObj:Object = _userList[user.userId];

			if (userObj)
			{
				userObj['isOnline'] = user.isOnline;
				userObj['variables'] = user.variables;
			}
		}

		public function get isConn():Boolean
		{
			return _isConn;
		}

		public function set isConn(v:Boolean):void
		{
			_isConn = v;
		}

		public function set opKey(v:String):void
		{
			if (!_opKey)
			{
				_opKey = v;
			}
		}

		public function get opKey():String
		{
			return _opKey;
		}
	}
}
