open Dkml_install_api
open Dkml_install_register

let execute_install ctx =
  Logs.info (fun m ->
      m "The install location is: %a" Fpath.pp
        (ctx.Context.path_eval "%{prefix}%"));
  if Context.Abi_v2.is_windows ctx.Context.target_abi_v2 then
    Staging_ocamlrun_api.spawn_ocamlrun ctx
      Bos.Cmd.(
        v
          (Fpath.to_string
             (ctx.Context.path_eval
                "%{staging-unixutils:share-generic}%/windows_install.bc"))
        %% of_list (Array.to_list (Log_config.to_args ctx.Context.log_config))
        % "--tmp-dir"
        % Fpath.to_string (ctx.Context.path_eval "%{tmp}%")
        % "--dkml-confdir-exe"
        % Fpath.to_string (Staging_dkmlconfdir_api.dkml_confdir_exe ctx)
        % "--target-msys2-dir"
        % Fpath.to_string (ctx.Context.path_eval "%{prefix}%/tools/MSYS2")
        % "--target-sh"
        % Fpath.to_string
            (ctx.Context.path_eval "%{prefix}%/tools/unixutils/bin/sh.exe")
        % "--curl-exe"
        % Fpath.to_string
            (ctx.Context.path_eval "%{staging-curl:share-abi}%/bin/curl.exe")
        %%
        match ctx.Context.target_abi_v2 with
        | Windows_x86 -> v "--32-bit"
        | _ -> empty)
  else
    Staging_ocamlrun_api.spawn_ocamlrun ctx
      Bos.Cmd.(
        v
          (Fpath.to_string
             (ctx.Context.path_eval
                "%{staging-unixutils:share-generic}%/unix_install.bc"))
        % "-target-sh"
        % Fpath.to_string
            (ctx.Context.path_eval "%{prefix}%/tools/unixutils/bin/sh"))

let register () =
  let reg = Component_registry.get () in
  Component_registry.add_component reg
    (module struct
      include Default_component_config

      let component_name = "network-unixutils"

      let install_depends_on =
        [
          "staging-ocamlrun";
          "staging-curl";
          "staging-unixutils";
          "staging-dkmlconfdir";
        ]

      let install_user_subcommand ~component_name:_ ~subcommand_name ~fl ~ctx_t
          =
        let doc = "Install Unix utilities" in
        Dkml_install_api.Forward_progress.Continue_progress
          ( Cmdliner.Cmd.v
              (Cmdliner.Cmd.info subcommand_name ~doc)
              Cmdliner.Term.(const execute_install $ ctx_t),
            fl )

      let uninstall_user_subcommand ~component_name:_ ~subcommand_name ~fl
          ~ctx_t =
        let doc = "Uninstall Unix utilities" in
        Dkml_install_api.Forward_progress.Continue_progress
          ( Cmdliner.Cmd.v
              (Cmdliner.Cmd.info subcommand_name ~doc)
              Cmdliner.Term.(
                const Dkml_component_common_unixutils.execute_uninstall $ ctx_t),
            fl )
    end)
