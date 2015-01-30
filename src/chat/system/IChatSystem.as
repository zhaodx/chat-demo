package chat.system
{
	public interface IChatSystem
	{
		function process():void;

		function doConnect():void;

		function leaveRoom(roomId:String):void;

		function joinRoom(roomId:String):void;

		function autoJoinRoom(group:String, roomId:String=null):void;

		//function joinBuddyRoom(userId:String):void;

		function sendPublicMsg(msg:String, params:Object=null):void;

		function sendPrivateMsg(msg:String, toId:String, params:Object=null):Boolean;

		function sendBuddyMsg(msg:String, toId:String, params:Object=null):Boolean;

		function extRequest(extCmd:String, params:Object=null):void;

		function get currRoomObj():Object;

		function get config():Object;

		function set configPath(filePath:String):void;

		function get isConnected():Boolean;

		function roomListFromGroup(groupId:String):Array;

		function initBuddyList(buddyList:Array=null):void;

		function addBuddy(userId:String):void;

		function removeBuddy(userId:String):void;

		function setMyVars(userVars:Object):void;
	}
}
