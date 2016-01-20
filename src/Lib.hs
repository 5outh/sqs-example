{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

module Lib
    ( go
    ) where

import qualified Aws
import qualified Aws.Core
import qualified Aws.S3                       as S3
import qualified Aws.Sqs                      as Sqs
import           Aws.Sqs.Core                 hiding (sqs)
import           Control.Concurrent
import           Control.Error
import           Control.Monad                (forM, forM_, replicateM)
import           Control.Monad.IO.Class
import           Control.Monad.Trans.Resource (runResourceT)
import           Data.Conduit                 (($$+-))
import           Data.Conduit.Binary          (sinkFile)
import           Data.Monoid
import           Data.String
import qualified Data.Text                    as T
import qualified Data.Text.IO                 as T
import qualified Data.Text.Read               as TR
import           Network.HTTP.Conduit

sqsEndpointUsEast :: Endpoint
sqsEndpointUsEast
    = Endpoint {
        endpointHost = "sqs.us-east-1.amazonaws.com"
      , endpointDefaultLocationConstraint = "us-east-1"
      , endpointAllowedLocationConstraints = ["us-east-1"]
      }

data SQSContext = SQSContext
  { aws       :: Aws.Configuration
  , sqs       :: Sqs.SqsConfiguration Aws.NormalQuery
  , queueName :: Sqs.QueueName
  }

data QueueContext = QueueContext
  { queueContext :: SQSContext
  , manager      :: Manager
  }

data QueueError
  = QueueEmpty
  | GenericFailure
    deriving (Show, Eq)

data PullRequest = PullRequest
  { maxMessages :: Int
  } deriving (Show, Eq)

pull :: MonadIO io
     => QueueContext
     -> Int
     -> io (Either QueueError [Sqs.Message])
pull QueueContext{..} n = do
  Sqs.ReceiveMessageResponse msgs <-
    Aws.simpleAws (aws queueContext) (sqs queueContext) req
  return (case msgs of
    [] -> Left QueueEmpty
    _ -> Right msgs)
  where req = Sqs.ReceiveMessage
                Nothing
                []
                (Just n)
                []
                (queueName queueContext)
                (Just 20)

go :: IO ()
go = do
  cfg <- Aws.baseConfiguration
  manager <- newManager tlsManagerSettings

  let sqscfg = Sqs.sqs Aws.Core.HTTP sqsEndpointUsEast False :: Sqs.SqsConfiguration Aws.NormalQuery
  let sqsQueueName = Sqs.QueueName "test-queue" "632433445472"
  let ctx = QueueContext (SQSContext cfg sqscfg sqsQueueName) manager

  res <- pull ctx 1
  print res
