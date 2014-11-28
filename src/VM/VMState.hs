
module VM.VMState (
  VMState(..),
  startingState,
  VMException(..),
  addErr,
  getReturnValue
  ) where

import qualified Data.ByteString as B

import ExtWord
import Format
import VM.Code
import VM.Memory

data VMException = OutOfGasException | StackTooSmallException | VMException String deriving (Show)

addErr::String->Code->VMState->IO VMState
addErr message c state = do
  let (op, _) = getOperationAt c (pc state)
  return state{vmException=Just $ VMException (message ++ " for a call to " ++ show op)}

data VMState =
  VMState {
    vmGasRemaining::Integer,
    pc::Int,
    memory::Memory,
    stack::[Word256],

    markedForSuicide::Bool,
    done::Bool,
    returnVal::Maybe B.ByteString,
    
    vmException::Maybe VMException
    }


instance Format VMState where
  format state =
    "pc: " ++ show (pc state) ++ "\n" ++
    "done: " ++ show (done state) ++ "\n" ++
    "gasRemaining: " ++ show (vmGasRemaining state) ++ "\n" ++
    "stack: " ++ show (stack state) ++ "\n"

startingState::IO VMState
startingState = do
  m <- newMemory
  return VMState {
    pc = 0,
    done=False,
    returnVal=Nothing,
    vmException=Nothing,
    vmGasRemaining=0,
    stack=[],
    memory=m, markedForSuicide=False }


getReturnValue::VMState->IO B.ByteString
getReturnValue state = 
  case stack state of
    [add, size] -> mLoadByteString (memory state) add size
    [] -> return B.empty --Happens when STOP is called
    --TODO- This needs better error handling other than to just crash if the stack isn't 2 items long
    _ -> error "Error in getReturnValue: VM ended with stack in an unsupported case"

  
