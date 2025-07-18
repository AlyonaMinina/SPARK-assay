//Alyona Minina. Uppsala.2025
//Clear the log window if it was open
if (isOpen("Log")){
	selectWindow("Log");
	run("Close");	
}

// Create tables for quantification in two channels
Ch1_table = "Channel 1 quantifications";
Table.create(Ch1_table);
Ch2_table = "Channel 2 quantifications";
Table.create(Ch2_table);
Column_1 = "File name";
Column_2 = "Punctum number";
Column_3 = "Punctum area_um";
Column_4 = "Mean intensty";
Column_5 = "Total root area_um";


// Print the unnecessary greeting
print(" ");
print("Welcome to the SPARK IJM");
print(" ");

// Find the original directory and create a new timestamped subfolder for quantification results
original_dir = getDirectory("Select a directory");
original_folder_name = File.getName(original_dir);

// Check for folders with previous IJM runs results
r_list = newArray();
file_list = getFileList(original_dir);	// Get a list of all files and folders in the directory

for (f = 0; f < file_list.length; f++) {	// Then loop through the rest of the directories and add any folders starting with "IJM results"
    if (startsWith(file_list[f].trim(), "IJM results")) {	// Ensure no leading/trailing spaces
        r_list = Array.concat(r_list, file_list[f]);
	}
}

if(r_list.length>0) {
		previous_run = substring(r_list[r_list.length-1], 0, 28);
		previous_run_dir = original_dir + previous_run + File.separator;
}

//create an output directory with a time stamp
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);	// Get the current date and time components
//make sure the time stamp has the same length ndependent on the date/time
month = month +1;
if(month < 10) {                            
	month = "0" + month;	
}
if(dayOfMonth < 10){
	dayOfMonth = "0" + dayOfMonth;
}
if(hour < 10){
hour = "0" + hour;
}
if(minute < 10){
minute = "0" + minute;
}
if(second < 10){
second = "0" + second;
}
timestamp = "" + year + "" + month + "" + dayOfMonth + "-" + hour + "" + minute + "" + second;      // Format and print the timestamp without leading zeros in the day and month
output_dir = original_dir + "IJM results " + timestamp + File.separator;
File.makeDirectory(output_dir);

// Get a list of all files in the directory
file_list = getFileList(original_dir);
image_list = newArray(0);
for(z = 0; z < file_list.length; z++) {
	if(endsWith(file_list[z], ".tif")) {
		image_list = Array.concat(image_list, file_list[z]);
	}
}
// Tell user how many images will be analyzed by the macro
print(image_list.length + " images were detected for analysis");
print("");

// Loop analysis through the list of image files
for (i = 0; i < image_list.length; i++) {
	path = original_dir + image_list[i];
	run("Bio-Formats Windowless Importer",  "open=path");
		      
	// Get the image file title and remove the extension from it    
	title = getTitle();
	a = lengthOf(title);
	b = a-4;
	short_name = substring(title, 0, b);
			
	// Print for the user what image is being processed
	print ("Processing image " + i+1 + " out of " + image_list.length + ":");
	print(title);
	print("");
	
	//create a z projection
	selectWindow(title);
	run("Z Project...", "projection=[Max Intensity]");
	rename("Max");
	
	//Create a root mask
	selectWindow("Max");
	run("Select None");
	run("Duplicate...", "title=[Root mask]");
	setAutoThreshold("MinError dark no-reset");
	run("Convert to Mask");
	run("Remove Outliers...", "radius=10 threshold=50 which=Dark");
	run("Create Selection");
	run("ROI Manager...");
	roiManager("reset");
	roiManager("Add");
	roiManager("save", output_dir + short_name + " root mask ROI.zip"); //save root mask ROI
	run("Set Measurements...", "area redirect=None decimal=3");
	roiManager("select", 0);
	run("Clear Results");
	roiManager("Measure");
	Root_area = getResult("Area",0);
	run("Clear Results");
	
	//Quantify puncta in Channel 1
	selectWindow("Max");
	run("Subtract Background...", "rolling=25 stack");
	run("Split Channels");
	run("Select None");
	selectWindow("C1-Max");
	run("Select None");
	run("Duplicate...", "title=[C1_mask]");
	setAutoThreshold("Minimum dark no-reset");
	run("Convert to Mask");
	run("Watershed");
	run("Create Selection");
	run("ROI Manager...");
	roiManager("reset");
	roiManager("Add");
	roiManager("save", output_dir + short_name + " puncta in ch1 ROI.zip"); //save selection of all puncta
	run("Green");
	
	selectWindow("C1-Max");	
	roiManager("select", 0);
	roiManager("Split");
	roiManager("select", 0);
	roiManager("delete");
	run("Set Measurements...", "area mean redirect=None decimal=3");
	ROI_number = roiManager("count");
	for (r = 0; r < ROI_number; r++) {
		roiManager("select", r);
		run("Clear Results");
		roiManager("Measure");
		current_last_row = Table.size(Ch1_table);
		Table.set(Column_1, current_last_row, short_name);
		Table.set(Column_2, current_last_row, r+1);
		Table.set(Column_3, current_last_row, getResult("Area", 0));
		Table.set(Column_4, current_last_row, getResult("Mean", 0));
		Table.set(Column_5, current_last_row, Root_area);
	}
	//save quantification results for the Channel 1 of the image. Intermediate step in case if macro run is interrupted
	Table.save(output_dir + "IJM results for Channel 1.csv", Ch1_table);
	
	//create a combined preview for Ch1
	selectWindow("C1-Max");
	run("RGB Color");
	run("Scale Bar...", "width=50 height=20 font=20 horizontal bold");
	x = getWidth() + 3;
	y = getHeight() + 3;
	setBackgroundColor(255, 255, 255);
	run("Canvas Size...", "width=" + x + " height=" + "y" + " position=Center");
	selectWindow("C1_mask");
	run("RGB Color");
	x = getWidth() + 3;
	y = getHeight() + 3;
	setBackgroundColor(255, 255, 255);
	run("Canvas Size...", "width=" + x + " height=" + "y" + " position=Center");
	run("Combine...", "stack1=C1-Max stack2=C1_mask");
	rename("Ch1");


//Quantify puncta in Channel 2
	run("Select None");
	selectWindow("C2-Max");
	run("Select None");
	run("Duplicate...", "title=[C2_mask]");
	setAutoThreshold("Minimum dark no-reset");
	run("Convert to Mask");
	run("Watershed");
	run("Create Selection");
	run("ROI Manager...");
	roiManager("reset");
	roiManager("Add");
	roiManager("save", output_dir + short_name + "puncta in ch2 ROI.zip"); //save selection of all puncta
	run("Magenta");
	
	selectWindow("C2-Max");	
	roiManager("select", 0);
	roiManager("Split");
	roiManager("select", 0);
	roiManager("delete");
	run("Set Measurements...", "area mean redirect=None decimal=3");
	ROI_number = roiManager("count");
	for (r = 0; r < ROI_number; r++) {
		roiManager("select", r);
		run("Clear Results");
		roiManager("Measure");
		current_last_row = Table.size(Ch2_table);
		Table.set(Column_1, current_last_row, short_name);
		Table.set(Column_2, current_last_row, r+1);
		Table.set(Column_3, current_last_row, getResult("Area", 0));
		Table.set(Column_4, current_last_row, getResult("Mean", 0));
		Table.set(Column_5, current_last_row, Root_area);
	}
	//save qunatification results for the Channel 2 of the image. Intermediate step in case if macro run is interrupted
	Table.save(output_dir + "IJM results for Channel 2.csv", Ch2_table);
	
	//create a combined preview for Ch2
	selectWindow("C2-Max");
	run("RGB Color");
	run("Scale Bar...", "width=50 height=20 font=20 horizontal bold");
	x = getWidth() + 3;
	y = getHeight() + 3;
	setBackgroundColor(255, 255, 255);
	run("Canvas Size...", "width=" + x + " height=" + "y" + " position=Center");
	selectWindow("C2_mask");
	run("RGB Color");
	x = getWidth() + 3;
	y = getHeight() + 3;
	setBackgroundColor(255, 255, 255);
	run("Canvas Size...", "width=" + x + " height=" + "y" + " position=Center");
	run("Combine...", "stack1=C2-Max stack2=C2_mask");
	rename("Ch2");
	
	//Create a combined preview for both channels
	run("Combine...", "stack1=[Ch1] stack2=[Ch2] combine");
	saveAs("tiff", output_dir + "Preview for " + short_name + ".tiff");
	close();
}

//Save the quantification results into a .csv table file
Table.save(output_dir + "IJM results for Channel 1.csv", Ch2_table);
Table.save(output_dir + "IJM results for Channel 2.csv", Ch2_table);

run("Close All");
roiManager("reset");
run("Clear Results");
if(isOpen(Ch1_table)){
	selectWindow(Ch1_table);
	run("Close");
}
if(isOpen(Ch2_table)){
	selectWindow(Ch2_table);
	run("Close");
}

print( "All done! Analysis is saved in " + output_dir);
print("");
print ("Alyona Minina. 2025");
