module Main where

import Prelude
import Bug
import Criterion
import Criterion.Main
import qualified Hasql.Connection as A
import qualified Hasql.Session as B
import qualified Hasql.Query as C
import qualified Hasql.Decoders as D
import qualified Hasql.Encoders as E
import qualified Data.Vector as F


main =
  do
    Right connection <- acquireConnection
    useConnection connection
  where
    acquireConnection =
      A.acquire settings
      where
        settings =
          A.settings host port user password database
          where
            host = "localhost"
            port = 5432
            user = "postgres"
            password = ""
            database = "postgres"
    useConnection connection =
      defaultMain
      [
        sessionBench "largeResultInVector" sessionWithSingleLargeResultInVector
        ,
        sessionBench "largeResultInList" sessionWithSingleLargeResultInList
        ,
        sessionBench "manySmallResults" sessionWithManySmallResults
      ]
      where
        sessionBench :: NFData a => String -> B.Session a -> Benchmark
        sessionBench name session =
          bench name (nfIO (fmap (either ($bug "") id) (B.run session connection)))


-- * Sessions
-------------------------

sessionWithManySmallParameters :: Vector (Int64, Int64) -> B.Session ()
sessionWithManySmallParameters =
  $(todo "sessionWithManySmallParameters")

sessionWithSingleLargeResultInVector :: B.Session (Vector (Int64, Int64))
sessionWithSingleLargeResultInVector =
  B.query () queryWithManyRowsInVector

sessionWithSingleLargeResultInList :: B.Session (List (Int64, Int64))
sessionWithSingleLargeResultInList =
  B.query () queryWithManyRowsInList

sessionWithManySmallResults :: B.Session (Vector (Int64, Int64))
sessionWithManySmallResults =
  F.replicateM 1000 (B.query () queryWithSingleRow)


-- * Statements
-------------------------

queryWithManyParameters :: C.Query (Vector (Int64, Int64)) ()
queryWithManyParameters =
  $(todo "statementWithManyParameters")

queryWithSingleRow :: C.Query () (Int64, Int64)
queryWithSingleRow =
  C.statement template encoder decoder True
  where
    template =
      "SELECT 1, 2"
    encoder =
      conquer
    decoder =
      D.singleRow row
      where
        row =
          tuple <$> D.value D.int8 <*> D.value D.int8
          where
            tuple !a !b =
              (a, b)

queryWithManyRows :: (D.Row (Int64, Int64) -> D.Result result) -> C.Query () result
queryWithManyRows decoder =
  C.statement template encoder (decoder rowDecoder) True
  where
    template =
      "SELECT generate_series(0,1000) as a, generate_series(1000,2000) as b"
    encoder =
      conquer
    rowDecoder =
      tuple <$> D.value D.int8 <*> D.value D.int8
      where
        tuple !a !b =
          (a, b)

queryWithManyRowsInVector :: C.Query () (Vector (Int64, Int64))
queryWithManyRowsInVector =
  queryWithManyRows D.rowsVector

queryWithManyRowsInList :: C.Query () (List (Int64, Int64))
queryWithManyRowsInList =
  queryWithManyRows D.rowsList
