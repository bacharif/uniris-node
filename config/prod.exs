use Mix.Config

# Do not print debug messages in production
config :logger, level: :info

# Networking module configuration:
# load_from_system_env - false if not defined
# ip_provider options: Uniris.Networking.IPLookup.Static, Uniris.Networking.IPLookup.Ipify, 
# hostname - provides a constant IP address for Static
# port - provides a P2P port number
config :uniris, Uniris.Networking, ip_provider: Uniris.Networking.IPLookup.Static

config :uniris, Uniris.Bootstrap, ip_lookup_provider: Uniris.Bootstrap.IPLookup.IPFYImpl

config :uniris, Uniris.Bootstrap.Sync,
  # 15 days
  out_of_sync_date_threshold: 54_000

config :uniris, Uniris.Bootstrap.NetworkInit,
  # TODO: provide the true addresses for the genesis UCO distribution
  genesis_pools: [
    funding: [
      public_key: "002E354A95241E867C836E8BBBBF6F9BF2450860BA28B1CF24B734EF67FF49169E",
      amount: 3.82e9
    ],
    deliverable: [
      public_key: "00AD439F0CD4048576D4AFB812DCB1815C57EFC303BFF03696436B157C69547128",
      amount: 2.36e9
    ],
    enhancement: [
      public_key: "008C9309535A3853379D6367F67AB93E3DAF5BFAA41C68BD7C3C1F00AA8D5822FD",
      amount: 9.0e8
    ],
    team: [
      public_key: "00B1F862FF9E534DAC6A0AD32528E08F7BB0F3DD0DCB253B119900F4CE447C5CC4",
      amount: 5.6e8
    ],
    exchange: [
      public_key: "004CD06F40D2F75DA02B29D559A3CBD5E07580B1E65163A4F3256CDC8781B280E3",
      amount: 3.4e8
    ],
    marketing: [
      public_key: "00783510644E885FFAC82FE22FB3F33C5B0936B79B7A3D3A78D5D612341A0B3B9A",
      amount: 3.4e8
    ],
    foundation: [
      public_key: "00CD534224DE5AE2584163D69A8A99F36E6FAE506373B619736B511A58B804E311",
      amount: 2.2e8
    ]
  ]

config :uniris, Uniris.BeaconChain.SlotTimer,
  # Every 10 minutes at the 50th second
  interval: "50 */10 * * * * *"

config :uniris, Uniris.BeaconChain.SummaryTimer,
  # Every day at midnight at the 50th second
  interval: "50 0 0 * * * *"

# TODO: specify the crypto implementation using hardware when developed
config :uniris, Uniris.Crypto.Keystore, impl: Uniris.Crypto.SoftwareKeystore

config :uniris, Uniris.DB, impl: Uniris.DB.CassandraImpl

config :uniris, Uniris.DB.KeyValueImpl, root_dir: "priv/storage"

config :uniris, Uniris.Governance.Pools,
  # TODO: provide the true addresses of the members
  initial_members: [
    technical_council: [],
    ethical_council: [],
    foundation: [],
    uniris: []
  ]

config :uniris, Uniris.SharedSecrets.NodeRenewalScheduler,
  # Every day at midnight at the 50th second
  interval: "50 0 0 * * * *"

config :uniris, Uniris.SelfRepair.Sync, last_sync_file: "priv/p2p/last_sync"

config :uniris, Uniris.SelfRepair.Scheduler,
  # Every day at midnight
  interval: "0 0 0 * * * *"

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :uniris, UnirisWeb.Endpoint,
  http: [:inet6, port: 80],
  url: [host: "*", port: 443],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Application.spec(:uniris, :vsn),
  check_origin: false,
  https: [
    port: 443,
    cipher_suite: :strong,
    keyfile: System.get_env("UNIRIS_WEB_SSL_KEY_PATH"),
    certfile: System.get_env("UNIRIS_WEB_SSL_CERT_PATH"),
    transport_options: [socket_opts: [:inet6]]
  ]

# force_ssl: [hsts: true]
