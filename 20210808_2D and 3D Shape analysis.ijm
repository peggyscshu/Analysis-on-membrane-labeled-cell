//Create dialog--------------------------------------------------------------------------------------------------------------------------------------------------
Dialog.create("Palmskin Analysis");
Dialog.addMessage("The images are analyzed in two steps.", 18);
Dialog.addMessage("1. Cells are cutted along the cell membrane. \n    Please choose the input format and define the image structure in the dialog.", 18);
Dialog.setInsets(5, 0, 3);
Dialog.addChoice("              Input format:", newArray(" tif ", " Leica lif "));
Dialog.addNumber("x (um)", 0.465);
Dialog.addToSameRow();
Dialog.addNumber("y (um)", 0.465);
Dialog.addToSameRow();
Dialog.addNumber("z (um)", 0.570);
Dialog.addNumber("Red (Ch)", 1);
Dialog.addToSameRow();
Dialog.addNumber("Green (Ch)", 2);
Dialog.addToSameRow();
Dialog.addNumber("Blue (Ch", 3);
Dialog.addToSameRow();
Dialog.addNumber("Nucleus (Ch)", 4);
Dialog.addMessage("2. Cell shape can be analyzed by either 2D or 3D mode. \n    If you only need the segmentated roi list, please choose ROI only.", 18);
labels = newArray("ROI only", " 2D Basic analysis", "3D volumn analysis");
defaults = newArray(false, true, false);
rows = 3;
columns = 1;
n = rows*columns;
Dialog.setInsets(5, 120, 3);
Dialog.addCheckboxGroup(rows, columns, labels, defaults);
Dialog.show();
//Get variables from the dialog
format = Dialog.getChoice();
xScale = Dialog.getNumber();
yScale = Dialog.getNumber();
zScale = Dialog.getNumber();
RedCh = Dialog.getNumber();
GreenCh = Dialog.getNumber();
BlueCh = Dialog.getNumber();
NucleusCh = Dialog.getNumber();
AnaROIonly = Dialog.getCheckbox();
AnaBasicAnalysis = Dialog.getCheckbox();
Ana3DAnalysis = Dialog.getCheckbox();
dir1 = getDirectory("Choose folder with raw files ");
dir1parent = File.getParent(dir1);
dir1name = File.getName(dir1);
dir2 = dir1parent+File.separator+dir1name+"--Ready for measure";
dir3 = dir1parent+File.separator+dir1name+"--measured tool";
dir4 = dir1parent+File.separator+dir1name+"--basic analysis";
dir5 = dir1parent+File.separator+dir1name+"--3D analysis";
if (File.exists(dir2)==false) {
		File.makeDirectory(dir2); 
	}
if (File.exists(dir3)==false) {
		File.makeDirectory(dir3); 
	}			
//showMessage(" --Process finished--\n  Now we are going to analyze images.");	
//print(AnaBasicAnalysis, AnaLineAnalysis, Ana3DAnalysis, AnaCloneAnalysis);
if(AnaROIonly == 1){
	LifToCutline();
	ROIonly();	
}
if(AnaBasicAnalysis == 1){
	if (File.exists(dir4)==false) {
		File.makeDirectory(dir4); 
	}
	LifToCutline();
	basicAnalysis();	
}
if(Ana3DAnalysis == 1){
	if (File.exists(dir5)==false) {
		File.makeDirectory(dir5); 
	}
	ThreeDAnalysis();
}
//function "LifToCutline"---------------------------------------------------------------------------------------------------------------------------------------------------
function LifToCutline() {
	run("Bio-Formats Macro Extensions");
	//dir1 = getDirectory("Choose folder with lif files ");
	list = getFileList(dir1);
	setBatchMode(true);
	for (i=0; i<list.length; i++){
		showProgress(i+1, list.length);
		print("processing ... "+i+1+"/"+list.length+"\n         "+list[i]);
		path=dir1+list[i];

		//how many series in this lif file?
		run("Bio-Formats Macro Extensions");
		Ext.setId(path);//-- Initializes the given path (filename).
		Ext.getSeriesCount(seriesCount); //-- Gets the number of image series in the active dataset.
	
		for (j=1; j<=seriesCount; j++) {
			run("Bio-Formats", "open=path autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_"+j);
			name=File.nameWithoutExtension;
			seriesname=getTitle();
			seN=replace(seriesname, ".lif", "");
			print("processing ... " + " series "+j + "/" + seriesCount + " in " + i+1 + "/" +list.length+" files"+"\n         " + name);
			getDimensions(width, height, channels, slices, frames);
			run("Properties...", "channels=channels slices=slices frames=frames pixel_width=xScale pixel_height=yScale voxel_depth=zScale");
			//project and save
			if (slices>1) {
				saveAs("TIFF", dir2+File.separator+seN+".tif");//1
				//1. Process to smooth the cell boundary
					rename("Raw");
					run("Z Project...", "projection=[Max Intensity]");
					selectWindow("MAX_Raw");
					run("Split Channels");
					selectWindow("C" + RedCh + "-MAX_Raw");
					rename("Red");
					selectWindow("C" + GreenCh + "-MAX_Raw");
					rename("Green");
					selectWindow("C" + BlueCh + "-MAX_Raw");
					rename("Blue");
					run("Merge Channels...", "c1=Red c2=Green c3=Blue create");
					rename("RGB");
					run("Flatten");
					run("8-bit");
					selectWindow("RGB (RGB)");
					run("Anisotropic Diffusion 2D", "number=20 smoothings=1 keep=20 a1=0.50 a2=0.90 dt=20 edge=5");
					selectWindow("RGB-iter20");
					saveAs("TIFF", dir2 + File.separator + seriesname+ "_3c MIP.tif");//2
			    //2. Process to get boundary line
					selectWindow(seriesname + "_3c MIP.tif");
					rename("3C MIP");
					run("Gaussian Blur...", "sigma=1.5");
					run("Duplicate...", "title=BG");
					selectWindow("BG");
					run("Gaussian Blur...", "sigma=6");
					imageCalculator("Subtract create", "3C MIP","BG");
					selectWindow("Result of 3C MIP");
					setMinAndMax(0, 21);
					run("Apply LUT");
					run("Gaussian Blur...", "sigma=3");
					run("Gaussian Blur...", "sigma=4");
				//3. Find cell marker
					selectWindow("Result of 3C MIP");
					run("Find Maxima...", "prominence=9 light output=[Segmented Particles]");
					selectWindow("Result of 3C MIP Segmented");
					saveAs("TIFF", dir2 + File.separator + seN + "_CellSelect.tif");//3
					rename("CellSelect");
					run("Find Maxima...", "prominence=9 light output=[Single Points]");
					rename("Marker");
				//4. Marker-based watershed
					selectWindow("3C MIP");
					run("Morphological Filters", "operation=Gradient element=Square radius=2");
					selectWindow("3C-Gradient");
					rename("Gradient");
					run("Marker-controlled Watershed", "input=Gradient marker=Marker mask=None binary calculate use");
					setThreshold(1.0000, 1000000000000000000000000000000.0000);
					run("Convert to Mask");
					selectWindow("Gradient-watershed");
					rename("Watershed");
				//Select the line within mask
					selectWindow("Watershed");
					run("Erode");
					run("Divide...", "value=255");
					selectWindow("Raw");
					run("Duplicate...", "title=Red duplicate channels=RedCh");
					selectWindow("Raw");
					run("Duplicate...", "title=Green duplicate channels=GreenCh");
					selectWindow("Raw");
					run("Duplicate...", "title=Blue duplicate channels=BlueCh");
					run("Merge Channels...", "c1=Red c2=Green c3=Blue create");
					rename("RGB");
					imageCalculator("Multiply create stack", "RGB","Watershed");
					selectWindow("Raw");
					run("Duplicate...", "title=DAPI duplicate channels=NucleusCh");
					selectWindow("Result of RGB");
					run("Split Channels");
					run("Merge Channels...", "c1=[C3-Result of RGB] c2=[C2-Result of RGB] c3=[C1-Result of RGB] c4=DAPI create");
					saveAs("TIFF", dir2 + File.separator + seN + "_Ready for analysis.tif");//4
				//Clear
			    	run("Close All");
				//Clear HD
			 		File.delete(dir2+File.separator+seN+".tif");
			 		File.delete(dir2 + File.separator + seriesname+ "_3c MIP.tif");
			 		File.delete(dir2 + File.separator + seN + "_CellSelect.tif");
		}
		else showMessage(" No Z stack inside");	
		}
	}
	setBatchMode(false);
}
//Function ROIonly--------------------------------------------------------------------------------------------------
function ROIonly(){
	list = getFileList(dir2);
	setBatchMode(true);
	for (i=0; i<list.length; i++){
		showProgress(i+1, list.length);
		print("processing ... "+i+1+"/"+list.length+"\n         "+list[i]);
		path=dir2 + File.separator + list[i];
		open(path);
		getPixelSize(unit, pixelWidth, pixelHeight);
		tifName = getTitle();
		nameWoExt=replace(tifName, ".tif", "");
		rename("Raw");
		run("Z Project...", "projection=[Max Intensity]");
		selectWindow("MAX_Raw");
		run("Duplicate...", "duplicate channels=1-3");
		selectWindow("MAX_Raw-1");
		run("Flatten");
		selectWindow("MAX_Raw-1 (RGB)");
		rename(nameWoExt);
		saveAs("TIFF", dir3 + File.separator + nameWoExt + "_2D analysis.tif");//1
		run("8-bit");
		setThreshold(1, 255);
		selectWindow(nameWoExt + "_2D analysis.tif");
		run("Set Measurements...", "area centroid shape feret's display redirect=None decimal=2");
		run("Analyze Particles...", "size=10-1040 display add");
		roiManager("Save", dir3 + File.separator + nameWoExt + "_RoiSet.zip");//2
	}
selectWindow("Log");
run("Close");
selectWindow("Results");
run("Close");	
setBatchMode(false);
}
//Function basic analysis--------------------------------------------------------------------------------------------------------------------------------------------------
function basicAnalysis(){
	list = getFileList(dir2);
	setBatchMode(true);
	for (i=0; i<list.length; i++){
		showProgress(i+1, list.length);
		print("processing ... "+i+1+"/"+list.length+"\n         "+list[i]);
		path=dir2 + File.separator + list[i];
		open(path);
		getPixelSize(unit, pixelWidth, pixelHeight);
		tifName = getTitle();
		nameWoExt=replace(tifName, ".tif", "");
		rename("Raw");
		run("Z Project...", "projection=[Max Intensity]");
		selectWindow("MAX_Raw");
		run("Duplicate...", "duplicate channels=1-3");
		selectWindow("MAX_Raw-1");
		run("Flatten");
		selectWindow("MAX_Raw-1 (RGB)");
		rename(nameWoExt);
		saveAs("TIFF", dir3 + File.separator + nameWoExt + "_2D analysis.tif");//1
		run("8-bit");
		setThreshold(1, 255);
		selectWindow(nameWoExt + "_2D analysis.tif");
		run("Set Measurements...", "area centroid shape feret's display redirect=None decimal=2");
		run("Analyze Particles...", "size=10-1040 display add");
		roiManager("Save", dir3 + File.separator + nameWoExt + "_RoiSet.zip");//2
		saveAs("Results", dir4 + File.separator + nameWoExt + "_Basic analysis.csv");//3
		//Clear
		roiManager("Deselect");
		roiManager("Delete");
		run("Close All");
		run("Clear Results");
	}
selectWindow("Log");
run("Close");
selectWindow("Results");
run("Close");
setBatchMode(false);
}
//Function 3DAnalysis------------------------------------------------------------------------------------------------
function ThreeDAnalysis(){
	//LifToCut()--------------------------------------------------------
	run("Bio-Formats Macro Extensions");
	//dir1 = getDirectory("Choose folder with lif files ");
	list = getFileList(dir1);
	setBatchMode(true);
	for (i=0; i<list.length; i++){
		showProgress(i+1, list.length);
		print("processing ... "+i+1+"/"+list.length+"\n         "+list[i]);
		path=dir1+list[i];

		//how many series in this lif file?
		run("Bio-Formats Macro Extensions");
		Ext.setId(path);//-- Initializes the given path (filename).
		Ext.getSeriesCount(seriesCount); //-- Gets the number of image series in the active dataset.
	
		for (j=1; j<=seriesCount; j++) {
			run("Bio-Formats", "open=path autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_"+j);
			name=File.nameWithoutExtension;
			seriesname=getTitle();
			seN=replace(seriesname, ".lif", "");
			print("processing ... " + " series "+j + "/" + seriesCount + " in " + i+1 + "/" +list.length+" files"+"\n         " + name);
			getDimensions(width, height, channels, slices, frames);
			run("Properties...", "channels=channels slices=slices frames=frames pixel_width=xScale pixel_height=yScale voxel_depth=zScale");
			//project and save
			if (slices>1) {
				saveAs("TIFF", dir2+File.separator+seN+".tif");//1
				//1. Process to smooth the cell boundary
					rename("Raw");
					run("Z Project...", "projection=[Max Intensity]");
					selectWindow("MAX_Raw");
					run("Split Channels");
					selectWindow("C" + RedCh + "-MAX_Raw");
					rename("Red");
					selectWindow("C" + GreenCh + "-MAX_Raw");
					rename("Green");
					selectWindow("C" + BlueCh + "-MAX_Raw");
					rename("Blue");
					run("Merge Channels...", "c1=Red c2=Green c3=Blue create");
					rename("RGB");
					run("Flatten");
					run("8-bit");
					selectWindow("RGB (RGB)");
					run("Anisotropic Diffusion 2D", "number=20 smoothings=1 keep=20 a1=0.50 a2=0.90 dt=20 edge=5");
					selectWindow("RGB-iter20");
					saveAs("TIFF", dir2 + File.separator + seriesname+ "_3c MIP.tif");//2
			    //2. Process to get boundary line
					selectWindow(seriesname + "_3c MIP.tif");
					rename("3C MIP");
					run("Gaussian Blur...", "sigma=1.5");
					run("Duplicate...", "title=BG");
					selectWindow("BG");
					run("Gaussian Blur...", "sigma=6");
					imageCalculator("Subtract create", "3C MIP","BG");
					selectWindow("Result of 3C MIP");
					setMinAndMax(0, 21);
					run("Apply LUT");
					run("Gaussian Blur...", "sigma=3");
					run("Gaussian Blur...", "sigma=4");
				//3. Find cell marker
					selectWindow("Result of 3C MIP");
					run("Find Maxima...", "prominence=9 light output=[Segmented Particles]");
					selectWindow("Result of 3C MIP Segmented");
					saveAs("TIFF", dir2 + File.separator + seN + "_CellSelect.tif");//3
					rename("CellSelect");
					run("Find Maxima...", "prominence=9 light output=[Single Points]");
					rename("Marker");
				//4. Marker-based watershed
					selectWindow("3C MIP");
					run("Morphological Filters", "operation=Gradient element=Square radius=2");
					selectWindow("3C-Gradient");
					rename("Gradient");
					run("Marker-controlled Watershed", "input=Gradient marker=Marker mask=None binary calculate use");
					setThreshold(1.0000, 1000000000000000000000000000000.0000);
					run("Convert to Mask");
					selectWindow("Gradient-watershed");
					rename("Watershed");
				//Select the line within mask
					selectWindow("Watershed");
					run("Erode");
					run("Divide...", "value=255");
					selectWindow("Raw");
					run("Duplicate...", "title=Red duplicate channels=RedCh");
					selectWindow("Raw");
					run("Duplicate...", "title=Green duplicate channels=GreenCh");
					selectWindow("Raw");
					run("Duplicate...", "title=Blue duplicate channels=BlueCh");
					run("Merge Channels...", "c1=Red c2=Green c3=Blue create");
					rename("RGB");
					imageCalculator("Multiply create stack", "RGB","Watershed");
					selectWindow("Raw");
					run("Duplicate...", "title=DAPI duplicate channels=NucleusCh");
					selectWindow("Result of RGB");
					run("Split Channels");
					run("Merge Channels...", "c1=[C3-Result of RGB] c2=[C2-Result of RGB] c3=[C1-Result of RGB] c4=DAPI create");
					saveAs("TIFF", dir2 + File.separator + seN + "_Ready for analysis.tif");//4
				//Clear
			    	run("Close All");
				//Clear HD
			 		File.delete(dir2+File.separator+seN+".tif");
			 		File.delete(dir2 + File.separator + seriesname+ "_3c MIP.tif");
			 		File.delete(dir2 + File.separator + seN + "_CellSelect.tif");
		}
		else showMessage(" No Z stack inside");	
		}
	}
	dir= dir2;
	diropt = dir5;
	count = 0;
    countFiles(dir);
    n = 0;
    processFiles(dir);
	setBatchMode(false);
}
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
             path = dir+File.separator+list[i];
             processFile(path);
          }
      }
}

function processFile(path) {
     if (endsWith(path, ".tif")) {
        open(path);
        measureVol();
     }
}

function measureVol(){
	tifName= getTitle();
	folderName=replace(tifName, ".tif", "");
	output= diropt+File.separator + folderName;
	File.makeDirectory(output);
	selectWindow(tifName);
	getDimensions(width, height, channels, slices, frames);
	bin=slices%9;
	if(bin!=0){
		slices=slices-bin;
		bin=slices/9;
	}
	    	run("Size...", "width=1024 height=1024 depth=bin constrain average interpolation=Bilinear");
			rename("Raw");
			run("Split Channels");
			selectWindow("C1-Raw");
			rename("R");
			selectWindow("C2-Raw");
			rename("G");
			selectWindow("C3-Raw");
			rename("B");
			selectWindow("C4-Raw");
			rename("DAPI");
		//BG subtract from DAPI
			selectWindow("DAPI");
			run("Duplicate...", "title=[DAPI mask] duplicate");
			selectWindow("DAPI mask");
			run("Gaussian Blur...", "sigma=1.50 stack");
			setThreshold(21, 255);
			run("Convert to Mask", "method=Default background=Dark black");
			selectWindow("DAPI mask");
			run("Divide...", "value=255 stack");
			imageCalculator("Multiply create stack", "DAPI","DAPI mask");
			selectWindow("DAPI");
			close();
			selectWindow("DAPI mask");
			close();
			selectWindow("Result of DAPI");
			rename("DAPI");
		//Measure R
			selectWindow("R");
			run("3D OC Options", "volume nb_of_obj._voxels integrated_density bounding_box dots_size=5 font_size=10 show_numbers white_numbers redirect_to=DAPI");
			run("3D Objects Counter", "threshold=11 slice=5 min.=1000 max.=10485760 objects statistics summary");
			selectWindow("Objects map of R redirect to DAPI");
			saveAs("Tiff", output + File.separator + "R map_"+ tifName);
			saveAs("Results", output + File.separator + "Statistics for R redirect to DAPI.csv");
			selectWindow("R map_" + tifName);
			close();
			selectWindow("R");
			close();
			run("Clear Results");
		//Measure G
			selectWindow("G");
			run("3D OC Options", "volume nb_of_obj._voxels integrated_density bounding_box dots_size=5 font_size=10 show_numbers white_numbers redirect_to=DAPI");
			run("3D Objects Counter", "threshold=11 slice=5 min.=1000 max.=10485760 objects statistics summary");
			//setBatchMode(false);	
			selectWindow("Objects map of G redirect to DAPI");
			saveAs("Tiff", output + File.separator + "G map_"+ tifName);
			saveAs("Results", output + File.separator + "Statistics for G redirect to DAPI.csv");
			selectWindow("G map_" + tifName);
			close();
			selectWindow("G");
			close();
			run("Clear Results");
		//Measure B
			selectWindow("B");
			run("3D OC Options", "volume nb_of_obj._voxels integrated_density bounding_box dots_size=5 font_size=10 show_numbers white_numbers redirect_to=DAPI");
			run("3D Objects Counter", "threshold=11 slice=5 min.=1000 max.=10485760 objects statistics summary");
			selectWindow("Objects map of B redirect to DAPI");
			saveAs("Tiff", output + File.separator + "B map_"+ tifName);
			saveAs("Results", output + File.separator + "Statistics for B redirect to DAPI.csv");
			selectWindow("B map_" + tifName);
			close();
			selectWindow("B");
			close();
			run("Clear Results");
		//Clean
			run("Close All");
}