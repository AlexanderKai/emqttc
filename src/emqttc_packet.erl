%%%-----------------------------------------------------------------------------
%%% Copyright (c) 2012-2016 eMQTT.IO, All Rights Reserved.
%%%
%%% Permission is hereby granted, free of charge, to any person obtaining a copy
%%% of this software and associated documentation files (the "Software"), to deal
%%% in the Software without restriction, including without limitation the rights
%%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%%% copies of the Software, and to permit persons to whom the Software is
%%% furnished to do so, subject to the following conditions:
%%%
%%% The above copyright notice and this permission notice shall be included in all
%%% copies or substantial portions of the Software.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
%%% SOFTWARE.
%%%-----------------------------------------------------------------------------
%%% @doc
%%% emqttc packet.
%%%
%%% @end
%%%-----------------------------------------------------------------------------

-module(emqttc_packet).

-author("Feng Lee <feng@emqtt.io>").

-include("emqttc_packet.hrl").

%% API
-export([protocol_name/1, type_name/1, connack_name/1]).

-export([dump/1]).

%%------------------------------------------------------------------------------
%% @doc Protocol name of version
%% @end
%%------------------------------------------------------------------------------
-spec protocol_name(mqtt_vsn()) -> binary().
protocol_name(Ver) when Ver =:= ?MQTT_PROTO_V31; Ver =:= ?MQTT_PROTO_V311->
    proplists:get_value(Ver, ?PROTOCOL_NAMES).

%%------------------------------------------------------------------------------
%% @doc Name of MQTT packet type
%% @end
%%------------------------------------------------------------------------------
-spec type_name(mqtt_packet_type()) -> atom().
type_name(Type) when Type > ?RESERVED andalso Type =< ?DISCONNECT ->
    lists:nth(Type, ?TYPE_NAMES).

%%------------------------------------------------------------------------------
%% @doc Connack Name
%% @end
%%------------------------------------------------------------------------------
-spec connack_name(mqtt_connack()) -> atom().
connack_name(?CONNACK_ACCEPT)       -> 'CONNACK_ACCEPT';
connack_name(?CONNACK_PROTO_VER)    -> 'CONNACK_PROTO_VER';
connack_name(?CONNACK_INVALID_ID )  -> 'CONNACK_INVALID_ID';
connack_name(?CONNACK_SERVER)       -> 'CONNACK_SERVER';
connack_name(?CONNACK_CREDENTIALS)  -> 'CONNACK_CREDENTIALS';
connack_name(?CONNACK_AUTH)         -> 'CONNACK_AUTH'.

%%------------------------------------------------------------------------------
%% @doc Dump packet
%% @end
%%------------------------------------------------------------------------------
-spec dump(mqtt_packet()) -> iolist().
dump(#mqtt_packet{header = Header, variable = Variable, payload = Payload}) ->
    dump_header(Header, dump_variable(Variable, Payload)).

dump_header(#mqtt_packet_header{type = Type,
                                dup = Dup,
                                qos = QoS,
                                retain = Retain}, S) ->
    S1 = if
             S == undefined -> <<>>;
             true           -> [", ", S]
         end,
    io_lib:format("~s(Q~p, R~p, D~p~s)", [type_name(Type), QoS, i(Retain), i(Dup), S1]).

dump_variable(undefined, _) ->
    undefined;
dump_variable(Variable, undefined) ->
    dump_variable(Variable);
dump_variable(Variable, Payload) ->
    io_lib:format("~s, Payload=~p", [dump_variable(Variable), Payload]).

dump_variable(#mqtt_packet_connect{
                 proto_ver     = ProtoVer,
                 proto_name    = ProtoName,
                 will_retain   = WillRetain,
                 will_qos      = WillQoS,
                 will_flag     = WillFlag,
                 clean_sess    = CleanSess,
                 keep_alive    = KeepAlive,
                 client_id     = ClientId,
                 will_topic    = WillTopic,
                 will_msg      = WillMsg,
                 username      = Username,
                 password      = Password}) ->
    Format = "ClientId=~s, ProtoName=~s, ProtoVsn=~p, CleanSess=~s, KeepAlive=~p, Username=~s, Password=~s",
    Args = [ClientId, ProtoName, ProtoVer, CleanSess, KeepAlive, Username, dump_password(Password)],
    {Format1, Args1} = if
                        WillFlag -> { Format ++ ", Will(Q~p, R~p, Topic=~s, Msg=~s)",
                                      Args ++ [WillQoS, i(WillRetain), WillTopic, WillMsg] };
                        true -> {Format, Args}
                       end,
    io_lib:format(Format1, Args1);

dump_variable(#mqtt_packet_connack{ack_flags   = AckFlags,
                                   return_code = ReturnCode}) ->
    io_lib:format("AckFlags=~p, RetainCode=~p", [AckFlags, ReturnCode]);

dump_variable(#mqtt_packet_publish{topic_name = TopicName,
                                   packet_id  = PacketId}) ->
    io_lib:format("TopicName=~s, PacketId=~p", [TopicName, PacketId]);

dump_variable(#mqtt_packet_puback{packet_id = PacketId}) ->
    io_lib:format("PacketId=~p", [PacketId]);

dump_variable(#mqtt_packet_subscribe{packet_id   = PacketId,
                                     topic_table = TopicTable}) ->
    io_lib:format("PacketId=~p, TopicTable=~p", [PacketId, TopicTable]);

dump_variable(#mqtt_packet_unsubscribe{packet_id = PacketId,
                                       topics    = Topics}) ->
    io_lib:format("PacketId=~p, Topics=~p", [PacketId, Topics]);

dump_variable(#mqtt_packet_suback{packet_id = PacketId,
                                  qos_table = QosTable}) ->
    io_lib:format("PacketId=~p, QosTable=~p", [PacketId, QosTable]);

dump_variable(#mqtt_packet_unsuback{packet_id = PacketId}) ->
    io_lib:format("PacketId=~p", [PacketId]);

dump_variable(PacketId) when is_integer(PacketId) ->
    io_lib:format("PacketId=~p", [PacketId]);

dump_variable(undefined) -> undefined.

dump_password(undefined) -> undefined;
dump_password(_)         -> <<"******">>.

i(true)  -> 1;
i(false) -> 0;
i(I) when is_integer(I) -> I.
