package chat.system.pnb
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;

	import chat.ChatManager;

	public class Pubnub
	{
		private var _unsub:Function

		public function Pubnub(mainClass:String)
		{
			callJS('AS3_PNB.setMovieName', mainClass);
		}

		public function init(config:Object):void
		{
			callJS('AS3_PNB.init', config);
		}

		public function addEvent():void
		{
			if (ExternalInterface.available)
			{
				ExternalInterface.addCallback('as_response', js_response);
			}
		}

		public function js_request(args:Object):void
		{
			callJS('AS3_PNB.as_request', args);
		}

		private function js_response(args:Object):void
		{
			OpManager.singleton.doResult(args);
		}

		private function callJS(funName:String, args:Object=null):void
		{
			if (ExternalInterface.available)
			{
				ExternalInterface.call(funName, args);
			}
		}

		public function messageStore(param:Object):void
		{
			//'https://slot-chatlog.socialgamenet.com/api/index.php';
			//'https://fantasyslot-dev.socialgamenet.com/chatlog';
			//'https://slot-us.socialgamenet.com/chatlog';

			if (param && param.timeStamp && ChatManager.singleton.log_url)
			{
				var url:String = ChatManager.singleton.log_url + 'chatlog';

				var sendParam : Object = {};

				sendParam['cmd'] = 'log';
				sendParam['params'] = 'mn=chatlog&ts='
									+ param.timeStamp
									+ '&d='
									+ JSON.stringify(param.data);

				sendToServer(url, sendParam);
			}
		}

		private function sendToServer(url:String, params:Object):void
		{
			var op:Operation = new Operation();
			OpManager.singleton.addOperation(op);

			op.addTodo(
				function ():void
				{
					var opKey:String = op.name;
					var loader:URLLoader = new URLLoader();
					var request:URLRequest = new URLRequest(url);
					request.method = 'POST';
					request.data = makeVars(params);
					loader.addEventListener(Event.COMPLETE, function (event:Event):void
					{
						OpManager.singleton.doResult({op_key:opKey});
					});

					loader.load(request);
				},
				function (data:Object):void
				{
					if (!data.op_status)
					{
						return;
					}

					op.dispose();

					ChatManager.singleton.showMsg('messageStore', data);
				}
			);
		}

		private function makeVars(paramDict:Object):URLVariables
		{
			var key:String;
			var urlVars:URLVariables;

			if (paramDict)
			{
				urlVars = new URLVariables();

				for (key in paramDict)
				{
					urlVars[key] = paramDict[key];
				}
			}

			return urlVars;
		}
	}
}
