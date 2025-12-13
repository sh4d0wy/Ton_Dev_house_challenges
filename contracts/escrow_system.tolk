fun loadEscrow(): EscrowSystem {
    return EscrowSystem.fromCell(contract.getData());
}

fun storeEscrow(self: EscrowSystem) {
    contract.setData(self);
}

// contracts/escrow_system.tolk
// EscrowSystem contract - fixed version

struct EscrowSystem {
    owner: address;
    recipient: address;
    amount: uint64;
    isReleased: bool;
    isRequested: bool;
}

static fun EscrowSystem.load(): EscrowSystem {
    return EscrowSystem.fromCell(contract.getData());
}

static fun EscrowSystem.store(self: EscrowSystem) {
    contract.setData(self);
}

struct (0xE3D2C1B4) InitializeEscrow {
    queryId: uint32;
    recipient: address;
    amount: uint64;
}
struct (0xF4E3D2C1) RequestFunds {
    queryId: uint32;
}
struct (0xA1B2C3D4) ReleaseFunds {
    queryId: uint32;
}
struct (0xB1C2D3E4) CancelEscrow {
    queryId: uint32;
}

type MessageBody = InitializeEscrow | RequestFunds | ReleaseFunds | CancelEscrow;

fun onInternalMessage(in: InMessage) {
    val msg = lazy MessageBody.fromSlice(in.body);

    match (msg) {
        InitializeEscrow => {
            val payload = msg as InitializeEscrow;
            var escrow = lazy EscrowSystem.load();

            // owner is the account that sent this internal message (initializer)
            escrow.owner = in.senderAddress;
            escrow.recipient = payload.recipient;
            escrow.amount = payload.amount;
            escrow.isReleased = false;
            escrow.isRequested = false;

            escrow.store();
        }

        RequestFunds => {
            val payload = msg as RequestFunds;
            var escrow = lazy EscrowSystem.load();

            // only the recipient may request funds
            assert (in.senderAddress == escrow.recipient) throw 101;

            // must not be already requested
            assert (!escrow.isRequested) throw 102;

            escrow.isRequested = true;
            escrow.store();
        }

        ReleaseFunds => {
            val payload = msg as ReleaseFunds;
            var escrow = lazy EscrowSystem.load();

            // must have been requested before releasing
            assert (escrow.isRequested) throw 108;

            // cannot release twice
            assert (!escrow.isReleased) throw 109;

            // only owner can release funds
            assert (in.senderAddress == escrow.owner) throw 110;

            escrow.isReleased = true;
            escrow.store();

            // send contract balance minus small reserve for gas (adjust if tests expect different)
            val res = createMessage({
                bounce: false,
                dest: escrow.recipient,
                value: contract.getOriginalBalance() - 100000000u
            });
            res.send(SEND_MODE_CARRY_ALL_BALANCE);
        }

        CancelEscrow => {
            val payload = msg as CancelEscrow;
            var escrow = lazy EscrowSystem.load();

            // only owner may cancel
            assert (in.senderAddress == escrow.owner) throw 106;

            // cannot cancel after release
            assert (!escrow.isReleased) throw 107;

            escrow.isReleased = true;
            escrow.store();

            val res = createMessage({
                bounce: false,
                dest: in.senderAddress,
                value: contract.getOriginalBalance() - 100000000u
            });
            res.send(SEND_MODE_CARRY_ALL_BALANCE);
        }

        else => {
            assert (in.body.isEmpty()) throw 100;
        }
    }
}

get fun getEscrowDetails(): (address, address, uint64, bool, bool) {
    var escrow = lazy EscrowSystem.load();
    return (escrow.owner, escrow.recipient, escrow.amount, escrow.isReleased, escrow.isRequested);
}

This must be the fix for the escrow contract according to me
