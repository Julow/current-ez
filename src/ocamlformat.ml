(** OCamlformat pipeline term *)

module Docker = Current_docker.Default
open Current.Syntax

type desc =
  | No  (** Disable checking *)
  | Dune  (** Using `dune build @fmt` *)

let docker_img ~ocamlformat_version ~repo base_img =
  (* Install OCamlformat in a separate image so it can be cached *)
  let base_img =
    let dockerfile =
      let+ base_img = base_img in
      let open Dockerfile in
      from (Docker.Image.hash base_img)
      @@ run "opam install ocamlformat.%s" ocamlformat_version
    in
    Docker.build ~label:"ocamlformat" ~pull:false ~dockerfile `No_context
  in
  let dockerfile =
    let+ base_img = base_img in
    let open Dockerfile in
    from (Docker.Image.hash base_img) @@ copy ~src:[ "." ] ~dst:"." ()
  in
  Docker.build ~label:"ocamlformat checking" ~pull:false ~dockerfile
    (`Git repo)

let ocamlformat_version = "v0.11.0"

(** [repo] is path to repository source locally
    Expect the base image to contains a clean opam switch and a clean working directory *)
let v ~base_img ~repo desc =
  let img = docker_img ~ocamlformat_version ~repo base_img in
  match desc with
  | No -> None
  | Dune -> Some (Docker.run img ~args:[ "dune"; "build"; "@fmt" ])
