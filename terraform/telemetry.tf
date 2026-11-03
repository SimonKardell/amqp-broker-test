resource "solacebroker_msg_vpn_telemetry_profile" "telemetry_profile" {
  msg_vpn_name                        = solacebroker_msg_vpn.dev.msg_vpn_name
  receiver_acl_connect_default_action = "allow"
  telemetry_profile_name              = "tracing-profile"
  trace_enabled                       = true
  receiver_enabled                    = true
  trace_send_span_generation_enabled  = true
}

resource "solacebroker_msg_vpn_telemetry_profile_trace_filter" "trace_filter" {
  depends_on             = [solacebroker_msg_vpn_telemetry_profile.telemetry_profile]
  msg_vpn_name           = solacebroker_msg_vpn.dev.msg_vpn_name
  telemetry_profile_name = solacebroker_msg_vpn_telemetry_profile.telemetry_profile.telemetry_profile_name
  trace_filter_name      = "trace_filter"
  enabled                = true
}

resource "solacebroker_msg_vpn_telemetry_profile_trace_filter_subscription" "trace_filter_subscription" {
  msg_vpn_name           = solacebroker_msg_vpn.dev.msg_vpn_name
  subscription           = ">"
  subscription_syntax    = "smf"
  telemetry_profile_name = solacebroker_msg_vpn_telemetry_profile.telemetry_profile.telemetry_profile_name
  trace_filter_name      = solacebroker_msg_vpn_telemetry_profile_trace_filter.trace_filter.trace_filter_name
}

resource "solacebroker_msg_vpn_client_username" "telemetry_client" {
  depends_on          = [solacebroker_msg_vpn_telemetry_profile.telemetry_profile]
  msg_vpn_name        = solacebroker_msg_vpn.dev.msg_vpn_name
  client_username     = "telemetry-client"
  password            = "telemetry-password"
  enabled             = true
  client_profile_name = "#telemetry-${solacebroker_msg_vpn_telemetry_profile.telemetry_profile.telemetry_profile_name}"
  acl_profile_name    = "#telemetry-${solacebroker_msg_vpn_telemetry_profile.telemetry_profile.telemetry_profile_name}"
}
