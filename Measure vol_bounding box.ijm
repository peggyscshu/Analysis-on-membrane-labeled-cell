//Set Batch
   dir = getDirectory("Choose the image folder");
   diropt = getDirectory("Choose the output image folder");
   setBatchMode(true);
   count = 0;
   countFiles(dir);
   n = 0;
   processFiles(dir);
   
   function countFiles(dir) {
      list = getFileList(dir);
      for (i=0; i<list.length; i++) {
          if (endsWith(list[i], "/"))
              countFiles(""+dir+list[i]);
          else
              count++;
      }
    }
    //print(count);
    
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
       		if (endsWith(path, ".tif")) {
           		open(path);
           		measureVol();
           	}
  		}

		function measureVol(){
			tifName= getTitle();
			folderName=replace(tifName, ".tif", "");
			output= diropt + File.separator + folderName;
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
		setBatchMode(false);
//122 slices 1K*1K take 2.5 min	
//219 slices 1K*1K take 8.5 min
	
