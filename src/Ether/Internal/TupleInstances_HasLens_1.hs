{-# OPTIONS -fno-warn-orphans #-}

module Ether.Internal.TupleInstances_HasLens_1 () where

import Ether.Internal.TH_TupleInstances (makeTupleInstancesHasLens)

makeTupleInstancesHasLens [2..20]
