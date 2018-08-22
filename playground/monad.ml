module type BINDABLE =
sig
  type 'a t
  val pure  : 'a -> 'a t
  val (>>=) : 'a t -> ('a -> 'b t)  -> 'b t
end

module type JOINABLE =
sig
  type 'a t
  val pure : 'a -> 'a t
  val map  : ('a -> 'b) -> 'a t -> 'b t
  val join : ('a t) t -> 'a t
end

module type MONAD =
sig
  type 'a t
  val pure  : 'a -> 'a t
  val map   : ('a -> 'b) -> 'a t -> 'b t
  val join  : ('a t) t -> 'a t
  val (>>=) : 'a t -> ('a -> 'b t)  -> 'b t
end

module With_bind (M : BINDABLE) :
  MONAD with type 'a t = 'a M.t =
struct
  include M
  let join x  = x >>= (fun x -> x)
  let map f x = x >>= (fun x -> pure (f x))
end

module With_join (M : JOINABLE) :
  MONAD with type 'a t = 'a M.t =
struct
  include M
  let (>>=) x f = join (map f x)
end

module OptionM = With_bind(
  struct
    type 'a t = 'a option
    let pure x = Some x
    let (>>=) x f = match x with
      | Some a -> f a
      | None -> None
  end)

module ListM = With_join(
  struct
    type 'a t = 'a list
    let pure x = [x]
    let map = List.map
    let join = List.flatten
  end)

module State (S : sig type t end) :
sig
  type state = S.t
  include MONAD with type 'a t = (state -> 'a * state)
  val get : state t
  val put : state -> unit t
  val eval : 'a t -> state -> 'a
  val exec : 'a t -> state -> state
  val run : 'a t -> state -> ('a * state)
end = struct

  type state = S.t
  include With_bind(
    struct
      type 'a t = (state -> 'a * state)
      let pure x = (fun state -> (x, state))
      let (>>=) h f =
        (fun state ->
            let (x, new_state) = h state in
            let g = f x in
            g new_state
          )
    end)

  let get = (fun state -> (state, state))
  let put state = (fun _ -> ((), state))
  let run f init = f init
  let eval f state = fst (f state)
  let exec f state = snd (f state)
end

module Count = State(struct type t = int end)
let tick state i = state (i + 1)

let rec insert x l =
  let open Count in
  match l with
  | [] -> pure [x]
  | h :: t ->
    tick (pure (x < h)) >>= fun b ->
    if b then pure (x::l)
    else insert x t >>= fun r ->
      pure (h::r)

open Count

let a = run (pure 0) 1
let b = run (
    pure 0
    >>= fun index -> put (index + 1)
    >>= fun () -> get
  ) 1
let c = run (
    pure 0
    >>= fun index -> put (index + 1)
    >>= fun () -> get
    >>= fun index -> put (index + 1)
    >>= fun () -> get
    >>= fun index -> put (index + 1)
    >>= fun () -> get
    >>= fun index ->
    pure (Format.sprintf "Je vaux %d -->" index)
  ) 0
