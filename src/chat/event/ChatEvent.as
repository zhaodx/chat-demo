package chat.event
{
	import flash.events.Event;

	public class ChatEvent extends Event
	{
		protected var dataObj:Object;

		public static const SYS_LOGIN:String = 'sys_login';
		public static const SYS_DISCONN:String = 'sys_disconn';
		public static const SYS_RECONN:String = 'sys_reconn';
		public static const SYS_MESSAGE:String = 'sys_message';
		public static const SYS_HISTORY_MESSAGE:String = 'sys_history_message';
		public static const SYS_ROOMJOIN:String = 'sys_joinroom';
		public static const SYS_ROOMLEAVE:String = 'sys_leaveroom';
		public static const SYS_AUTO_ROOMJOIN_ERROR:String = 'sys_auto_joinroom_error';
		public static const SYS_JOIN_BUDDY_ROOM:String = 'sys_join_buddy_room';
		public static const SYS_USER_ENTERROOM:String = 'sys_user_enterroom';
		public static const SYS_USER_EXITROOM:String = 'sys_user_exitroom';
		public static const SYS_BUDDY_LIST_INIT:String = 'sys_buddy_list_init';
		public static const SYS_BUDDY_ERROR:String = 'sys_buddy_error';
		public static const SYS_BUDDY_ADD:String = 'sys_buddy_add';
		public static const SYS_BUDDY_REMOVE:String = 'sys_buddy_remove';
		public static const SYS_BUDDY_ONLINE_STATE_UPDATE:String = 'sys_buddy_online_state_update';
		public static const SYS_BUDDYVARS_UPDATE:String = 'sys_buddyvars_update';
		public static const SYS_USERVARS_UPDATE:String = 'sys_uservars_update';
		public static const SYS_SERVER_PUSH:String = 'sys_server_push';

		public function ChatEvent(type:String, obj:Object=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);

			dataObj = obj;
		}

		public function get data():Object
		{
			return dataObj;
		}
	}
}
