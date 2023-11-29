# SLEEC tool
This repository contains two Eclipse plug-ins that allow writing and validating
Social Legal Empathetic Ethical and Cultural (SLEEC) rules, and checking whether
a design model, written in RoboChart, conforms to a set of SLEEC rules.

## Building
The plug-ins can be built from the source code in this repository. Below are
requirements and stepwise instructions.

### Requirements
For building, the following software must be available:

* Java 11 for building
* Maven

### Stepwise instructions
Clone this git repository on your machine. In the root folder issue the command `mvn install`.

## Installation
Once the build has succeeded, the tool can be installed by using The Eclipse 
Installer and the Eclipse Product file `RoboTool_and_SLEEC.setup`.

1. Download the Eclipse Installer 2023-09 R from [https://www.eclipse.org/downloads/packages/installer](https://www.eclipse.org/downloads/packages/installer), extract and run it.
2. Click the hamburger button on the top-right corner. Deselect `Bundle Pools` and click
on `Advanced mode`.
3. Click the green plus button (+) on the top-right corner. A dialog titled
`Add User Products` will appear. Find the file `RoboTool_and_SLEEC.setup`,
and then press `OK`.
3. Select a suitable Java VM. If there is no version suitable, then select a
compatible Java Runtime Environment (JRE) for installation. It is also
recommended that `Bundle Pool` is left disabled.
4. Click `Next` twice and for the field `SLEEC Tool repository location` browse
to the folder `repository` of your local clone of this repository.
5. Click `Next` and finally `Finish`.
6. During the installation, which should take a couple of minutes, you will be
prompted to:
* Accept the EPL license: we recommend toggling `Remember accepted licenses`.
* Trust `unsigned content of unknown origin`: you will need to click on
    `Select All` followed by `Trust Selected`.
7. At the end of this process, if everything succeeds, Eclipse 2021 will be
launched automatically with the plug-ins in this folder installed, as well
as the required dependencies (eg. Xtext, Sirius, RoboChart). You can then 
click `Finish` to exit the installer.

### Production installation
