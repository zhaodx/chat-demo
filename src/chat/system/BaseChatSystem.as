package chat.system
{
	import flash.events.EventDispatcher;

	import chat.ChatManager;

	public class BaseChatSystem extends EventDispatcher
	{
		protected var _chatManager:ChatManager;

		public function BaseChatSystem()
		{
			_chatManager = ChatManager.singleton;
		}

		protected function init():void
		{

		}

		protected function addEvent():void
		{

		}

		protected function removeEvent():void
		{

		}

		protected function dispose():void
		{

		}
	}
}
