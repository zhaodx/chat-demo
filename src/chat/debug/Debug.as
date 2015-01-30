package chat.debug
{
	import flash.external.ExternalInterface;

	/**
	 * Debug功能
	 */
	public class Debug
	{

		public static function consoleObj(debugObj:Object, debugRoot:String='root'):void
		{
			var debugMsg:String = '\n'+ encodeObject(debugObj, '        ' + debugRoot);
			consoleStr(debugMsg);
		}

        public static function consoleStr(debugMsg:String):void
		{
			trace(debugMsg);

			if(ExternalInterface.available)
			{
				ExternalInterface.call('console.log', debugMsg);
			}
		}

		private static function encodeObject(debugObj:Object, debugRoot:String):String
		{
			var resultStr:String = '';
			var childObj:*;

			for(var i : String in debugObj)
			{
				childObj = debugObj[i];

				if(typeof childObj == 'object')
				{
					if(debugObj is Array)
					{
						resultStr += encodeObject(childObj, debugRoot + '[' + i + ']');
					}else
					{
						resultStr += encodeObject(childObj, debugRoot + '.' + i);
					}
				}else
				{
					if(debugObj is Array)
					{
						resultStr += (debugRoot + '[' + i + ']=' + childObj) + '\n';
					}else
					{
						resultStr += (debugRoot + '.' + i + '=' + childObj) + '\n';
					}
				}
			}

			return resultStr;
		}
	}
}
