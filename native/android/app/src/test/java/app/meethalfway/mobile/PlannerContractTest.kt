package app.meethalfway.mobile
import org.junit.Test
import org.junit.Assert.*
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

class PlannerContractTest {
    private val directory=File(System.getProperty("contractDir"))
    private val data=Experience.parse(File(directory,"experience.json").readText())
    @Test fun nativePlannerMatchesAllSharedWebCases() {
        val cases=JSONArray(File(directory,"planner-cases.json").readText()).objects()
        for(case in cases) {
            val actual=Planner.rank(case.getJSONArray("members").objects().map{Member.parse(it)},data.catalog,data)
            val expected=case.getJSONArray("expected").objects()
            assertEquals(case.getString("name"),expected.size,actual.size)
            actual.zip(expected).forEach{(got,want)->
                assertEquals(want.getString("id"),got.id);assertEquals(want.getInt("minFit"),got.minFit)
                assertEquals(want.getInt("meanFit"),got.meanFit);assertEquals(want.getInt("maxTravel"),got.maxTravel);assertEquals(want.getInt("start"),got.start)
            }
        }
    }
    @Test fun approvedCardRejectsPrivateNotesAndInvalidFields() {
        val polluted=JSONObject(data.defaultCard.fields()).put("privateNote","NEVER_SHARED")
        assertThrows(IllegalArgumentException::class.java){PreferenceCard.parse(polluted)}
        assertThrows(IllegalArgumentException::class.java){data.defaultCard.copy(maxSpend=-1).valid(data)}
        assertThrows(IllegalArgumentException::class.java){data.defaultCard.copy(interests=listOf("games","games")).valid(data)}
    }
    @Test fun confirmationRequiresCurrentUnanimousVotes() {
        val members=data.members.take(2);val p=Proposal("college-games",1020,3)
        val room=PlanRoom("test","Test","2026-11-28",members[0].id,members.map{it.id},"voting",3,p,members)
        assertFalse(room.canConfirm)
        val yes=members.associate{it.id to Vote("yes",p.candidateId,3)}
        assertTrue(room.copy(votes=yes).canConfirm)
        assertFalse(room.copy(votes=yes+(members[1].id to Vote("yes",p.candidateId,2))).canConfirm)
    }
}
