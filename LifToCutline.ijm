macro 'LifToCutline' {

	run("Bio-Formats Macro Extensions");
	dir1 = getDirectory("Choose folder with lif files ");
	list = getFileList(dir1);
	setBatchMode(true);
	
	// create folders for the tifs
		dir1parent = File.getParent(dir1);
		dir1name = File.getName(dir1);
		dir2 = dir1parent+File.separator+dir1name+"--Ready for Vol measurement";
		if (File.exists(dir2)==false) {
				File.makeDirectory(dir2); 
		}
 
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
			print("processing ... " + " series "+j + "/" + seriesCount + " in " + i+1 + "/" +list.length+"\n         "+list[i]);
			getDimensions(width, height, channels, slices, frames);

	//project and save
		if (slices>1) {
			saveAs("TIFF", dir2+File.separator+seN+".tif");//1
			//Process to smooth the cell boundary
				rename("Raw");
				run("Duplicate...", "duplicate channels=3-5");
				run("Z Project...", "projection=[Max Intensity]");
				selectWindow("MAX_Raw-1");
				run("Split Channels");
				run("Merge Channels...", "c1=C3-MAX_Raw-1 c2=C2-MAX_Raw-1 c3=C1-MAX_Raw-1 create");
				run("Flatten");
				run("8-bit");
				selectWindow("Composite (RGB)");
				run("Anisotropic Diffusion 2D", "number=20 smoothings=1 keep=20 a1=0.50 a2=0.90 dt=20 edge=5");
				selectWindow("Composite-iter20");
				saveAs("TIFF", dir2 + File.separator + seriesname+ "_3c MIP.tif");//2
			//Process to get boundary line
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
			//Find cell marker
				selectWindow("Result of 3C MIP");
				run("Find Maxima...", "prominence=9 light output=[Segmented Particles]");
				selectWindow("Result of 3C MIP Segmented");
				saveAs("TIFF", dir2 + File.separator + seN + "_CellSelect.tif");//3
				rename("CellSelect");
				run("Find Maxima...", "prominence=9 output=[Single Points]");
				rename("Marker");
			//Marker-based watershed
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
				run("Duplicate...", "title=3C duplicate channels=3-5");
				imageCalculator("Multiply create stack", "3C","Watershed");
				selectWindow("Raw");
				run("Duplicate...", "title=DAPI duplicate channels=1");
				selectWindow("Result of 3C");
				run("Split Channels");
				run("Merge Channels...", "c1=[C3-Result of 3C] c2=[C2-Result of 3C] c3=[C1-Result of 3C] c4=DAPI create");
				saveAs("TIFF", dir2 + File.separator + seN + "_Ready for Imaris.tif");//4
			//Clear
			    selectWindow("Raw");
				close();
				selectWindow("Raw-1");
				close();
				selectWindow("Composite (RGB)");
				close();
				selectWindow("3C MIP");
				close();
				selectWindow("BG");
				close();
				selectWindow("Result of 3C MIP");
				close();
				selectWindow("CellSelect");
				close();
				selectWindow("Marker");
				close();
				selectWindow("3C");
				close();
				selectWindow("Watershed");
				close();
				selectWindow("Gradient");
				close();
				run("Close All");
			//Clear HD
			 	File.delete(dir2+File.separator+seN+".tif");
			 	File.delete(dir2 + File.separator + seriesname+ "_3c MIP.tif");
			 	File.delete(dir2 + File.separator + seN + "_CellSelect.tif");
			//Measure the cell volume
			
		}
		else showMessage(" No Lif inside");	
		
	}
	}
showMessage(" -- finished --");	
run("Close All");
setBatchMode(false);

} // macro