{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MagicHash #-}

-- | See "Control.Monad.Reader.Class".

module Control.Monad.Ether.Reader.Class
  ( MonadReader(..)
  ) where

import GHC.Prim (Proxy#)
import qualified Control.Monad.Trans.Lift.Local as Lift

-- | See 'Control.Monad.Reader.MonadReader'.
class Monad m => MonadReader tag r m | m tag -> r where

    {-# MINIMAL (ask | reader), local #-}

    -- | Retrieves the monad environment.
    ask :: Proxy# tag -> m r
    ask t = reader t id

    -- | Executes a computation in a modified environment.
    local
        :: Proxy# tag
        -> (r -> r)
        -- ^ The function to modify the environment.
        -> m a
        -- ^ @Reader@ to run in the modified environment.
        -> m a

    -- | Retrieves a function of the current environment.
    reader
        :: Proxy# tag
        -> (r -> a)
        -- ^ The selector function to apply to the environment.
        -> m a
    reader t f = fmap f (ask t)

instance {-# OVERLAPPABLE #-}
         ( Lift.LiftLocal t
         , Monad (t m)
         , MonadReader tag r m
         ) => MonadReader tag r (t m) where
    ask t = Lift.lift (ask t)
    local t = Lift.liftLocal (ask t) (local t)