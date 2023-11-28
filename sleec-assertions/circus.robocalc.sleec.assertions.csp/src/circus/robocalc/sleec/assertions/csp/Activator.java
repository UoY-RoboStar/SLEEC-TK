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
 *   Pedro Ribeiro - initial definition
 ********************************************************************************/
package circus.robocalc.sleec.assertions.csp;

import java.util.Collections;
import java.util.Map;

import org.apache.log4j.Logger;
import org.eclipse.xtext.ui.shared.SharedStateModule;
import org.eclipse.xtext.util.Modules2;
import org.osgi.framework.BundleActivator;
import org.osgi.framework.BundleContext;

import com.google.common.collect.Maps;
import com.google.inject.Guice;
import com.google.inject.Injector;

import circus.robocalc.robochart.assertions.AssertionsRuntimeModule;
import circus.robocalc.sleec.SLEECRuntimeModule;

public class Activator implements BundleActivator {

	public static final String PLUGIN_ID = "circus.robocalc.sleec.assertions.csp";
	public static final String CIRCUS_ROBOCALC_SLEEC = "circus.robocalc.sleec.SLEEC";
	public static final String CIRCUS_ROBOCALC_ROBOCHART_ASSERTIONS_ASSERTIONS = "circus.robocalc.robochart.assertions.Assertions";
    
  
	private static BundleContext context;
	private static Activator plugin;
	    
    private static final Logger logger = Logger.getLogger(Activator.class);

    private Map<String, Injector> injectors = Collections.synchronizedMap(Maps.<String, Injector> newHashMapWithExpectedSize(1));
    
	static BundleContext getContext() {
		return context;
	}

	public void start(BundleContext bundleContext) throws Exception {
		Activator.context = bundleContext;
		plugin = this;
	}

	public void stop(BundleContext bundleContext) throws Exception {
		Activator.context = null;
		plugin = null;
	}
	
	public Injector getInjector(String language) {
		synchronized (injectors) {
			Injector injector = injectors.get(language);
			if (injector == null) {
				injectors.put(language, injector = createInjector(language));
			}
			return injector;
		}
	}

    protected Injector createInjector(String language) {
		try {
			com.google.inject.Module runtimeModule = getRuntimeModule(language);
			com.google.inject.Module sharedStateModule = getSharedStateModule();
			com.google.inject.Module mergedModule = Modules2.mixin(runtimeModule, sharedStateModule);
			return Guice.createInjector(mergedModule);
		} catch (Exception e) {
			logger.error("Failed to create injector for " + language);
			logger.error(e.getMessage(), e);
			throw new RuntimeException("Failed to create injector for " + language, e);
		}
	}
	
	protected com.google.inject.Module getRuntimeModule(String grammar) {
		if (CIRCUS_ROBOCALC_SLEEC.equals(grammar)) {
			return new SLEECRuntimeModule();
		} else if (CIRCUS_ROBOCALC_ROBOCHART_ASSERTIONS_ASSERTIONS.equals(grammar)) {
			return new AssertionsRuntimeModule();
		}
		throw new IllegalArgumentException(grammar);
	}
	
	protected com.google.inject.Module getSharedStateModule() {
		return new SharedStateModule();
	}
    
    /**
     * Returns the shared instance
     * 
     * @return the shared instance
     */
    public static Activator getInstance() {
    	return plugin;
    }	

}
