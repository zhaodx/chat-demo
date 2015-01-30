package chat.system.pnb
{
	import flash.utils.getTimer;
	import chat.ChatManager;

	public class OpManager
	{
		private static const DEALY:int = 200;
		private static var _instance:OpManager;

		private var _opList:Array;
		private var _index:Number;
		private var _stime:Number;
		private var _delList:Array;

		public function OpManager()
		{
			_index = 0;
			_stime = 0;
			_opList = [];
			_delList = [];
		}

		public static function get singleton():OpManager
		{
			if (!_instance)
			{
				_instance = new OpManager();
			}

			return _instance;
		}

		public function process():void
		{
			var ctime:Number = getTimer();
			var ct:int = int(ctime * 0.001);

			if (ctime - _stime < DEALY)
			{
				return;
			}

			_stime = ctime;

			if(_delList && _delList.length)
			{
				doRemove();
			}

			for each(var op:Operation in _opList)
			{
				switch(op.status)
				{
					case Operation.OP_DISPOSE:
						//ChatManager.singleton.showMsg('remove: ' + op.name)
						removeOperation(op);
						break;

					case Operation.OP_WAITING:
						//ChatManager.singleton.showMsg('do: ' + op.name)
						op.doFuntion(ct);
						break;
				}
			}
		}

		public function doResult(data:Object):void
		{
			var op:Operation = getOp(data.op_key);

			if (op)
			{
				data['op_status'] = true;
				op.doResult(data);
			}
		}

		public function addOperation(op:Operation):String
		{
			var key:String = getKey();
			op.name = key;

			_opList.push(op);
			return op.name;
		}

		public function removeOperation(op:Operation):void
		{
			if (op)
			{
				_delList.push(op.name);
			}
		}

		private function doRemove():void
		{
			var index:int;
			var op:Operation;

			//ChatManager.singleton.showMsg('_delList.length: ' + _delList.length)
			//ChatManager.singleton.showMsg('_opList.length: ' + _opList.length)
			for each(var key:String in _delList)
			{
				op = getOp(key);

				if (op)
				{
					index = _opList.indexOf(op);

					if (index != -1)
					{
						_opList.splice(index, 1);
					}

					op.dispose();
				}
			}

			_delList = [];
			//ChatManager.singleton.showMsg('_opList.length:: ' + _opList.length)
		}

		private function getKey():String
		{
			_index++;

			return new Date().getTime() + '_OP_' + _index;
		}

		public function getOp(key:String):Operation
		{
			for each(var op:Operation in _opList)
			{
				if (key == op.name)
				{
					return op;
				}
			}

			return null;
		}

		public function dispose():void
		{
			for each(var op:Operation in _opList)
			{
				op.dispose();
			}

			_opList = [];
			_delList = [];
			_index = 0;
			_stime = 0;
		}
	}
}
