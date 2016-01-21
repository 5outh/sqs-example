module Types where

import qualified Aws
import qualified Aws.Core
import qualified Aws.Sqs                    as Sqs
import           Aws.Sqs.Core               hiding (sqs)
import           Control.Monad
import           Control.Monad.IO.Class
import           Control.Monad.Trans.Reader
import qualified Data.Text                  as T
import           Network.HTTP.Conduit

type QueueM io a = ReaderT SQSContext io (Either QueueError a)

data SQSContext = SQSContext
  { aws       :: Aws.Configuration
  , sqs       :: Sqs.SqsConfiguration Aws.NormalQuery
  , queueName :: Sqs.QueueName
  }

data QueueError
  = QueueEmpty
  | GenericFailure
    deriving (Show, Eq)

data PullRequest = PullRequest
  { maxMessages :: Int
  } deriving (Show, Eq)

data WorkStatus
  = WorkSuccess
  | WorkError T.Text
    deriving (Show, Eq)
