// contracts/simple_dao.tolk
// SimpleDAO contract - voting (yes/no) implementation

struct SimpleDao {
    queryId: uint32;
    yesVotes: uint32;
    noVotes: uint32;
    totalVotes: uint32;
}

static fun SimpleDao.load(): SimpleDao {
    return SimpleDao.fromCell(contract.getData());
}

static fun SimpleDao.store(self: SimpleDao) {
    contract.setData(self);
}

// Message structs (opcodes per spec)
struct (0xF4A2B1C9) RecordVote {
    queryId: uint32;
    vote: bool; // true => yes, false => no
}
struct (0xD4E7B328) ResetVotes {
    queryId: uint32;
}

type MessageBody = RecordVote | ResetVotes;

fun onInternalMessage(in: InMessage) {
    val msg = lazy MessageBody.fromSlice(in.body);

    match (msg) {
        RecordVote => {
            val payload = msg as RecordVote;
            var dao = lazy SimpleDao.load();

            // increment appropriate counter
            if (payload.vote) {
                dao.yesVotes = dao.yesVotes + 1u;
            } else {
                dao.noVotes = dao.noVotes + 1u;
            }
            dao.totalVotes = dao.totalVotes + 1u;

            dao.store();
        }

        ResetVotes => {
            val payload = msg as ResetVotes;
            var dao = lazy SimpleDao.load();

            // Reset counts to zero
            dao.yesVotes = 0u;
            dao.noVotes = 0u;
            dao.totalVotes = 0u;

            // Optionally store queryId for traceability
            dao.queryId = payload.queryId;

            dao.store();
        }

        else => {
            assert (in.body.isEmpty()) throw 100;
        }
    }
}

// Getter to return votes
get fun getVotes(): (uint32, uint32, uint32) {
    var dao = lazy SimpleDao.load();
    return (dao.yesVotes, dao.noVotes, dao.totalVotes);
}
  
Check if this works for simpleDao
