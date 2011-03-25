-module(dumpd).
-export([start/0,listen/0,listen/1,listen/2, listen/3]).

%-define(DEFAULT_TCPOPTS, [
%	list,
%	{packet, raw},
%	{header, 0},
%	{active, false},
%	{verify, verify_none},
%	{certfile, "./cert.pem"}
%	]).
%
-define(DEFAULT_TCPOPTS, [
	{verify, 0},
	{active, false},
	{certfile, "/Users/wolf/Projects/ThoughtExperiments/cert.pem"}
	]).


-define(DEFAULT_PORT, 443).


start()->
	application:start(crypto),
	application:start(ssl),
	ssl:seed("rttflagdfttidppohjeh"),
	listen(true).

% Call echo:listen(Port) to start the service.
listen() ->
	listen(?DEFAULT_PORT, ?DEFAULT_TCPOPTS, false).


listen(true) ->
	listen(?DEFAULT_PORT, ?DEFAULT_TCPOPTS, true);

listen(Port) ->
	listen(Port, ?DEFAULT_TCPOPTS, false).

listen(Port, true) ->
	listen(Port, ?DEFAULT_TCPOPTS, true).

listen(Port, TcpOpts, false = UseSSL) ->
    {ok, LSocket} = gen_tcp:listen(Port, TcpOpts),
    io:format("Now listening on port ~p, using following TCP options: ~p, and SSL flag set to ~p", [Port, TcpOpts, UseSSL]),
    accept(LSocket);
listen(Port, TcpOpts, true = UseSSL) ->
    io:format("Attempting to use SSL"),
    case ssl:listen(Port, TcpOpts) of
	{ok, LSocket} ->
    		io:format("Now listening on port ~p, using following TCP options: ~p, and SSL flag set to ~p", [Port, TcpOpts, UseSSL]),
    		ssl_accept(LSocket);
	{error, Reason} ->
		io:format("ssl:listen returned error code of ~p", [Reason])
   end.



% Wait for incoming connections and spawn the echo loop when we get one.
accept(LSocket) ->
    {ok, Socket} = gen_tcp:accept(LSocket),
    spawn(fun() -> loop(Socket, gen_tcp) end),
    accept(LSocket).

ssl_accept(LSocket) ->
    case ssl:transport_accept(LSocket) of
    	{ok, TSocket} -> case ssl:ssl_accept(TSocket) of
    		ok ->
    			spawn(fun() -> loop(TSocket, ssl) end),
    			ssl_accept(LSocket);
		SslErr -> 
			Msg = io_lib:format("Error, ssl:ssl_accept returned ~p", [SslErr]),
			error_logger:error_msg(Msg),
			exit(Msg)
		end;
	TransportErr -> 
		Msg = io_lib:format("Error, ssl:transport_accept returned ~p", [TransportErr]),
		error_logger:error_msg(Msg),
		exit(Msg)
	end.

% Echo back whatever data we receive on Socket.
loop(Socket, Mod) ->
    case Mod:recv(Socket, 0) of
        {ok, Data} ->
	    io:format("Socket received data...~n~p~n", [Data]),
            loop(Socket, Mod);
        {error, closed} ->
	    io:format("Socket closed."),
            ok
    end.
