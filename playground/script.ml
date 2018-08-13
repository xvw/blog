type ('a, 'b) either =
  | Left of 'a
  | Right of 'b

let ($) f x = f x

module Script :
sig

  type ('a, 'state) t = 'state -> ('a, 'state) step
  and ('a, 'state) step =
    | Done of 'a
    | Next of ('a, 'state) t

  val return : 'a -> ('a, 'state) t
  val bind : ('a, 'state) t -> ('a -> ('b, 'state) t) -> ('b, 'state) t
  val (>>=) : ('a, 'state) t -> ('a -> ('b, 'state) t) -> ('b, 'state) t
  val lift : ('a -> 'b) -> ('a, 'state) t ->  ('b, 'state) t
  val lift2 : ('a -> 'b -> 'c) -> ('a, 'state) t -> ('b, 'state) t -> ('c, 'state) t

end = struct

  type ('a, 's) t = 's -> ('a, 's) step
  and ('a, 's) step =
    | Done of 'a
    | Next of ('a, 's) t

  let return x _ = Done x

  let rec bind script f state =
    match script state with
    | Done x -> Next (f x)
    | Next continuation -> Next (bind continuation f)

  let (>>=) = bind

  let lift f x = x >>= fun a -> return $ f a
  let lift2 f x y =
    x >>= fun a ->
    y >>= fun b -> return $ f a b
end

module Game :
sig

  type state = unit
  type 'a script = ('a, state) Script.t

  val parallel : 'a script -> 'b script -> ('a * 'b) script
  val concurrent : 'a script -> 'b script -> ('a, 'b) either script
  val guard : bool script -> 'a script -> 'a script
  val repeat : unit script -> unit script
  val tick : 'a script -> 'a script

  val pattern :
    init:('a script)
    -> game_over:('a -> bool script)
    -> loop:('a -> unit script)
    -> ending:('a -> 'b script)
    -> unit
    -> 'b script

end = struct

  type state = unit
  type 'a script = ('a, state) Script.t

  let rec parallel script1 script2 state =
    match (script1 state, script2 state) with
    | Script.Done x, Script.Done y -> Script.return (x, y) state
    | Script.Next x, Script.Next y -> parallel x y state
    | Script.Next x, Script.Done y -> parallel x $ Script.return y $ state
    | Script.Done x, Script.Next y -> parallel $ Script.return x $ y $ state

  let rec concurrent script1 script2 state =
    match (script1 state, script2 state) with
    | Script.Done x, _ -> Script.return $ Left x $ state
    | _, Script.Done y -> Script.return $ Right y $ state
    | Script.Next x, Script.Next y -> concurrent x y state


  let rec guard predicate script =
    let open Script in
    predicate >>= fun x -> if x then script
    else script >>= fun result -> guard predicate script

  let rec repeat script =
    let open Script in
    script >>= fun () ->
    (repeat script) >>= fun () -> Script.return ()

  let rec tick script state =
    match script state with
    | Script.Done x -> Script.return x state
    | Script.Next x -> tick x state


  let rec pattern ~init ~game_over ~loop ~ending () =
    let process x = concurrent
        (guard $ game_over x $ tick (ending x))
        (repeat $ loop x)
    in
    let open Script in
    tick init >>= fun x ->
    process x >>= function Left y -> return y  [@@ocaml.warning "-8"]


end
