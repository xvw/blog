open Js_of_ocaml
open Util

let () =
  Js.export "__useResumable" Resume.handler
