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
	import chat.event.ChatEvent;
	import data.ChatData;

	public class ChatPanel extends Sprite
	{
		public static const TABROOM:String = 'tabroom';
		public static const TABBUDDY:String = 'tabbuddy';

		private var _asset:Sprite;
		private var _ac:Aschat;
		private var _roomTabBtn:MovieClip;
		private var _buddyTabBtn:MovieClip;
		private var _sendTxt:TextField;
		private var _sendBtn:MovieClip;
		private var _chatTxt:TextField;
		private var _infoTxt:TextField;
		private var _currTab:String;
		private var _currMode:String;
		private var _nextRoom:String;

		public function ChatPanel(cls:Class, ac:Aschat)
		{
			_ac = ac;

			if (cls)
			{
				_asset = new cls() as Sprite;
			}

			if (_asset)
			{
				addChild(_asset);

				init();
			}
		}

		private function init():void
		{
			_roomTabBtn = _asset.getChildByName('roomTabBtn') as MovieClip;
			_roomTabBtn.buttonMode = true;
			_roomTabBtn.mouseChildren = false;
			_roomTabBtn.gotoAndStop(3);
			_roomTabBtn.addEventListener(MouseEvent.CLICK, roomTabBtnClick);
			_roomTabBtn.addEventListener(MouseEvent.MOUSE_OVER, btnHandler);
			_roomTabBtn.addEventListener(MouseEvent.MOUSE_OUT, btnHandler);

			_buddyTabBtn = _asset.getChildByName('buddyTabBtn') as MovieClip;
			_buddyTabBtn.buttonMode = true;
			_buddyTabBtn.mouseChildren = false;
			_buddyTabBtn.gotoAndStop(1);
			_buddyTabBtn.addEventListener(MouseEvent.CLICK, buddyTabBtnClick);
			_buddyTabBtn.addEventListener(MouseEvent.MOUSE_OVER, btnHandler);
			_buddyTabBtn.addEventListener(MouseEvent.MOUSE_OUT, btnHandler);

			_currTab = TABROOM;

			_sendBtn = _asset.getChildByName('sendBtn') as MovieClip;
			_sendBtn.buttonMode = true;
			_sendBtn.mouseChildren = false;
			_sendBtn.gotoAndStop(3);
			_sendBtn.addEventListener(MouseEvent.CLICK, sendBtnClick);
			_sendBtn.addEventListener(MouseEvent.MOUSE_OVER, btnHandler);
			_sendBtn.addEventListener(MouseEvent.MOUSE_OUT, btnHandler);

			_sendTxt = _asset.getChildByName('sendTxt') as TextField;
			_sendTxt.textColor = 0x00AFFF;
			_sendTxt.addEventListener(MouseEvent.CLICK, setInputTxt);
			_sendTxt.addEventListener(Event.CHANGE, textInput);
			_sendTxt.addEventListener(FocusEvent.FOCUS_IN, focusInHandler);
			_sendTxt.addEventListener(FocusEvent.FOCUS_OUT, focusOutHandler);

			_chatTxt = _asset.getChildByName('chatTxt') as TextField;
			_chatTxt.selectable = true;
			_chatTxt.wordWrap = true;
			_chatTxt.multiline = true;
			_chatTxt.condenseWhite = true;
			_chatTxt.alwaysShowSelection = true;
			_chatTxt.addEventListener(TextEvent.LINK, onTxtClick);

			_infoTxt = _asset.getChildByName('infoTxt') as TextField;
			_infoTxt.selectable = false;
			_infoTxt.wordWrap = true;
			_infoTxt.multiline = true;
			_infoTxt.condenseWhite = true;
			_infoTxt.addEventListener(TextEvent.LINK, onTxtClick);

			ChatManager.singleton.addEventListener(ChatEvent.SYS_MESSAGE, onMessage);
			ChatManager.singleton.addEventListener(ChatEvent.SYS_ROOMJOIN, onRoomJoin);
			//ChatManager.singleton.addEventListener(ChatEvent.SYS_ROOMLEAVE, onRoomLeave);
			ChatManager.singleton.addEventListener(ChatEvent.SYS_USER_ENTERROOM, onUserEnterRoom);
			ChatManager.singleton.addEventListener(ChatEvent.SYS_USER_EXITROOM, onUserExitRoom);
			ChatManager.singleton.addEventListener(ChatEvent.SYS_HISTORY_MESSAGE, onHistoryMessage);
		}

		public function showRoomList():void
		{
			_infoTxt.htmlText = ChatData.singleton.getRoomTxt();
			_infoTxt.scrollV = _infoTxt.maxScrollV;
		}

		private function onTxtClick(event:TextEvent):void
		{
			var idArr:Array;
			var id:String;

			if (event.text)
			{
				idArr = event.text.split('_');
				id = event.text.substr(idArr[0].length + 1);

				if (idArr[0] == 'ROOM')
				{
					joinRoom(id);
				}else if (idArr[0] == 'USER')
				{
					_currMode = ChatManager.PRIVATE_MESSAGE;

					setChatTxt(id);
				}else if (idArr[0] == 'ADD')
				{
					addBuddy(id);
				}else if (idArr[0] == 'REMOVE')
				{
					removeBuddy(id);
				}else if (idArr[0] == 'BUDDY')
				{
					_currMode = ChatManager.BUDDY_MESSAGE;

					setChatTxt(id);
				}else if (idArr[0] == 'JBR')
				{
					//joinBuddyRoom(id);
				}
			}
		}

		private function setChatTxt(userId:String):void
		{
			var len:int;
			var sendObj:Object = ChatData.singleton.getSendObj(sendTxt, _currMode);

			if (sendObj)
			{
				_sendTxt.text = '@' + userId + ':' + sendObj.msg;
			}else
			{
				_sendTxt.text = '@' + userId + ':';
			}

			_sendTxt.stage.focus = _sendTxt;
			len = sendTxt.length;
			_sendTxt.setSelection(len, len);

			getInputMode();
		}

		private function joinRoom(roomId:String):void
		{
			_ac.showLoading();

			if (!_nextRoom)
			{
				_nextRoom = roomId;
			}

			if (ChatManager.singleton.currRoom)
			{
				ChatData.singleton.loadRoomUser([]);
				ChatManager.singleton.leaveRoom(ChatManager.singleton.currRoom.name);
			}

			ChatManager.singleton.joinRoom(roomId);

			//if (ChatManager.singleton.currRoom)
			//{
			//	if (!_nextRoom)
			//	{
			//		_nextRoom = roomId;
			//	}

			//	ChatManager.singleton.leaveRoom();
			//}else
			//{
			//	ChatManager.singleton.joinRoom(roomId);
			//}
		}

		private function addBuddy(userId:String):void
		{
			_ac.showLoading();

			ChatManager.singleton.addEventListener(ChatEvent.SYS_BUDDY_ERROR, onAddError);
			ChatManager.singleton.addEventListener(ChatEvent.SYS_BUDDY_ADD, onBuddyAdded);

			ChatManager.singleton.addBuddy(userId);
		}

		private function onAddError(event:ChatEvent):void
		{
			_ac.hideLoading();
			ChatManager.singleton.removeEventListener(ChatEvent.SYS_BUDDY_ERROR, onAddError);
			ChatManager.singleton.removeEventListener(ChatEvent.SYS_BUDDY_ADD, onBuddyAdded);

			//do some thing
		}

		private function onBuddyAdded(event:ChatEvent):void
		{
			ChatManager.singleton.removeEventListener(ChatEvent.SYS_BUDDY_ERROR, onAddError);
			ChatManager.singleton.removeEventListener(ChatEvent.SYS_BUDDY_ADD, onBuddyAdded);

			ChatData.singleton.addBuddy(event.data.buddyData);

			infoTxtUpdate();

			_ac.hideLoading();
		}

		private function removeBuddy(userId:String):void
		{
			_ac.showLoading();

			ChatManager.singleton.addEventListener(ChatEvent.SYS_BUDDY_ERROR, onRemoveError);
			ChatManager.singleton.addEventListener(ChatEvent.SYS_BUDDY_REMOVE, onBuddyRemoved);

			ChatManager.singleton.removeBuddy(userId);
		}

		private function onRemoveError(event:ChatEvent):void
		{
			_ac.hideLoading();

			ChatManager.singleton.removeEventListener(ChatEvent.SYS_BUDDY_ERROR, onRemoveError);
			ChatManager.singleton.removeEventListener(ChatEvent.SYS_BUDDY_REMOVE, onBuddyRemoved);

			//do some thing
		}

		private function onBuddyRemoved(event:ChatEvent):void
		{
			ChatManager.singleton.removeEventListener(ChatEvent.SYS_BUDDY_ERROR, onRemoveError);
			ChatManager.singleton.removeEventListener(ChatEvent.SYS_BUDDY_REMOVE, onBuddyRemoved);

			ChatData.singleton.removeBuddy(event.data.buddyData);

			infoTxtUpdate();

			_ac.hideLoading();
		}

		//private function joinBuddyRoom(userId:String):void
		//{
		//	_ac.showLoading();

		//	ChatManager.singleton.addEventListener(ChatEvent.SYS_JOIN_BUDDY_ROOM, onJoinBuddyRoom);
		//	ChatManager.singleton.joinBuddyRoom(userId);
		//}

		private function setInputTxt(event:Event):void
		{

			var tf:TextField = event.target as TextField;
			var len:int;

			if (tf.stage)
			{
				tf.stage.focus = tf;
				len = sendTxt.length;
				if (!len)
				{
					tf.text = '@All:';
					len = sendTxt.length;
					tf.setSelection(len, len);
					_currMode = ChatManager.PUBLIC_MESSAGE;
				}
			}
		}

		private function textInput(event:Event):void
		{
			var tf:TextField = event.target as TextField;
			var sendObj:Object;

			if (tf)
			{
				getInputMode();

				sendObj = ChatData.singleton.getSendObj(sendTxt, _currMode);

				if (sendObj && sendObj.msg)
				{
					_sendBtn.gotoAndStop(1);
				}else
				{
					_sendBtn.gotoAndStop(3);
				}
			}
		}

		private function getInputMode():void
		{
			var index:int;
			var msg:String = sendTxt;

			if (msg)
			{
				if (msg.substr(0, 1) == '@')
				{
					index = msg.indexOf(':');

					if (index == -1)
					{
						index = msg.indexOf(' ');
					}

					if (index == -1)
					{
						index = msg.indexOf('：');
					}

					if (index != -1)
					{
						if (msg.substring(1, index).toUpperCase() == 'ALL')
						{
							_currMode = ChatManager.PUBLIC_MESSAGE;
						}
					}else
					{
						_currMode = ChatManager.PUBLIC_MESSAGE;
					}
				}else
				{
					_currMode = ChatManager.PUBLIC_MESSAGE;
				}
			}

			changeInputColor();
		}

		private function changeInputColor():void
		{
			if (_currMode == ChatManager.PRIVATE_MESSAGE)
			{
				_sendTxt.textColor = 0xD75FD7;
			}

			if (_currMode == ChatManager.PUBLIC_MESSAGE)
			{
				_sendTxt.textColor = 0x00AFFF;
			}

			if (_currMode == ChatManager.BUDDY_MESSAGE)
			{
				_sendTxt.textColor = 0x5F87FF;
			}
		}

		private function focusInHandler(event:FocusEvent):void
		{
			ChatData.singleton.enableIME();
		}

		private function focusOutHandler(event:FocusEvent):void
		{
			ChatData.singleton.disableIME();
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

		private function roomTabBtnClick(event:MouseEvent):void
		{
			var btn:MovieClip = event.target as MovieClip;

			if (btn)
			{
				if (btn.currentFrame > 2) return;

				if (currTab != TABROOM)
				{
					_currTab = TABROOM;
					_roomTabBtn.gotoAndStop(3);
					_buddyTabBtn.gotoAndStop(1);

					_infoTxt.htmlText = ChatData.singleton.getRoomTxt();

					_infoTxt.scrollV = _infoTxt.maxScrollV;
				}
			}
		}

		private function buddyTabBtnClick(event:MouseEvent):void
		{
			var btn:MovieClip = event.target as MovieClip;

			if (btn)
			{
				if (btn.currentFrame > 2) return;

				if (currTab != TABBUDDY)
				{
					_currTab = TABBUDDY;
					_roomTabBtn.gotoAndStop(1);
					_buddyTabBtn.gotoAndStop(3);

					_infoTxt.htmlText = ChatData.singleton.getBuddyTxt();

					_infoTxt.scrollV = _infoTxt.maxScrollV;
				}
			}

		}

		public function infoTxtUpdate():void
		{
			if (currTab == TABBUDDY)
			{
				_infoTxt.htmlText = ChatData.singleton.getBuddyTxt();
			}else if (currTab == TABROOM)
			{
				_infoTxt.htmlText = ChatData.singleton.getRoomTxt();
			}

			_infoTxt.scrollV = _infoTxt.maxScrollV;
		}

		private function sendBtnClick(event:MouseEvent):void
		{
			var btn:MovieClip = event.target as MovieClip;

			sendMsg(btn);
		}

		private function sendMsg(btn:MovieClip):void
		{

			var sendObj:Object = ChatData.singleton.getSendObj(sendTxt, _currMode);
			var isSend:Boolean;
			var obj:Object;
			var userObj:Object;

			if (btn)
			{
				if (btn.currentFrame > 2) return;

				if (sendObj && sendObj.msg)
				{
					if (sendObj.type == ChatManager.PUBLIC_MESSAGE && !ChatManager.singleton.currRoom)
					{
						return;
					}

					if (sendObj.type == ChatManager.PUBLIC_MESSAGE)
					{
						ChatManager.singleton.sendPublicMsg(sendObj.msg);

						userObj = {name:ChatManager.singleton.userId, isMe:true};

						obj =
						{
							senderData:userObj,
							msgData:sendObj.msg,
							type:sendObj.type,
							paramsData:null
						}
					}else if (sendObj.type == ChatManager.PRIVATE_MESSAGE)
					{
						isSend = ChatManager.singleton.sendPrivateMsg(sendObj.msg, sendObj.recipient);

						if (isSend)
						{
							userObj = {name:ChatManager.singleton.userId, isMe:true};

							obj =
							{
								senderData:userObj,
								recipient:sendObj.recipient,
								msgData:sendObj.msg,
								type:sendObj.type,
								paramsData:null
							}
						}
					}else if (sendObj.type == ChatManager.BUDDY_MESSAGE)
					{
						isSend = ChatManager.singleton.sendBuddyMsg(sendObj.msg, sendObj.recipient);

						if (isSend)
						{
							userObj = {name:ChatManager.singleton.userId, isMe:true};

							obj =
							{
								senderData:userObj,
								recipient:sendObj.recipient,
								msgData:sendObj.msg,
								type:sendObj.type,
								paramsData:null
							}
						}
					}

					ChatData.singleton.addChatData(obj);

					_chatTxt.htmlText = ChatData.singleton.getChatTxt();
					_chatTxt.scrollV = _chatTxt.maxScrollV;

					_sendTxt.text = sendObj.to;
					_sendTxt.stage.focus = _sendTxt;
					var len:int = sendTxt.length;
					_sendTxt.setSelection(len, len);
				}
			}
		}

		private function onMessage(event:ChatEvent):void
		{
			if (event.data)
			{
				ChatData.singleton.addChatData(event.data);
			}

			_chatTxt.htmlText = ChatData.singleton.getChatTxt();
			_chatTxt.scrollV = _chatTxt.maxScrollV;
		}

		private function onHistoryMessage(event:ChatEvent):void
		{
			if (event.data && event.data.roomData && event.data.historyData)
			{
				if (event.data.roomData.name == ChatManager.singleton.currRoom.name)
				{
					ChatData.singleton.addHistoryChatData(event.data.historyData as Array);
				}
			}

			_chatTxt.htmlText = ChatData.singleton.getChatTxt();
			_chatTxt.scrollV = _chatTxt.maxScrollV;
		}

		public function onEnterKey():void
		{
			sendMsg(_sendBtn);
		}

		public function get currTab():String
		{
			return _currTab;
		}

		public function get currMode():String
		{
			return _currMode;
		}

		private function onRoomJoin(event:ChatEvent):void
		{
			if (event.data && event.data.status && event.data.roomData)
			{
				if (event.data.roomData.name == ChatManager.singleton.currRoom.name)
				{
					loadRoomUser(event.data.roomUsers);
				}

				_nextRoom = null;
				_ac.hideLoading();
			}else
			{
				//join error
				ChatManager.singleton.joinRoom(_nextRoom);
			}
		}

		//private function onRoomLeave(event:ChatEvent):void
		//{
		//	if (event.data && event.data.status)
		//	{
		//		loadRoomUser([]);

		//		if (_nextRoom)
		//		{
		//			ChatManager.singleton.joinRoom(_nextRoom);
		//		}else
		//		{
		//			_ac.hideLoading();
		//		}
		//	}else
		//	{
		//		//leaveRoom error
		//		if (_nextRoom)
		//		{
		//			joinRoom(_nextRoom)
		//		}else
		//		{
		//			ChatManager.singleton.leaveRoom();
		//		}
		//	}
		//}

		private function onUserEnterRoom(event:ChatEvent):void
		{
			if (event.data && event.data.userData && event.data.roomData)
			{
				if (event.data.roomData.name == ChatManager.singleton.currRoom.name)
				{
					ChatData.singleton.addRoomUser(event.data.userData);
				}
			}

			loadRoomUser(null);
		}

		private function onUserExitRoom(event:ChatEvent):void
		{
			if (event.data && event.data.userData && event.data.roomData)
			{
				if (event.data.roomData.name == ChatManager.singleton.currRoom.name)
				{
					ChatData.singleton.removeRoomUser(event.data.userData);
				}
			}

			loadRoomUser(null);
		}

		private function onJoinBuddyRoom(event:ChatEvent):void
		{
			_ac.hideLoading();

			ChatManager.singleton.removeEventListener(ChatEvent.SYS_JOIN_BUDDY_ROOM, onJoinBuddyRoom);

			if (event.data && event.data.status)
			{
				loadRoomUser(null);
			}else
			{
				//do error
			}
		}

		private function loadRoomUser(userList:Array):void
		{
			if (userList)
			{
				ChatData.singleton.loadRoomUser(userList);
			}

			if (currTab == TABROOM)
			{
				var count:int = _infoTxt.scrollV;
				_infoTxt.htmlText = ChatData.singleton.getRoomTxt();
				_infoTxt.scrollV = count;
			}
		}

		private function get sendTxt():String
		{
			return ChatData.singleton.trim(_sendTxt.text);
		}
	}
}
