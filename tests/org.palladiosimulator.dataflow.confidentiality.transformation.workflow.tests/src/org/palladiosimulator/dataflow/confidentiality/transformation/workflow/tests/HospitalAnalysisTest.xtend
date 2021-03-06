package org.palladiosimulator.dataflow.confidentiality.transformation.workflow.tests

import java.util.Arrays
import org.eclipse.xtext.resource.SaveOptions
import org.junit.jupiter.api.Disabled
import org.junit.jupiter.api.Test
import org.palladiosimulator.dataflow.confidentiality.transformation.prolog.configuration.NameDerivationMethod
import org.palladiosimulator.dataflow.confidentiality.transformation.workflow.tests.impl.AnalysisIntegrationTestBase

import static org.junit.jupiter.api.Assertions.*

class HospitalAnalysisTest extends AnalysisIntegrationTestBase {

	@Test
	def void testOneViolation() {
		builder.addDFD(getRelativeURI("models/evaluation/hospital/DFDC_Hospital.xmi"))
		var solution = findFlaws()
		assertNumberOfSolutions(solution, 1, Arrays.asList("P", "PIN"))
	}
	
	@Test
	@Disabled("The used embedded solver does not support tabling, which results in an endless recursion")
	def void testOneViolation2() {
		builder.addDFD(getRelativeURI("models/evaluation/hospital/DFDC_HospitalLoopful.xmi"))
		var solution = findFlaws()
		assertNumberOfSolutions(solution, 1, Arrays.asList("P", "PIN"))
	}
	
	@Test
	def void testNoFlaw() {
		builder.addDFD(getRelativeURI("models/evaluation/hospital/DFDC_HospitalAlternative.xmi"))
		var solution = findFlaws()
		assertNumberOfSolutions(solution, 0, Arrays.asList("P", "PIN"))
	}

	protected def findFlaws() {
		builder.addSerializeToString(SaveOptions.newBuilder().format().getOptions().toOptionsMap())
		builder.setNameDerivationMethod(NameDerivationMethod.NAME_AND_ID)
		var workflow = builder.build()

		workflow.run()
		var result = workflow.getSerializedPrologProgram()
		assertFalse(result.isEmpty())

		prover.loadTheory(result.get())
		var queryString = '''
			inputPin(P, PIN),
			nodeCharacteristic(P, ?CTZONE, ?CZONE),
			characteristic(P, PIN, ?CTLEVEL, ?CLEVEL, S).
		'''
		var query = prover.query(queryString)
		query.bind("J$CTZONE", "ZoneMembership (_R8xrE1IoEeqxoa0IdF5JoA)")
		query.bind("J$CZONE", "AttackZone (_exuVgFIuEeqkVaPUPi-ogw)")
		query.bind("J$CTLEVEL", "ConfidentialityRequirements (_LNbeM1IoEeqxoa0IdF5JoA)")
		query.bind("J$CLEVEL", "High (_PtJx0FIoEeqxoa0IdF5JoA)")
		var solution = query.solve()
		solution
	}

}
