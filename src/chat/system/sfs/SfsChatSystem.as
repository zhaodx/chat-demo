package chat.system.sfs
{
	import com.smartfoxserver.v2.SmartFox;
	import com.smartfoxserver.v2.core.SFSEvent;
	import com.smartfoxserver.v2.core.SFSBuddyEvent;
	import com.smartfoxserver.v2.entities.*;
	import com.smartfoxserver.v2.entities.data.*;
	import com.smartfoxserver.v2.requests.*;
	import com.smartfoxserver.v2.requests.buddylist.*;
	import com.smartfoxserver.v2.util.*;

	import chat.ChatManager;
	import chat.event.ChatEvent;
	import chat.system.IChatSystem;
	import chat.system.BaseChatSystem;

	public class SfsChatSystem extends BaseChatSystem implements IChatSystem
	{
		private var _sfs:SmartFox;
		private var _currRoom:Room;
		private var _configPath:String;
		private var _isLogin:Boolean;
		private var _retryCount:int;
		private var _reConnTime:int;
		private var _isReConn:Boolean;
		private var _pingTime:int;

		private static const PING_INTERVAL:int = 100;
		private static const RECONN_TIMES:int = 5;
		private static const MAX_RECONN_TIMES:int = RECONN_TIMES * 3;

		public function SfsChatSystem()
		{
			super();

			_configPath = 'sfs-config.xml';
		}

		override protected function init():void
		{
			if (!_sfs)
			{
				_sfs = new SmartFox(_chatManager.debug);

				addEvent();
			}else
			{
				dispose();
				init();
			}
		}

		override protected function addEvent():void
		{
			_sfs.addEventListener(SFSEvent.CONFIG_LOAD_SUCCESS, onConfigLoadSuccess);
			_sfs.addEventListener(SFSEvent.CONFIG_LOAD_FAILURE, onConfigLoadFailure);
			_sfs.addEventListener(SFSEvent.CONNECTION, onConnection);
			_sfs.addEventListener(SFSEvent.CONNECTION_LOST, onConnectionLost);
			_sfs.addEventListener(SFSEvent.CONNECTION_ATTEMPT_HTTP, onAttemptHttp);
			_sfs.addEventListener(SFSEvent.CONNECTION_RESUME, onConnectionResume);
			_sfs.addEventListener(SFSEvent.CONNECTION_RETRY, onConnectionRetry);
			_sfs.addEventListener(SFSEvent.SOCKET_ERROR, onSocketError);
			_sfs.addEventListener(SFSEvent.LOGIN_ERROR, onLoginError);
			_sfs.addEventListener(SFSEvent.LOGIN, onLogin);
			_sfs.addEventListener(SFSEvent.EXTENSION_RESPONSE, onExtensionResponse);
			_sfs.addEventListener(SFSEvent.ROOM_JOIN_ERROR, onRoomJoinError);
			_sfs.addEventListener(SFSBuddyEvent.BUDDY_LIST_INIT, onBuddyListInitialized);
			_sfs.addEventListener(SFSBuddyEvent.BUDDY_ERROR, onBuddyError);
			_sfs.addEventListener(SFSBuddyEvent.BUDDY_ADD, onBuddyAdded);
			_sfs.addEventListener(SFSBuddyEvent.BUDDY_REMOVE, onBuddyRemoved);
			_sfs.addEventListener(SFSBuddyEvent.BUDDY_ONLINE_STATE_UPDATE, onBuddyOnlineStateUpdated);
			//_sfs.addEventListener(SFSEvent.ROOM_JOIN, onRoomJoin);
			//_sfs.addEventListener(SFSEvent.PUBLIC_MESSAGE, onPublicMessage);
			//_sfs.addEventListener(SFSEvent.PRIVATE_MESSAGE, onPrivateMessage);
			//_sfs.addEventListener(SFSEvent.USER_ENTER_ROOM, onUserEnterRoom);
			//_sfs.addEventListener(SFSEvent.USER_EXIT_ROOM, onUserExitRoom);
			//_sfs.addEventListener(SFSEvent.USER_COUNT_CHANGE, onUserCountChange);
		}

		override protected function removeEvent():void
		{
			if (_sfs)
			{
				_sfs.removeEventListener(SFSEvent.CONFIG_LOAD_SUCCESS, onConfigLoadSuccess);
				_sfs.removeEventListener(SFSEvent.CONFIG_LOAD_FAILURE, onConfigLoadFailure);
				_sfs.removeEventListener(SFSEvent.CONNECTION, onConnection);
				_sfs.removeEventListener(SFSEvent.CONNECTION_LOST, onConnectionLost);
				_sfs.removeEventListener(SFSEvent.CONNECTION_ATTEMPT_HTTP, onAttemptHttp);
				_sfs.removeEventListener(SFSEvent.CONNECTION_RESUME, onConnectionResume);
				_sfs.removeEventListener(SFSEvent.CONNECTION_RETRY, onConnectionRetry);
				_sfs.removeEventListener(SFSEvent.SOCKET_ERROR, onSocketError);
				_sfs.removeEventListener(SFSEvent.LOGIN_ERROR, onLoginError);
				_sfs.removeEventListener(SFSEvent.LOGIN, onLogin);
				_sfs.removeEventListener(SFSEvent.EXTENSION_RESPONSE, onExtensionResponse);
				_sfs.removeEventListener(SFSEvent.ROOM_JOIN_ERROR, onRoomJoinError);
				_sfs.removeEventListener(SFSBuddyEvent.BUDDY_LIST_INIT, onBuddyListInitialized);
				_sfs.removeEventListener(SFSBuddyEvent.BUDDY_ERROR, onBuddyError);
				_sfs.removeEventListener(SFSBuddyEvent.BUDDY_ADD, onBuddyAdded);
				_sfs.removeEventListener(SFSBuddyEvent.BUDDY_REMOVE, onBuddyRemoved);
				_sfs.removeEventListener(SFSBuddyEvent.BUDDY_ONLINE_STATE_UPDATE, onBuddyOnlineStateUpdated);
				//_sfs.removeEventListener(SFSEvent.ROOM_JOIN, onRoomJoin);
				//_sfs.removeEventListener(SFSEvent.PUBLIC_MESSAGE, onPublicMessage);
				//_sfs.removeEventListener(SFSEvent.PRIVATE_MESSAGE, onPrivateMessage);
				//_sfs.removeEventListener(SFSEvent.USER_ENTER_ROOM, onUserEnterRoom);
				//_sfs.removeEventListener(SFSEvent.USER_EXIT_ROOM, onUserExitRoom);
				//_sfs.removeEventListener(SFSEvent.USER_COUNT_CHANGE, onUserCountChange);
			}
		}

		override protected function dispose():void
		{
			removeEvent();

			_sfs = null;
		}

		public function process():void
		{
			if (_isReConn)
			{
				reConnect();
			}else
			{
				loadServerTime();
			}
		}

		public function doConnect():void
		{
			init();
			doLoadConfig();
		}

		private function doLoadConfig():void
		{
			if (!hasConfig())
			{
				sfs_loadConfig(_configPath, false);
			}else
			{
				connectServer();
			}
		}

		private function connectServer():void
		{
			if(!isConnected)
			{
				sfs_connect();
			}else
			{
				doLogin();
			}
		}

		private function doLogin():void
		{
			if (!_isLogin)
			{
				sfs_login(_chatManager.userId, _chatManager.password);
			}
		}

		private function doJoinRoom():void
		{
			if (currRoomObj)
			{
				//joinRoom(currRoomObj.name);
				autoJoinRoom('alice', currRoomObj.name);
			}
		}

		private function reConnect():void
		{
			var times:int = _retryCount % RECONN_TIMES;
			var interval:int = 2 << times;

			if (!_reConnTime)
			{
				_reConnTime = _chatManager.sysTime;
			}

			if (_chatManager.sysTime - _reConnTime >= interval)
			{
				_reConnTime = 0;
				_retryCount++;
				_isReConn = false;

				if (_retryCount >= MAX_RECONN_TIMES)
				{
					_retryCount = 0;
					dispatchEvent(new ChatEvent(ChatEvent.SYS_DISCONN));
				}else
				{
					doConnect();
				}
			}
		}

		private function sfs_loadConfig(filePath:String='sfs-config.xml', connectOnSuccess:Boolean=true):void
		{
			_sfs && _sfs.loadConfig(filePath, connectOnSuccess);
		}

		private function sfs_connect(host:String=null, port:int=-1):void
		{
			_sfs && _sfs.connect(host, port);
		}

		private function sfs_login(username:String, password:String, zoneName:String=null, params:ISFSObject = null):void
		{
			var request:LoginRequest = new LoginRequest(username, password);

			_sfs && _sfs.send(request);
		}

		public function leaveRoom(roomId:String):void
		{

		}

		public function joinRoom(roomId:String):void
		{
			var roomIdToLeave:Number;

			sfs_joinRoom(roomId, roomIdToLeave);
		}

		private function sfs_joinRoom(id:String, roomIdToLeave:Number, pass:String=null, asSpect:Boolean = false):void
		{
			var request:JoinRoomRequest = new JoinRoomRequest(id, pass, roomIdToLeave, asSpect);

			_sfs && _sfs.send(request);
		}

		public function autoJoinRoom(group:String, roomId:String=null):void
		{
			var params:Object = {sn:group, rn:roomId};

			extRequest('sr', params);
		}

		//public function joinBuddyRoom(userId:String):void
		//{
		//	var params:Object = {bn:userId};

		//	extRequest('jbr', params);
		//}

		public function sendPublicMsg(msg:String, params:Object=null):void
		{
			sfs_sendPublicMsg(msg, params, _currRoom);
		}

		private function sfs_sendPublicMsg(msg:String, params:Object=null, room:Room=null):void
		{
			var isfsParams:ISFSObject = SFSObject.newFromObject(params);
			var request:PublicMessageRequest = new PublicMessageRequest(msg, isfsParams, room);

		    _sfs && _sfs.send(request);
		}

		public function sendPrivateMsg(msg:String, toId:String, params:Object=null):Boolean
		{
			return sfs_sendPrivateMsg(msg, toId, params);
		}

		private function sfs_sendPrivateMsg(msg:String, userId:String, params:Object=null):Boolean
		{
			var isfsParams:ISFSObject;

			if (!_chatManager.isMe(userId))
			{
				if (!params)
				{
					params = {};
				}

				params['rn'] = userId;
				isfsParams = SFSObject.newFromObject(params);
				var request:PrivateMessageRequest = new PrivateMessageRequest(msg, 1, isfsParams);
		    	_sfs && _sfs.send(request);

				return true;
			}

			return false;
		}

		public function sendBuddyMsg(msg:String, toId:String, params:Object=null):Boolean
		{
			return sfs_sendBuddyMsg(msg, toId, params);
		}

		private function sfs_sendBuddyMsg(msg:String, userId:String, params:Object=null):Boolean
		{
			var buddy:Buddy;
			var isfsParams:ISFSObject;

			if (!_chatManager.isMe(userId))
			{
				if (!params)
				{
					params = {};
				}

				if (_sfs)
				{
					buddy = _sfs.buddyManager.getBuddyByName(userId);
				}

				if (buddy)
				{
					params['rn'] = userId;
					isfsParams = SFSObject.newFromObject(params);

					var request:BuddyMessageRequest = new BuddyMessageRequest(msg, buddy, isfsParams);
					_sfs.send(request);

					return true;
				}
			}

			return false;
		}

		public function extRequest(extCmd:String, params:Object=null):void
		{
			sfs_extRequest(extCmd, params);
		}

		private function sfs_extRequest(extCmd:String, params:Object=null, room:Room=null, useUDP:Boolean=false):void
		{
			var isfsParams:ISFSObject = SFSObject.newFromObject(params);
			var request:ExtensionRequest = new ExtensionRequest(extCmd, isfsParams, room, useUDP);

			_sfs && _sfs.send(request);
		}

		public function initBuddyList(buddyList:Array=null):void
		{
			sfs_initBuddyList();
		}

		private function sfs_initBuddyList():void
		{
			var request:InitBuddyListRequest = new InitBuddyListRequest();

			_sfs && _sfs.send(request);
		}

		public function addBuddy(userId:String):void
		{
			sfs_addBuddy(userId);
		}

		private function sfs_addBuddy(userId:String):void
		{
			var request:AddBuddyRequest = new AddBuddyRequest(userId);

			_sfs && _sfs.send(request);
		}

		public function removeBuddy(userId:String):void
		{
			sfs_removeBuddy(userId);
		}

		private function sfs_removeBuddy(userId:String):void
		{
			var request:RemoveBuddyRequest = new RemoveBuddyRequest(userId);

			_sfs && _sfs.send(request);
		}

		public function setMyVars(userVars:Object):void
		{
			sfs_setUserVariables(userVars);
		}

		private function sfs_setUserVariables(userVarsObj:Object):void
		{
			//var key:String;
			//var userVars:Array = [];
			//var buddyVars:Array = [];

			//for (key in userVarsObj)
			//{
			//	userVars.push(new SFSUserVariable(key, erVarsObj[key]));
			//}

			//var userRequest:SetUserVariablesRequest = new SetUserVariablesRequest(userVars);

			//_sfs && _sfs.send(userRequest);

			//for (key in userVarsObj)
			//{
			//	buddyVars.push(new SFSBuddyVariable(key, erVarsObj[key]));
			//}

			//var buddyRequest:SetBuddyVariablesRequest = new SetBuddyVariablesRequest(buddyVars);

			//_sfs && _sfs.send(buddyRequest);
		}

		//public function goOnline(online:Boolean=true):void
		//{
		//	sfs_goOnline(online);
		//}

		private function sfs_goOnline(online:Boolean=true):void
		{
			var request:GoOnlineRequest = new GoOnlineRequest(online);

			_sfs && _sfs.send(request);
		}

		public function get currRoomObj():Object
		{
			return roomToObject(_currRoom);
		}

		private function hasConfig():Boolean
		{
			if (_sfs && _sfs.config)
			{
				return true;
			}

			return false;
		}

		public function get config():Object
		{
			if (_sfs && _sfs.config)
			{
				return configDataToObject(_sfs.config);
			}

			return null;
		}

		public function set configPath(filePath:String):void
		{
			if (filePath)
			{
				_configPath = filePath;
			}
		}

		public function get isConnected():Boolean
		{
			if (_sfs && _sfs.isConnected)
			{
				return true;
			}

			return false;
		}

		public function roomListFromGroup(groupId:String):Array
		{
			var roomList:Array;

			if (_sfs)
			{
				roomList = _sfs.getRoomListFromGroup(groupId);
			}

			return roomListToArray(roomList);
		}

		private function onConfigLoadSuccess(event:SFSEvent):void
		{
			_chatManager.showMsg('onConfigLoadSuccess:', config);
			connectServer();
		}

		private function onConfigLoadFailure(event:SFSEvent):void
		{
			if (_chatManager.autoReConn)
			{
				_isReConn = true;
				_chatManager.showMsg('onConfigLoadFailure: try to reconnect.');
			}else
			{
				_chatManager.showMsg('onConfigLoadFailure');
				dispatchEvent(new ChatEvent(ChatEvent.SYS_DISCONN));
			}
		}

		private function onConnection(event:SFSEvent):void
		{
			if (event.params.success)
			{
				_chatManager.showMsg('onConnection: connected.');
				doLogin();
			}else
			{
				if (_chatManager.autoReConn)
				{
					_chatManager.showMsg('onConnection: connect fail, try to reconnect.');
					_isReConn = true;
				}else
				{
					_chatManager.showMsg('onConnection: connected fail.');
					dispatchEvent(new ChatEvent(ChatEvent.SYS_DISCONN));
				}
			}
		}

		private function onLogin(event:SFSEvent):void
		{
			_isLogin = true;
			_reConnTime = 0;
			_retryCount = 0;

			_chatManager.showMsg('onLogin:', event.params);
			dispatchEvent(new ChatEvent(ChatEvent.SYS_LOGIN));

			doJoinRoom();
		}

		private function onLoginError(event:SFSEvent):void
		{
			if (_chatManager.autoReConn)
			{
				_isReConn = true;
				_chatManager.showMsg('onLoginError:' + event.params.errorMessage + ', try to reconnect.');
			}else
			{
				_chatManager.showMsg('onLoginError:' + event.params.errorMessage);
				dispatchEvent(new ChatEvent(ChatEvent.SYS_DISCONN));
			}

		}

		private function onConnectionLost(event:SFSEvent):void
		{
			_isLogin = false;

			if (_chatManager.autoReConn)
			{
				_chatManager.showMsg('onConnectionLost: try to reconnect.');
				_isReConn = true;
			}else
			{
				_chatManager.showMsg('onConnectionLost');
				dispatchEvent(new ChatEvent(ChatEvent.SYS_DISCONN));
			}
		}

		private function onAttemptHttp(event:SFSEvent):void
		{
			_chatManager.showMsg('onAttemptHttp');
		}

		private function onConnectionResume(event:SFSEvent):void
		{
			_chatManager.showMsg('onConnectionResume: auto connect');
			dispatchEvent(new ChatEvent(ChatEvent.SYS_LOGIN, {auto:true}));
		}

		private function onConnectionRetry(event:SFSEvent):void
		{
			_chatManager.showMsg('onConnectionRetry: auto connect');
			dispatchEvent(new ChatEvent(ChatEvent.SYS_DISCONN, {auto:true}));
		}

		private function onSocketError(event:SFSEvent):void
		{
			_chatManager.showMsg('onSocketError:' + event.params.errorMessage);
		}

		private function onRoomJoinError(event:SFSEvent):void
		{
			_chatManager.showMsg('onRoomJoinError:' + event.params.errorMessage);
			dispatchEvent(new ChatEvent(ChatEvent.SYS_ROOMJOIN, {status:false}));
		}

		private function onRoomJoin(event:SFSEvent):void
		{
			var room:Room = event.params.room;
			_currRoom = room;

			var roomObj:Object = roomToObject(room);

			_chatManager.showMsg('onRoomJoin', roomObj);
		}

		private function onPublicMessage(event:SFSEvent):void
		{
			var sender:User = event.params.sender;
			var msg:String = event.params.message;
			var subParams:ISFSObject = event.params.data;
			var senderObj:Object = userToObject(sender);

			_chatManager.showMsg('onPublicMessage:' + sender.name + ', ' + msg, subParams.toObject());
		}

		private function onPrivateMessage(event:SFSEvent):void
		{
			var sender:User = event.params.sender;
			var msg:String = event.params.message;
			var subParams:ISFSObject = event.params.data;
			var senderObj:Object = userToObject(sender);

			_chatManager.showMsg('onPrivateMessage:' + sender.name + ', ' + msg, subParams.toObject());
		}

		private function onUserEnterRoom(event:SFSEvent):void
		{
			var user:User = event.params.user;
			var roomObj:Object = roomToObject(_currRoom);
			var userObj:Object = userToObject(user);

			_chatManager.showMsg('onUserEnterRoom:' + user.name, roomObj);
		}

		private function onUserExitRoom(event:SFSEvent):void
		{
			var user:User = event.params.user;
			var roomObj:Object = roomToObject(_currRoom);
			var userObj:Object = userToObject(user);

			_chatManager.showMsg('onUserExitRoom:' + user.name, roomObj);
		}

		private function onUserCountChange(event:SFSEvent):void
		{
			_chatManager.showMsg('onUserCountChange', event.params);
		}

		private function onExtensionResponse(event:SFSEvent):void
        {
            var cmd:String = event.params.cmd;
			var responseParams:ISFSObject = event.params.params as SFSObject;
			var paramsObj:Object = responseParams.toObject();

            switch(cmd)
            {
                case 'pong':
					pongExt(paramsObj.t);

                    break;
                case 'jr':
                    jrExt(paramsObj.r, paramsObj.ul);

                    break;
                case 'er':
                    erExt(paramsObj.r, paramsObj.u);

                    break;
                case 'lr':
                    lrExt(paramsObj.r, paramsObj.u);

                    break;
                case 'pum':
					pumExt(paramsObj.r, paramsObj.u, paramsObj.m, paramsObj.p);

                    break;
                case 'prm':
					prmExt(paramsObj.u, paramsObj.m, paramsObj.p);

					break;
                case 'bm':
					bmExt(paramsObj.u, paramsObj.m, paramsObj.p);

                    break;
                case 'push':
					pushExt(paramsObj.m);

                    break;
                case 'sr':
					srExt(paramsObj.re, paramsObj.m);

					break;
                case 'jbr':
					jbrExt(paramsObj.re, paramsObj.m);

                    break;
                default:
                    _chatManager.showMsg('onExtResponse:' + cmd + '(cmd) is not fond.');
            }
        }

		private function jrExt(roomName:String, userListData:Array):void
        {
            var roomObj:Object = getRoomObjByName(roomName);
            var userList:Array = getUserList(userListData);

            setCurrRoom(roomName);
            _chatManager.showMsg('jrExt:' + roomName);

            dispatchEvent(new ChatEvent(ChatEvent.SYS_ROOMJOIN, {status:true, roomData:roomObj, roomUsers:userList}));
        }

		private function erExt(roomName:String, userData:Array):void
        {
            var roomObj:Object = getRoomObjByName(roomName);
            var userObj:Object = getUserObj(userData);

            _chatManager.showMsg('erExt:' + userObj.userId);

            dispatchEvent(new ChatEvent(ChatEvent.SYS_USER_ENTERROOM, {userData:userObj, roomData:roomObj}));
        }

		private function lrExt(roomName:String, userData:Array):void
        {
            var roomObj:Object = getRoomObjByName(roomName);
            var userObj:Object = getUserObj(userData);

            _chatManager.showMsg('lrExt:' + userObj.userId);

            dispatchEvent(new ChatEvent(ChatEvent.SYS_USER_EXITROOM, {userData:userObj, roomData:roomObj}));
        }

		private function pumExt(roomName:String, userData:Array, msgData:String, params:Object):void
        {
            var roomObj:Object = getRoomObjByName(roomName);
            var userObj:Object = getUserObj(userData);

            _chatManager.showMsg('pumExt:' + roomObj.name + ', ' + userObj.userId + ', ' + msgData, params);

            if (!_chatManager.isMe(userObj.userId))
            {
                dispatchEvent(new ChatEvent(ChatEvent.SYS_MESSAGE, {roomData:roomObj, senderData:userObj,
					msgData:msgData, paramsData:params, type:ChatManager.PUBLIC_MESSAGE}));
            }
        }

		private function prmExt(userData:Array, msgData:String, params:Object):void
        {
            var userObj:Object = getUserObj(userData);

            _chatManager.showMsg('prmExt:'+ userObj.userId + ', ' + msgData, params);

            if (!_chatManager.isMe(userObj.userId))
            {
                dispatchEvent(new ChatEvent(ChatEvent.SYS_MESSAGE, {senderData:userObj, msgData:msgData,
					paramsData:params, type:ChatManager.PRIVATE_MESSAGE}));
            }
        }

		private function bmExt(userData:Array, msgData:String, params:Object):void
		{
            var userObj:Object = getUserObj(userData);

            _chatManager.showMsg('bmExt:'+ userObj.userId + ', ' + msgData, params);

            if (!_chatManager.isMe(userObj.userId))
            {
                dispatchEvent(new ChatEvent(ChatEvent.SYS_MESSAGE, {senderData:userObj, msgData:msgData,
					paramsData:params, type:ChatManager.BUDDY_MESSAGE}));
            }
		}

		private function pushExt(data:String):void
		{
			_chatManager.showMsg('pushExt:'+ data);

            dispatchEvent(new ChatEvent(ChatEvent.SYS_SERVER_PUSH, {pushData:data}));
		}

		private function pongExt(time:int):void
        {
            _pingTime = 0;
			_chatManager.setSysTime(time);
        }

		private function srExt(status:Boolean, message:String):void
		{
			_chatManager.showMsg('srExt:'+ status + ', ' + message);

			if (!status)
			{
            	dispatchEvent(new ChatEvent(ChatEvent.SYS_AUTO_ROOMJOIN_ERROR));
			}
		}

		private function jbrExt(status:Boolean, message:String):void
		{
			_chatManager.showMsg('jbrExt:'+ status + ', ' + message);

           	dispatchEvent(new ChatEvent(ChatEvent.SYS_JOIN_BUDDY_ROOM, {status:status, errorMsg:message}));
		}

		private function onBuddyListInitialized(event:SFSBuddyEvent):void
		{
			var buddies:Array = event.params.buddyList;
			var buddyList:Array = buddyListToArray(buddies);

            _chatManager.showMsg('onBuddyListInitialized', buddyList);

			dispatchEvent(new ChatEvent(ChatEvent.SYS_BUDDY_LIST_INIT, {buddyListData:buddyList}));

			sfs_goOnline(true);
		}

		private function onBuddyError(event:SFSBuddyEvent):void
		{
            _chatManager.showMsg('onBuddyError:'+ event.params.errorMessage);

			dispatchEvent(new ChatEvent(ChatEvent.SYS_BUDDY_ERROR));
		}

		private function onBuddyAdded(event:SFSBuddyEvent):void
		{
			var buddy:Buddy = event.params.buddy;
			var buddyObj:Object = buddyToObject(buddy);

			_chatManager.showMsg('onBuddyAdded', buddyObj);

			dispatchEvent(new ChatEvent(ChatEvent.SYS_BUDDY_ADD, {buddyData:buddyObj}));
		}

		private function onBuddyRemoved(event:SFSBuddyEvent):void
		{
			var buddy:Buddy = event.params.buddy;
			var buddyObj:Object = buddyToObject(buddy);

			_chatManager.showMsg('onBuddyRemoved', buddyObj);

			dispatchEvent(new ChatEvent(ChatEvent.SYS_BUDDY_REMOVE, {buddyData:buddyObj}));
		}

		private function onBuddyOnlineStateUpdated(event:SFSBuddyEvent):void
		{
			var isItMe:Boolean = event.params.isItMe;
			var buddy:Buddy = event.params.buddy;
			var buddyObj:Object = buddyToObject(buddy);

			if (!isItMe)
			{
				dispatchEvent(new ChatEvent(ChatEvent.SYS_BUDDY_ONLINE_STATE_UPDATE, {buddyData:buddyObj}));
			}
		}

        private function loadServerTime():void
        {
            if (_isLogin)
            {
                if (!_pingTime)
                {
                    _pingTime = _chatManager.sysTime;
                }

                if (_chatManager.sysTime - _pingTime >= PING_INTERVAL)
                {
                    _pingTime = 0;
                    extRequest('ping');
                }
            }
        }

		private function configDataToObject(config:ConfigData):Object
		{
			var obj:Object;

			if (config)
			{
				obj = {};
				obj['blueBoxPollingRate'] = config.blueBoxPollingRate;
				obj['debug'] = config.debug;
				obj['host'] = config.host;
				obj['httpPort'] = config.httpPort;
				obj['port'] = config.port;
				obj['udpHost'] = config.udpHost;
				obj['udpPort'] = config.udpPort;
				obj['useBlueBox'] = config.useBlueBox;
				obj['zone'] = config.zone;
			}

			return obj;
		}

		private function userToObject(user:User):Object
		{
			var obj:Object;

			if (user)
			{
				obj = {};
				obj['userId'] = user.name;
				obj['isMe'] = user.isItMe;
			}

			return obj;
		}

		private function userListToArray(userList:Array):Array
		{
			var arr:Array;

			if (userList && userList.length)
			{
				arr = [];

				for each(var user:User in userList)
				{
					arr.push(userToObject(user));
				}
			}

			return arr;
		}

		private function buddyToObject(buddy:Buddy):Object
		{
			var obj:Object;

			if (buddy)
			{
				obj = {};
				obj['userId'] = buddy.name;
				obj['isOnline'] = buddy.isOnline;
				obj['nickName'] = buddy.nickName;
				obj['state'] = buddy.state;
				obj['variables'] = buddy.variables;
			}

			return obj;
		}

		private function buddyListToArray(buddyList:Array):Array
		{
			var arr:Array;

			if (buddyList && buddyList.length)
			{
				arr = [];

				for each(var buddy:Buddy in buddyList)
				{
					arr.push(buddyToObject(buddy));
				}
			}

			return arr;
		}

		private function roomToObject(room:Room):Object
		{
			var obj:Object;

			if (room)
			{
				obj = {};
				obj['id'] = room.id;
				obj['name'] = room.name;
				obj['groupId'] = room.groupId;
				obj['isJoined'] = room.isJoined;
				obj['maxUsers'] = room.maxUsers;
				obj['userCount'] = room.userCount;
				obj['userList'] = userListToArray(room.userList);
			}

			return obj;
		}

		private function roomListToArray(roomList:Array):Array
		{
			var arr:Array;

			if (roomList && roomList.length)
			{
				arr = [];

				for each(var room:Room in roomList)
				{
					arr.push(roomToObject(room));
				}
			}

			return arr;
		}

		private function setCurrRoom(name:String):void
		{
			var room:Room;

			if (_sfs)
			{
				room = _sfs.roomManager.getRoomByName(name);
			}

			if (room)
			{
				_currRoom = room;
			}
		}

		private function getUserObj(data:Array):Object
		{
			var userObj:Object;

			if (data && data.length)
			{
				userObj = {};
				userObj['userId'] = data[0];
				userObj['isMe'] = _chatManager.isMe(userObj['userId']);
				userObj['nodeId'] = data[1];
			}

			return userObj;
		}

		private function getUserList(data:Array):Array
		{
			var userList:Array;
			var userObj:Object;

			if (data && data.length)
			{
				userList = [];

				for each(var arr:Array in data)
				{
					userObj = getUserObj(arr);

					if (userObj)
					{
						userList.push(userObj);
					}
				}
			}

			return userList;
		}

		private function getRoomObjByName(name:String):Object
		{
			var room:Room;
			var roomObj:Object;

			if (_sfs)
			{
				room = _sfs.roomManager.getRoomByName(name);
			}

			if (room)
			{
				roomObj = {};
				roomObj['id'] = room.id;
				roomObj['name'] = room.name;
				roomObj['groupId'] = room.groupId;
				roomObj['isJoined'] = room.isJoined;
				roomObj['maxUsers'] = room.maxUsers;
			}

			return roomObj;
		}
	}
}
