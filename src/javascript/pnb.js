var AS3_PNB = function ()
{
	var config = null;
	var movieName = null;
	var pubnub = null;

	//-------------------------------------------init----------------------------------------------
	this.init = function (args)
	{
		config = args;
		config['ssl'] = true;
		config['jsonp'] = true;
		config['keepalive'] = 20;
		config['windowing'] = 1000;

		pubnub = PUBNUB.init(config);
	}

	//-------------------------------------------swf_name-------------------------------------------
	this.setMovieName = function(name)
	{
		movieName = name;
	}

	//-------------------------------------------request----------------------------------------------
	this.as_request = function (args)
	{
		switch(args.reuest_type)
		{
			case 'subscribe':
				subscribe(args);
				break;

			case 'unsubscribe':
				unsubscribe(args);
				break;

			case 'publish':
				publish(args);
				break;

			case 'here_now':
				here_now(args);
				break;

			default:
				console.log('reuest_type does not exit!');
		}
	}

	//-------------------------------------------response----------------------------------------------
	var as_response = function (args)
	{
		console.log(args);

		if (movieName)
		{
			getSwfInstance(movieName).as_response(args);
		}
	}

	//-------------------------------------------subscribe----------------------------------------------
	var subscribe = function (args)
	{
		var subscribe_args = {
			channel: args.channel,
			restore: true,
			connect: function (message)
			{
				as_response({op_key:args.op_key, channel:args.channel, message:message, response_type:'connect'});
			},
			disconnect: function (message)
			{
				as_response({op_key:args.op_key, channel:args.channel, message:message, response_type:'disconnect'});
			},
			reconnect: function (message)
			{
				as_response({op_key:args.op_key, channel:args.channel, message:message, response_type:'reconnect'});
			},
			callback: function (message)
			{
				as_response({op_key:args.op_key, channel:args.channel, message:message, response_type:'callback'});
			}
		};
		pubnub.subscribe(subscribe_args);
	}

	//-------------------------------------------unsubscribe----------------------------------------------
	var unsubscribe = function (args)
	{
		pubnub.unsubscribe({
     		channel : args.channel, //Array String
		});
	}

	//-------------------------------------------publish----------------------------------------------
	var publish = function (args)
	{
		var publish_args = {
			publish_key: config.publish_key,
			channel: args.channel,
			message: args.message,
			callback: function (message)
			{
				as_response({op_key:args.op_key, channel:args.channel, message:message, response_type:'callback'});
			}
		};

		pubnub.publish(publish_args);
	}

	//-------------------------------------------here_now----------------------------------------------
	var here_now = function (args)
	{
		var here_now_args = {
     		channel: args.channel, //String
     		callback: function (message)
			{
				as_response({op_key:args.op_key, channel:args.channel, message:message, response_type:'callback'});
			}
		};

		pubnub.here_now(here_now_args);
	}

	return this;
}();

function getSwfInstance(swf)
{
	if (navigator.appName.indexOf('Microsoft') != -1)
	{
		return window[swf];
	}

	return document[swf];
}
