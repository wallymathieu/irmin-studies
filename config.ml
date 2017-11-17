open Mirage

(* Command-line options *)

let port_k =
  let doc = Key.Arg.info ~doc:"Socket port." ["p"; "port"] in
  Key.(create "port" Arg.(opt int 8080 doc))

let tls_port_k =
  let doc = Key.Arg.info ~doc:"Enable TLS (using keys in `tls/`) on given port." ["tls"] in
  Key.(create "tls_port" Arg.(opt (some int) None doc))

(* Dependencies *)

let packages = [
  package "ptime";
  package ~min:"1.0.0" "irmin";
  package "irmin-mirage";
  package "mirage-http";
  package "mirage-flow";
  package ~sublibs:["mirage"] "tls";
  package ~min:"0.21.0" "cohttp";
  package "logs";
]


(* Network stack *)
let stack =
  if_impl Key.is_unix
    (socket_stackv4 [Ipaddr.V4.any])
    (generic_stackv4 default_network)

let () =
  let keys = Key.([
      abstract port_k;
      abstract tls_port_k;
    ])
  in
  register "irmin-studies" [
    foreign
      ~deps:[abstract nocrypto]
      ~keys
      ~packages
      "IrminStudies_main.Main"
      (stackv4 @-> resolver @-> conduit @-> pclock @-> kv_ro @-> job)
    $ stack
    $ resolver_dns stack
    $ conduit_direct ~tls:true stack
    $ default_posix_clock
    $ crunch "tls"
  ]
