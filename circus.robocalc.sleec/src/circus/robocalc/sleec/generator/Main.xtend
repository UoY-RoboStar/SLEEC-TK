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
 ********************************************************************************/
package circus.robocalc.sleec.generator

import circus.robocalc.sleec.SLEECStandaloneSetup
import com.google.inject.Inject
import com.google.inject.Provider
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.generator.GeneratorContext
import org.eclipse.xtext.generator.GeneratorDelegate
import org.eclipse.xtext.generator.JavaIoFileSystemAccess
import org.eclipse.xtext.util.CancelIndicator
import org.eclipse.xtext.validation.CheckMode
import org.eclipse.xtext.validation.IResourceValidator
import org.eclipse.xtext.diagnostics.Severity

class Main {

	def static main(String[] args) {
		if (args.empty) {
			System::err.println('Aborting: no path to EMF resource provided!')
			return
		}
		val injector = new SLEECStandaloneSetup().createInjectorAndDoEMFRegistration
		val main = injector.getInstance(Main)
		for(arg : args) {
			main.runGenerator(arg)
		}
	}

	@Inject Provider<ResourceSet> resourceSetProvider

	@Inject IResourceValidator validator

	@Inject GeneratorDelegate generator

	@Inject JavaIoFileSystemAccess fileAccess

	def protected runGenerator(String string) {
		// Load the resource
		val set = resourceSetProvider.get
		val resource = set.getResource(URI.createFileURI(string), true)

		// Validate the resource
		val issues = validator.validate(resource, CheckMode.ALL, CancelIndicator.NullImpl)
		issues.forEach[System.err.println(it)]
		if (!issues.filter[severity==Severity.ERROR].isEmpty)
			return;

		// Configure and start the generator if there were no errors
		fileAccess.outputPath = 'src-gen/'
		val context = new GeneratorContext => [
			cancelIndicator = CancelIndicator.NullImpl
		]
		generator.generate(resource, fileAccess, context)
		System.out.println('Code generation finished.')
	}
}
