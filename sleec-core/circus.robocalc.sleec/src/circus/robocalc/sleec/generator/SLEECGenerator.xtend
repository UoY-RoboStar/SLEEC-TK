/********************************************************************************
 * Copyright (c) 2023 University of York and others
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 *
 * Contributors:
 *  Charlie Burholt - initial definition
 *	Sinem Getir Yaman - initial definition
 *	Maddie Jones - initial definition 
 *  Pedro Ribeiro - contributor
 ********************************************************************************/
package circus.robocalc.sleec.generator

import circus.robocalc.sleec.sLEEC.Atom
import circus.robocalc.sleec.sLEEC.BoolComp
import circus.robocalc.sleec.sLEEC.BoolValue
import circus.robocalc.sleec.sLEEC.Boolean
import circus.robocalc.sleec.sLEEC.Constant
import circus.robocalc.sleec.sLEEC.Defeater
import circus.robocalc.sleec.sLEEC.Definition
import circus.robocalc.sleec.sLEEC.Event
import circus.robocalc.sleec.sLEEC.MBoolExpr
import circus.robocalc.sleec.sLEEC.Measure
import circus.robocalc.sleec.sLEEC.Not
import circus.robocalc.sleec.sLEEC.Numeric
import circus.robocalc.sleec.sLEEC.RelComp
import circus.robocalc.sleec.sLEEC.Response
import circus.robocalc.sleec.sLEEC.Rule
import circus.robocalc.sleec.sLEEC.Scale
import circus.robocalc.sleec.sLEEC.TimeUnit
import circus.robocalc.sleec.sLEEC.Trigger
import circus.robocalc.sleec.sLEEC.Type
import circus.robocalc.sleec.sLEEC.Value
import java.util.Collections
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import java.util.Set
import org.eclipse.emf.ecore.util.EcoreUtil
import java.util.HashSet
import java.io.File
import circus.robocalc.sleec.sLEEC.Constraint
import java.util.LinkedHashSet

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class SLEECGenerator extends AbstractGenerator {

	Set<String> scaleIDs
	Set<String> measureIDs

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		this.scaleIDs = resource.allContents.filter(Measure).filter[it.type instanceof Scale].map['v' + it.name].toSet
		this.measureIDs = resource.allContents.filter(Measure).map[name].toSet

		val ticktock = new File("../src-gen/ticktock.csp")
		if (!ticktock.exists()) {
			generateTickTock(resource, fsa, context)
		}
		
		val instantiatons = new File("../src-gen/ticktock.csp")
		if (!instantiatons.exists()) {
			generateInstantiations(resource, fsa, context)
		}
		
		fsa.generateFile(resource.getURI().trimFileExtension().lastSegment() + '.csp', '''
			
			--Specify the integer intervals for type Int e.g. {0..30}. 
			
			«resource.allContents
				.filter(Definition)
				.toIterable
				.map[D]
				.join('')»
				
			Capabilities = 
			  {| «resource.allContents
								.filter(Definition)
								.filter(Event)
								.toIterable
								.map[Cap]
								.join(',' + '\n   ')»«CapM(resource)»
			  |}
			Measures =
			  {| «resource.allContents
								.filter(Definition)
								.filter(Measure)
								.toIterable
								.map[Meas]
								.join(',' + '\n   ')»
			  |}
				
			
			Timed(OneStep) {
			
			«resource.allContents
				.filter(Rule)
				.toIterable
				.map[ rule | show(rule) + '\n' + R(rule) ]
				.join('')»
				
			}
		''')
		
		fsa.generateFile(resource.getURI().trimFileExtension().lastSegment() + '-assertions.csp', ''' 
			-- ASSERTIONS --
			include "tick-tock.csp"
			include "instantiations.csp"
			include "«resource.getURI().trimFileExtension().lastSegment()».csp"			
			«resource.allContents
										.filter(Rule)
										.toList
										.generateAssertions»
		''')
	}

	// -----------------------------------------------------------
	private def Cap(Definition d) {
		'''«d.name»'''
	}

	private def CapM(Resource resource) {

		// if measures exist, add to list of capabilities
		if (!resource.allContents.filter(Definition).filter(Measure).isEmpty) {
			return ''',
	 «resource.allContents
				.filter(Definition)
				.filter(Measure)
				.toIterable
				.map[Cap]
				.join(',' + '\n')»'''
		} else {
			return ''''''
		}
	}

	private def Meas(Definition d) {
		'''«d.name»'''
	}

	// -----------------------------------------------------------
	private def D(Definition d) {
		switch d {
			// [[event eID]]D
			Event: '''
				channel «d.name»
			'''
			// [[measure mID : T]]D
			Measure: '''
				channel «d.name», i_«d.name» : «T(d.type, d.name)»
				Mem_«d.name»(o__) =
					let
						Mem =  «d.name»?x__ -> (Provide(x__) /\ tock -> Mem)
						Provide(x__) = RUN(union({|i_«d.name».x__|},o__))
					within
						Mem
			'''
			// constant cID = v]]D
			Constant: '''
				«d.name» = «norm(d.value)»
			'''
		}
	}

	private def T(Type t, String mID) {
		switch t {
			Boolean:
				'Bool'
			Numeric:
				'core_int'
			Scale: {
				val sps = t.scaleParams.map[name]
				'''
					ST«mID»
					
					datatype ST«mID» = «sps.join(" | ")»
					
					STle«mID»(v1«mID», v2«mID») =
						if v1«mID» == «sps.head» then true
						«(1 ..< sps.size - 1).map[
						'''else (if v1«mID» == «sps.get(it)» then not member(v2«mID»,{«sps.take(it).join(', ')»})'''
					].join('\n')»
						else v2«mID» == «sps.last»«')'.repeat(sps.size-2)»
						
					STeq«mID»(v1«mID», v2«mID») =
						v1«mID» == v2«mID»
						
					STlt«mID»(v1«mID», v2«mID») =
						STle«mID»(v1«mID», v2«mID») and STne«mID»(v1«mID», v2«mID»)
						
					STgt«mID»(v1«mID», v2«mID») =
						STlt«mID»(v2«mID», v1«mID»)
						
					STne«mID»(v1«mID», v2«mID») =
						not STeq«mID»(v1«mID», v2«mID»)
						
					STge«mID»(v1«mID», v2«mID») =
						STlt«mID»(v2«mID», v1«mID»)
					
				'''
			}
		}
	}

	// -----------------------------------------------------------
	private def R(Rule r) {
		val rID = r.name
		val trig = r.trigger
		val resp = r.response
		val alpha = alphaE(resp)
		
	
		// [[rID when trig then resp dfts]]R
		'''
			«rID» = Trigger«rID»; Monitoring«rID»; «rID»
			
			Trigger«rID» = «TG(trig, alpha, 'SKIP', 'Trigger'+rID)»
			
			Monitoring«rID» = «RDS(resp)»
			
			-- alphabet for «rID» 
			A«rID» = {|«alphabetString(r)»|}
			SLEEC«rID» = timed_priority(«rID»)
			
			
		'''
	}

	// -----------------------------------------------------------	
	private def TG(Trigger trig, Iterable<String> AR, String sp, String fp) {
		val eID = trig.event.name
		val mBE = trig.expr

		// [[eID,AR, sp,fp]]TG
		if (mBE === null)
			'''
				«eID» -> «sp»«AR.map[ '''	[] «it» -> «fp»''' ].join('\n')»
				
			'''
		// [[eID and mBE, AR, sp,fp]]TG
		else
			'''
				let
					MTrigger = «ME(alphaMtree(mBE), mBE, sp, fp)»
				within «eID» -> MTrigger «sp.join('\n')»«AR.map[ '''	[] «it» -> «fp»''' ].join('\n')»
			'''
	}

	private def CharSequence ME(List<String> mIDs, MBoolExpr mBE, String sp, String fp) {
		val mID = mIDs.head

		// [[<>,mBE,sp,fp]]ME
		if (mID === null)
			'''
				if «norm(mBE)» then «sp» else «fp»
			'''
		// [[<mID>^mIDs,mBE[vmID/mID],sp,fp]]ME
		else
			'''
				StartBy(«mID»?v«mID» ->
					«ME(mIDs.subList(1, mIDs.size), replace(mBE, 'v'+mID, mID), sp, fp)»
				,0)
			'''
	}

	// -----------------------------------------------------------
	private def RDS(Response resp) {
		val dfts = resp.defeater
		// [[resp,trig,ARDS,mp]]RDS
		if (dfts.isEmpty)
			C(resp.constraint)
		// [[resp dfts,trig,ARDS,mp]]RDS
		else
			'''
				let
					«LRDS(resp, dfts, 1)»
				within «CDS(dfts.flatMap[alphaMtree], dfts, dfts.size+1)»
			'''
	}

	// -----------------------------------------------------------
	private def CharSequence C(Constraint const) {
		val eID = const.event.name
		val v = const.value
		val tU = const.unit
		val resp = const.response
		//val respList = getAllResponses(r)
		
		//[[eID, trig, ARDS, mp]] C
		if (v === null)
			'''«eID» -> SKIP'''
		
		else if (resp === null) {
			// [[not eID within v tU, trig, ARDS, mp]]
			if (const.not)
				'''WAIT(«norm(v, tU)»)'''
			// [[eID within v tU, trig, ARDS, mp]] C
			else 
				'''StartBy(«eID» -> SKIP,«norm(v, tU)»)'''
		}
		// [[eID within v tU otherwise resp, trig, ARDS, mp]]C
		else {
			'''TimedInterruptSeq(«eID»,«norm(v, tU)»,«RDS(resp)»)'''

		}
	}

	// -----------------------------------------------------------
	private def LRDS(Response resp, Integer n) {
		// [[<resp>,trig,AR,mp,n]]
		if (resp !== null)
			'''
				Monitoring«n» = «C(resp.constraint)»
			'''
		// [[<NOREP>,trig,AR,mp,n]]
		else
			'''
				Monitoring«n» = SKIP
			'''
	}

	// [[<resp>^resps,trig,AR,mp,n]]LRDS
	private def CharSequence LRDS(Response resp, Iterable<Defeater> dfts,
		Integer n) { '''
		«LRDS(resp, n)»
		«if(!dfts.isEmpty)
			LRDS(dfts.head.response, dfts.tail, n+1)»
	'''
}
	// -----------------------------------------------------------	
	private def CharSequence CDS(Iterable<String> mIDs, Iterable<Defeater> dfts, Integer n) {
		// [[<>,dfts,n]]CDS
		if (mIDs.isEmpty)
			return EDS(dfts, 'Monitoring1', n)

		// [[<mID>^mIDs,dfts,n]]CDS
		val mID = mIDs.head
		'''
			StartBy(«mID»?v«mID» ->
				«CDS(mIDs.tail, dfts.map[ replace(it, 'v'+mID, mID) ], n)»
			,0)
		'''
	}

	// [[unless mBE,fp,n]]EDS
	// [[unless mBE then resp,fp,n]]EDS
	private def EDS(Defeater dft, CharSequence fp, Integer n) {
		val mBE = dft.expr
		'''
		if «norm(mBE)» then Monitoring«n»
		else («fp»)'''
	}

	// [[dfts dft,fp,n]]EDS
	private def CharSequence EDS(Iterable<Defeater> dfts, CharSequence fp, Integer n) {
		if (dfts.isEmpty)
			fp
		else
			EDS(dfts.last, EDS(dfts.take(n - 2), fp, n - 1), n)
	}

	// -----------------------------------------------------------
	private def generateAssertions(List<Rule> rules) {

		var assertions = ''
		var assertions_part = ''
		var measurePrint = ''
		assertions += '''Timed(OneStep) {

'''

		for (i : 0 ..< rules.size - 1) {

			var firstRule = rules.get(i)
			var firstAlphabet = generateAlphabet(firstRule)

			for (j : i + 1 ..< rules.size) {

				var secondRule = rules.get(j)
				var secondAlphabet = generateAlphabet(secondRule)
				// Check intersection of rule alphabets
				var intersection = new HashSet<String>(firstAlphabet)
				intersection.retainAll(secondAlphabet)
				if (!intersection.isEmpty) {
					// [[r1, r2]]CC
					// [[r1, r2]]UC
					var unionMeasures = new LinkedHashSet<String>(alphaMtree(firstRule));
					unionMeasures.addAll(alphaMtree(secondRule));
					var firstRuleMeasures = alphaMtree(firstRule)
					var secondRuleMeasures = alphaMtree(secondRule)
					assertions += '''
					'''
				
					assertions += '''-- Checking «firstRule.name» with «secondRule.name»:
					'''
					assertions += '''intersection«firstRule.name»«secondRule.name» = 
					'''
					assertions += '''  let
					'''
					if (unionMeasures.size == 0) {
						assertions += '''    Env«firstRule.name»«secondRule.name» = SKIP'''
					} else if (unionMeasures.size == 1) {
						assertions += '''Env«firstRule.name»«secondRule.name» = Env«unionMeasures.get(0)»
						'''
					} else { // (unionMeasures.size >1)
						for (m : 0 ..< unionMeasures.size) {
							val element = unionMeasures.get(m)
							if (m == 0) {
								assertions += '''    Env«firstRule.name»«secondRule.name» = Env«element»'''

							} else if (m > 0) {
								assertions += '''||| Env«element»
								'''
							}
						}
					}

					for (m : 0 ..< unionMeasures.size) {
						val element = unionMeasures.get(m)
						assertions += '''    Env«element» = «element»?x__ -> VEnv«element»(x__)
    VEnv«element»(x__) = «element»!x__ -> VEnv«element»(x__) 
  '''
					}
					
						assertions += '''  within
  
  «CP(firstRule, secondRule, String.join(",",unionMeasures))»
  SLEEC«firstRule.name»«secondRule.name» = timed_priority(intersection«firstRule.name»«secondRule.name»)
					
  assert SLEEC«firstRule.name»«secondRule.name»:[deadlock-free]					
  			
  SLEEC«firstRule.name»«secondRule.name»CF   = prioritise(
  	timed_priority(intersection«firstRule.name»«secondRule.name»)
  	[[ tock <- tock, tock <- tock' ]],
  	<diff(Events,{|tock',tock|}),{|tock|}>)\{|tock|}
										
  assert SLEEC«firstRule.name»«secondRule.name»CF  :[divergence-free]
  
  '''
 
					
//Rule1 wrt Rule2
assertions+= wrt(firstRule, secondRule, unionMeasures)

//Rule2 wrt Rule1
assertions+= wrt(secondRule, firstRule, unionMeasures)   
assertions += '''assert not «firstRule.name»_wrt_«secondRule.name» [T= «secondRule.name»_wrt_«firstRule.name» 
'''
assertions += '''assert not «secondRule.name»_wrt_«firstRule.name» [T= «firstRule.name»_wrt_«secondRule.name» 

'''


				}
			}
		}
		assertions += '''
			}'''
		
		if (assertions === '') {
			return '''-- No intersections of rules; no assertions can be made. --'''
		} else {
			return assertions
		}
	}

	private def CP(Rule firstRule, Rule secondRule, CharSequence measures) {
		// [[r1,r2]]CP
		'''
			(«firstRule.name»[|diff(inter({|«alphabetString(firstRule)»|}, {|«alphabetString(secondRule)»|}),{|«measures»|})|]«secondRule.name»)
			[| {|«measures»|} |]
				Env«firstRule.name»«secondRule.name»
		'''
	}
	
	private def wrt(Rule firstRule, Rule secondRule,  LinkedHashSet<String> unionMeasures) {
		var assertions = ''
		var assertions_part = ''
		if (unionMeasures.size == 0) {
			assertions += '''   «firstRule.name»_wrt_«secondRule.name» =
		let
		-- The external 'm' channels for every measure of («firstRule.name» or «secondRule.name»)
		MemoryExternalEvents = {||}
		-- The internal 'i_m' channels for every measure of («firstRule.name» or «secondRule.name»)
		MemoryInternalEvents = {||}
		-- Common events of «firstRule.name» and «secondRule.name»
		CommonEvents = union(A«firstRule.name»,A«secondRule.name»)
		-- Common events of «firstRule.name» and «secondRule.name», except for those of measures:
		CommonProvideEvents = diff(CommonEvents,MemoryExternalEvents)
		
		-- The memory process
		Memory = 
				TRUN(CommonProvideEvents)
				MemoryInOrder = SKIP
				within
					timed_priority(
						(
							(SLEEC«firstRule.name»)
						    [| union(diff(A«firstRule.name»,MemoryExternalEvents),MemoryInternalEvents) |]
						    (
						    -- Generalised parallel composition of all measure processes
						       Memory
						       [| MemoryExternalEvents |]
						       MemoryInOrder
						    )
						 ) \MemoryInternalEvents
				     ) 
						        						 						      '''
		}else if (unionMeasures.size == 1) {
			val element = unionMeasures.get(0)
			assertions += '''   «firstRule.name»_wrt_«secondRule.name» =
		let
		-- The external 'm' channels for every measure of («firstRule.name» or «secondRule.name»)
		MemoryExternalEvents = {|«element»|}
		-- The internal 'i_m' channels for every measure of («firstRule.name» or «secondRule.name»)
		MemoryInternalEvents = {|i_«element»|}
		-- Common events of «firstRule.name» and «secondRule.name»
		CommonEvents = union(A«firstRule.name»,A«secondRule.name»)
		-- Common events of «firstRule.name» and «secondRule.name», except for those of measures:
		CommonProvideEvents = diff(CommonEvents,MemoryExternalEvents)
		
		-- The memory process
		Memory = 
				 Mem_«element»(CommonProvideEvents)
			     MemoryInOrder = «element»?x__ -> MemoryInOrder
			     within
					timed_priority(
						 (
						 	(
						     SLEEC«firstRule.name» [[
						     «element» <- i_«element»
						     ]]
						    )
						    [| union(diff(A«firstRule.name»,MemoryExternalEvents),MemoryInternalEvents) |]
						    (
						    -- Generalised parallel composition of all measure processes
						        Memory
						        [| MemoryExternalEvents |]
						        MemoryInOrder
						    )
						 ) \MemoryInternalEvents
				     ) 
						        						 						      '''
						     				     
  
		}else{ // (unionMeasures.size >1)
		assertions += '''   «firstRule.name»_wrt_«secondRule.name» =
		let
		-- The external 'm' channels for every measure of («firstRule.name» or «secondRule.name»)
		MemoryExternalEvents = {|'''
						       for (m : 0 ..< unionMeasures.size) { 
						       val element = unionMeasures.get(m)
						       	
						       	if (m == 0) {
						       	assertions+= '''«element»'''
						       	}else if (m > 0) {
						       		assertions+= ''',«element»'''
						       	}
						       }
						       assertions+='''|}'''
						       assertions+='''   -- The internal 'i_m' channels for every measure of («firstRule.name» or «secondRule.name»)
		MemoryInternalEvents = {|'''
						         for (m : 0 ..< unionMeasures.size) { 
						       val element = unionMeasures.get(m)
						       	
						       	if (m == 0) {
						       	assertions+= '''i_«element»'''
						       	}else if (m > 0) {
						       		assertions+= ''',i_«element»'''
						       	}
						       }
						        assertions+='''|}'''
						        assertions+='''
						        -- Common events of «firstRule.name» and «secondRule.name»
						        CommonEvents = union(A«firstRule.name»,A«secondRule.name»)
						        -- Common events of «firstRule.name» and «secondRule.name», except for those of measures:
						        CommonProvideEvents = diff(CommonEvents,MemoryExternalEvents)
						         -- The memory process
						        Memory = '''
							assertions_part = ''
							for (m : 0 ..< unionMeasures.size) {
							val element = unionMeasures.get(m)
							if (m == 0) {
								assertions_part += '''(Mem_«element»(CommonProvideEvents)''' 
							}else if (m > 0 && m < unionMeasures.size-1) {
								assertions_part += ''' [| CommonProvideEvents |] (Mem_«element»(CommonProvideEvents)
								'''
							}else if (m == unionMeasures.size-1) {
							assertions_part += ''' [| CommonProvideEvents |] Mem_«element»(CommonProvideEvents)
								'''}
								}
							for (m : 0 ..< unionMeasures.size-1) {
							assertions_part += ''')
							'''
							}
							assertions += assertions_part
						
						
						//assertions += nestedParalel(assertions_part)
						
							assertions+= '''MemoryInOrder = '''
						for (m : 0 ..< unionMeasures.size) {
							val element = unionMeasures.get(m)
							
							if (m == 0) {
								assertions += '''«element»?x__'''
							} else if (m > 0) {
								assertions += '''-> «element»?x__ 
								'''
							}
						}
						
						assertions+= '''-> MemoryInOrder
						'''
							
						assertions+= '''within
		timed_priority(
						 (
							(
							SLEEC«firstRule.name»[[ '''
						for (m : 0 ..< unionMeasures.size) {
							val element = unionMeasures.get(m)
							
							if (m == 0) {
								assertions += '''«element» <- i_«element»'''
								

							} else if (m > 0) {
								assertions += ''',
							«element» <- i_«element»
								'''
							}
						}
							assertions += ''' ]]
							)
							[| union(diff(A«firstRule.name»,MemoryExternalEvents),MemoryInternalEvents) |]
							(
							-- Generalised parallel composition of all measure processes
							Memory
							[| MemoryExternalEvents |]
							MemoryInOrder
						    )
						 ) \MemoryInternalEvents
				     ) 
																			      '''
						}					
	}
	

	// -----------------------------------------------------------
	// helper functions used in the translation rules:
	// Returns string of all eventIDs and measureIDs of a rule
	protected def alphabetString(Rule r) {

		val Set<String> ruleAlphabet = new HashSet<String>(generateAlphabet(r))
		var String alphString = ''
		for (i : 0 ..< ruleAlphabet.size) {
			val element = ruleAlphabet.get(i)
			if (i == (ruleAlphabet.size - 1)) {
				alphString += element
			} else {
				alphString += element + ', '
			}
		}
		'''«alphString»'''
	}

	// Returns a set of all eventIDs and measureIDs of a rule
	protected def generateAlphabet(Rule r) {

		// creates an alphabet containing all the event IDs and measure IDs used in a rule		
		var Set<String> ruleAlphabet = new HashSet<String>()

		ruleAlphabet.add(r.trigger.event.name)
		// getResponseEvents(r.response, ruleAlphabet)
		ruleAlphabet.addAll(alphaE(r)+alphaMtree(r))

		return ruleAlphabet

	}

	// Returns a list of all the MeasureIds in AST
	protected def <T extends EObject> List<String> alphaMtree(T AST) {
		// eAllContents does not include the root of the tree
		// so this will return an empty list if AST is an instance of Atom, which is an error
		// so first check that AST is an instance of atom
		val Iterable<Atom> leaves = if (AST instanceof Atom)
				// create a 1 element list with the atom's measureID
				Collections.singleton(AST as Atom)
			else
				AST.eAllContents.filter(Atom).toList
		// the name of an atom can either be a measureID or a scaleParam
		// filter out the scaleParams 
		return leaves.map[measureID].filter[this.measureIDs.contains(it)].toList
	}

	private def <T extends EObject> List<String> alphaM(T AST) {
		val listMeasures = alphaMtree(AST)
		var list = newArrayList

		for (value : listMeasures) {
			list.add(value + "?x")
		}
		return list

	}

	// Returns a list of all the EventIds in AST
	protected def <T extends EObject> List<String> alphaE(T AST) {
		// eAllContents does not include the root of the tree
		// so this will return an empty list if AST is an instance of Atom, which is an error
		// so first check that AST is an instance of atom
		val Iterable<Constraint> leaves = if (AST instanceof Constraint)
				// create a 1 element list with the atom's measureID
				Collections.singleton(AST as Constraint)
			else
				AST.eAllContents.filter(Constraint).toList
		// the name of an atom can either be a measureID or a scaleParam
		// filter out the scaleParams 
		return leaves.map[event.name].toList
	}

	private def <T extends EObject> List<Response> getAllResponses(T AST) {
		val Iterable<Response> leaves = if (AST instanceof Response)
				Collections.singleton(AST as Response)
			else
				AST.eAllContents.filter(Response).toList

		return leaves.map[constraint.response].toList

	}

	// return an MBoolExpr as a string using CSP operators
	private def CharSequence norm(MBoolExpr mBE) {
		'(' + switch (mBE) {
			BoolComp: norm(mBE as BoolComp)
			Not: norm(mBE as Not)
			RelComp: norm(mBE as RelComp)
			Atom: norm(mBE as Atom)
			Value: norm(mBE as Value)
			BoolValue: norm(mBE as BoolValue)
		} + ')'
	}

	private def norm(BoolComp b) {
		norm(b.left) + switch (b.op) {
			case AND: ' and '
			case OR: ' or '
		} + norm(b.right)
	}

	private def norm(Not n) {
		// no need to check that n.expr is null
		'not ' + norm(n.expr)
	}

	private def norm(RelComp r) {
		// the validation pass ensures that one of the arguments is a measureID
		// so the case where both are scaleParams can be ignored
		if (isScaleID(r.left) || isScaleID(r.right)) {
			// if the arguments are scale types then they are atoms
			val left = (r.left as Atom).measureID
			val right = (r.right as Atom).measureID
			val scaleType = (isScaleID(left) ? left : right).substring(1)
			'''ST«switch(r.op) {
				case LESS_THAN : 'lt'
				case GREATER_THAN : 'gt'
				case NOT_EQUAL : 'ne'
				case LESS_EQUAL : 'le'
				case GREATER_EQUAL : 'ge'
				case EQUAL : 'eq'
			}»«scaleType»(«left», «right»)'''
		} else
			norm(r.left) + switch (r.op) {
				case LESS_THAN: ' < '
				case GREATER_THAN: ' > '
				case NOT_EQUAL: ' != '
				case LESS_EQUAL: ' <= '
				case GREATER_EQUAL: ' >= '
				case EQUAL: ' == '
			} + norm(r.right)
	}

	private def norm(Atom a) {
		a.measureID
	}

	private def CharSequence norm(Value v) {
		if (v.constant === null)
			v.value.toString
		else
			norm(v.constant.value)
	}

	private def norm(BoolValue b) {
		b.value.toString
	}

	// Convert value to seconds.
	// NOTE the standard unit may need to be changed from seconds depending on the implementation.
	private def norm(Value v, TimeUnit tU) '''(«norm(v)» * «norm(tU)»)'''

	private def Integer norm(TimeUnit tU) {
		switch (tU) {
			case SECONDS: 1
			case MINUTES: 60
			case HOURS: 60 * norm(TimeUnit.MINUTES)
			case DAYS: 24 * norm(TimeUnit.HOURS)
		}
	}

	// replace each MeasureID in the AST with 'vmID'
	private def <T extends EObject> replace(T AST, String vmID, String mID) {
		val res = EcoreUtil.copy(AST)
		if (res instanceof Atom)
			res.measureID = vmID
		else
			res.eAllContents.filter(Atom).filter[it.measureID == mID].forEach[it.measureID = vmID]
		return res
	}

	// -----------------------------------------------------------
	// functions used for AST printing TODO this could be done during serialisation
	private def CharSequence show(Rule r) '''
		-- «r.name» when «show(r.trigger)» then «show(r.response)» «r.response.defeater.map[show].join('')»
	'''

	private def show(Trigger t) {
		t.event.name + if (t.expr === null)
			''
		else
			' and ' + norm(t.expr)
	}

	private def CharSequence show(Response r) {
		if (r.constraint.not)
			'not ' + r.constraint.event.name + ' within ' + norm(r.constraint.value) + ' ' + show(r.constraint.unit)
		else
			r.constraint.event.name + if (r.constraint.value === null)
				''
			else
				' within ' + norm(r.constraint.value) + ' ' + show(r.constraint.unit) +
					if (r.constraint.response === null)
						''
					else
						'\n-- otherwise ' + show(r.constraint.response)
	}

	private def show(TimeUnit t) {
		switch (t) {
			case SECONDS: 'seconds'
			case MINUTES: 'minutes'
			case HOURS: 'hours'
			case DAYS: 'days'
		}
	}

	private def show(Defeater d) {
		'\n-- unless ' + norm(d.expr) + if (d.response === null)
			''
		else
			' then ' + show(d.response)
	}

	// -----------------------------------------------------------
	private def isScaleID(MBoolExpr m) {
		m instanceof Atom && isScaleID((m as Atom).measureID)
	}

	private def isScaleID(String measureID) {
		this.scaleIDs.contains(measureID)
	}
	
	private def generateInstantiations(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		fsa.generateFile('instantiations.csp',
			'''
			-- This file contains user-adjustable parameters for model-checking.
			
			-- core_int : the domain of the numeric type.
			nametype core_int = { -2..2}
			'''
		)
	}

	// -----------------------------------------------------------
	// Generates ticktock.csp in src-gen if it does not exist.
	// -----------------------------------------------------------
	private def generateTickTock(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		fsa.generateFile(
			'tick-tock.csp',
			'''---------------------------------------------------------------------------
		-- Pedro Ribeiro <pedro.ribeiro@york.ac.uk>
		-- Department of Computer Science
		-- University of York
		-- York, YO10 5GH
		-- UK
		---------------------------------------------------------------------------
		
		---------------------------------------------------------------------------
		-- SUMMARY AND ACKNOWLEDGMENTS
		---------------------------------------------------------------------------
		--
		-- This file contains an encoding of 'tick-tock'-CSP, as well as encodings
		-- for the Refusal Testing model. This work is based on a tailoring (and
		-- an extension to cater for termination) of a technique by David Mestel,
		-- originally available at:
		--
		-- http://www.cs.ox.ac.uk/people/david.mestel/model-shifting.csp
		--
		-- That work referred to the strategy outlined in the following paper:
		--
		-- Mestel, D. and Roscoe, A.W., 2016. Reducing complex CSP models
		-- to traces via priority. Electronic Notes in Theoretical Computer
		-- Science, 325, pp.237-252.
		--
		-- The current file extends that work to 'tick-tock'-CSP, whose details
		-- can be found in the paper:
		--
		-- Baxter, J., Ribeiro, P. and Cavalcanti, A. Sound reasoning in
		-- tock-CSP. Acta Informatica 59, pp.125-162 (2022).
		--
		-- We observe that in that paper a refusal of an event e is encoded as e',
		-- whereas here a refusal e is encoded as ref.e. This is a technicality
		-- that enables the declaration of a parametric channel ref based solely on a
		-- set of regular events. Furthermore we take advantage of FDR's Modules
		-- to encapsulate the encoding within an MS(X) module where X is a set of
		-- events. It exports two parametric processes, C3(P) corresponding to the
		-- encoding of tick-tock, and CRT(P), corresponding to refusal-testing.
		--
		---------------------------------------------------------------------------
		
		---------------------------------------------------------------------------
		-- CHANGE LOG
		---------------------------------------------------------------------------
		--
		-- 4-Oct-2023 : Added TRUN(X) to include tock implicitly.
		--
		-- 7-Sep-2022 : Included revised versions of the following operators:
		--
		--				* 	TimedInterrupt operator now admits terminating
		--					processes in the first operand.
		--				*	Added TCHAOS, the bottom of the refinement order in
		--					tick-tock.
		--				*	Added TimeOut operator.
		--
		--				Included notes regarding use of timed processes within
		--				assertion commands, and the reasoning for the definition
		--				of TCHAOS.
		--
		--				Added a note about timed deadlock freedom checking using
		--				Roscoe's slow-abstraction technique.
		
		---------------------------------------------------------------------------
		-- USAGE
		---------------------------------------------------------------------------
		--
		-- Modelling:
		--
		-- Processes in 'tick-tock' are modelled within a Timed Section, declared as
		-- Timed(et) { ... }. Untimed operators USTOP and Int(P,Q) (untimed interrupt)
		-- are defined below for convenience.
		--
		-- Instantiating the encoding:
		--
		-- Given a set of events of interest {a,b,c}, the encoding can be instantiated as:
		-- instance M = MS({a,b,c}).
		-- Important note: the argument of MS cannot be Events; this is a technicality
		-- due to the way in which MS is defined.
		--
		-- Refinement checking:
		--
		-- To check that P is refined by Q in the tick-tock model the following
		-- assertion should be written:
		--
		-- assert M::C3(P) [T= M::C3(Q)
		--
		-- Observe that although assertions can be written within a timed section,
		-- processes written in an assertion command may not be correctly interpreted
		-- as being in a timed section. For example, in the assertion below
		--
		-- assert M::C3(timed_priority(P ||| Q)) [T= ...
		--
		-- the interleaving on the left will not be interpreted to introduce the
		-- appropriate synchronisation on 'tock' as would be expected in a
		-- timed section. Therefore only named processes should appear in
		-- such assertion commands.
		--
		-- Traces refinement in the tick-tock model corresponds to traces refinement
		-- within a timed section, and does not require the encoding here.
		---------------------------------------------------------------------------
		
		---------------------------------------------------------------------------
		-- DEFINITIONS
		---------------------------------------------------------------------------
		
		---------------------------------------------------------------------------
		-- Auxiliary definitions for tick-tock-CSP modelling
		---------------------------------------------------------------------------
		
		-- Events
		channel tock, tock'
		
		-- For definition of timed sections, no time is added implicitly.
		OneStep(_) = 0
		
		-- Timelock (untimed STOP)
		USTOP = STOP
		
		-- Untimed interrupt
		UInt(P__,Q__) = P__ /\ Q__
		
		Timed(OneStep) {
		
			-- Timed SKIP
			TSKIP = SKIP
		
			-- Nondeterministic wait
			WAIT_INTERVAL(S__) = |~| x__ : S__ @ WAIT(x__)
		
			-- Timed deadlock
			TSTOP = STOP
		
			-- Deadlines on processes to terminate
			EndBy(P__,d__) = P__ /\ (WAIT(d__) ; USTOP)
			Deadline(P__,d__) = EndBy(P__,d__)
		
			-- Deadline on processes to start
			StartBy(P__,d__) = P__ [] (WAIT(d__) ; USTOP)
			-- Deadline on event
			EDeadline(e__,d__) = StartBy(e__ -> SKIP,d__)
		
			-- Strict timed interrupt
			channel finishedp__, finishedq__, timeout__
		
			-- Behaves as P__ until it either terminates, or, after exactly
			-- d__ time units behaves as Q__.
			TimedInterrupt(P__,d__,Q__) =
		      ((((P__; EDeadline(finishedp__,0))
		        /\ timeout__ -> (RUN(diff(Events,{finishedp__,finishedq__,timeout__}))
		                       /\ finishedq__ -> SKIP)
		       )
		         [| Events |]
		       RT__(d__,Q__)) \ {finishedp__, finishedq__, timeout__}); SKIP
		
			TimedInterruptSeq(e__,d__,Q__) =
				let
					TT(n__) = if n__ < d__ then TimeOut_1(e__ -> SKIP,TT(n__ + 1)) else Q__
				within
					TT(0)
		
			-- Timeout process:
			--
			-- Initially behaves as P__, and if no event from P__ is communicated
			-- before exactly d__ time units then, after exactly d__ time units it
			-- behaves as Q__.
			TimeOut(P__,d__,Q__) =
				(P__ /+Events+\ (TimedInterrupt(Some__,d__,STOP);RUN(Events)))
				[]
				(WAIT(d__);Q__)
		
			TRUN(X__) = RUN(union({tock},X__))
		}
		
		---------------------------------------------------------------------------
		-- Special cases
		---------------------------------------------------------------------------
		
		-- A version of TimedInterrupt that can be used when P__ is known not to
		-- terminate. It uses RTd__, a simplified version or the auxiliary process
		-- RT__, defined later.
		
		STimedInterrupt(P__,d__,Q__) = (P__ /+Events+\ RTd__(d__));Q__
		
		-- Note: TimeOut(P__,d__,Q__) cannot be used in a recursive definition as
		-- 		 /+ +\ cannot be recursed. However, TimeOut_1(P__,Q__) can be used.
		--
		-- Besides, TimeOut(P__,d__,Q__) can result in a non-optimal representation
		-- in FDR.
		
		-- TimeOut_1(P__,Q__) is an efficient timeout operator for d__ = 1, that
		-- can be used when P__ is known not to have an initial deadline.
		
		TimeOut_1(P__,Q__) = (USTOP[+{tock}+]P__) [] (tock -> Q__)
		
		-- A similar observation applies to the STimedInterrupt operator. Below is
		-- an optimised version that is applicable whenever P__ is known not to
		-- impose a deadline.
		
		STimedInterrupt_1(P__) = (USTOP[+{tock}+]P__) /\ (tock -> TSKIP)
		
		-- The in-built process CHAOS(_) of FDR is only suitable for analysis
		-- up to the failures-divergences model. By examining its graph in FDR
		-- it is apparent that its definition is given as follows.
		--
		-- CHAOS(S__) = USTOP |~| ([] x__ : S__ @ x__ -> CHAOS(S__))
		--
		-- Therefore, in the context of tick-tock (assuming tock is in S__) we
		-- have that in addition to timelocking, the process can offer any of
		-- the events in the set S__ in external choice. This is ok in the failures
		-- model given that the external choice becomes an internal choice. For
		-- example, consider the following equality in the failures model:
		--
		-- USTOP |~| (a -> Q [] b -> Q) = USTOP |~| a -> Q |~| b -> Q
		--
		-- In tick-tock, however, if CHAOS(S__) chooses to behave as the external
		-- choice, then preceding a tock there is an empty refusal, and so a
		-- refinement of CHAOS(S__) could not possibly refuse an event before tock.
		--
		-- Instead, we adopt the following process TCHAOS, a version of CHAOS
		-- suitable for use in tick-tock: it offers the events in S__
		-- non-deterministically and can either timelock or deadlock. We note that
		-- tock does not need to be a member of S__.
		
		TCHAOS(S__) = CHAOS(S__) /\ (SKIP |~| USTOP |~| tock -> TCHAOS(S__))
		
		-- When used with S__ as the set of all events of interest, then TCHAOS
		-- is the bottom of the refinement order, ie. every process refines it
		-- in tick-tock.
		--
		-- TCHAOS(S__) is equivalent to the following definition within a timed
		-- section:
		--
		-- Timed(OneStep) {
		--
		--   TCHAOS(S__) = C(union(S__,{tock}))
		--   C(S__) = (|~| e__ : S__ @ e__ -> C(S__)) |~| USTOP |~| SKIP
		--
		-- }
		--
		-- This is, however, not used as it can cause an inefficient compilation
		-- by FDR.
		
		---------------------------------------------------------------------------
		-- Auxiliary processes
		---------------------------------------------------------------------------
		
		-- Wait for use outside Timed Sections, and where termination is immediate.
		wait(n__) = if n__ > 0 then tock -> wait(n__-1) else SKIP
		
		-- Auxiliary counter for TimedInterrupt definition above.
		RT__(d__,Q__) =
			if d__ > 0
		        then RUN(diff(Events,{finishedp__, finishedq__, timeout__, tock}))
				  	 /\ (finishedp__ -> SKIP [] tock -> RT__(d__-1,Q__))
			    else timeout__ -> Q__; finishedq__ -> SKIP
		
		-- Auxiliary counter for the STimedInterrupt definition above.
		RTd__(d__) =
			if d__ > 0
				then RUN(diff(Events,{tock})) /\ tock -> RTd__(d__-1)
				else SKIP
		
		-- Offers in choice to perform any event once followed by termination.
		Some__ = [] x__ : Events @ x__ -> SKIP
		
		-- Termination at any time.
		SKIP_ANYTIME = SKIP |~| tock -> SKIP_ANYTIME
		
		---------------------------------------------------------------------------
		-- Timed deadlock checking
		---------------------------------------------------------------------------
		
		external prioritise
		
		-- Version of P__ suitable for checking timed-deadlock freedom via
		-- divergence-freedom checking. In P__ tock is relationally renamed to
		-- tock and tock' and subsequently every event other than tock and tock'
		-- is prioritised over tock, that is, tock can only happen from states where
		-- no other regular event (in diff(Events,{tock',tock})) is possible.
		-- Finally, hiding tock turns a state where tock is the only event offered
		-- forever into a divergence, which can be identified by FDR.
		TDeadlock(P__) = prioritise(P__[[tock<-tock,tock<-tock']],
								   	<diff(Events,{tock',tock}),{tock}>)\{tock}
		
		-- This technique is an implementation of Roscoe's slow-abstraction described
		-- in the follow paper.
		--
		-- A.W. Roscoe, The automated verification of timewise refinement, in:
		-- First Open EIT ICT Labs Workshop on Cyber-Physical Systems Engineering, 2013
		--
		-- The check can therefore be used as:
		--
		-- assert TDeadlock(P) :[divergence free]
		--
		-- We note that, according to the definition of timed deadlock, a deadlocked
		-- process is not timed deadlocked. A timed deadlocked process allows time
		-- to pass, but nothing else to happen.
		
		---------------------------------------------------------------------------
		-- Semantic encoding
		---------------------------------------------------------------------------
		
		module MS(Sigma)
		
		external prioritisepo
		
		-- Note that for the purposes of encoding refusals/acceptances in this model
		-- ref.x, rather than x' is used, unlike that discussed in the paper. This
		-- is a technicality as it makes it easier to defined a parametrised channel.
		
		channel ref:union(Sigma,{tock,tick})
		channel acc:union(Sigma,{tock,tick})
		
		channel stab
		channel tick
		
		-- The partial order gives each event 'x' priority over 'ref.x'
		order = {(x,ref.x) | x:union(Sigma,{tock,tick})}
		
		---------------------------------------------------------------------------
		-- Context C1
		---------------------------------------------------------------------------
		
		-- This is the first context, whereby in interleaving with P we have the
		-- process that can perform ref or stab, and is prioritised according to
		-- 'order', whereby 'Sigma' have same priority as 'tau' and 'tick'.
		--
		-- This is effectively an implementation of the RT-model, because after each
		-- normal trace (ie, with events drawn from Sigma) we have the possibility
		-- to also observe in the trace refusal information, at that point.
		
		C1(P__) =
			prioritisepo(
				P__ ||| RUN({|ref,stab|}),
				union(Sigma,{|ref,tock,tick|}),
				order,
				union(Sigma,{tock,tick})
			)
		
		---------------------------------------------------------------------------
		-- Encoding of 'tick-tock'-CSP model
		---------------------------------------------------------------------------
		
		C2(P__) = C1(P__) [| union(Sigma,{|ref,stab,tock,tick|}) |] Sem
		
		Sem = ([] x : union(Sigma,{tock,tick}) @ x -> Sem)
		      [] (ref?x -> Ref)
		      [] (stab -> Ref)
		
		Ref = (ref?x -> Ref) [] (stab -> Ref) [] tock -> Sem
		
		exports
		
		-- Refusal-testing (via refusals)
		CRT(P__) = C1(P__ ; tick -> SKIP)
		
		-- tick-tock (via refusals)
		C3(P__) = C2(P__ ; tick -> SKIP)
		
		endmodule
		---------------------------------------------------------------------------


	'''
		)
	}

}
