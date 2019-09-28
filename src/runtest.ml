(** Pipeline term running test *)

module Docker = Current_docker.Default

type desc = No  (** Disabled *) | Dune  (** Using dune *)

(** [build_img] is expected to contains the repo built *)
let v ~build_img = function
  | No -> None
  | Dune -> Some (Docker.run build_img ~args:[ "dune"; "runtest" ])
