(* Main *)

let desc = Pipeline.{ ocamlformat = Ocamlformat.Dune }

let main config mode repo () =
  let repo = match repo with Some d -> d | None -> Sys.getcwd () in
  let repo = Current_git.Local.v (Fpath.v repo) in
  let engine =
    Current.Engine.create ~config (fun () -> Pipeline.v ~repo desc)
  in
  Lwt_main.run
  @@ Lwt.choose [ Current.Engine.thread engine; Current_web.run ~mode engine ]

(* Cli *)

open Cmdliner

let repo =
  Arg.(
    value & pos 0 (some dir) None & info ~doc:"The repository" ~docv:"DIR" [])

let () =
  let open Term in
  exit @@ eval
  @@
  let doc = "Easy ci" in
  ( const main $ Current.Config.cmdliner $ Current_web.cmdliner $ repo
    $ Logging.cli,
    info "current-ez" ~doc )
