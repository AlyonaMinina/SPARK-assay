//Alyona Minina. Uppsala.2025
//Clear the log window if it was open
	if (isOpen("Log")){
		selectWindow("Log");
		run("Close");
	}
	
//Print the unnecessary greeting
	print(" ");
	print("Welcome to the SPARK macro");
	print(" ");
	print(" ");
	
// ask user for the desired file format. It is kept as a dialog instead of automated detection, due to the frequent error of keeping extra tiff files in the analysis folder (despite the printed warning)
Dialog.create("Image file format");
Dialog.addMessage("Please select the format of the images used for this analysis. Hit ok to proceed to selecting the folder with the images.");
Dialog.addChoice("Image file format:", newArray(".czi", ".tif"));
Dialog.show();
image_format = Dialog.getChoice();

// Find the original directory and create a new one for quantification results
original_dir = getDirectory("Select a directory");
original_folder_name = File.getName(original_dir);
output_dir = original_dir +"Results" + File.separator;
File.makeDirectory(output_dir);

// Get a list of all files in the directory
file_list = getFileList(original_dir);

//If user selected .czi format, create a shorter list contiaiing .czi files only
if (image_format == ".czi") {
	image_list = newArray(0);
	for(z = 0; z < file_list.length; z++) {
		if(endsWith(file_list[z], ".czi")) {
			image_list = Array.concat(image_list, file_list[z]);
		}
	 }
	//abort the macro if no files of the correct format were found
 	if(image_list.length == 0){
    print("No '.czi' files found in the selected folder. Stopping the macro.");
    // Stop the macro execution
    exit();
	} 
}

//If user selected .tif format, create a shorter list contiaiing .tif files only
if (image_format == ".tif") {
	image_list = newArray(0);
	for(z = 0; z < file_list.length; z++) {
		if(endsWith(file_list[z], ".tif")) {
			image_list = Array.concat(image_list, file_list[z]);
		}
	 }
	//abort the macro if no files of the correct format were found
 	if(image_list.length == 0){
    print("No '.tif' files found in the selected folder. Stopping the macro.");
    // Stop the macro execution
    exit();
	}
}

// Tell user how many images will be analyzed by the macro
print(image_list.length + " " + image_format + " images were detected for analysis");
print("");
print(" ");


//Create the table for all results
	Table.create("Image Results");
	
//Loop analysis through the list of . czi files
	for (i = 0; i < image_list.length; i++){
		path = original_dir + image_list[i];
		run("Bio-Formats Windowless Importer",  "open=path");
		      
		//Get the image file title and remove the extension from it    
				title = getTitle();
				a = lengthOf(title);
				b = a-4;
				short_name = substring(title, 0, b);
				
		//Print for the user what image is being processed
				print ("Processing image " + i+1 + " out of " + image_list.length + ":");
				print(title);
				print("");
							
		///select quantifiable area on the image
			selectWindow(title);
			setSlice(1);
			run("Duplicate...", "duplicate channels=1");
			rename("Quantifiable Area");
			run("Enhance Contrast...", "saturated=0.35 normalize");
			setAutoThreshold("Otsu no-reset");
			setOption("BlackBackground", true);
			run("Convert to Mask");
			run("Convert to Mask");
			run("Despeckle");
			run("Options...", "iterations=1 count=2 black do=Dilate");
			roiManager("reset");
			run("Create Selection");
			roiManager("Add");
			run("Set Measurements...", "area redirect=None decimal=3");
			roiManager("Select", 0);
			roiManager("Save", output_dir + short_name +"_Quantifiable_area.zip");
			run("Clear Results");
			run("Measure");						
			//record the area size in um
			quant_area = getResult("Area", 0);
			current_last_row = Table.size("Image Results");
			Table.set("File name", current_last_row, short_name, "Image Results");
			Table.set("Quantifable area in um2", current_last_row, quant_area, "Image Results");
			run("Clear Results");
			if (isOpen("Quantifiable Area")){
			selectWindow("Quantifiable Area");
			run("Close");
		}
			
			//select SPARK puncta
			selectWindow(title);
			run("Duplicate...", "duplicate channels=1");
			rename("Original_image");
			selectWindow(title);
			run("Duplicate...", "duplicate channels=1");
			rename("SPARK_speckles");
			setAutoThreshold("Shanbhag no-reset");
			setOption("BlackBackground", true);
			run("Convert to Mask");
			run("Convert to Mask");
			run("Set Measurements...", "area integrated redirect=None decimal=3");
			run("Analyze Particles...", "  show=[Overlay Masks] display clear summarize");
			if (isOpen("Results")){
			selectWindow("Results");
			run("Close");
		}
			selectWindow("Summary");
			//rename("Results");
			number_of_speckles = getResult("Count", 0);
			area_of_speckles = getResult("Total Area", 0);
			IntDen_of_speckles = getResult("IntDen", 0);
			Table.set("Number of SPARK speckles", current_last_row, number_of_speckles, "Image Results");
			Table.set("Total area of SPARK speckles in um", current_last_row, area_of_speckles, "Image Results");
			Table.set("IntDen of SPARK speckles in um", current_last_row, IntDen_of_speckles, "Image Results");
			percent = area_of_speckles/(quant_area/100);
			Table.set("Area of SPARK speckles per um of quantifable area", current_last_row, percent, "Image Results");
			run("Clear Results");
			if (isOpen("Summary")){
			selectWindow("Summary");
			run("Close");
		}

			selectWindow("SPARK_speckles");
			run("Invert");
			run("RGB Color");
			selectWindow("Original_image");
			run("RGB Color");
			//Save thersholding results
			run("Combine...", "stack1=Original_image stack2=SPARK_speckles");
			saveAs("Tiff", output_dir + "Segmentation results for " + short_name + " .tif");
			close();
}			

//Save the quantification results into a .csv table file
	Table.save(output_dir + "SPARK macro results for experiment " + original_folder_name + ".csv");
	

//A feeble attempt to close those pesky ImageJ windows		
	run("Close All");
	selectWindow("ROI Manager");
	run("Close");
	if (isOpen("Image Results")){
	selectWindow("Image Results");
	run("Close");
	}

//Print the final message
print(" ");
   print("All Done!");
   print("Your quantification results are saved in the folder " + output_dir);
   print(" "); 
   print(" ");
   print("Alyona Minina. 2025");
   
//Save the log
	selectWindow("Log");
	saveAs("Text", output_dir + "Analysis summary.txt");