package data
{
	import flash.text.TextField;
	import flash.system.Capabilities;
	import flash.system.IME;
	import flash.system.IMEConversionMode;

	import chat.ChatManager;

	public class ChatData
	{
		private static var _instance:ChatData;

		private var _chatData:Array;
		private var _roomUser:Array;
		private var _buddyData:Array;

		//\x20表示半角空格，\　表示全角空格，\n\t\r分别表示换行符、制表位、回车
		private static const blankStr:String = '\x20\　\n\t\r';

		public function ChatData()
		{
			_chatData = [];
			_roomUser = [];
			_buddyData = [];
		}

		public static function get singleton():ChatData
		{
			if (!_instance)
			{
				_instance = new ChatData();
			}

			return _instance;
		}

		public function loadRoomUser(userList:Array):void
		{
			_roomUser = [];

			for each(var user:Object in userList)
			{
				if (!user.isMe)
				{
					_roomUser.push(user)
				}
			}
		}

		public function addRoomUser(userObj:Object):void
		{
			if (userObj.isMe)
			{
				return;
			}

			for each(var user:Object in roomUser)
			{
				if (userObj.userId == user.userId)
				{
					ChatManager.singleton.showMsg('addRoomUser:user (' + userObj.userId + ') already exists.')
					return;
				}
			}

			_roomUser.push(userObj);
		}

		public function removeRoomUser(userObj:Object):void
		{
			var index:int = 0;

			if (userObj.isMe)
			{
				return;
			}

			for each(var user:Object in roomUser)
			{
				if (userObj.userId == user.userId)
				{
					_roomUser.splice(index, 1);
					return;
				}

				index++;
			}

			ChatManager.singleton.showMsg('removeRoomUser:user (' + userObj.userId + ') does not exist.')
		}

		public function get roomUser():Array
		{
			return _roomUser;
		}

		public function addHistoryChatData(chatArr:Array):void
		{
			_chatData = [];

			for each(var msgObj:Object in chatArr)
			{
				addChatData(msgObj);
			}
		}

		public function addChatData(msgObj:Object):void
		{
			_chatData.push(msgObj);

			if (_chatData.length > 100)
			{
				_chatData.shift();
			}
		}

		public function get chatData():Array
		{
			return _chatData;
		}

		public function loadBuddyData(buddyList:Array):void
		{
			_buddyData = [];

			for each(var buddy:Object in buddyList)
			{
				if (!ChatManager.singleton.isMe(buddy.userId))
				{
					_buddyData.push(buddy);
				}
			}
		}

		public function addBuddy(buddyObj:Object):void
		{
			for each(var buddy:Object in buddyData)
			{
				if (buddyObj.userId == buddy.userId)
				{
					ChatManager.singleton.showMsg('addBuddy:buddy (' + buddyObj.userId + ') already exists.')
					return;
				}
			}

			_buddyData.push(buddyObj);
		}

		public function removeBuddy(buddyObj:Object):void
		{
			var index:int = 0;

			for each(var buddy:Object in buddyData)
			{
				if (buddyObj.userId == buddy.userId)
				{
					_buddyData.splice(index, 1);
					return;
				}

				index++;
			}

			ChatManager.singleton.showMsg('removeBuddy:buddy (' + buddyObj.userId + ') does not exist.')
		}

		public function updateBuddyState(buddyObj:Object):void
		{
			for each(var buddy:Object in buddyData)
			{
				if (buddyObj.userId == buddy.userId)
				{
					buddy.isOnline = buddyObj.isOnline;
					return;
				}
			}
		}

		public function get buddyData():Array
		{
			return _buddyData;
		}

		public function get buddySortData():Array
		{
			return _buddyData.sortOn(['isOnline', 'userId'], [Array.DESCENDING, Array.CASEINSENSITIVE]);
		}

		public function isBuddy(userId:String):Boolean
		{
			for each(var buddy:Object in buddyData)
			{
				if (userId == buddy.userId)
				{
					return true;
				}
			}

			return false;
		}

		public function inRoom(userId:String):Boolean
		{
			var userName:String;
			for each(userName in _roomUser)
			{
				if (userId == userName)
				{
					return true;
				}
			}

			return false;
		}

		public function getSendObj(msg:String, mode:String):Object
		{
			var obj:Object;
			var index:int;

			if (msg)
			{
				obj = {};
				obj['to'] = '@All:';
				obj['msg'] = msg;

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
						obj['msg'] = msg.substr(index + 1);
						obj['to'] = msg.substring(0, index + 1);

						if (msg.substring(1, index).toUpperCase() != 'ALL')
						{
							if (mode == ChatManager.PUBLIC_MESSAGE)
							{
								obj['msg'] = msg;
							}

							obj['recipient'] = msg.substr(1, index - 1);
						}
					}
				}

				obj['type'] = mode;
			}

			return obj;
		}

		private function replaceStr(str:String):String
		{
			if (str)
			{
				str = str.replace(/&/g, '&amp;');
				str = str.replace(/>/g, '&gt;');
				str = str.replace(/</g, '&lt;');
				str = str.replace(/ /g, '&nbsp;');
				str = str.replace(/\"/g, '&quot;');
				str = str.replace(/\\n/g, '<BR/>');
			}

			return str;
		}

		public function getBuddyTxt():String
		{
			var tf:TextField = new TextField();
			var index:int = 0;
			var len:int = buddySortData.length;
			var buddyObj:Object;

			tf.text = '';

			for (index; index < len; index++)
			{
				buddyObj = buddySortData[index];

				if (index)
				{
					tf.appendText('<BR/><BR/>');
				}

				tf.appendText('<TEXTFORMAT LEFTMARGIN="10">');

				if (buddyObj.isOnline)
				{
					tf.appendText('<FONT COLOR="#5F87FF"><B><A HREF="EVENT:BUDDY_');
					tf.appendText(buddyObj.userId);
					tf.appendText('">» ');
					tf.appendText(buddyObj.userId);
					tf.appendText('</A></B></FONT>');
				}else
				{
					tf.appendText('<FONT SIZE="12" COLOR="#B2B2B2">');
					tf.appendText(buddyObj.userId);
					tf.appendText('</FONT>');
				}

				tf.appendText('<FONT SIZE="12" COLOR="#B2B2B2"><B>&nbsp;&nbsp;[</B></FONT>');
				tf.appendText('<FONT SIZE="10" COLOR="#AF0000"><B><A HREF="EVENT:REMOVE_');
				tf.appendText(buddyObj.userId);
				tf.appendText('">DEL');

				if (buddyObj.isOnline)
				{

					tf.appendText('</A></B></FONT>');
					tf.appendText('<FONT SIZE="12" COLOR="#B2B2B2"><B>&nbsp;|&nbsp;</B></FONT>');
					tf.appendText('<FONT SIZE="10" COLOR="#00AFFF"><B><A HREF="EVENT:JBR_');
					tf.appendText(buddyObj.userId);
					tf.appendText('">JBR');
				}

				tf.appendText('</A></B></FONT>');
				tf.appendText('<FONT SIZE="12" COLOR="#B2B2B2"><B>]</B></FONT></TEXTFORMAT>');
			}

			return tf.text;
		}

		public function getUserTxt():String
		{
			var tf:TextField = new TextField();
			var index:int = 0;
			var len:int = roomUser.length;
			var userObj:Object;

			tf.text = '';

			for (index; index < len; index++)
			{
				userObj = roomUser[index];

				if (index)
				{
					tf.appendText('<BR/><BR/>');
				}

				tf.appendText('<TEXTFORMAT LEFTMARGIN="20">');
				tf.appendText('<FONT COLOR="#D7AF00"><B><A HREF="EVENT:USER_');
				tf.appendText(userObj.userId);
				tf.appendText('">» ');
				tf.appendText(userObj.userId);
				tf.appendText('</A></B></FONT>');
				if (isBuddy(userObj.userId))
				{
					tf.appendText('<FONT SIZE="12" COLOR="#B2B2B2"><B>&nbsp;&nbsp;[</B></FONT>');
					tf.appendText('<FONT SIZE="10" COLOR="#00D75F"><B>');
					tf.appendText('^_^');
					tf.appendText('</B></FONT>');
					tf.appendText('<FONT SIZE="12" COLOR="#B2B2B2"><B>]</B></FONT></TEXTFORMAT>');
				}else
				{
					tf.appendText('<FONT SIZE="12" COLOR="#B2B2B2"><B>&nbsp;&nbsp;[</B></FONT>');
					tf.appendText('<FONT SIZE="10" COLOR="#00AFFF"><B><A HREF="EVENT:ADD_');
					tf.appendText(userObj.userId);
					tf.appendText('">ADD');
					tf.appendText('</A></B></FONT>');
					tf.appendText('<FONT SIZE="12" COLOR="#B2B2B2"><B>]</B></FONT></TEXTFORMAT>');
				}
			}

			return tf.text;
		}

		public function getRoomTxt():String
		{
			var roomList:Array = [{name:'room_1'}, {name:'room_2'}, {name:'room_3'}];

			if (!roomList)
			{
				return '';
			}

			var tf:TextField = new TextField();
			var index:int = 0;
			var len:int = roomList.length;
			var roomName:String;

			tf.text = '';

			for (index; index < len; index++)
			{
				roomName = roomList[index].name;

				if (index)
				{
					tf.appendText('<BR/><BR/>');
				}

				tf.appendText('<TEXTFORMAT LEFTMARGIN="10"><FONT COLOR="');

				if(ChatManager.singleton.currRoom && roomName == ChatManager.singleton.currRoom.name)
				{
					tf.appendText('#00D75F');
					tf.appendText('"><B>~ ');
				}else
				{
					tf.appendText('#00AFFF');
					tf.appendText('"><B><A HREF="EVENT:ROOM_');
					tf.appendText(roomName);
					tf.appendText('">+ ');
				}

				tf.appendText(roomName);
				tf.appendText('</A></B></FONT></TEXTFORMAT>');

				if (roomUser.length && ChatManager.singleton.currRoom && roomName == ChatManager.singleton.currRoom.name)
				{
					tf.appendText('<BR/><BR/>');
					tf.appendText(getUserTxt());
				}
			}

			return tf.text;
		}

		public function getChatTxt():String
		{
			var msgObj:Object;
			var index:int = 0;
			var len:int = chatData.length;
			var tf:TextField = new TextField();
			var isMe:Boolean;

			tf.text = '';

			if (chatData.length > 30)
			{
				index = chatData.length - 30;
			}

			for (index; index < len; index++)
			{
				msgObj = chatData[index];

				if (!msgObj)
				{
					continue;
				}

				isMe = msgObj.senderData.isMe;

				if (index)
				{
					tf.appendText('<BR/><BR/>');
				}

				tf.appendText('<FONT COLOR=');
				if (isMe)
				{
					if (msgObj.type == ChatManager.PUBLIC_MESSAGE)
					{
						tf.appendText('"#00AFFF"><B>You');
					}else if (msgObj.type == ChatManager.PRIVATE_MESSAGE)
					{
						tf.appendText('"#D75FD7"><B>You');
					}else if (msgObj.type == ChatManager.BUDDY_MESSAGE)
					{
						tf.appendText('"#5F87FF"><B>You');
					}
				}else
				{
					tf.appendText('"#D7AF00"><B>');

					if (msgObj.type == ChatManager.BUDDY_MESSAGE)
					{
						tf.appendText('<A HREF="EVENT:BUDDY_');
					}else
					{
						tf.appendText('<A HREF="EVENT:USER_');
					}

					tf.appendText(msgObj.senderData.userId);
					tf.appendText('">');
					tf.appendText(msgObj.senderData.userId);
					tf.appendText('</A>');
				}
				tf.appendText('</B></FONT><FONT COLOR=');

				if (msgObj.type == ChatManager.PUBLIC_MESSAGE)
				{
					tf.appendText('"#00D75F"><B>@All:</B></FONT><BR/>');
					tf.appendText('<TEXTFORMAT LEFTMARGIN="30" RIGHTMARGIN="30">');
					tf.appendText('<FONT COLOR=');
					if (isMe)
					{
						tf.appendText('"#00AFFF">');
					}else
					{
						tf.appendText('"#00D75F">');
					}
					tf.appendText(replaceStr(msgObj.msgData));
					tf.appendText('</FONT></TEXTFORMAT>');
				}else if (msgObj.type == ChatManager.PRIVATE_MESSAGE)
				{
					if (isMe)
					{
						tf.appendText('"#D7AF00"><B>@');
						tf.appendText('<A HREF="EVENT:USER_');
						tf.appendText(msgObj.recipient);
						tf.appendText('">');
						tf.appendText(msgObj.recipient);
						tf.appendText('</A>:');
					}else
					{
						tf.appendText('"#D75FD7"><B>@You:');
					}
					tf.appendText('</B></FONT><BR/>');
					tf.appendText('<TEXTFORMAT LEFTMARGIN="30" RIGHTMARGIN="30">');
					tf.appendText('<FONT COLOR="#D75FD7">');
					tf.appendText(replaceStr(msgObj.msgData));
					tf.appendText('</FONT></TEXTFORMAT>');
				}else if (msgObj.type == ChatManager.BUDDY_MESSAGE)
				{
					if (isMe)
					{
						tf.appendText('"#D7AF00"><B>@');
						tf.appendText('<A HREF="EVENT:BUDDY_');
						tf.appendText(msgObj.recipient);
						tf.appendText('">');
						tf.appendText(msgObj.recipient);
						tf.appendText('</A>:');
					}else
					{
						tf.appendText('"#5F87FF"><B>@You:');
					}
					tf.appendText('</B></FONT><BR/>');
					tf.appendText('<TEXTFORMAT LEFTMARGIN="30" RIGHTMARGIN="30">');
					tf.appendText('<FONT COLOR="#5F87FF">');
					tf.appendText(replaceStr(msgObj.msgData));
					tf.appendText('</FONT></TEXTFORMAT>');
				}
			}

			return tf.text;
		}

		public function trim(str:String):String
		{
			var i:int;
			var c:String;

			for (i=0; i<str.length; i++)
			{
				if (blankStr.indexOf(str.charAt(i)) == -1)
				{
					break;
				}
			}

			str = str.substr(i);

			for (i=str.length; i>=0; i--)
			{
				if (blankStr.indexOf(str.charAt(i)) == -1)
				{
					break;
				}
			}

			str = str.slice(0, i + 1);

			var reg1:RegExp = /^\s*/g;
			var reg2:RegExp = /\s*$/g;
			return str.replace(reg1, '').replace(reg2, '');
		}

		public function enableIME():void
		{
			if (Capabilities.hasIME)
			{
				IME.enabled = true;

				switch (IME.conversionMode)
    			{
    			    case IMEConversionMode.CHINESE:
						try
    					{
    					    IME.enabled = true;
    					    IME.conversionMode = IMEConversionMode.ALPHANUMERIC_HALF;
    					}
    					catch (error:Error)
    					{
    					}
    			        break;
    			    case IMEConversionMode.ALPHANUMERIC_FULL:
						try
    					{
    					    IME.enabled = true;
    					    IME.conversionMode = IMEConversionMode.ALPHANUMERIC_HALF;
    					}
    					catch (error:Error)
    					{
    					}
    			        break;
    			    case IMEConversionMode.JAPANESE_HIRAGANA:
						try
    					{
    					    IME.enabled = true;
    					    IME.conversionMode = IMEConversionMode.ALPHANUMERIC_HALF;
    					}
    					catch (error:Error)
    					{
    					}
    			        break;
    			    case IMEConversionMode.JAPANESE_KATAKANA_FULL:
						try
    					{
    					    IME.enabled = true;
    					    IME.conversionMode = IMEConversionMode.ALPHANUMERIC_HALF;
    					}
    					catch (error:Error)
    					{
    					}
    			        break;
    			    case IMEConversionMode.KOREAN:
						try
    					{
    					    IME.enabled = true;
    					    IME.conversionMode = IMEConversionMode.ALPHANUMERIC_HALF;
    					}
    					catch (error:Error)
    					{
    					}
    			        break;
    			    default:
						IME.enabled = true;
    			        break;
    			}
			}
		}

		public function disableIME():void
		{
			if (Capabilities.hasIME)
			{
				IME.enabled = false;
			}
		}
	}
}
