module Main where

import Test.Tasty

import Regression.T1
import Regression.T2
import Regression.T3
import Regression.T4
import Regression.T5
import Regression.T6
import Regression.T7
import Regression.T8
import Regression.T9

main :: IO ()
main = defaultMain suite

suite :: TestTree
suite = testGroup "Ether"
  [ test1
  , test2
  , test3
  , test4
  , test5
  , test6
  , test7
  , test8
  , test9
  ]
