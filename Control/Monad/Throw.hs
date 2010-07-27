{- | This is just like "Control.Monad.Error.Class" except you can throw/catch the error of any ErrorT in the monad stack instead of just the top one as long as the error types are different. If two or more ErrorTs in the stack have the same error type you get the error of the top one. -}

{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances, OverlappingInstances #-}

module Control.Monad.Throw where

import Prelude hiding (catch)
import Control.Monad.Reader
import Control.Monad.Error

-- | Same as 'MonadError' but without functional dependency so the same monad can have multiple errors with different types
class (Monad m) => Throw e m where
	throw :: e -> m a
	-- ^ Abort action and throw give exception. Analogous to 'throwError'.
	catch :: m a -> (e -> m a) -> m a 
	-- ^ If first action aborts with exception then execute second action. Analogous to 'catchError'

throwLeft :: (Throw e m) => m (Either e a) -> m a
-- ^ Execute action and throw exception if result is Left, otherwise return the Right result
throwLeft = (either throw return =<<)

instance (Error e) => Throw e (Either e) where
	throw = throwError
	catch = catchError

instance (Error e, Monad m) => Throw e (ErrorT e m) where
	throw = throwError
	catch = catchError

instance (Error e, Throw e m, Error x) => Throw e (ErrorT x m) where
	throw = lift . throw
	catch a h = ErrorT $ catch (runErrorT a) (runErrorT . h)

instance (Throw e m) => Throw e (ReaderT x m) where
	throw = lift . throw
	catch a h = ReaderT $ \x -> catch (runReaderT a x) (flip runReaderT x . h)