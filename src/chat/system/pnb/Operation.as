package chat.system.pnb
{
	//import chat.ChatManager;

	public class Operation
	{
		public static const OP_DISPOSE:int = 0;
		public static const OP_WAITING:int = 1;
		public static const OP_DOING:int = 2;
		public static const OP_PENDING:int = 3;

		private var _status:int;
		private var _todo:Function;
		private var _callback:Function;
		private var _name:String;

		public function Operation()
		{
			_status = -1;
		}

		public function addTodo(todo:Function, callback:Function):void
		{
			if (_todo == null)
			{
				_todo = todo;
				_callback = callback;
				_status = OP_WAITING;
			}
		}

		public function doFuntion(ct:int):void
		{
			if (_status == OP_WAITING)
			{
				try
				{
					_status = OP_DOING;
					_todo && _todo();
				}catch(e:Error)
				{
					_status = OP_DISPOSE;
					_callback && _callback({error:e});
				}
			}
		}

		public function doResult(data:Object):void
		{
			if (_status == OP_DOING || _status == OP_PENDING)
			{
				if (_status != OP_PENDING)
				{
					_status = OP_PENDING;
				}

				_callback && _callback(data);
			}
		}

		public function dispose():void
		{
			_todo = null;
			_callback = null;
			_status = OP_DISPOSE;
		}

		public function get status():int
		{
			return _status;
		}

		public function set name(v:String):void
		{
			_name = v;
		}

		public function get name():String
		{
			return _name;
		}
	}
}
