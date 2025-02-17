{-# OPTIONS --type-in-type #-}  -- yes, I will let you cheat in this exercise
{-# OPTIONS --allow-unsolved-metas #-}  -- allows import, unfinished

------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- CS410 2017/18 Exercise 2  CATEGORIES AND MONADS (worth 50%)
------------------------------------------------------------------------------
------------------------------------------------------------------------------

-- NOTE (19/10/17)  This file is currently incomplete: more will arrive on
-- GitHub.

-- NOTE (29/10/17)  All components are now present.

-- REFLECTION: When I started setting this exercise, I intended it as a
-- normal size 25% exercise, but it grew and grew, as did the struggles of
-- the students. I accepted that I had basically set two exercises in one
-- file and revalued it as such.


------------------------------------------------------------------------------
-- Dependencies
------------------------------------------------------------------------------

open import Prelude
open import Categories
open import Ex1


------------------------------------------------------------------------------
-- Categorical Jigsaws (based on Ex1)
------------------------------------------------------------------------------

-- In this section, most of the work has already happened. All you have to do
-- is assemble the collection of things you did into Ex1 into neat categorical
-- packaging.

--??--2.1-(4)-----------------------------------------------------------------

OPE : Category            -- The category of order-preserving embeddings...
OPE = record
  { Obj          = Nat    -- ...has numbers as objects...
  ; _~>_         = _<=_   -- ...and "thinnings" as arrows.
                          -- Now, assemble the rest of the components.
  ; id~>         = oi
  ; _>~>_        = _o>>_
  ; law-id~>>~>  = idThen-o>>
  ; law->~>id~>  = idAfter-o>>
  ; law->~>>~>   = assoc-o>>
  }


VEC : Nat -> SET => SET                -- Vectors of length n...
VEC n = record
  { F-Obj       = \ X -> Vec X n       -- ...give a functor from SET to SET...
  ; F-map       = \ f xs -> vMap f xs  --.doing vMap to arrows.
                                       -- Now prove the laws.
  ; F-map-id~>  = extensionality \ xs -> vMapIdFact (\x -> refl x) xs
  ; F-map->~>   = \ f g -> extensionality \ xs -> sym (vMapCpFact g f (g << f) (\ x -> refl (g (f x))) xs)
  } 


Op : Category -> Category             -- Every category has an opposite...
Op C = record
  { Obj          = Obj                -- ...with the same objects, but...  
  ; _~>_         = \ S T -> T ~> S    -- ...arrows that go backwards!
                                      -- Now, find the rest!
  ; id~>         = id~> 
  ; _>~>_        = \ f g -> g >~> f 
  ; law-id~>>~>  = law->~>id~>
  ; law->~>id~>  = law-id~>>~>
  ; law->~>>~>   = \ f g h -> sym (law->~>>~> h g f) 
  } where open Category C

CHOOSE : Set -> OPE => Op SET    -- Show that thinnings from n to m...
CHOOSE X = record                -- ...act by selection...
  { F-Obj       = Vec X          -- ...to cut vectors down from m to n.
  ; F-map       = _<?=_ 
  ; F-map-id~>  = extensionality \ xs -> id-<?= xs 
  ; F-map->~>   = \ f g -> extensionality \ xs -> cp-<?=  f g xs  
  }
--??--------------------------------------------------------------------------


------------------------------------------------------------------------------
-- The List Monad (a warm-up)
------------------------------------------------------------------------------

-- The declaration of List has been added to the CS410-Prelude file:

-- data List (X : Set) : Set where
--   []   : List X
--   _,-_ : (x : X)(xs : List X) -> List X
-- infixr 4 _,-_

-- Appending two lists is rather well known, so I'll not ask you to write it.

_+L_ : {X : Set} -> List X -> List X -> List X
[]        +L ys = ys
(x ,- xs) +L ys = x ,- (xs +L ys)
infixr 4 _+L_

-- But I will ask you to find some structure for it.

+LId : {X : Set}(xs : List X) -> (xs +L []) == xs
+LId [] = refl []
+LId (x ,- xs) rewrite +LId xs = refl (x ,- xs)
+LAssoc : {X : Set}(xs ys zs : List X) -> ((xs +L ys) +L zs) == (xs +L (ys +L zs))
+LAssoc [] ys zs = refl (ys +L zs)
+LAssoc (x ,- xs) ys zs rewrite +LAssoc xs ys zs = refl (x ,- xs +L ys +L zs)
--??--2.2-(3)-----------------------------------------------------------------

LIST-MONOID : Set -> Category
LIST-MONOID X =            -- Show that _+L_ is the operation of a monoid,...
  record
  { Obj          = One     -- ... i.e., a category with one object.
  ; _~>_         = \ _ _ -> List X
  ; id~>         = []
  ; _>~>_        = _+L_
  ; law-id~>>~>  = \ xs -> refl xs
  ; law->~>id~>  = +LId 
  ; law->~>>~>   = +LAssoc
  } where

--??--------------------------------------------------------------------------

-- Next, functoriality of lists. Given a function on elements, show how to
-- apply that function to all the elements of a list. (Haskell calls this
-- operation "map".)

--??--2.3-(3)-----------------------------------------------------------------

list : {X Y : Set} -> (X -> Y) -> List X -> List Y
list f [] = []
list f (x ,- xs) = f x ,- list f xs



mapConcat : {X Y : Set}(f : X -> Y) -> (xs ys : List X) -> (list f xs +L list f ys) == (list f (xs +L ys))
mapConcat f [] ys = refl (list f ys)
mapConcat f (x ,- xs) ys rewrite mapConcat f xs ys = refl (f x ,- list f (xs +L ys))

LIST : SET => SET
LIST = record
  { F-Obj       = List
  ; F-map       = list
  ; F-map-id~>  = extensionality \ xs -> mapId (\ x -> refl x) xs
  ; F-map->~>   = \ f g -> extensionality \ xs -> mapCp f g xs
  } where
  mapId :  {X : Set}{f : X -> X}(feq : (x : X) -> f x == x) ->
            (xs : List X) -> list f xs == xs
  mapId feq [] = refl []
  mapId feq (x ,- xs) rewrite mapId feq xs rewrite feq x = refl (x ,- xs)

  mapCp : {X Y Z : Set}(f : X -> Y)(g : Y -> Z) -> (xs : List X) -> list (\ x -> g (f x)) xs == list g (list f xs)  
  mapCp f g [] = refl []
  mapCp f g (x ,- xs) rewrite mapCp f g xs = refl (g (f x) ,- list g (list f xs))

  -- useful helper proofs (lemmas) go here

--??--------------------------------------------------------------------------


-- Moreover, applying a function elementwise should respect appending.

--??--2.4-(3)-----------------------------------------------------------------

LIST+L : {X Y : Set}(f : X -> Y) -> LIST-MONOID X => LIST-MONOID Y
LIST+L {X}{Y} f = record
  { F-Obj       = id
  ; F-map       = list f -- this yellow will go once LIST-MONOID has arrows!
  ; F-map-id~>  = refl []
  ; F-map->~>   = \ xs ys -> sym (mapConcat f xs ys) 
  } where
  -- useful helper proofs (lemmas) go here


--??--------------------------------------------------------------------------


-- Next, we have two very important "natural transformations".

--??--2.5-(1)-----------------------------------------------------------------

SINGLE : ID ~~> LIST
SINGLE = record
  { xf          = \ x -> x ,- []      -- turn a value into a singleton list
  ; naturality  = \ f -> refl (\  x -> f x ,- [])
  }

--??--------------------------------------------------------------------------

-- Here, naturality means that it doesn't matter
-- whether you apply a function f, then make a singleton list
-- or you make a singleton list, then apply f to all (one of) its elements.


-- Now, define the operation that concatenates a whole list of lists, and
-- show that it, too, is natural. That is, it doesn't matter whether you
-- transform the elements (two layers inside) then concatenate, or you
-- concatenate, then transform the elements.

--??--2.6-(3)-----------------------------------------------------------------

concat : {X : Set} -> List (List X) -> List X
concat [] = []
concat (xs ,- xss) = xs +L concat xss

CONCAT : (LIST >=> LIST) ~~> LIST
CONCAT = record
  { xf          = concat
  ; naturality  = \ f -> extensionality \ xss -> naturalityHelp f xss
  } where 
  naturalityHelp : {X Y : Set} -> (f : X -> Y) -> (xss : List (List X)) -> concat (list (list f) xss) == list f (concat xss)
  naturalityHelp f [] = refl []
  naturalityHelp f (xs ,- xss) rewrite naturalityHelp f xss rewrite mapConcat f xs (concat xss) = refl (list f (xs +L concat xss))
  -- useful helper proofs (lemmas) go here

--??--------------------------------------------------------------------------


-- You've nearly built your first monad! You just need to prove that
-- single and concat play nicely with each other.

--??--2.7-(4)-----------------------------------------------------------------

module LIST-MONAD where
  open MONAD LIST public
  ListMonad : Monad
  ListMonad = record
    { unit      = SINGLE
    ; mult      = CONCAT
    ; unitMult  = extensionality \ xs -> +LId xs
    ; multUnit  = extensionality \ xs -> multUnitHelper xs
    ; multMult  = extensionality \ xs -> multMultHelper xs
    } where
    multUnitHelper : {X : Set} -> (xs : List X) -> concat (list (\ x -> x ,- []) xs) == xs
    multUnitHelper [] = refl []
    multUnitHelper (x ,- xs) rewrite multUnitHelper xs = refl (x ,- xs)
    multMultHelper : {X : Set} -> (xsss : List (List (List X))) -> concat (concat xsss) ==
      concat (list concat xsss)
    multMultHelper [] = refl []
    multMultHelper ([] ,- xss) rewrite multMultHelper xss = refl (concat (list concat xss)) 
    multMultHelper ((x ,- xs) ,- xss) rewrite multMultHelper (xs ,- xss) rewrite +LAssoc x (concat xs) (concat (list concat xss)) = refl (x +L concat xs +L concat (list concat xss))

-- open LIST-MONAD

--??--------------------------------------------------------------------------

-- More monads to come...


------------------------------------------------------------------------------
-- Categories of Indexed Sets
------------------------------------------------------------------------------

-- We can think of some
--   P : I -> Set
-- as a collection of sets indexed by I, such that
--   P i
-- means "exactly the P-things which fit with i".

-- You've met
--   Vec X : Nat -> Set
-- where
--   Vec X n
-- means "exactly the vectors which fit with n".

-- Now, given two such collections, S and T, we can make a collection
-- of function types: the functions which fit with i map the
-- S-things which fit with i to the T-things which fit with i.

_-:>_ : {I : Set} -> (I -> Set) -> (I -> Set) -> (I -> Set)
(S -:> T) i = S i -> T i

-- So, (Vec X -:> Vec Y) n contains the functions which turn
-- n Xs into n Ys.

-- Next, if we know such a collection of sets, we can claim to have
-- one for each index.

[_] : {I : Set} -> (I -> Set) -> Set
[ P ] = forall i -> P i    -- [_] {I} P = (i : I) -> P i

-- E.g., [ Vec X -:> Vec Y ] is the type of functions from X-vectors
-- to Y-vectors which preserve length.

-- For any such I, we get a category of indexed sets with index-preserving
-- functions.

_->SET : Set -> Category
I ->SET = record
  { Obj    = I -> Set                 -- I-indexed sets
  ; _~>_   = \ S T -> [ S -:> T ]     -- index-respecting functions
  ; id~>   = \ i -> id                -- the identity at every index
  ; _>~>_  = \ f g i -> f i >> g i    -- composition at every index
  ; law-id~>>~> = refl                -- and the laws are very boring
  ; law->~>id~> = refl
  ; law->~>>~>  = \ f g h -> refl _
  }

-- In fact, we didn't need to choose SET here. We could do this construction
-- for any category: index the objects; index the morphisms.
-- But SET is plenty to be getting on with.

-- Now, let me define an operation that makes types from lists.

All : {X : Set} -> (X -> Set) -> (List X -> Set)
All P [] = One
All P (x ,- xs) = P x * All P xs

-- The idea is that we get a tuple of P-things: one for each list element.
-- So
--     All P (1 ,- 2 ,- 3 ,- [])
--   = P 1 * P 2 * P 3 * One

-- Note that if you think of List One as a version of Nat,
-- All becomes a lot like Vec.

copy : Nat -> List One
copy zero = []
copy (suc n) = <> ,- copy n

VecCopy : Set -> Nat -> Set
VecCopy X n = All (\ _ -> X) (copy n)

-- Now, your turn...

--??--2.8-(4)-----------------------------------------------------------------

-- Show that, for any X, All induces a functor
-- from (X ->SET) to (List X ->SET)

all : {X : Set}{S T : X -> Set} ->
      [ S -:> T ] -> [ All S -:> All T ]
all f [] <> = <>
all f (s ,- ss) (t , ts) = f s t , all f ss ts 



allId~> : {X : Set}{S : X -> Set} -> (xs : List X) -> (ts : All S xs) -> all (\ i x -> x) xs ts == ts
allId~> [] ys = refl <>
allId~> (x ,- xs) (y , ys) rewrite allId~> xs ys = refl (y , ys)
all>~> : {X : Set}{R S T : X -> Set} -> (f : [ R -:> S ] ) -> (g : [ S -:> T ] ) -> (xs : List X) -> (ys : All R xs) -> all (\ i x -> g i (f i x)) xs ys == all g xs (all f xs ys)
all>~> f g [] ys = refl <>
all>~> f g (x ,- xs) (y , ys) rewrite all>~> f g xs ys = refl (g x (f x y) , all g xs (all f xs ys))

ALL : (X : Set) -> (X ->SET) => (List X ->SET)
ALL X = record
  { F-Obj      = All
  ; F-map      = all
  ; F-map-id~> = extensionality \ xs -> extensionality \ ys -> allId~> xs ys 
  ; F-map->~>  = \ f g ->  extensionality \ xs -> extensionality \ ys -> all>~> f g xs ys
  } where

--??--------------------------------------------------------------------------


-- ABOVE THIS LINE, 25%
-- BELOW THIS LINE, 25%


------------------------------------------------------------------------------
-- Cutting Things Up
------------------------------------------------------------------------------

-- Next, we're going to develop a very general technique for building
-- data structures.

-- We may think of an I |> O as a way to "cut O-shapes into I-shaped pieces".
-- The pointy end points to the type being cut; the flat end to the type of
-- pieces.

record _|>_ (I O : Set) : Set where
  field
    Cuts   : O -> Set                      -- given o : O, how may we cut it?
    inners : {o : O} -> Cuts o -> List I   -- given how we cut it, what are
                                           --   the shapes of its pieces?

-- Let us have some examples right away!

VecCut : One |> Nat              -- cut numbers into boring pieces
VecCut = record
  { Cuts = \ n -> One            -- there is one way to cut n
  ; inners = \ {n} _ -> copy n   -- and you get n pieces
  }

-- Here's a less boring example. You can cut a number into *two* pieces
-- by finding two numbers that add to it.

NatCut : Nat |> Nat
NatCut = record
  { Cuts = \ mn -> Sg Nat \ m -> Sg Nat \ n -> (m +N n) == mn
  ; inners = \ { (m , n , _) -> m ,- n ,- [] }
  }

-- The point is that we can make data structures that record how we
-- built an O-shaped thing from I-shaped pieces.

record Cutting {I O}(C : I |> O)(P : I -> Set)(o : O) : Set where
  constructor _8><_               -- "scissors"
  open _|>_ C
  field
    cut     : Cuts o              -- we decide how to cut o
    pieces  : All P (inners cut)  -- then we give all the pieces.
infixr 3 _8><_

-- For example...

VecCutting : Set -> Nat -> Set
VecCutting X = Cutting VecCut (\ _ -> X)

myVecCutting : VecCutting Char 5
myVecCutting = <> 8>< 'h' , 'e' , 'l' , 'l' , 'o' , <>

-- Or, if you let me fiddle about with strings for a moment,...
length : {X : Set} -> List X -> Nat
length [] = zero
length (x ,- xs) = suc (length xs)

listVec : {X : Set}(xs : List X) -> Vec X (length xs)
listVec [] = []
listVec (x ,- xs) = x ,- listVec xs

strVec : (s : String) -> Vec Char (length (primStringToList s))
strVec s = listVec (primStringToList s)

-- ...an example of cutting a number in two, with vector pieces.

footprints : Cutting NatCut (Vec Char) 10
footprints = (4 , 6 , refl 10) 8>< strVec "foot"
                                 , strVec "prints"
                                 , <>

-- Now, let me direct you to the =$ operator, now in CS410-Prelude.agda,
-- which you may find helps with the proofs in the following.

--??--2.9-(3)-----------------------------------------------------------------

-- Using what you already built for ALL, show that every Cutting C gives us
-- a functor between categories of indexed sets.


CUTTING : {I O : Set}(C : I |> O) -> (I ->SET) => (O ->SET)
CUTTING {I}{O} C = record
  { F-Obj = Cutting C
  ; F-map = mapHelper
  ; F-map-id~> = \ {T} -> extensionality \ o -> extensionality \ { (cut 8>< pieces) ->
   mapHelper (Category.id~> (I ->SET)) o (cut 8>< pieces) 
   =[ refl (cut 8>< all (Category.id~> (I ->SET)) (inners cut) pieces) >= 
   cut 8>< all ((Category.id~> (I ->SET))) (inners cut) pieces 
   =[ refl (\ x -> cut 8>< x) =$= ((F-map-id~> =$ inners cut) =$ pieces)  >= 
   (cut 8>< pieces) 
   [QED] }
  ; F-map->~> = \ f g ->
     extensionality \ o -> extensionality \ { (c 8>< ps) ->  
     mapHelper (((I ->SET) Category.>~> f) g) o (c 8>< ps) 
     =[ refl (c 8>< all (((I ->SET) Category.>~> f) g) (inners c) ps) >= 
     (c 8>< all (\  i x -> g i (f i x)) (inners c) ps) 
     =[ refl (\ x -> c 8>< x) =$= ((F-map->~> f g =$ inners c) =$ ps) >=
     (c 8>< all g (inners c) (all f (inners c) ps))
     =[ refl (c 8>< all g (inners c) (all f (inners c) ps)) >=
     ((O ->SET) Category.>~> mapHelper f) (mapHelper g) o (c 8>< ps) 
     [QED]
     } 
  } where
  open _|>_ C
  open _=>_ (ALL I)
  mapHelper : {S T : I -> Set} -> [ S -:> T ] -> [ Cutting C S -:> Cutting C T ]
  mapHelper f o (cut 8>< pieces) = cut 8>< all f _ pieces

------------------------------------------------------------------------------
-- Interiors
------------------------------------------------------------------------------

-- Next, let me define the notion of an algebra for a given functor in C => C

module ALGEBRA {C : Category}(F : C => C) where
  open Category C
  open _=>_ F

  Algebra : (X : Obj) -> Set   -- we call X the "carrier" of the algebra...
  Algebra X = F-Obj X ~> X     -- ...and we explain how to turn a bunch of Xs
                               -- into one
open ALGEBRA

-- Some week, we'll build categories whose objects are algebras. Not this week.

-- Instead, let's work with them a bit.

-- If we know a way to cut I-shapes into I-shaped pieces, we can build the
-- ways to "tile" an I with I-shaped T-tiles.

data Interior {I}(C : I |> I)(T : I -> Set)(i : I) : Set where
                                         -- either...
  tile : T i -> Interior C T i           -- we have a tile that fits, or...
  <_>  : Cutting C (Interior C T) i ->   -- ...we cut, then tile the pieces.
         Interior C T i

-- Let me give you an example of an interior.

subbookkeeper : Interior NatCut (Vec Char) 13
subbookkeeper = < (3 , 10 , refl _)
                  8>< tile (strVec "sub")
                    , < (4 , 6 , refl _)
                        8>< tile (strVec "book")
                          , tile (strVec "keeper")
                          , <> >
                    , <> >

-- We make a 13-interior from
-- a 3-tile and a 10-interior made from a 4-tile and a 6-tile.

-- Guess what? Interior C is always a Monad! We'll get there.

module INTERIOR {I : Set}{C : I |> I} where  -- fix some C...

  open _|>_ C                                -- ...and open it
  
  open module I->SET {I : Set} = Category (I ->SET)  -- work in I ->SET

  -- tile gives us an arrow from T into Interior C T

  tile' : {T : I -> Set} -> [ T -:> Interior C T ]
  tile' i = tile

  -- <_> gives us an algebra!

  cut' : {T : I -> Set} -> Algebra (CUTTING C) (Interior C T)
  cut' i = <_>

  -- Now, other (CUTTING C) algebras give us operators on interiors.

  module INTERIORFOLD {P Q : I -> Set} where
  
    interiorFold :
      [ P -:> Q ] ->              -- if we can turn a P into a Q...
      Algebra (CUTTING C) Q ->    -- ...and a bunch of Qs into a Q...
      [ Interior C P -:> Q ]      -- ...we can turn an interior of Ps into a Q

    allInteriorFold :             -- annoyingly, we'll need a specialized "all"
      [ P -:> Q ] ->
      Algebra (CUTTING C) Q ->
      [ All (Interior C P) -:> All Q ]

    interiorFold pq qalg i (tile p)      = pq i p
    interiorFold pq qalg i < c 8>< pcs > =
      qalg i (c 8>< allInteriorFold pq qalg (inners c) pcs)

    -- recursively turn all the sub-interiors into Qs
    allInteriorFold pq qalg []        <>         = <>
    allInteriorFold pq qalg (i ,- is) (pi , pis) =
      interiorFold pq qalg i pi , allInteriorFold pq qalg is pis

    -- The trouble is that if you use
    --   all (interiorFold pq qalg)
    -- to process the sub-interiors, the termination checker complains.

    -- But if you've built "all" correctly, you should be able to prove this:

--??--2.10-(2)----------------------------------------------------------------

    allInteriorFoldLaw : (pq : [ P -:> Q ])(qalg : Algebra (CUTTING C) Q) ->
      allInteriorFold pq qalg == all (interiorFold pq qalg)
    allInteriorFoldLaw pq qalg = extensionality \ is -> extensionality \ ps -> help pq qalg is ps
      where
      help : (pq : [ P -:> Q ])
         (qalg : Algebra (CUTTING C) Q) (is : List I)
         (ps : All (Interior C P) is) ->
       allInteriorFold pq qalg is ps == all (interiorFold pq qalg) is ps
      help pq qalg [] ps = refl <>
      help pq qalg (i ,- is) (p , ps) rewrite help pq qalg is ps = 
        refl (interiorFold pq qalg i p , all (interiorFold pq qalg) is ps)
--??--------------------------------------------------------------------------

    -- Now, do me a favour and prove this extremely useful fact.
    -- Its purpose is to bottle the inductive proof method for functions
    -- built with interiorFold.

--??--2.11-(3)----------------------------------------------------------------
    interiorFoldLemma :
      (pq : [ P -:> Q ])(qalg : Algebra (CUTTING C) Q)
      (f : [ Interior C P -:> Q ]) ->
      ((i : I)(p : P i) -> pq i p == f i (tile p)) ->
      ((i : I)(c : Cuts i)(ps : All (Interior C P) (inners c)) ->
        qalg i (c 8>< all f (inners c) ps) == f i < c 8>< ps >) ->
      (i : I)(pi : Interior C P i) -> interiorFold pq qalg i pi == f i pi

    -- have to do 'mutual recursion' since interiorFold is defined that way
    allinteriorFoldLemma : (pq : [ P -:> Q ])(qalg : Algebra (CUTTING C) Q)
      (f : [ Interior C P -:> Q ]) ->
      ((i : I)(p : P i) -> pq i p == f i (tile p)) ->
      ((i : I)(c : Cuts i)(ps : All (Interior C P) (inners c)) ->
      qalg i (c 8>< all f (inners c) ps) == f i < c 8>< ps >) ->
      (is : List I) -> (ps : All (Interior C P) is) ->
      all (interiorFold pq qalg) is ps == all f is ps

    interiorFoldLemma pq qalg f base step i (tile x) = base i x
    interiorFoldLemma pq qalg f base step i < c 8>< pcs > 
      rewrite (sym (step i c pcs)) 
      rewrite allInteriorFoldLaw pq qalg 
      rewrite allinteriorFoldLemma pq qalg f base step (inners c) pcs = refl (qalg i (c 8>< all f (inners c) pcs))
      
    allinteriorFoldLemma pq qalg f base step [] ps = refl <>
    allinteriorFoldLemma pq qalg f base step (i ,- is) (p , ps) 
      rewrite interiorFoldLemma pq qalg f base step i p 
      rewrite allinteriorFoldLemma pq qalg f base step is ps = refl (f i p , all f is ps)


--??--------------------------------------------------------------------------
    -- We'll use it in this form:

    interiorFoldLaw : (pq : [ P -:> Q ])(qalg : Algebra (CUTTING C) Q)
      (f : [ Interior C P -:> Q ]) ->
      ((i : I)(p : P i) -> pq i p == f i (tile p)) ->
      ((i : I)(c : Cuts i)(ps : All (Interior C P) (inners c)) ->
        qalg i (c 8>< all f (inners c) ps) == f i < c 8>< ps >) ->
      interiorFold pq qalg == f
      
    interiorFoldLaw pq qalg f base step =
      extensionality \ i -> extensionality \ pi ->
      interiorFoldLemma pq qalg f base step i pi

  open INTERIORFOLD

  -- Let me pay you back immediately!
  -- An interiorBind is an interiorFold which computes an Interior,
  --   rewrapping each layer with < ... >

  interiorBind : {X Y : I -> Set} ->
                 [ X -:> Interior C Y ] -> [ Interior C X -:> Interior C Y ]
  interiorBind f = interiorFold f (\ i -> <_>)

  -- Because an interiorBind *makes* an interior, we can say something useful
  -- about what happens if we follow it with an interiorFold.

  interiorBindFusion : {X Y Z : I -> Set} ->
    (f : [ X -:> Interior C Y ])
    (yz : [ Y -:> Z ])(zalg : Algebra (CUTTING C) Z) ->
    (interiorBind f >~> interiorFold yz zalg) ==
      interiorFold (f >~> interiorFold yz zalg) zalg

  -- That is, we can "fuse" the two together, making one interiorFold.

  -- I'll do the proof as it's a bit hairy. You've given me all I need.
  -- Note that I don't use extensionality, just laws that relate functions.

  -- interiorFold (\  i x -> interiorFold yz zalg i (f i x)) zalg ==
  --   (\  i x -> interiorFold yz zalg i (interiorBind f i x))
  interiorBindFusion f yz zalg =
    (interiorBind f >~> interiorFold yz zalg)
      =< interiorFoldLaw
         (f >~> interiorFold yz zalg) zalg
         (interiorBind f >~> interiorFold yz zalg)
         (\ i p -> refl (interiorFold yz zalg i (f i p)))
         (\ i c ps -> refl (zalg i) =$= (refl (c 8><_) =$= (
            ((all (interiorBind f >~> interiorFold yz zalg)
              =[ F-map->~> (interiorBind f) (interiorFold yz zalg) >=
            (all (interiorBind f) >~> all (interiorFold yz zalg))
              =< refl _>~>_
                 =$= allInteriorFoldLaw f cut'
                 =$= allInteriorFoldLaw yz zalg  ]=
            allInteriorFold f (\ i -> <_>) >~> allInteriorFold yz zalg [QED])
           =$ inners c =$= refl ps))))
      ]=
    interiorFold (f >~> interiorFold yz zalg) zalg [QED]
    where open _=>_ (ALL I)

  -- You should find that a very useful piece of kit. In fact, you should
  -- not need extensionality, either.

  -- We need Interior C to be a functor.

--??--2.12-(5)----------------------------------------------------------------

  -- using interiorBind, implement the "F-map" for Interiors as a one-liner

  interior : {X Y : I -> Set} ->
             [ X -:> Y ] -> [ Interior C X -:> Interior C Y ]
  interior f = interiorBind \ i -> \ x -> tile (f i x)

  -- using interiorBindFusion, prove the following law for "fold after map"
  -- interiorFold (\  i x -> qr i (pq i x)) ralg == 
  --   (\  i x -> interiorFold qr ralg i (interior pq i x))
  interiorFoldFusion : {P Q R : I -> Set}
    (pq : [ P -:> Q ])(qr : [ Q -:> R ])(ralg : Algebra (CUTTING C) R) ->
    (interior pq >~> interiorFold qr ralg) == interiorFold (pq >~> qr) ralg
  interiorFoldFusion pq qr ralg =
    interior pq >~> interiorFold qr ralg
    =[ refl _ >=
    (\  i x -> interiorFold qr ralg i (interiorBind (\ i x -> tile (pq i x)) i x)) 
    =[ interiorBindFusion (\ i x -> tile (pq i x)) qr ralg >= 
    interiorFold (\ i x -> interiorFold qr ralg i (tile (pq i x))) ralg 
    =[ refl _ >=
    interiorFold (pq >~> qr) ralg [QED]
    where open _=>_ (ALL I)

  -- interiorFoldFusion : {P Q R : I -> Set}
  --   (pq : [ P -:> Q ])(qr : [ Q -:> R ])(ralg : Algebra (CUTTING C) R) 
  -- and now, using interiorFoldFusion if it helps,
  -- complete the functor construction

  INTERIOR : (I ->SET) => (I ->SET)
  INTERIOR = record
    { F-Obj      = Interior C
    ; F-map      = interior
    ; F-map-id~> = extensionality \ i -> extensionality \ x -> help i x
    ; F-map->~>  = \ f g -> help' f g
    } where 
      help : {T : I -> Set} (i : I)
         (x : Interior C T i) ->
       interior (\ i x -> x) i x == x

      -- TODO : merge two branches
      help i (tile x) = refl (tile x)
      help i < cut 8>< pieces > = 
        interior (\ i x -> x) i < cut 8>< pieces >
        =[ refl _ >= interiorBind (\ i x -> tile x) i < cut 8>< pieces >
        =[ refl _ >= interiorFold (\ i x -> tile x) (\ i -> <_>) i < cut 8>< pieces >
        =[ refl <_> =$= (refl (cut 8><_) =$= (allInteriorFoldLaw (\ i x -> tile x) (\ i -> <_>) =$ (inners cut) =$ pieces ))  >= 
        < cut 8>< all (interiorFold (\ i x -> tile x) (\ i -> <_>)) (inners cut) pieces >
        =[ refl <_> =$= (refl (cut 8><_) =$= 
          allinteriorFoldLemma 
            (\ i x -> tile x)  (\ i -> <_>)  (\ i x -> x) 
            (\ i p -> refl (tile p)) (\ i cut ps -> refl <_> =$= (refl (cut 8><_) =$= (allId~> (inners cut) ps)))
            (inners cut) pieces
          )>=
        < cut 8>< all (\ i x -> x) (inners cut) pieces >
        =[ refl <_> =$= (refl (cut 8><_) =$= (allId~> (inners cut) pieces)) >=
        < cut 8>< pieces > [QED]
      help' : {R S T : I -> Set}
          (rs : [ R -:> S ]) (st : [ S -:> T ]) -> 
        interior (\  i x -> st i (rs i x)) ==
          (\  i x -> interior st i (interior rs i x))
      help' rs st = 
        interior (\  i x -> st i (rs i x))
        =[ refl _ >=
        interiorBind (\ i -> \ x -> tile (st i (rs i x)))
        =[ refl _ >=
        interiorFold (\ i -> \ x -> tile (st i (rs i x))) (\ i -> <_>)
        =[ sym (interiorFoldFusion rs (\ i x -> tile (st i x)) (\ i -> <_>))  >=
        (\ i x -> interiorFold (\ i x -> tile (st i x)) (\ i -> <_>) i (interior rs i x))
        =< refl _ ]=
        (\ i x -> interiorBind (\  i x -> tile (st i x)) i (interior rs i x))
        =< refl _  ]=
        (\ i x -> interior st i (interior rs i x))
        [QED]
      open _=>_ (ALL I)
--??--------------------------------------------------------------------------

  -- Now let's build the Monad.
  -- You should find that all the laws you have to prove follow from the
  -- fusion laws you already have.

  open MONAD INTERIOR

--??--2.13-(5)----------------------------------------------------------------

  WRAP : ID ~~> INTERIOR
  WRAP = record
    { xf         = \ i x -> tile x
    ; naturality = \ f -> extensionality \ i -> extensionality \ x  -> help f i x
    } where 
    help : {X Y : I -> Set}
          (f : [ X -:> Y ]) (i : I) (x : X i) ->
          (interior f) i (tile x) == tile (f i x)
    help {X} {Y} f i x with interior f i (tile x)
    ... | z = refl z

  -- use interiorBind to define the following
  -- above hint is misleading when implementing
  FLATTEN : (INTERIOR >=> INTERIOR) ~~> INTERIOR
  FLATTEN = record
    { -- xf      = \ i x -> interiorFold (\ i x -> x) cut' i x
      xf         = interiorBind (\ i x -> x)
    ; naturality = \ f -> extensionality \ i -> extensionality \ x -> naturalityHelp f i x
    } where
    naturalityHelp : {X Y : I -> Set}
         (f : [ X -:> Y ]) (i : I) (x :  Interior C (Interior C X) i ) ->
       interiorBind (\ i x -> x) i (interior (interior f) i x) ==
       interior f i (interiorBind (\ i x -> x) i x)
    naturalityHelp f i x =
      interiorBind (\ i x -> x) i (interior (interior f) i x)
      =[ refl _ >= 
      interiorFold (\ i x -> x) (\ i -> <_>) i (interior (interior f) i x)
      =[ interiorFoldFusion (interior f) (\ i x -> x) (\ i -> <_>) =$ i =$ x >=
      interiorFold (\ i x -> ((interior f) i x)) (\ i -> <_>) i x 
      =[ refl _ >=
      interiorFold (\ i x -> interiorFold (\ i x -> tile (f i x)) (\ i -> <_>) i x) (\ i -> <_>) i x
      =< interiorBindFusion (λ i₁ x₁ → x₁) (\ i x -> tile (f i x)) (\ i -> <_>) =$ i =$ x ]=
      interiorFold (\ i x -> tile (f i x)) (\ i -> <_>) i (interiorBind (λ i₁ x₁ → x₁) i x) 
      =< refl _ ]= 
      interior f i (interiorBind (\ i x -> x) i x) 
      [QED]

  INTERIOR-Monad : Monad
  INTERIOR-Monad = record
    { unit = WRAP
    ; mult = FLATTEN
    ; unitMult = extensionality \ i -> extensionality \ x -> refl x
    ; multUnit = extensionality \ i -> extensionality \ x -> multUnitHelp i x
    ; multMult = extensionality \ i -> extensionality \ x -> multMultHelp i x
    } where

    multUnitHelp : {X : I -> Set } (i : I)
         (x : Interior C X i ) ->
      interiorBind (\ i x -> x) i (interior (\ i x -> tile x) i x) == x
    multUnitHelp i x = 
      interiorBind (\ i x -> x) i (interior (\ i x -> tile x) i x)
      =[ refl _ >=
      interiorFold (\ i x -> x) (\ i -> <_>) i (interior (\ i x -> tile x) i x)
      =[ ( (interiorFoldFusion (\ i x -> tile x) (\ i x -> x) (\ i -> <_>))) =$ i =$ x >=
      interiorFold (\ i x -> tile x) (\ i -> <_>) i x
      =[ interiorFoldLemma 
            (\ i x -> tile x)  (\ i -> <_>)  (\ i x -> x) 
            (\ i p -> refl (tile p)) (\ i cut ps -> refl <_> =$= (refl (cut 8><_) =$= (allId~> (inners cut) ps))) i x >=
      x [QED]

    multMultHelp :  {X : Category.Obj (I ->SET)} (i : I)
       (x : Interior C (Interior C (Interior C X)) i ) -> 
       interiorBind (\ i x -> x) i  (interiorBind (\ i x -> x) i x) ==
          interiorBind (\ i x -> x) i (interior (interiorBind (\ i x -> x)) i x)
    multMultHelp i x =
      interiorBind (\ i x -> x) i  (interiorBind (\ i x -> x) i x)
      =[ refl _ >= 
      interiorFold (\ i x -> x) (\ i -> <_>) i (interiorBind (\ i x -> x) i x)
      =[ interiorBindFusion (\ i x -> x) (\ i x -> x) (\ i -> <_>) =$ i =$ x >= 
      interiorFold (\ i x -> ((interiorBind (\ i x -> x)) i x)) (\ i -> <_>) i x
      =< interiorFoldFusion (interiorBind (\ i x -> x)) (\ i x -> x) (\ i -> <_>) =$ i =$ x ]=
      interiorFold (\ i x -> x) (\ i -> <_>) i (interior (interiorBind (\ i x -> x)) i x)
      =< refl _ ]=
      interiorBind (\ i x -> x) i (interior (interiorBind (\ i x -> x)) i x)
      [QED]
    open _=>_ INTERIOR

--??--------------------------------------------------------------------------

open INTERIOR
open INTERIORFOLD


-- You should be able to define an algebra on vectors for NatCut, using +V

--??--2.14-(2)----------------------------------------------------------------

NatCutVecAlg : {X : Set} -> Algebra (CUTTING NatCut) (Vec X)
NatCutVecAlg d (m , n , m+n=d 8>< vm , vn , _) rewrite (sym m+n=d) = vm +V vn
--??--------------------------------------------------------------------------

-- Check that it puts things together suitably when you evaluate this:

test1 : Vec Char 13
test1 = interiorFold (\ _ -> id) NatCutVecAlg 13 subbookkeeper


------------------------------------------------------------------------------
-- Cutting Up Pairs
------------------------------------------------------------------------------

module CHOICE where
  open _|>_

--??--2.15-(2)----------------------------------------------------------------

  -- Show that if you can cut up I and cut up J, then you can cut up I * J.
  -- You now have two dimensions (I and J). The idea is that you choose one
  -- dimension in which to make a cut, and keep everything in the other
  -- dimension the same.

  _+C_ : {I J : Set} ->  I |> I ->  J |> J  ->  (I * J) |> (I * J)
  Cuts   (P +C Q) (i , j) = Cuts P i + Cuts Q j
  inners (P +C Q) {i , j} 
   = \ { (inl x) -> list (\ i -> i , j) (inners P x)
       ; (inr x) -> list (\ j -> i , j) (inners Q x)}
  --                                                                                                          ; (inr x) -> {! inners x !}} 
--??--------------------------------------------------------------------------

open CHOICE

-- That should get us the ability to cut up *rectangules* by cutting either
-- vertically or horizontally.

NatCut2D : (Nat * Nat) |> (Nat * Nat)
NatCut2D = NatCut +C NatCut

Matrix : Set -> Nat * Nat -> Set
Matrix X (w , h) = Vec (Vec X w) h

-- If you've done it right, you should find that the following typechecks.
-- It's the interior of a rectangle, tiled with matrices of characters.

rectangle : Interior NatCut2D (Matrix Char) (15 , 6)
rectangle = < inr (4 , 2 , refl _)
            8>< < inl (7 , 8 , refl _)
                8>< tile (strVec "seventy"
                       ,- strVec "kitchen"
                       ,- strVec "program"
                       ,- strVec "mistake"
                       ,- [])
                  , tile (strVec "thousand"
                       ,- strVec "soldiers"
                       ,- strVec "probably"
                       ,- strVec "undefine"
                       ,- [])
                  , <> >
              , tile (strVec "acknowledgement"
                   ,- strVec "procrastination"
                   ,- [])
              , <> >

-- Later, we'll use rectangular interiors as the underlying data structure
-- for a window manager.

-- But for now, one last thing.

--??--2.16-(4)----------------------------------------------------------------

-- Show that if you have a vector of n Ps for every element of a list,
-- then you can make a vector of n (All P)s .
-- Hint: Ex1 provides some useful equipment for this job.

vecAll : {I : Set}{P : I -> Set}{is : List I}{n : Nat} ->
         All (\ i -> Vec (P i) n) is -> Vec (All P is) n
vecAll {is = []} pss = vPure <>
vecAll {is = x ,- is} (ps , pss) = vec _,_ ps $V vecAll {is = is} pss

-- Given vecAll, show that algebra for any cutting can be lifted
-- to an algebra on vectors.

VecLiftAlg : {I : Set}(C : I |> I){X : I -> Set}
             (alg : Algebra (CUTTING C) X){n : Nat} ->
             Algebra (CUTTING C) (\ i -> Vec (X i) n)
VecLiftAlg record { Cuts = Cuts ; inners = inners } alg {n} i (c 8>< pss) = VecLiftAlgHelp alg i c (vecAll pss)
  where 
    VecLiftAlgHelp : ∀ {I} {Cuts : I -> Set} {inners : {o : I} -> Cuts o -> List I}
            {X : I -> Set} {n} -> ((i : I) -> Cutting (record { Cuts = Cuts ; inners = inners }) X i -> X i) ->
          (i : I) (c : Cuts i) -> Vec (All X (inners c)) n -> Vec (X i) n
    VecLiftAlgHelp alg i c [] = []
    VecLiftAlgHelp alg i c (ps ,- pss) = alg i (c 8>< ps) ,- VecLiftAlgHelp alg i c pss


NatCut2DMatAlg : {X : Set} -> Algebra (CUTTING NatCut2D) (Matrix X)
NatCut2DMatAlg {x} (i , j) (inl (i1 , i2 , i1+i2=i) 8>< mi1 , mi2 , _) rewrite (sym i1+i2=i) = (vec _+V_ mi1) $V mi2
NatCut2DMatAlg {x} (i , j) (inr (j1 , j2 , j1+j2=j) 8>< mj1 , mj2 , _) rewrite (sym j1+j2=j) = mj1 +V mj2

--??--------------------------------------------------------------------------

-- And that should give you a way to glue pictures together from interiors.

picture : [ Interior NatCut2D (Matrix Char) -:> Matrix Char ]
picture = interiorFold (\ _ -> id) NatCut2DMatAlg

-- You should be able to check that the following gives you something
-- sensible:

test2 = picture _ rectangle
