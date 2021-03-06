module Ether.TaggedTrans
  ( TaggedTrans(..)
  ) where

import Control.Applicative
import Control.Monad (MonadPlus)
import Control.Monad.Fix (MonadFix)
import Control.Monad.Trans.Class (MonadTrans, lift)
import Control.Monad.IO.Class (MonadIO)
import Control.Monad.Morph (MFunctor, MMonad)
import Control.Monad.Catch (MonadThrow, MonadCatch, MonadMask)

import qualified Control.Monad.Base as MB
import qualified Control.Monad.Trans.Control as MC

import qualified Control.Monad.Trans.Lift.StT    as Lift
import qualified Control.Monad.Trans.Lift.Local  as Lift
import qualified Control.Monad.Trans.Lift.Catch  as Lift
import qualified Control.Monad.Trans.Lift.Listen as Lift
import qualified Control.Monad.Trans.Lift.Pass   as Lift
import qualified Control.Monad.Trans.Lift.CallCC as Lift

import qualified Control.Monad.Cont.Class    as Mtl
import qualified Control.Monad.Reader.Class  as Mtl
import qualified Control.Monad.State.Class   as Mtl
import qualified Control.Monad.Writer.Class  as Mtl
import qualified Control.Monad.Error.Class   as Mtl

import GHC.Generics (Generic)
import Data.Coerce (coerce)

newtype TaggedTrans tag trans m a = TaggedTrans (trans m a)
  deriving
    ( Generic
    , Functor, Applicative, Alternative, Monad, MonadPlus
    , MonadFix, MonadTrans, MonadIO, MFunctor, MMonad
    , MonadThrow, MonadCatch, MonadMask )

type Pack tag trans m a = trans m a -> TaggedTrans tag trans m a

type Unpack tag trans m a = TaggedTrans tag trans m a -> trans m a

instance
    ( MB.MonadBase b (trans m)
    ) => MB.MonadBase b (TaggedTrans tag trans m)
  where
    liftBase =
      (coerce :: forall a .
        (b a -> trans m a) ->
        (b a -> TaggedTrans tag trans m a))
      MB.liftBase
    {-# INLINE liftBase #-}

instance
    ( MC.MonadTransControl trans
    ) => MC.MonadTransControl (TaggedTrans tag trans)
  where
    type StT (TaggedTrans tag trans) a = MC.StT trans a

    liftWith = MC.defaultLiftWith
      (coerce :: Pack tag trans m a)
      (coerce :: Unpack tag trans m a)
    {-# INLINE liftWith #-}

    restoreT = MC.defaultRestoreT
      (coerce :: Pack tag trans m a)
    {-# INLINE restoreT #-}

type LiftBaseWith b m a = (MC.RunInBase m b -> b a) -> m a

newtype LiftBaseWith' b m a = LBW { unLBW :: LiftBaseWith b m a }

coerceLiftBaseWith ::
  LiftBaseWith b                 (trans m) a ->
  LiftBaseWith b (TaggedTrans tag trans m) a
coerceLiftBaseWith lbw =
  unLBW (coerce (LBW lbw))
{-# INLINE coerceLiftBaseWith #-}

instance
    ( MC.MonadBaseControl b (trans m)
    ) => MC.MonadBaseControl b (TaggedTrans tag trans m)
  where
    type StM (TaggedTrans tag trans m) a = MC.StM (trans m) a

    liftBaseWith = coerceLiftBaseWith MC.liftBaseWith
    {-# INLINE liftBaseWith #-}

    restoreM =
      (coerce :: forall a .
        (MC.StM (trans m) a ->                 trans m a) ->
        (MC.StM (trans m) a -> TaggedTrans tag trans m a))
      MC.restoreM
    {-# INLINE restoreM #-}

type instance Lift.StT (TaggedTrans tag trans) a = Lift.StT trans a

instance Lift.LiftLocal trans => Lift.LiftLocal (TaggedTrans tag trans) where
  liftLocal =
    Lift.defaultLiftLocal
      (coerce :: Pack tag trans m a)
      (coerce :: Unpack tag trans m a)

instance Lift.LiftCatch trans => Lift.LiftCatch (TaggedTrans tag trans) where
  liftCatch =
    Lift.defaultLiftCatch
      (coerce :: Pack tag trans m a)
      (coerce :: Unpack tag trans m a)

instance Lift.LiftListen trans => Lift.LiftListen (TaggedTrans tag trans) where
  liftListen =
    Lift.defaultLiftListen
      (coerce :: Pack tag trans m a)
      (coerce :: Unpack tag trans m a)

instance Lift.LiftPass trans => Lift.LiftPass (TaggedTrans tag trans) where
  liftPass =
    Lift.defaultLiftPass
      (coerce :: Pack tag trans m a)
      (coerce :: Unpack tag trans m a)

instance Lift.LiftCallCC trans => Lift.LiftCallCC (TaggedTrans tag trans) where
  liftCallCC  =
    Lift.defaultLiftCallCC
      (coerce :: Pack tag trans m a)
      (coerce :: Unpack tag trans m a)
  liftCallCC' =
    Lift.defaultLiftCallCC'
      (coerce :: Pack tag trans m a)
      (coerce :: Unpack tag trans m a)


-- Instances for mtl classes

instance
    ( Mtl.MonadCont m
    , Lift.LiftCallCC trans
    , Monad (trans m)
    ) => Mtl.MonadCont (TaggedTrans tag trans m)
  where
    callCC = Lift.liftCallCC' Mtl.callCC

instance
    ( Mtl.MonadReader r m
    , Lift.LiftLocal trans
    , Monad (trans m)
    ) => Mtl.MonadReader r (TaggedTrans tag trans m)
  where
    ask = lift Mtl.ask
    local = Lift.liftLocal Mtl.ask Mtl.local
    reader = lift . Mtl.reader

instance
    ( Mtl.MonadState s m
    , MonadTrans trans
    , Monad (trans m)
    ) => Mtl.MonadState s (TaggedTrans tag trans m)
  where
    get = lift Mtl.get
    put = lift . Mtl.put
    state = lift . Mtl.state

instance
    ( Mtl.MonadWriter w m
    , Lift.LiftListen trans
    , Lift.LiftPass trans
    , Monad (trans m)
    ) => Mtl.MonadWriter w (TaggedTrans tag trans m)
  where
    writer = lift . Mtl.writer
    tell   = lift . Mtl.tell
    listen = Lift.liftListen Mtl.listen
    pass   = Lift.liftPass Mtl.pass

instance
    ( Mtl.MonadError e m
    , Lift.LiftCatch trans
    , Monad (trans m)
    ) => Mtl.MonadError e (TaggedTrans tag trans m)
  where
    throwError = lift . Mtl.throwError
    catchError = Lift.liftCatch Mtl.catchError
