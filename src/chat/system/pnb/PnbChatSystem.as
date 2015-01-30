package chat.system.pnb
{
	import flash.utils.getTimer;

	import chat.ChatManager;
    import chat.event.ChatEvent;
    import chat.system.IChatSystem;
    import chat.system.BaseChatSystem;

	public class PnbChatSystem extends BaseChatSystem implements IChatSystem
	{
		private static const LOBBY_ROOM:String = 'lobby_room';
		private static const HERENOW_INTERVAL:int = 30;
		private static const PRESENCE_INTERVAL:int = 1;

		private static const ROOM_MESSAGE:String = 'room_message';
		private static const PRIVATE_MESSAGE:String = 'private_message';
		private static const BUDDY_MESSAGE:String = 'buddy_message';
		private static const SYS_MESSAGE:String = 'sys_message';
		private static const SYS_USERVARS:String = 'sys_uservars';
		private static const SYS_BUDDYVARS:String = 'sys_buddyvars';

		private var _pnb:Pubnub;
		private var _opm:OpManager;
		private var _config:Object;
		private var _ownroom:Room;
		private var _slotsroom:Room;
		private var _buddyroom:Room;
		private var _isConnected:Boolean;
		private var _stime:int;
		private var _pstime:int;
		private var _presenceList:Array;
		private var _pub_here_now_lock:Boolean;
		private var _bud_here_now_lock:Boolean;
		private var _slotsroom_once_herenow:Boolean;
		private var _slotsroom_op:Operation;
		private var _leaveroom_op:Operation;
		private var _leaveRoomList:Array;
		private var _leaveChannels:String;

		public function PnbChatSystem()
		{
			super();

			_leaveRoomList = [];
		}

		override protected function init():void
		{
			if (!_pnb)
			{
				_pnb =  new Pubnub(_chatManager.mainClass);

				addEvent();

				_config = {
					origin:'pubsub.pubnub.com',

					publish_key:'demo',
					sub_key:'demo',
					secret_key:'demo',

					uuid:_chatManager.userId
				};

				_pnb.init(_config);
			}

			if (!_presenceList)
			{
				_presenceList = [];
			}

			if (!_opm)
			{
				_opm = OpManager.singleton;
			}

			if (!_ownroom)
			{
				_ownroom = new Room(_chatManager.userId);
			}

			if (!_isConnected)
			{
				doLogin();
			}

		}

		override protected function addEvent():void
		{
			_pnb.addEvent();
		}

		override protected function dispose():void
		{
			_opm.dispose();
			_ownroom = null;
			_slotsroom = null;
			_buddyroom = null;
			_isConnected = false;
			_stime = 0;
			_presenceList = [];
			_leaveRoomList = [];
		}

		private function doLogin():void
		{
			var op:Operation = new Operation();
			_ownroom.opKey = _opm.addOperation(op);

			op.addTodo(
				function ():void
				{
					_pnb.js_request({
						channel : _ownroom.channel,
						op_key : _ownroom.opKey,
						reuest_type : 'subscribe'
					});
				},
				function (data:Object):void
				{
					if (!data.op_status)
					{
						_isConnected = false;
						_chatManager.showError('doLogin', data);

						dispatchEvent(new ChatEvent(ChatEvent.SYS_DISCONN));
						return;
					}

					switch(data.response_type)
					{
						case 'callback':
							onMessageCallBack(data.message);
							break;

						case 'connect':
							_isConnected = true;

							dispatchEvent(new ChatEvent(ChatEvent.SYS_LOGIN));
							break;

						case 'disconnect':
							_isConnected = false;

							dispatchEvent(new ChatEvent(ChatEvent.SYS_DISCONN, {auto:true}));
							break;

						case 'reconnect':
							_isConnected = true;

							dispatchEvent(new ChatEvent(ChatEvent.SYS_LOGIN, {auto:true}));
							break;
					}
				}
			);
		}

		public function process():void
		{
			if (_opm)
			{
				_opm.process();
			}

			doLeave();

			if (_isConnected)
			{
				if (int(getTimer() * 0.001) - _stime >= HERENOW_INTERVAL)
				{
					_stime = int(getTimer() * 0.001);

					//sendPublicMsg('test here_now ' + getTimer(), {name:'zhaodx', x:10, y:10});

					slotsroomHereNow();
					buddyroomHereNow();
				}

				if (int(getTimer() * 0.001) - _pstime >= PRESENCE_INTERVAL)
				{
					_pstime = int(getTimer() * 0.001);
					presence();
				}
			}
		}

		public function doConnect():void
		{
			init();
		}

		public function leaveRoom(roomId:String):void
		{
			if (_slotsroom)
			{
				var op:Operation = _opm.getOp(_slotsroom.opKey);

				if (op)
				{
					op.dispose();
				}

				_slotsroom.dispose();
				_slotsroom = null;

				_presenceList = [];
			}

			_leaveRoomList.push(_chatManager.channel_pre + roomId);
		}

		private function doLeave():void
		{
			var channels:String;

			if (_leaveRoomList.length)
			{
				channels = _leaveRoomList.join(',');
				_leaveRoomList = [];
			}

			if (channels)
			{
				_pnb.js_request({
					channel: channels,
					reuest_type : 'unsubscribe'
				});
			}
		}

		public function autoJoinRoom(group:String, roomId:String=null):void
		{
			return;

			if (roomId)
			{
				joinRoom(roomId);
			}else
			{
				joinRoom((_slotsroom) ? _slotsroom.name : null);
			}
		}

		public function joinRoom(roomId:String):void
		{
			if (_slotsroom)
			{
				_slotsroom.dispose();
				_slotsroom = null;
			}

			if (roomId)
			{
				_slotsroom = new Room(roomId);
				_slotsroom_once_herenow = false;

				doJoinRoom();
			}
		}

		private function doJoinRoom():void
		{
			var roomName:String = _slotsroom.name;
			var op:Operation = new Operation();
			_slotsroom.opKey = _opm.addOperation(op);

			op.addTodo(
				function ():void
				{
					_pnb.js_request({
						channel : _slotsroom.channel,
						op_key : _slotsroom.opKey,
						reuest_type : 'subscribe'
					});

					dispatchEvent(new ChatEvent(ChatEvent.SYS_ROOMJOIN, {
						status : true,
						isConn : true,
						roomData : {name:roomName}
					}));
				},
				function (data:Object):void
				{
					if (!data.op_status)
					{
						dispatchEvent(new ChatEvent(ChatEvent.SYS_ROOMJOIN, {
							status : false,
							isConn : false,
							roomData : {name:roomName}
						}));
						return;
					}

					switch(data.response_type)
					{
						case 'callback':
							onMessageCallBack(data.message);
							break;

						case 'connect':
							_slotsroom.isConn = true;
							break;
					}
				}
			);
		}

		private function slotsroomHereNow():void
		{
			if (!_pub_here_now_lock && _slotsroom && _slotsroom.isConn)
			{
				var userList:Array = [];
				var userId:String;
				var roomName:String = _slotsroom.name;
				var op:Operation = new Operation();
				_opm.addOperation(op);

				op.addTodo(
					function ():void
					{
						_pub_here_now_lock = true;

						_pnb.js_request({
							channel : _slotsroom.channel,
							op_key : op.name,
							reuest_type : 'here_now'
						});
					},
					function (data:Object):void
					{
						if (!data.op_status)
						{
							_pub_here_now_lock = false;
							return;
						}

						op.dispose();

						switch(data.response_type)
						{
							case 'callback':
								_pub_here_now_lock = false;

								if (_slotsroom && roomName == _slotsroom.name)
								{
									userList = data.message.uuids as Array;

									if (userList && userList.length)
									{
										if (!_slotsroom_once_herenow)
										{
											_slotsroom_once_herenow = true;

											for each(userId in userList)
											{
												_slotsroom.addUser(userId);
											}

											dispatchEvent(new ChatEvent(ChatEvent.SYS_ROOMJOIN, {
												status : true,
												isConn : false,
												roomData : {name:roomName},
												roomUsers : _slotsroom.userArray
											}));
										}else
										{
											mergeSlotsRoomUser(userList);
										}
									}
								}
								break;
						}
					}
				);
			}
		}

		private function mergeSlotsRoomUser(uuids:Array):void
		{
			var roomData:Object = {name:_slotsroom.name};
			var roomName:String = _slotsroom.name;
			var userObj:Object;
			var reportList:Array = [];

			if (uuids && uuids.length)
			{
				var userId:String;

				for each(userId in uuids)
				{
					userObj = _slotsroom.getUserObj(userId);

					if (!userObj)
					{
						userObj = _chatManager.getNewUserObj(userId);
						userObj['isOnline'] = true;
						reportList.push(userObj);
					}
				}

				for each(userObj in _slotsroom.userList)
				{
					if (uuids.indexOf(userObj.userId) == -1)
					{
						userObj['isOnline'] = false;
						reportList.push(userObj);
					}
				}

				_slotsroom.clearUsers();

				for each(userId in uuids)
				{
					_slotsroom.addUser(userId);
				}

				for each(userObj in reportList)
				{
					if (userObj['isOnline'])
					{
						_presenceList.push({
							type:ChatEvent.SYS_USER_ENTERROOM,
							data:{userData:userObj, roomData:{name:roomName}}
						});
					}else
					{
						_presenceList.push({
							type:ChatEvent.SYS_USER_EXITROOM,
							data:{userData:userObj, roomData:{name:roomName}}
						});
					}
				}
			}
		}

		private function buddyroomHereNow():void
		{
			if (!_bud_here_now_lock && _buddyroom && _buddyroom.isConn)
			{
				var op:Operation = new Operation();
				_opm.addOperation(op);

				op.addTodo(
					function ():void
					{
						_bud_here_now_lock = true;

						_pnb.js_request({
							channel : _buddyroom.channel,
							op_key : op.name,
							reuest_type : 'here_now'
						});
					},
					function (data:Object):void
					{
						if (!data.op_status)
						{
							_bud_here_now_lock = false;
							return;
						}

						op.dispose();

						switch(data.response_type)
						{
							case 'callback':
								_bud_here_now_lock = false;

								if (_buddyroom)
								{
									mergeBuddyRoomUser(data.message.uuids as Array);
								}
								break;
						}
					}
				);
			}
		}

		private function mergeBuddyRoomUser(uuids:Array):void
		{
			var userObj:Object;
			var buddyList:Object;
			var online:Boolean;

			if (uuids && uuids.length)
			{
				buddyList = _buddyroom.userList;

				for each(userObj in buddyList)
				{
					online = uuids.indexOf(userObj.userId) != -1;

					if (online && userObj['isOnline'])
					{
						continue;
					}

					if (!online && !userObj['isOnline'])
					{
						continue;
					}

					userObj['isOnline'] = online;

					_presenceList.push({
						type:ChatEvent.SYS_BUDDY_ONLINE_STATE_UPDATE,
						data:{buddyData:userObj}
					});
				}
			}
		}

		private function presence():void
		{
			var presenceObj:Object = _presenceList.shift();

			if (presenceObj)
			{
				if (presenceObj.data && presenceObj.data.roomData)
				{
					if (_slotsroom && presenceObj.data.roomData.name == _slotsroom.name)
					{
            			dispatchEvent(new ChatEvent(presenceObj.type, presenceObj.data));
					}
				}else
				{
            		dispatchEvent(new ChatEvent(presenceObj.type, presenceObj.data));
				}
			}
		}

		//public function joinBuddyRoom(userId:String):void
		//{

		//}

		public function sendPublicMsg(msg:String, params:Object=null):void
		{
			if (_slotsroom)
			{
				var msgObj:Object = {
					sender:_chatManager.userId,
					room:_slotsroom.name,
					type:ROOM_MESSAGE,
					message:msg,
					params:params
				};

				var op:Operation = new Operation();
				_opm.addOperation(op);

				op.addTodo(
					function ():void
					{
						_pnb.js_request({
							op_key : op.name,
							channel : _slotsroom.channel,
							message : msgObj,
							reuest_type : 'publish'
						});
					},
					function (data:Object):void
					{
						if (!data.op_status)
						{
							return;
						}

						op.dispose();

						switch(data.response_type)
						{
							case 'callback':
								_pnb.messageStore({
									timeStamp : data.message[2],
									data : msgObj
								});

								break;
						}
					}
				);
			}
		}

		public function sendPrivateMsg(msg:String, toId:String, params:Object=null):Boolean
		{
			if (_slotsroom)
			{
				if (!_slotsroom.getUserObj(toId))
				{
					return false;
				}

				var msgObj:Object = {
					sender:_chatManager.userId,
					room:_slotsroom.name,
					type:PRIVATE_MESSAGE,
					message:msg,
					params:params
				};

				var op:Operation = new Operation();
				_opm.addOperation(op);

				op.addTodo(
					function ():void
					{
						_pnb.js_request({
							op_key : op.name,
							channel : _chatManager.channel_pre + toId,
							message : msgObj,
							reuest_type : 'publish'
						});
					},
					function (data:Object):void
					{
						if (!data.op_status)
						{
							return;
						}

						op.dispose();

						switch(data.response_type)
						{
							case 'callback':
								_pnb.messageStore({
									timeStamp : data.message[2],
									data : msgObj
								});

								break;
						}
					}
				);

				return true;
			}

			return false;
		}

		public function sendBuddyMsg(msg:String, toId:String, params:Object=null):Boolean
		{
			var userObj:Object = _buddyroom.getUserObj(toId);

			if (!userObj || !userObj['isOnline'])
			{
				return false;
			}

			var msgObj:Object = {
				sender:_chatManager.userId,
				type:BUDDY_MESSAGE,
				message:msg,
				params:params
			};

			var op:Operation = new Operation();
			_opm.addOperation(op);

			op.addTodo(
				function ():void
				{
					_pnb.js_request({
						op_key : op.name,
						channel : _chatManager.channel_pre + toId,
						message : msgObj,
						reuest_type : 'publish'
					});
				},
				function (data:Object):void
				{
					if (!data.op_status)
					{
						return;
					}

					op.dispose();

					switch(data.response_type)
					{
						case 'callback':
							_pnb.messageStore({
								timeStamp : data.message[2],
								data : msgObj
							});

							break;
					}
				}
			);

			return true;
		}

		public function extRequest(extCmd:String, params:Object=null):void
		{
			if (extCmd && params && params.toId)
			{
				params['cmd'] = extCmd;

				var msgObj:Object = {
					sender:_chatManager.userId,
					type:SYS_MESSAGE,
					params:params
				};

				var op:Operation = new Operation();
				_opm.addOperation(op);

				op.addTodo(
					function ():void
					{
						_pnb.js_request({
							op_key : op.name,
							channel : _chatManager.channel_pre + params.toId,
							message : msgObj,
							reuest_type : 'publish'
						});
					},
					function (data:Object):void
					{
						if (!data.op_status)
						{
							return;
						}

						op.dispose();

						switch(data.response_type)
						{
							case 'callback':
								_pnb.messageStore({
									timeStamp : data.message[2],
									data : msgObj
								});

								break;
						}
					}
				);
			}
		}

		public function get currRoomObj():Object
		{
			if (_slotsroom)
			{
				return getRoomObjByName(_slotsroom.name);
			}

			return null;
		}

		public function get config():Object
		{
			return _config;
		}

		public function set configPath(filePath:String):void
		{

		}

		public function get isConnected():Boolean
		{
			return _isConnected;
		}

		public function roomListFromGroup(groupId:String):Array
		{
			return null;
		}

		public function initBuddyList(buddyList:Array=null):void
		{
			if (!_buddyroom)
			{
				_buddyroom = new Room(LOBBY_ROOM);
			}

			var userObj:Object;

			if (buddyList && buddyList.length)
			{
				for each(var id:String in buddyList)
				{
					userObj = _buddyroom.addUser(id);
					userObj['isOnline'] = false;
				}
			}

			doInitBuddy();
		}

		private function doInitBuddy():void
		{
			var op:Operation = new Operation();
			_buddyroom.opKey = _opm.addOperation(op);

			op.addTodo(
				function ():void
				{
					_pnb.js_request({
						op_key : _buddyroom.opKey,
						channel : _buddyroom.channel,
						reuest_type : 'subscribe'
					});

					dispatchEvent(new ChatEvent(ChatEvent.SYS_BUDDY_LIST_INIT, {
						status:true,
						buddyListData:_buddyroom.userArray
					}));
				},
				function (data:Object):void
				{
					if (!data.op_status)
					{
						dispatchEvent(new ChatEvent(ChatEvent.SYS_BUDDY_LIST_INIT, {
							status:false,
							buddyListData:_buddyroom.userArray
						}));
						return;
					}

					switch(data.response_type)
					{
						case 'connect':
							_buddyroom.isConn = true;
							break;
					}
				}
			);
		}

		public function addBuddy(userId:String):void
		{
			var buddyObj:Object = _buddyroom.addUser(userId);
			dispatchEvent(new ChatEvent(ChatEvent.SYS_BUDDY_ADD, {buddyData:buddyObj}));
		}

		public function removeBuddy(userId:String):void
		{
			var buddyObj:Object = _buddyroom.removeUser(userId);
			dispatchEvent(new ChatEvent(ChatEvent.SYS_BUDDY_REMOVE, {buddyData:buddyObj}));
		}

		public function setMyVars(userVars:Object):void
		{
			if (_slotsroom)
			{
				pushUserVars(userVars);
			}

			//if (_buddyroom)
			//{
			//	pushBuddyVars(userVars);
			//}
		}

		private function pushUserVars(userVars:Object):void
		{
			var msgObj:Object = {
				sender:_chatManager.userId,
				room:_slotsroom.name,
				type:SYS_USERVARS,
				params:userVars
			};

			var op:Operation = new Operation();
			_opm.addOperation(op);

			op.addTodo(
				function ():void
				{
					_pnb.js_request({
						op_key : op.name,
						channel : _slotsroom.channel,
						message : msgObj,
						reuest_type : 'publish'
					});
				},
				function (data:Object):void
				{
					if (!data.op_status)
					{
						return;
					}

					op.dispose();

					switch(data.response_type)
					{
						case 'callback':
							_pnb.messageStore({
								timeStamp : data.message[2],
								data : msgObj
							});

							break;
					}
				}
			);
		}

		private function pushBuddyVars(userVars:Object):void
		{
			var msgObj:Object = {
				sender:_chatManager.userId,
				type:SYS_BUDDYVARS,
				params:userVars
			};

			var userObj:Object;

			for each(userObj in _buddyroom.userList)
			{
				if (userObj['isOnline'])
				{
					var op:Operation = new Operation();
					_opm.addOperation(op);

					op.addTodo(
						function ():void
						{
							_pnb.js_request({
								op_key : op.name,
								channel : _chatManager.channel_pre + userObj.userId,
								message : msgObj,
								reuest_type : 'publish'
							});
						},
						function (data:Object):void
						{
							if (!data.op_status)
							{
								return;
							}

							op.dispose();

							switch(data.response_type)
							{
								case 'callback':
									_pnb.messageStore({
										timeStamp : data.message[2],
										data : msgObj
									});

									break;
							}
						}
					);
				}
			}
		}

		private function onMessageCallBack(data:Object):void
		{
			switch(data.type)
			{
				case ROOM_MESSAGE:
					onPublicMessage(data);
					break;
				case PRIVATE_MESSAGE:
					onPrivateMessage(data);
					break;
				case BUDDY_MESSAGE:
					onBuddyMessage(data);
					break;
				case SYS_USERVARS:
					onUserVars(data);
					break;
				case SYS_BUDDYVARS:
					onBuddyVars(data);
					break;
				case SYS_MESSAGE:
					onSysMessage(data);
					break;
			}
		}

		private function onPublicMessage(obj:Object):void
		{
			if (_slotsroom)
			{
				var msg:String = obj.message;
				var params:Object = obj.params;
            	var roomObj:Object = getRoomObjByName(obj.room);
            	var userObj:Object = _chatManager.getNewUserObj(obj.sender);

            	if (!userObj.isMe)
            	{
					if (_slotsroom && roomObj.name == _slotsroom.name)
					{
						userObj['isOnline'] = true;

            	    	dispatchEvent(new ChatEvent(ChatEvent.SYS_MESSAGE, {
							roomData:roomObj,
							senderData:userObj,
							msgData:msg,
							paramsData:params,
							type:ChatManager.PUBLIC_MESSAGE
						}));
					}
            	}
			}
		}

		private function onPrivateMessage(obj:Object):void
		{
			if (_slotsroom)
			{
				var msg:String = obj.message;
				var params:Object = obj.params;
            	var roomObj:Object = getRoomObjByName(obj.room);
            	var userObj:Object = _chatManager.getNewUserObj(obj.sender);

            	if (!userObj.isMe)
            	{
					if (_slotsroom && roomObj.name == _slotsroom.name)
					{
						userObj['isOnline'] = true;

            	    	dispatchEvent(new ChatEvent(ChatEvent.SYS_MESSAGE, {
							senderData:userObj,
							msgData:msg,
							paramsData:params,
							type:ChatManager.PRIVATE_MESSAGE
						}));
					}
            	}
			}
		}

		private function onBuddyMessage(obj:Object):void
		{
			if (_buddyroom)
			{
				var msg:String = obj.message;
				var params:Object = obj.params;
            	var userObj:Object = _chatManager.getNewUserObj(obj.sender);

            	if (!userObj.isMe)
            	{
					userObj['isOnline'] = true;

            	    dispatchEvent(new ChatEvent(ChatEvent.SYS_MESSAGE, {
						senderData:userObj,
						msgData:msg,
						paramsData:params,
						type:ChatManager.BUDDY_MESSAGE
					}));
            	}
			}
		}

		private function onUserVars(obj:Object):void
		{
			var params:Object = obj.params;
            var roomObj:Object = getRoomObjByName(obj.room);
            var userObj:Object = _chatManager.getNewUserObj(obj.sender);

            //if (!userObj.isMe)
            //{
			if (_slotsroom && roomObj.name == _slotsroom.name)
			{
				userObj['isOnline'] = true;
				userObj['variables'] = params;

				_slotsroom.updateUser(userObj);

            	dispatchEvent(new ChatEvent(ChatEvent.SYS_USERVARS_UPDATE, {
					roomData:roomObj,
					senderData:userObj
				}));
			}
            //}
		}

		private function onBuddyVars(obj:Object):void
		{
			if (_buddyroom)
			{
				var params:Object = obj.params;
            	var userObj:Object = _chatManager.getNewUserObj(obj.sender);

            	if (!userObj.isMe)
            	{
					userObj['isOnline'] = true;
					userObj['variables'] = params;

					_buddyroom.updateUser(userObj);

            	    dispatchEvent(new ChatEvent(ChatEvent.SYS_BUDDYVARS_UPDATE, {senderData:userObj}));
            	}
			}
		}

		private function onSysMessage(obj:Object):void
		{
			var params:Object = obj.params;
            var userObj:Object = _chatManager.getNewUserObj(obj.sender);

            if (!userObj.isMe)
            {
				userObj['isOnline'] = true;

				dispatchEvent(new ChatEvent(ChatEvent.SYS_SERVER_PUSH, {
					senderData:userObj,
					extData:params
				}));
            }
		}

		private function getRoomObjByName(name:String):Object
		{
			return {name:name};
		}
	}
}
