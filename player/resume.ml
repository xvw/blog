open Util
open Optional
module S = Storage.Local

let make_storage_key path =
  "--xvw-scroll-position:" ^ path

let resize =
  watch Lwt_js_events.onresize


let get_size = function
  | None -> float_of_int (document ##. documentElement ##. scrollHeight)
  | Some x -> float_of_int ((offset_y x) - 100)

let find_pred_h offset =
  let h = Js.string "h1, h2, h3, h4, h5, h6" in
  let nodes =
    document ## querySelectorAll h
    |> Dom.list_of_nodeList
  in
  nodes
  |> List.filter (fun node -> (offset_y node) < offset )
  |> List.sort (fun a b -> compare (offset_y b) (offset_y a))
  |> (function
      | x :: _ -> Some (Js.to_string x ##. id)
      | [] -> None
    )

let jump_to elt _ev _ =
  let offset = max 0 (offset_y elt - 80) in
  let () = window ## scroll 0 offset in
  Lwt.return_unit

let a content =
  let txt = (Dom_html.document ## createTextNode) (Js.string content) in
  let lnk = Dom_html.createA document in
  let () = Dom.appendChild lnk txt in
  lnk

let perform_ui path key =
  match Option.(S.get key >>= get_by_id), get_by_id "resume-box" with
  | Some elt, Some parent ->
    let () = clear parent in
    let child = a "Reprendre la lecture" in
    let _ = Lwt_js_events.(async_loop click child (jump_to elt)) in
    Dom.appendChild parent child
  | _, _ -> ()

let compute_progress percent = function
  | None -> ()
  | Some x ->
    let p = min (int_of_float (percent *. 100.0)) 100 in
    let px = (string_of_int p) ^ "%" in
    x ##.style##.width := (Js.string px)

let handler js_path =
  let path = Js.to_string js_path in
  let key = make_storage_key path in
  let last_tick = ref 0. in
  let progress = get_by_id "progress-bar" in
  let eof_article = get_by_id "eof-article" in
  let document_size = ref (get_size eof_article) in
  let () = perform_ui path key in
  let _ =
    let open Lwt_js_events in
    let _ = resize () (fun _ ->
        document_size := get_size eof_article;
        compute_progress !last_tick progress
      )
    in
    seq_loop scroll window (fun target _ ->
        let real_scroll = scroll_y () in
        let scroll = float_of_int real_scroll in
        let percent = scroll /. !document_size in
        let pred_percent = !last_tick in
        let diff = (abs_float (percent -. pred_percent)) *. !document_size in
        let () =
          if diff > 25.0 then
            let () = last_tick := percent in
            let () = match find_pred_h real_scroll with
              | Some ""
              | None -> S.remove key
              | Some id -> S.set key id
            in
            compute_progress percent progress
        in
        request_animation_frame ()
      )
  in ()
