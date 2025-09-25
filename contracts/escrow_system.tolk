// Below you will find an EscrowSystem contract that allows user to initialize an escrow, request funds, release funds, and cancel escrow.
// The EscrowSystem struct is the main storage of the contract.
// It contains:
// - owner: address
// - recipient: address
// - amount: uint64
// - isReleased: bool
// - isRequested: bool

// Your task it to fix the errors in the contract and make it work as expected.

// Helpful Blueprint sdk commands:
// - npx blueprint build - To build the contract
// - npx blueprint test tests/EscrowSystem.spec.ts - To test the contract

tolk 1.1

struct EscrowSystem {
    owner: address;
    recipient: address;
    amount: uint64;
    isReleased: bool;
    isRequested: bool;
}

fun EscrowSystem.load() {
    return EscrowSystem.fromCell(contract.getData());
}
fun EscrowSystem.store(self) {
    contract.setData(self.toCell());
}

struct (0xE3D2C1B4) InitializeEscrow {
    queryId: uint32
    recipient: address
    amount: uint64
}
struct (0xF4E3D2C1) RequestFunds {
    queryId: uint32
}
struct (0xA1B2C3D4) ReleaseFunds {
    queryId: uint32
}
struct (0xB1C2D3E4) CancelEscrow {
    queryId: uint32
}

type MessageBody = RequestFunds | ReleaseFunds | CancelEscrow | InitializeEscrow

fun onInternalMessage(in: InMessage) {
    val msg = lazy MessageBody.fromSlice(in.body);
    
    match (msg) {
        InitializeEscrow => {
            var escrow = lazy EscrowSystem.load();
            escrow.owner = in.senderAddress;
            escrow.recipient = msg.recipient;
            escrow.amount = msg.amount;
            escrow.isReleased = false;
            escrow.isRequested = false;
            escrow.store();
        }
        RequestFunds => {
            var escrow = lazy EscrowSystem.load();
            assert (in.senderAddress == escrow.recipient) throw 101;
            assert (!escrow.isRequested) throw 102;
            escrow.isRequested = true;
            escrow.store();
        }
        ReleaseFunds => {
            var escrow = lazy EscrowSystem.load();
            assert (in.senderAddress == escrow.owner) throw 103;
            assert (escrow.isRequested) throw 108;
            assert (!escrow.isReleased) throw 109;
            escrow.isReleased = true;
            escrow.store();
            val res = createMessage({
                bounce: false,
                dest: escrow.recipient,
                value: contract.getOriginalBalance() - 100000000 
            });
            res.send(SEND_MODE_CARRY_ALL_BALANCE);
        }
        CancelEscrow=>{
            var escrow = lazy EscrowSystem.load();
            assert (in.senderAddress == escrow.owner) throw 104;
            assert (!escrow.isReleased) throw 107;
            escrow.isReleased = true;
            escrow.store();
            val res = createMessage({
                bounce: false,
                dest: in.senderAddress, 
                value: contract.getOriginalBalance() - 100000000 
            });
            res.send(SEND_MODE_CARRY_ALL_BALANCE);
        }
        else => {
            assert (in.body.isEmpty()) throw 100;
        }
    }
}

get fun getEscrowDetails(): (address, address, uint64 , bool, bool) {
    var escrow = lazy EscrowSystem.load();
    return (escrow.owner, escrow.recipient, escrow.amount, escrow.isReleased, escrow.isRequested);
}