# SLEECVAL
This repository contains the Xtext projects for the parser and code generator for SLEEC requirements

### Development platform requirements ###

* Java 11
* Eclipse 2021-12 (Java 11 must already be installed before installing eclipse)
* Sirius 7.0.1 Update Site for eclipse: <https://download.eclipse.org/sirius/updates/releases/7.0.1/2021-06/>
* Xtext 2.25.0 Update Site for eclipse: <http://download.eclipse.org/modeling/tmf/xtext/updates/composite/releases/> but the option "Show only the latest versions of available software" needs to be unchecked.
* Maven
* Git

### Build (maven) ###

        1. mvn clean install

### Build (eclipse) ###

        1. Right click circus.robocalc.sleec/src/circus.robocalc.sleec/GenerateSLEEC.mwe2
            1. select 'Run As' > 'MWE2 Workflow'

### Run (eclipse) ###

        1. Right click circus.robocalc.sleec.parent
            1. select 'Run As'
            2. double click 'Eclipse Application'
        2. Select the new co
