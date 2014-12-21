
module VM.Opcodes where

import Prelude hiding (LT, GT, EQ)

import Data.Binary
import qualified Data.ByteString as B
import Data.Functor
import qualified Data.Map as M
import Data.Maybe
import Numeric
import Text.PrettyPrint.ANSI.Leijen hiding ((<$>))

import Util

--import Debug.Trace

data Operation = 
    STOP | ADD | MUL | SUB | DIV | SDIV | MOD | SMOD | ADDMOD | MULMOD | EXP | SIGNEXTEND | NEG | LT | GT | SLT | SGT | EQ | ISZERO | NOT | AND | OR | XOR | BYTE | SHA3 | 
    ADDRESS | BALANCE | ORIGIN | CALLER | CALLVALUE | CALLDATALOAD | CALLDATASIZE | CALLDATACOPY | CODESIZE | CODECOPY | GASPRICE | EXTCODESIZE | EXTCODECOPY |
    PREVHASH | COINBASE | TIMESTAMP | NUMBER | DIFFICULTY | GASLIMIT | POP | DUP | SWAP | MLOAD | MSTORE | MSTORE8 | SLOAD | SSTORE | 
    JUMP | JUMPI | PC | MSIZE | GAS | JUMPDEST | 
    PUSH [Word8] | 
    DUP1 | DUP2 | DUP3 | DUP4 |
    DUP5 | DUP6 | DUP7 | DUP8 |
    DUP9 | DUP10 | DUP11 | DUP12 |
    DUP13 | DUP14 | DUP15 | DUP16 |
    CREATE | CALL | RETURN | CALLCODE | SUICIDE |
    --Pseudo Opcodes
    LABEL String | PUSHLABEL String |
    PUSHDIFF String String | DATA B.ByteString |
    MalformedOpcode deriving (Show, Eq, Ord)

instance Pretty Operation where
  pretty x@JUMPDEST = text $ "------" ++ show x
  pretty x@(PUSH vals) = text $ show x ++ " --" ++ show (bytes2Integer vals)
  pretty x = text $ show x

data OPData = OPData Word8 Operation Int Int String

type EthCode = [Operation]

singleOp::Operation->([Word8]->Operation, Int)
singleOp o = (const o, 1)

opDatas::[OPData]
opDatas = 
  [
    OPData 0x00 STOP 0 0 "Halts execution.",
    OPData 0x01 ADD 2 1 "Addition operation.",
    OPData 0x02 MUL 2 1 "Multiplication operation.",
    OPData 0x03 SUB 2 1 "Subtraction operation.",
    OPData 0x04 DIV 2 1 "Integer division operation.",
    OPData 0x05 SDIV 2 1 "Signed integer division operation.",
    OPData 0x06 MOD 2 1 "Modulo remainder operation.",
    OPData 0x07 SMOD 2 1 "Signed modulo remainder operation.",
    OPData 0x08 ADDMOD 2 1 "unsigned modular addition",
    OPData 0x09 MULMOD 2 1 "unsigned modular multiplication",
    OPData 0x0a EXP 2 1 "Exponential operation.",
    OPData 0x0b SIGNEXTEND undefined undefined undefined,

    OPData 0x10 LT 2 1 "Less-than comparision.",
    OPData 0x11 GT 2 1 "Greater-than comparision.",
    OPData 0x12 SLT 2 1 "Signed less-than comparision.",
    OPData 0x13 SGT 2 1 "Signed greater-than comparision.",
    OPData 0x14 EQ 2 1 "Equality comparision.",
    OPData 0x15 ISZERO 1 1 "Simple not operator.",
    OPData 0x16 AND 2 1 "Bitwise AND operation.",
    OPData 0x17 OR 2 1 "Bitwise OR operation.",
    OPData 0x18 XOR 2 1 "Bitwise XOR operation.",
    OPData 0x19 NOT 1 1 "Bitwise not operator.",
    OPData 0x1a BYTE 2 1 "Retrieve single byte from word.",

    OPData 0x20 SHA3 2 1 "Compute SHA3-256 hash.",

    OPData 0x30 ADDRESS 0 1 "Get address of currently executing account.",
    OPData 0x31 BALANCE 1 1 "Get balance of the given account.",
    OPData 0x32 ORIGIN 0 1 "Get execution origination address.",
    OPData 0x33 CALLER 0 1 "Get caller address.",
    OPData 0x34 CALLVALUE 0 1 "Get deposited value by the instruction/transaction responsible for this execution.",
    OPData 0x35 CALLDATALOAD 1 1 "Get input data of current environment.",
    OPData 0x36 CALLDATASIZE 0 1 "Get size of input data in current environment.",
    OPData 0x37 CALLDATACOPY 3 0 "Copy input data in current environment to memory.",
    OPData 0x38 CODESIZE 0 1 "Get size of code running in current environment.",
    OPData 0x39 CODECOPY 3 0 "Copy code running in current environment to memory.",
    OPData 0x3a GASPRICE 0 1 "Get price of gas in current environment.",
    OPData 0x3b EXTCODESIZE undefined undefined "get external code size (from another contract)",
    OPData 0x3c EXTCODECOPY undefined undefined "copy external code (from another contract)",

    OPData 0x40 PREVHASH 0 1 "Get hash of most recent complete block.",
    OPData 0x41 COINBASE 0 1 "Get the block’s coinbase address.",
    OPData 0x42 TIMESTAMP 0 1 "Get the block’s timestamp.",
    OPData 0x43 NUMBER 0 1 "Get the block’s number.",
    OPData 0x44 DIFFICULTY 0 1 "Get the block’s difficulty.",
    OPData 0x45 GASLIMIT 0 1 "Get the block’s gas limit.",

    OPData 0x50 POP 1 0 "Remove item from stack.",
    OPData 0x51 MLOAD 1 1 "Load word from memory.",
    OPData 0x52 MSTORE 2 0 "Save word to memory.",
    OPData 0x53 MSTORE8 2 0 "Save byte to memory.",
    OPData 0x54 SLOAD 1 1 "Load word from storage.",
    OPData 0x55 SSTORE 2 0 "Save word to storage.",
    OPData 0x56 JUMP 1 0 "Alter the program counter.",
    OPData 0x57 JUMPI 2 0 "Conditionally alter the program counter.",
    OPData 0x58 PC 0 1 "Get the program counter.",
    OPData 0x59 MSIZE 0 1 "Get the size of active memory in bytes.",
    OPData 0x5a GAS 0 1 "Get the amount of available gas.",
    OPData 0x5b JUMPDEST undefined undefined "set a potential jump destination",

    OPData 0x80 DUP1 undefined undefined undefined,
    OPData 0x81 DUP2 undefined undefined undefined,
    OPData 0x82 DUP3 undefined undefined undefined,
    OPData 0x83 DUP4 undefined undefined undefined,
    OPData 0x84 DUP5 undefined undefined undefined,
    OPData 0x85 DUP6 undefined undefined undefined,
    OPData 0x86 DUP7 undefined undefined undefined,
    OPData 0x87 DUP8 undefined undefined undefined,
    OPData 0x88 DUP9 undefined undefined undefined,
    OPData 0x89 DUP10 undefined undefined undefined,
    OPData 0x8a DUP11 undefined undefined undefined,
    OPData 0x8b DUP12 undefined undefined undefined,
    OPData 0x8c DUP13 undefined undefined undefined,
    OPData 0x8d DUP14 undefined undefined undefined,
    OPData 0x8e DUP15 undefined undefined undefined,
    OPData 0x8f DUP16 undefined undefined undefined,

    OPData 0xf0 CREATE 3 1 "Create a new account with associated code.",
    OPData 0xf1 CALL 7 1 "Message-call into an account.",
    OPData 0xf2 CALLCODE undefined undefined "message-call with another account's code only",
    OPData 0xf3 RETURN 2 0 "Halt execution returning output data.",
    OPData 0xff SUICIDE 1 0 "Halt execution and register account for later deletion."
  ]


op2CodeMap::M.Map Operation Word8
op2CodeMap=M.fromList $ (\(OPData code op _ _ _) -> (op, code)) <$> opDatas

code2OpMap::M.Map Word8 Operation
code2OpMap=M.fromList $ (\(OPData opcode op _ _ _) -> (opcode, op)) <$> opDatas

op2OpCode::Operation->[Word8]
op2OpCode (PUSH theList) | length theList <= 32 && not (null theList) =
  0x5F + fromIntegral (length theList):theList
op2OpCode (PUSH []) = error "PUSH needs at least one word"
op2OpCode (PUSH x) = error $ "PUSH can only take up to 32 words: " ++ show x
op2OpCode (DATA bytes) = B.unpack bytes
op2OpCode op =
  case M.lookup op op2CodeMap of
    Just x -> [x]
    Nothing -> error $ "op is missing in op2CodeMap: " ++ show op

opLen::Operation->Int
opLen (PUSH x) = 1 + length x
opLen _ = 1

opCode2Op::B.ByteString->(Operation, Int)
opCode2Op rom | B.null rom = (STOP, 1) --according to the yellowpaper, should return STOP if outside of the code bytestring
opCode2Op rom =
  let opcode = B.head rom in
  if opcode >= 0x60 && opcode <= 0x7f
  then (PUSH $ B.unpack $ B.take (fromIntegral $ opcode-0x5F) $ B.tail rom, fromIntegral $ opcode - 0x5E)
  else
--    let op = fromMaybe (error $ "code is missing in code2OpMap: 0x" ++ showHex (B.head rom) "")
    let op = fromMaybe MalformedOpcode
             $ M.lookup opcode code2OpMap in
    (op, 1)


