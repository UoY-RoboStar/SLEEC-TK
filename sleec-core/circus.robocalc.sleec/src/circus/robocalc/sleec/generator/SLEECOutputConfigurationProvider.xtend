package circus.robocalc.sleec.generator

import org.eclipse.xtext.generator.OutputConfigurationProvider
import org.eclipse.xtext.generator.OutputConfiguration
import java.util.HashSet

class SLEECOutputConfigurationProvider extends OutputConfigurationProvider {
	
	override getOutputConfigurations() {
		
		var ocp = new HashSet<OutputConfiguration>// super.getOutputConfigurations()
		val dc = new OutputConfiguration("circus.robocalc.sleec");
		dc.setDescription("Configuration for SLEEC generator");
		dc.setOutputDirectory("src-gen");
		dc.setOverrideExistingResources(true);
		dc.setCreateOutputDirectory(true);
		dc.setCanClearOutputDirectory(true);
		dc.setCleanUpDerivedResources(false);
		dc.setSetDerivedProperty(true);
		dc.setKeepLocalHistory(true);
		ocp.add(dc)
		return ocp
		
	}
}