macro "Batch 3D OBIA of Autophagic Foci"{
/*
 * ***MACRO DESCRIPTION***
 * The macro was originally written by Dr Benjamin Scott Padman, for work conducted in his 2019 Nature Communications manuscript (doi: 10.1038/s41467-019-08335-6).
 * This version of the script has been optimized to make it generally applicable and user friendly, with comments outlining the important regions to consider.
 * The brightness corrector portion of this macro is based on the “Auto contrast adjustment” script for ImageJ written by Damien Guimond & Kota Miura (https://github.com/miura/IJ_BCautoMacro.git) in 2014. 
 * To visually inspect the ROIs generated using this script, please use the "3D_ROI_Inspector.ijm" companion macro.
 * If the user is unsatisfied with the quality of the image segmentation, they should refer to the ***TROUBLESHOOTING:*** section labelled below.
 * 
 * 
 * ***HOW TO USE THE MACRO***
 * STEP 1: Your images need to be stored in the following folder structure
 * 	ROOTDIRECTORY/
 * 	├── EXPERIMENT 1 (MAINFOLDER 1)/
 * 	│   ├── Images 			(All Z-stacks from one repeat go here; They need to be 8-bit TIFFs)
 * 	│   ├── ROIs
 * 	│   └── Outputs
 * 	├── EXPERIMENT 2 (MAINFOLDER 2)/...	(Separate each experimental repeat into a different main folder)
 * 
 * STEP 2: Adjust the parameters in the sections below labelled ***UserParameters*** 
 * This is the first section to look at if you're getting error messages.
 * These parameters might not require adjustment, but I'll put explanations in there just in case. 
 * 
 * STEP 3: Run the macro. It will ask you for 3 folders. Here is the purpose of each folder
 * FOLDER 1 ("1 IMAGES TO ANALYSE"):		Usually the main image folder (MAINFOLDER/EXPERIMENT 1/Images). If the macro crashed, you can choose a different folder with the remaining images.
 * FOLDER 2 ("2 ROI FILE DESTINATION"):	ONLY choose the main ROI folder (MAINFOLDER/EXPERIMENT 1/ROIs)
 * FOLDER 3 ("3 DATA FILE DESTINATION"):	ONLY choose the main Data folder (MAINFOLDER/EXPERIMENT 1/Outputs)
 * 
 * 
 * STEP 4: Wait for macro to complete. 
 * First, the macro will show you a montage of images. It will then show you a calculated threshold for that montage.
 * The threshold is for guidance only, since it is not 100% representative (its showing it in 2d instead of 3d)
 * Cancel the macro immediately if nothing gets detected... or "everything" gets detected. Otherwise, let the macro run.
 * It will fill the ROI and output folders with data.
 * 
 * 	***DISCLAIMER*** 
 * This ImageJ macro is provided "As is" under GNU General Public License v2.0. In no event shall the author of this macro or its contributors be liable for any direct, indirect, incidental, special, exemplary, or consequential damages (including, but not limited to, procurement of substitute goods or services; loss of use, data, or profits).
 */

// MACRO WARNING MESSAGE START
// You can delete this section once you've read and understood the messages
Dialog.create("WARNING!");
  Dialog.addMessage("READ THE MACRO INSTRUCTIONS BEFORE USE! \n This macro has the potential to overwrite data; \n Read the notes FIRST by editing the macro file in ImageJ/FIJI");
  Dialog.show();
// MACRO WARNING MESSAGE END

// 		***UserParameters***   
//Change the following settings to match your experimental parameters
//***FAILURE TO ADJUST THESE PARAMETERS WILL CRASH THE MACRO
// **Image Parameters**
		Number_Of_Channels = 4;		//How many channels in each image?
		Target_Foci_Channel = 3;	//This defines the channel used to create ROIs for analysis. What channel are your foci in?
		Number_Of_Slices = 10;		//How many z-slices in each image?
		Number_Of_Samples = 6;		//How many samples are there per repeat?
		Images_Per_Sample = 3;		//How many random images did you collect per sample?


//	**AnalysisParameters**
/* ***TROUBLESHOOTING:*** 
 * Look here if you need to troubleshoot the detection of foci in your images.
 * The first parameter to inspect is the "BRIGHTNESS_CUTOFF" 
 * When using a different microscope or staining procedure, you may need to adjust the autobrightness function.
 * Here are some useful numbers to know for the BRIGHTNESS_CUTOFF
 * BRIGHTNESS_CUTOFF = 20000; //to use min and max values that saturate 0.005% of all pixels
 * BRIGHTNESS_CUTOFF = 10000; //to use min and max values that saturate 0.01% of all pixels ***PREFERRED DEFAULT**
 * BRIGHTNESS_CUTOFF = 5000; //to use min and max values that saturate 0.02% of all pixels
 * BRIGHTNESS_CUTOFF = 2000; //to use min and max values that saturate 0.05% of all pixels
 * 
 * The next parameters to inspect are the minimum and maximum allowed foci size. These parameters are measured in voxels rather than micron. 
 * The Atg13 foci in my experiments have never exceeded 300 voxels (approx 3.2 cubic micron), but this may vary in your data.
 * If your images are being acquired at significantly higher magnification (or have VERY large foci), consider raising the value of MaximumAllowedFociSize.
 * Avoid altering the MinimumAllowedFociSize; If its smaller than 2 voxels (i.e. 1 voxel) its probably just sensor noise.
 * 
 * The final parameter to inspect is "newThresh"; newThresh defines the global threshold used on the images after brightness adjustment of the set.
 * For reasons that aren't entirely clear, I rarely ever need to adjust this parameter.
 * A value of 96 has so far worked for the analysis of Atg13, WIPI2B, Atg16L1, FIP200, Atg2B, etc. 
*/
		newThresh=96; 				//This is the global threshold. 96 has worked for everything so far... I have no idea how!...
		BRIGHTNESS_CUTOFF = 10000; 	//This will set the 0.02% lowest & 0.02% highest detected intensities as 0 & 255 respectively. 
		MinimumAllowedFociSize = 2; //Use this to define the minimum number of voxels required to call it a genuine foci
		MaximumAllowedFociSize = 300;//Use this to deal with chunks of debris that generate false signals
// 		***End of UserParameters***  


run("Close All");
//		***MACRO FRONT END***
   requires("1.33s"); 
   dir = getDirectory("1 IMAGES TO ANALYSE");
   dirthresh = dir;
   //dirthresh = getDirectory("2 IMAGES TO SET THRESHOLD");
   roidir = getDirectory("2 ROI FILE DESTINATION");
   outdir = getDirectory("3 DATA FILE DESTINATION");
//		This section will create new subfolders in the output folder
if (!File.exists(outdir+File.separator+"FOCI Vols")) {
	   File.makeDirectory(outdir+File.separator+"FOCI Vols");
outdirVols = outdir+File.separator+"FOCI Vols"+File.separator;
   } else {
outdirVols = outdir+File.separator+"FOCI Vols"+File.separator;
   }
   if (!File.exists(outdir+File.separator+"FOCICh1")) {
   	   File.makeDirectory(outdir+File.separator+"FOCICh1");
outdirCh1 = outdir+File.separator+"FOCICh1"+File.separator;
   } else {
outdirCh1 = outdir+File.separator+"FOCICh1"+File.separator;
   }
   if (!File.exists(outdir+File.separator+"FOCICh2")) {
   	   File.makeDirectory(outdir+File.separator+"FOCICh2");
outdirCh2 = outdir+File.separator+"FOCICh2"+File.separator;
   } else {
outdirCh2 = outdir+File.separator+"FOCICh2"+File.separator;
   }
if (Number_Of_Channels > 2) {
   if (!File.exists(outdir+File.separator+"FOCICh3")) {
   	   File.makeDirectory(outdir+File.separator+"FOCICh3");
outdirCh3 = outdir+File.separator+"FOCICh3"+File.separator;
   } else {
outdirCh3 = outdir+File.separator+"FOCICh3"+File.separator;
   }
}
   if (Number_Of_Channels > 3) {
   if (!File.exists(outdir+File.separator+"FOCICh4")) {
   	   File.makeDirectory(outdir+File.separator+"FOCICh4");
outdirCh4 = outdir+File.separator+"FOCICh4"+File.separator;
   } else {
outdirCh4 = outdir+File.separator+"FOCICh4"+File.separator;
   }
   }
/*
 * Quick sanity check, just to make sure that you actually read the instructions before running this macro
 */
Number_of_Images = Images_Per_Sample * Number_Of_Samples;
filecount = getFileList(dir);
if (Number_of_Images!=filecount.length) {
exit("ERROR: YOU FAILED TO FOLLOW THE INSTRUCTIONS! \n \n The user parameters were not adjusted before running the macro!");
}
filecount = getFileList(dir);
pathtemp = dir+filecount[1];
open(pathtemp);
getVoxelSize(VOXwidth2, VOXheight2, VOXdepth2, VOXunit2);
getDimensions(width2, height2, channels2, slices2, frames2);
if (channels2<2 || slices2<2 || VOXunit2=="pixels") {
exit("ERROR: YOU FAILED TO FOLLOW THE INSTRUCTIONS! \n \n The 3D OBIA macros only work on images that are: \n - 8-bit Tiffs \n - Multiple slices (i.e. stacks) \n - Multiple fluorescence channels \n - Have known pixel scale (units per pixel)");
}
run("Close All");

/*		***EXPERIMENT THRESHOLD DEFINER***
This section is required to account for variation in staining intensity between experiments.
Heres how it works: All images from an experimental repeat are imported, maximum projected, then assembled into a montage.
A previous version used the original image stacks, but no advantage was found.
The montage is then used to calculate new maximum and minimum brightnesses for the entire experiment.
This is identical to the "Enhance Contrast" calculation in imageJ. Depending on the quality of your data, you may need to adjust this parameter.
This lets you use the same global threshold for every image in every repeat.
To calculate the new brightness, this section will use the BRIGHTNESS_CUTOFF parameter listed above.
*/
run("Set Measurements...", "area mean standard modal min integrated median stack add redirect=None decimal=3");
run("Image Sequence...", "open=["+dirthresh+"] sort use");
run("Stack to Hyperstack...", "order=xyczt(default) channels="+Number_Of_Channels+" slices="+Number_Of_Slices+" frames="+Number_of_Images+" display=Composite");
expname = getTitle();
selectWindow(expname);
run("Duplicate...", "title=FOCI duplicate channels="+Target_Foci_Channel);
run("Median 3D...", "x=1 y=1 z=1");
stackname = getTitle();
selectWindow(expname);
close();
selectWindow("FOCI");
run("Hyperstack to Stack");
run("Grouped Z Project...", "projection=[Max Intensity] group="+Number_Of_Slices);
run("Make Montage...", "columns="+Images_Per_Sample+" rows="+Number_Of_Samples+" scale=1.0");
getStatistics(area, mean, min, max, std, histogram);

 getRawStatistics(pixcount);
 limit = 0.1*pixcount;
 threshold = pixcount/BRIGHTNESS_CUTOFF;
 nBins = 256;
 getHistogram(values, histA, nBins);
 getStatistics(area, mean, min, max, std, histogram);
 i = -1;
 found = false;
 do {
         counts = histA[++i];
         if (counts > limit) counts = 0;
         found = counts > threshold;
 }while ((!found) && (i < histA.length-1))
 hmin = values[i];
 i = histA.length;
 do {    counts = histA[--i];
         if (counts > limit) counts = 0; 
         found = counts > threshold;
 } while ((!found) && (i > 0))
 hmax = values[i];
 
newMin=hmin;
newMax=hmax;
setMinAndMax(newMin, newMax);
run("Apply LUT", "stack");
print("New minimum intensity: "+newMin);
print("New maximum intensity: "+newMax);
print("Global Threshold After Rescale : "+newThresh);
           print("Last chance to abort!");
           run("In [+]");
           wait(1000); 
setAutoThreshold("Default dark");
setThreshold(newThresh, 255);
wait(3000); 
print("For real, Last chance to abort!");
                      wait(3000); 
           print("HERE WE GOOO!");
           print("MACRO RUNNING NOW");
run("Close All");
setBatchMode(false);

// 	***BATCH PROCESS INITIATED HERE***
   run("3D Manager");
   count = 0;
   countFiles(dir);
   n = 0;
   processFiles(dir);
run("Set Measurements...", "area mean standard modal min integrated median stack add redirect=None decimal=3");
   
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
  function processFile(path) {
       	   setBatchMode(true);
           open(path);
	imgname = getTitle();
	getDimensions(width, height, channels, slices, frames);
	getVoxelSize(VOXwidth, VOXheight, VOXdepth, VOXunit);
run("Duplicate...", "title=FOCI duplicate channels="+Target_Foci_Channel);
selectWindow(imgname);
close();
selectWindow("FOCI");
//SEGMENTATION START
setMinAndMax(newMin, newMax);
run("Apply LUT", "stack");
run("Median 3D...", "x=1 y=1 z=1");
//Old version used 2px median filters
print("New minimum: "+newMin);
print("New maximum: "+newMax);
print("Global Threshold : "+newThresh);
Stack.getStatistics(count, mean, min, max, std);
if (max<newThresh) { 
	/*
 * NULL FOCI CATCH-ALL: The 3D ROI manager can't handle the absence of foci, and will crash the system if foci are missing.
 * To make sure that the macro doesnt crash, I've had to get creative with a workaround.
 * This section will create a decoy image, then make a single pixel "foci" in the middle of it.
 * The single voxel decoy foci will then be analyzed in a blank image to generate an empty dataset.
 * The empty dataset will not contribute to subsequent analyses
 * 
*/
  //		***DECOY ROI MAKER***
	print("NO FOCI DETECTED: loading decoy");
newImage("HyperStack", "8-bit color-mode", 512, 512, Number_Of_Channels, Number_Of_Slices, 1);
Stack.setChannel(Target_Foci_Channel);
run("Specify...", "width=1 height=1 x=256.50 y=256.50 slice=1 centered");
run("Fill", "slice");
run("Properties...", "unit="+VOXunit+" pixel_width="+VOXwidth+" pixel_height="+VOXheight+" voxel_depth="+VOXdepth);
run("3D Simple Segmentation", "low_threshold="+newThresh+" min_size=0 max_size=300");
Ext.Manager3D_AddImage();
wait(200); //To reduce crashing
Ext.Manager3D_Save(roidir+imgname+"_FOCIroi.zip");
wait(200); //To reduce crashing
run("Close All");
  //		***EMPTY IMAGE ANALYSER***
newImage("HyperStack", "8-bit color-mode", 512, 512, Number_Of_Channels, Number_Of_Slices, 1);
Stack.setChannel(Target_Foci_Channel);
run("Properties...", "unit="+VOXunit+" pixel_width="+VOXwidth+" pixel_height="+VOXheight+" voxel_depth="+VOXdepth);
           wait(100); 
Ext.Manager3D_SelectAll();
wait(300); //To reduce crashing
//To get volume of all objects, save it, then close it
Ext.Manager3D_Measure();
Ext.Manager3D_SaveResult("M",outdirVols+imgname+"Vol.csv");
Ext.Manager3D_CloseResult("M");
//Chan1 Fluoro
Stack.setChannel(1);
Ext.Manager3D_Quantif();
Ext.Manager3D_SaveResult("Q",outdirCh1+imgname+"IntCh1.csv");
Ext.Manager3D_CloseResult("Q");
//Chan2 Fluoro
Stack.setChannel(2);
Ext.Manager3D_Quantif();
Ext.Manager3D_SaveResult("Q",outdirCh2+imgname+"IntCh2.csv");
Ext.Manager3D_CloseResult("Q");
//Chan3 Fluoro
if (Number_Of_Channels > 2)
Stack.setChannel(3);
Ext.Manager3D_Quantif();
Ext.Manager3D_SaveResult("Q",outdirCh3+imgname+"IntCh3.csv");
Ext.Manager3D_CloseResult("Q");
//Chan4 Fluoro
if (Number_Of_Channels > 3)
Stack.setChannel(4);
Ext.Manager3D_Quantif();
Ext.Manager3D_SaveResult("Q",outdirCh3+imgname+"IntCh4.csv");
Ext.Manager3D_CloseResult("Q");
Ext.Manager3D_Reset();
} else {
	//	***REAL FOCI ANALYSER***
run("3D Simple Segmentation", "low_threshold="+newThresh+" min_size="+MinimumAllowedFociSize+" max_size="+MaximumAllowedFociSize);
Ext.Manager3D_AddImage();
wait(200); //To reduce crashing
Ext.Manager3D_Save(roidir+imgname+"_Foci3Droi.zip");
wait(200); //To reduce crashing
//Save the ROIs, but you may as well pump some quants out immediately
selectWindow("FOCI");
close();
          open(path);
           wait(100); 
Ext.Manager3D_SelectAll();
wait(300); //To reduce crashing
//To get volume of all objects, save it, then close it
Ext.Manager3D_Measure();
Ext.Manager3D_SaveResult("M",outdirVols+imgname+"Vol.csv");
Ext.Manager3D_CloseResult("M");
//Chan1 Fluoro
Stack.setChannel(1);
Ext.Manager3D_Quantif();
Ext.Manager3D_SaveResult("Q",outdirCh1+imgname+"IntCh1.csv");
Ext.Manager3D_CloseResult("Q");
//Chan2 Fluoro
Stack.setChannel(2);
Ext.Manager3D_Quantif();
Ext.Manager3D_SaveResult("Q",outdirCh2+imgname+"IntCh2.csv");
Ext.Manager3D_CloseResult("Q");
//Chan3 Fluoro
if (Number_Of_Channels > 2) {
Stack.setChannel(3);
Ext.Manager3D_Quantif();
Ext.Manager3D_SaveResult("Q",outdirCh3+imgname+"IntCh3.csv");
Ext.Manager3D_CloseResult("Q");
}
//Chan4 Fluoro
if (Number_Of_Channels > 3) {
Stack.setChannel(4);
Ext.Manager3D_Quantif();
Ext.Manager3D_SaveResult("Q",outdirCh4+imgname+"IntCh4.csv");
Ext.Manager3D_CloseResult("Q");
}
Ext.Manager3D_Reset();
}
  setBatchMode(false);
run("Close All");
      }
Ext.Manager3D_Close();
}
