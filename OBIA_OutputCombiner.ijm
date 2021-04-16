 macro "Merge OBIA measurements between ROIs" {
/*
 * ***MACRO DESCRIPTION***
 * The macro was written by Dr Benjamin Scott Padman, to simplify the numerical analysis of OBIA outputs.
 * This script will correlate all morphological/intensity measurements between each of the 3D ROIs generated by the 3D OBIA scripts (MitoQuant_OBIA.ijm, FociQuant_OBIA.ijm) 
 * 
 * 
 * 	***HOW TO USE THE MACRO***
 * STEP 1: You need to have already run one (or both) of the 3D quantification macros (MitoQuant_OBIA.ijm, FociQuant_OBIA.ijm).
 * If you followed the instructions included in those macros, your folder structure should look like this:
 * 	ROOTDIRECTORY/
 * 	├── EXPERIMENT (MAINFOLDER)/
 * 	    ├── Images 			
 * 	    ├── ROIs		
 * 	    └── Outputs		
 * 	 		  ├── (Mito/Foci) Vols		(Morphology of ROIs; Mito or Foci OBIA output)
 * 	  		  ├── (Mito/Foci)Ch1		(Channel 1 intensities of ROIs)
 * 	  	 	  ├── (Mito/Foci)Ch2		(Channel 2 intensities of ROIs)
 * 	   		  ├── ... 				etc.
 * 
 * 
 * STEP 2: Run the macro, and it will ask you for the "(Mito/Foci) Vols" subfolder in the outputs.
 * To combine the mitochondrial data, select ".../Outputs/Mito Vols"
 * To combine the autophagic foci data, select ".../Outputs/FOCI Vols"
 * 
 * STEP 3: The macro will now have created a new subdirectory in the outputs folder, containing the merged datasets for each image.
 * The new subdirectory with the final merged datasets is located here:
 * 	ROOTDIRECTORY/
 * 	├── EXPERIMENT (MAINFOLDER)/
 * 	    ├── ...		
 * 	    └── Outputs		
 * 	 		  ├── ...
 * 	   		  └── Merged (Mito/Foci) OBIA data		(Final the merged numerical outputs from OBIA)
 * 
 * 	***DISCLAIMER*** 
 * This ImageJ macro is provided "As is". In no event shall the author of this macro or its contributors be liable for any direct, indirect, incidental, special, exemplary, or consequential damages (including, but not limited to, procurement of substitute goods or services; loss of use, data, or profits).
 */
   dir = getDirectory("Where are the VOL outputs for your OBIA data?");

      count = 0;
   countFiles(dir);
     n = 0;
   processFiles(dir);
        requires("1.35r");

      function countFiles(dir) {
      list = getFileList(dir);
      for (i=0; i<list.length; i++) {
          if (endsWith(list[i], "/"))
              countFiles(""+dir+list[i]);
          else
              count++;
      }
  }

   function processFiles(dir) {
      list = getFileList(dir);
      for (i=0; i<list.length; i++) {
          if (endsWith(list[i], "/"))
              processFiles(""+dir+list[i]);
          else {
             showProgress(n++, count);
             path = dir+list[i];
          	processFile(path);
          }
          }
      }
  }
  function processFile(path) {
       	   setBatchMode(true);
     lineseparator = "\n";
     cellseparator = ",\t";
  run("Clear Results");
     linesVol=split(File.openAsString(path), lineseparator);
filenameVol = File.getName(path);
RootDataDIR = substring(File.getParent(path),0,lengthOf(File.getParent(path))-10);
OBIAStructureType = substring(File.getParent(path),lengthOf(File.getParent(path))-9,lengthOf(File.getParent(path))-5);
if (OBIAStructureType=="FOCI") {
	outDir=RootDataDIR+File.separator+"Merged Foci OBIA data";
GeneralizedFilename=substring(filenameVol,2,lengthOf(filenameVol)-7);
IntFile1=RootDataDIR+File.separator+"FOCICh1"+File.separator+"Q_"+GeneralizedFilename+"IntCh1.csv";
IntFile2=RootDataDIR+File.separator+"FOCICh2"+File.separator+"Q_"+GeneralizedFilename+"IntCh2.csv";
IntFile3=RootDataDIR+File.separator+"FOCICh3"+File.separator+"Q_"+GeneralizedFilename+"IntCh3.csv";
IntFile4=RootDataDIR+File.separator+"FOCICh4"+File.separator+"Q_"+GeneralizedFilename+"IntCh4.csv";
} else {
		outDir=RootDataDIR+File.separator+"Merged Mito OBIA data";
GeneralizedFilename=substring(filenameVol,2,lengthOf(filenameVol)-7);
IntFile1=RootDataDIR+File.separator+"MitoCh1"+File.separator+"Q_"+GeneralizedFilename+"IntCh1.csv";
IntFile2=RootDataDIR+File.separator+"MitoCh2"+File.separator+"Q_"+GeneralizedFilename+"IntCh2.csv";
IntFile3=RootDataDIR+File.separator+"MitoCh3"+File.separator+"Q_"+GeneralizedFilename+"IntCh3.csv";
IntFile4=RootDataDIR+File.separator+"MitoCh4"+File.separator+"Q_"+GeneralizedFilename+"IntCh4.csv";
} 
for (i=0; i<linesVol.length; i++) {
     labelsVol=split(linesVol[0], cellseparator);
     itemsVol=split(linesVol[i], cellseparator);
     for (j=0; j<labelsVol.length; j++){
     			if (i==0) {
        setResult(labelsVol[j],i,labelsVol[j]);
     } else {
     	setResult(labelsVol[j],i,itemsVol[j]);
     }
     }
     linesInt1=split(File.openAsString(IntFile1), lineseparator);
     labelsInt1=split(linesInt1[0], cellseparator);
     itemsInt1=split(linesInt1[i], cellseparator);
     for (j=0; j<labelsInt1.length; j++){
		if (i==0) {
        setResult("Ch1"+labelsInt1[j],i,labelsInt1[j]);
     } else {
     	setResult("Ch1"+labelsInt1[j],i,itemsInt1[j]);
     }
     }
     linesInt2=split(File.openAsString(IntFile2), lineseparator);
     labelsInt2=split(linesInt2[0], cellseparator);
     itemsInt2=split(linesInt2[i], cellseparator);
     for (j=0; j<labelsInt2.length; j++){
		if (i==0) {
        setResult("Ch2"+labelsInt2[j],i,labelsInt2[j]);
     } else {
     	setResult("Ch2"+labelsInt2[j],i,itemsInt2[j]);
     }
     }
	if (File.exists(IntFile3)) {
     linesInt3=split(File.openAsString(IntFile3), lineseparator);
     labelsInt3=split(linesInt3[0], cellseparator);
     itemsInt3=split(linesInt3[i], cellseparator);
     for (j=0; j<labelsInt3.length; j++){
		if (i==0) {
        setResult("Ch3"+labelsInt3[j],i,labelsInt3[j]);
     } else {
     	setResult("Ch3"+labelsInt3[j],i,itemsInt3[j]);
     }
     }
	}
	if (File.exists(IntFile4)) {
     linesInt4=split(File.openAsString(IntFile4), lineseparator);
     labelsInt4=split(linesInt4[0], cellseparator);
     itemsInt4=split(linesInt4[i], cellseparator);
     for (j=0; j<labelsInt4.length; j++){
		if (i==0) {
        setResult("Ch4"+labelsInt4[j],i,labelsInt4[j]);
     } else {
     	setResult("Ch4"+labelsInt4[j],i,itemsInt4[j]);
     }
     }
	}
}
if (!File.exists(outDir)) {
	   File.makeDirectory(outDir);
   } 
updateResults();
File.append(String.getResultsHeadings, outDir+File.separator+GeneralizedFilename+"RawData.xls");
IJ.deleteRows(0,0);
           String.copyResults; 
File.append(String.paste, outDir+File.separator+GeneralizedFilename+"RawData.xls");
run("Clear Results");
  setBatchMode(false);
run("Close All");    
 }