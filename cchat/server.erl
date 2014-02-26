-module(server).
-compile(export_all).
%-export([loop/2, initial_state/1]).

-include_lib("./defs.hrl").



loop(St, {connect, From, _Nick}) -> 
        St2 = St#server_st{users = [From | St#server_st.users], nicks = [_Nick | St#server_st.nicks]},
		case lists:member(From, St#server_st.users) of
			true ->
                {user_already_connected, St};
            false ->
                case lists:member( _Nick, St#server_st.nicks) of
                    true ->
                        {nick_exist, St};
                    false -> 
                        erlang:display(St2),
                        {ok, St2}
                end
		end;

loop(St, {disconnect, From, _Nick}) -> 
        case lists:member(From, St#server_st.users) of
            true ->
                    St2 = St#server_st{users = lists:delete(From, St#server_st.users),
                                        nicks = lists:delete(_Nick,St#server_st.nicks)},
                    {ok, St2}
        end;

		
loop(St, {join, From, _Channel, _Nick}) ->
        case lists:member(_Channel, St#server_st.channels) of
            false ->
                 Pid = spawn(fun() -> channel([_Nick]) end),
                 register(list_to_atom(_Channel), Pid), 
                 Pid ! {join, self(),  _Nick},
                 {ok, St#server_st{channels = [_Channel | St#server_st.channels]}};
            true -> 
                 Reply = whereis(list_to_atom(_Channel)) ! {join, self(), _Nick},
                 case Reply of
                     ok -> 
                        {ok, St};
                     user_already_joined -> 
                        {{error, user_already_joined, "You are already connected to that channel!"}, St}

                 end
        end;
loop(St, {leave, From, _Channel, _Nick}) ->
     case whereis(list_to_atom(_Channel)) ! {leave, self(), _Nick} of
         ok -> 
            {ok, St};
         user_not_joined -> 
            {{error, user_not_joined, "You are not in that channel!"}, St}
     end;

        
loop(St,{msg_from_GUI, From, Ref, _Channel, _Msg}) ->
    {ok, St}.
		%%%%%%TODO%%%%%

channel(Nicks) -> 
    receive 
       {join, From, Nick} -> 
            case lists:member(Nick, Nicks) of
                true -> 
                    From ! user_already_joined,
                    channel(Nicks);
                false -> 
                    channel([Nick | Nicks]),
                    From ! ok
            end;
       {leave, From, Nick} ->
            case lists:member(Nick, Nicks) of
                false -> 
                    From ! user_not_joined,
                    channel(Nicks);
                true -> 
                    channel(lists:delete(Nick)),
                    From ! ok
            end
    end.

initial_state(_Server) ->
    #server_st{name = _Server, users = [], nicks = [], channels=[]}.
