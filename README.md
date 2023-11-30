# SLEEC tool
This repository contains Eclipse plug-ins that allow writing and validating
Social, Legal, Ethical, Empathetic and Cultural (SLEEC) rules, and checking whether
a design model, written in RoboChart, conforms to a set of SLEEC rules.

Details on the SLEEC framework can be found in related papers, namely 
[arXiv:2307.03697](https://arxiv.org/abs/2307.03697).

## Requirements
For running the tool:

* Java 11 or higher.
* FDR4 for analysis of redundancy, conflict and conformance, available from [https://cocotec.io/fdr/](https://cocotec.io/fdr/).
  Stepwise installation instructions available below.

We recommend that the tool is executed under Ubuntu LTS (22.04) Linux (x86_64), 
which is the platform used for development.

## Building
The plug-ins can be built from the source code in this repository. Below are
requirements and stepwise instructions.

### Requirements
For building, the following software must be available:

* Java 11 for building
* Maven (running under Java 11)

### Stepwise instructions
Clone this git repository on your machine. In the root folder issue the command `mvn install`.
If there are multiple JRE/JDKs on your machine, please make sure that the environment variable
`JAVA_HOME` points to the JRE/JDK for Java 11, otherwise the Maven build may fail.

## SLEEC Tool Installation
Once the build has succeeded, the tool can be installed by using The Eclipse 
Installer and the Eclipse Product file `RoboTool_and_SLEEC.setup`.

1. Download the Eclipse Installer 2023-09 R from [https://www.eclipse.org/downloads/packages/installer](https://www.eclipse.org/downloads/packages/installer), extract and run it.
2. When the window with the installation options appears, click the hamburger button on the top-right corner.
   Deselect `Bundle Pools` and click on `Advanced mode`.
4. Click the green plus button (+) on the top-right corner. A dialog titled
   `Add User Products` will appear. Find the file `RoboTool_and_SLEEC.setup`,
   and then press `OK`.
3. Select a suitable Java VM. If there is no version suitable, then select a
   compatible Java Runtime Environment (JRE) for installation. It is also
   recommended that `Bundle Pool` is left disabled.
5. Click `Next` twice and for the field `SLEEC Tool repository location` browse
   to the folder `repository` of your local clone of this repository.
7. Click `Next` and finally `Finish`.
8. During the installation, which should take a couple of minutes, you will be
   prompted to:
   * Accept the EPL license: we recommend toggling `Remember accepted licenses`.
   * Trust `unsigned content of unknown origin`: you will need to click on
    `Select All` followed by `Trust Selected`.
9. At the end of this process, if everything succeeds, Eclipse 2021 will be
   launched automatically with the plug-ins in this folder installed, as well
   as the required dependencies (eg. Xtext, Sirius, RoboChart). You can then
   click `Finish` to exit the installer.

## FDR4 Installation
General instructions for installation are avaiable from [https://cocotec.io/fdr/](https://cocotec.io/fdr/).
Below we include specific instructions useful for installation on recent versions of Ubuntu LTS (22.04).
Root privileges are necessary to install FDR4 using its debian package.

### Installing FDR4 via apt-get
Under Ubuntu, installation can be achieved by using `apt-get` using the following commands:
```
sudo sh -c 'echo "deb http://dl.cocotec.io/fdr/debian/ fdr release\n" > /etc/apt/sources.list.d/fdr.list'
wget -qO - http://dl.cocotec.io/fdr/linux_deploy.key | sudo apt-key add -
sudo apt-get update
sudo apt-get install fdr
```
The apt-get install may fail due to a missing dependency on `libpng12`, which is no longer included in
recent Linux distributions. To workaround this problem, the [following commands](https://www.linuxuprising.com/2018/05/fix-libpng12-0-missing-in-ubuntu-1804.html) can be used to install
the missing dependency:
```
sudo add-apt-repository ppa:linuxuprising/libpng12
sudo apt-get update
sudo apt-get install libpng12-0
```

### Configuring TLS CA certificates for FDR4 activation
Recent Linux distributions have changed the path where TLS Certificate Authority (CA) certificates are stored.
FDR looks for this under `/etc/pki/tls/certs/ca-bundle.crt`, however Ubuntu LTS 22.04 has such certificates
available under `/etc/ssl/certs/ca-certificates.crt`. FDR, may, therefore fail to connect to its licensing
servers as a result. To workaround this issue, create a symlink using the following commands:
```
sudo mkdir -p /etc/pki/tls/certs/
sudo ln -s /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt
```

### Activating FDR4
FDR4 **must be activated** before performing any verification activity. The first time FDR4 is executed a dialog
will appear with instructions for activation. Alternatively, this can also be achieved by running the following
command in the terminal and following the instructions that appear aftewards:
```
refines test.csp
```

## Usage of tools via example
To demonstrate use of the SLEEC tool, an example is provided as an Eclipse project under the folder `examples/ALMI`.

Further details on the usage of the SLEEC tool can be found in [TBC](), while for RoboChart this can be found in the 
[RoboTool manual](https://robostar.cs.york.ac.uk/publications/techreports/reports/robotool-manual.pdf). 
For convenience, below, we include instructions for getting started with a demo example included in this repository.

### Importing example from Git repository
This can be loaded into Eclipse by using its EGit import facility:

1. In a running installation of the SLEEC Tool (in a running instance of Eclipse), select `File` > `Import`. After
   the `Import` wizzard dialog appears, select `Git` > `Projects from Git (with smart import)` and click `Next`.
2. When the pane `Select Repository Source` appears, select `Existing local repository` and click `Next`.
3. When the pane `Select a Git Repository` appears, click on `Add`. A new dialog will appear to facilitate
   locating the cloned copy of this repository. Click on `Browse` and locate it as appropriate. Then, in
   the list below, select the repository, and then click on `Add`.
4. Back in the pane `Select a Git Repository`, select the newly added repository and press `Next`.
5. In the pane named `Import projects from File System or Archive`, click `Deselect All`. Afterwards,
   search for the repository whose folder includes the path `examples/ALMI` and select it.
6. Finally click on `Finish`. The new project will now be loaded and appear under the view `Project Explorer`.
   You may expand the project view by clicking on the arrows to expand the file tree.

This Eclipse project contains SLEEC rules in the file `ALMI-demo.sleec` and a RoboChart model specified across
two packages in files `main.rct` and `system.rct`. After importing the project a prompt should appear to load
the graphical representation for the RoboChart models. If not, these can be loaded by expanding the tree under
the file `representations.aird` in the `Project Explorer` view and double-clicking on the package of interest.

### Redundancy and conflict checking
TBC

### Conformance verification
Before performing any verification ensure that FDR4 is correctly installed and configured, and activated, 
as described above. In the sample project ALMI, a file named `verification.assertions` contains a collection
of functional and sleec assertions. It can be loaded for edition by double-clicking on the file.

To run the verifications from within the Eclipse environment, right-click on the file `verification.assertions`
and select `RoboTool` > `CSP` > `Run...`. If FDR is correctly configured, the verification will be performed
in the background and a new file `verification_results.html` will be automatically opened. This file contains
a table of results for the verification of all assertions in the file `verification.assertions`.

Alternatively, the file `csp-gen/timed/file_verification.csp` automatically generated under the project folder
can be loaded into FDR for a more in-depth analysis of counter-examples.
