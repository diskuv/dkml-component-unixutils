open Dkml_install_api
open Dkml_install_register

let () =
  let reg = Component_registry.get () in
  Component_registry.add_component reg
    (module struct
      include Default_component_config

      let component_name = "staging-unixutils"
    end)
