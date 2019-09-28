(** Full pipeline term *)

module Docker = Current_docker.Default
module Git = Current_git
include Current.Syntax

type desc = {
  ocamlformat : Ocamlformat.desc;
  build : Build.desc;
  runtest : Runtest.desc;
}

let base_img ~ocaml_version =
  let schedule = Current_cache.Schedule.v ~valid_for:(Duration.of_day 7) () in
  let opam_base = Docker.pull ~schedule "ocaml/opam2" in
  let dockerfile =
    let+ base_img = opam_base in
    let open Dockerfile in
    from (Docker.Image.hash base_img)
    @@ user "root"
    @@ run "mkdir /ci && chown opam:opam /ci"
    @@ user "opam" @@ workdir "/ci"
    @@ run "opam switch create %s" ocaml_version
  in
  Docker.build ~label:"base image" ~pull:false ~dockerfile `No_context

let v ~repo desc =
  let ocaml_version = "4.08.1" in
  let base_img = base_img ~ocaml_version in
  let repo = Git.Local.head_commit repo in
  let build_img = Build.v ~base_img ~repo desc.build in
  let ocamlformat = Ocamlformat.v ~base_img ~repo desc.ocamlformat in
  let build = Some (Current.ignore_value build_img) in
  let runtest = Runtest.v ~build_img desc.runtest in
  Current.all (List.filter_map (fun x -> x) [ ocamlformat; build; runtest ])
