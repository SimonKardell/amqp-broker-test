terraform {
  required_providers {
    solacebroker = {
      source  = "SolaceProducts/solacebroker"
      version = "1.1.1"
    }
  }
}

provider "solacebroker" {
  username = "admin"
  password = "password"
  url = var.broker_url
}

resource "solacebroker_msg_vpn_acl_profile" "client" {
  msg_vpn_name                  = solacebroker_msg_vpn.dev.msg_vpn_name
  acl_profile_name              = "dev-acl-profile"
  client_connect_default_action = "allow"
}

resource "solacebroker_msg_vpn_acl_profile_publish_topic_exception" "pub_exceptions" {
  acl_profile_name               = solacebroker_msg_vpn_acl_profile.client.acl_profile_name
  msg_vpn_name                   = solacebroker_msg_vpn.dev.msg_vpn_name
  publish_topic_exception        = "*/>"
  publish_topic_exception_syntax = "smf"
}

resource "solacebroker_msg_vpn_acl_profile_subscribe_topic_exception" "sub_exceptions" {
  acl_profile_name                 = solacebroker_msg_vpn_acl_profile.client.acl_profile_name
  msg_vpn_name                     = solacebroker_msg_vpn.dev.msg_vpn_name
  subscribe_topic_exception        = "*/>"
  subscribe_topic_exception_syntax = "smf"
}


resource "solacebroker_msg_vpn_client_profile" "client" {
  msg_vpn_name        = solacebroker_msg_vpn.dev.msg_vpn_name
  client_profile_name = "user-profile"

  # Enable flow permissions
  allow_guaranteed_msg_send_enabled    = true
  allow_guaranteed_msg_receive_enabled = true

  # Set quota
  max_transacted_session_count = 10
  max_transaction_count        = 10
}


# Users
resource "solacebroker_msg_vpn_client_username" "user" {
  msg_vpn_name        = solacebroker_msg_vpn.dev.msg_vpn_name
  client_username     = "username"
  password            = "password"
  enabled             = true
  acl_profile_name    = solacebroker_msg_vpn_acl_profile.client.acl_profile_name
  client_profile_name = solacebroker_msg_vpn_client_profile.client.client_profile_name
}

resource "solacebroker_msg_vpn_client_username" "order_app_user" {
  msg_vpn_name        = solacebroker_msg_vpn.dev.msg_vpn_name
  client_username     = var.order_app_username
  password            = var.order_app_password
  enabled             = true
  acl_profile_name    = solacebroker_msg_vpn_acl_profile.client.acl_profile_name
  client_profile_name = solacebroker_msg_vpn_client_profile.client.client_profile_name
}


# Create a message-vpn on the event broker
resource "solacebroker_msg_vpn" "dev" {
  msg_vpn_name                        = var.message_vpn_name
  enabled                             = true
  max_msg_spool_usage                 = 200
  authentication_basic_enabled        = true
  authentication_basic_type           = "internal"
  service_amqp_plain_text_enabled     = true
  service_amqp_plain_text_listen_port = 4242
  service_amqp_tls_enabled            = true
  service_amqp_tls_listen_port        = 4243
}

# Queues

# Dead Message Queue
resource "solacebroker_msg_vpn_queue" "dmq" {
  msg_vpn_name        = solacebroker_msg_vpn.dev.msg_vpn_name
  queue_name          = "test_dmq"
  ingress_enabled     = true
  egress_enabled      = true
  owner               = "username"
  respect_ttl_enabled = true
}

resource "solacebroker_msg_vpn_queue" "main" {
  msg_vpn_name         = solacebroker_msg_vpn.dev.msg_vpn_name
  access_type          = "non-exclusive"
  queue_name           = "test_q"
  ingress_enabled      = true
  egress_enabled       = true
  dead_msg_queue       = solacebroker_msg_vpn_queue.dmq.queue_name
  max_redelivery_count = 3
  redelivery_enabled   = true
  owner                = "username"
  respect_ttl_enabled  = true
}

# Queue Subscription
resource "solacebroker_msg_vpn_queue_subscription" "subscription" {
  msg_vpn_name       = solacebroker_msg_vpn.dev.msg_vpn_name
  queue_name         = solacebroker_msg_vpn_queue.main.queue_name
  subscription_topic = "*/>"
}