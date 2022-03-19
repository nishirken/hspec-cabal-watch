{-# LANGUAGE OverloadedStrings  #-}

module Main where

import qualified Shelly as Sh
import qualified Console.Options as Cli
import Data.Text (pack, unpack)
import Data.Maybe (fromMaybe)

main :: IO ()
main = Cli.defaultMain $ do
  cabalArgs <- Cli.flagParam (Cli.FlagLong "cabal-args") $ Cli.FlagOptional "" Right
  match <- Cli.flagParam (Cli.FlagLong "match") $ Cli.FlagOptional "" Right
  Cli.action $ \toParam -> Sh.shelly $ do
    hasGit <- Sh.test_e ".gitignore"
    let
      lsCmd = if hasGit then "git ls-files" else "ls -R"
      withQuotes str = "\"" <> str <> "\""
      grepRegex = withQuotes "\\.\\(hs\\|cabal\\)$"
      watchFiles = lsCmd <> " | grep " <> grepRegex
      matchArgs = fromMaybe "" $ do
        cmd' <- toParam match
        pure $ "--test-option=--match --test-option=" <> withQuotes cmd'
      cabalCmd = unwords
        [ "cabal v2-test"
        , "--test-show-details=direct"
        , "--disable-optimization"
        , matchArgs
        , fromMaybe "" $ toParam cabalArgs
        ]
    Sh.bash_ (watchFiles <> " | " <> "entr -s " <> withQuotes cabalCmd) []

