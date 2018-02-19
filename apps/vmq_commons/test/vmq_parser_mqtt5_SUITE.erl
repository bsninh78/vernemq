-module(vmq_parser_mqtt5_SUITE).

-compile(export_all).

-include_lib("common_test/include/ct.hrl").
-include("vmq_parser_mqtt5.hrl").

-import(vmq_parser_mqtt5, [enc_properties/1,
                           parse_properties/2]).

init_per_suite(Config) ->
    Config.

end_per_suite(_Config) ->
    ok.

init_per_testcase(_TestCase, Config) ->
    Config.

end_per_testcase(_TestCase, _Config) ->
    ok.

groups() ->
    [].

all() -> 
    [parse_unparse_tests,
     parse_unparse_properties_test,
     parse_unparse_publish_test,
     parse_unparse_puback_test,
     parse_unparse_pubrec_test,
     parse_unparse_pubrel_test,
     parse_unparse_pubcomp_test,
     parse_unparse_subscribe_test,
     parse_unparse_suback_test,
     parse_unparse_unsubscribe_test,
     parse_unparse_unsuback_test,
     parse_unparse_pingreq_test,
     parse_unparse_pingresp_test,
     parse_unparse_disconnect_test,
     parse_unparse_auth_test].

parse_unparse_tests(_Config) ->
    Properties = [#p_session_expiry_interval{value = 12341234}],
    Opts = [{properties, Properties}],
    parse_unparse("connect", vmq_parser_mqtt5:gen_connect("test-client", Opts)),

    parse_unparse("connack", vmq_parser_mqtt5:gen_connack()),
    parse_unparse("connack SP=0", vmq_parser_mqtt5:gen_connack(0)),
    parse_unparse("connack SP=1", vmq_parser_mqtt5:gen_connack(1)),
    parse_unparse("connack SP=0, RC=0", vmq_parser_mqtt5:gen_connack(0, ?M5_CONNACK_ACCEPT)),
    parse_unparse("connack SP=0, RC=16#81 (malformed packet)",
                  vmq_parser_mqtt5:gen_connack(0, ?M5_MALFORMED_PACKET)),
    ConnAckProps =
        [#p_session_expiry_interval{value=3600},
         #p_receive_max{value=10},
         #p_max_qos{value=1},
         #p_retain_available{value=true},
         #p_max_packet_size{value=1024},
         #p_assigned_client_id{value= <<"assigned_client_id">>},
         #p_topic_alias_max{value=100},
         #p_reason_string{value= <<"there's a reason!">>},
         #p_user_property{value={<<"key1">>, <<"val1">>}},
         #p_user_property{value={<<"key2">>, <<"val2">>}},
         #p_wildcard_subs_available{value=true},
         #p_sub_ids_available{value=true},
         #p_shared_subs_available{value=true},
         #p_server_keep_alive{value=10000},
         #p_response_info{value= <<"response information">>},
         #p_server_ref{value= <<"server reference">>},
         #p_authentication_method{value = <<"authentication method">>},
         #p_authentication_data{value = <<"authentication data">>}],
    parse_unparse("connack with properties", vmq_parser_mqtt5:gen_connack(0, ?M5_CONNACK_ACCEPT, ConnAckProps)).

parse_unparse_publish_test(_Config) ->
    parse_unparse("publish qos0", vmq_parser_mqtt5:gen_publish(<<"some/topic">>, 0, <<"payload">>, [])),
    parse_unparse("publish qos1", vmq_parser_mqtt5:gen_publish(<<"some/topic">>, 1, <<"payload">>, [{mid, 16}])),
    parse_unparse("publish qos2", vmq_parser_mqtt5:gen_publish(<<"some/topic">>, 2, <<"payload">>, [{mid, 32}])),

    Properties = [#p_payload_format_indicator{value=utf8},
                  #p_message_expiry_interval{value=3600},
                  #p_topic_alias{value=42},
                  #p_response_topic{value= <<"my/response/topic">>},
                  #p_correlation_data{value= <<"correlation data">>}],

    parse_unparse("publish with properties",
                  vmq_parser_mqtt5:gen_publish(<<"some/topic">>, 2, <<"payload">>, [{properties, Properties}])).

parse_unparse_puback_test(_Config) ->
    parse_unparse("puback", vmq_parser_mqtt5:gen_puback(5)),
    Properties = [#p_reason_string{value= <<"no subscribers for topic /topic">>},
                  #p_user_property{value={<<"key">>, <<"val">>}}],
    parse_unparse("puback with reason_code and properties",
                  vmq_parser_mqtt5:gen_puback(5, ?M5_NO_MATCHING_SUBSCRIBERS, Properties)).

parse_unparse_pubrec_test(_Config) ->
    parse_unparse("pubrec", vmq_parser_mqtt5:gen_pubrec(5)),
    Properties = [#p_reason_string{value= <<"no subscribers for topic /topic">>},
                  #p_user_property{value={<<"key">>, <<"val">>}}],
    parse_unparse("pubrec with reason_code and properties",
                  vmq_parser_mqtt5:gen_pubrec(5, ?M5_NO_MATCHING_SUBSCRIBERS, Properties)).

parse_unparse_pubrel_test(_Config) ->
    parse_unparse("pubrel", vmq_parser_mqtt5:gen_pubrel(5)),
    Properties = [#p_reason_string{value= <<"no subscribers for topic /topic">>},
                  #p_user_property{value={<<"key">>, <<"val">>}}],
    parse_unparse("pubrel with reason_code and properties",
                  vmq_parser_mqtt5:gen_pubrel(5, ?M5_NO_MATCHING_SUBSCRIBERS, Properties)).

parse_unparse_pubcomp_test(_Config) ->
    parse_unparse("pubcomp", vmq_parser_mqtt5:gen_pubcomp(5)),
    Properties = [#p_reason_string{value= <<"no subscribers for topic /topic">>},
                  #p_user_property{value={<<"key">>, <<"val">>}}],
    parse_unparse("pubcomp with reason_code and properties",
                  vmq_parser_mqtt5:gen_pubcomp(5, ?M5_NO_MATCHING_SUBSCRIBERS, Properties)).

parse_unparse_subscribe_test(_Config) ->
    Properties = [#p_subscription_id{value=45},
                  #p_user_property{value={<<"key">>, <<"val">>}}],
    Topics = [#mqtt5_subscribe_topic{
                 topic = <<"topic/0">>,
                 qos = 0,
                 no_local = false,
                 rap = false,
                 retain_handling = send_retain},
              #mqtt5_subscribe_topic{
                 topic = <<"topic/1">>,
                 qos = 1,
                 no_local = true,
                 rap = true,
                 retain_handling = send_if_new_sub},
              #mqtt5_subscribe_topic{
                 topic = <<"topic/2">>,
                 qos = 2,
                 no_local = false,
                 rap = false,
                 retain_handling = dont_send}],
    parse_unparse("subscribe with properties",
                  vmq_parser_mqtt5:gen_subscribe(6, Topics, Properties)).

parse_unparse_suback_test(_Config) ->
    Properties = [#p_reason_string{value= <<"a great reason">>},
                  #p_user_property{value={<<"key">>, <<"val">>}}],
    ReasonCodes = [?M5_GRANTED_QOS0, ?M5_GRANTED_QOS1, ?M5_GRANTED_QOS2,
                   ?M5_UNSPECIFIED_ERROR, ?M5_IMPL_SPECIFIC_ERROR, 
                   ?M5_NOT_AUTHORIZED, ?M5_TOPIC_FILTER_INVALID, 
                   ?M5_PACKET_ID_IN_USE, ?M5_QUOTA_EXCEEDED, 
                   ?M5_SHARED_SUBS_NOT_SUPPORTED, 
                   ?M5_SUBSCRIPTION_IDS_NOT_SUPPORTED, 
                   ?M5_WILDCARD_SUBS_NOT_SUPPORTED],
    parse_unparse("suback with properties",
                  vmq_parser_mqtt5:gen_suback(7, ReasonCodes, Properties)), 
    parse_unparse("suback",
                  vmq_parser_mqtt5:gen_suback(8, [?M5_GRANTED_QOS0], [])).

parse_unparse_unsubscribe_test(_Config) ->
    Properties = [#p_user_property{value={<<"key">>, <<"val">>}}],
    Topics = [<<"topic/0">>,
              <<"topic/#">>,
              <<"topic/+/1">>],
    parse_unparse("unsubscribe with properties",
                  vmq_parser_mqtt5:gen_unsubscribe(6, Topics, Properties)).

parse_unparse_unsuback_test(_Config) ->
    Properties = [#p_reason_string{value= <<"a great reason">>},
                  #p_user_property{value={<<"key">>, <<"val">>}}],
    ReasonCodes = [?M5_SUCCESS,
                   ?M5_NO_SUBSCRIPTION_EXISTED,
                   ?M5_UNSPECIFIED_ERROR,
                   ?M5_IMPL_SPECIFIC_ERROR,
                   ?M5_NOT_AUTHORIZED,
                   ?M5_TOPIC_FILTER_INVALID,
                   ?M5_PACKET_ID_IN_USE],
    parse_unparse("unsuback with properties",
                  vmq_parser_mqtt5:gen_unsuback(7, ReasonCodes, Properties)),
    parse_unparse("unsuback",
                  vmq_parser_mqtt5:gen_unsuback(8, [?M5_SUCCESS], [])).

parse_unparse_pingreq_test(_Config) ->
    parse_unparse("pingreq", vmq_parser_mqtt5:gen_pingreq()).

parse_unparse_pingresp_test(_Config) ->
    parse_unparse("pingresp", vmq_parser_mqtt5:gen_pingresp()).

parse_unparse_disconnect_test(_Config) ->
    Properties = [#p_session_expiry_interval{value=3600},
                  #p_reason_string{value= <<"a great reason">>},
                  #p_user_property{value={<<"key">>, <<"val">>}},
                  #p_server_ref{value= <<"some other server">>}],
    parse_unparse("disconnect with properties", vmq_parser_mqtt5:gen_disconnect(?M5_NORMAL_DISCONNECT, Properties)),
    parse_unparse("disconnect simple", vmq_parser_mqtt5:gen_disconnect()).

parse_unparse_auth_test(_Config) ->
    Properties = [#p_authentication_method{value= <<"auth method">>},
                  #p_authentication_data{value= <<"auth data">>},
                  #p_reason_string{value= <<"a great reason">>},
                  #p_user_property{value={<<"key">>, <<"val">>}}],
    parse_unparse("auth with properties", vmq_parser_mqtt5:gen_auth(?M5_SUCCESS, Properties)),
    parse_unparse("auth", vmq_parser_mqtt5:gen_auth()).

parse_unparse_properties_test(_Config) ->
    parse_unparse_property(#p_payload_format_indicator{value = utf8}),
    parse_unparse_property(#p_payload_format_indicator{value = unspecified}),

    parse_unparse_property(#p_message_expiry_interval{value = 123}),

    parse_unparse_property(#p_content_type{value = <<"some content type">>}),

    parse_unparse_property(#p_response_topic{value = <<"a response topic">>}),

    parse_unparse_property(#p_correlation_data{value = <<"correlation data">>}),

    parse_unparse_property(#p_subscription_id{value = 123412345}),

    parse_unparse_property(#p_session_expiry_interval{value = 123412345}),

    parse_unparse_property(#p_assigned_client_id{value = <<"assigned client id">>}),

    parse_unparse_property(#p_server_keep_alive{value = 3600}),

    parse_unparse_property(#p_authentication_method{value = <<"authentication method">>}),

    parse_unparse_property(#p_authentication_data{value = <<"authentication data">>}),

    parse_unparse_property(#p_request_problem_info{value = true}),
    parse_unparse_property(#p_request_problem_info{value = false}),

    parse_unparse_property(#p_will_delay_interval{value = 3600}),

    parse_unparse_property(#p_request_response_info{value = true}),
    parse_unparse_property(#p_request_response_info{value = false}),

    parse_unparse_property(#p_response_info{value = <<"response information">>}),

    parse_unparse_property(#p_server_ref{value = <<"server reference">>}),

    parse_unparse_property(#p_reason_string{value = <<"reason string">>}),

    parse_unparse_property(#p_receive_max{value = 65535}),

    parse_unparse_property(#p_topic_alias_max{value = 65535}),

    parse_unparse_property(#p_topic_alias{value = 65535}),

    parse_unparse_property(#p_max_qos{value = 0}),
    parse_unparse_property(#p_max_qos{value = 1}),

    parse_unparse_property(#p_retain_available{value = true}),
    parse_unparse_property(#p_retain_available{value = false}),

    parse_unparse_property(#p_user_property{value = {<<"key">>, <<"val">>}}),

    parse_unparse_property(#p_max_packet_size{value = 12341234}),

    parse_unparse_property(#p_wildcard_subs_available{value = true}),
    parse_unparse_property(#p_wildcard_subs_available{value = false}),

    parse_unparse_property(#p_sub_ids_available{value = true}),
    parse_unparse_property(#p_sub_ids_available{value = false}),

    parse_unparse_property(#p_shared_subs_available{value = true}),
    parse_unparse_property(#p_shared_subs_available{value = false}).

parse_unparse_property(Property) ->
    Encoded = enc_property_([Property]),
    [Parsed] = parse_properties(Encoded, []),
    compare_property(Property, Parsed).

enc_property_(Property) ->
    iolist_to_binary(enc_properties(Property)).

compare_property(P, P) -> true.

parse_unparse(Test, Frame) ->
    io:format(user, "parse/unparse: ~p~n", [Test]),
    {ParsedFrame, <<>>} = vmq_parser_mqtt5:parse(Frame),
    SerializedFrame = iolist_to_binary(vmq_parser_mqtt5:serialise(ParsedFrame)),
    compare_frame(Test, Frame, SerializedFrame).

compare_frame(_, F, F) -> true.