open Util
open Optional
module S = Storage.Local

let make_storage_key path =
  "--xvw-scroll-position:" ^ path

let jump_to parent key _ev =
  let base_offset = Option.(
      S.get key
      >>= int_of_string_opt
      |> (fun opt -> get opt (fun () -> 0))
    ) in
  let () = window ## scroll 0 base_offset in
  false

let perform_ui path key offset =
  if offset > 80 then begin
    match get_by_id "resume-box" with
    | None -> ()
    | Some parent ->
      let () = clear parent in
      let open Tyxml_js.Html in
      let child =
        a ~a:[a_onclick (jump_to parent key)] [pcdata "Reprendre la lecture"]
      in Dom.appendChild parent (Tyxml_js.To_dom.of_a child)
  end

let compute_progress offset doc_size = function
  | None -> ()
  | Some x ->
    let f = float_of_int offset in
    let g = float_of_int doc_size in
    let size = min (int_of_float ((f /. g) *. 100.0)) 100 in
    let px = (string_of_int size) ^ "%" in
    x ##.style##.width := (Js.string px)

let handler js_path =
  let path = Js.to_string js_path in
  let key = make_storage_key path in
  let base_offset = Option.(
      S.get key
      >>= int_of_string_opt
      |> (fun opt -> get opt (fun () -> 0))
    ) in
  let last_tick = ref 0 in
  let progress = get_by_id "progress-bar" in
  let document_size = match get_by_id "eof-article" with
    | None -> document ##. documentElement ##. scrollHeight
    | Some e -> (offset_y e) - 100
  in
  let () = perform_ui path key base_offset in
  let _ =
    let open Lwt_js_events in
    seq_loop scroll window (fun target _ ->
        let offset = scroll_y () in
        let pred_offset = !last_tick in
        let diff = abs (offset - pred_offset) in
        let () =
          if diff > 50 then
            let () = last_tick := offset in
            let () = S.set key (string_of_int offset) in
            compute_progress offset document_size progress
        in
        request_animation_frame ()
      )
  in ()
