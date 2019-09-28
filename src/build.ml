(** Build pipeline term *)

module Docker = Current_docker.Default
open Current.Syntax

type desc = Dune  (** Using `dune build @install` *)

let docker_img ~repo base_img build_cmd =
  let dockerfile =
    let+ base_img = base_img in
    let open Dockerfile in
    from (Docker.Image.hash base_img)
    @@ copy ~src:[ "*.opam" ] ~dst:"./" ()
    @@ run "opam install --deps-only ."
    @@ copy ~src:[ "." ] ~dst:"./" ()
    @@ run build_cmd
  in
  Docker.build ~label:"build" ~pull:false ~dockerfile (`Git repo)

let v ~base_img ~repo = function
  | Dune -> docker_img ~repo base_img "dune build @install"
