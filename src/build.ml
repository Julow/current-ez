(** Build pipeline term *)

module Docker = Current_docker.Default
open Current.Syntax

type desc = Dune  (** Using `dune build @install` *)

let docker_img ~repo base_img build_cmd =
  let dockerfile =
    let+ base_img = base_img in
    let open Dockerfile in
    from (Docker.Image.hash base_img)
    @@ user "opam"
    @@ copy ~src:[ "*.opam" ] ~dst:"./" ()
    (* Using --fake because depext operate on installed packages
         An alternative would be to know the list of packages *)
    @@ run "opam install --fake --deps-only ."
    @@ run "opam depext --with-test"
    @@ run "opam remove --auto-remove"
    @@ run "opam install --deps-only --with-test ."
    @@ copy ~chown:"opam:opam" ~src:[ "." ] ~dst:"./" ()
    @@ run build_cmd
  in
  Docker.build ~label:"build" ~pull:false ~dockerfile (`Git repo)

let v ~base_img ~repo = function
  | Dune -> docker_img ~repo base_img "opam exec dune build @install"
