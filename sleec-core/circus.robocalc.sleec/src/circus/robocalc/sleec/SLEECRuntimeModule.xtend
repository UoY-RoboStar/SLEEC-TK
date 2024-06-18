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
package circus.robocalc.sleec

import org.eclipse.xtext.generator.IOutputConfigurationProvider
import circus.robocalc.sleec.generator.SLEECOutputConfigurationProvider

/**
 * Use this class to register components to be used at runtime / without the Equinox extension registry.
 */
class SLEECRuntimeModule extends AbstractSLEECRuntimeModule {
	
	def Class<? extends IOutputConfigurationProvider> bindIOutputConfigurationProvider() {
		return SLEECOutputConfigurationProvider
	}
}
