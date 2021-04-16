macro "Batch 3D OBIA of Mitochondria [F9]"{
/*
 * ***MACRO DESCRIPTION***
 * The macro was originally written by Dr Benjamin Scott Padman, for work conducted in his 2019 Nature Communications manuscript (doi: 10.1038/s41467-019-08335-6).
 * This version of the script has been optimized to make it generally applicable and user friendly, with comments outlining the important parameters to consider.
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
 * This is the first section to look at if you're getting error messages. The mitochondrial script only has 1 parameter to change.
 * 
 * STEP 3: Run the macro. It will ask you for 3 folders. Here is the purpose of each folder
 * FOLDER 1 ("1 IMAGES TO ANALYSE"):		Usually the main image folder (MAINFOLDER/EXPERIMENT 1/Images). If the macro crashed, you can choose a different folder with the remaining images.
 * FOLDER 2 ("2 ROI FILE DESTINATION"):	ONLY choose the main ROI folder (MAINFOLDER/EXPERIMENT 1/ROIs)
 * FOLDER 3 ("3 DATA FILE DESTINATION"):	ONLY choose the main Data folder (MAINFOLDER/EXPERIMENT 1/Outputs)
 * 
 * STEP 4: Wait for macro to complete. 
 * It will fill the ROI and output folders with data.
 * 
 * 	***DISCLAIMER*** 
 * This ImageJ macro is provided "As is". In no event shall the author of this macro or its contributors be liable for any direct, indirect, incidental, special, exemplary, or consequential damages (including, but not limited to, procurement of substitute goods or services; loss of use, data, or profits).
 */

// MACRO WARNING MESSAGE START
// You can delete this section once you've read and understood the messages
Dialog.create("WARNING!");
  Dialog.addMessage("READ THE MACRO INSTRUCTIONS BEFORE USE! \n This macro has the potential to overwrite data; \n Read the notes FIRST by editing the macro file in ImageJ/FIJI");
  Dialog.show();
// MACRO WARNING MESSAGE END
// 		***UserParameters***   
		//Change the following settings to match your experimental parameters
		Number_Of_Channels = 3;
		Target_Mito_Channel = 3;	//This defines the channel used to create ROIs for analysis. What channel are your mitochondria in?
// 		***End of UserParameters***     

//		***MACRO FRONT END***
   requires("1.33s"); //I'll update this eventually
   dir = getDirectory("Where are your Images??");
   roidir = getDirectory("Where will the ROIs go? ");
   outdir = getDirectory("Where is the data going?? ");
   //This section is to separate out the different channel data into folders
if (!File.exists(outdir+File.separator+"Mito Vols")) {
	   File.makeDirectory(outdir+File.separator+"Mito Vols");
outdirVols = outdir+File.separator+"Mito Vols"+File.separator;
   } else {
outdirVols = outdir+File.separator+"Mito Vols"+File.separator;
   }

   if (!File.exists(outdir+File.separator+"MitoCh1")) {
   	   File.makeDirectory(outdir+File.separator+"MitoCh1");
outdirCh1 = outdir+File.separator+"MitoCh1"+File.separator;
   } else {
outdirCh1 = outdir+File.separator+"MitoCh1"+File.separator;
   }

   if (!File.exists(outdir+File.separator+"MitoCh2")) {
   	   File.makeDirectory(outdir+File.separator+"MitoCh2");
outdirCh2 = outdir+File.separator+"MitoCh2"+File.separator;
   } else {
outdirCh2 = outdir+File.separator+"MitoCh2"+File.separator;
   }
   if (Number_Of_Channels > 2) {
   if (!File.exists(outdir+File.separator+"MitoCh3")) {
   	   File.makeDirectory(outdir+File.separator+"MitoCh3");
outdirCh3 = outdir+File.separator+"MitoCh3"+File.separator;
   } else {
outdirCh3 = outdir+File.separator+"MitoCh3"+File.separator;
   }
   }
      if (Number_Of_Channels > 3) {
      if (!File.exists(outdir+File.separator+"MitoCh4")) {
   	   File.makeDirectory(outdir+File.separator+"MitoCh4");
outdirCh4 = outdir+File.separator+"MitoCh4"+File.separator;
   } else {
outdirCh4 = outdir+File.separator+"MitoCh4"+File.separator;
   }
      }
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
      	   call("java.lang.System.gc");
           open(path);
	imgname = getTitle();
	getVoxelSize(VOXwidth, VOXheight, VOXdepth, VOXunit);
	getDimensions(width, height, channels, slices, frames);
run("Duplicate...", "title=mitos duplicate channels="+Target_Mito_Channel);
selectWindow(imgname);
close();
/*
 * Quick sanity check, just to make sure that you actually read the instructions before running this macro
 */
if (channels<2 || slices<2 || VOXunit=="pixels") {
exit("ERROR: YOU FAILED TO FOLLOW THE INSTRUCTIONS! \n \n The 3D OBIA macros only work on images that are: \n - 8-bit Tiffs \n - Multiple slices (i.e. stacks) \n - Multiple fluorescence channels \n - Have known pixel scale (units per pixel)");
}

//	SEGMENTATION START
/* ***TROUBLESHOOTING:***
 * Look here if you need to troubleshoot the detection of mitochondria in your images.
 * The radii of each filter are the first parameters to inspect;The current parameters were set up for an x/y/z voxel size of 180/180/320nm. 
 * If the scale of you images is significantly different, consider changing the radius of the following functions: 
 * "Subtract Background...", "Median...", or any of the threshold functions.
 * If you suspect that the the scale of the images is fine, consider changing the autolocal threshold algorithm from Bernsen (to something like Phansalkar).
 */
 
	//	Image PreProcessing
selectWindow("mitos");
run("Subtract Background...", "rolling=50 sliding stack");
run("Enhance Contrast...", "saturated=0.2 process_all use");
run("Median...", "radius=1.25 stack");
	//MAKE SEEDS
run("3D Fast Filters","filter=MaximumLocal radius_x_pix=8.0 radius_y_pix=8.0 radius_z_pix=4.0 Nb_cpus=8");
selectWindow("mitos");
	//PRE-THRESHOLD FOR 3D WATERSHED; STAGE 1 OF MULTISTAGE THRESHOLD
run("Median 3D...", "x=2 y=2 z=2");
run("Auto Local Threshold", "method=Bernsen radius=5 parameter_1=0 parameter_2=0 white stack");

//These macros have a habit of over-writing the original scale information in the image
run("Properties...", "unit="+VOXunit+" pixel_width="+VOXwidth+" pixel_height="+VOXheight+" voxel_depth="+VOXdepth); 
	//FINAL THRESHOLD FOR 3D WATERSHED; STAGE 1 OF MULTISTAGE THRESHOLD
run("3D Watershed Split", "binary=mitos seeds=3D_MaximumLocal radius=5");
	//	SEGMENTATION END
run("Properties...", "unit="+VOXunit+" pixel_width="+VOXwidth+" pixel_height="+VOXheight+" voxel_depth="+VOXdepth); 

//***ROIS GET CREATED HERE***
wait(300); //To reduce probability of crashing
//The first ROI is not mitochondria! (its everything EXCEPT the mitochondria)
Ext.Manager3D_AddImage();


wait(100); //To reduce crashing
Ext.Manager3D_DeselectAll();
Ext.Manager3D_Select(0);
Ext.Manager3D_Delete();
//The first ROI is not mitochondria! (its everything EXCEPT the mitochondria)
wait(100); //To reduce crashing
Ext.Manager3D_SelectAll();
wait(100); //To reduce crashing

//Save the ROIs, then quant what youve got
Ext.Manager3D_Save(roidir+imgname+"_Mito3Droi.zip");
wait(100); //To reduce crashing
run("Close All");
wait(100); //To reduce crashing
      	   setBatchMode(false);
//      	   setBatchMode(true);
wait(100); //To reduce crashing
	//***END OF ROI CREATION***


	//**START OF ROI ANALYSIS IN ALL CHANNELS**
           open(path);
//These macros have a habit of over-writing the original scale information in the image for some reason. Thats why i keep re-applying the scale.
run("Properties...", "unit="+VOXunit+" pixel_width="+VOXwidth+" pixel_height="+VOXheight+" voxel_depth="+VOXdepth); 
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
//**END OF ROI ANALYSIS IN ALL CHANNELS**
}
Ext.Manager3D_Reset();

//  setBatchMode(false);
run("Close All");

      }
Ext.Manager3D_Close();
}
