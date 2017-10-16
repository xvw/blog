type empty_t
type not_empty_t

type ('a, 'b) t =
  | Empty : (empty_t, 'b) t
  | Cons : ('b * ('a, 'b) t) -> (not_empty_t, 'b) t


let head (Cons (x, _)) = x

