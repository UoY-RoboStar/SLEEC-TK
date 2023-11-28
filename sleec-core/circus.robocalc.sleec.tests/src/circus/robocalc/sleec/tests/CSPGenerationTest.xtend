package circus.robocalc.sleec.tests

import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith
import org.junit.jupiter.api.Assertions
import java.nio.file.Files
import java.nio.file.Paths
import java.nio.file.Path
import java.util.stream.Collectors
import java.util.stream.Stream
import java.util.List

// import java.io.File
// import org.junit.Assert

@ExtendWith(InjectionExtension)
@InjectWith(SLEECInjectorProvider)
class CSPGenerationTest {
	
	val path = '../circus.robocalc.sleec.runtime/src-gen/'
	
	
//	// check if generated csp files are empty 
	@Test
	def void test_empty() {
		
		val Stream<Path> stream = Files.list(Paths.get(path))
		val List<Path> result = stream.collect(Collectors.toList())
		for (r : result) {
			Assertions.assertTrue(Files.size(r) != 0)
		}
				
	}

}	